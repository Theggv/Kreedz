#include <amxmodx>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN			"[KZ] Teleport to player"
#define VERSION			__DATE__
#define AUTHOR			"ggv"

new gb_IsTeleportAllowed[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("goto", "cmd_TeleportToPlayer");
	kz_register_cmd("allowgoto", "cmd_AllowTeleports");
}

public client_putinserver(id) {
	gb_IsTeleportAllowed[id] = true;
}

public cmd_TeleportToPlayer(id) {
	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}

	new players[MAX_PLAYERS], iNum, iPlayer;

	get_players(players, iNum, "ah");

	if (!iNum) {
		return PLUGIN_HANDLED;
	}

	new szMsg[128], szName[MAX_NAME_LENGTH];

	formatex(szMsg, charsmax(szMsg), "%L", id, "GOTOMENU_TITLE");
	new menu = menu_create(szMsg, "@MenuCallback")

	for (new i = 0; i < iNum; ++i) {
		iPlayer = players[i];

		if (id == iPlayer) continue;

		get_user_name(iPlayer, szName, charsmax(szName));

		if (gb_IsTeleportAllowed[iPlayer]) {
			formatex(szMsg, charsmax(szMsg), "%L", id, "GOTOMENU_ALLOWED", szName);
			menu_additem(menu, szMsg, fmt("%d", iPlayer));
		} else {
			formatex(szMsg, charsmax(szMsg), "%L", id, "GOTOMENU_FORBIDDEN", szName);
			menu_additem(menu, szMsg, fmt("%d", iPlayer));
		}
	}
	
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

@MenuCallback(id, menu, item) {
	if (item == MENU_EXIT || !is_user_alive(id)) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	static szData[16], access;
	menu_item_getinfo(menu, item, access, szData, charsmax(szData));

	menu_destroy(menu);

	new iPlayer = str_to_num(szData);

	// is player alive validation
	if (!is_user_alive(iPlayer)) {
		cmd_TeleportToPlayer(id);
		return PLUGIN_HANDLED;
	}

	new szName[MAX_NAME_LENGTH];
	get_user_name(iPlayer, szName, charsmax(szName));

	if (!gb_IsTeleportAllowed[iPlayer]) {
		client_print_color(id, print_team_red, "%L", id, "GOTO_FORBIDDEN_CHAT", szName);
		cmd_TeleportToPlayer(id);
		return PLUGIN_HANDLED;
	}

	if (kz_get_timer_state(id) == TIMER_ENABLED)
		kz_set_pause(id);

	new vOrigin[3];
	get_entvar(iPlayer, var_origin, vOrigin);
	set_entvar(id, var_origin, vOrigin);

	client_print_color(id, print_team_default, "%L", id, "GOTO_TELEPORTED_TO_CHAT", szName);

	cmd_TeleportToPlayer(id);
	return PLUGIN_HANDLED;
}

public cmd_AllowTeleports(id) {
	gb_IsTeleportAllowed[id] = !gb_IsTeleportAllowed[id];

	return PLUGIN_HANDLED;
}
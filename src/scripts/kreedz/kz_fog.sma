#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>

#define PLUGIN 			"[KZ] Frames on the ground"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

new bool:g_isFogEnabled[MAX_PLAYERS + 1];
new g_fogCounter[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("fog", "cmd_Fog");

	RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink");
}

public cmd_Fog(id) {
	g_isFogEnabled[id] = !g_isFogEnabled[id];

	if (g_isFogEnabled[id]) {
		client_print_color(id, print_team_default, "^4[KZ] ^1Fog enabled.");
	} else {
		client_print_color(id, print_team_default, "^4[KZ] ^1Fog disabled.");
	}

	return PLUGIN_HANDLED;
}

public client_disconnected(id) {
	g_isFogEnabled[id] = false;
}

public OnPlayerPreThink(id) {
	if (!g_isFogEnabled[id] || !is_user_alive(id)) {
		return;
	}

	if (get_entvar(id, var_flags) & FL_ONGROUND) {
		if (g_fogCounter[id] <= 10)
			g_fogCounter[id]++;
	} else {
		if (g_fogCounter[id] && g_fogCounter[id] < 10) {
			set_dhudmessage(255, 255, 255, -1.0, 0.75, 0, 0.0, 0.5, 0.05, 0.05);
			show_dhudmessage(id, "fog: %d", g_fogCounter[id]);
		}

		g_fogCounter[id] = 0;
	}
}
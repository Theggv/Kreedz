#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Spectator"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:eForward {
	fwd_SpecPre,
	fwd_SpecPost,
}

new g_Forwards[eForward];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	kz_register_cmd("spec", "cmd_Spec");
	kz_register_cmd("ct", "cmd_Spec");

	InitForwards();
}

InitForwards() {
	g_Forwards[fwd_SpecPre] = CreateMultiForward("kz_spectator_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_SpecPost] = CreateMultiForward("kz_spectator_post", ET_IGNORE, FP_CELL);
}
 
public client_kill(id) {
	cmd_Spec(id);
	
	return PLUGIN_HANDLED;
}

public client_command(id) {
	static szCommand[256];
	read_args(szCommand, charsmax(szCommand));

	remove_quotes(szCommand);

	// client_print(id, print_chat, szCommand);

	if (equal(szCommand, "/spec ", 6)) {
		amxclient_cmd(id, "spec", szCommand[6]);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cmd_Spec(id) {
	new iRet;
	ExecuteForward(g_Forwards[fwd_SpecPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;
	
	if (cs_get_user_team(id) == CS_TEAM_CT) {
		if (kz_get_timer_state(id) == TIMER_ENABLED) {
			kz_set_pause(id);
		}

		if (read_argc() > 0) {
			new szName[MAX_NAME_LENGTH];
			read_argv(1, szName, charsmax(szName));

			new iPlayer = find_player("bfh", szName);

			if(iPlayer)
			{
				set_entvar(id, var_iuser1, 4);
				set_entvar(id, var_iuser2, iPlayer);
			}
		}

		cs_set_user_team(id, CS_TEAM_SPECTATOR);

		set_entvar(id, var_solid, SOLID_NOT);
		set_entvar(id, var_movetype, MOVETYPE_FLY);
		set_entvar(id, var_effects, EF_NODRAW);
		set_entvar(id, var_deadflag, DEAD_DEAD);
		
	}
	else {
		cs_set_user_team(id, CS_TEAM_CT);

		set_entvar(id, var_effects, 0);
		set_entvar(id, var_movetype, MOVETYPE_WALK);
		set_entvar(id, var_deadflag, DEAD_NO);
		set_entvar(id, var_takedamage, DAMAGE_AIM);

		if (get_user_team(id) != 3) 
			ExecuteHamB(Ham_CS_RoundRespawn, id);

		give_item(id, "weapon_knife");
		new weapon = rg_give_item(id, "weapon_usp", GT_REPLACE);

		if(!is_nullent(weapon))
		{
			rg_set_iteminfo(weapon, ItemInfo_iMaxClip, 10);
			rg_set_user_ammo(id, WEAPON_USP, 10);	
		}

		kz_tp_last_pos(id);
	}

	ExecuteForward(g_Forwards[fwd_SpecPost], _, id);

	return PLUGIN_HANDLED;
}
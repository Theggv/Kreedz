#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Spectator"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserData
{
	bool:ud_IsHideList
}

enum _:eForward {
	fwd_SpecPre,
	fwd_SpecPost,
}

new hudsync;

new g_UserData[MAX_PLAYERS + 1][UserData];
new g_Forwards[eForward];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("jointeam", "cmd_Spec");
	register_clcmd("chooseteam", "cmd_Spec");

	kz_register_cmd("spec", "cmd_Spec");
	kz_register_cmd("ct", "cmd_Spec");

	kz_register_cmd("speclist", "cmd_Speclist");
	
	set_task(1.0, "Task_SpecList", .flags = "b");

	hudsync = CreateHudSyncObj();

	InitForwards();
}

InitForwards() {
	g_Forwards[fwd_SpecPre] = CreateMultiForward("kz_spectator_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_SpecPost] = CreateMultiForward("kz_spectator_post", ET_IGNORE, FP_CELL);
}
 
public client_kill(id)
{
	cmd_Spec(id);
	
	return PLUGIN_HANDLED;
}

public client_command(id)
{
	static szCommand[256];
	read_args(szCommand, charsmax(szCommand));

	remove_quotes(szCommand);

	// client_print(id, print_chat, szCommand);

	if(equal(szCommand, "/spec ", 6))
	{
		amxclient_cmd(id, "spec", szCommand[6]);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cmd_Speclist(id)
{
	g_UserData[id][ud_IsHideList] = !g_UserData[id][ud_IsHideList];

	return PLUGIN_HANDLED;
}

public cmd_Spec(id)
{
	new iRet;
	ExecuteForward(g_Forwards[fwd_SpecPre], iRet, id);

	if(iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(kz_get_timer_state(id) == TIMER_ENABLED)
		{
			kz_set_pause(id);
		}

		if(read_argc() > 0)
		{
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
	else
	{
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

public Task_SpecList()
{
	static szMsg[2048], szSpectators[2048], szName[MAX_NAME_LENGTH];
	static specNum, bool:hasSpectators;

	for(new iAlive = 1; iAlive <= MAX_PLAYERS; ++iAlive)
	{
		if(!is_user_alive(iAlive))
			continue;

		new bool:specList[MAX_PLAYERS + 1];
		hasSpectators = false;
		specNum = 0;

		specList[iAlive] = true;

		formatex(szSpectators, charsmax(szSpectators), "");

		for(new iDead = 1; iDead <= MAX_PLAYERS; ++iDead)
		{
			if(!is_user_connected(iDead) || is_user_alive(iDead) || is_user_bot(iDead))
				continue;

			if(	get_entvar(iDead, var_iuser1) != 1 && 
				get_entvar(iDead, var_iuser1) != 2 &&
				get_entvar(iDead, var_iuser1) != 4)
				continue;

			if(get_entvar(iDead, var_iuser2) != iAlive)
				continue;

			if(get_user_flags(iDead) & ADMIN_KICK)
			{
				specList[iDead] = true;
				continue;
			}

			hasSpectators = true;
			specNum++;

			specList[iDead] = true;

			get_user_name(iDead, szName, charsmax(szName));

			add(szSpectators, charsmax(szSpectators), szName);
			add(szSpectators, charsmax(szSpectators), "^n");
		}

		if(!hasSpectators)
			continue;

		formatex(szMsg, charsmax(szMsg), "%L^n%s", 
			LANG_PLAYER, "SPECLIST_TITLE", specNum, szSpectators);
		
		for(new i = 1; i <= MAX_PLAYERS; ++i)
		{
			if(specList[i] && !g_UserData[i][ud_IsHideList])
			{
				set_hudmessage(255, 255, 255, 0.75, 0.15, 0, 0.0, 1.0, 0.05, 0.05, -1);
				ShowSyncHudMsg(i, hudsync, szMsg);
			}
		}
	}
}
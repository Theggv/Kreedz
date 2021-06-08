#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Remove Ents & HP System"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

#define TASK_HEAL 	5050

new Trie:g_tStarts;
new Trie:g_tStops;

new bool:g_hasInfinityHP = false;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_dictionary("kz_mode.txt");

	register_clcmd("fullupdate", "cmd_Block");

	RegisterHam(Ham_CS_RoundRespawn, "player", "ham_Respawn_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage_Pre", 0);
	RegisterHam(Ham_Touch, "weaponbox", "ham_Touch_Pre", 0);
	RegisterHam(Ham_Killed, "player", "ham_Killed_Post", 1);

	register_message(get_user_msgid("StatusIcon"), "msgStatusIcon");

	init_tries();
	set_task(1.0, "init_RemoveEnts");
}

public plugin_precache()
{
	new iNumSpawns = 0, Float:vPos[3];
	new iEnt = -1, iEnt2;
	while((iEnt = rg_find_ent_by_class(iEnt, "info_player_start")) != 0)
	{
		iNumSpawns++;
		get_entvar(iEnt, var_origin, vPos);
	}

	for(new i; i < 32 - iNumSpawns; i++)
	{
		iEnt2 = create_entity("info_player_start");
		entity_set_origin(iEnt2, vPos);
	}
}

init_tries()
{
	g_tStarts = TrieCreate();
	g_tStops  = TrieCreate();

	new const szStarts[][] =
	{
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
	}

	new const szStops[][]  =
	{
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	}

	for(new i; i < sizeof szStarts; i++)
		TrieSetCell(g_tStarts, szStarts[i], 1);
	
	for(new i; i < sizeof szStops; i++)
		TrieSetCell(g_tStops, szStops[i], 1);
}

public init_RemoveEnts()
{
	new szTempStr[32];
	new iEnt, iEnt2;

	remove_entity_name("player_weaponstrip");
	remove_entity_name("armoury_entity");
	remove_entity_name("info_player_deathmatch");
	remove_entity_name("game_player_equip");
	
	//Remove func_breakables with < 9999 hp	
	iEnt = -1;

	while((iEnt = rg_find_ent_by_class(iEnt, "func_breakable")) != 0)
	{
		if(Float:get_entvar(iEnt, var_health) < 9999.0) 
			remove_entity(iEnt);
	}
	
	//Remove neg dmg func_door that aren't targeted by a button
	iEnt = -1;

	while((iEnt = rg_find_ent_by_class(iEnt, "func_door")) != 0)
	{
		if(entity_get_float(iEnt, EV_FL_dmg) < 0)
		{
			get_entvar(iEnt, var_targetname, szTempStr, charsmax(szTempStr));

			if(strlen(szTempStr))
			{
				iEnt2 = find_ent_by_target(-1, szTempStr);

				if(iEnt2)
					remove_entity(iEnt2);
			}

			g_hasInfinityHP = true;

			remove_entity(iEnt);
		}
	}

	// Find hp booster
	iEnt = -1;

	if(!g_hasInfinityHP)
	{
		while((iEnt = rg_find_ent_by_class(iEnt, "trigger_hurt")) != 0)
		{
			if(entity_get_float(iEnt, EV_FL_dmg) < -100.0)
			{
				g_hasInfinityHP = true;
				break;
			}
		}
	}
	
	//Remove map built in start button sounds
	iEnt = -1;

	while((iEnt = rg_find_ent_by_class(iEnt, "ambient_generic")) != 0)
	{
		get_entvar(iEnt, var_targetname, szTempStr, charsmax(szTempStr));

		if(TrieKeyExists(g_tStarts, szTempStr))
			remove_entity(iEnt);
	}
}

public kz_timer_start_post(id)
{
	if(g_hasInfinityHP)
	{
		set_entvar(id, var_takedamage, DAMAGE_NO);
		set_entvar(id, var_health, 255.0);
	}
	else
	{
		set_entvar(id, var_takedamage, DAMAGE_YES);
		set_entvar(id, var_health, 100.0);
	}
}

public cmd_Block(id)
{
	return PLUGIN_HANDLED;
}

public ham_Touch_Pre(iEnt, id)
{
	if(is_entity(iEnt))
		remove_entity(iEnt);
}

public ham_TakeDamage_Pre(id, iInflictor, iAttacker, Float:fDamage, damagebits)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(fDamage < 0 || kz_get_timer_state(id) != TIMER_ENABLED)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public ham_TakeDamage_Post(id, iInflictor, iAttacker, Float:fDamage, damagebits)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(damagebits)
	{
		set_task(0.5, "task_Heal", TASK_HEAL + id);
	}

	return HAM_IGNORED;
}

public ham_Respawn_Post(id)
{
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(g_hasInfinityHP)
	{
		set_entvar(id, var_takedamage, DAMAGE_NO);
		set_entvar(id, var_health, 255.0);
	}
	else if(kz_get_timer_state(id) == TIMER_ENABLED)
	{
		set_entvar(id, var_takedamage, DAMAGE_YES);
		set_entvar(id, var_health, 100.0);
	}


	return HAM_IGNORED;
}

public ham_Killed_Post(id)
{
	if(is_user_connected(id))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
}

public task_Heal(id)
{
	id -= TASK_HEAL;

	if(g_hasInfinityHP)
	{
		set_entvar(id, var_health, 255.0);
	}
	else
	{
		set_entvar(id, var_health, 100.0);
	}
}

public msgStatusIcon(msgid, msgdest, id)
{
	static szIcon[8];
	get_msg_arg_string(2, szIcon, 7);

	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		if(!is_user_connected(id))
			return PLUGIN_CONTINUE;
		
		set_pdata_int(id, 235, get_pdata_int(id, 235, 5) & ~(1 << 0), 5);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
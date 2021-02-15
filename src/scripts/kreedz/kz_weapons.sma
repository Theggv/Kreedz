#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Weapons"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserData
{
	ud_MaxRank
}

new g_UserData[MAX_PLAYERS + 1][UserData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("weapons", "cmd_Weapons");
	kz_register_cmd("scout", "cmd_Scout");
	kz_register_cmd("usp", "cmd_Usp");
	kz_register_cmd("awp", "cmd_AWP");
	kz_register_cmd("m4a1", "cmd_M4A1");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "ham_Silent_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_usp", "ham_Silent_Shoot", 1);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_famas", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p90", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_scout", "ham_Other_Shoot", 1);

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "HookResetMaxSpeed", 1);

	register_dictionary("kz_mode.txt");
}

public plugin_natives()
{
	register_native("kz_get_min_rank", "native_get_min_rank", 1);
	register_native("kz_set_min_rank", "native_set_min_rank", 1);
	register_native("kz_get_weapon_name", "native_get_weapon_name", 1);
	register_native("kz_get_usp", "native_get_usp", 1);
}

public native_get_min_rank(id)
{
	return g_UserData[id][ud_MaxRank];
}

public native_set_min_rank(id, value)
{
	g_UserData[id][ud_MaxRank] = value;
}

public native_get_weapon_name(iRank, szWeapon[], iLen)
{
	param_convert(2);
	wpn_rank_to_name(szWeapon, iLen, iRank);
}

public native_get_usp(id)
{
	rg_give_item(id, "weapon_knife", GT_REPLACE);
	give_user_item(id, "weapon_usp", 10, GT_REPLACE);
}

public cmd_Weapons(id)
{
	give_user_item(id, "weapon_awp", 2);
	give_user_item(id, "weapon_m249", 2);
	give_user_item(id, "weapon_m4a1", 10);
	give_user_item(id, "weapon_sg552", 2);
	give_user_item(id, "weapon_famas", 2);
	give_user_item(id, "weapon_p90", 2);
	give_user_item(id, "weapon_usp", 10, GT_REPLACE);
	give_user_item(id, "weapon_scout", 2);

	return PLUGIN_HANDLED;
}

public cmd_Scout(id)
{
	give_user_item(id, "weapon_scout", 10, GT_REPLACE);

	return PLUGIN_HANDLED;
}

public cmd_Usp(id)
{
	native_get_usp(id);
	return PLUGIN_HANDLED;
}

public cmd_AWP(id)
{
	give_user_item(id, "weapon_awp", 2, GT_REPLACE);
	return PLUGIN_HANDLED;
}

public cmd_M4A1(id)
{
	give_user_item(id, "weapon_m4a1", 10, GT_REPLACE);
	return PLUGIN_HANDLED;
}

// 
// forwards
// 

public kz_timer_started(id)
{
	g_UserData[id][ud_MaxRank] = get_max_rank(id);
}

public HookResetMaxSpeed(id)
{
	if(kz_get_timer_state(id) != TIMER_ENABLED)
		return HC_CONTINUE;

	new iRank = get_max_rank(id);

	if(iRank > g_UserData[id][ud_MaxRank])
		g_UserData[id][ud_MaxRank] = iRank;

	return HC_CONTINUE;
}

public ham_Silent_Shoot(iEnt)
{
	if(!is_entity(iEnt))
		return HAM_IGNORED;

	cs_set_weapon_silen(iEnt, 1, 0);

	new id = get_member(iEnt, m_pPlayer);

	if(id < 1 || id > MaxClients)
		return HAM_IGNORED;

	new iItem = get_user_weapon(id);

	cs_set_user_bpammo(id, iItem, 10);

	return HAM_IGNORED;
}

public ham_Other_Shoot(iEnt)
{
	if(!is_entity(iEnt))
		return HAM_IGNORED;
	
	new id = get_member(iEnt, m_pPlayer);

	if(id < 1 || id > MaxClients)
		return HAM_IGNORED;

	new iItem = get_user_weapon(id);

	cs_set_user_bpammo(id, iItem, 2);
	
	return HAM_IGNORED;
}

public wpn_rank_to_name(szWeapon[], iLen, iRank)
{
	switch(iRank)
	{
		case 0: formatex(szWeapon, iLen, "AWP");
		case 1: formatex(szWeapon, iLen, "M249");
		case 2: formatex(szWeapon, iLen, "M4A1");
		case 3: formatex(szWeapon, iLen, "SG552");
		case 4: formatex(szWeapon, iLen, "Famas");
		case 5: formatex(szWeapon, iLen, "P90");
		case 6: formatex(szWeapon, iLen, "USP");
		case 7: formatex(szWeapon, iLen, "Scout");
	}
}

public get_max_rank(id)
{
	new iMaxSpeed = floatround(Float:get_entvar(id, var_maxspeed));

	switch(iMaxSpeed)
	{
		case 210: return 0;
		case 220: return 1;
		case 230: return 2;
		case 235: return 3;
		case 240: return 4;
		case 245: return 5;
		case 250: return 6;
		case 260: return 7;
	}

	return -1;
}

stock give_user_item(id, const szWeapon[], numBullets, GiveType:giveType = GT_APPEND)
{
	new iWeapon = rg_give_item(id, szWeapon, giveType);

	if(!is_nullent(iWeapon))
	{
		rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, numBullets);
		rg_set_user_ammo(id, rg_get_weapon_info(szWeapon, WI_ID), numBullets);		
	}
}
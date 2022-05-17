/*
*	Changelog:
*	
*	08.06.2021: 
*		- Removed silent shooting for usp and m4a1
*		- Added protection for accidential weapon swap.
*		  Now to change weapon rank player should jump.
*		- Added some checks for give_user_item()
*	
*/

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Weapons"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserData
{
	ud_MinRank,
	ud_TemporaryRank,
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

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_usp", "ham_Other_Shoot", 1);

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_famas", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p90", "ham_Other_Shoot", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_scout", "ham_Other_Shoot", 1);

	RegisterHam(Ham_Player_Jump, "player", "ham_Jump_Post", 1);

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "HookResetMaxSpeed", 1);

	RegisterHam(Ham_Spawn, "player", "ham_Spawn_Post", 1);

	register_dictionary("kz_mode.txt");
}

public plugin_precache() {
	for (new i = 0; i <= MAX_PLAYERS; ++i) {
		kz_set_min_rank(i, -1);
	}
}

/**
*	------------------------------------------------------------------
*	Natives section
*	------------------------------------------------------------------
*/


public plugin_natives()
{
	register_native("kz_get_min_rank", "native_get_min_rank");
	register_native("kz_set_min_rank", "native_set_min_rank");
	register_native("kz_get_weapon_name", "native_get_weapon_name");
	register_native("kz_get_usp", "native_get_usp");
}

public native_get_min_rank(pluginId, argc) {
	enum { arg_id = 1 };

	new id = get_param(arg_id);

	return g_UserData[id][ud_MinRank];
}

public native_set_min_rank(pluginId, argc) {
	enum { arg_id = 1, arg_value };

	new id = get_param(arg_id);
	new value = get_param(arg_value);

	g_UserData[id][ud_MinRank] = value;
	g_UserData[id][ud_TemporaryRank] = value;

	if (is_user_alive(id)) {
		ham_Spawn_Post(id);
	}
}

public native_get_weapon_name(pluginId, argc) {
	enum { arg_rank = 1, arg_buffer, arg_len };

	new rank = get_param(arg_rank);
	new len = get_param(arg_len);
	new szWeapon[32];

	wpn_rank_to_name(szWeapon, len, rank);
	set_string(arg_buffer, szWeapon, len);
}

public native_get_usp(pluginId, argc) {
	enum { arg_id = 1 };

	new id = get_param(arg_id);

	rg_give_item(id, "weapon_knife", GT_REPLACE);
	give_user_item(id, "weapon_usp", 10, GT_REPLACE);
}

/**
*	------------------------------------------------------------------
*	Commands
*	------------------------------------------------------------------
*/


public cmd_Weapons(id)
{
	give_user_item(id, "weapon_awp", 10);
	give_user_item(id, "weapon_m249", 10);
	give_user_item(id, "weapon_m4a1", 10);
	give_user_item(id, "weapon_sg552", 10);
	give_user_item(id, "weapon_famas", 10);
	give_user_item(id, "weapon_p90", 10);
	give_user_item(id, "weapon_usp", 12, GT_REPLACE);
	give_user_item(id, "weapon_scout", 10);

	return PLUGIN_HANDLED;
}

public cmd_Scout(id)
{
	give_user_item(id, "weapon_scout", 10, GT_REPLACE);

	return PLUGIN_HANDLED;
}

public cmd_Usp(id)
{
	kz_get_usp(id);
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

/**
*	------------------------------------------------------------------
*	Forwards
*	------------------------------------------------------------------
*/

public client_connect(id) {
	kz_set_min_rank(id, -1);
}

public kz_timer_start_post(id) {
	g_UserData[id][ud_MinRank] = get_min_rank(id);
	g_UserData[id][ud_TemporaryRank] = g_UserData[id][ud_MinRank];
}

public kz_timer_pause_post(id) {
	if (kz_get_timer_state(id) != TIMER_ENABLED) 
		return;
	
	// Update weapon after pause
	HookResetMaxSpeed(id);
}

public HookResetMaxSpeed(id) {
	if (kz_get_timer_state(id) != TIMER_ENABLED) 
		return HC_CONTINUE;

	new iRank = get_min_rank(id);

	if (iRank > g_UserData[id][ud_MinRank])
		g_UserData[id][ud_TemporaryRank] = iRank;

	return HC_CONTINUE;
}

public ham_Spawn_Post(id) {
	if (g_UserData[id][ud_MinRank] != -1 &&
		g_UserData[id][ud_MinRank] != 6) {

		// Give user weapons if weapon was saved
		amxclient_cmd(id, "weapons");

		switch (g_UserData[id][ud_MinRank]) {
			case 0: amxclient_cmd(id, "weapon_awp");
			case 1: amxclient_cmd(id, "weapon_m249");
			case 2: amxclient_cmd(id, "weapon_m4a1");
			case 3: amxclient_cmd(id, "weapon_sg552");
			case 4: amxclient_cmd(id, "weapon_famas");
			case 5: amxclient_cmd(id, "weapon_p90");
			case 7: amxclient_cmd(id, "weapon_scout"); 
		}
	}
}

// deprecated
public ham_Silent_Shoot(iEnt)
{
	if(!is_entity(iEnt))
		return HAM_IGNORED;

	cs_set_weapon_silen(iEnt, 1, 0);

	new id = get_member(iEnt, m_pPlayer);

	if (id < 1 || id > MaxClients || !is_user_alive(id))
		return HAM_IGNORED;

	new iItem = get_user_weapon(id);

	cs_set_user_bpammo(id, iItem, 10);

	return HAM_IGNORED;
}

public ham_Other_Shoot(iEnt)
{
	if (!is_entity(iEnt))
		return HAM_IGNORED;
	
	new id = get_member(iEnt, m_pPlayer);

	if (id < 1 || id > MaxClients || !is_user_alive(id))
		return HAM_IGNORED;

	new iItem = get_user_weapon(id);

	cs_set_user_bpammo(id, iItem, 10);
	
	return HAM_IGNORED;
}

public ham_Jump_Post(id) {
	if (!is_user_alive(id) ||
		kz_get_timer_state(id) != TIMER_ENABLED) 
		return HAM_IGNORED;

	if (g_UserData[id][ud_TemporaryRank] > g_UserData[id][ud_MinRank]) {
		g_UserData[id][ud_MinRank] = g_UserData[id][ud_TemporaryRank];
	}

	return HAM_IGNORED;
}

/**
*	------------------------------------------------------------------
*	Utility
*	------------------------------------------------------------------
*/


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

public get_min_rank(id)
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
	if (!is_user_alive(id)) return;

	new iWeapon = rg_give_item(id, szWeapon, giveType);

	if (!is_nullent(iWeapon) && iWeapon != -1)
	{
		rg_set_iteminfo(iWeapon, ItemInfo_iMaxClip, numBullets);
		rg_set_user_ammo(id, rg_get_weapon_info(szWeapon, WI_ID), numBullets);		
	}
}
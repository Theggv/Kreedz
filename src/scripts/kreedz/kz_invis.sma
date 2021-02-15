#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <kreedz/kz_api>

enum _:InvisStruct
{
	bool:isHidePlayers,
	bool:isHideWater
}

new g_UserData[MAX_PLAYERS + 1][InvisStruct];

new gWaterFound;
new g_IsWaterEntity[2048];

#define PLUGIN 	 	"[Kreedz] Invis"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("invis", "cmd_Invis");

	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink_Post", 1);
	RegisterHam(Ham_Player_PostThink, "player", "fw_PostThink", 1);
	register_forward(FM_AddToFullPack, "FM_AddToFullPack_Post", 1);

	init_water();

	register_dictionary("kz_mode.txt");
}

public client_disconnected(id) {
	g_UserData[id][isHidePlayers] = false;
	g_UserData[id][isHideWater] = false;
}

init_water() {
	new iEnt = -1;

	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "func_water"))) {
		if (!gWaterFound) gWaterFound = true;

		g_IsWaterEntity[iEnt] = true;
	}
	
	iEnt = -1;
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "func_illusionary"))) {
		if (pev(iEnt, pev_skin) == CONTENTS_WATER) {
			if (!gWaterFound)
				gWaterFound = true;
	
			g_IsWaterEntity[iEnt] = true;
		}
	}
	
	iEnt = -1;
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "func_conveyor"))) {
		if (pev(iEnt, pev_spawnflags) == 3) {
			if (!gWaterFound)
				gWaterFound = true;
	
			g_IsWaterEntity[iEnt] = true;
		}
	}
}

// 
// Commands
// 

public cmd_Invis(id) {
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "\y%L", id, "INVISMENU_TITLE");
	
	new iMenu = menu_create(szMsg, "InvisMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "%L: %L", 
		id, "INVISMENU_PLAYERS", id, 
		(g_UserData[id][isHidePlayers] ? "INVISMENU_HIDE" : "INVISMENU_DRAW"));
	
	menu_additem(iMenu, szMsg, "1", 0);
	
	if (gWaterFound) {
		formatex(szMsg, charsmax(szMsg), "%L: %L", 
			id, "INVISMENU_WATER", id, 
			(g_UserData[id][isHideWater] ? "INVISMENU_HIDE" : "INVISMENU_DRAW"));

		menu_additem(iMenu, szMsg, "2", 0);
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public InvisMenu_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static szData[6], szName[64], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

	new iItem = str_to_num(szData);
	
	menu_destroy(menu);
	
	switch (iItem) {
		case 1: g_UserData[id][isHidePlayers] = !g_UserData[id][isHidePlayers];
		case 2: g_UserData[id][isHideWater] = !g_UserData[id][isHideWater];
	}

	cmd_Invis(id);

	return PLUGIN_HANDLED;
}

public fw_PreThink_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	static i;

	for (i = 1; i <= MAX_PLAYERS; ++i) {
		if (id != i) {
			if (is_user_alive(i))
				set_pev(i, pev_solid, SOLID_NOT);
		}
	}
}

public fw_PostThink(id)
{
	if (!is_user_alive(id))
		return;
	
	static i;

	for (i = 1; i <= MAX_PLAYERS; ++i) {
		if (id != i) {
			if (is_user_alive(i))
				set_pev(i, pev_solid, SOLID_SLIDEBOX);
		}
	}
}

public FM_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet) 
{
	if (id == iEnt)
		return FMRES_IGNORED;

	if (player) {
		set_es(es, ES_Solid, SOLID_NOT);

		if (is_user_alive(iEnt)) {
			if (fm_get_entity_distance(id, iEnt) < 200.0) {
				set_es(es, ES_RenderMode, kRenderTransTexture);
				set_es(es, ES_RenderAmt, 150);
			}

			if (get_member(id, m_iTeam) == TEAM_CT) {
				if (g_UserData[id][isHidePlayers]) {
					set_es(es, ES_RenderMode, kRenderTransTexture);
					set_es(es, ES_RenderAmt, 0);
					set_es(es, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 });
				}
			}
		}
	}
	else if (g_UserData[id][isHideWater] && g_IsWaterEntity[iEnt])
		set_es(es, ES_Effects, get_es( es, ES_Effects ) | EF_NODRAW);
	
	return FMRES_IGNORED;
}
#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>
#include <settings_api>

enum _:InvisStruct {
	bool:isHidePlayers,
	bool:isHideWater
};

new g_UserData[MAX_PLAYERS + 1][InvisStruct];
new bool:g_IsBoostEnable[MAX_PLAYERS + 1];

new gWaterFound;
new bool:g_IsWaterEntity[2048];

enum OptionsEnum {
    optIntInvisMode,
};

new g_Options[OptionsEnum];


#define PLUGIN 	 	"[Kreedz] Invis"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

// #define BOOST_MODE

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("invis", "cmd_Invis");
#if defined BOOST_MODE
	kz_register_cmd("boost", "cmd_Boost");
#endif

	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink_Post", 1);
	RegisterHam(Ham_Player_PostThink, "player", "fw_PostThink", 1);

	register_forward(FM_AddToFullPack, "FM_AddToFullPack_Post", 1);

	RegisterHookChain(RH_SV_StartSound, "OnStartSound", .post = false);

	init_water();

	bindOptions();

	register_dictionary("kreedz_lang.txt");
	register_dictionary("common.txt");
}

public client_disconnected(id) {
	g_UserData[id][isHidePlayers] = false;
	g_UserData[id][isHideWater] = false;
	g_IsBoostEnable[id] = false;
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

public bindOptions() {
	g_Options[optIntInvisMode] = find_option_by_name("invis_mode");
}

public OnCellValueChanged(id, optionId, newValue) {
	if (optionId == g_Options[optIntInvisMode]) {
		g_UserData[id][isHidePlayers] = !!(newValue & (1 << 0));
		g_UserData[id][isHideWater] = !!(newValue & (1 << 1));
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
	
	formatex(szMsg, charsmax(szMsg), "%L: %L", 
		id, "INVISMENU_WATER", id, 
		(g_UserData[id][isHideWater] ? "INVISMENU_HIDE" : "INVISMENU_DRAW"));

	menu_additem(iMenu, szMsg, "2", 0);

	formatex(szMsg, charsmax(szMsg), "%L", id, "EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szMsg);

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

	set_option_cell(id, g_Options[optIntInvisMode], 
		(_:g_UserData[id][isHideWater] << 1) + (_:g_UserData[id][isHidePlayers] << 0));

	cmd_Invis(id);

	return PLUGIN_HANDLED;
}

public cmd_Boost(id) {
	g_IsBoostEnable[id] = !g_IsBoostEnable[id];

	set_dhudmessage(0, 200, 0, .holdtime = 3.0);
	show_dhudmessage(id, g_IsBoostEnable[id] 
		? "BoOsT mOdE On" 
		: "BoOsT mOdE oFF");

	return PLUGIN_HANDLED;
}

public fw_PreThink_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	static i;

	for (i = 1; i <= MAX_PLAYERS; ++i) {
		if (id != i && is_user_alive(i)) 
			set_pev(i, pev_solid, SOLID_NOT);
	}
}

public fw_PostThink(id)
{
	if (!is_user_alive(id))
		return;
	
	static i;

	for (i = 1; i <= MAX_PLAYERS; ++i) {
		if (id != i && is_user_alive(i)) 
			set_pev(i, pev_solid, SOLID_SLIDEBOX);
	}
}

public FM_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet) 
{
	if (id == iEnt)
		return FMRES_IGNORED;

	if (player) {
#if defined BOOST_MODE
		if (!g_IsBoostEnable[id] || !g_IsBoostEnable[iEnt]) {
			set_es(es, ES_Solid, SOLID_NOT);
		}
#else
		set_es(es, ES_Solid, SOLID_NOT);
#endif

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

public OnStartSound(
	const recipients, const entity, const channel, 
	const sample[], const volume, Float:attenuation, 
	const fFlags, const pitch) {

	if (!is_user_connected(entity)) return HC_CONTINUE;
	if (is_user_bot(entity)) return HC_CONTINUE;

	if (IsStepSound(sample)) {
		for (new i = 1; i <= MAX_PLAYERS; ++i) {
			if (!is_user_connected(i) || entity == i) continue;
			if (!is_user_spectating(entity, i)) continue;

			// if (is_user_spectating(entity, i)) {
			// 	rh_emit_sound2(entity, i, channel, sample, float(volume), attenuation, fFlags, pitch);
			// 	continue;
			// }
			// else if (g_UserData[i][isHidePlayers]) {
			// 	continue;
			// }

			rh_emit_sound2(entity, i, channel, sample, volume / 255.0, attenuation, fFlags, pitch);
		}
		
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}


/**
*	------------------------------------------------------------------
*	Utils
*	------------------------------------------------------------------
*/


bool:IsStepSound(const sample[]) {
	return !!equal(sample, "player/pl_step", 14);
}
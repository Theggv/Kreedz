#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Core"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

/**
 *	------------------------------------------------------------------
 * 	Globals
 *	------------------------------------------------------------------
 */

#define MAX_CACHE			20
#define HUD_UPDATE_TIME		0.2
#define KEYS_UPDATE_TIME	0.1

enum (+=64) {
	TASK_FLASHLIGHT = 2048,
}

enum _:HudChannels {
	channel_All = -1,
	channel_Timer = 2,
	channel_Keys = 1
};

enum _:CheckpointStruct {
	Float:cp_Pos[3],
	Float:cp_Angle[3]
};

enum _:UserDataStruct {
	Float:ud_StartTime,
	Float:ud_HookProtection,
	bool:ud_isHookEnable,
	ud_SteamId[37],

	// Checks data
	ud_AvailableStucks,
	ud_CheckIndex,
	ud_ChecksNum,
	ud_TeleNum,

	// Pause checks data
	ud_PauseAvailableStucks,
	ud_PauseCheckIndex,

	// Pause data
	Float:ud_PauseTime,
	Float:ud_LastPos[3],

	// Start position data
	bool:ud_IsStartSaved,
	ud_StartPos[CheckpointStruct],

	// Timer state
	TimerState:ud_TimerState,

	// Nightvision & flashlight
	ud_NVGMode,

	// Keys
	bool:ud_showKeys,
	bool:ud_showKeysSpec,

	// Settings data
	ud_TimerData[TimerStruct],
	ud_Settings[SettingsStruct],
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];

enum _:eForwards {
	fwd_TimerStartPre,
	fwd_TimerStartPost,

	fwd_TimerPausePre,
	fwd_TimerPausePost,

	fwd_TimerFinishPre,
	fwd_TimerFinishPost,

	fwd_TimerStopPre,
	fwd_TimerStopPost,

	fwd_CheckpointPre,
	fwd_CheckpointPost,

	fwd_TeleportPre,
	fwd_TeleportPost,

	fwd_StartTeleportPre,
	fwd_StartTeleportPost,
};

new g_Forwards[eForwards];

new Float:g_Checks[MAX_PLAYERS + 1][MAX_CACHE][CheckpointStruct];
new Float:g_PauseChecks[MAX_PLAYERS + 1][MAX_CACHE][CheckpointStruct];

new Trie:g_tStarts;
new Trie:g_tStops;


// night vision
new g_sDefaultLight[8];
new g_fwd_LightStyle;

/**
 *	------------------------------------------------------------------
 * 	Init section
 *	------------------------------------------------------------------
 */

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Use, "func_button", "ham_Use", 0);
	RegisterHam(Ham_Player_PreThink, "player", "ham_PreThink");
	RegisterHam(Ham_Player_PostThink, "player", "ham_PostThink");

	// Fix for kz_a2_bhop_corruo_ez/h and maps with movable start/end buttons
	RegisterHam(Ham_Touch, "func_button", "ham_Touch", 0);

	unregister_forward(FM_LightStyle, g_fwd_LightStyle);

	// Flashlight block
	register_impulse(100, "impulse_FlashLight");

	// Init section
	InitTries();
	InitForwards();
	InitCommands();

	set_task(HUD_UPDATE_TIME, "timer_handler", .flags = "b");
	set_task(KEYS_UPDATE_TIME, "keys_handler", .flags = "b");
	
	set_pcvar_num(get_cvar_pointer("sv_skycolor_r"), 0);
	set_pcvar_num(get_cvar_pointer("sv_skycolor_g"), 0);
	set_pcvar_num(get_cvar_pointer("sv_skycolor_b"), 0);
}

InitForwards() {
	g_Forwards[fwd_TimerStartPre] = 	CreateMultiForward("kz_timer_start_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_TimerStartPost] = 	CreateMultiForward("kz_timer_start_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_TimerPausePre] = 	CreateMultiForward("kz_timer_pause_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_TimerPausePost] = 	CreateMultiForward("kz_timer_pause_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_TimerFinishPre] = 	
		CreateMultiForward("kz_timer_finish_pre", ET_CONTINUE, FP_CELL, FP_FLOAT);
	g_Forwards[fwd_TimerFinishPost] = 	
		CreateMultiForward("kz_timer_finish_post", ET_IGNORE, FP_CELL, FP_FLOAT);

	g_Forwards[fwd_TimerStopPre] = 		CreateMultiForward("kz_timer_stop_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_TimerStopPost] = 	CreateMultiForward("kz_timer_stop_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_CheckpointPre] = 	CreateMultiForward("kz_cp_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_CheckpointPost] = 	CreateMultiForward("kz_cp_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_TeleportPre] = 		CreateMultiForward("kz_tp_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_TeleportPost] = 		CreateMultiForward("kz_tp_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_StartTeleportPre] = 	CreateMultiForward("kz_starttp_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_StartTeleportPost] = CreateMultiForward("kz_starttp_post", ET_IGNORE, FP_CELL);
}

InitCommands() {
	register_clcmd("kz_version", 	"cmd_ShowVersion");

	register_clcmd("+hook", 		"cmd_DetectHook");
	register_clcmd("-hook", 		"cmd_DetectHook_Disable");
	register_clcmd("nightvision", 	"cmd_Nightvision");

	kz_register_cmd("cp", 			"cmd_Checkpoint");
	kz_register_cmd("tp", 			"cmd_Gocheck");
	kz_register_cmd("gc", 			"cmd_Gocheck");
	kz_register_cmd("stuck", 		"cmd_Stuck");
	kz_register_cmd("pause", 		"cmd_Pause");
	kz_register_cmd("unpause", 		"cmd_Pause");
	kz_register_cmd("p", 			"cmd_Pause");
	kz_register_cmd("start", 		"cmd_Start");
	kz_register_cmd("restart", 		"cmd_Start");
	kz_register_cmd("stop",		 	"cmd_Stop");
	kz_register_cmd("reset", 		"cmd_Stop");
	kz_register_cmd("keys", 		"cmd_ShowKeys");
	kz_register_cmd("showkeys", 	"cmd_ShowKeys");
	kz_register_cmd("showkeysspec", "cmd_ShowKeysSpec");

	// register_clcmd("say /vars", "cmd_vars");
}

InitTries() {
	g_tStarts = TrieCreate();
	g_tStops  = TrieCreate();

	new const szStarts[][] = {
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
	};

	new const szStops[][] = {
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	};

	for (new i; i < sizeof szStarts; i++)
		TrieSetCell(g_tStarts, szStarts[i], 1);
	
	for (new i; i < sizeof szStops; i++)
		TrieSetCell(g_tStops, szStops[i], 1);
}

public plugin_precache() {
	g_fwd_LightStyle = register_forward(FM_LightStyle, "fw_LightStyle");
}

public cmd_vars(id) {
	client_print(id, print_console, "%d %d %d %d", 
		get_entvar(id, var_iuser1), get_entvar(id, var_iuser2),
		get_entvar(id, var_iuser3), get_entvar(id, var_iuser4));

	client_print(id, print_console, "%.1f %.1f %.1f %.1f", 
		get_entvar(id, var_fuser1), get_entvar(id, var_fuser2),
		get_entvar(id, var_fuser3), get_entvar(id, var_fuser4));
}

/**
 *	------------------------------------------------------------------
 * 	Natives section
 *	------------------------------------------------------------------
 */

public plugin_natives()
{
	register_native("kz_get_timer_state", 	"native_get_timer_state");
	register_native("kz_start_timer", 		"native_start_timer");
	register_native("kz_set_pause", 		"native_set_pause");

	register_native("kz_tp_last_pos", 		"native_tp_last_pos");

	register_native("kz_get_cp_num", 		"native_get_cp_num");
	register_native("kz_set_cp_num", 		"native_set_cp_num");

	register_native("kz_get_tp_num", 		"native_get_tp_num");
	register_native("kz_set_tp_num", 		"native_set_tp_num");

	register_native("kz_get_last_pos", 		"native_get_last_pos");
	register_native("kz_set_last_pos", 		"native_set_last_pos");

	register_native("kz_get_last_cp", 		"native_get_last_cp");
	register_native("kz_set_last_cp", 		"native_set_last_cp");

	register_native("kz_get_actual_time", 	"native_get_actual_time");
	register_native("kz_set_start_time", 	"native_set_start_time");

	register_native("kz_set_timer_data", 	"native_set_timer_data");

	register_native("kz_get_settings", 		"native_get_settings");
	register_native("kz_set_settings", 		"native_set_settings");
}

public native_start_timer() {
	new id = get_param(1);

	run_start(id);
}

public native_get_cp_num() {
	new id = get_param(1);

	return g_UserData[id][ud_ChecksNum];
}

public native_set_cp_num() {
	new id = get_param(1);
	new value = get_param(2);

	g_UserData[id][ud_ChecksNum] = value;
}

public native_get_tp_num() {
	new id = get_param(1);

	return g_UserData[id][ud_TeleNum];
}

public native_set_tp_num() {
	new id = get_param(1);
	new value = get_param(2);

	g_UserData[id][ud_TeleNum] = value;
}

public native_get_last_pos() {
	new id = get_param(1);

	new value[PosStruct];

	value[pos_x] = g_UserData[id][ud_LastPos][0];
	value[pos_y] = g_UserData[id][ud_LastPos][1];
	value[pos_z] = g_UserData[id][ud_LastPos][2];

	set_array(2, value, sizeof(value));
}

public native_set_last_pos() {
	new id = get_param(1);

	new value[PosStruct];

	get_array(2, value, sizeof(value));

	g_UserData[id][ud_LastPos][0] = value[pos_x];
	g_UserData[id][ud_LastPos][1] = value[pos_y];
	g_UserData[id][ud_LastPos][2] = value[pos_z];
}

public native_get_last_cp() {
	new id = get_param(1);

	new i = g_UserData[id][ud_CheckIndex] - 1;

	if (i < 0)
		i = MAX_CACHE - 1;

	new value[PosStruct];

	value[pos_x] = g_Checks[id][i][0];
	value[pos_y] = g_Checks[id][i][1];
	value[pos_z] = g_Checks[id][i][2];

	set_array(2, value, sizeof(value));
}

public native_set_last_cp() {
	new id = get_param(1);

	new value[PosStruct];

	get_array(2, value, sizeof(value));

	g_Checks[id][0][0] = value[pos_x];
	g_Checks[id][0][1] = value[pos_y];
	g_Checks[id][0][2] = value[pos_z];

	g_UserData[id][ud_CheckIndex] = 1;
	g_UserData[id][ud_AvailableStucks] = 1;
}

public Float:native_get_actual_time() {
	new id = get_param(1);

	switch (g_UserData[id][ud_TimerState]) {
		case TIMER_DISABLED: return 0.0;
		case TIMER_ENABLED: return get_gametime() - g_UserData[id][ud_StartTime];
		case TIMER_PAUSED: return g_UserData[id][ud_PauseTime] - g_UserData[id][ud_StartTime];
	}

	return 0.0;
}

public native_set_start_time() {
	new id = get_param(1);
	new Float:value = get_param_f(2);

	g_UserData[id][ud_StartTime] = value;
}

public native_set_pause() {
	new id = get_param(1);

	new iRet;
	ExecuteForward(g_Forwards[fwd_TimerPausePre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return;

	g_UserData[id][ud_TimerState] = TIMER_PAUSED;
	g_UserData[id][ud_PauseTime] = get_gametime();

	cmd_Fade(id);

	ExecuteForward(g_Forwards[fwd_TimerPausePost], _, id);
}

public native_tp_last_pos() {
	new id = get_param(1);

	if (!g_UserData[id][ud_LastPos][0] && !g_UserData[id][ud_LastPos][1]) return;

	set_entvar(id, var_origin, g_UserData[id][ud_LastPos]);

	set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
	set_entvar(id, var_view_ofs, Float:{0.0, 0.0, 12.0});
	set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
	set_entvar(id, var_fuser2, 0.0);

	if (g_UserData[id][ud_TimerState] == TIMER_PAUSED)
		cmd_Fade(id);
}

public TimerState:native_get_timer_state() {
	new id = get_param(1);

	return g_UserData[id][ud_TimerState];
}

public native_set_timer_data() {
	new id = get_param(1);

	new value[TimerStruct];
	get_array(2, value, sizeof(value));

	g_UserData[id][ud_TimerData] = value;
}

public native_get_settings() {
	new id = get_param(1);

	new value[SettingsStruct];

	value = g_UserData[id][ud_Settings];

	set_array(2, value, sizeof(value));
}

public native_set_settings() {
	new id = get_param(1);

	new value[SettingsStruct];
	get_array(2, value, sizeof(value));

	g_UserData[id][ud_Settings] = value;
}

/**
 *	------------------------------------------------------------------
 * 	Commands section
 *	------------------------------------------------------------------
 */

public cmd_Checkpoint(id)
{
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_CheckpointPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	// air check
	if (!(get_entvar(id, var_flags) & FL_ONGROUND) &&
		!(get_entvar(id, var_movetype) == MOVETYPE_FLY)
		) {
		set_dhudmessage(150, 0, 0, -1.0, 0.8, 0, 3.0, 1.0, 0.0, 0.0);
		show_dhudmessage(id, "%L", id, "KZ_HUD_CANT_SAVE");

		return PLUGIN_HANDLED;
	}

	static Float:vPos[3], Float:vAngle[3];

	get_entvar(id, var_origin, vPos);
	get_entvar(id, var_v_angle, vAngle);

	switch (g_UserData[id][ud_TimerState]) {
		case TIMER_PAUSED: {
			g_PauseChecks[id][g_UserData[id][ud_PauseCheckIndex]][cp_Pos] = vPos;
			g_PauseChecks[id][g_UserData[id][ud_PauseCheckIndex]][cp_Angle] = vAngle;

			if (g_UserData[id][ud_PauseCheckIndex] == MAX_CACHE - 1)
				g_UserData[id][ud_PauseCheckIndex] = 0;
			else
				g_UserData[id][ud_PauseCheckIndex]++;

			if (g_UserData[id][ud_PauseAvailableStucks] < MAX_CACHE)
				g_UserData[id][ud_PauseAvailableStucks]++;
		}
		default: {
			g_Checks[id][g_UserData[id][ud_CheckIndex]][cp_Pos] = vPos;
			g_Checks[id][g_UserData[id][ud_CheckIndex]][cp_Angle] = vAngle;

			if (g_UserData[id][ud_CheckIndex] == MAX_CACHE - 1)
				g_UserData[id][ud_CheckIndex] = 0;
			else
				g_UserData[id][ud_CheckIndex]++;

			if (g_UserData[id][ud_AvailableStucks] < MAX_CACHE)
				g_UserData[id][ud_AvailableStucks]++;

			g_UserData[id][ud_ChecksNum]++;
		}
	}

	return PLUGIN_HANDLED;
}

public cmd_Gocheck(id) {
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_TeleportPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	static i;

	switch (g_UserData[id][ud_TimerState]) {
		case TIMER_PAUSED: {
			i = g_UserData[id][ud_PauseCheckIndex] - 1;

			if (i < 0)
				i = MAX_CACHE - 1;

			if (!g_PauseChecks[id][i][cp_Pos][0] && !g_PauseChecks[id][i][cp_Pos][1])
				return PLUGIN_HANDLED;

			set_entvar(id, var_origin, g_PauseChecks[id][i][cp_Pos]);

			if (g_UserData[id][ud_Settings][set_IsSaveAngles]) {
				set_entvar(id, var_angles, g_PauseChecks[id][i][cp_Angle]);
				set_entvar(id, var_v_angle, g_PauseChecks[id][i][cp_Angle]);
				set_entvar(id, var_fixangle, 1);
			}
		}
		default: {
			if (!g_UserData[id][ud_ChecksNum]) {
				set_dhudmessage(150, 0, 0, -1.0, 0.8, 0, 3.0, 1.0, 0.0, 0.0);
				show_dhudmessage(id, "%L", id, "KZ_HUD_CANT_TELEPORT");

				return PLUGIN_HANDLED;
			}

			i = g_UserData[id][ud_CheckIndex] - 1;

			if (i < 0)
				i = MAX_CACHE - 1;

			set_entvar(id, var_origin, g_Checks[id][i][cp_Pos]);

			if (g_UserData[id][ud_Settings][set_IsSaveAngles]) {
				set_entvar(id, var_angles, g_Checks[id][i][cp_Angle]);
				set_entvar(id, var_v_angle, g_Checks[id][i][cp_Angle]);
				set_entvar(id, var_fixangle, 1);
			}

			g_UserData[id][ud_TeleNum]++;
		}
	}

	set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
	set_entvar(id, var_view_ofs, Float:{0.0, 0.0, 12.0});
	set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
	set_entvar(id, var_fuser2, 0.0);

	ExecuteForward(g_Forwards[fwd_TeleportPost], _, id);

	return PLUGIN_HANDLED;
}

public cmd_Stuck(id) {
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	switch (g_UserData[id][ud_TimerState]) {
		case TIMER_PAUSED: {
			if (g_UserData[id][ud_PauseAvailableStucks] - 1 > 0)
				g_UserData[id][ud_PauseAvailableStucks]--;
			else
				return PLUGIN_HANDLED;

			if (--g_UserData[id][ud_PauseCheckIndex] < 0)
				g_UserData[id][ud_PauseCheckIndex] = MAX_CACHE - 1;
		}
		default: {
			if (g_UserData[id][ud_AvailableStucks] - 1 > 0)
				g_UserData[id][ud_AvailableStucks]--;
			else
				return PLUGIN_HANDLED;

			if (--g_UserData[id][ud_CheckIndex] < 0)
				g_UserData[id][ud_CheckIndex] = MAX_CACHE - 1;
		}
	}

	cmd_Gocheck(id);

	return PLUGIN_HANDLED;
}

public cmd_Start(id) {
	if (!is_user_alive(id))
		amxclient_cmd(id, "spec");

	new iRet;
	ExecuteForward(g_Forwards[fwd_StartTeleportPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	if (g_UserData[id][ud_IsStartSaved]) {
		set_entvar(id, var_origin, g_UserData[id][ud_StartPos][cp_Pos]);
		set_entvar(id, var_angles, g_UserData[id][ud_StartPos][cp_Angle]);
		set_entvar(id, var_v_angle, g_UserData[id][ud_StartPos][cp_Angle]);
		set_entvar(id, var_fixangle, 1);

		set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
		set_entvar(id, var_view_ofs, Float:{0.0, 0.0, 12.0});
		set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
		set_entvar(id, var_fuser2, 0.0);
	} else {
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}

	ExecuteForward(g_Forwards[fwd_StartTeleportPost], _, id);

	return PLUGIN_HANDLED;
}

public cmd_Stop(id)
{
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_TimerStopPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	g_UserData[id][ud_TimerState] = TIMER_DISABLED;

	cmd_Fade(id);

	ExecuteForward(g_Forwards[fwd_TimerStopPost], iRet, id);

	return PLUGIN_HANDLED;
}

public cmd_Pause(id) {
	if (!is_user_alive(id)) return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_TimerPausePre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	switch (g_UserData[id][ud_TimerState]) {
		case TIMER_DISABLED: return PLUGIN_HANDLED;
		case TIMER_ENABLED: {
			kz_set_pause(id);
		}
		case TIMER_PAUSED: {
			g_UserData[id][ud_TimerState] = TIMER_ENABLED;

			g_UserData[id][ud_StartTime] += get_gametime() - g_UserData[id][ud_PauseTime];

			kz_tp_last_pos(id);

			cmd_Fade(id);

			set_user_noclip(id, 0);
			amxclient_cmd(id, "-hook");

			ExecuteForward(g_Forwards[fwd_TimerPausePost], _, id);
		}
	}

	return PLUGIN_HANDLED;
}

public cmd_DetectHook(id) {
	if (is_user_alive(id) && g_UserData[id][ud_TimerState] == TIMER_ENABLED)
		kz_set_pause(id);

	g_UserData[id][ud_isHookEnable] = true;
}

public cmd_DetectHook_Disable(id) {
	g_UserData[id][ud_isHookEnable] = false;
	g_UserData[id][ud_HookProtection] = get_gametime();
}

public cmd_ShowKeys(id) {
	g_UserData[id][ud_showKeys] = !g_UserData[id][ud_showKeys];

	return PLUGIN_HANDLED;
}

public cmd_ShowKeysSpec(id) {
	g_UserData[id][ud_showKeysSpec] = !g_UserData[id][ud_showKeysSpec];

	return PLUGIN_HANDLED;
}

public impulse_FlashLight(id) {
	if (!task_exists(TASK_FLASHLIGHT + id)) {
		set_task(0.8, "TaskFlashLight", TASK_FLASHLIGHT + id, .flags = "b");
		TaskFlashLight(TASK_FLASHLIGHT + id);
	} else {
		remove_task(TASK_FLASHLIGHT + id);
	}

	return PLUGIN_HANDLED;
}

public cmd_ShowVersion(id) {
	client_print(id, print_console, "[KZ] Current version: %s", VERSION);

	return PLUGIN_HANDLED;
}

/**
 *	------------------------------------------------------------------
 * 	Forwards section
 *	------------------------------------------------------------------
 */

public client_putinserver(id) {
	new szSteamId[37];
	get_user_authid(id, szSteamId, charsmax(szSteamId));
	
	if (!equal(szSteamId, g_UserData[id][ud_SteamId])) {
		copy(g_UserData[id][ud_SteamId], charsmax(szSteamId), szSteamId);

		g_UserData[id][ud_TimerState] = TIMER_DISABLED;
		g_UserData[id][ud_LastPos] = Float:{0.0, 0.0, 0.0};

		g_UserData[id][ud_HookProtection] = 0.0;
		g_UserData[id][ud_isHookEnable] = false;

		g_UserData[id][ud_showKeys] = false;
		g_UserData[id][ud_showKeysSpec] = true;

		g_UserData[id][ud_AvailableStucks] = 0;
		g_UserData[id][ud_CheckIndex] = 0;
		g_UserData[id][ud_ChecksNum] = 0;
		g_UserData[id][ud_TeleNum] = 0;
		g_UserData[id][ud_PauseAvailableStucks] = 0;
		g_UserData[id][ud_PauseCheckIndex] = 0;
		g_UserData[id][ud_LastPos] = Float:{0.0, 0.0, 0.0};
		g_UserData[id][ud_IsStartSaved] = false;

		g_UserData[id][ud_NVGMode] = 0;
	}
}

public client_disconnected(id) {
	if (g_UserData[id][ud_TimerState] == TIMER_ENABLED) {
		g_UserData[id][ud_TimerState] = TIMER_PAUSED;
		g_UserData[id][ud_PauseTime] = get_gametime();
	}

	remove_task(TASK_FLASHLIGHT + id);
}

public ham_Use(iEnt, id) {
	if (!is_entity(iEnt) || !is_user_alive(id)) return HAM_IGNORED;

	new szTarget[32];
	get_entvar(iEnt, var_target, szTarget, charsmax(szTarget));

	// Start button detected
	if (TrieKeyExists(g_tStarts, szTarget)) {
		if (g_UserData[id][ud_isHookEnable] || 
			g_UserData[id][ud_HookProtection] > get_gametime() - 1.5 ||
			get_user_noclip(id)
			)
			return HAM_IGNORED;

		run_start(id);
	}

	// Stop button detected
	if (TrieKeyExists(g_tStops, szTarget)) {
		if (g_UserData[id][ud_TimerState] != TIMER_ENABLED)
			return HAM_IGNORED;

		run_finish(id);
	}

	return HAM_IGNORED;
}

public ham_Touch(iEnt, id) {
	if (!FClassnameIs(iEnt, "func_button")) return HAM_IGNORED;

	new szTarget[32];
	get_entvar(iEnt, var_target, szTarget, charsmax(szTarget));

	if (TrieKeyExists(g_tStarts, szTarget) || TrieKeyExists(g_tStops, szTarget))
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public ham_PreThink(id) {
	if (!is_user_alive(id)) return HAM_IGNORED;

	// use detection
	if ((get_entvar(id, var_button) & IN_USE) && 
		!(get_entvar(id, var_oldbuttons) & IN_USE)) {
		new entlist[3], count;
		count = find_sphere_class(id, "func_button", 64.0, entlist, 3);

		if (count) {
			new Float:orig[3];

			for (new i = 0; i < count; i++) {
				get_brush_entity_origin( entlist[i], orig );

				if ( is_in_viewcone( id, orig ) )
					ExecuteHamB(Ham_Use, entlist[i], id, 0, 1, true);
			}
		}
	}

	return HAM_IGNORED;
}

public ham_PostThink(id) {
	if (!is_user_alive(id) || g_UserData[id][ud_TimerState] == TIMER_PAUSED)
		return HAM_IGNORED;

	get_entvar(id, var_origin, g_UserData[id][ud_LastPos]);

	return HAM_IGNORED;
}

public fw_LightStyle(iStyle, const szValue[]) {
	if (!iStyle)
		copy(g_sDefaultLight, charsmax(g_sDefaultLight), szValue);
}

run_start(id) {
	new iRet;
	ExecuteForward(g_Forwards[fwd_TimerStartPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return;

	g_UserData[id][ud_StartTime] = get_gametime();
	g_UserData[id][ud_TimerState] = TIMER_ENABLED;

	g_UserData[id][ud_CheckIndex] = 0;
	g_UserData[id][ud_ChecksNum] = 0;
	g_UserData[id][ud_AvailableStucks] = 0;
	g_UserData[id][ud_TeleNum] = 0;

	static Float:vPos[3], Float:vAngle[3];

	get_entvar(id, var_origin, vPos);
	get_entvar(id, var_v_angle, vAngle);

	g_UserData[id][ud_IsStartSaved] = true;

	g_UserData[id][ud_StartPos][cp_Pos] = vPos;
	g_UserData[id][ud_StartPos][cp_Angle] = vAngle;

	cmd_Fade(id);

	ExecuteForward(g_Forwards[fwd_TimerStartPost], _, id);
}

run_finish(id)
{
	new Float:fTime = get_gametime() - g_UserData[id][ud_StartTime];
	new iMin, iSec, iMS;

	new iRet;
	ExecuteForward(g_Forwards[fwd_TimerFinishPre], iRet, id, fTime);

	if (iRet == KZ_SUPERCEDE) return;

	UTIL_TimeToSec(fTime, iMin, iSec, iMS);

	new szName[MAX_NAME_LENGTH];
	get_user_name(id, szName, charsmax(szName));

	new iWeaponRank = kz_get_min_rank(id);
	// new iWeaponRank = 6;
	new szWeaponName[32];

	kz_get_weapon_name(iWeaponRank, szWeaponName, charsmax(szWeaponName));

	client_print_color(0, print_team_default, "%L", LANG_PLAYER, "KZ_CHAT_FINISHED",
		szName, iMin, iSec, iMS, 
		g_UserData[id][ud_ChecksNum], g_UserData[id][ud_TeleNum], szWeaponName);

	new curScore = get_user_frags(id) * 60 + get_user_deaths(id);
	if (curScore > iMin * 60 + iSec || !curScore)
	{
		set_user_frags(id, iMin);
		cs_set_user_deaths(id, iSec);
		
		message_begin(MSG_ALL, get_user_msgid("TeamInfo"));
		write_byte(id);
		write_string("CT");
		message_end();
	}

	g_UserData[id][ud_TimerState] = TIMER_DISABLED;

	cmd_Fade(id);

	ExecuteForward(g_Forwards[fwd_TimerFinishPost], _, id, fTime);
}

public timer_handler() {
	static szMsg[256], szTime[32];
	static iMin, iSec, iMS;

	for (new id = 1; id <= MAX_PLAYERS; ++id) {
		if (!is_user_alive(id))
			continue;

		if (!g_UserData[id][ud_StartTime])
			continue;

		switch (g_UserData[id][ud_TimerState]) {
			case TIMER_DISABLED: continue;
			case TIMER_ENABLED: {
				UTIL_TimeToSec(get_gametime() - g_UserData[id][ud_StartTime], iMin, iSec, iMS);

				UTIL_FormatTime(get_gametime() - g_UserData[id][ud_StartTime],
				 	szTime, charsmax(szTime), g_UserData[id][ud_TimerData][timer_MS]);

				formatex(szMsg, charsmax(szMsg), "%s | [ %d cp | %d gc ]",
					szTime, g_UserData[id][ud_ChecksNum], g_UserData[id][ud_TeleNum]);
			}
			case TIMER_PAUSED: {
				UTIL_FormatTime(g_UserData[id][ud_PauseTime] - g_UserData[id][ud_StartTime],
				 	szTime, charsmax(szTime), g_UserData[id][ud_TimerData][timer_MS]);

				formatex(szMsg, charsmax(szMsg), 
					"%s | [ %d cp | %d gc ]^nPAUSED - say '/unpause' or '/p' to resume.",
					szTime, 
					g_UserData[id][ud_ChecksNum], g_UserData[id][ud_TeleNum]);
			}
		}

		if (g_UserData[id][ud_TimerState] == TIMER_PAUSED) {
			UTIL_BroadcastToSpec(id, "***Paused***", false, true, 
				150, 0, 0, 			// rgb
				-1.0, 0.8, 			// x y
				HUD_UPDATE_TIME); 	// time
		}

		for (new i = 1; i <= MAX_PLAYERS; ++i) {
			static timerData[TimerStruct], rgb[3];

			if (is_user_alive(i) && i != id)
				continue;

			if (get_entvar(i, var_iuser2) != id && i != id)
				continue;

			rgb = UTIL_RGBUnpack(g_UserData[i][ud_TimerData][timer_RGB]);

			timerData[timer_X] = g_UserData[i][ud_TimerData][timer_X];
			timerData[timer_Y] = g_UserData[i][ud_TimerData][timer_Y];
			timerData[timer_isDhud] = g_UserData[i][ud_TimerData][timer_isDhud];

			if (timerData[timer_isDhud]) {
				set_dhudmessage(rgb[0], rgb[1], rgb[2], 
					timerData[timer_X], timerData[timer_Y], 0, 
					0.00, HUD_UPDATE_TIME, 0.01, 0.01);
				show_dhudmessage(i, szMsg);
			}
			else {
				set_hudmessage(rgb[0], rgb[1], rgb[2], 
					timerData[timer_X], timerData[timer_Y], 0, 
					0.00, HUD_UPDATE_TIME, 0.01, 0.01, channel_Timer);
				show_hudmessage(i, szMsg);
			}
		}

		// UTIL_BroadcastToSpec(id, szMsg, false, false, 
		// 	0, 200, 0, 		// rgb
		// 	0.02, 0.2, 			// x y
		// 	HUD_UPDATE_TIME, 	// time
		// 	channel_Timer); 	// channel
	}
}

public keys_handler() {
	static szMsg[128], szAdd[16];

	for (new id = 1; id <= MAX_PLAYERS; ++id) {
		if (!is_user_alive(id))
			continue;

		new iButton = get_entvar(id, var_button);

		szMsg = "^t ";

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_FORWARD) && !(iButton & IN_BACK) ? "W^t" : "-^t");
		add(szMsg, charsmax(szMsg), szAdd);

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_JUMP) ? "^tjump^n" : "^t-^n");
		add(szMsg, charsmax(szMsg), szAdd);

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_MOVELEFT) && !(iButton & IN_MOVERIGHT) ? "A^t" : "-^t");
		add(szMsg, charsmax(szMsg), szAdd);

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_BACK) && !(iButton & IN_FORWARD) ? "S^t" : "-^t");
		add(szMsg, charsmax(szMsg), szAdd);

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_MOVERIGHT) && !(iButton & IN_MOVELEFT) ? "D^t" : "-^t");
		add(szMsg, charsmax(szMsg), szAdd);

		formatex(szAdd, charsmax(szAdd), "%s", 
			(iButton & IN_DUCK) ? "duck^n" : "-^n");
		add(szMsg, charsmax(szMsg), szAdd);

		if (g_UserData[id][ud_showKeys]) {
			set_hudmessage(175, 175, 175, -1.0, 0.6, 0, 0.00, 
				KEYS_UPDATE_TIME, 0.01, 0.01, channel_Keys);
			show_hudmessage(id, szMsg);
		}

		for (new iDead = 1; iDead <= MAX_PLAYERS; ++iDead) {
			if (is_user_alive(iDead) || id == iDead)
				continue;

			if (get_entvar(iDead, var_iuser2) != id)
				continue;

			if (g_UserData[iDead][ud_showKeysSpec]) {
				set_hudmessage(175, 175, 175, -1.0, 0.6, 0, 0.00, 
					KEYS_UPDATE_TIME, 0.01, 0.01, channel_Keys);
				show_hudmessage(iDead, szMsg);
			}
		}
	}
}

public cmd_Fade(id)
{
	if (!is_user_alive(id))
		return;

	if (g_UserData[id][ud_TimerState] == TIMER_PAUSED) {
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
		write_short(1); 	// total duration
		write_short(0); 	// time it stays one color
		write_short(5); 	// fade type
		write_byte(0); 		// r
		write_byte(0); 		// g
		write_byte(0); 		// b
		write_byte(100); 	// a
		message_end();
	}
	else {
		message_begin(MSG_ONE, get_user_msgid( "ScreenFade" ), _, id);
		write_short(1); 	// total duration
		write_short(0); 	// time it stays one color
		write_short(0); 	// fade type
		write_byte(0); 		// r
		write_byte(0); 		// g
		write_byte(0); 		// b
		write_byte(0); 		// a
		message_end();
	}
}

public cmd_Nightvision(id) {
	g_UserData[id][ud_NVGMode] = (g_UserData[id][ud_NVGMode] + 1) % 3;

	if (g_UserData[id][ud_NVGMode] == 1) {
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string("#");
		message_end();
	} else if (g_UserData[id][ud_NVGMode] == 2) {
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string("z");
		message_end();
	} else {
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string(g_sDefaultLight);
		message_end();
	}

	return PLUGIN_HANDLED;
}

public TaskFlashLight(taskId) {
	new id = taskId - TASK_FLASHLIGHT;

	if (!is_user_alive(id)) {
		remove_task(taskId);
		return;
	}

	new Float:vOrigin[3];
	get_entvar(id, var_origin, vOrigin);

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = id);
	{
		write_byte(TE_DLIGHT);
		write_coord_f(vOrigin[0]);
		write_coord_f(vOrigin[1]);
		write_coord_f(vOrigin[2]);
		write_byte(125);
		write_byte(255);
		write_byte(255);
		write_byte(255);
		write_byte(10);
		write_byte(0);
	}
	message_end();
}
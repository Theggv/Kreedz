#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <kreedz_api>
#include <kreedz_util>
#include <settings_api>

#define PLUGIN 	 	"[Kreedz] Noclip & Hook"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:(+=64) {
	TASK_HOOK = 5000,
}

enum OptionsEnum {
    optFloatNoclipSpeed,
    optFloatHookSpeed,
};

new g_Options[OptionsEnum];

enum _:UserData {
	bool:ud_hookEnabled,
	ud_hookDest[3],
	Float:ud_hookSpeed,

	bool:ud_noclipEnabled,
	Float:ud_noclipSpeed,
};

new g_UserData[MAX_PLAYERS + 1][UserData];

enum _:eForward {
	fwd_NoclipPre,
	fwd_NoclipPost,

	fwd_HookPre,
	fwd_HookPost,
};

new g_Forwards[eForward];

new g_BeamIndex;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("+hook", "cmd_Hook_Enable");
	register_clcmd("-hook", "cmd_Hook_Disable");

	RegisterHam(Ham_Player_PreThink, "player", "fw_PreThink");

	kz_register_cmd("noclip", "cmd_Noclip");
	kz_register_cmd("nc", "cmd_Noclip");

	initForwards();
	bindOptions();
}

public plugin_natives() {
	register_native("kz_in_hook", "native_in_hook");
	register_native("kz_in_noclip", "native_in_noclip");
}

public native_in_hook() {
	new id = get_param(1);
	if(id < 1 || id > MAX_PLAYERS) return false;

	return g_UserData[id][ud_hookEnabled];
}

public native_in_noclip() {
	new id = get_param(1);
	if(id < 1 || id > MAX_PLAYERS) return false;

	return g_UserData[id][ud_noclipEnabled];
}


initForwards() {
	g_Forwards[fwd_NoclipPre] = CreateMultiForward("kz_noclip_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_NoclipPost] = CreateMultiForward("kz_noclip_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_HookPre] = CreateMultiForward("kz_hook_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_HookPost] = CreateMultiForward("kz_hook_post", ET_IGNORE, FP_CELL);
}

bindOptions() {
	g_Options[optFloatNoclipSpeed] = find_option_by_name("max_noclip_speed");
	g_Options[optFloatHookSpeed] = find_option_by_name("hook_speed");
}

public OnCellValueChanged(id, optionId, newValue) {
	if (optionId == g_Options[optFloatNoclipSpeed]) {
		g_UserData[id][ud_noclipSpeed] = _:newValue;

		if (g_UserData[id][ud_noclipEnabled]) {
			set_user_maxspeed(id, g_UserData[id][ud_noclipSpeed]);
		}
	}
	else if (optionId == g_Options[optFloatHookSpeed]) {
		g_UserData[id][ud_hookSpeed] = _:newValue;
	}
}

public plugin_precache() {
	g_BeamIndex = precache_model("sprites/laserbeam.spr");
}

public client_putinserver(id) {
	cmd_Hook_Disable(id);
}

public client_disconnected(id) {
	cmd_Hook_Disable(id);

	g_UserData[id][ud_hookEnabled] = false;
	g_UserData[id][ud_noclipEnabled] = false;
}

public kz_timer_pause_pre(id) {
	if(kz_get_timer_state(id) == TIMER_ENABLED) {
		g_UserData[id][ud_noclipEnabled] = false;
	}
}

public cmd_Noclip(id) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_NoclipPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	g_UserData[id][ud_noclipEnabled] = !g_UserData[id][ud_noclipEnabled];

	if (g_UserData[id][ud_noclipEnabled]) {
		if (kz_get_timer_state(id) == TIMER_ENABLED)
			kz_set_pause(id);

		set_user_maxspeed(id, g_UserData[id][ud_noclipSpeed]);
		set_user_noclip(id, 1);
	}
	else {
		rg_reset_maxspeed(id);
		set_user_noclip(id, 0);
	}

	ExecuteForward(g_Forwards[fwd_NoclipPost], _, id);

	return PLUGIN_HANDLED;
}

public cmd_Hook_Enable(id) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_HookPre], iRet, id);

	if(iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	g_UserData[id][ud_hookEnabled] = true;

	new vTemp[3];
	get_user_origin(id, vTemp, 3);

	g_UserData[id][ud_hookDest][0] = vTemp[0];
	g_UserData[id][ud_hookDest][1] = vTemp[1];
	g_UserData[id][ud_hookDest][2] = vTemp[2];

	set_task(0.1, "task_HookHandler", TASK_HOOK + id, .flags = "b");
	task_HookHandler(TASK_HOOK + id);

	ExecuteForward(g_Forwards[fwd_HookPost], _, id);

	return PLUGIN_HANDLED;
}

public fw_PreThink(id) {
	if(!g_UserData[id][ud_hookEnabled] || !is_user_alive(id))
		return;

	static Float:vPos[3];

	get_entvar(id, var_origin, vPos);

	vPos[0] = float(g_UserData[id][ud_hookDest][0]) - vPos[0];
	vPos[1] = float(g_UserData[id][ud_hookDest][1]) - vPos[1];
	vPos[2] = float(g_UserData[id][ud_hookDest][2]) - vPos[2];

	xs_vec_normalize(vPos, vPos);
	xs_vec_mul_scalar(vPos, g_UserData[id][ud_hookSpeed], vPos);

	set_entvar(id, var_velocity, vPos);
}

public cmd_Hook_Disable(id) {
	g_UserData[id][ud_hookEnabled] = false;

	if (task_exists(TASK_HOOK + id))
		remove_task(TASK_HOOK + id);

	remove_beam(id);

	return PLUGIN_HANDLED;
}

public task_HookHandler(id) {
	id -= TASK_HOOK;

	remove_beam(id);
	draw_hook(id);
}

public draw_hook(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(g_UserData[id][ud_hookDest][0])
	write_coord(g_UserData[id][ud_hookDest][1])
	write_coord(g_UserData[id][ud_hookDest][2])
	write_short(g_BeamIndex)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(105)		// life
	write_byte(random_num(8, 10))		// width
	write_byte(random_num(0, 1))		// noise					
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(0)		// b
	write_byte(random_num(200, 500))		// brightness
	write_byte(random_num(50, 200))		// speed
	message_end()
}

public remove_beam(id) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}
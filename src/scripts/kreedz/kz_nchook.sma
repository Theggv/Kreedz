#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Noclip & Hook"
#define VERSION 	"0.1"
#define AUTHOR	 	"ggv"

#define TASK_HOOK 	5100

#define MAX_SPEED	500.0

enum _:UserData
{
	bool:ud_IsHookEnable,
	bool:ud_IsNoclipEnable,
	ud_HookOrigin[3]
}

enum _:eForward
{
	fwd_NoclipPre,
	fwd_NoclipPost,

	fwd_HookPre,
	fwd_HookPost,
}

new g_UserData[MAX_PLAYERS + 1][UserData];
new g_Forwards[eForward];
new Sbeam;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("+hook", "cmd_Hook_Enable");
	register_clcmd("-hook", "cmd_Hook_Disable");

	RegisterHookChain(RG_CBasePlayer_PreThink, "fw_PreThink");

	kz_register_cmd("noclip", "cmd_Noclip");
	kz_register_cmd("nc", "cmd_Noclip");

	InitForwards();
}

InitForwards() {
	g_Forwards[fwd_NoclipPre] = CreateMultiForward("kz_noclip_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_NoclipPost] = CreateMultiForward("kz_noclip_post", ET_IGNORE, FP_CELL);

	g_Forwards[fwd_HookPre] = CreateMultiForward("kz_hook_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[fwd_HookPost] = CreateMultiForward("kz_hook_post", ET_IGNORE, FP_CELL);
}

public plugin_precache() {
	Sbeam = precache_model("sprites/laserbeam.spr");
}

public client_putinserver(id) {
	cmd_Hook_Disable(id);
}

public client_disconnected(id) {
	cmd_Hook_Disable(id);

	g_UserData[id][ud_IsHookEnable] = false;
	g_UserData[id][ud_IsNoclipEnable] = false;
}

public kz_timer_paused(id) {
	if(kz_get_timer_state(id) == TIMER_ENABLED) {
		g_UserData[id][ud_IsNoclipEnable] = false;
	}
}

public cmd_Noclip(id) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	new iRet;
	ExecuteForward(g_Forwards[fwd_NoclipPre], iRet, id);

	if (iRet == KZ_SUPERCEDE) return PLUGIN_HANDLED;

	g_UserData[id][ud_IsNoclipEnable] = !g_UserData[id][ud_IsNoclipEnable];

	if(g_UserData[id][ud_IsNoclipEnable]) {
		if(kz_get_timer_state(id) == TIMER_ENABLED)
			kz_set_pause(id);

		set_user_noclip(id, 1);
	}
	else {
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

	g_UserData[id][ud_IsHookEnable] = true;

	new vTemp[3];
	get_user_origin(id, vTemp, 3);

	g_UserData[id][ud_HookOrigin][0] = vTemp[0];
	g_UserData[id][ud_HookOrigin][1] = vTemp[1];
	g_UserData[id][ud_HookOrigin][2] = vTemp[2];

	set_task(0.1, "task_HookHandler", TASK_HOOK + id, .flags = "b");
	task_HookHandler(TASK_HOOK + id);

	ExecuteForward(g_Forwards[fwd_HookPost], _, id);

	return PLUGIN_HANDLED;
}

public fw_PreThink(id) {
	if(!g_UserData[id][ud_IsHookEnable] || !is_user_alive(id))
		return;

	static Float:vPos[3];

	get_entvar(id, var_origin, vPos);

	vPos[0] = float(g_UserData[id][ud_HookOrigin][0]) - vPos[0];
	vPos[1] = float(g_UserData[id][ud_HookOrigin][1]) - vPos[1];
	vPos[2] = float(g_UserData[id][ud_HookOrigin][2]) - vPos[2];

	xs_vec_normalize(vPos, vPos);
	xs_vec_mul_scalar(vPos, MAX_SPEED, vPos);

	set_entvar(id, var_velocity, vPos);
}

public cmd_Hook_Disable(id) {
	g_UserData[id][ud_IsHookEnable] = false;

	if(task_exists(TASK_HOOK + id))
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
	write_coord(g_UserData[id][ud_HookOrigin][0])
	write_coord(g_UserData[id][ud_HookOrigin][1])
	write_coord(g_UserData[id][ud_HookOrigin][2])
	write_short(Sbeam)			// sprite index
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
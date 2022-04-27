#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Nightvision"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserDataStruct {
    ud_SteamId[37],
    ud_NVGMode,
    bool:ud_bFlashLight
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];

new g_sDefaultLight[8];
new g_fwd_LightStyle;

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    unregister_forward(FM_LightStyle, g_fwd_LightStyle);
    register_forward(FM_PlayerPreThink, "fwdPlayerPreThink", false);

    register_clcmd("nightvision", 	"cmd_Nightvision");
    register_impulse(100, "cmd_Flashlight");
}

public plugin_precache() {
    g_fwd_LightStyle = register_forward(FM_LightStyle, "fw_LightStyle");
}

public fw_LightStyle(iStyle, const szValue[]) {
    if (!iStyle)
        copy(g_sDefaultLight, charsmax(g_sDefaultLight), szValue);
}

public client_putinserver(id) {
    new szSteamId[37];
    get_user_authid(id, szSteamId, charsmax(szSteamId));
	
    if (!equal(szSteamId, g_UserData[id][ud_SteamId])) {
		copy(g_UserData[id][ud_SteamId], charsmax(szSteamId), szSteamId);

		g_UserData[id][ud_NVGMode] = 0;
		g_UserData[id][ud_bFlashLight] = false;
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

public fwdPlayerPreThink(id) {
    if (is_user_alive(id)) {
		if (g_UserData[id][ud_bFlashLight])
			Make_FlashLight(id);
    }
}

public cmd_Flashlight(id) {
	g_UserData[id][ud_bFlashLight] = !g_UserData[id][ud_bFlashLight];

	return PLUGIN_HANDLED;
}

stock Make_FlashLight(id) {
	static iAimOrigin[3];

	get_user_origin(id, iAimOrigin, 3);

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_DLIGHT);
	write_coord(iAimOrigin[0]);
	write_coord(iAimOrigin[1]);
	write_coord(iAimOrigin[2]);
	write_byte(12);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(1);
	write_byte(4800);
	message_end();
}
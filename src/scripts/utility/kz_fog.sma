#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <kreedz_api>
#include <kreedz_util>
#include <settings_api>

#define PLUGIN 			"[KZ] Frames on the ground"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

enum OptionsEnum {
	optBoolFog,
};

new g_Options[OptionsEnum];

new bool:g_isFogEnabled[MAX_PLAYERS + 1];
new g_fogCounter[MAX_PLAYERS + 1];

new g_entFlags[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("fog", "cmdFog");

	RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink");

	bindOptions();
}

public bindOptions() {
	g_Options[optBoolFog] = find_option_by_name("fog");
}

public OnCellValueChanged(id, optionId, newValue) {
	if (optionId == g_Options[optBoolFog]) {
		g_isFogEnabled[id] = !!newValue;
	}
}

public cmdFog(id) {
	g_isFogEnabled[id] = !g_isFogEnabled[id];

	if (g_isFogEnabled[id]) {
		client_print_color(id, print_team_default, "^4[KZ] ^1Fog enabled.");
	} else {
		client_print_color(id, print_team_default, "^4[KZ] ^1Fog disabled.");
	}

	set_option_cell(id, g_Options[optBoolFog], g_isFogEnabled[id]);

	return PLUGIN_HANDLED;
}

public OnPlayerPreThink(id) {
	if (!g_isFogEnabled[id] || !is_user_alive(id)) {
		return;
	}

	g_entFlags[id] = pev(id, pev_flags);

	if (g_entFlags[id] & FL_ONGROUND) {
		if (g_fogCounter[id] <= 10)
			g_fogCounter[id]++;
	}
	else {
		if (isUserSurfing(id)) {
			g_fogCounter[id] = 0;
			return;
		}

		if (g_fogCounter[id] > 0 && g_fogCounter[id] < 10) {
			set_dhudmessage(255, 255, 255, -1.0, 0.75, 0, 0.0, 0.5, 0.05, 0.05);
			show_dhudmessage(id, "fog: %d", g_fogCounter[id]);
		}

		g_fogCounter[id] = 0;
	}
}

stock bool:isUserSurfing(id) {
	static Float:origin[3], Float:dest[3];
	pev(id, pev_origin, origin);
	
	dest[0] = origin[0];
	dest[1] = origin[1];
	dest[2] = origin[2] - 1.0;

	static Float:flFraction;

	engfunc(EngFunc_TraceHull, origin, dest, 0, g_entFlags[id] & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id, 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0) return false;
	
	get_tr2(0, TR_vecPlaneNormal, dest);

	return dest[2] <= 0.7;
} 
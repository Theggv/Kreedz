#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 			"[KZ] Hud"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

#define HUD_UPDATE		0.1

enum _:(+=64) {
	TASK_HUD = 2048,
}

new HudSyncObj;
new g_iPlayerKeys[MAX_PLAYERS + 1];

enum _:UserDataStruct {
	bool:ud_showKeys,
	bool:ud_showKeysSpec,
	bool:ud_showSpecList,
	bool:ud_hideAdminInSpecList,
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];

//Status Info
new g_iMsgStatusText;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHookChain(RG_CBasePlayer_PostThink, "Hook_PostThink");

	kz_register_cmd("speclist", 	"cmd_Speclist");
	kz_register_cmd("spechide", 	"cmd_SpecHide");
	kz_register_cmd("showkeys", 	"cmd_ShowKeys");
	kz_register_cmd("showkeysspec", "cmd_ShowKeysSpec");

	set_task(0.1, "Task_HudList", TASK_HUD, .flags = "b");

	HudSyncObj = CreateHudSyncObj();

	g_iMsgStatusText = get_user_msgid("StatusText");
}

public client_putinserver(id) {
	g_UserData[id][ud_showKeys] = false;
	g_UserData[id][ud_showKeysSpec] = true;
	g_UserData[id][ud_showSpecList] = true;

	if (get_user_flags(id) & ADMIN_KICK) {
		g_UserData[id][ud_hideAdminInSpecList] = true;
	} else {
		g_UserData[id][ud_hideAdminInSpecList] = false;
	}
}

public cmd_Speclist(id)
{
	g_UserData[id][ud_showSpecList] = !g_UserData[id][ud_showSpecList];

	return PLUGIN_HANDLED;
}
public cmd_SpecHide(id)
{
	if (get_user_flags(id) & ADMIN_KICK) {
		g_UserData[id][ud_hideAdminInSpecList] = !g_UserData[id][ud_hideAdminInSpecList];
	}

	return PLUGIN_HANDLED;
}

public cmd_ShowKeys(id) {
	g_UserData[id][ud_showKeys] = !g_UserData[id][ud_showKeys];

	return PLUGIN_HANDLED;
}

public cmd_ShowKeysSpec(id) {
	g_UserData[id][ud_showKeysSpec] = !g_UserData[id][ud_showKeysSpec];

	return PLUGIN_HANDLED;
}

public Hook_PostThink(id) {
	if (!is_user_alive(id))
		return;

	new Button = get_entvar(id, var_button);

	if (Button & IN_FORWARD)
		g_iPlayerKeys[id] |= IN_FORWARD;
	if (Button & IN_BACK)
		g_iPlayerKeys[id] |= IN_BACK;
	if (Button & IN_MOVELEFT)
		g_iPlayerKeys[id] |= IN_MOVELEFT;
	if (Button & IN_MOVERIGHT)
		g_iPlayerKeys[id] |= IN_MOVERIGHT;
	if (Button & IN_DUCK)
		g_iPlayerKeys[id] |= IN_DUCK;
	if (Button & IN_JUMP )
		g_iPlayerKeys[id] |= IN_JUMP;
}

public Task_HudList() {
	static Float:timestamp, bool:shouldUpdateTimer;

	static specNum;

	static szMsgHud[2048];

	static szRunData[128], szTime[32], iTime;
	static szMsgKeysList[128];
	static szSpectators[2048];

	if (get_gametime() - timestamp >= 1.0) {
		timestamp = get_gametime();
		shouldUpdateTimer = true;
	}

	for (new iAlive = 1; iAlive <= MAX_PLAYERS; ++iAlive) {
		if (!is_user_alive(iAlive) && !is_user_bot(iAlive))
			continue;

		specNum = 0;
		iTime = floatround(kz_get_actual_time(iAlive), floatround_floor);
		
		// get checks and teleports
		FormatCheckpointsHud(iAlive, szRunData, charsmax(szRunData));

		// get timer
		FormatTimerHud(iAlive, szTime, charsmax(szTime));

		// get pressed keys
		FormatKeysHud(iAlive, szMsgKeysList, charsmax(szMsgKeysList));

		// get spec list
		FormatSpecList(iAlive, szSpectators, charsmax(szSpectators), specNum);

		for (new id = 1; id <= MAX_PLAYERS; ++id) {
			if (id == iAlive) {
				formatex(szMsgHud, charsmax(szMsgHud), "%s", szRunData);

				if (g_UserData[id][ud_showKeys])
					add(szMsgHud, charsmax(szMsgHud), szMsgKeysList);
			}
			else {
				if (!is_user_spectating(iAlive, id))
					continue;

				// Show timer in round time
				if (shouldUpdateTimer) {
					UTIL_TimerRoundtime(id, iTime);
				}

				if (kz_get_timer_state(iAlive) != TIMER_DISABLED)
					formatex(szMsgHud, charsmax(szMsgHud), "%s %s", szTime, szRunData);
				else
					formatex(szMsgHud, charsmax(szMsgHud), "%s", szRunData);

				if (g_UserData[id][ud_showKeysSpec])
					add(szMsgHud, charsmax(szMsgHud), szMsgKeysList);
			}

			if (specNum > 0 && g_UserData[id][ud_showSpecList]) {
				add(szMsgHud, charsmax(szMsgHud), "^nSpectators:^n"); 
				add(szMsgHud, charsmax(szMsgHud), szSpectators);
			}

			set_hudmessage(100, 100, 100, 
				0.80, 0.15, 0, 0.0, HUD_UPDATE, 0.15, 0.15, CHANNEL_HUD);
		
			if (kz_get_timer_state(iAlive) == TIMER_PAUSED) {
				set_hudmessage(255, 0, 0,
					0.80, 0.15, 0, 0.0, HUD_UPDATE, 0.15, 0.15, CHANNEL_HUD);
			}

			ShowSyncHudMsg(id, HudSyncObj, szMsgHud);
		}

		cmd_ShowStatusText(iAlive);
		g_iPlayerKeys[iAlive] = 0;
	}

	shouldUpdateTimer = false;
}

FormatCheckpointsHud(id, szMsg[], iLen) {
	new numChecks = kz_get_cp_num(id);
	new numTeleports = kz_get_tp_num(id);

	switch (kz_get_timer_state(id)) {
		case TIMER_DISABLED: {
			formatex(szMsg, iLen, "^t^n^n");
		}
		case TIMER_ENABLED: {
			formatex(szMsg, iLen, "[%d cp %d gc]^n^n", numChecks, numTeleports);
		}
		case TIMER_PAUSED: {
			formatex(szMsg, iLen, "[%d cp %d gc] | PAUSED^n^n", numChecks, numTeleports);
		}
	}
}

FormatTimerHud(id, szMsg[], iLen) {
	new Float:actualTime = kz_get_actual_time(id);

	UTIL_FormatTime(actualTime, szMsg, iLen, true);
}

FormatKeysHud(id, szKeyList[], iLen) {
	static szAddKey[16];

	formatex(szKeyList, iLen, "^t ");

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_FORWARD ? "W^t" : ".^t");
	add(szKeyList, iLen, szAddKey);

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_JUMP  ? "^tJUMP^n" : "^t^n");
	add(szKeyList, iLen, szAddKey);

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_MOVELEFT ? "A^t" : ".^t");
	add(szKeyList, iLen, szAddKey);

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_BACK ? "S^t" : ".^t");
	add(szKeyList, iLen, szAddKey);

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_MOVERIGHT ? "D^t" : ".^t");
	add(szKeyList, iLen, szAddKey);

	formatex(szAddKey, charsmax(szAddKey), "%s", 
		g_iPlayerKeys[id] & IN_DUCK ? "DUCK^n^n" : "^n^n");
	add(szKeyList, iLen, szAddKey);
}

FormatSpecList(id, szSpecList[], iLen, &specNum) {
	static szName[MAX_NAME_LENGTH];
	specNum = 0;

	formatex(szSpecList, iLen, "");

	for (new iSpec = 1; iSpec <= MAX_PLAYERS; ++iSpec) {
		if (!is_user_spectating(id, iSpec))
			continue;

		if (g_UserData[iSpec][ud_hideAdminInSpecList])
			continue;

		get_user_name(iSpec, szName, charsmax(szName));
		add(szSpecList, iLen, fmt("%s^n", szName));

		specNum++;
	}
}

bool:is_user_spectating(iAlive, iSpec) {
	if (!is_user_connected(iSpec) || is_user_alive(iSpec) || is_user_bot(iSpec))
		return false;

	if (get_entvar(iSpec, var_iuser1) != 1 && 
		get_entvar(iSpec, var_iuser1) != 2 &&
		get_entvar(iSpec, var_iuser1) != 4)
		return false;

	if (get_entvar(iSpec, var_iuser2) != iAlive)
		return false;

	return true;
}

stock cmd_ShowStatusText(id) {
	new iTarget, szStatusInfo[256];
	static szMsgTimeDead[128], szTime[32];
	static iMin, iSec, iMS;

	get_user_aiming(id, iTarget, .dist = 1000);

	if (is_user_alive(iTarget)) {
		new timerData[TimerStruct];
		kz_get_timer_data(iTarget, timerData);

		new numChecks = kz_get_cp_num(iTarget);
		new numTeleports = kz_get_tp_num(iTarget); 

		new Float:time = kz_get_actual_time(iTarget);

		switch (kz_get_timer_state(iTarget)) {
			case TIMER_DISABLED: {
				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), "^t");
			}
			case TIMER_ENABLED: {
				UTIL_TimeToSec(time, iMin, iSec, iMS);

				UTIL_FormatTime(time, szTime, charsmax(szTime), timerData[timer_MS]);

				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), "| %s [%d cp %d gc]",
					szTime, numChecks, numTeleports);
			}
			case TIMER_PAUSED: {
				UTIL_FormatTime(time, szTime, charsmax(szTime), timerData[timer_MS]);

				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), 
					"| %s [%d cp %d gc] | PAUSED",
					szTime, numChecks, numTeleports);
			}
		}

		formatex(szStatusInfo, charsmax(szStatusInfo), "1 Player: %%p2 %s", szMsgTimeDead);
	}

	message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusText, .player = id);
	write_byte(0);
	write_string(szStatusInfo);
	message_end();
}
#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 			"[KZ] Hud"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

#define HUD_UPDATE		0.09

enum _:(+=64) {
	TASK_HUD = 2048,
}

new HudSyncObj;
new g_iPlayerKeys[MAX_PLAYERS + 1];

enum _:UserDataStruct {
	bool:ud_showKeys,
	bool:ud_showKeysSpec,
	bool:ud_showSpecList,
	bool:ud_showSpecListAdmin,
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
	g_UserData[id][ud_showKeys] =  false;
	g_UserData[id][ud_showKeysSpec] =  true;
	g_UserData[id][ud_showSpecList] =  true;
	g_UserData[id][ud_showSpecListAdmin] =  true;
}

public cmd_Speclist(id)
{
	g_UserData[id][ud_showSpecList] = !g_UserData[id][ud_showSpecList];

	return PLUGIN_HANDLED;
}
public cmd_SpecHide(id)
{
	if(get_user_flags(id) & ADMIN_KICK) {
		g_UserData[id][ud_showSpecListAdmin] = !g_UserData[id][ud_showSpecListAdmin];
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
	static szMsgHud[2048], szSpectators[2048], szName[MAX_NAME_LENGTH];
	static specNum, bool:hasSpectators;
	
	static szMsgKeylist[128], szAddKey[16];

	static szMsgTimeAlive[128],szMsgTimeDead[128], szTime[32];
	static iMin, iSec, iMS;

	for (new iAlive = 1; iAlive <= MAX_PLAYERS; ++iAlive) {
		if (!is_user_alive(iAlive) && !is_user_bot(iAlive))
			continue;

		hasSpectators = false;
		specNum = 0;
		
		formatex(szSpectators, charsmax(szSpectators), "");
		szMsgKeylist = "^t ";
		szMsgTimeAlive = "^t ";
		szMsgTimeDead = "^t ";

		new Float:actualTime = kz_get_actual_time(iAlive);

		new timerData[TimerStruct];
		kz_get_timer_data(iAlive, timerData);

		new numChecks = kz_get_cp_num(iAlive);
		new numTeleports = kz_get_tp_num(iAlive);

		switch (kz_get_timer_state(iAlive)) {
			case TIMER_DISABLED: {
				formatex(szMsgTimeAlive, charsmax(szMsgTimeAlive), "^t^n^n");
				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), "^t^n^n");
			}
			case TIMER_ENABLED: {
				UTIL_TimeToSec(actualTime, iMin, iSec, iMS);

				UTIL_FormatTime(actualTime, szTime, charsmax(szTime), timerData[timer_MS]);

				formatex(szMsgTimeAlive, charsmax(szMsgTimeAlive), "[%d cp %d gc]^n^n",
					numChecks, numTeleports);

				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), "%s [%d cp %d gc]^n^n",
					szTime, numChecks, numTeleports);
			}
			case TIMER_PAUSED: {
				UTIL_FormatTime(actualTime, szTime, charsmax(szTime), timerData[timer_MS]);

				formatex(szMsgTimeAlive, charsmax(szMsgTimeAlive), 
					"[%d cp %d gc] | PAUSED^n^n", 
					numChecks, numTeleports);

				formatex(szMsgTimeDead, charsmax(szMsgTimeDead), 
					"%s [%d cp %d gc] | PAUSED^n^n",
					szTime, numChecks, numTeleports);
			}
		}

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_FORWARD ? "W^t" : ".^t");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_JUMP  ? "^tJUMP^n" : "^t^n");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_MOVELEFT ? "A^t" : ".^t");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_BACK ? "S^t" : ".^t");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_MOVERIGHT ? "D^t" : ".^t");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szAddKey, charsmax(szAddKey), "%s", 
			g_iPlayerKeys[iAlive] & IN_DUCK ? "DUCK^n^n" : "^n^n");
		add(szMsgKeylist, charsmax(szMsgKeylist), szAddKey);

		formatex(szMsgHud, charsmax(szMsgHud), "%s", szMsgTimeAlive);

		if (g_UserData[iAlive][ud_showKeys]) {
			add(szMsgHud, charsmax(szMsgHud), szMsgKeylist);
		}

		if (g_UserData[iAlive][ud_showSpecList] && specNum > 0) {
			add(szMsgHud, charsmax(szMsgHud), "^nSpectators:^n"); 
			add(szMsgHud, charsmax(szMsgHud), szSpectators);
		}
			
		set_hudmessage(100, 100, 100, 0.80, 0.15, 0, 0.0, HUD_UPDATE + 0.05, HUD_UPDATE + 0.05, HUD_UPDATE + 0.05, -1);
		
		if (kz_get_timer_state(iAlive) == TIMER_PAUSED) {
			set_hudmessage(255, 0, 0, 0.80, 0.15, 0, 0.0, HUD_UPDATE, HUD_UPDATE + 0.1, HUD_UPDATE + 0.1, -1);
		}

		ShowSyncHudMsg(iAlive, HudSyncObj, szMsgHud);

		cmd_ShowStatusText(iAlive);

		for (new iDead = 1; iDead <= MAX_PLAYERS; ++iDead) {
			if (!is_user_connected(iDead) || is_user_alive(iDead) || is_user_bot(iDead))
				continue;

			if (get_entvar(iDead, var_iuser1) != 1 && 
				get_entvar(iDead, var_iuser1) != 2 &&
				get_entvar(iDead, var_iuser1) != 4)
				continue;

			if (get_entvar(iDead, var_iuser2) != iAlive)
				continue;

			if (g_UserData[iDead][ud_showSpecListAdmin]){
				//specList[iDead] = true;
				// specNum--
				//continue;
			}

			hasSpectators = true;
			specNum++;

			//specList[iDead] = true;

			get_user_name(iDead, szName, charsmax(szName));

			if (!g_UserData[iDead][ud_showSpecListAdmin]){
				add(szSpectators, charsmax(szSpectators), szName);
				add(szSpectators, charsmax(szSpectators), "^n");
			}

			if (!hasSpectators)
				continue;
	
			formatex(szMsgHud, charsmax(szMsgHud), "%s", szMsgTimeDead);

			if (g_UserData[iDead][ud_showKeysSpec]) {
				add(szMsgHud, charsmax(szMsgHud), szMsgKeylist);
			}

			if (g_UserData[iDead][ud_showSpecList] && specNum > 0) {
				add(szMsgHud, charsmax(szMsgHud), "Spectators:^n"); 
				add(szMsgHud, charsmax(szMsgHud), szSpectators);
			}

			set_hudmessage(100, 100, 100, 0.80, 0.15, 0, 0.0, HUD_UPDATE + 0.1, HUD_UPDATE + 0.1, HUD_UPDATE + 0.1, -1);

			if (kz_get_timer_state(iAlive) == TIMER_PAUSED) {
				set_hudmessage(255, 0, 0, 0.80, 0.15, 0, 0.0, HUD_UPDATE + 0.1, HUD_UPDATE + 0.1, HUD_UPDATE + 0.1, -1);
			}

			ShowSyncHudMsg(iDead, HudSyncObj, szMsgHud);
		}
		
		g_iPlayerKeys[iAlive] = 0;

	}
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
#if defined _kreedz_util_included
	#endinput
#endif

#define _kreedz_util_included

stock kz_register_cmd(szCmd[], szHandler[]) {
	new szFormatedCmd[64];

	formatex(szFormatedCmd, 63, "say %s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);

	formatex(szFormatedCmd, 63, "say_team %s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);

	formatex(szFormatedCmd, 63, "say /%s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);

	formatex(szFormatedCmd, 63, "say_team /%s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);

	formatex(szFormatedCmd, 63, "%s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);

	formatex(szFormatedCmd, 63, "/%s", szCmd);
	register_clcmd(szFormatedCmd, szHandler);
}

stock UTIL_LogToFile(const szPath[], const szLevel[], const szFunction[], const szMessage[], any:...) {
	new szMsg[512];
	vformat(szMsg, charsmax(szMsg), szMessage, 5);
	
	log_to_file(szPath, "[%s][%s] %s", szLevel, szFunction, szMsg);
}

stock UTIL_TimeToSec(Float:fTime, &iMin, &iSec, &iMS) {
	iMin = floatround(fTime / 60.0, floatround_floor);
	iSec = floatround(fTime - iMin * 60.0, floatround_floor);
	iMS  = floatround((fTime - (iMin * 60.0 + iSec)) * 100.0, floatround_floor);
}

stock UTIL_FormatTime(Float:fTime, szBuffer[], iLen, bool:withMS = false) {
	new iMin, iSec, iMS;
	UTIL_TimeToSec(fTime, iMin, iSec, iMS);

	if (withMS)
		formatex(szBuffer, iLen, "%02d:%02d.%02d", iMin, iSec, iMS);
	else
		formatex(szBuffer, iLen, "%02d:%02d", iMin, iSec);
}

stock UTIL_BroadcastToSpec(
    id, const szMsg[], bool:isOnlySpec, bool:isDhud,
	red, green, blue, 
    Float:x, Float:y, 
    Float:holdTime, channel = -1
    ) {
	for (new i = 1; i <= MAX_PLAYERS; ++i) {
		if (i == id && !isOnlySpec) {
			if (isDhud) {
				set_dhudmessage(red, green, blue, x, y, 0, 
					0.00, holdTime, 0.01, 0.01);
				show_dhudmessage(i, szMsg);
			}
			else {
				set_hudmessage(red, green, blue, x, y, 0, 
					0.00, holdTime, 0.01, 0.01, channel);
				show_hudmessage(i, szMsg);
			}

			continue;
		}

		if (is_user_alive(i)) continue;
		if (get_entvar(i, var_iuser2) != id) continue;

		if (isDhud) {
			set_dhudmessage(red, green, blue, x, y, 0, 
				0.00, holdTime, 0.02, 0.02);
			show_dhudmessage(i, szMsg);
		}
		else {
			set_hudmessage(red, green, blue, x, y, 0, 
				0.00, holdTime, 0.02, 0.02, channel);
			show_hudmessage(i, szMsg);
		}
	}
}

stock UTIL_RGBPack(r, g, b) {
	new rgb = (r << 16) + (g << 8) + b;

	return rgb;
}

stock UTIL_RGBUnpack(color) {
	new rgb[3];
    
	rgb[0] = (color >> 16) & 255;
	rgb[1] = (color >> 8) & 255;
	rgb[2] = color & 255;

	return rgb;
}

stock UTIL_TimerRoundtime(id, time) {
	if (!is_user_connected(id)) return;

	static msgRoundTime;

	if (!msgRoundTime) msgRoundTime = get_user_msgid("RoundTime");

	message_begin(MSG_ONE_UNRELIABLE, msgRoundTime, .player = id);
	write_short(time + 1);
	message_end();
}
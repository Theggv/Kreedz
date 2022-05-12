#if defined _settings_util_included
	#endinput
#endif

#define _settings_util_included

stock UTIL_DebugMessage(const szMsg[], any:...) {
// disable warning
#pragma unused szMsg

#if defined PRINT_DEBUG_MESSAGES
	new szFormatted[256];

	vformat(szFormatted, 255, szMsg, 2);
	format(szFormatted, 255, "[SETTINGS_DEBUG] %s", szFormatted);

	server_print(szFormatted);
#endif
}

#if !defined UTIL_LogToFile
stock UTIL_LogToFile(const szPath[], const szLevel[], const szFunction[], const szMessage[], any:...) {
	new szMsg[512];
	vformat(szMsg, charsmax(szMsg), szMessage, 5);
	
	log_to_file(szPath, "[%s][%s] %s", szLevel, szFunction, szMsg);
}
#endif
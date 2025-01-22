#if defined _general_util_included
	#endinput
#endif

#define _general_util_included

stock UTIL_LogToFile(const szPath[], const szLevel[], const szFunction[], const szMessage[], any:...) {
	new szMsg[512];
	vformat(szMsg, charsmax(szMsg), szMessage, 5);
	
	log_to_file(szPath, "[%s][%s] %s", szLevel, szFunction, szMsg);
}

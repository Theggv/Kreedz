#if defined _settings_util_included
	#endinput
#endif

#define _settings_util_included

#include <general_util>

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
#include <amxmodx>

#include <kreedz_api>

#define PLUGIN 	 	"[Kreedz] Server utils"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("amx_restart", "cmd_ServerRestart");
}

public cmd_ServerRestart(id) {
	if (!(get_user_flags(id) & ADMIN_IMMUNITY)) return PLUGIN_CONTINUE;

	server_cmd("restart");

	return PLUGIN_HANDLED;
}
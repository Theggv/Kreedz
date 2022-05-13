#include <amxmodx>
#include <amxmisc>

#define PLUGIN 		"Disable startup MOTD"
#define VERSION 	"1.0"
#define AUTHOR 		"Sn!ff3r"

new bool:saw[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_message(get_user_msgid("MOTD"), "message_MOTD");
}

public client_connect(id) {
	saw[id] = false;
}

public message_MOTD(const MsgId, const MsgDest, const MsgEntity) {
	if (!saw[MsgEntity] && get_msg_arg_int(1) == 1) {
		saw[MsgEntity] = true;

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
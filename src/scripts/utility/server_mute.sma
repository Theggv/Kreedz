#include <amxmodx>
#include <fakemeta>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 		"[Server] Mute"
#define VERSION 	__DATE__
#define AUTHOR 		"ggv"

new g_Muted[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// register_message(get_user_msgid("TextMsg"), "TextMsg_Handler")
	// register_message(get_user_msgid("SendAudio"), "SendAudio_Handler")

	kz_register_cmd("mute", 			"cmd_MuteMenu");

	// register_clcmd("radio1", 		"cmd_CheckRadio");
	// register_clcmd("radio2", 		"cmd_CheckRadio");
	// register_clcmd("radio3", 		"cmd_CheckRadio");
	// register_clcmd("coverme", 		"cmd_CheckRadio");
	// register_clcmd("takepoint", 		"cmd_CheckRadio");
	// register_clcmd("holdpos", 		"cmd_CheckRadio");
	// register_clcmd("regroup",		"cmd_CheckRadio");
	// register_clcmd("followme",		"cmd_CheckRadio");
	// register_clcmd("takingfire",		"cmd_CheckRadio");
	// register_clcmd("go",				"cmd_CheckRadio");
	// register_clcmd("fallback",		"cmd_CheckRadio");
	// register_clcmd("sticktog",		"cmd_CheckRadio");
	// register_clcmd("getinpos",		"cmd_CheckRadio");
	// register_clcmd("stormfront",		"cmd_CheckRadio");
	// register_clcmd("report",			"cmd_CheckRadio");
	// register_clcmd("roger",			"cmd_CheckRadio");
	// register_clcmd("enemyspot",		"cmd_CheckRadio");
	// register_clcmd("needbackup",		"cmd_CheckRadio");
	// register_clcmd("sectorclear",	"cmd_CheckRadio");
	// register_clcmd("inposition",		"cmd_CheckRadio");
	// register_clcmd("reportingin",	"cmd_CheckRadio");
	// register_clcmd("getout",			"cmd_CheckRadio");
	// register_clcmd("negative",		"cmd_CheckRadio");
	// register_clcmd("enemydown",		"cmd_CheckRadio");

	register_forward(FM_Voice_SetClientListening, "fw_SetVoice");
}

public client_disconnected(id) {
	g_Muted[id] = 0;
}

public cmd_CheckRadio(id) {
	if (!kz_is_radio_enable(id))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public SendAudio_Handler(iMsgId, msg_dest, msg_entity)
{
	new szMsg[128];
	get_msg_arg_string(2, szMsg, charsmax(szMsg));

	if(kz_is_radio_enable(msg_entity))
		return PLUGIN_CONTINUE;

	if(	// radio1
		equal(szMsg, "%!MRAD_COVERME") || 
		equal(szMsg, "%!MRAD_TAKEPOINT") ||
		equal(szMsg, "%!MRAD_POSITION") || 
		equal(szMsg, "%!MRAD_REGROUP") ||
		equal(szMsg, "%!MRAD_FOLLOWME") || 
		equal(szMsg, "%!MRAD_HITASSIST") ||
		// radio2
		equal(szMsg, "%!MRAD_GO") || 
		equal(szMsg, "%!MRAD_FALLBACK") ||
		equal(szMsg, "%!MRAD_STICKTOG") || 
		equal(szMsg, "%!MRAD_GETINPOS") ||
		equal(szMsg, "%!MRAD_STORMFRONT") || 
		equal(szMsg, "%!MRAD_REPORTIN") ||
		// radio3
		equal(szMsg, "%!MRAD_AFFIRM") || 
		equal(szMsg, "%!MRAD_ROGER") ||
		equal(szMsg, "%!MRAD_ENEMYSPOT") || 
		equal(szMsg, "%!MRAD_BACKUP") ||
		equal(szMsg, "%!MRAD_CLEAR") || 
		equal(szMsg, "%!MRAD_INPOS") ||
		equal(szMsg, "%!MRAD_REPRTINGIN") || 
		equal(szMsg, "%!MRAD_BLOW") ||
		equal(szMsg, "%!MRAD_NEGATIVE") || 
		equal(szMsg, "%!MRAD_ENEMYDOWN"))
	{
		set_msg_arg_string(2, "");

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public TextMsg_Handler(iMsgId, msg_dest, msg_entity)
{
	new iType = get_msg_arg_int(1);

	if(iType != 5)
		return PLUGIN_CONTINUE;

	new szMsg[128];
	get_msg_arg_string(3, szMsg, charsmax(szMsg));

	if(equal(szMsg, "#Game_radio") && !kz_is_radio_enable(msg_entity))
	{
		set_msg_arg_string(3, "");

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cmd_MuteMenu(id)
{
	new szMsg[128];
	new i_Menu = menu_create("Mute menu", "MuteMenu_Handler");

	new szName[32], szItem[6];

	new sPlayers[32], iNum, iPlayer;
	get_players(sPlayers, iNum, "ch");

	for (new i = 0; i < iNum; ++i) {
		iPlayer = sPlayers[i];

		if(id == iPlayer)
			continue;

		get_user_name(iPlayer, szName, charsmax(szName));
		num_to_str(iPlayer, szItem, charsmax(szItem));

		if(g_Muted[id] & (1 << iPlayer))
			formatex(szMsg, charsmax(szMsg), "%s \d- \rMuted", szName);
		else
			formatex(szMsg, charsmax(szMsg), "%s", szName);

		menu_additem(i_Menu, szMsg, szItem, 0);
	}

	menu_display(id, i_Menu, 0);

	return PLUGIN_HANDLED;
}

public MuteMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	new s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);

	new iCommand = str_to_num(s_Data);

	if(g_Muted[id] & (1 << iCommand))
		g_Muted[id] &= ~(1 << iCommand);
	else
		g_Muted[id] |= (1 << iCommand);

	cmd_MuteMenu(id);

	return PLUGIN_HANDLED;
}

public fw_SetVoice(iReceiver, iSender, bool:bIsListen)
{
	if(iReceiver == iSender || !is_user_connected(iReceiver) || !is_user_connected(iSender))
		return FMRES_IGNORED;

	if(g_Muted[iReceiver] & (1 << iSender))
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
	else
		engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);

	return FMRES_SUPERCEDE;
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static s_Msg[191];
	vformat(s_Msg, 190, input, 3);
	
	replace_all(s_Msg, 190, "!g", "^4");
	replace_all(s_Msg, 190, "!y", "^1");
	replace_all(s_Msg, 190, "!team", "^3");
	replace_all(s_Msg, 190, "!team2", "^0");
	
	if(id) 
		players[0] = id; 
	else 
		get_players(players, count, "ch");
	
	for(new i = 0; i < count; i++)
	{
		if(is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
			write_byte(players[i]);
			write_string(s_Msg);
			message_end();
		}
	}
}
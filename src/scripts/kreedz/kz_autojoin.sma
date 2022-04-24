#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Auto Join"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

#define XO_PLAYER 5
#define m_fHasPrimary	116
#define m_iMenuCode 	205
#define m_iNumSpawns 	365

new g_iMsgId[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_message(get_user_msgid("ShowMenu"), "MessageShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "MessageVGUIMenu");
	
	RegisterHookChain(RG_RoundEnd, "Block_RoundEnd", 0);
	
	set_cvar_num("mp_limitteams", 0);
	set_cvar_num("mp_autoteambalance", 0);
}

public Block_RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
    if (event != ROUND_GAME_RESTART) {
        set_member_game(m_bGameStarted, true);
        SetHookChainReturn(ATYPE_BOOL, false);

        return HC_SUPERCEDE;
    }

    return HC_CONTINUE;
}

public client_putinserver(id) {
	if (!is_user_bot(id))
		set_pdata_int(id, m_iNumSpawns, 1, XO_PLAYER);
}

public MessageShowMenu(iMsgID, iDest, iReceiver) {
	if (!is_user_connected(iReceiver))
		return PLUGIN_HANDLED;
	
	new const Team_Select[] = "#Team_Select";

	new szMenu[sizeof(Team_Select)];
	get_msg_arg_string(4, szMenu, charsmax(szMenu));

	if (!equal(szMenu, Team_Select))
		return PLUGIN_CONTINUE;

	set_pdata_int(iReceiver, m_iMenuCode, 0, XO_PLAYER);
	
	g_iMsgId[iReceiver] = iMsgID;

	set_task(0.2, "Task_JoinTeam", iReceiver);

	return PLUGIN_HANDLED;
}

public MessageVGUIMenu(iMsgID, iDest, iReceiver) {
	if (get_msg_arg_int(1) != 2)
		return PLUGIN_CONTINUE;

	g_iMsgId[iReceiver] = iMsgID;
	
	set_task(0.3, "Task_JoinTeam", iReceiver);

	return PLUGIN_HANDLED;
}

public Task_JoinTeam(id) {
	new iMenuMsgid = g_iMsgId[id];
	new iMsgBlock = get_msg_block(iMenuMsgid);
	
	set_msg_block(iMenuMsgid, BLOCK_SET);
	engclient_cmd(id, "jointeam", "2");
	engclient_cmd(id, "joinclass", "5");
	set_msg_block(iMenuMsgid, iMsgBlock);
	
	set_task(0.2, "Task_Spawn", id);
}

public Task_Spawn(id) {
	if (!is_user_connected(id)) return;

	dllfunc(DLLFunc_Spawn, id);
	
	kz_get_usp(id);

	kz_tp_last_pos(id);
}
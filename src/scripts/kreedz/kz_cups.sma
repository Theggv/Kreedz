/*
*	Функционал:
*	1) Игрок открывает меню состязаний с помощью команды '/cups'
*	2) Меню выглядит так:
*		- Список лобби
*		- Создать лобби
*		- Приглашения
*	3) В списке лобби находятся только открытые лобби. 
		Отображается хост, кол-во игроков и статус
*	4) В меню создания лобби есть следующие настройки:
*		- Чекпоинты (вкл/выкл)
*		- Тип лобби (открытое/закрытое)
*		- Количество игроков
*		- Пригласить игроков
*		- Исключить игроков
*		- Начать состязание / Прекратить состязание
*	5) Пригласить можно только игроков, которые не участвуют в состязании
* 	6) Начать состязание может хост с помощью команды '/cup st'
* 	7) Прекратить состязание может хост с помощью команды '/cup end'
*	8) При старте состязания оно начинается через 10-с таймера, 
*		после чего игроки телепортируются на старт и не могут использовать pause, hook и noclip.
*	9) Игрок может выйти из состязания с помощью команды '/leave'
*	10) Если все игроки, кроме 1 вышли из состязания, то оно автоматически заканчивается.
*/

#include <amxmodx>
#include <fun>
#include <reapi>
#include <xs>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Cups"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

/**
 *	------------------------------------------------------------------
 * 	Globals section
 *	------------------------------------------------------------------
 */

#define LOBBY_MIN_PLAYERS	2
#define LOBBY_MAX_PLAYERS	4
#define AUTO_END_SECONDS	180

enum (+=500)
{
	TASK_START = 15000,
	TASK_ENDTIMER
}

enum CupState
{
	State_Inactive,
	State_Pending,
	State_Waiting,
	State_Started,
}

enum _:CupStruct
{
	cup_HostId,
	bool:cup_Players[MAX_PLAYERS + 1],
	bool:cup_Invites[MAX_PLAYERS + 1],
	cup_NumSlots,
	CupState:cup_State,
	bool:cup_IsCPAllow,
	bool:cup_IsLocked,
	Float:cup_Time[MAX_PLAYERS + 1]
}

new g_Cups[MAX_PLAYERS + 1][CupStruct];
new g_CurrentLobby[MAX_PLAYERS + 1];
new g_Timer[MAX_PLAYERS + 1];

/**
 *	------------------------------------------------------------------
 * 	Init section
 *	------------------------------------------------------------------
 */

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("cup", "cmd_MainMenu");
	kz_register_cmd("duel", "cmd_MainMenu");
	kz_register_cmd("lobby", "cmd_MainMenu");
	kz_register_cmd("leave", "cmd_Leave");
	kz_register_cmd("cup_st", "cmd_CupStart");
	kz_register_cmd("cup_end", "cmd_CupEnd");
	register_clcmd("kz_cups_version", "cmd_Version");

	register_dictionary("kz_cups.txt");
}

public plugin_natives()
{
	register_native("kz_cup_is_in_cup", "native_is_in_cup", 1);
	register_native("kz_cup_is_cp_allow", "native_is_cp_allow", 1);
}

/**
 *	------------------------------------------------------------------
 * 	Forwards section
 *	------------------------------------------------------------------
 */

public kz_timer_stop_post(id)
{
	if (!has_active_cup(id)) return;

	cmd_Leave(id);
}

public kz_cp_pre(id)
{
	if (!has_active_cup(id)) return KZ_CONTINUE;

	return g_Cups[get_active_cup(id)][cup_IsCPAllow] ?
		KZ_CONTINUE : KZ_SUPERCEDE;
}

public kz_starttp_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_timer_pause_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_noclip_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_hook_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_spectator_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_hookdetect_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public kz_startrun_pre(id)
{
	return has_active_cup(id) ? KZ_SUPERCEDE : KZ_CONTINUE;
}

public native_is_in_cup(id)
{
	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (g_Cups[i][cup_Players][id])
			return true;
	}

	return false;
}

public native_is_cp_allow(iLobby)
{
	return g_Cups[iLobby][cup_IsCPAllow];
}

public kz_timer_finished(id, Float:flTime)
{
	if (!has_active_cup(id))
		return;

	new iLobby = get_lobby(id);

	g_Cups[iLobby][cup_Time][id] = flTime;

	new Float:bestTime;
	new numFinished = 0;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (g_Cups[iLobby][cup_Time][i])
		{
			numFinished++;

			if (!bestTime)
				bestTime = g_Cups[iLobby][cup_Time][i];

			if (g_Cups[iLobby][cup_Time][i] < bestTime)
				bestTime = g_Cups[iLobby][cup_Time][i];
		}
	}

	new szName[MAX_NAME_LENGTH];
	get_user_name(id, szName, charsmax(szName));

	if ( flTime == bestTime)
	{
		new szTime[64];
		UTIL_FormatTime(flTime, szTime, charsmax(szTime), true);

		client_print_color(0, print_team_default, "%L", LANG_PLAYER, "CUPS_CHAT_WON", szName, szTime);

		for (new i; i <= MAX_PLAYERS; ++i)
		{
			if (g_Cups[iLobby][cup_Players][i])
			{
				client_print_color(i, print_team_default, "%L", i, "CUPS_CHAT_AUTOEND", AUTO_END_SECONDS);
			}
		}

		set_task(float(AUTO_END_SECONDS), "Task_EndTimer", TASK_ENDTIMER + iLobby);
	}
	else
	{
		new Float:diff = flTime - bestTime;

		new szTime[64], szDiff[64];
		UTIL_FormatTime(flTime, szTime, charsmax(szTime), true);
		UTIL_FormatTime(diff, szDiff, charsmax(szDiff), true);

		client_print_color(0, print_team_red, "%L", LANG_PLAYER, "CUPS_CHAT_FINISHED", szName, szTime, szDiff);
	}

	// client_print(0, print_console, "%d %d", numFinished, get_num_players_in_lobby(iLobby));

	EndMatchCheck(iLobby);
}

public client_disconnected(id)
{
	cmd_Leave(id);
}

public Task_EndTimer(iLobby)
{
	EndMatch(iLobby - TASK_ENDTIMER);
}

// 
// Commands
// 

public cmd_Version(id)
{
	client_print(id, print_console, "[KZ Cups] Current version: %s", VERSION);
	
	return PLUGIN_HANDLED;
}

public cmd_MainMenu(id)
{
	new szMsg[512];
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_MAIN_TITLE");
	
	new iMenu = menu_create(szMsg, "CupMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_MAIN_LIST");
	menu_additem(iMenu, szMsg, "1", 0);

	if (has_lobby(id))
		formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_MAIN_LOBBY");
	else
		formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_MAIN_CREATE");
	
	menu_additem(iMenu, szMsg, "2", 0);

	new numInvites = get_num_invites(id);

	if (numInvites)
		formatex(szMsg, charsmax(szMsg), "\w%L [\y%d\w]", id, "CUPS_MAIN_INVITES", numInvites);
	else
		formatex(szMsg, charsmax(szMsg), "\w%L", id, "CUPS_MAIN_INVITES");

	menu_additem(iMenu, szMsg, "3", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public CupMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);

	switch(iItem)
	{
		case 1:
			cmd_LobbyList(id);
		case 2:
			cmd_Lobby(id, id);
		case 3: 
			cmd_Invites(id);
	}

	return PLUGIN_HANDLED;
}

public cmd_LobbyList(id)
{
	if (!get_num_valid_lobbies())
	{
		cmd_MainMenu(id);
		return PLUGIN_HANDLED;
	}

	new szMsg[256], szLobbyName[64], szStatus[32];
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_LIST_TITLE");
	
	new iMenu = menu_create(szMsg, "LobbyList_Handler");

	for (new iLobby; iLobby <= MAX_PLAYERS; ++iLobby)
	{
		if (g_Cups[iLobby][cup_State] == State_Inactive ||
			g_Cups[iLobby][cup_State] == State_Pending)
			continue;

		new bool:isLocked = g_Cups[iLobby][cup_IsLocked];
		new numFilledSlots = get_num_players_in_lobby(iLobby);
		new numSlots = g_Cups[iLobby][cup_NumSlots];
		new bool:canJoin = !is_lobby_full(iLobby) && (!isLocked || is_invite_valid(id, iLobby));

		if (is_lobby_member(id, iLobby))
			canJoin = true;

		get_lobby_name(iLobby, szLobbyName, charsmax(szLobbyName));
		get_status(id, iLobby, szStatus, charsmax(szStatus));

		if (canJoin)
			formatex(szMsg, charsmax(szMsg), "\w'%s' - \y%d\w/\y%d \w- %s \d%s%s", 
				szLobbyName, numFilledSlots, numSlots, szStatus, 
				isLocked ? "[CLOSED]" : "", is_lobby_member(id, iLobby) ? " \y*" : "");
		else
			formatex(szMsg, charsmax(szMsg), "\d'%s' - %d/%d - %s %s%s", 
				szLobbyName, numFilledSlots, numSlots, szStatus, 
				isLocked ? "[CLOSED]" : "", is_lobby_member(id, iLobby) ? " \y*" : "");

		menu_additem(iMenu, szMsg, fmt("%d", iLobby), 0);
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public LobbyList_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);

	cmd_Lobby(id, iItem);

	return PLUGIN_HANDLED;
}

public cmd_Lobby(id, iLobby)
{
	g_CurrentLobby[id] = iLobby;
	new bool:isHost = (id == iLobby);

	if (isHost && g_Cups[iLobby][cup_State] == State_Inactive)
		create_lobby(iLobby);

	new szLobbyName[64];
	get_lobby_name(iLobby, szLobbyName, charsmax(szLobbyName));

	new szListOfPlayers[256];
	get_lobby_playerslist(id, iLobby, szListOfPlayers, charsmax(szListOfPlayers));

	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "\y%L", id, "CUPS_LOBBY_TITLE", szLobbyName);
	
	new iMenu = menu_create(szMsg, "LobbyMenu_Handler");

	if (isHost)
	{
		switch(g_Cups[iLobby][cup_State])
		{
			case State_Pending, State_Waiting:
			{
				formatex(szMsg, charsmax(szMsg), "\w%L: \y%L", id, "CUPS_LOBBY_CHECKS",
					id, g_Cups[iLobby][cup_IsCPAllow] ? "CUPS_ENABLE" : "CUPS_DISABLE");

				menu_additem(iMenu, szMsg, "1", 0);


				formatex(szMsg, charsmax(szMsg), "\w%L: \y%L", id, "CUPS_LOBBY_ROOMTYPE",
					id, g_Cups[iLobby][cup_IsLocked] ? "CUPS_LOBBY_LOCKED" : "CUPS_LOBBY_OPEN");

				menu_additem(iMenu, szMsg, "2", 0);


				formatex(szMsg, charsmax(szMsg), "\w%L: \y%d^n", id, "CUPS_LOBBY_NUMSLOTS",
					g_Cups[iLobby][cup_NumSlots]);

				menu_additem(iMenu, szMsg, "10", 0);

				if (g_Cups[iLobby][cup_State] != State_Pending)
				{
					menu_addtext2(iMenu, szListOfPlayers);

					formatex(szMsg, charsmax(szMsg), "\w%L", id, "CUPS_LOBBY_INVITE");
					menu_additem(iMenu, szMsg, "3", 0);

					formatex(szMsg, charsmax(szMsg), "\w%L^n", id, "CUPS_LOBBY_KICK");
					menu_additem(iMenu, szMsg, "4", 0);

					formatex(szMsg, charsmax(szMsg), "\w%L", id, "CUPS_LOBBY_STARTMATCH");
					menu_additem(iMenu, szMsg, "5", 0);

					formatex(szMsg, charsmax(szMsg), "\r%L", id, "CUPS_LOBBY_DELETE");
					menu_additem(iMenu, szMsg, "6", 0);
				}
				else
				{
					formatex(szMsg, charsmax(szMsg), "\y%L", id, "CUPS_LOBBY_CREATE");
					menu_additem(iMenu, szMsg, "6", 0);
				}
			}
			case State_Started:
			{
				formatex(szMsg, charsmax(szMsg), "\d%L: %L", id, "CUPS_LOBBY_CHECKS",
					id, g_Cups[iLobby][cup_IsCPAllow] ? "CUPS_ENABLE" : "CUPS_DISABLE");

				menu_additem(iMenu, szMsg, "1", 0);


				formatex(szMsg, charsmax(szMsg), "\d%L: %L^n", id, "CUPS_LOBBY_ROOMTYPE",
					id, g_Cups[iLobby][cup_IsLocked] ? "CUPS_LOBBY_LOCKED" : "CUPS_LOBBY_OPEN");

				menu_additem(iMenu, szMsg, "2", 0);


				formatex(szMsg, charsmax(szMsg), "\d%L: %d^n", id, "CUPS_LOBBY_NUMSLOTS",
					g_Cups[iLobby][cup_NumSlots]);

				menu_additem(iMenu, szMsg, "10", 0);

				menu_addtext2(iMenu, szListOfPlayers);


				formatex(szMsg, charsmax(szMsg), "\r%L", id, "CUPS_LOBBY_ENDMATCH");
				menu_additem(iMenu, szMsg, "5", 0);

				formatex(szMsg, charsmax(szMsg), "\r%L", id, "CUPS_LOBBY_DELETE");
				menu_additem(iMenu, szMsg, "6", 0);
			}
		}
	}
	else
	{
		new bool:isJoined = is_lobby_member(id, iLobby);
		new bool:isInviteValid = is_invite_valid(id, iLobby);

		formatex(szMsg, charsmax(szMsg), "\d%L: %L", id, "CUPS_LOBBY_CHECKS",
			id, g_Cups[iLobby][cup_IsCPAllow] ? "CUPS_ENABLE" : "CUPS_DISABLE");

		menu_additem(iMenu, szMsg, "1", 0);

		formatex(szMsg, charsmax(szMsg), "\d%L: %L^n", id, "CUPS_LOBBY_ROOMTYPE",
			id, g_Cups[iLobby][cup_IsLocked] ? "CUPS_LOBBY_LOCKED" : "CUPS_LOBBY_OPEN");

		menu_additem(iMenu, szMsg, "2", 0);

		formatex(szMsg, charsmax(szMsg), "\d%L: %d^n", id, "CUPS_LOBBY_NUMSLOTS",
			g_Cups[iLobby][cup_NumSlots]);

		menu_additem(iMenu, szMsg, "10", 0);

		menu_addtext2(iMenu, szListOfPlayers);

		if (isJoined)
		{
			formatex(szMsg, charsmax(szMsg), "\r%L", id, "CUPS_LOBBY_LEAVE");
			menu_additem(iMenu, szMsg, "6", 0);
		}
		else
		{
			if (!is_lobby_full(iLobby))
			{
				if (!g_Cups[iLobby][cup_IsLocked] || isInviteValid)
				{
					formatex(szMsg, charsmax(szMsg), "\y%L", id, "CUPS_LOBBY_JOIN");
					menu_additem(iMenu, szMsg, "6", 0);
				}

				if (isInviteValid)
				{
					formatex(szMsg, charsmax(szMsg), "\r%L", id, "CUPS_LOBBY_DECLINE");
					menu_additem(iMenu, szMsg, "7", 0);
				}
			}
		}
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public LobbyMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		cmd_MainMenu(id);

		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);

	new iLobby = g_CurrentLobby[id];
	new bool:isHost = (id == iLobby);

	if (g_Cups[iLobby][cup_State] == State_Inactive)
	{
		// invalid lobby
		return PLUGIN_HANDLED;
	}

	if (isHost)
	{
		switch(iItem)
		{
			case 1:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
					g_Cups[iLobby][cup_IsCPAllow] ^= true;

				cmd_Lobby(id, iLobby);
				return PLUGIN_HANDLED;
			}
			case 2:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
					g_Cups[iLobby][cup_IsLocked] ^= true;

				cmd_Lobby(id, iLobby);
				return PLUGIN_HANDLED;
			}
			case 10:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
				{
					g_Cups[iLobby][cup_NumSlots]++;

					if (g_Cups[iLobby][cup_NumSlots] > LOBBY_MAX_PLAYERS)
					{
						g_Cups[iLobby][cup_NumSlots] = 
							max(LOBBY_MIN_PLAYERS, get_num_players_in_lobby(iLobby));
					}
				}

				cmd_Lobby(id, iLobby);
				return PLUGIN_HANDLED;
			}
			case 3:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
					cmd_InvitePlayers(id);
			}
			case 4:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
					cmd_KickPlayers(id);
			}
			case 5:
			{
				if (g_Cups[iLobby][cup_State] != State_Started)
				{
					// Start match logic
					if (get_num_players_in_lobby(iLobby) > 1)
					{
						PreStartLobby(iLobby);
						return PLUGIN_HANDLED;
					}
				}
				else
				{
					// End match logic
					EndMatch(iLobby);
				}

				cmd_Lobby(id, iLobby);
			}
			case 6:
			{
				switch(g_Cups[iLobby][cup_State])
				{
					case State_Inactive:
						cmd_MainMenu(id);
					case State_Pending:
					{
						g_Cups[iLobby][cup_State] = State_Waiting;
						cmd_Lobby(id, iLobby);
					}
					default:
					{
						delete_lobby(iLobby);
						cmd_MainMenu(id);
					}
				}
			}
		}
	}
	else
	{
		switch(iItem)
		{
			case 1, 2, 10:
				cmd_Lobby(id, iLobby);
			case 6:
			{
				if (is_lobby_member(id, iLobby))
					cmd_Leave(id);
				else
				{
					if (	!is_lobby_full(iLobby) &&
						(!g_Cups[iLobby][cup_IsLocked] || is_invite_valid(id, iLobby)))
					{
						cmd_Join(id, iLobby);
					}
				}
			}
		}
	}

	return PLUGIN_HANDLED;
}

public cmd_InvitePlayers(id)
{
	new iLobby = get_lobby(id);

	if (iLobby < 0)
		return PLUGIN_HANDLED;

	new szMsg[256], szName[MAX_NAME_LENGTH];
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_INVITEPLAYERS_TITLE");
	
	new iMenu = menu_create(szMsg, "InvitePlayers_Handler");

	new hasPlayers = false;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (i == id || !is_user_connected(i) || 
			g_Cups[iLobby][cup_Players][i] ||
			g_Cups[iLobby][cup_Invites][i] || 
			is_user_bot(i))
			continue;

		if (get_active_cup(i) < 0)
		{
			hasPlayers = true;
			get_user_name(i, szName, charsmax(szName));
			menu_additem(iMenu, szName, fmt("%d", i), 0);
		}
	}

	if (!hasPlayers)
	{
		cmd_Lobby(id, id);
		return PLUGIN_HANDLED;
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public InvitePlayers_Handler(iLobby, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		cmd_Lobby(iLobby, iLobby);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[16], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new id = str_to_num(s_Data);
	
	menu_destroy(menu);

	if (get_active_cup(id) < 0)
	{
		new szName[MAX_NAME_LENGTH];
		get_user_name(id, szName, charsmax(szName));

		new szLobbyName[64];
		get_lobby_name(iLobby, szLobbyName, charsmax(szLobbyName));

		g_Cups[iLobby][cup_Invites][id] = true;
		client_print_color(id, print_team_default, "%L", id, "CUPS_CHAT_INVITED", szLobbyName);
		client_print_color(iLobby, print_team_default, "%L", id, "CUPS_CHAT_INVITED_SENT", szName);
		cmd_Invites(id);
	}

	cmd_InvitePlayers(iLobby);

	return PLUGIN_HANDLED;
}

public cmd_KickPlayers(id)
{
	new iLobby = get_lobby(id);

	if (iLobby < 0)
		return PLUGIN_HANDLED;

	new szMsg[256], szName[MAX_NAME_LENGTH];
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_KICKPLAYERS_TITLE");
	
	new iMenu = menu_create(szMsg, "KickPlayers_Handler");

	new hasPlayers = false;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (!g_Cups[iLobby][cup_Players][i] || i == id || is_user_bot(i))
			continue;

		hasPlayers = true;

		get_user_name(i, szName, charsmax(szName));
		menu_additem(iMenu, szName, fmt("%d", i), 0);
	}

	if (!hasPlayers)
	{
		cmd_Lobby(id, id);
		return PLUGIN_HANDLED;
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public KickPlayers_Handler(iLobby, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		cmd_Lobby(iLobby, iLobby);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[16], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new id = str_to_num(s_Data);
	
	menu_destroy(menu);

	g_Cups[iLobby][cup_Players][id] = false;

	if (!is_user_connected(id))
	{
		cmd_KickPlayers(iLobby);
		return PLUGIN_HANDLED;
	}

	new szName[MAX_NAME_LENGTH], szLobbyName[64];
	get_user_name(id, szName, charsmax(szName));
	get_lobby_name(iLobby, szLobbyName, charsmax(szLobbyName));

	client_print_color(id, print_team_default, "%L", id, "CUPS_CHAT_KICKED_PLAYER", szLobbyName);
	client_print_color(iLobby, print_team_default, "%L", id, "CUPS_CHAT_KICKED_LOBBY", szName);

	cmd_KickPlayers(iLobby);

	return PLUGIN_HANDLED;
}

public cmd_Invites(id)
{
	if (!get_num_invites(id))
	{
		cmd_MainMenu(id);
		return PLUGIN_HANDLED;
	}

	new szMsg[256], szLobbyName[64];
	formatex(szMsg, charsmax(szMsg), "%L", id, "CUPS_INVITES_TITLE");
	
	new iMenu = menu_create(szMsg, "Invites_Handler");

	for (new iLobby; iLobby <= MAX_PLAYERS; ++iLobby)
	{
		if (	iLobby == id || !is_invite_valid(id, iLobby))
			continue;

		new numFilledSlots = get_num_players_in_lobby(iLobby);
		new numSlots = g_Cups[iLobby][cup_NumSlots];

		get_lobby_name(iLobby, szLobbyName, charsmax(szLobbyName));

		formatex(szMsg, charsmax(szMsg), "\w'%s' - \y%d\w/\y%d", 
			szLobbyName, numFilledSlots, numSlots);

		menu_additem(iMenu, szMsg, fmt("%d", iLobby), 0);
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public Invites_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		cmd_MainMenu(id);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[16], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iLobby = str_to_num(s_Data);
	
	menu_destroy(menu);

	cmd_Lobby(id, iLobby);

	return PLUGIN_HANDLED;
}

public cmd_CupStart(id)
{
	if (g_Cups[id][cup_State] == State_Waiting)
		PreStartLobby(id);

	return PLUGIN_HANDLED;
}

public cmd_CupEnd(id)
{
	if (g_Cups[id][cup_State] == State_Started)
		EndMatch(id);

	return PLUGIN_HANDLED;
}

bool:can_join_lobby(iLobby)
{
	if (g_Cups[iLobby][cup_State] == State_Waiting)
		return true;

	return false;
}

bool:is_lobby_full(iLobby)
{
	if (get_num_players_in_lobby(iLobby) >= g_Cups[iLobby][cup_NumSlots])
		return true;

	return false;
}

bool:is_invite_valid(id, iLobby)
{
	if (!can_join_lobby(iLobby))
		return false;

	if (get_lobby(id) == iLobby)
		return false;

	if (!g_Cups[iLobby][cup_Invites][id])
		return false;

	if (is_lobby_full(iLobby))
		return false;

	return true;
}

bool:has_active_cup(id)
{
	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if ( g_Cups[i][cup_State] == State_Started &&
			g_Cups[i][cup_Players][id] && !g_Cups[i][cup_Time][id])
			return true;
	}

	return false;
}

get_active_cup(id)
{
	if (!has_active_cup(id))
		return -1;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if ( g_Cups[i][cup_State] == State_Started &&
			g_Cups[i][cup_Players][id])
			return i;
	}

	return -1;
}

bool:has_lobby(id)
{
	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if ( g_Cups[i][cup_State] != State_Inactive &&
			g_Cups[i][cup_Players][id])
			return true;
	}

	return false;
}

get_lobby(id)
{
	if (!has_lobby(id))
		return -1;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if ( g_Cups[i][cup_State] != State_Inactive &&
			g_Cups[i][cup_Players][id])
			return i;
	}

	return -1;
}

bool:is_lobby_member(id, iLobby)
{
	return g_Cups[iLobby][cup_Players][id];
}

get_lobby_playerslist(iPlayer, iLobby, szMsg[], iLen)
{
	new szName[MAX_NAME_LENGTH];
	formatex(szMsg, iLen, "\w%L:^n", iPlayer, "CUPS_LOBBY_PLAYERSLIST");

	for (new id; id <= MAX_PLAYERS; ++id)
	{
		if (!g_Cups[iLobby][cup_Players][id])
			continue;

		if (!is_user_connected(id))
			continue;

		get_user_name(id, szName, charsmax(szName));
		add(szMsg, iLen, fmt("^t%s^n", szName));
	}
}

get_lobby_name(iLobby, szLobbyName[], iLen)
{
	new szName[MAX_NAME_LENGTH];
	get_user_name(g_Cups[iLobby][cup_HostId], szName, charsmax(szName));

	formatex(szLobbyName, iLen, "%s's game", szName);
}

create_lobby(iLobby)
{
	g_Cups[iLobby][cup_HostId] = iLobby;
	g_Cups[iLobby][cup_NumSlots] = LOBBY_MIN_PLAYERS;
	g_Cups[iLobby][cup_IsCPAllow] = true;
	g_Cups[iLobby][cup_IsLocked] = false;
	g_Cups[iLobby][cup_State] = State_Pending;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		g_Cups[iLobby][cup_Players][i] = false; 
		g_Cups[iLobby][cup_Invites][i] = false; 
		g_Cups[iLobby][cup_Time][i] = 0.0;
	}

	g_Cups[iLobby][cup_Players][iLobby] = true;
}

delete_lobby(iLobby)
{
	EndMatch(iLobby);

	g_Cups[iLobby][cup_State] = State_Inactive;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (g_Cups[iLobby][cup_Players][i])
		{
			client_print_color(i, print_team_default, "%L", i, "CUPS_CHAT_LOBBY_DELETED");
			RemoveEffects(i);
		}

		g_Cups[iLobby][cup_Players][i] = false; 
		g_Cups[iLobby][cup_Invites][i] = false;
		g_Cups[iLobby][cup_Time][i] = 0.0;
	}
}

get_num_invites(id)
{
	new numInvites = 0;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (is_invite_valid(id, i))
			numInvites++;
	}

	return numInvites;
}

get_num_players_in_lobby(iLobby)
{
	new numPlayers = 0;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (g_Cups[iLobby][cup_Players][i])
			numPlayers++;
	}

	return numPlayers;
}

get_num_valid_lobbies()
{
	new numLobbies = 0;

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (	g_Cups[i][cup_State] != State_Inactive &&
			g_Cups[i][cup_State] != State_Pending)
			numLobbies++;
	}

	return numLobbies;
}

get_status(id, iLobby, szStatus[], iLen)
{
	switch(g_Cups[iLobby][cup_State])
	{
		case State_Inactive:
			formatex(szStatus, iLen, "%L", id, "CUPS_STATUS_INACTIVE");
		case State_Pending:
			formatex(szStatus, iLen, "%L", id, "CUPS_STATUS_PENDING");
		case State_Waiting:
			formatex(szStatus, iLen, "%L", id, "CUPS_STATUS_WAITING");
		case State_Started:
			formatex(szStatus, iLen, "%L", id, "CUPS_STATUS_STARTED");
	}
}

public cmd_Join(id, iLobby)
{
	cmd_Leave(id);

	g_Cups[iLobby][cup_Players][id] = true;
	g_Cups[iLobby][cup_Invites][id] = false;

	new szName[MAX_NAME_LENGTH];
	get_user_name(id, szName, charsmax(szName));

	for (new i; i <= MAX_PLAYERS; ++i)
	{
		if (g_Cups[iLobby][cup_Players][i])
			client_print_color(i, print_team_default, "%L", id, "CUPS_CHAT_JOIN_LOBBY", szName);
	}

	return PLUGIN_HANDLED;
}

public cmd_Leave(id)
{
	new iLobby = get_lobby(id);

	if (iLobby < 0)
		return PLUGIN_HANDLED;

	if (is_user_connected(id))
	{
		new szName[MAX_NAME_LENGTH];
		get_user_name(id, szName, charsmax(szName));

		for (new i; i <= MAX_PLAYERS; ++i)
		{
			if (g_Cups[iLobby][cup_Players][i])
				client_print_color(i, print_team_default, "%L", id, "CUPS_CHAT_LEAVE_LOBBY", szName);
		}
	}

	g_Cups[iLobby][cup_Players][id] = false;
	g_Cups[iLobby][cup_Invites][id] = false;

	if (id == iLobby)
		delete_lobby(iLobby);
	else
		EndMatchCheck(iLobby);

	return PLUGIN_HANDLED;
}

PreStartLobby(iLobby)
{
	if (get_num_players_in_lobby(iLobby) < 2)
		return;

	if (get_member(iLobby, m_iTeam) == CS_TEAM_SPECTATOR)
		amxclient_cmd(iLobby, "spec");

	amxclient_cmd(iLobby, "start");

	new Float:vOrigin[3];
	get_entvar(iLobby, var_origin, vOrigin);

	for (new id; id <= MAX_PLAYERS; ++id)
	{
		if (is_user_connected(id) && g_Cups[iLobby][cup_Players][id])
		{
			if (get_member(id, m_iTeam) == TEAM_SPECTATOR)
				amxclient_cmd(id, "spec");

			set_entvar(id, var_origin, vOrigin);
			set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_FROZEN);
			amxclient_cmd(id, "stop");

			set_user_noclip(id, 0);

			g_Cups[iLobby][cup_Time][id] = 0.0;
		}
	}

	g_Cups[iLobby][cup_State] = State_Started;

	StartTimer(iLobby);
}

StartTimer(iLobby)
{
	g_Timer[iLobby] = 10;
	set_task(1.0, "Task_StartTimer", TASK_START + iLobby, .flags = "b")
}

public RemoveEffects(id)
{
	if (get_entvar(id, var_flags) & FL_FROZEN)
	{
		set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
		set_entvar(id, var_view_ofs, Float:{0.0, 0.0, 12.0});
		set_entvar(id, var_flags, get_entvar(id, var_flags) | FL_DUCKING);
		set_entvar(id, var_fuser2, 0.0);
		set_entvar(id, var_flags, get_entvar(id, var_flags) & ~FL_FROZEN);
	}
}

public Task_StartTimer(iLobby)
{
	iLobby -= TASK_START;

	if (g_Cups[iLobby][cup_State] != State_Started)
	{
		for (new id; id <= MAX_PLAYERS; ++id)
		{
			if (g_Cups[iLobby][cup_Players][id])
				RemoveEffects(id);
		}

		remove_task(iLobby + TASK_START);
		return;
	}

	new Float:vOrigin[3];
	get_entvar(iLobby, var_origin, vOrigin);

	for (new id; id <= MAX_PLAYERS; ++id)
	{
		if (g_Cups[iLobby][cup_Players][id])
		{
			set_dhudmessage(255, 255, 255, -1.0, 0.8, 0, 3.0, 1.0, 0.0, 0.0);

			if (g_Timer[iLobby])
				show_dhudmessage(id, "The cup will start in [%d]", g_Timer[iLobby]);
			else
			{
				show_dhudmessage(id, "Go! Go! Go!");

				RemoveEffects(id);
				kz_start_timer(id);
				// ne prokatit, peredelat'
				// set_entvar(id, var_origin, vOrigin); 

				remove_task(iLobby + 15000);
			}
		}
	}

	g_Timer[iLobby]--;
}

EndMatchCheck(iLobby)
{
	if (g_Cups[iLobby][cup_State] != State_Started)
		return;

	new numFinished = 0;
	new numPlayers = get_num_players_in_lobby(iLobby);

	for (new i; i <= MAX_PLAYERS; ++i)
		if (g_Cups[iLobby][cup_Time][i])
			numFinished++;

	if (	numFinished == numPlayers ||
		numPlayers == 1)
		EndMatch(iLobby);
}

EndMatch(iLobby)
{
	remove_task(iLobby + TASK_ENDTIMER);

	if (g_Cups[iLobby][cup_State] != State_Started)
		return;

	g_Cups[iLobby][cup_State] = State_Waiting;

	for (new id; id <= MAX_PLAYERS; ++id)
	{
		if (g_Cups[iLobby][cup_Players][id])
		{
			// amxclient_cmd(id, "stop");
			RemoveEffects(id);
			client_print_color(id, print_team_default, "%L", id, "CUPS_CHAT_MATCH_END");
		}
	}
}
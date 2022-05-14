/*
*	Changelog:
*	
*	08.06.2021: 
*		- Fixed giving weapons on LoadPos
*	
*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <sqlx>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Sql SavePos"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserData
{
	ud_Uid,
	Float:ud_SavedTime,
	ud_SavedChecksNum,
	ud_SavedTeleNum,
	ud_SavedStucksNum,
	Float:ud_LastCP[3],
	Float:ud_LastPos[3],
	Float:ud_LastVel[3],
	ud_Weapon,
	bool:ud_hasSavedRun
}

new Handle:SQL_Tuple;

new g_UserData[MAX_PLAYERS + 1][UserData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("savepos", "cmd_SavePos");
	kz_register_cmd("saverun", "cmd_SavePos");
	kz_register_cmd("loadpos", "cmd_LoadPos");
	kz_register_cmd("loadrun", "cmd_LoadPos");

	for (new i; i <= MAX_PLAYERS; ++i)
		g_UserData[i][ud_Weapon] = -1;
}

public client_disconnected(id)
{
	if(kz_get_timer_state(id) != TIMER_DISABLED)
		SavePos(id);

	g_UserData[id][ud_Weapon] = -1;
}

public kz_timer_start_post(id) {
	deleteSavedRun(id);
}

public kz_timer_finish_post(id) {
	deleteSavedRun(id);
}

public kz_timer_stop_post(id) {
	deleteSavedRun(id);
}

public kz_sql_initialized()
{
	SQL_Tuple = kz_sql_get_tuple();
}

public kz_sql_data_recv(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_savedruns` \
		WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@UserRun_Callback", szQuery, szData, charsmax(szData));
}

public deleteSavedRun(id) {
	if (g_UserData[id][ud_hasSavedRun]) {
		g_UserData[id][ud_hasSavedRun] = false;

		new szQuery[512];
		formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_savedruns` WHERE `uid` = %d AND `mapid` = %d;",
			kz_sql_get_user_uid(id), kz_sql_get_map_uid());

		new szData[5];
		num_to_str(id, szData, charsmax(szData));
		SQL_ThreadQuery(SQL_Tuple, "@RunDeleted_Callback", szQuery, szData, charsmax(szData));
	}
}

@UserRun_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "UserRun_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	if(SQL_NumResults(hQuery) > 0)
	{
		new id = str_to_num(szData);

		g_UserData[id][ud_SavedTime] = Float:SQL_ReadResult(hQuery, 2);
		g_UserData[id][ud_SavedChecksNum] = SQL_ReadResult(hQuery, 4);
		g_UserData[id][ud_SavedTeleNum] = SQL_ReadResult(hQuery, 5);
		g_UserData[id][ud_SavedStucksNum] = SQL_ReadResult(hQuery, 6);

		g_UserData[id][ud_LastPos][0] = (Float:SQL_ReadResult(hQuery, 7));
		g_UserData[id][ud_LastPos][1] = (Float:SQL_ReadResult(hQuery, 8));
		g_UserData[id][ud_LastPos][2] = (Float:SQL_ReadResult(hQuery, 9));

		g_UserData[id][ud_LastCP][0] = (Float:SQL_ReadResult(hQuery, 10));
		g_UserData[id][ud_LastCP][1] = (Float:SQL_ReadResult(hQuery, 11));
		g_UserData[id][ud_LastCP][2] = (Float:SQL_ReadResult(hQuery, 12));

		g_UserData[id][ud_LastVel][0] = (Float:SQL_ReadResult(hQuery, 13));
		g_UserData[id][ud_LastVel][1] = (Float:SQL_ReadResult(hQuery, 14));
		g_UserData[id][ud_LastVel][2] = (Float:SQL_ReadResult(hQuery, 15));

		g_UserData[id][ud_Weapon] = SQL_ReadResult(hQuery, 16);

		g_UserData[id][ud_hasSavedRun] = true;

		LoadRun(id);
	}

	return PLUGIN_HANDLED;
}

LoadRun(id)
{
	kz_set_cp_num(id, g_UserData[id][ud_SavedChecksNum]);
	kz_set_tp_num(id, g_UserData[id][ud_SavedTeleNum]);

	new lastPos[PosStruct], lastCP[PosStruct], lastVel[PosStruct];

	lastPos[pos_x] = g_UserData[id][ud_LastPos][0];
	lastPos[pos_y] = g_UserData[id][ud_LastPos][1];
	lastPos[pos_z] = g_UserData[id][ud_LastPos][2];

	kz_set_last_pos(id, lastPos);

	lastCP[pos_x] = g_UserData[id][ud_LastCP][0];
	lastCP[pos_y] = g_UserData[id][ud_LastCP][1];
	lastCP[pos_z] = g_UserData[id][ud_LastCP][2];

	kz_set_last_cp(id, lastCP);

	kz_set_start_time(id, get_gametime() - g_UserData[id][ud_SavedTime]);

	kz_set_pause(id);

	kz_tp_last_pos(id);

	lastVel[pos_x] = g_UserData[id][ud_LastVel][0];
	lastVel[pos_y] = g_UserData[id][ud_LastVel][1];
	lastVel[pos_z] = g_UserData[id][ud_LastVel][2];
	
	kz_set_last_vel(id, lastVel);

	kz_set_min_rank(id, g_UserData[id][ud_Weapon]);
}

public cmd_SavePos(id)
{
	if(kz_get_timer_state(id) == TIMER_DISABLED)
	{
		return PLUGIN_HANDLED;
	}

	if(kz_get_timer_state(id) == TIMER_ENABLED)
		kz_set_pause(id);

	new szTime[32];
	UTIL_FormatTime(kz_get_actual_time(id), szTime, charsmax(szTime), true);

	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "\y%L", id, "SAVEPOS_TITLE",
		szTime,
		g_UserData[id][ud_SavedChecksNum], 
		g_UserData[id][ud_SavedTeleNum]);
	
	new iMenu = menu_create(szMsg, "SavePos_Handler");
	
	formatex(szMsg, charsmax(szMsg), "%L", id, "SAVEPOS_SAVE");
	
	menu_additem(iMenu, szMsg, "1", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public SavePos_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
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
		{
			SavePos(id);
		}
	}

	return PLUGIN_HANDLED;
}

SavePos(id)
{
	new iLastPos[3], iLastCp[3], iLastVel[3];
	kz_get_last_pos(id, iLastPos);
	kz_get_last_cp(id, iLastCp);
	kz_get_last_vel(id, iLastVel);

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		DELETE FROM `kz_savedruns` WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid()
		);

	SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

	formatex(szQuery, charsmax(szQuery), "\
		INSERT INTO `kz_savedruns` \
		(`uid`, `mapid`, `time`, `cp`, `tp`, \
		`pos_x`, `pos_y`, `pos_z`, \
		`lastcp_x`, `lastcp_y`, `lastcp_z`, \
	 	`weapon`, \
		`lastvel_x`, `lastvel_y`, `lastvel_z`) \
		\
		VALUES (%d, %d, %d, %d, %d, \
		%d, %d, %d, \
		%d, %d, %d, \
		%d, %d, %d, %d\
		);",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid(),
		kz_get_actual_time(id), kz_get_cp_num(id), kz_get_tp_num(id),
		iLastPos[0], iLastPos[1], iLastPos[2],
		iLastCp[0], iLastCp[1], iLastCp[2],
		kz_get_min_rank(id),
		iLastVel[0], iLastVel[1], iLastVel[2]
		);


	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@SavePos_Callback", szQuery, szData, charsmax(szData));
}

public cmd_LoadPos(id)
{
	if(!g_UserData[id][ud_hasSavedRun])
	{
		return PLUGIN_HANDLED;
	}

	new szTime[32];
	UTIL_FormatTime(g_UserData[id][ud_SavedTime], szTime, charsmax(szTime), true);

	new szWeapon[32];
	kz_get_weapon_name(g_UserData[id][ud_Weapon], szWeapon, charsmax(szWeapon));

	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "\y%L", id, "LOADPOS_TITLE",
		szTime, 
		g_UserData[id][ud_SavedChecksNum], 
		g_UserData[id][ud_SavedTeleNum],
		szWeapon);
	
	new iMenu = menu_create(szMsg, "LoadPos_Handler");
	
	formatex(szMsg, charsmax(szMsg), "%L", id, "LOADPOS_LOAD");
	
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "%L", id, "LOADPOS_NEW");
	
	menu_additem(iMenu, szMsg, "2", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public LoadPos_Handler(id, menu, item)
{
	if(item == MENU_EXIT || !g_UserData[id][ud_hasSavedRun])
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
		{
			LoadRun(id);
		}
		case 2:
		{
			amxclient_cmd(id, "start");
		}
	}

	return PLUGIN_HANDLED;
}

@SavePos_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "SavePos_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	g_UserData[id][ud_hasSavedRun] = true;

	client_print_color(id, print_team_default, "^4[KZ] ^1Your run was successfully saved.");

	return PLUGIN_HANDLED;
}

@WithoutAnswer_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "WithoutAnswer_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

@RunDeleted_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "WithoutAnswer_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	// new id = str_to_num(szData);

	// client_print_color(id, print_team_default, "^4[KZ] ^1Your previous saved run was deleted.");

	return PLUGIN_HANDLED;
}
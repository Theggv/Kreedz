#include <amxmodx>
#include <cstrike>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>

#pragma dynamic 16384

#define PLUGIN 	 	"[Kreedz] Sql Top"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"


enum _:UserDataStruct {
	bool:ud_hasRecord,
	bool:ud_isLoaded,
	Float:ud_bestTime,
	ud_cpCount,
	ud_tpCount,
};

new g_UserDataPro[MAX_PLAYERS + 1][UserDataStruct];
new g_UserDataNub[MAX_PLAYERS + 1][UserDataStruct];

new g_Candidates[MAX_PLAYERS + 1][RunStruct];

enum _:eForward {
	fwdNewProRecord,
	fwdNewNubRecord,
};

new g_Forwards[eForward];


new Handle:SQL_Tuple;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("top", "cmd_Top");
	kz_register_cmd("top15", "cmd_Top");
	kz_register_cmd("pro15", "cmd_ProTop");
	kz_register_cmd("nub15", "cmd_NubTop");
	kz_register_cmd("noob15", "cmd_NubTop");
	kz_register_cmd("weapontop", "cmd_WeaponTop");
	kz_register_cmd("cfr", "ShowBestScore");
	kz_register_cmd("rec", "cmd_ProRecord");
	kz_register_cmd("record", "cmd_ProRecord");

	initForwards();
}

initForwards() {
	g_Forwards[fwdNewProRecord] = CreateMultiForward("kz_top_new_pro_rec", ET_IGNORE, FP_CELL, FP_FLOAT);
	g_Forwards[fwdNewNubRecord] = CreateMultiForward("kz_top_new_nub_rec", ET_IGNORE, FP_CELL, FP_FLOAT);
}

public client_disconnected(id) {
	g_UserDataPro[id][ud_hasRecord] = false;
	g_UserDataPro[id][ud_isLoaded] = false;

	g_UserDataNub[id][ud_hasRecord] = false;
	g_UserDataNub[id][ud_isLoaded] = false;
}



public kz_timer_finish_post(id, runInfo[RunStruct]) {
	new szQuery[512];

	if (kz_get_min_rank(id) != 6) {
		formatex(szQuery, charsmax(szQuery), "\
SELECT * FROM `kz_weapontop` WHERE `uid` = %d AND `mapid` = %d AND `weapon` = %d;\
			", kz_sql_get_user_uid(id), kz_sql_get_map_uid(), kz_get_min_rank(id));

		new szData[64];
		formatex(szData, charsmax(szData), "%d %f", id, fTime);

		SQL_ThreadQuery(SQL_Tuple, "@findCurrentRecHandler", szQuery, szData, charsmax(szData));
	}
	else if(!kz_get_tp_num(id))
	{
		if( g_UserDataPro[id][ud_hasRecord] && 
			fTime < g_UserDataPro[id][ud_bestTime])
		{
			formatex(szQuery, charsmax(szQuery), "\
				UPDATE `kz_protop` SET `time` = %d, `date` = CURRENT_TIMESTAMP \
				WHERE `uid` = %d AND `mapid` = %d;",
				fTime, kz_sql_get_user_uid(id), kz_sql_get_map_uid());

			SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

			new szTime[32];
			UTIL_FormatTime(g_UserDataPro[id][ud_bestTime] - fTime,
				szTime, charsmax(szTime), true);

			client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_BEAT_RECORD", szTime);

			g_UserDataPro[id][ud_bestTime] = fTime;

			show_place_pro(id, fTime);
		}
		else if(!g_UserDataPro[id][ud_hasRecord])
		{
			formatex(szQuery, charsmax(szQuery), "\
				INSERT INTO `kz_protop` (`uid`, `mapid`, `time`) VALUES \
				(%d, %d, %d);",
				kz_sql_get_user_uid(id), kz_sql_get_map_uid(), fTime);

			SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

			g_UserDataPro[id][ud_bestTime] = fTime;
			g_UserDataPro[id][ud_hasRecord] = true;

			show_place_pro(id, fTime);
		}
		else
		{
			new szTime[32];
			UTIL_FormatTime(fTime - g_UserDataPro[id][ud_bestTime],
				szTime, charsmax(szTime), true);

			client_print_color(id, print_team_red, "%L", id, "KZ_CHAT_LOSE_RECORD", szTime);
		}
	}
	else
	{
		if( g_UserDataNub[id][ud_hasRecord] && 
			fTime < g_UserDataNub[id][ud_bestTime])
		{
			formatex(szQuery, charsmax(szQuery), "\
				UPDATE `kz_nubtop` SET `time` = %d, `date` = CURRENT_TIMESTAMP, \
				`cp` = %d, `tp` = %d \
				WHERE `uid` = %d AND `mapid` = %d;",
				fTime, kz_get_cp_num(id), kz_get_tp_num(id),
				kz_sql_get_user_uid(id), kz_sql_get_map_uid());

			SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

			new szTime[32];
			UTIL_FormatTime(g_UserDataNub[id][ud_bestTime] - fTime,
				szTime, charsmax(szTime), true);

			client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_BEAT_RECORD", szTime);

			g_UserDataNub[id][ud_bestTime] = fTime;
			g_UserDataNub[id][ud_cpCount] = kz_get_cp_num(id);
			g_UserDataNub[id][ud_tpCount] = kz_get_tp_num(id);

			show_place_nub(id, fTime);
		}
		else if(!g_UserDataNub[id][ud_hasRecord])
		{
			formatex(szQuery, charsmax(szQuery), "\
				INSERT INTO `kz_nubtop` (`uid`, `mapid`, `time`, `cp`, `tp`) VALUES \
				(%d, %d, %d, %d, %d);",
				kz_sql_get_user_uid(id), kz_sql_get_map_uid(), fTime,
				kz_get_cp_num(id), kz_get_tp_num(id));

			SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

			g_UserDataNub[id][ud_bestTime] = fTime;
			g_UserDataNub[id][ud_cpCount] = kz_get_cp_num(id);
			g_UserDataNub[id][ud_tpCount] = kz_get_tp_num(id);
			g_UserDataNub[id][ud_hasRecord] = true;

			show_place_nub(id, fTime);
		}
		else
		{
			new szTime[32];
			UTIL_FormatTime(fTime - g_UserDataNub[id][ud_bestTime],
				szTime, charsmax(szTime), true);

			client_print_color(id, print_team_red, "%L", id, "KZ_CHAT_LOSE_RECORD", szTime);
		}
	}
}

public kz_sql_initialized()
{
	SQL_Tuple = kz_sql_get_tuple();
}

public kz_sql_data_recv(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_protop` \
		WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@UserProTop_Callback", szQuery, szData, charsmax(szData));

	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_nubtop` \
		WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid());

	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@UserNubTop_Callback", szQuery, szData, charsmax(szData));
}

@findCurrentRecHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "findCurrentRecHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new szQuery[512];
	new szId[16], szTime[16];
	parse(szData, szId, 15, szTime, 15);
	new id = str_to_num(szId);
	new Float:fTime = str_to_float(szTime);

	if (SQL_NumResults(hQuery) > 0) {
		new Float:curTime = Float:SQL_ReadResult(hQuery, 0);
		new numTPs = SQL_ReadResult(hQuery, 5);

		if((!kz_get_tp_num(id) && numTPs) || 
			(fTime < curTime && !numTPs) || (fTime < curTime && kz_get_tp_num(id) && numTPs))
		{
			formatex(szQuery, charsmax(szQuery), "\
				UPDATE `kz_weapontop` SET `time` = %d, `date` = CURRENT_TIMESTAMP, \
				`cp` = %d, `tp` = %d \
				WHERE `uid` = %d AND `mapid` = %d AND `weapon` = %d;",
				fTime, (kz_get_tp_num(id) != 0 ? kz_get_cp_num(id) : 0) , kz_get_tp_num(id),
				kz_sql_get_user_uid(id), kz_sql_get_map_uid(), kz_get_min_rank(id));

			SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);
		}
	}
	else
	{
		formatex(szQuery, charsmax(szQuery), "\
			INSERT INTO `kz_weapontop` (`uid`, `mapid`, `time`, `cp`, `tp`, `weapon`) VALUES \
			(%d, %d, %d, %d, %d, %d);",
			kz_sql_get_user_uid(id), kz_sql_get_map_uid(), fTime,
			(kz_get_tp_num(id) != 0 ? kz_get_cp_num(id) : 0), 
			kz_get_tp_num(id), kz_get_min_rank(id));

		SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);
	}

	return PLUGIN_HANDLED;
}

@UserProTop_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "UserProTop_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		g_UserDataPro[id][ud_bestTime] = Float:SQL_ReadResult(hQuery, 2);
		SQL_ReadResult(hQuery, 3, g_UserDataPro[id][ud_date], 63);
		g_UserDataPro[id][ud_hasRecord] = true;
	}

	g_UserDataPro[id][ud_isLoaded] = true;

	if(g_UserDataPro[id][ud_isLoaded] && g_UserDataNub[id][ud_isLoaded])
	{
		set_task(1.0, "ShowBestScore", id);
	}

	return PLUGIN_HANDLED;
}

@UserNubTop_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "UserNubTop_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		g_UserDataNub[id][ud_bestTime] = Float:SQL_ReadResult(hQuery, 2);
		SQL_ReadResult(hQuery, 3, g_UserDataNub[id][ud_date], 63);
		g_UserDataNub[id][ud_hasRecord] = true;

		g_UserDataNub[id][ud_cpCount] = SQL_ReadResult(hQuery, 4);
		g_UserDataNub[id][ud_tpCount] = SQL_ReadResult(hQuery, 5);
	}

	g_UserDataNub[id][ud_isLoaded] = true;

	if(g_UserDataPro[id][ud_isLoaded] && g_UserDataNub[id][ud_isLoaded])
	{
		set_task(1.0, "ShowBestScore", id);
	}

	return PLUGIN_HANDLED;
}

public ShowBestScore(id)
{
	new szTime[32];

	if(g_UserDataPro[id][ud_hasRecord])
	{
		UTIL_FormatTime(g_UserDataPro[id][ud_bestTime],
			szTime, charsmax(szTime), true);

		client_print_color(id , print_team_default, "%L", id, "KZ_CHAT_BEST_PRO", szTime);
	}
	else if(g_UserDataNub[id][ud_hasRecord])
	{
		UTIL_FormatTime(g_UserDataNub[id][ud_bestTime],
			szTime, charsmax(szTime), true);

		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_BEST_NUB", 
			szTime, g_UserDataNub[id][ud_cpCount], g_UserDataNub[id][ud_tpCount]);
	}
	else
	{
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_RECORD");
	}

	return PLUGIN_HANDLED;
}

public cmd_Top(id)
{
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "Top");
	new iMenu = menu_create(szMsg, "TopMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "Pro top");
	
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "Nub top^n");
	
	menu_additem(iMenu, szMsg, "2", 0);

	formatex(szMsg, charsmax(szMsg), "Weapon top");
	
	menu_additem(iMenu, szMsg, "3", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public TopMenu_Handler(id, menu, item)
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
		case 1: cmd_ProTop(id);
		case 2: cmd_NubTop(id);
		case 3: cmd_WeaponTop(id);
	}

	return PLUGIN_HANDLED;
}

public cmd_ProTop(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT `last_name`, `time`, `date` FROM `kz_uid` as t1 INNER JOIN \
		(SELECT * FROM `kz_protop` WHERE `mapid` = %d ORDER BY TIME LIMIT 20) as t2 \
		ON t1.id = t2.uid ORDER BY TIME;",
		kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@ProTop_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@ProTop_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
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

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		new index = 1;
		new szBuffer[4096];
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));
		
		formatex(szBuffer, charsmax(szBuffer), "\
<!DOCTYPE html>\
<html>\
<head>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</head>\
<body>\
	<table>\
		<thead>\
			<tr>\
				<th scope=^"col^">Place</th>\
				<th scope=^"col^">Nick</th>\
				<th scope=^"col^">Time</th>\
			</tr>\
		</thead>\
		<tbody>\
			", szMapName);
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime;
		new szDate[64], szTime[32];
		new szAddString[256];
		
		while(SQL_MoreResults(hQuery))
		{
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);
			SQL_ReadResult(hQuery, 2, szDate, charsmax(szDate));

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);
			

			formatex(szAddString, charsmax(szAddString), "<tr>\
				<th scope=^"row^">%d\
				<td>%s\
				<td>%s\
				</tr>",
				index++, szName, szTime);

			add(szBuffer, charsmax(szBuffer), szAddString);
				
				
			SQL_NextRow(hQuery);
		}

		for(new i = index; i <= 20; i++)
		{
			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<td>\
				<td>\
				<td>\
				</tr>");

			add(szBuffer, charsmax(szBuffer), szAddString);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</tbody></table><footer>.</footer>");

		add(szBuffer, charsmax(szBuffer), szAddString);
		
		show_motd(id, szBuffer, szMapName);
	}
	else
	{
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_PRO_RECORDS");
	}

	return PLUGIN_HANDLED;
}

public cmd_NubTop(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT `last_name`, `time`, `date`, `cp`, `tp` FROM `kz_uid` as t1 INNER JOIN \
		(SELECT * FROM `kz_nubtop` WHERE `mapid` = %d ORDER BY TIME LIMIT 20) as t2 \
		ON t1.id = t2.uid ORDER BY TIME;",
		kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@NubTop_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@NubTop_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "NubTop_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		new index = 1;
		new szBuffer[3072];
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));
		
		formatex(szBuffer, charsmax(szBuffer), "\
<!DOCTYPE html>\
<html>\
<head>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</head>\
<body>\
	<table>\
		<thead>\
			<tr>\
				<th scope=^"col^">Place</th>\
				<th scope=^"col^">Nick</th>\
				<th scope=^"col^">Time</th>\
				<th scope=^"col^">CPs</th>\
				<th scope=^"col^">GCs</th>\
			</tr>\
		</thead>\
		<tbody>\
			", szMapName);
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime;
		new szDate[64], szTime[32];
		new szAddString[256];
		new iCPNum, iTPNum;
		
		while(SQL_MoreResults(hQuery))
		{
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);
			SQL_ReadResult(hQuery, 2, szDate, charsmax(szDate));
			iCPNum = SQL_ReadResult(hQuery, 3);
			iTPNum = SQL_ReadResult(hQuery, 4);

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<th scope=^"row^">%d\
				<td>%s\
				<td>%s\
				<td>%d\
				<td>%d",
				index++, szName, szTime, iCPNum, iTPNum);

			add(szBuffer, charsmax(szBuffer), szAddString);
				
			SQL_NextRow(hQuery);
		}

		for(new i = index; i <= 20; i++)
		{
			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<th scope=^"row^">\
				<td>\
				<td>\
				<td>\
				<td>");

			add(szBuffer, charsmax(szBuffer), szAddString);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</tbody></table><footer>.</footer>");

		add(szBuffer, charsmax(szBuffer), szAddString);
		
		show_motd(id, szBuffer, szMapName);
	}
	else
	{
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_NUB_RECORDS");
	}

	return PLUGIN_HANDLED;
}

public cmd_WeaponTop(id)
{
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "Weapon Top");
	new iMenu = menu_create(szMsg, "WeaponTopMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "AWP");
	menu_additem(iMenu, szMsg, "0", 0);

	formatex(szMsg, charsmax(szMsg), "M249");
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "M4A1");
	menu_additem(iMenu, szMsg, "2", 0);

	formatex(szMsg, charsmax(szMsg), "SG552");
	menu_additem(iMenu, szMsg, "3", 0);

	formatex(szMsg, charsmax(szMsg), "Famas");
	menu_additem(iMenu, szMsg, "4", 0);

	formatex(szMsg, charsmax(szMsg), "P90");
	menu_additem(iMenu, szMsg, "5", 0);

	formatex(szMsg, charsmax(szMsg), "Scout");
	menu_additem(iMenu, szMsg, "7", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public WeaponTopMenu_Handler(id, menu, item)
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

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT `last_name`, `time`, `date`, `cp`, `tp` FROM `kz_uid` as t1 INNER JOIN \
		((SELECT * FROM `kz_weapontop` \
         	WHERE `mapid` = %d AND `weapon` = %d AND `tp` = 0 ORDER BY TIME LIMIT 20) \
        UNION \
     	(SELECT * FROM `kz_weapontop` \
         	WHERE `mapid` = %d AND `weapon` = %d AND `tp` > 0 ORDER BY TIME LIMIT 20)) as t2 \
		ON t1.id = t2.uid \
		LIMIT 20; \
		",
		kz_sql_get_map_uid(), iItem, kz_sql_get_map_uid(), iItem);

	server_print(szQuery);

	new szData[64];
	formatex(szData, charsmax(szData), "%d %d", id, iItem);

	SQL_ThreadQuery(SQL_Tuple, "@WeaponTop_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@WeaponTop_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "WeaponTop_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new szId[16], szWeaponId[16], szWeapon[64];
	parse(szData, szId, 15, szWeaponId, 15);

	new id = str_to_num(szId);
	kz_get_weapon_name(str_to_num(szWeaponId), szWeapon, charsmax(szWeapon));

	if(SQL_NumResults(hQuery) > 0)
	{
		new index = 1;
		new szBuffer[4096];
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));
		
		formatex(szBuffer, charsmax(szBuffer), "\
<!DOCTYPE html>\
<html>\
<head>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</head>\
<body>\
	<table>\
		<thead>\
			<tr>\
				<th scope=^"col^">Place</th>\
				<th scope=^"col^">Nick</th>\
				<th scope=^"col^">Time</th>\
				<th scope=^"col^">CPs</th>\
				<th scope=^"col^">GCs</th>\
			</tr>\
		</thead>\
		<tbody>\
			", szMapName);
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime;
		new szDate[64], szTime[32];
		new szAddString[256];
		new iCPNum, iTPNum;

		while(SQL_MoreResults(hQuery))
		{
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);
			SQL_ReadResult(hQuery, 2, szDate, charsmax(szDate));
			iCPNum = SQL_ReadResult(hQuery, 3);
			iTPNum = SQL_ReadResult(hQuery, 4);

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<th scope=^"row^">%d\
				<td>%s\
				<td>%s\
				<td>%d\
				<td>%d",
				index++, szName, szTime, iCPNum, iTPNum);

			add(szBuffer, charsmax(szBuffer), szAddString);
				
			SQL_NextRow(hQuery);
		}

		for(new i = index; i <= 20; i++)
		{
			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<th scope=^"row^">\
				<td>\
				<td>\
				<td>\
				<td>");

			add(szBuffer, charsmax(szBuffer), szAddString);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</tbody></table><footer>.</footer>");

		add(szBuffer, charsmax(szBuffer), szAddString);
		
		show_motd(id, szBuffer, fmt("%s - %s", szMapName, szWeapon));
	}
	else
	{
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_WEAPON_RECORDS",
			szWeapon);
	}

	cmd_WeaponTop(id);

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

public show_place_pro(id, Float:fTime)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT COUNT(*) FROM `kz_protop` \
		WHERE `time` <= %d AND `mapid` = %d \
 		ORDER BY `time` DESC;", 
		fTime, kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@ProPlace_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@ProPlace_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "ProPlace_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		new iPlace = SQL_ReadResult(hQuery, 0);

		new szName[MAX_NAME_LENGTH];
		get_user_name(id, szName, charsmax(szName));

		if(iPlace > 3)
			client_print_color(0, print_team_default, 
				"^4[KZ]^1 %s achieved %d ^1place in the pro top!", szName, iPlace);
		else if(iPlace == 3)
			client_print_color(0, print_team_blue, 
				"^4[KZ]^1 %s achieved^3 3rd^1 place in the pro top!", szName);
		else if(iPlace == 2)
			client_print_color(0, print_team_grey, 
				"^4[KZ]^1 %s achieved^3 2nd^1 place in the pro top!", szName);
		else if(iPlace <= 1)
		{
			client_print_color(0, print_team_red, 
				"^4[KZ]^1 %s achieved^3 1st^1 place in the pro top!", szName);
		}

		new iRet;

		if(iPlace <= 1)
		{
			ExecuteForward(g_Forwards[fwdNewProRecord], iRet, id, g_UserDataPro[id][ud_bestTime]);
		}
		else
		{
			ExecuteForward(g_Forwards[fwdNewProRecord], iRet, id, 0.0);
		}
	}

	return PLUGIN_HANDLED;
}

public show_place_nub(id, Float:fTime)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT COUNT(*) FROM `kz_nubtop` \
		WHERE `time` <= %d AND `mapid` = %d \
 		ORDER BY `time` DESC;",
		fTime, kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@NubPlace_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}


@NubPlace_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "NubPlace_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		new iPlace = SQL_ReadResult(hQuery, 0);

		new szName[MAX_NAME_LENGTH];
		get_user_name(id, szName, charsmax(szName));

		if(iPlace > 3)
			client_print_color(0, print_team_default, 
				"^4[KZ]^1 %s achieved %d^1 place in the nub top!", szName, iPlace);
		else if(iPlace == 3)
			client_print_color(0, print_team_blue, 
				"^4[KZ]^1 %s achieved^3 3rd^1 place in the nub top!", szName);
		else if(iPlace == 2)
			client_print_color(0, print_team_grey, 
				"^4[KZ]^1 %s achieved^3 2nd^1 place in the nub top!", szName);
		else if(iPlace <= 1)
			client_print_color(0, print_team_red, 
				"^4[KZ]^1 %s achieved^3 1st^1 place in the nub top!", szName);
	}

	return PLUGIN_HANDLED;
}

public cmd_ProRecord(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT `last_name`, `time` FROM `kz_uid` as t1 INNER JOIN \
		(SELECT * FROM `kz_protop` WHERE `mapid` = %d ORDER BY TIME LIMIT 1) as t2 \
		ON t1.id = t2.uid;",
		kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@ProRecord_Callback", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@ProRecord_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
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

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		new szName[MAX_NAME_LENGTH];
		new Float:fTime, szTime[32];

		SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
		fTime = Float:SQL_ReadResult(hQuery, 1);

		UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

		client_print_color(id, print_team_default, "^4[KZ] ^1Pro record: [^4%s^1] by ^3%s^1.", 
			szTime, szName);
	}
	else
	{
		client_print_color(id, print_team_red, "^4[KZ] ^1Pro record: ^3No data^1.");
	}

	return PLUGIN_HANDLED;
}
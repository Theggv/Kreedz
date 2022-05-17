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

new Handle:SQL_Tuple;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("top", "cmd_Top");
	kz_register_cmd("top15", "cmd_Top");
	kz_register_cmd("pro15", "cmd_ProTop");
	kz_register_cmd("nub15", "cmd_NubTop");
	kz_register_cmd("noob15", "cmd_NubTop");
	kz_register_cmd("weapontop", "cmd_WeaponTop");
	kz_register_cmd("rec", "cmd_ProRecord");
	kz_register_cmd("record", "cmd_ProRecord");
}

public kz_sql_initialized()
{
	SQL_Tuple = kz_sql_get_tuple();
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
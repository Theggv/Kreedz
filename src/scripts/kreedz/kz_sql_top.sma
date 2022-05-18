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

new const g_szTopCSS[] = "*{box-sizing:border-box;font-family:-apple-system,\
BlinkMacSystemFont,Segoe UI,Roboto,Oxygen,Ubuntu,Cantarell,Fira Sans,Droid Sans,\
Helvetica Neue,sans-serif}\
body,html{padding:0;margin:0;background-color:#1b1b1b;color:#ccc}\
.container{margin:24px auto;width:600px}\
table{width:100%;background-color:#4e4e4e;border-radius:.5rem}\
td,th{padding:.5rem}th{font-weight:700}";

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("top", "cmdTop");
	kz_register_cmd("top15", "cmdTop");
	kz_register_cmd("pro15", "cmdProTop");
	kz_register_cmd("nub15", "cmdNubTop");
	kz_register_cmd("noob15", "cmdNubTop");
	kz_register_cmd("rec", "cmdProRecord");
	kz_register_cmd("record", "cmdProRecord");
}

public kz_sql_initialized() {
	SQL_Tuple = kz_sql_get_tuple();
}

/**
*	------------------------------------------------------------------
*	Commands
*	------------------------------------------------------------------
*/


public cmdTop(id) {
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "Top");
	new iMenu = menu_create(szMsg, "@topMenuHandler");

	formatex(szMsg, charsmax(szMsg), "Pro top");
	menu_additem(iMenu, szMsg, "1");

	formatex(szMsg, charsmax(szMsg), "Nub top^n");
	menu_additem(iMenu, szMsg, "2");

	formatex(szMsg, charsmax(szMsg), "Weapon pro top");
	menu_additem(iMenu, szMsg, "3");

	formatex(szMsg, charsmax(szMsg), "Weapon nub top");
	menu_additem(iMenu, szMsg, "4");

	menu_display(id, iMenu);

	return PLUGIN_HANDLED;
}

@topMenuHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static szData[32], szName[64], access, callback;
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);
	new iItem = str_to_num(szData);
	
	menu_destroy(menu);

	switch (iItem) {
		case 1: cmdProTop(id);
		case 2: cmdNubTop(id);
		case 3: weaponTopMenu(id, true);
		case 4: weaponTopMenu(id, false);
	}

	return PLUGIN_HANDLED;
}

public cmdProTop(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time`, `cp`, `tp` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` \
WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 AND `is_pro_record` = 1 ORDER BY `time` LIMIT 15) as record \
ON user.id = record.user_id ORDER BY `time`;",
		kz_sql_get_map_uid());

	new szData[32];
	formatex(szData, charsmax(szData), "%d %d %d", id, true, WPN_USP);
	SQL_ThreadQuery(SQL_Tuple, "@recordsTableHandler", szQuery, szData, charsmax(szData));

	cmdTop(id);
	return PLUGIN_HANDLED;
}

public cmdNubTop(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time`, `cp`, `tp` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` \
WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 AND `is_pro_record` = 0 ORDER BY `time` LIMIT 15) as record \
ON user.id = record.user_id ORDER BY `time`;",
		kz_sql_get_map_uid());

	new szData[32];
	formatex(szData, charsmax(szData), "%d %d %d", id, false, WPN_USP);
	SQL_ThreadQuery(SQL_Tuple, "@recordsTableHandler", szQuery, szData, charsmax(szData));

	cmdTop(id);
	return PLUGIN_HANDLED;
}

public weaponTopMenu(id, bool:isProTop) {
	new szMsg[256];

	if (isProTop)
		formatex(szMsg, charsmax(szMsg), "Weapon Pro Top");
	else
		formatex(szMsg, charsmax(szMsg), "Weapon Nub Top");

	new iMenu = menu_create(szMsg, "@weaponTopMenuHandler");

	for (new weapon = 0; weapon < WeaponsEnum; ++weapon) {
		if (weapon == WPN_USP) continue;

		kz_get_weapon_name(weapon, szMsg, charsmax(szMsg));
		menu_additem(iMenu, szMsg, fmt("%d %d", weapon, isProTop));
	}

	menu_display(id, iMenu);
}

@weaponTopMenuHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		cmdTop(id);
		
		return PLUGIN_HANDLED;
	}
	
	static szData[32], szName[64], access, callback;
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);

	new szWeapon[16], szIsProTop[16];
	parse(szData, szWeapon, 15, szIsProTop, 15);

	new weapon = str_to_num(szWeapon);
	new bool:isProTop = bool:str_to_num(szIsProTop);

	menu_destroy(menu);

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time`, `cp`, `tp` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` \
WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = %d AND `is_pro_record` = %d ORDER BY `time` LIMIT 15) as record \
ON user.id = record.user_id ORDER BY `time`;",
		kz_sql_get_map_uid(), weapon, isProTop);

	formatex(szData, charsmax(szData), "%d %d %d", id, isProTop, weapon);
	SQL_ThreadQuery(SQL_Tuple, "@recordsTableHandler", szQuery, szData, charsmax(szData));

	weaponTopMenu(id, isProTop);

	return PLUGIN_HANDLED;
}

public cmdProRecord(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 ORDER BY TIME LIMIT 1) as rec \
ON user.id = rec.user_id;",
		kz_sql_get_map_uid());

	new szData[16];
	formatex(szData, charsmax(szData), "%d", id);
	SQL_ThreadQuery(SQL_Tuple, "@proRecordHandler", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Query handlers
*	------------------------------------------------------------------
*/


@recordsTableHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "recordsTableHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new szId[16], szIsPro[16], szWeapon[16];
	parse(szData, szId, 15, szIsPro, 15, szWeapon, 15);

	new id = str_to_num(szId);
	new bool:isPro = bool:str_to_num(szIsPro);
	new weapon = str_to_num(szWeapon);

	if (SQL_NumResults(hQuery) > 0) {
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));

		new szBuffer[4096], szAddString[256];
		UTIL_GenerateHtmlHeader(szBuffer, charsmax(szBuffer), isPro, weapon);

		new index = 1;
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime, szTime[32];
		new cpCount, tpCount;
		
		while (SQL_MoreResults(hQuery)) {
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);
			cpCount = SQL_ReadResult(hQuery, 2);
			tpCount = SQL_ReadResult(hQuery, 3);

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

			if (isPro) {
				formatex(szAddString, charsmax(szAddString), "\
<tr>\
<th scope=^"row^">%d\
<td>%s\
<td>%s", index++, szName, szTime);
			}
			else {
				formatex(szAddString, charsmax(szAddString), "\
<tr>\
<th scope=^"row^">%d\
<td>%s\
<td>%d\
<td>%d\
<td>%s", index++, szName, cpCount, tpCount, szTime);
			}

			add(szBuffer, charsmax(szBuffer), szAddString);
				
			SQL_NextRow(hQuery);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</tbody></table>");

		add(szBuffer, charsmax(szBuffer), szAddString);
		
		show_motd(id, szBuffer, szMapName);
	}
	else {
		if (isPro)
			client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_PRO_RECORDS");
		else
			client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_NUB_RECORDS");
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

@proRecordHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if (SQL_NumResults(hQuery) > 0) {
		new szName[MAX_NAME_LENGTH];
		new Float:fTime, szTime[32];

		SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
		fTime = Float:SQL_ReadResult(hQuery, 1);

		UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

		client_print_color(id, print_team_default, "^4[KZ] ^1Pro record: [^4%s^1] by ^3%s^1.", 
			szTime, szName);
	}
	else {
		client_print_color(id, print_team_red, "^4[KZ] ^1Pro record: ^3No data^1.");
	}

	return PLUGIN_HANDLED;
}

@dummyHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	SQL_FreeHandle(hQuery);

	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Utils
*	------------------------------------------------------------------
*/

stock UTIL_GenerateHtmlHeader(szBuffer[], len, bool:isPro, weapon = 6) {
	new szWeaponName[32], szTitle[128], szMapName[64];

	kz_get_weapon_name(weapon, szWeaponName, charsmax(szWeaponName));
	get_mapname(szMapName, charsmax(szMapName));

	if (isPro)
		formatex(szTitle, charsmax(szTitle), "Pro records on %s (%s)", szMapName, szWeaponName);
	else
		formatex(szTitle, charsmax(szTitle), "Nub records on %s (%s)", szMapName, szWeaponName);
	
	formatex(szBuffer, len, "\
<!DOCTYPE HTML PUBLIC ^"-//W3C//DTD HTML 4.01//EN^"\
   ^"http://www.w3.org/TR/html4/strict.dtd^">\
<HTML>\
<HEAD>\
	<style>%s</style>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</HEAD>\
<BODY>\
	<H2>%s</H2>\
	<TABLE>\
		<TBODY>\
			", g_szTopCSS, szMapName, szTitle);

	if (isPro) {
		format(szBuffer, len, "%s\
<TR>\
	<TH width=^"10%^" scope=^"col^">Place</TH>\
	<TH width=^"50%^" scope=^"col^">Nick</TH>\
	<TH width=^"40%^" scope=^"col^">Time</TH>\
</TR>\
<TBODY>\
		", szBuffer);
	}
	else {
		format(szBuffer, len, "%s\
<TR>\
	<TH width=^"10%^" scope=^"col^">Place</TH>\
	<TH width=^"40%^" scope=^"col^">Nick</TH>\
	<TH width=^"15%^" scope=^"col^">CPs</TH>\
	<TH width=^"15%^" scope=^"col^">GCs</TH>\
	<TH width=^"20%^" scope=^"col^">Time</TH>\
</TR>\
<TBODY>\
		", szBuffer);
	}
}
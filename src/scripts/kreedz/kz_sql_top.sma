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

public cmdTop(id) {
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "Top");
	new iMenu = menu_create(szMsg, "TopMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "Pro top");
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "Nub top");
	menu_additem(iMenu, szMsg, "2", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public TopMenu_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);

	switch (iItem) {
		case 1: cmdProTop(id);
		case 2: cmdNubTop(id);
	}

	return PLUGIN_HANDLED;
}

public cmdProTop(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` \
WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 AND `tp` = 0 ORDER BY `time` LIMIT 15) as record \
ON user.id = record.user_id ORDER BY `time`;",
		kz_sql_get_map_uid());

	new szData[16];
	formatex(szData, charsmax(szData), "%d", id);
	SQL_ThreadQuery(SQL_Tuple, "@proTopHandler", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@proTopHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if (SQL_NumResults(hQuery) > 0) {
		new index = 1;
		new szBuffer[4096];
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));
		
		formatex(szBuffer, charsmax(szBuffer), "\
<!DOCTYPE HTML PUBLIC ^"-//W3C//DTD HTML 4.01//EN^"\
   ^"http://www.w3.org/TR/html4/strict.dtd^">\
<HTML>\
<HEAD>\
	<style>%s</style>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</HEAD>\
<BODY>\
	<H2>Pro records on %s</H2>\
	<TABLE>\
		<THEAD>\
			<TR>\
				<TH width=^"10%^" scope=^"col^">Place</TH>\
				<TH width=^"50%^" scope=^"col^">Nick</TH>\
				<TH width=^"40%^" scope=^"col^">Time</TH>\
			</TR>\
		</THEAD>\
		<TBODY>\
			", g_szTopCSS, szMapName, szMapName);
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime;
		new szTime[32];
		new szAddString[256];
		
		while (SQL_MoreResults(hQuery)) {
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

			formatex(szAddString, charsmax(szAddString), "<TR>\
				<TH scope=^"row^">%d</TH>\
				<TD>%s\
				<TD>%s\
				</TR>",
				index++, szName, szTime);

			add(szBuffer, charsmax(szBuffer), szAddString);
				
			SQL_NextRow(hQuery);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</TBODY></TABLE>");

		add(szBuffer, charsmax(szBuffer), szAddString);

		show_motd(id, szBuffer, szMapName);
	}
	else {
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_PRO_RECORDS");
	}

	return PLUGIN_HANDLED;
}

public cmdNubTop(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time`, `cp`, `tp` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` \
WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 AND `tp` > 0 ORDER BY `time` LIMIT 15) as record \
ON user.id = record.user_id ORDER BY `time`;",
		kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@nubTopHandler", szQuery, szData, charsmax(szData));

	return PLUGIN_HANDLED;
}

@nubTopHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch(QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "nubTopHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if (SQL_NumResults(hQuery) > 0) {
		new index = 1;
		new szBuffer[3072];
		new szMapName[64];
		get_mapname(szMapName, charsmax(szMapName));

		formatex(szBuffer, charsmax(szBuffer), "\
<!DOCTYPE HTML PUBLIC ^"-//W3C//DTD HTML 4.01//EN^"\
   ^"http://www.w3.org/TR/html4/strict.dtd^">\
<HTML>\
<HEAD>\
	<style>%s</style>\
	<meta charset=^"utf-8^">\
	<title>%s</title>\
</HEAD>\
<BODY>\
	<H2>Nub records on %s</H2>\
	<TABLE>\
		<THEAD>\
			<TR>\
				<TH width=^"10%^" scope=^"col^">Place</TH>\
				<TH width=^"40%^" scope=^"col^">Nick</TH>\
				<TH width=^"15%^" scope=^"col^">CPs</TH>\
				<TH width=^"15%^" scope=^"col^">GCs</TH>\
				<TH width=^"20%^" scope=^"col^">Time</TH>\
			</TR>\
		</THEAD>\
		<TBODY>\
			", g_szTopCSS, szMapName, szMapName);
		
		new szName[MAX_NAME_LENGTH];
		new Float:fTime;
		new szTime[32];
		new szAddString[256];
		new cpCount, tpCount;
		
		while (SQL_MoreResults(hQuery)) {
			SQL_ReadResult(hQuery, 0, szName, charsmax(szName));
			fTime = Float:SQL_ReadResult(hQuery, 1);
			cpCount = SQL_ReadResult(hQuery, 2);
			tpCount = SQL_ReadResult(hQuery, 3);

			UTIL_FormatTime(fTime, szTime, charsmax(szTime), true);

			formatex(szAddString, charsmax(szAddString), "\
				<tr>\
				<th scope=^"row^">%d\
				<td>%s\
				<td>%d\
				<td>%d\
				<td>%s",
				index++, szName, cpCount, tpCount, szTime);

			add(szBuffer, charsmax(szBuffer), szAddString);
				
			SQL_NextRow(hQuery);
		}

		formatex(szAddString, charsmax(szAddString), "\
			</tbody></table><footer>.</footer>");

		add(szBuffer, charsmax(szBuffer), szAddString);
		
		show_motd(id, szBuffer, szMapName);
	}
	else {
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_NUB_RECORDS");
	}

	return PLUGIN_HANDLED;
}

@dummyHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

public cmdProRecord(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `time` FROM `kz_uid` as user INNER JOIN \
(SELECT * FROM `kz_records` WHERE `map_id` = %d AND `aa` = 0 AND `weapon` = 6 ORDER BY TIME LIMIT 1) as rec \
ON user.id = rec.user_id;",
		kz_sql_get_map_uid());

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@proRecordHandler", szQuery, szData, charsmax(szData));

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
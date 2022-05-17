#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Sql Top"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"


new Handle:SQL_Tuple;

new g_szRecordsFrontendUrl[128];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("top", "cmd_Top");
	kz_register_cmd("top15", "cmd_Top");
	kz_register_cmd("pro15", "cmd_ProTop");
	kz_register_cmd("nub15", "cmd_NubTop");
	kz_register_cmd("noob15", "cmd_NubTop");
	kz_register_cmd("rec", "cmd_ProRecord");
	kz_register_cmd("record", "cmd_ProRecord");
}

public plugin_cfg() {
	new szCfgDir[256];
	get_configsdir(szCfgDir, charsmax(szCfgDir));

	format(szCfgDir, charsmax(szCfgDir), "%s/kreedz.cfg", szCfgDir);

	LoadConfig(szCfgDir);
}

public kz_sql_initialized()
{
	SQL_Tuple = kz_sql_get_tuple();
}

public cmd_Top(id) {
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
		case 1: cmd_ProTop(id);
		case 2: cmd_NubTop(id);
	}

	return PLUGIN_HANDLED;
}

public cmd_ProTop(id) {
	new szMap[64], szUrl[256];
	get_mapname(szMap, charsmax(szMap));

	formatex(szUrl, charsmax(szUrl), "%s/records?type=pro&mapName=%s", 
		g_szRecordsFrontendUrl, szMap);
	
	show_motd(id, szUrl, szMap);

	return PLUGIN_HANDLED;
}


public cmd_NubTop(id) {
	new szMap[64], szUrl[256];
	get_mapname(szMap, charsmax(szMap));

	formatex(szUrl, charsmax(szUrl), "%s/records?type=nub&mapName=%s", 
		g_szRecordsFrontendUrl, szMap);
	
	show_motd(id, szUrl, szMap);

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

LoadConfig(szFileName[]) {
	if (!file_exists(szFileName)) return;
	
	new szData[256];
	new hFile = fopen(szFileName, "rt");

	while (hFile && !feof(hFile)) {
		fgets(hFile, szData, charsmax(szData));
		trim(szData);
		
		// Skip Comment and Empty Lines
		if (containi(szData, ";") > -1 || equal(szData, "") || equal(szData, "//", 2))
			continue;
		
		static szKey[64], szValue[64];

		strtok(szData, szKey, 63, szValue, 63, '=');

		trim(szKey);
		trim(szValue);
		remove_quotes(szValue);

		if (equal(szKey, "kz_records_frontend_url"))
			copy(g_szRecordsFrontendUrl, charsmax(g_szRecordsFrontendUrl), szValue);
	}
	
	if (hFile) {
		fclose(hFile);
	}
}
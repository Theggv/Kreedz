#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>

#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Sql Core"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:ConnectionStruct
{
	eHostName[64],
	eUser[64],
	ePassWord[64],
	eDataBase[64]
}

enum _:eForwards
{
	fwd_Initialized,
	fwd_InfoReceived,
}

new Handle:SQL_Tuple;
new Handle:SQL_Connection;

new g_ConnInfo[ConnectionStruct];

new g_NumInitQueries;

new g_UserData[MAX_PLAYERS + 1];
new g_MapId;

new g_Forwards[eForwards];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Forwards[fwd_Initialized] = 	CreateMultiForward("kz_sql_initialized", ET_IGNORE);
	g_Forwards[fwd_InfoReceived] = 	CreateMultiForward("kz_sql_data_recv", ET_IGNORE, FP_CELL);

	register_srvcmd("amx_updatecharset", "cmd_UpdateEncoding");
}

public plugin_cfg()
{
	new szCfgDir[256];
	get_configsdir(szCfgDir, charsmax(szCfgDir));

	format(szCfgDir, charsmax(szCfgDir), "%s/kreedz.cfg", szCfgDir);

	LoadConfig(szCfgDir);

	mkdir("addons/amxmodx/logs/kz_db_log");
	
	new szError[512], iError;

	SQL_Tuple = SQL_MakeDbTuple(g_ConnInfo[eHostName], g_ConnInfo[eUser], g_ConnInfo[ePassWord], g_ConnInfo[eDataBase]);
	SQL_Connection = SQL_Connect(SQL_Tuple, iError, szError, charsmax(szError));

	if (SQL_Connection == Empty_Handle)
	{
		UTIL_LogToFile(MYSQL_LOG, "ERROR", "plugin_cfg", "[%d] %s", iError, szError);
		set_fail_state(szError);
	}

	SQL_SetCharset(SQL_Tuple, "utf8");
	
	SQL_FreeHandle(SQL_Connection);

	init_tables();
}

public plugin_end()
{
	SQL_FreeHandle(SQL_Tuple);
}

public plugin_natives()
{
	register_native("kz_sql_get_user_uid", "native_get_user_uid", 1);
	register_native("kz_sql_get_map_uid", "native_get_map_uid", 1);
	register_native("kz_sql_get_tuple", "native_get_tuple", 1);
	register_native("db_update_user_info", "native_db_update_user_info", 1);
}

public native_get_user_uid(id)
{
	return g_UserData[id];
}

public native_get_map_uid()
{
	return g_MapId;
}

public native_db_update_user_info(id)
{
	client_putinserver(id);
}

public Handle:native_get_tuple()
{
	return SQL_Tuple;
}

public init_tables()
{
	g_NumInitQueries = 6;

	new szQuery[2048];

	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_uid` (\
		`id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,\
		`steam_id` varchar(37) NOT NULL UNIQUE,\
		`last_name` varchar(32) DEFAULT NULL\
		) DEFAULT CHARSET utf8;\
	\
	CREATE TABLE IF NOT EXISTS `kz_maps` (\
		`id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,\
		`mapname` varchar(64) NOT NULL UNIQUE\
		) DEFAULT CHARSET utf8;\
		");

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);
	
	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_protop` (\
		`uid` int(11) NOT NULL,\
		`mapid` int(11) NOT NULL,\
		`time` int(11) NOT NULL,\
		`date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
		FOREIGN KEY (uid) REFERENCES kz_uid(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE,\
		FOREIGN KEY (mapid) REFERENCES kz_maps(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8;\
	\
	CREATE TABLE IF NOT EXISTS `kz_nubtop` (\
		`uid` int(11) NOT NULL,\
		`mapid` int(11) NOT NULL,\
		`time` int(11) NOT NULL,\
		`date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
		`cp` int(11) NOT NULL DEFAULT 0,\
		`tp` int(11) NOT NULL DEFAULT 0,\
		FOREIGN KEY (uid) REFERENCES kz_uid(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE,\
		FOREIGN KEY (mapid) REFERENCES kz_maps(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8;\
		");

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);

	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_weapontop` (\
		`uid` int(11) NOT NULL,\
		`mapid` int(11) NOT NULL,\
		`time` int(11) NOT NULL,\
		`date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
		`cp` int(11) NOT NULL DEFAULT 0,\
		`tp` int(11) NOT NULL DEFAULT 0,\
		`weapon` int(11) NOT NULL DEFAULT 0,\
		FOREIGN KEY (uid) REFERENCES kz_uid(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE,\
		FOREIGN KEY (mapid) REFERENCES kz_maps(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8; \
		");

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);

	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_savedruns` (\
		`uid` int(11) NOT NULL,\
		`mapid` int(11) NOT NULL,\
		`time` int(11) NOT NULL,\
		`date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
		`cp` int(11) NOT NULL DEFAULT 0,\
		`tp` int(11) NOT NULL DEFAULT 0,\
		`stuck` int(11) NOT NULL DEFAULT 0,\
		`pos_x` int(11) NOT NULL DEFAULT 0,\
		`pos_y` int(11) NOT NULL DEFAULT 0,\
		`pos_z` int(11) NOT NULL DEFAULT 0,\
		`lastcp_x` int(11) NOT NULL DEFAULT 0,\
		`lastcp_y` int(11) NOT NULL DEFAULT 0,\
		`lastcp_z` int(11) NOT NULL DEFAULT 0,\
		`weapon` int(11) NOT NULL DEFAULT 6,\
		FOREIGN KEY (uid) REFERENCES kz_uid(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE,\
		FOREIGN KEY (mapid) REFERENCES kz_maps(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8;\
		");

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);

	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_settings` (\
		`uid` int(11) NOT NULL UNIQUE,\
		`is_save_angles` int(11) NOT NULL DEFAULT 1,\
		`is_radio_enable` int(11) NOT NULL DEFAULT 0,\
		FOREIGN KEY (uid) REFERENCES kz_uid(id)\
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8;\
		");

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);

	formatex(szQuery, charsmax(szQuery), "\
	CREATE TABLE IF NOT EXISTS `kz_settings_timer` ( \
		`uid` int(11) NOT NULL UNIQUE, \
		`rgb` int(11) NOT NULL DEFAULT 6618980, \
		`x` int(11) NOT NULL DEFAULT %d, \
		`y` int(11) NOT NULL DEFAULT %d, \
		`is_dhud` int(11) NOT NULL DEFAULT 1, \
		`type` int(11) NOT NULL DEFAULT 0, \
		`is_ms` int(11) NOT NULL DEFAULT 1, \
		FOREIGN KEY (uid) REFERENCES kz_uid(id) \
			ON DELETE CASCADE \
			ON UPDATE CASCADE \
		) DEFAULT CHARSET utf8; \
		", -1.0, 0.01);

	SQL_ThreadQuery(SQL_Tuple, "@InitTables_Callback", szQuery);
}

@InitTables_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "InitTables_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	static i = 0;

	if (!i++)
		init_map();

	if (i == g_NumInitQueries)
	{
		new iRet;
		ExecuteForward(g_Forwards[fwd_Initialized], iRet);
	}
	
	SQL_FreeHandle(hQuery);
	
	return PLUGIN_HANDLED;
}

public init_map()
{
	new szMapName[64], szQuery[512];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);

	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_maps` \
		WHERE `mapname` = ^"%s^";",
		szMapName);

	SQL_ThreadQuery(SQL_Tuple, "@InitMap_Callback", szQuery);
}

@InitMap_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "InitMap_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	if (SQL_NumResults(hQuery) <= 0)
	{
		new szMapName[64], szQuery[512];
		get_mapname(szMapName, charsmax(szMapName));
		strtolower(szMapName);

		formatex(szQuery, charsmax(szQuery), "\
			INSERT INTO `kz_maps` (`mapname`) VALUES (^"%s^");",
			szMapName);

		SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

		init_map();
	}
	else
	{
		g_MapId = SQL_ReadResult(hQuery, 0);
	}

	return PLUGIN_HANDLED;
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		return;
	
	new szQuery[512], szAuth[37], szData[5];
	
	// get user steam id
	get_user_authid(id, szAuth, charsmax(szAuth));
	
	// id to string
	num_to_str(id, szData, charsmax(szData));
	
	// format query
	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_uid` \
		WHERE `steam_id` = ^"%s^";",
		szAuth);
	
	UTIL_LogToFile(MYSQL_LOG, "DEBUG", "client_putinserver", szQuery);
	
	// async query to get user info
	SQL_ThreadQuery(SQL_Tuple, "@UserInfo_Callback", szQuery, szData, charsmax(szData));
}

@UserInfo_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "UserInfo_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}
	
	// get user id from data
	new id = str_to_num(szData);
	new szQuery[512], szAuth[37];

	new szName[MAX_NAME_LENGTH];

	// get user name
	get_user_name(id, szName, charsmax(szName));

	// get user steam id
	get_user_authid(id, szAuth, charsmax(szAuth));
	
	// no results -> player connected for first time
	if (SQL_NumResults(hQuery) <= 0)
	{
		// format query
		formatex(szQuery, charsmax(szQuery), "\
			INSERT INTO `kz_uid` (`steam_id`, `last_name`) VALUES (^"%s^", ^"%s^");\
			",
			szAuth, szName);
		
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "UserInfo_Callback", szQuery);

		// async query to get user info again
		SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);
		
		formatex(szQuery, charsmax(szQuery), "\
			SELECT * FROM `kz_uid` \
			WHERE `steam_id` = ^"%s^";",
			szAuth);
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "UserInfo_Callback", szQuery);
		
		// async query to get user info
		SQL_ThreadQuery(SQL_Tuple, "@UserInfo_Callback", szQuery, szData, iLen);
	}
	// has result -> parse user data
	else
	{
		// get unique id
		g_UserData[id] = SQL_ReadResult(hQuery, 0);
		
		new iRet;
		ExecuteForward(g_Forwards[fwd_InfoReceived], iRet, id);
		
		// format query
		formatex(szQuery, charsmax(szQuery), "\
			UPDATE `kz_uid` SET `last_name` = ^"%s^" \
			WHERE `id` = %d;",
			szName, g_UserData[id]);
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "UserInfo_Callback", szQuery);
		
		// async query to get user info again
		SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);
	}
	
	SQL_FreeHandle(hQuery);
	
	return PLUGIN_HANDLED;
}

public cmd_UpdateEncoding()
{
	new szQuery[512];

	// format query
	formatex(szQuery, charsmax(szQuery), "\
		ALTER TABLE `kz_uid` CONVERT TO CHARACTER SET utf8;\
		ALTER TABLE `kz_maps` CONVERT TO CHARACTER SET utf8;\
		ALTER TABLE `kz_nubtop` CONVERT TO CHARACTER SET utf8;\
		ALTER TABLE `kz_protop` CONVERT TO CHARACTER SET utf8;\
		ALTER TABLE `kz_savedruns` CONVERT TO CHARACTER SET utf8;\
		");

	// async query to get user info again
	SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);
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
	
	SQL_FreeHandle(hQuery);
	
	return PLUGIN_HANDLED;
}

LoadConfig(szFileName[])
{
	if (!file_exists(szFileName))
		return;
	
	new szData[256];
	new hFile = fopen(szFileName, "rt");

	while (hFile && !feof(hFile))
	{
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

		if (equal(szKey, "kz_sql_hostname"))
			copy(g_ConnInfo[eHostName], charsmax(g_ConnInfo[eHostName]), szValue);
		else if (equal(szKey, "kz_sql_username"))
			copy(g_ConnInfo[eUser], charsmax(g_ConnInfo[eUser]), szValue);
		else if (equal(szKey, "kz_sql_password"))
			copy(g_ConnInfo[ePassWord], charsmax(g_ConnInfo[ePassWord]), szValue);
		else if (equal(szKey, "kz_sql_database"))
			copy(g_ConnInfo[eDataBase], charsmax(g_ConnInfo[eDataBase]), szValue);
	}
	
	if (hFile) {
		fclose(hFile);
	}
}
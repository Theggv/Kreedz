#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>


#define PLUGIN 	 	"[Kreedz] Sql Core"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:ConnectionStruct {
	eHostName[64],
	eUser[64],
	ePassWord[64],
	eDataBase[64]
};

new g_ConnInfo[ConnectionStruct];

enum _:eForwards {
	fwd_Initialized,
	fwd_InfoReceived,
};

new g_Forwards[eForwards];

new Handle:SQL_Tuple;
new Handle:SQL_Connection;

new g_UserData[MAX_PLAYERS + 1];
new g_MapId;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	initForwards();

	register_srvcmd("amx_updatecharset", "cmd_UpdateEncoding");
}

initForwards() {
	g_Forwards[fwd_Initialized] = 	CreateMultiForward("kz_sql_initialized", ET_IGNORE);
	g_Forwards[fwd_InfoReceived] = 	CreateMultiForward("kz_sql_data_recv", ET_IGNORE, FP_CELL);
}

public plugin_cfg() {
	new szCfgDir[256];
	get_configsdir(szCfgDir, charsmax(szCfgDir));

	format(szCfgDir, charsmax(szCfgDir), "%s/kreedz.cfg", szCfgDir);

	LoadConfig(szCfgDir);

	mkdir("addons/amxmodx/logs/kz_db_log");
	
	new szError[512], iError;

	SQL_Tuple = SQL_MakeDbTuple(g_ConnInfo[eHostName], g_ConnInfo[eUser], g_ConnInfo[ePassWord], g_ConnInfo[eDataBase]);
	SQL_Connection = SQL_Connect(SQL_Tuple, iError, szError, charsmax(szError));

	if (SQL_Connection == Empty_Handle) {
		UTIL_LogToFile(MYSQL_LOG, "ERROR", "plugin_cfg", "[%d] %s", iError, szError);
		set_fail_state(szError);
	}

	SQL_SetCharset(SQL_Tuple, "utf8");
	
	SQL_FreeHandle(SQL_Connection);

	initTables();
}

initTables() {
	new szQuery[4096];

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
\
CREATE TABLE IF NOT EXISTS `kz_records` (\
	`id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,\
	`user_id` int(11) NOT NULL,\
	`map_id` int(11) NOT NULL,\
	`time` int(11) NOT NULL,\
	`date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
	`cp` int(11) NOT NULL DEFAULT 0,\
	`tp` int(11) NOT NULL DEFAULT 0,\
	`weapon` int(11) NOT NULL DEFAULT 6,\
	`aa` int(11) NOT NULL DEFAULT 0,\
	`is_pro_record` tinyint(1) GENERATED ALWAYS AS (`tp` = 0) STORED,\
	INDEX user_idx (`user_id`),\
	INDEX map_idx (`map_id`),\
	INDEX rec_idx (`map_id`, `weapon`, `aa`, `is_pro_record`),\
	FOREIGN KEY (user_id) REFERENCES kz_uid(id)\
		ON DELETE CASCADE \
		ON UPDATE CASCADE,\
	FOREIGN KEY (map_id) REFERENCES kz_maps(id)\
		ON DELETE CASCADE \
		ON UPDATE CASCADE \
	) DEFAULT CHARSET utf8; \
\
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
	`lastvel_x` int(11) NOT NULL DEFAULT 0,\
	`lastvel_y` int(11) NOT NULL DEFAULT 0,\
	`lastvel_z` int(11) NOT NULL DEFAULT 0,\
	FOREIGN KEY (uid) REFERENCES kz_uid(id)\
		ON DELETE CASCADE \
		ON UPDATE CASCADE,\
	FOREIGN KEY (mapid) REFERENCES kz_maps(id)\
		ON DELETE CASCADE \
		ON UPDATE CASCADE \
	) DEFAULT CHARSET utf8;\
		");

	SQL_ThreadQuery(SQL_Tuple, "@initTablesHandler", szQuery);
}

initMap() {
	new szMapName[64], szQuery[512];
	get_mapname(szMapName, charsmax(szMapName));
	strtolower(szMapName);

	formatex(szQuery, charsmax(szQuery), "\
SELECT * FROM `kz_maps` WHERE `mapname` = '%s';\
		", szMapName);

	SQL_ThreadQuery(SQL_Tuple, "@initMapHandler", szQuery);
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

public plugin_end() {
	SQL_FreeHandle(SQL_Tuple);
}

/**
*	------------------------------------------------------------------
*	Natives section
*	------------------------------------------------------------------
*/


public plugin_natives() {
	register_native("kz_sql_get_user_uid", "native_get_user_uid", 1);
	register_native("kz_sql_get_map_uid", "native_get_map_uid", 1);
	register_native("kz_sql_get_tuple", "native_get_tuple", 1);
	register_native("db_update_user_info", "native_db_update_user_info", 1);
}

public native_get_user_uid(id) {
	return g_UserData[id];
}

public native_get_map_uid() {
	return g_MapId;
}

public native_db_update_user_info(id) {
	client_putinserver(id);
}

public Handle:native_get_tuple() {
	return SQL_Tuple;
}

/**
*	------------------------------------------------------------------
*	Game events handlers
*	------------------------------------------------------------------
*/


public client_putinserver(id) {
	if (is_user_bot(id)) return;
	
	new szQuery[512], szAuth[37], szData[5];
	
	// get user steam id
	get_user_authid(id, szAuth, charsmax(szAuth));
	
	// id to string
	num_to_str(id, szData, charsmax(szData));
	
	// format query
	formatex(szQuery, charsmax(szQuery), "\
SELECT * FROM `kz_uid` WHERE `steam_id` = '%s';\
		", szAuth);
	
	UTIL_LogToFile(MYSQL_LOG, "DEBUG", "client_putinserver", szQuery);
	
	// async query to get user info
	SQL_ThreadQuery(SQL_Tuple, "@getUserInfoHandler", szQuery, szData, charsmax(szData));
}

/**
*	------------------------------------------------------------------
*	Query handlers
*	------------------------------------------------------------------
*/

@initTablesHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "initTablesHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	initMap();

	new iRet;
	ExecuteForward(g_Forwards[fwd_Initialized], iRet);
	
	SQL_FreeHandle(hQuery);
	
	return PLUGIN_HANDLED;
}

@initMapHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "initMapHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	if (SQL_NumResults(hQuery) <= 0) {
		new szMapName[64], szQuery[512];
		get_mapname(szMapName, charsmax(szMapName));
		strtolower(szMapName);

		formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_maps` (`mapname`) VALUES ('%s');\
			", szMapName);

		SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);

		initMap();
	}
	else {
		g_MapId = SQL_ReadResult(hQuery, 0);
	}

	return PLUGIN_HANDLED;
}

@getUserInfoHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "getUserInfoHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}
	
	// get user id from data
	new id = str_to_num(szData);
	new szQuery[512], szAuth[37];

	new szName[MAX_NAME_LENGTH];

	get_user_name(id, szName, charsmax(szName));
	get_user_authid(id, szAuth, charsmax(szAuth));
	
	// no results -> player connected for first time
	if (SQL_NumResults(hQuery) <= 0) {
		// format query
		formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_uid` (`steam_id`, `last_name`) VALUES ('%s', '%s');\
			", szAuth, szName);
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "getUserInfoHandler", szQuery);

		// async query to get user info again
		SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);
		
		formatex(szQuery, charsmax(szQuery), "\
SELECT * FROM `kz_uid` WHERE `steam_id` = '%s';\
			", szAuth);
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "getUserInfoHandler", szQuery);
		
		// async query to get user info
		SQL_ThreadQuery(SQL_Tuple, "@getUserInfoHandler", szQuery, szData, iLen);
	}
	// has result -> parse user data
	else {
		// get unique id
		g_UserData[id] = SQL_ReadResult(hQuery, 0);
		
		new iRet;
		ExecuteForward(g_Forwards[fwd_InfoReceived], iRet, id);
		
		// format query
		formatex(szQuery, charsmax(szQuery), "\
UPDATE `kz_uid` SET `last_name` = '%s' WHERE `id` = %d;\
			", szName, g_UserData[id]);
		
		UTIL_LogToFile(MYSQL_LOG, "DEBUG", "getUserInfoHandler", szQuery);
		
		// async query to get user info again
		SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);
	}
	
	SQL_FreeHandle(hQuery);
	
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
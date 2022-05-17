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

enum _:(+=50) {
	TASK_SHOWBESTSCORE = 1024,
};

enum _:ConnectionStruct {
	eHostName[64],
	eUser[64],
	ePassWord[64],
	eDataBase[64]
};

new g_ConnInfo[ConnectionStruct];

enum _:eForwards {
	fwdInitialized,
	fwdInfoReceived,
	fwdNewProRecord,
	fwdNewNubRecord,
};

new g_Forwards[eForwards];

new Handle:SQL_Tuple;
new Handle:SQL_Connection;

new g_MapId;

enum _:UserRecordStruct {
	bool:ud_hasRecord,
	bool:ud_isLoaded,
	Float:ud_bestTime,
	ud_cpCount,
	ud_tpCount,
};

// Best personal records storage
new g_ProRecords[MAX_PLAYERS + 1][UserRecordStruct];
new g_NubRecords[MAX_PLAYERS + 1][UserRecordStruct];

// Run info for insert/update queries
new g_Candidates[MAX_PLAYERS + 1][RunStruct];

// User ids
new g_UserData[MAX_PLAYERS + 1];


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	initForwards();
	initCommands();
}

initForwards() {
	g_Forwards[fwdInitialized] = 	CreateMultiForward("kz_sql_initialized", ET_IGNORE);
	g_Forwards[fwdInfoReceived] = 	CreateMultiForward("kz_sql_data_recv", ET_IGNORE, FP_CELL);
	g_Forwards[fwdNewProRecord] = 	CreateMultiForward("kz_top_new_pro_rec", ET_IGNORE, FP_CELL, FP_FLOAT);
	g_Forwards[fwdNewNubRecord] = 	CreateMultiForward("kz_top_new_nub_rec", ET_IGNORE, FP_CELL, FP_FLOAT);
}

initCommands() {
	kz_register_cmd("cfr", "cmdShowPersonalBest");
}

public plugin_cfg() {
	new szCfgDir[256];
	get_configsdir(szCfgDir, charsmax(szCfgDir));

	format(szCfgDir, charsmax(szCfgDir), "%s/kreedz.cfg", szCfgDir);

	loadConfig(szCfgDir);

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

loadConfig(szFileName[]) {
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
*	Commands
*	------------------------------------------------------------------
*/

public cmdShowPersonalBest(id) {
	new szTime[32];

	if (g_ProRecords[id][ud_hasRecord]) {
		UTIL_FormatTime(g_ProRecords[id][ud_bestTime],
			szTime, charsmax(szTime), true);

		client_print_color(id , print_team_default, "%L", id, "KZ_CHAT_BEST_PRO", szTime);
	}
	else if(g_NubRecords[id][ud_hasRecord]) {
		UTIL_FormatTime(g_NubRecords[id][ud_bestTime],
			szTime, charsmax(szTime), true);

		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_BEST_NUB", 
			szTime, g_NubRecords[id][ud_cpCount], g_NubRecords[id][ud_tpCount]);
	}
	else {
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_NO_RECORD");
	}

	return PLUGIN_HANDLED;
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
SELECT * FROM `kz_uid` WHERE `steam_id` = '%s';", 
		szAuth);
	
	UTIL_LogToFile(MYSQL_LOG, "DEBUG", "client_putinserver", szQuery);
	
	// async query to get user info
	SQL_ThreadQuery(SQL_Tuple, "@getUserInfoHandler", szQuery, szData, charsmax(szData));
}

public client_disconnected(id) {
	g_ProRecords[id][ud_hasRecord] = false;
	g_ProRecords[id][ud_isLoaded] = false;

	g_NubRecords[id][ud_hasRecord] = false;
	g_NubRecords[id][ud_isLoaded] = false;
}

public kz_timer_finish_post(id, runInfo[RunStruct]) {
	insertOrUpdateRecord(id, runInfo);
}

public kz_sql_data_recv(id) {
	new szQuery[256], szData[32];

	new mapId = kz_sql_get_map_uid();
	new userId = kz_sql_get_user_uid(id);


	for (new isProRecord = 0; isProRecord <= 1; ++isProRecord) {
		formatex(szQuery, charsmax(szQuery), "\
SELECT `time`, `cp`, `tp`, `weapon`, `aa` FROM `kz_records` WHERE `user_id` = %d AND `map_id` = %d \
AND `weapon` = 6 AND `aa` = 0 AND `is_pro_record` = %d;",
			userId, mapId, isProRecord);

		formatex(szData, charsmax(szData), "%d %d", id, isProRecord);
		SQL_ThreadQuery(SQL_Tuple, "@getPersonalRecordHandler", szQuery, szData, charsmax(szData));
	}
}

insertOrUpdateRecord(id, runInfo[RunStruct]) {
	new szQuery[256];

	new userId = kz_sql_get_user_uid(id);
	new mapId = kz_sql_get_map_uid();

	copy(g_Candidates[id], RunStruct, runInfo);

	formatex(szQuery, charsmax(szQuery), "\
SELECT `id`, `time` FROM `kz_records` WHERE `user_id` = %d AND `map_id` = %d \
AND `weapon` = %d AND `aa` = %d AND `is_pro_record` = %d;",
		userId, mapId, g_Candidates[id][run_weapon], 
		g_Candidates[id][run_airaccelerate], (g_Candidates[id][run_tpCount] == 0));

	new szData[32];
	formatex(szData, charsmax(szData), "%d", id);

	SQL_ThreadQuery(SQL_Tuple, "@insertOrUpdateRecHandler", szQuery, szData, charsmax(szData));
}

printTimeDifference(id, Float:oldTime, Float:newTime) {
	if (!is_user_connected(id)) return;

	new Float:diff = floatabs(oldTime - newTime);

	new szTime[32];
	UTIL_FormatTime(diff, szTime, charsmax(szTime), true);

	if (newTime < oldTime) {
		client_print_color(id, print_team_default, "%L", id, "KZ_CHAT_BEAT_RECORD", szTime);
	}
	else {
		client_print_color(id, print_team_red, "%L", id, "KZ_CHAT_LOSE_RECORD", szTime);
	}
}

getAchievement(id) {
	new mapId = kz_sql_get_map_uid();

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT COUNT(*) FROM `kz_records` \
WHERE `map_id` = %d AND `weapon` = %d AND `aa` = %d AND `is_pro_record` = %d` AND `time` <= %d;",
		mapId, g_Candidates[id][run_weapon], g_Candidates[id][run_airaccelerate], 
		(g_Candidates[id][run_tpCount] == 0), g_Candidates[id][run_time]);

	new szData[32];
	formatex(szData, charsmax(szData), "%d", id);
	SQL_ThreadQuery(SQL_Tuple, "@getAchievementHandler", szQuery, szData, charsmax(szData));
}

public taskShowBestScore(taskId) {
	new id = taskId - TASK_SHOWBESTSCORE;

	if (!is_user_connected(id)) return;

	cmdShowPersonalBest(id);
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

	checkIsMigrationNeeded();
	initMap();

	new iRet;
	ExecuteForward(g_Forwards[fwdInitialized], iRet);
	
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
		ExecuteForward(g_Forwards[fwdInfoReceived], iRet, id);
		
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

@insertOrUpdateRecHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "insertOrUpdateRecHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	new szQuery[512];

	// Update record if exists
	if (SQL_NumResults(hQuery) > 0) {
		new runId = SQL_ReadResult(hQuery, 0);
		new Float:curTime = Float:SQL_ReadResult(hQuery, 1);

		// Print time difference to user
		printTimeDifference(id, curTime, g_Candidates[id][run_time]);

		// Update record if user has beaten previous one
		if (g_Candidates[id][run_time] < curTime) {
			formatex(szQuery, charsmax(szQuery), "\
UPDATE `kz_records` SET `time` = %d, `date` = CURRENT_TIMESTAMP, \
`cp` = %d, `tp` = %d WHERE `id` = %d;",
				g_Candidates[id][run_time], g_Candidates[id][run_cpCount],
				g_Candidates[id][run_tpCount], runId);

			SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);

			// Print map achievement
			getAchievement(id);
		}
	}
	// Or insert if not
	else {
		new userId = kz_sql_get_user_uid(id);
		new mapId = kz_sql_get_map_uid();

		formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `cp`, `tp`, `weapon`, `aa`) VALUES \
(%d, %d, %d, %d, %d, %d, %d);",
			userId, mapId, g_Candidates[id][run_time],
			g_Candidates[id][run_cpCount], g_Candidates[id][run_tpCount],
			g_Candidates[id][run_weapon], g_Candidates[id][run_airaccelerate]);

		SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);

		// Print map achievement
		getAchievement(id);
	}

	return PLUGIN_HANDLED;
}

@getPersonalRecordHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "getPersonalRecordHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new szId[16], szIsPro[16];
	parse(szData, szId, 15, szIsPro, 15);

	new id = str_to_num(szId);
	new bool:isProRecord = bool:str_to_num(szIsPro);

	if (SQL_NumResults(hQuery) > 0) {
		if (isProRecord) {
			g_ProRecords[id][ud_bestTime] = Float:SQL_ReadResult(hQuery, 0);
			g_ProRecords[id][ud_cpCount] = SQL_ReadResult(hQuery, 1);
			g_ProRecords[id][ud_tpCount] = SQL_ReadResult(hQuery, 2);
			g_ProRecords[id][ud_hasRecord] = true;
		}
		else {
			g_NubRecords[id][ud_bestTime] = Float:SQL_ReadResult(hQuery, 0);
			g_NubRecords[id][ud_cpCount] = SQL_ReadResult(hQuery, 1);
			g_NubRecords[id][ud_tpCount] = SQL_ReadResult(hQuery, 2);
			g_NubRecords[id][ud_hasRecord] = true;
		}
	}
	else {
		if (isProRecord)
			g_ProRecords[id][ud_hasRecord] = false;
		else
			g_NubRecords[id][ud_hasRecord] = false;
	}

	if (isProRecord)
		g_ProRecords[id][ud_isLoaded] = true;
	else
		g_NubRecords[id][ud_isLoaded] = true;

	// Show best record if all data has received
	if (g_ProRecords[id][ud_isLoaded] && g_NubRecords[id][ud_isLoaded]) {
		set_task(1.0, "taskShowBestScore", TASK_SHOWBESTSCORE + id);
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

@getAchievementHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "getAchievementHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if (SQL_NumResults(hQuery) > 0) {
		new place = SQL_ReadResult(hQuery, 0);

		new szPlace[32], szTopType[32];
		new printType = print_team_default;

		new szName[MAX_NAME_LENGTH];
		get_user_name(id, szName, charsmax(szName));

		new szWeaponName[32];
		kz_get_weapon_name(g_Candidates[id][run_weapon], szWeaponName, charsmax(szWeaponName));

		if (g_Candidates[id][run_tpCount] == 0) {
			formatex(szTopType, charsmax(szTopType), "pro");
		}
		else {
			formatex(szTopType, charsmax(szTopType), "nub");
		}

		switch (place) {
			case 1: {
				printType = print_team_red;
				formatex(szPlace, charsmax(szPlace), "^31");
			}
			case 2: {
				printType = print_team_grey;
				formatex(szPlace, charsmax(szPlace), "^32");
			}
			case 3: {
				printType = print_team_blue;
				formatex(szPlace, charsmax(szPlace), "^33");
			}
			default: {
				printType = print_team_default;
				formatex(szPlace, charsmax(szPlace), "^1%d", place);
			}
		}

		// Print achievement message
		client_print_color(0, printType, 
			"^4[KZ]^1 %s achieved %s^1 place in the %s top with %s!", 
			szName, szTopType, szWeaponName);

		
		// Call forward
		if (g_Candidates[id][run_weapon] == 6) {
			new fwd = (g_Candidates[id][run_tpCount] == 0) ? 
				g_Forwards[fwdNewProRecord] :
				g_Forwards[fwdNewNubRecord];

			new Float:time = (place == 1) ? g_Candidates[id][run_time] : 0.0;

			ExecuteForward(fwd, _, id, time);
		}
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

@dummyHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	SQL_FreeHandle(hQuery);

	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
		}
	}
	
	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Migrations
*	------------------------------------------------------------------
*/

checkIsMigrationNeeded() {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
SELECT \
	(SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_NAME = 'kz_protop'),\
	(SELECT COUNT(*) FROM `kz_records` WHERE 1);\
		");

	SQL_ThreadQuery(SQL_Tuple, "@isMigrationNeededHandler", szQuery);
}

@isMigrationNeededHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "isMigrationNeededHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	if (SQL_NumResults(hQuery) > 0) {
		new isProtopExists = SQL_ReadResult(hQuery, 0);
		new count = SQL_ReadResult(hQuery, 1);

		if (isProtopExists && count == 0) {
			migrateRecords();
		}
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}


migrateRecords() {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`) \
    (SELECT `uid`, `mapid`, `time`, `date` FROM `kz_protop` WHERE 1); \
\
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`, `cp`, `tp`) \
   (SELECT `uid`, `mapid`, `time`, `date`, `cp`, `tp` FROM `kz_nubtop` WHERE 1);\
\
INSERT INTO `kz_records` (`user_id`, `map_id`, `time`, `date`, `cp`, `tp`, `weapon`) \
    (SELECT `uid`, `mapid`, `time`, `date`, `cp`, `tp`, `weapon` FROM `kz_weapontop` WHERE 1); \
		");

	SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);
}
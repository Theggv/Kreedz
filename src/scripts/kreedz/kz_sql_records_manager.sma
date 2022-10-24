#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>


#define PLUGIN 			"[Kreedz] Records manager"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"


enum RemoveQueryType {
	UNSET,
	SINGLE_BY_RECORD_ID,
	MULTIPLE_BY_MAP_ID,
	MULTIPLE_BY_USER_ID,
};

enum _:RemoveQueryStruct {
	RemoveQueryType:RemoveQuery_Type,
	RemoveQuery_Data,
};

new g_Requests[MAX_PLAYERS][RemoveQueryStruct];

new Handle:SQL_Tuple;

/**
*	------------------------------------------------------------------
*	Init
*	------------------------------------------------------------------
*/


public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    initCommands();
}


initCommands() {
	register_clcmd("kz_get_user_by_record", "cmdGetUserByRecord", ADMIN_BAN);
	register_clcmd("kz_remove_record", "cmdRemoveRecord", ADMIN_BAN);
	register_clcmd("kz_remove_record_accept", "cmdRemoveRecordAccept", ADMIN_BAN);
}


public kz_sql_initialized() {
	SQL_Tuple = kz_sql_get_tuple();
}

public client_disconnected(id) {
	UTIL_ClearQueryType(id);
}

/**
*	------------------------------------------------------------------
*	Commands
*	------------------------------------------------------------------
*/

public cmdGetUserByRecord(id) {
	new argc = read_argc();

	if (argc < 4) {
		client_print(id, print_console, "Description: Get user info by record.");
		client_print(id, print_console, "Usage: kz_get_user_by_record <mapname> <place> <is_pro_record> <weapon=6> <aa=0>");
		client_print(id, print_console, "Args:");
		client_print(id, print_console, "   mapname {string} - map name");
		client_print(id, print_console, "   place {number} - place in the top");
		client_print(id, print_console, "   is_pro_record {number} - 0 for nub record, 1 for pro record");
		client_print(id, print_console, "   weapon {number=6} - 0 (AWP), 1 (M249), 2 (M4A1), 3 (SG552), 4 (FAMAS), 5 (P90), 6 (USP), 7 (SCOUT)");
		client_print(id, print_console, "   aa {number=0} - 0 for 10 aa, 1 for 100 aa");
		client_print(id, print_console, "Example: kz_get_user_by_record ^"bkz_goldbhop^" 1 1");

		return PLUGIN_HANDLED;
	}

	new mapName[64];

	read_argv(1, mapName, charsmax(mapName));
	new place = clamp(read_argv_int(2), 1);
	new isProRecord = clamp(read_argv_int(3), 0, 1);
	new weapon = clamp((argc >= 5) ? read_argv_int(4) : 6, 0, 7);
	new aa = clamp((argc >= 6) ? read_argv_int(5) : 0, 0, 1);

	new weaponName[32];
	kz_get_weapon_name(weapon, weaponName, charsmax(weaponName));

	client_print(id, print_console, 
		"Trying to find user by #%d %s record on '%s' with %s (%daa)...", 
		place, isProRecord ? "pro" : "nub", mapName, weaponName, aa ? 100 : 10);

	tryFindUserQuery(id, mapName, isProRecord, place, weapon, aa);

	return PLUGIN_HANDLED;
}

public cmdRemoveRecord(id) {
	new argc = read_argc();

	if (argc < 4) {
		client_print(id, print_console, "Description: Remove record from the database.");
		client_print(id, print_console, "Usage: kz_remove_record <mapname> <steam_id> <is_pro_record> <weapon=6> <aa=0>");
		client_print(id, print_console, "Args:");
		client_print(id, print_console, "   mapname {string} - map name");
		client_print(id, print_console, "   steam_id {string} - user steam id");
		client_print(id, print_console, "   is_pro_record {number} - 0 for nub record, 1 for pro record");
		client_print(id, print_console, "   weapon {number=6} - 0 (AWP), 1 (M249), 2 (M4A1), 3 (SG552), 4 (FAMAS), 5 (P90), 6 (USP), 7 (SCOUT)");
		client_print(id, print_console, "   aa {number=0} - 0 for 10 aa, 1 for 100 aa");
		client_print(id, print_console, "Example: kz_remove_record ^"bkz_goldbhop^" ^"STEAM_1:0:11101^" 1");

		return PLUGIN_HANDLED;
	}

	new mapName[64], steamId[64];

	read_argv(1, mapName, charsmax(mapName));
	read_argv(2, steamId, charsmax(steamId));
	new isProRecord = clamp(read_argv_int(3), 0, 1);
	new weapon = clamp((argc >= 5) ? read_argv_int(4) : 6, 0, 7);
	new aa = clamp((argc >= 6) ? read_argv_int(5) : 0, 0, 1);

	new weaponName[32];
	kz_get_weapon_name(weapon, weaponName, charsmax(weaponName));

	client_print(id, print_console, 
		"Trying to find %s record on '%s' with %s by '%s' (%daa)...", 
		isProRecord ? "pro" : "nub", mapName, weaponName, steamId, aa ? 100 : 10);

	tryFindRecordQuery(id, mapName, steamId, isProRecord, weapon, aa);
		
	return PLUGIN_HANDLED;
}

public cmdRemoveRecordAccept(id) {
	removeRecordsQuery(id);

	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Queries
*	------------------------------------------------------------------
*/

public tryFindRecordQuery(id, mapName[64], steamId[64], isProRecord, weapon, aa) {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
SELECT \
	((SELECT `id` FROM `kz_maps` WHERE `mapname` = '%s') UNION (SELECT -1) ORDER BY `id` = -1 LIMIT 1) as mapId,\
	((SELECT `id` FROM `kz_uid` WHERE `steam_id` = '%s') UNION (SELECT -1) ORDER BY `id` = -1 LIMIT 1) as userId,\
	((SELECT `id` FROM `kz_records` \
		WHERE `user_id` = userId AND `map_id` = mapId AND `weapon` = %d AND `is_pro_record` = %d AND `aa` = %d)\
	UNION (SELECT -1) ORDER BY `id` = -1 LIMIT 1) as recordId;\
		", mapName, steamId, weapon, isProRecord, aa);

	new szData[1];
	szData[0] = id;

	SQL_ThreadQuery(SQL_Tuple, "@tryFindRecordHandler", szQuery, szData, sizeof szData);
}

public tryFindUserQuery(id, mapName[64], isProRecord, place, weapon, aa) {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `steam_id` FROM `kz_uid` \ 
	INNER JOIN `kz_records` ON `kz_records`.`user_id` = `kz_uid`.`id` \
	INNER JOIN `kz_maps` ON `kz_records`.`map_id` = `kz_maps`.`id` \
WHERE \
    `kz_maps`.`mapname` = '%s' AND `weapon` = %d AND `is_pro_record` = %d AND `aa` = %d \
ORDER BY \
    `time` \
LIMIT 1 OFFSET %d;\
		", mapName, weapon, isProRecord, aa, place - 1);

	new szData[1];
	szData[0] = id;

	SQL_ThreadQuery(SQL_Tuple, "@tryFindUserHandler", szQuery, szData, sizeof szData);
}

public getRecordInfoQuery(id, recordId) {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
SELECT `last_name`, `mapname`, `time`, `cp`, `tp`, `weapon`, `aa` from `kz_records` \
INNER JOIN `kz_maps` ON `kz_records`.`map_id`=`kz_maps`.`id` \
INNER JOIN `kz_uid` ON `kz_records`.`user_id`=`kz_uid`.`id` \
WHERE `kz_records`.`id` = %d;\
		", recordId);

	new szData[1];
	szData[0] = id;

	SQL_ThreadQuery(SQL_Tuple, "@getRecordInfoHandler", szQuery, szData, sizeof szData);
}

public removeRecordsQuery(id) {
	new szQuery[1024];

	switch (g_Requests[id][RemoveQuery_Type]) {
		case UNSET: {
			return;
		}
		case SINGLE_BY_RECORD_ID: {
			new recordId = g_Requests[id][RemoveQuery_Data];

			if (recordId < 0) return;

			formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_records` WHERE `id` = %d;", recordId);
		}
		case MULTIPLE_BY_MAP_ID: {
			new mapId = g_Requests[id][RemoveQuery_Data];

			if (mapId < 0) return;

			formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_records` WHERE `map_id` = %d;", mapId);
		}
		case MULTIPLE_BY_USER_ID: {
			new userId = g_Requests[id][RemoveQuery_Data];

			if (userId < 0) return;

			formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_records` WHERE `user_id` = %d;", userId);
		}
	}

	new szData[1];
	szData[0] = id;

	SQL_ThreadQuery(SQL_Tuple, "@removeRecordsHandler", szQuery, szData, sizeof szData);
}

/**
*	------------------------------------------------------------------
*	Query handlers
*	------------------------------------------------------------------
*/

@tryFindUserHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "tryFindUserHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = szData[0];

	new lastName[64], steamId[64];

	if (SQL_NumResults(hQuery) <= 0) {
		client_print(id, print_console, "Record was not found.");
		return PLUGIN_HANDLED;
	}

	SQL_ReadResult(hQuery, 0, lastName, charsmax(lastName));
	SQL_ReadResult(hQuery, 1, steamId, charsmax(steamId));

	client_print(id, print_console, "Found: %s [ %s ]", lastName, steamId);

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

@tryFindRecordHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "tryFindRecordHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = szData[0];

	new mapId = SQL_ReadResult(hQuery, 0);
	new userId = SQL_ReadResult(hQuery, 1);
	new recordId = SQL_ReadResult(hQuery, 2);

	if (mapId < 0) {
		client_print(id, print_console, "Map was not found.");
		return PLUGIN_HANDLED;
	}

	if (userId < 0) {
		client_print(id, print_console, "User was not found.");
		return PLUGIN_HANDLED;
	}

	if (recordId < 0) {
		client_print(id, print_console, "Record was not found.");
		return PLUGIN_HANDLED;
	}

	if (!is_user_connected(id)) {
		UTIL_ClearQueryType(id);
		return PLUGIN_HANDLED;
	}

	g_Requests[id][RemoveQuery_Type] = SINGLE_BY_RECORD_ID;
	g_Requests[id][RemoveQuery_Data] = recordId;

	getRecordInfoQuery(id, recordId);

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

@getRecordInfoHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "getRecordInfoHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = szData[0];

	new lastName[64], mapName[64], runInfo[RunStruct];

	SQL_ReadResult(hQuery, 0, lastName, charsmax(lastName));
	SQL_ReadResult(hQuery, 1, mapName, charsmax(mapName));
	runInfo[run_time] = Float:SQL_ReadResult(hQuery, 2);
	runInfo[run_cpCount] = SQL_ReadResult(hQuery, 3);
	runInfo[run_tpCount] = SQL_ReadResult(hQuery, 4);
	runInfo[run_weapon] = SQL_ReadResult(hQuery, 5);
	runInfo[run_airaccelerate] = SQL_ReadResult(hQuery, 6);

	client_print(id, print_console, "Found:");
	UTIL_PrintRecord(id, lastName, mapName, runInfo);
	client_print(id, print_console, "Are you sure you want to delete this score?");
	client_print(id, print_console, "Type kz_remove_record_accept for confirmation.");

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}


@removeRecordsHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "removeRecordsHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = szData[0];

	switch (g_Requests[id][RemoveQuery_Type]) {
		case SINGLE_BY_RECORD_ID: {
			client_print(id, print_console, "The record was removed.");
		}
		case MULTIPLE_BY_MAP_ID: {
			client_print(id, print_console, "Map records were removed.");
		}
		case MULTIPLE_BY_USER_ID: {
			client_print(id, print_console, "Records were removed.");
		}
	}

	UTIL_ClearQueryType(id);

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Utility
*	------------------------------------------------------------------
*/

public UTIL_ClearQueryType(id) {
	g_Requests[id][RemoveQuery_Type] = UNSET;
}

stock UTIL_PrintRecord(id, nickName[64], mapName[64], runInfo[RunStruct], index = 0) {
	new szTime[32], weaponName[32];
	UTIL_FormatTime(runInfo[run_time], szTime, charsmax(szTime), true);
	kz_get_weapon_name(runInfo[run_weapon], weaponName, charsmax(weaponName));

	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "%s on '%s' - %s [%d cp %d gc] [%s] [%daa]", 
		nickName, mapName, szTime, runInfo[run_cpCount], runInfo[run_tpCount], 
		weaponName, runInfo[run_airaccelerate] ? 100 : 10);

	if (index > 0) {
		format(szMsg, charsmax(szMsg), "%d) %s", index, szMsg);
	}
	
	client_print(id, print_console, szMsg);
}
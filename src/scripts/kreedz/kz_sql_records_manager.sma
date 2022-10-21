#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>


#define PLUGIN 			"[Kreedz] Records manager"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

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
}

public kz_sql_initialized() {
	SQL_Tuple = kz_sql_get_tuple();
}

/**
*	------------------------------------------------------------------
*	Commands
*	------------------------------------------------------------------
*/

/**
*	------------------------------------------------------------------
*	Queries
*	------------------------------------------------------------------
*/

public isRecordExistQuery(userId, mapId, weapon, isProRecord, aa) {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
SELECT COUNT(*) FROM `kz_records` \
WHERE `user_id` = %d AND `map_id` = %d AND `weapon` = %d AND `is_pro_record` = %d AND `aa` = %d; \
		", userId, mapId, weapon, isProRecord, aa);

	new szData[5];
	szData[0] = userId;
	szData[1] = mapId;
	szData[2] = weapon;
	szData[3] = isProRecord;
	szData[4] = aa;

	SQL_ThreadQuery(SQL_Tuple, "@isRecordExistHandler", szQuery, szData, sizeof szData);
}

public removeRecordQuery(userId, mapId, weapon, isProRecord, aa) {
	new szQuery[1024];

	formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_records` \
WHERE `user_id` = %d AND `map_id` = %d AND `weapon` = %d AND `is_pro_record` = %d AND `aa` = %d; \
		", userId, mapId, weapon, isProRecord, aa);

	new szData[5];
	szData[0] = userId;
	szData[1] = mapId;
	szData[2] = weapon;
	szData[3] = isProRecord;
	szData[4] = aa;

	SQL_ThreadQuery(SQL_Tuple, "@removeRecordHandler", szQuery, szData, sizeof szData);
}

/**
*	------------------------------------------------------------------
*	Query handlers
*	------------------------------------------------------------------
*/

@isRecordExistHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "isRecordExistHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new userId = szData[0];
	new mapId = szData[1];
	new weapon = szData[2];
	new isProRecord = szData[3];
	new aa = szData[4];

	new resultsCount = SQL_ReadResult(hQuery, 0);

	if (resultsCount == 0) {
		server_print("[KZ_RECORDS_MANAGER] Record wasn't found.");
	} else if (resultsCount > 1) {
		server_print("[KZ_RECORDS_MANAGER] There's multiple records smh. Is it possible?");
	} else {
		server_print("[KZ_RECORDS_MANAGER] Record was found. Deleting...");

		removeRecordQuery(userId, mapId, weapon, isProRecord, aa);
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}


@removeRecordHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "removeRecordHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	server_print("[KZ_RECORDS_MANAGER] Record was deleted.");

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

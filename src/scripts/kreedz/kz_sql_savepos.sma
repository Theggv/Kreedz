#include <amxmodx>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Sql SavePos"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum _:UserData {
	ud_Uid,
	Float:ud_SavedTime,
	ud_SavedChecksNum,
	ud_SavedTeleNum,
	ud_SavedStucksNum,
	Float:ud_LastCP[3],
	Float:ud_LastPos[3],
	Float:ud_LastVel[3],
	ud_Weapon,
	bool:ud_hasSavedRun,
};

new g_UserData[MAX_PLAYERS + 1][UserData];

new Handle:SQL_Tuple;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i <= MAX_PLAYERS; ++i)
		g_UserData[i][ud_Weapon] = -1;
}

public client_disconnected(id) {
	if (kz_get_timer_state(id) != TIMER_DISABLED) {
		savePos(id);
	}

	g_UserData[id][ud_Weapon] = -1;
}

public kz_timer_start_post(id) {
	deleteSavedRun(id);
}

public kz_timer_finish_post(id) {
	deleteSavedRun(id);
}

public kz_timer_stop_post(id) {
	deleteSavedRun(id);
}

public kz_sql_initialized() {
	SQL_Tuple = kz_sql_get_tuple();
}

public kz_sql_data_recv(id) {
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
SELECT * FROM `kz_savedruns` WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid());

	new szData[1];
	szData[0] = id;
	SQL_ThreadQuery(SQL_Tuple, "@loadRunHandler", szQuery, szData, sizeof szData);
}

stock deleteSavedRun(id, ignoreChecks = false) {
	if (!g_UserData[id][ud_hasSavedRun] && !ignoreChecks) return;

	g_UserData[id][ud_hasSavedRun] = false;

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
DELETE FROM `kz_savedruns` WHERE `uid` = %d AND `mapid` = %d;",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid());

	SQL_ThreadQuery(SQL_Tuple, "@dummyHandler", szQuery);
}

@loadRunHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "loadRunHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	if (SQL_NumResults(hQuery) > 0) {
		new id = szData[0];

		g_UserData[id][ud_SavedTime] = Float:SQL_ReadResult(hQuery, 2);
		g_UserData[id][ud_SavedChecksNum] = SQL_ReadResult(hQuery, 4);
		g_UserData[id][ud_SavedTeleNum] = SQL_ReadResult(hQuery, 5);
		g_UserData[id][ud_SavedStucksNum] = SQL_ReadResult(hQuery, 6);

		g_UserData[id][ud_LastPos][0] = (Float:SQL_ReadResult(hQuery, 7));
		g_UserData[id][ud_LastPos][1] = (Float:SQL_ReadResult(hQuery, 8));
		g_UserData[id][ud_LastPos][2] = (Float:SQL_ReadResult(hQuery, 9));

		g_UserData[id][ud_LastCP][0] = (Float:SQL_ReadResult(hQuery, 10));
		g_UserData[id][ud_LastCP][1] = (Float:SQL_ReadResult(hQuery, 11));
		g_UserData[id][ud_LastCP][2] = (Float:SQL_ReadResult(hQuery, 12));

		g_UserData[id][ud_Weapon] = SQL_ReadResult(hQuery, 13);

		g_UserData[id][ud_LastVel][0] = (Float:SQL_ReadResult(hQuery, 14));
		g_UserData[id][ud_LastVel][1] = (Float:SQL_ReadResult(hQuery, 15));
		g_UserData[id][ud_LastVel][2] = (Float:SQL_ReadResult(hQuery, 16));

		g_UserData[id][ud_hasSavedRun] = true;

		setLoadedRun(id);
	}

	SQL_FreeHandle(hQuery);
	return PLUGIN_HANDLED;
}

setLoadedRun(id) {
	kz_set_cp_num(id, g_UserData[id][ud_SavedChecksNum]);
	kz_set_tp_num(id, g_UserData[id][ud_SavedTeleNum]);

	new lastPos[PosStruct], lastCP[PosStruct], lastVel[PosStruct];

	lastPos[pos_x] = g_UserData[id][ud_LastPos][0];
	lastPos[pos_y] = g_UserData[id][ud_LastPos][1];
	lastPos[pos_z] = g_UserData[id][ud_LastPos][2];

	kz_set_last_pos(id, lastPos);

	lastCP[pos_x] = g_UserData[id][ud_LastCP][0];
	lastCP[pos_y] = g_UserData[id][ud_LastCP][1];
	lastCP[pos_z] = g_UserData[id][ud_LastCP][2];

	kz_set_last_cp(id, lastCP);

	kz_set_start_time(id, get_gametime() - g_UserData[id][ud_SavedTime]);

	kz_set_pause(id);

	kz_tp_last_pos(id);

	lastVel[pos_x] = g_UserData[id][ud_LastVel][0];
	lastVel[pos_y] = g_UserData[id][ud_LastVel][1];
	lastVel[pos_z] = g_UserData[id][ud_LastVel][2];
	
	kz_set_last_vel(id, lastVel);

	kz_set_min_rank(id, g_UserData[id][ud_Weapon]);
}

savePos(id) {
	new iLastPos[3], iLastCp[3], iLastVel[3];
	kz_get_last_pos(id, iLastPos);
	kz_get_last_cp(id, iLastCp);
	kz_get_last_vel(id, iLastVel);

	deleteSavedRun(id, true);

	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_savedruns` \
	(`uid`, `mapid`, `time`, `cp`, `tp`, \
	`pos_x`, `pos_y`, `pos_z`, \
	`lastcp_x`, `lastcp_y`, `lastcp_z`, \
	`weapon`, \
	`lastvel_x`, `lastvel_y`, `lastvel_z`) \
	\
	VALUES (%d, %d, %d, %d, %d, \
	%d, %d, %d, \
	%d, %d, %d, \
	%d, \
	%d, %d, %d\
		);",
		kz_sql_get_user_uid(id), kz_sql_get_map_uid(),
		kz_get_actual_time(id), kz_get_cp_num(id), kz_get_tp_num(id),
		iLastPos[0], iLastPos[1], iLastPos[2],
		iLastCp[0], iLastCp[1], iLastCp[2],
		kz_get_min_rank(id),
		iLastVel[0], iLastVel[1], iLastVel[2]
		);


	new szData[1];
	szData[0] = id;
	SQL_ThreadQuery(SQL_Tuple, "@savePosHandler", szQuery, szData, sizeof szData);
}

@savePosHandler(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime) {
	SQL_FreeHandle(hQuery);

	switch (QueryState) {
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "savePosHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = szData[0];
	g_UserData[id][ud_hasSavedRun] = true;

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
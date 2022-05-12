// 
// TODO:
//  1. update queries as bundles
// for cell:
//  INSERT INTO `kz_option_%s` (id, value) VALUES(%d, %d) ON DUPLICATE KEY UPDATE value=VALUES(value)
// for string:
//  INSERT INTO `kz_option_%s` (id, value) VALUES(%d, '%s') ON DUPLICATE KEY UPDATE value=VALUES(value)
// 

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#include <kreedz_sql>
#include <settings_api>

#define PLUGIN 			"[Settings] MySQL"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

#define LOGS_FOLDER     "addons/amxmodx/logs/settings_mysql_logs"

#define MAX_REGISTER_QUERY_LENGTH   512
#define MAX_BUNDLE_QUERY_LENGTH   4096

#pragma dynamic 16384

new g_logFile[256];


enum _:ConnStruct {
	ConnHostname[64],
	ConnUsername[64],
	ConnPassword[64],
	ConnDatabase[64],
};

new g_ConnInfo[ConnStruct];
new Handle:SQL_Tuple, Handle:SQL_Connection;


enum ForwardsEnum {
    fwdOnConnectionIsReady,
    fwdOnOptionsInitialized,
};

new g_Forwards[ForwardsEnum];


new g_QueryBundle[MAX_BUNDLE_QUERY_LENGTH];
new g_InitQueriesCount;
new bool:gb_IsInitialized = false;

// Cached option names
new Array:ga_CachedCellNames;
new Array:ga_CachedStringNames;

/**
*	------------------------------------------------------------------
*	Init section
*	------------------------------------------------------------------
*/


public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    initForwards();
}

public plugin_precache() {
    ga_CachedCellNames = ArrayCreate(MAX_OPTION_LENGTH);
    ga_CachedStringNames = ArrayCreate(MAX_OPTION_LENGTH);
}

public plugin_cfg() {
    setupLogFile();
    setupConnection();
}

public plugin_end() {
    SQL_FreeHandle(SQL_Connection);
    SQL_FreeHandle(SQL_Tuple);
}

initForwards() {
    g_Forwards[fwdOnConnectionIsReady] = CreateMultiForward("OnConnectionIsReady", ET_CONTINUE);
    g_Forwards[fwdOnOptionsInitialized] = CreateMultiForward("OnOptionsInitialized", ET_CONTINUE);
}

/**
*	------------------------------------------------------------------
*	Game events handlers
*	------------------------------------------------------------------
*/

public kz_sql_data_recv(id) {
    new uid = kz_sql_get_user_uid(id);

    new szQuery[2048], szAdd[512], optionName[MAX_OPTION_LENGTH];

    // prepare query
    formatex(szQuery, charsmax(szQuery), "SELECT ");

    for (new i; i < ArraySize(ga_CachedCellNames); ++i) {
        ArrayGetString(ga_CachedCellNames, i, optionName, MAX_OPTION_LENGTH - 1);

        formatex(szAdd, charsmax(szAdd), "\
(SELECT IFNULL(MAX(value), DEFAULT(value)) from `kz_option_%s` where uid = %d) as %s,\
            ", optionName, uid, optionName);

        add(szQuery, charsmax(szQuery), szAdd);
    }

    for (new i; i < ArraySize(ga_CachedStringNames); ++i) {
        ArrayGetString(ga_CachedStringNames, i, optionName, MAX_OPTION_LENGTH - 1);

        formatex(szAdd, charsmax(szAdd), "\
(SELECT IFNULL(MAX(value), DEFAULT(value)) from `kz_option_%s` where uid = %d) as %s,\
            ", optionName, uid, optionName);

        add(szQuery, charsmax(szQuery), szAdd);
    }

    szQuery[strlen(szQuery) - 1] = ';';

    // pack user data
    new szData[16];
    formatex(szData, charsmax(szData), "%d", id);

    UTIL_DebugMessage(szQuery);

    // execute query
    SQL_ThreadQuery(SQL_Tuple, "@getUserSettingsHandler", szQuery, szData, charsmax(szData));
}

/**
*	------------------------------------------------------------------
*	Forward handlers
*	------------------------------------------------------------------
*/

public OnOptionsInitialized() {
    set_task(5.0, "executeBundleQuery", 1000, .flags = "b");
}

public OnRegisterOption(optionName[MAX_OPTION_LENGTH], OptionFieldType:fieldType, defaultValue[MAX_STR_VALUE_LENGTH]) {
    if (equal(optionName, RESERVER_OPTION_END)) {
        executeBundleQuery();
        return;
    }

    new szQuery[MAX_REGISTER_QUERY_LENGTH], szType[32], szValue[MAX_STR_VALUE_LENGTH * 2];

    if (fieldType != FIELD_TYPE_STRING) {
        formatex(szType, charsmax(szType), "varchar(%d)", MAX_STR_VALUE_LENGTH);
        formatex(szValue, charsmax(szValue), "'%s'", defaultValue);

        ArrayPushString(ga_CachedCellNames, optionName);
    }
    else {
        formatex(szType, charsmax(szType), "int(11)");
        formatex(szValue, charsmax(szValue), "%s", defaultValue);

        ArrayPushString(ga_CachedStringNames, optionName);
    }

    formatex(szQuery, charsmax(szQuery), "\
CREATE TABLE IF NOT EXISTS `kz_option_%s` (\
    `uid` int(11) NOT NULL UNIQUE,\
    `value` %s DEFAULT %s\
    ) DEFAULT CHARSET utf8;\
    ", optionName, szType, szValue);

    bundleQueries(szQuery);
}

public OnNotifyMysqlCellValue(id, optionId, newValue) {
    if (!is_user_connected(id)) return;

    new optionName[MAX_OPTION_LENGTH];
    ArrayGetString(ga_CachedCellNames, optionId, optionName, MAX_OPTION_LENGTH - 1);

    new uid = kz_sql_get_user_uid(id);
    
    if (!uid) return;

    new szQuery[MAX_REGISTER_QUERY_LENGTH];
    formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_option_%s` (uid, value) VALUES(%d, %d) ON DUPLICATE KEY UPDATE value=VALUES(value);\
        ", optionName, uid, newValue);

    bundleQueries(szQuery);

    UTIL_DebugMessage("set %s = %d to player %d", optionName, newValue, id);
}

public OnNotifyMysqlStringValue(id, optionId, newValue[MAX_STR_VALUE_LENGTH]) {
    if (!is_user_connected(id)) return;

    new optionName[MAX_OPTION_LENGTH];
    ArrayGetString(ga_CachedCellNames, optionId, optionName, MAX_OPTION_LENGTH - 1);

    new uid = kz_sql_get_user_uid(id);

    if (!uid) return;

    new szQuery[MAX_REGISTER_QUERY_LENGTH];
    formatex(szQuery, charsmax(szQuery), "\
INSERT INTO `kz_option_%s` (uid, value) VALUES(%d, '%s') ON DUPLICATE KEY UPDATE value=VALUES(value);\
        ", optionName, uid, newValue);

    bundleQueries(szQuery);

    UTIL_DebugMessage("set %s = %s to player %d", optionName, newValue, id);
}

bundleQueries(szQuery[MAX_REGISTER_QUERY_LENGTH]) {
    // overflow check 
    if (strlen(g_QueryBundle) + strlen(szQuery) >= MAX_BUNDLE_QUERY_LENGTH) {
        executeBundleQuery();

        formatex(g_QueryBundle, charsmax(g_QueryBundle), szQuery);

        return;
    }

    add(g_QueryBundle, charsmax(g_QueryBundle), szQuery);
}

public executeBundleQuery() {
    if (equal(g_QueryBundle, "")) return;

    if (!gb_IsInitialized) {
        g_InitQueriesCount++;
    }

    UTIL_DebugMessage("Bundle query: %s", g_QueryBundle);

    SQL_ThreadQuery(SQL_Tuple, "@bundleQueryHandler", g_QueryBundle);
    formatex(g_QueryBundle, charsmax(g_QueryBundle), "");
}

/**
*	------------------------------------------------------------------
*	Private functions
*	------------------------------------------------------------------
*/


setupLogFile() {
    new time[32];
    get_time("%m%d%Y_%H%M%S", time, charsmax(time));

    mkdir(LOGS_FOLDER);
    formatex(g_logFile, charsmax(g_logFile), "%s/%s.log", LOGS_FOLDER, time);
}

setupConnection() {
    loadConfig();

    new szError[512], iError;

    SQL_Tuple = SQL_MakeDbTuple(
        g_ConnInfo[ConnHostname], 
        g_ConnInfo[ConnUsername], 
        g_ConnInfo[ConnPassword], 
        g_ConnInfo[ConnDatabase]);
    
    SQL_Connection = SQL_Connect(SQL_Tuple, iError, szError, charsmax(szError));

    if (SQL_Connection == Empty_Handle) {
        UTIL_LogToFile(g_logFile, "ERROR", "plugin_cfg", "[%d] %s", iError, szError);
        set_fail_state(szError);
    }

    SQL_SetCharset(SQL_Tuple, "utf8");
    
    ExecuteForward(g_Forwards[fwdOnConnectionIsReady], _);
}

loadConfig() {
    new szConfigPath[256];
    get_configsdir(szConfigPath, charsmax(szConfigPath));
    format(szConfigPath, charsmax(szConfigPath), "%s/kreedz.cfg", szConfigPath);

    if (!file_exists(szConfigPath)) return;

    new szData[256];
    new hFile = fopen(szConfigPath, "rt");

    new szKey[64], szValue[128];

    while (hFile && !feof(hFile)) {
        fgets(hFile, szData, charsmax(szData));
        trim(szData);
        
        // Skip comments and empty lines
        if (containi(szData, ";") > -1 || equal(szData, "") || equal(szData, "//", 2))
            continue;
        
        strtok(szData, szKey, 63, szValue, 127, '=');

        trim(szKey);
        trim(szValue);
        remove_quotes(szValue);

        if (equal(szKey, "kz_sql_hostname"))
            copy(g_ConnInfo[ConnHostname], charsmax(g_ConnInfo[ConnHostname]), szValue);
        else if (equal(szKey, "kz_sql_username"))
            copy(g_ConnInfo[ConnUsername], charsmax(g_ConnInfo[ConnUsername]), szValue);
        else if (equal(szKey, "kz_sql_password"))
            copy(g_ConnInfo[ConnPassword], charsmax(g_ConnInfo[ConnPassword]), szValue);
        else if (equal(szKey, "kz_sql_database"))
            copy(g_ConnInfo[ConnDatabase], charsmax(g_ConnInfo[ConnDatabase]), szValue);
    }

    if (hFile) {
        fclose(hFile);
    }
}

/**
*	------------------------------------------------------------------
*	Query handlers
*	------------------------------------------------------------------
*/

@bundleQueryHandler(queryState, Handle:handle, szError[], iError, szData[], iLen, Float:fQueryTime) {
    SQL_FreeHandle(handle);

    switch (queryState) {
        case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
            UTIL_LogToFile(g_logFile, "ERROR", "bundleQueryHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
        }
    }

    if (!gb_IsInitialized) {
        g_InitQueriesCount--;

        if (g_InitQueriesCount == 0) {
            gb_IsInitialized = true;
            ExecuteForward(g_Forwards[fwdOnOptionsInitialized], _);
        }
    }

    return PLUGIN_HANDLED;
}

@getUserSettingsHandler(queryState, Handle:handle, szError[], iError, szData[], iLen, Float:fQueryTime) {
    switch (queryState) {
        case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
            UTIL_LogToFile(g_logFile, "ERROR", "getUserSettingsHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
        }
    }

    new id = str_to_num(szData);
    new size = ArraySize(ga_CachedCellNames);

    for (new i = 0; i < size; ++i) {
        new data = SQL_ReadResult(handle, i);

        set_option_cell(id, i, data, false);
    }

    for (new i = 0; i < ArraySize(ga_CachedStringNames); ++i) {
        new data[MAX_STR_VALUE_LENGTH];
        SQL_ReadResult(handle, i + size, data, MAX_STR_VALUE_LENGTH - 1);

        set_option_string(id, i, data, false);
    }

    SQL_FreeHandle(handle);

    return PLUGIN_HANDLED;
}

@dummyHandler(queryState, Handle:handle, szError[], iError, szData[], iLen, Float:fQueryTime) {
    SQL_FreeHandle(handle);

    switch (queryState) {
        case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED: {
            UTIL_LogToFile(g_logFile, "ERROR", "dummyHandler", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
        }
    }

    return PLUGIN_HANDLED;
}
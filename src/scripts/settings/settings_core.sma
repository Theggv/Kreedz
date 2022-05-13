#include <amxmodx>

#include <settings_api>

#define PLUGIN 			"[Settings] Core"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

enum ForwardsEnum {
    fwdOnRegisterOption,
    fwdOnCellValueChanged,
    fwdOnStringValueChanged,
    fwdOnNotifyMysqlCellValue,
    fwdOnNotifyMysqlStringValue,
};

new g_Forwards[ForwardsEnum];


enum _:OptionStruct {
    op_Name[MAX_OPTION_LENGTH],
    OptionFieldType:op_Type,
    op_DefaultValue[MAX_STR_VALUE_LENGTH],
};

new Array:ga_CellOptions;
new Array:ga_CellValues;

new Array:ga_StringOptions;
new Array:ga_StringValues;

/**
*	------------------------------------------------------------------
*	Init section
*	------------------------------------------------------------------
*/


public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    initForwards();
    initData();
}

public plugin_precache() {
    ga_CellOptions = ArrayCreate(OptionStruct);
    ga_CellValues = ArrayCreate(1);

    ga_StringOptions = ArrayCreate(OptionStruct);
    ga_StringValues = ArrayCreate(MAX_STR_VALUE_LENGTH);
}

initForwards() {
    g_Forwards[fwdOnRegisterOption] = 
        CreateMultiForward("OnRegisterOption", ET_CONTINUE, FP_STRING, FP_CELL, FP_STRING);
    g_Forwards[fwdOnCellValueChanged] = 
        CreateMultiForward("OnCellValueChanged", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
    g_Forwards[fwdOnStringValueChanged] = 
        CreateMultiForward("OnStringValueChanged", ET_CONTINUE, FP_CELL, FP_CELL, FP_STRING);
    g_Forwards[fwdOnNotifyMysqlCellValue] = 
        CreateMultiForward("OnNotifyMysqlCellValue", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
    g_Forwards[fwdOnNotifyMysqlStringValue] = 
        CreateMultiForward("OnNotifyMysqlStringValue", ET_CONTINUE, FP_CELL, FP_CELL, FP_STRING);
}

initData() {
    new option[OptionStruct];
    new cellValue, strValue[MAX_STR_VALUE_LENGTH];

    for (new i = 0; i < ArraySize(ga_CellOptions); ++i) {
        ArrayGetArray(ga_CellOptions, i, option);

        cellValue = str_to_num(option[op_DefaultValue]);

        for (new j = 0; j < MAX_PLAYERS; ++j) {
            ArrayPushCell(ga_CellValues, cellValue);
        }
    }

    for (new i = 0; i < ArraySize(ga_StringOptions); ++i) {
        ArrayGetArray(ga_StringOptions, i, option);

        copy(strValue, MAX_STR_VALUE_LENGTH - 1, option[op_DefaultValue])

        for (new j = 0; j < MAX_PLAYERS; ++j) {
            ArrayPushString(ga_StringValues, strValue);
        }
    }
}

/**
*	------------------------------------------------------------------
*	Game events handlers
*	------------------------------------------------------------------
*/

public client_remove(id) {
    // Set default values after player disconnect
    new option[OptionStruct];
    new cellValue, strValue[MAX_STR_VALUE_LENGTH];

    for (new i = 0; i < ArraySize(ga_CellOptions); ++i) {
        ArrayGetArray(ga_CellOptions, i, option);
        cellValue = str_to_num(option[op_DefaultValue]);

        ArraySetCell(ga_CellValues, encodeIndex(id, i), cellValue);
    }

    for (new i = 0; i < ArraySize(ga_StringOptions); ++i) {
        ArrayGetArray(ga_StringOptions, i, option);
        copy(strValue, MAX_STR_VALUE_LENGTH - 1, option[op_DefaultValue])

        ArraySetString(ga_StringValues, encodeIndex(id, i), strValue);
    }
}


/**
*	------------------------------------------------------------------
*	Natives section
*	------------------------------------------------------------------
*/


public plugin_natives() {
    register_native("register_players_option_cell", "native_players_option_cell");
    register_native("register_players_option_str", "native_players_option_str");

    register_native("get_option_cell", "native_get_option_cell");
    register_native("set_option_cell", "native_set_option_cell");

    register_native("get_option_string", "native_get_option_string");
    register_native("set_option_string", "native_set_option_string");

    register_native("find_option_by_name", "native_find_option_by_name");
}

public native_players_option_cell() {
    enum { arg_name = 1, arg_type, arg_defValue };

    new option[OptionStruct];

    get_string(arg_name, option[op_Name], MAX_OPTION_LENGTH - 1);
    option[op_Type] = any:get_param(arg_type);
    formatex(option[op_DefaultValue], MAX_STR_VALUE_LENGTH - 1, "%d", get_param(arg_defValue));

    ArrayPushArray(ga_CellOptions, option);

    return ArraySize(ga_CellOptions) - 1;
}

public native_players_option_str() {
    enum { arg_name = 1, arg_defValue };

    new option[OptionStruct];

    get_string(arg_name, option[op_Name], MAX_OPTION_LENGTH - 1);
    option[op_Type] = any:FIELD_TYPE_STRING;
    get_string(arg_defValue, option[op_DefaultValue], MAX_STR_VALUE_LENGTH - 1);

    ArrayPushArray(ga_StringOptions, option);

    return ArraySize(ga_StringOptions) - 1;
}

public native_get_option_cell() {
    enum { arg_id = 1, arg_optionId };

    new id = get_param(arg_id);
    new optionId = get_param(arg_optionId);

    if (id <= 0 || id > MAX_PLAYERS) return 0;
    if (optionId < 0 || optionId >= ArraySize(ga_CellOptions)) return 0;

    return getCellValue(id, optionId);
}

public native_set_option_cell() {
    enum { arg_id = 1, arg_optionId, arg_newValue, arg_notify };

    new id = get_param(arg_id);
    new optionId = get_param(arg_optionId);
    new newValue = _:get_param(arg_newValue);
    new bool:notify = bool:get_param(arg_notify);

    if (id <= 0 || id > MAX_PLAYERS) return 0;
    if (optionId < 0 || optionId >= ArraySize(ga_CellOptions)) return 0;

    setCellValue(id, optionId, newValue);

    // notify other plugins that value has changed
    ExecuteForward(g_Forwards[fwdOnCellValueChanged], _, id, optionId, newValue);

    if (notify) {
        ExecuteForward(g_Forwards[fwdOnNotifyMysqlCellValue], _, id, optionId, newValue);
    }

    return 1;
}

public native_get_option_string() {
    enum { arg_id = 1, arg_optionId, arg_buffer };

    new id = get_param(arg_id);
    new optionId = get_param(arg_optionId);

    if (id <= 0 || id > MAX_PLAYERS) return 0;
    if (optionId < 0 || optionId >= ArraySize(ga_StringOptions)) return 0;

    new buffer[MAX_STR_VALUE_LENGTH];
    getStringValue(id, optionId, buffer);

    set_string(arg_buffer, buffer, MAX_STR_VALUE_LENGTH - 1);

    return 1;
}

public native_set_option_string() {
    enum { arg_id = 1, arg_optionId, arg_newValue, arg_notify };

    new id = get_param(arg_id);
    new optionId = get_param(arg_optionId);
    new newValue[MAX_STR_VALUE_LENGTH];
    get_string(arg_newValue, newValue, MAX_STR_VALUE_LENGTH - 1);
    new bool:notify = bool:get_param(arg_notify);

    if (id <= 0 || id > MAX_PLAYERS) return 0;
    if (optionId < 0 || optionId >= ArraySize(ga_StringOptions)) return 0;

    setStringValue(id, optionId, newValue);

    // notify other plugins that value has changed
    ExecuteForward(g_Forwards[fwdOnStringValueChanged], _, id, optionId, newValue);

    if (notify) {
        ExecuteForward(g_Forwards[fwdOnNotifyMysqlStringValue], _, id, optionId, newValue);
    }

    return 1;
}

public native_find_option_by_name() {
    enum { arg_name = 1 };

    new optionName[MAX_OPTION_LENGTH];
    get_string(arg_name, optionName, MAX_OPTION_LENGTH - 1);

    new option[OptionStruct];

    for (new i = 0; i < ArraySize(ga_CellOptions); ++i) {
        ArrayGetArray(ga_CellOptions, i, option);

        if (equal(option[op_Name], optionName)) return i;
    }

    for (new i = 0; i < ArraySize(ga_StringOptions); ++i) {
        ArrayGetArray(ga_StringOptions, i, option);

        if (equal(option[op_Name], optionName)) return i;
    }

    return -1;
}

/**
*	------------------------------------------------------------------
*	Forward handlers
*	------------------------------------------------------------------
*/

public OnConnectionIsReady() {
    UTIL_DebugMessage("Init started");

    new option[OptionStruct];
    new optionName[MAX_OPTION_LENGTH], OptionFieldType:fieldType, defaultValue[MAX_STR_VALUE_LENGTH];

    for (new i = 0; i < ArraySize(ga_CellOptions); ++i) {
        ArrayGetArray(ga_CellOptions, i, option);

        copy(optionName, MAX_OPTION_LENGTH - 1, option[op_Name]);
        fieldType = OptionFieldType:option[op_Type];
        copy(defaultValue, MAX_STR_VALUE_LENGTH - 1, option[op_DefaultValue]);
        
        ExecuteForward(g_Forwards[fwdOnRegisterOption], _, optionName, fieldType, defaultValue);
    }

    for (new i = 0; i < ArraySize(ga_StringOptions); ++i) {
        ArrayGetArray(ga_StringOptions, i, option);

        copy(optionName, MAX_OPTION_LENGTH - 1, option[op_Name]);
        fieldType = OptionFieldType:option[op_Type];
        copy(defaultValue, MAX_STR_VALUE_LENGTH - 1, option[op_DefaultValue]);
        
        ExecuteForward(g_Forwards[fwdOnRegisterOption], _, optionName, fieldType, defaultValue);
    }

    ExecuteForward(g_Forwards[fwdOnRegisterOption], _, RESERVER_OPTION_END, 0, "");
}

public OnOptionsInitialized() {
    UTIL_DebugMessage("Init completed");
}

/**
*	------------------------------------------------------------------
*	Private functions
*	------------------------------------------------------------------
*/

getCellValue(id, optionId) {
    return ArrayGetCell(ga_CellValues, encodeIndex(id, optionId));
}

setCellValue(id, optionId, newValue) {
    ArraySetCell(ga_CellValues, encodeIndex(id, optionId), newValue);
}

getStringValue(id, optionId, buffer[MAX_STR_VALUE_LENGTH]) {
    ArrayGetString(ga_StringValues, encodeIndex(id, optionId), buffer, MAX_STR_VALUE_LENGTH - 1);
}

setStringValue(id, optionId, buffer[MAX_STR_VALUE_LENGTH]) {
    ArraySetString(ga_StringValues, encodeIndex(id, optionId), buffer);
}

encodeIndex(id, optionId) {
    return optionId * MAX_PLAYERS + id - 1;
}
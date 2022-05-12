#if defined _settings_api_included
	#endinput
#endif

#define _settings_api_included

// Comment this to disable debug messages
// #define PRINT_DEBUG_MESSAGES

#include <settings_util>

#define MAX_OPTION_LENGTH       32
#define MAX_STR_VALUE_LENGTH    64

#define RESERVER_OPTION_END     "#reserved_option_end"

enum OptionFieldType {
    FIELD_TYPE_INT,
    FIELD_TYPE_FLOAT,
    FIELD_TYPE_BOOL,
    FIELD_TYPE_STRING,
};

/**
 *  Register option for players (int/float/bool value)
 *  note: should be called in plugin_precache
 *  
 *  @param optionName   option name
 *  @param fieldType    see `OptionFieldType` constants
 *  @param defaultValue default value
 *  
 *  @noreturn 
 */
native register_players_option_cell(optionName[MAX_OPTION_LENGTH], OptionFieldType:fieldType, any:defaultValue = 0);

/**
 *  Register option for players (string value)
 *  note: should be called in plugin_precache
 *  
 *  @param optionName   option name
 *  @param defaultValue default value
 *  
 *  @noreturn 
 */
native register_players_option_str(optionName[MAX_OPTION_LENGTH], defaultValue[MAX_STR_VALUE_LENGTH]);

/**
 *  Get option id by its name
 *  note: should not be called in plugin_precache
 *
 *  @param optionName   option name
 *
 *  @return -1 if option does not exist, id >= 0 otherwise
 */
native find_option_by_name(optionName[MAX_OPTION_LENGTH]);

native get_option_cell(id, optionId);

native set_option_cell(id, optionId, newValue, bool:notifyMysql = true);

native get_option_string(id, optionId, buffer[MAX_STR_VALUE_LENGTH]);

native set_option_string(id, optionId, buffer[MAX_STR_VALUE_LENGTH], bool:notifyMysql = true);

/**
 *  Calls from `settings_mysql` when connection is ready
 *
 *  @noreturn
 */
forward OnConnectionIsReady();

/**
 *  Calls after all options were created in database
 *
 *  @noreturn
 */
forward OnOptionsInitialized();

/**
 *  Calls when option is ready to be initialized (after `OnConnectionIsReady`)
 *
 *  @param optionName   option name
 *  @param fieldType    see `OptionFieldType` constants
 *  @param defaultValue default value
 */
forward OnRegisterOption(optionName[MAX_OPTION_LENGTH], OptionFieldType:fieldType, defaultValue[MAX_STR_VALUE_LENGTH]);

forward OnCellValueChanged(id, optionId, newValue);

forward OnStringValueChanged(id, optionId, newValue[MAX_STR_VALUE_LENGTH]);

forward OnNotifyMysqlCellValue(id, optionId, newValue);

forward OnNotifyMysqlStringValue(id, optionId, newValue[MAX_STR_VALUE_LENGTH]);
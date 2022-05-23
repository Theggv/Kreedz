#include <amxmodx>
#include <hamsandwich>

#include <kreedz_api>
#include <kreedz_util>
#include <settings_api>

#define PLUGIN 			"[KZ] Settings"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"

enum (+=50) {
    TASK_USER_INITIALIZED = 1024,
};

enum OptionsEnum {
    optBoolStopSound,
    optIntSaveAngles,
    optBoolBlockRadio,
    optIntInvisMode,
    optFloatNoclipSpeed,
    optFloatHookSpeed,
    optBoolFog,
    optBoolShowMenu,
    optBoolAllowGoto,
    optIntMkeyBehavior,
    optIntJumpStats,
};

new g_Options[OptionsEnum];


enum UserDataStruct {
    bool:ud_initialized,

    bool:ud_stopSound,
    ud_anglesMode,
    bool:ud_blockRadio,
    ud_invisMode,
    Float:ud_noclipSpeed,
    Float:ud_hookSpeed,
    bool:ud_fog,
    bool:ud_showMenu,
    bool:ud_allowGoto,

    ud_mkeyBehavior,
    ud_jumpStats,
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];

new const DEFAULT_JUMP_STATS = 
    flagHasColorChat | flagLjStats | flagShowPre | 
    flagStrafeStats | flagFailEarly | flagLjPre | 
    flagShowEdge | flagShowEdgeFail |flagEnableSounds;


public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "fwdOnSpawn", .Post = true)

    kz_register_cmd("settings", "cmdSettings");

    register_clcmd("set_hook_speed", "cmdSetHookSpeed");
    register_clcmd("set_noclip_speed", "cmdSetNoclipSpeed");
}

public plugin_precache() {
    // stopsound after connect
    // 
    // default: false
    g_Options[optBoolStopSound] = register_players_option_cell("stopsound", FIELD_TYPE_BOOL, false);

    // save angles mode:
    // 0 - don't save
    // 1 - save on teleport
    // 2 - save on start
    // 3 - save on teleport and start
    // 
    // default: 3
    g_Options[optIntSaveAngles] = register_players_option_cell("save_angles", FIELD_TYPE_INT, 3);

    // block radio commands:
    // 
    // default: false
    g_Options[optBoolBlockRadio] = register_players_option_cell("block_radio", FIELD_TYPE_BOOL, false);

    // invis mode:
    // 
    // 0 - don't hide anything
    // 1 - hide players
    // 2 - hide water
    // 3 - hide players & water
    // 
    // default: 0
    g_Options[optIntInvisMode] = register_players_option_cell("invis_mode", FIELD_TYPE_INT, 0);

    // noclip speed:
    // 
    // default: 250.0
    g_Options[optFloatNoclipSpeed] = register_players_option_cell("max_noclip_speed", FIELD_TYPE_FLOAT, 250.0);

    // hook speed:
    // 
    // default: 600.0
    g_Options[optFloatHookSpeed] = register_players_option_cell("hook_speed", FIELD_TYPE_FLOAT, 600.0);

    // enable fog:
    // 
    // default: false
    g_Options[optBoolFog] = register_players_option_cell("fog", FIELD_TYPE_BOOL, false);

    // show menu on connect:
    // 
    // default: false
    g_Options[optBoolShowMenu] = register_players_option_cell("show_menu", FIELD_TYPE_BOOL, false);

    // allow go to:
    // 
    // default: true
    g_Options[optBoolAllowGoto] = register_players_option_cell("allow_goto", FIELD_TYPE_BOOL, true);

    // M key behavior:
    // 
    // 0 - open menu
    // 1 - go to spec/ct
    // 
    // default: 0
    g_Options[optIntMkeyBehavior] = register_players_option_cell("mkey_behavior", FIELD_TYPE_INT, 0);

    // Jump stats flags:
    // 
    // default: bitsum of abdehklmn
    g_Options[optIntJumpStats] = register_players_option_cell("jump_stats", FIELD_TYPE_INT, DEFAULT_JUMP_STATS);
}

public client_putinserver(id) {
    g_UserData[id][ud_initialized] = false;

    g_UserData[id][ud_stopSound] = false;
    g_UserData[id][ud_anglesMode] = 3;
    g_UserData[id][ud_blockRadio] = false;
    g_UserData[id][ud_invisMode] = 0;
    g_UserData[id][ud_noclipSpeed] = 250.0;
    g_UserData[id][ud_hookSpeed] = 600.0;
    g_UserData[id][ud_fog] = false;
    g_UserData[id][ud_showMenu] = false;
    g_UserData[id][ud_allowGoto] = true;

    g_UserData[id][ud_mkeyBehavior] = 0;
    g_UserData[id][ud_jumpStats] = DEFAULT_JUMP_STATS;

    remove_task(TASK_USER_INITIALIZED + id)
    set_task(5.0, "taskInitialized", TASK_USER_INITIALIZED + id);
}

public OnCellValueChanged(id, optionId, newValue) {
    if (optionId == g_Options[optBoolStopSound]) {
        g_UserData[id][ud_stopSound] = !!newValue;

        if (g_UserData[id][ud_initialized]) return;

        if (g_UserData[id][ud_stopSound] && is_user_connected(id)) {
            client_cmd(id, "stopsound");
        }
    }
    else if (optionId == g_Options[optIntSaveAngles]) {
        g_UserData[id][ud_anglesMode] = newValue;
    }
    else if (optionId == g_Options[optBoolBlockRadio]) {
        g_UserData[id][ud_blockRadio] = !!newValue;
    }
    else if (optionId == g_Options[optIntInvisMode]) {
        g_UserData[id][ud_invisMode] = newValue;
    }
    else if (optionId == g_Options[optFloatNoclipSpeed]) {
        g_UserData[id][ud_noclipSpeed] = Float:newValue;
    }
    else if (optionId == g_Options[optFloatHookSpeed]) {
        g_UserData[id][ud_hookSpeed] = Float:newValue;
    }
    else if (optionId == g_Options[optBoolFog]) {
        g_UserData[id][ud_fog] = !!newValue;
    }
    else if (optionId == g_Options[optBoolAllowGoto]) {
        g_UserData[id][ud_allowGoto] = !!newValue;
    }
    else if (optionId == g_Options[optBoolShowMenu]) {
        g_UserData[id][ud_showMenu] = !!newValue;

        if (g_UserData[id][ud_initialized]) return;

        if (g_UserData[id][ud_showMenu]) {
            amxclient_cmd(id, "menu");
        }
    }
    else if (optionId == g_Options[optIntMkeyBehavior]) {
        g_UserData[id][ud_mkeyBehavior] = newValue;
    }
    else if (optionId == g_Options[optIntJumpStats]) {
        g_UserData[id][ud_jumpStats] = newValue;
    }
}

public cmdSettings(id) {
    settingsMenu(id);

    return PLUGIN_HANDLED;
}

stock settingsMenu(id, page = 0) {
    new szMsg[256];
    formatex(szMsg, charsmax(szMsg), "\yKZ Settings");
    
    new iMenu = menu_create(szMsg, "@settingsMenuHandler");

    switch (g_UserData[id][ud_anglesMode]) {
        case 0: formatex(szMsg, charsmax(szMsg), "Save angles mode: \dnone");
        case 1: formatex(szMsg, charsmax(szMsg), "Save angles mode: \ron teleport");
        case 2: formatex(szMsg, charsmax(szMsg), "Save angles mode: \ron start");
        default: {
            formatex(szMsg, charsmax(szMsg), "Save angles mode: \ron teleport and start");
        }
    }
    
    menu_additem(iMenu, szMsg, "1", 0);

    switch (g_UserData[id][ud_invisMode]) {
        case 0: formatex(szMsg, charsmax(szMsg), "Invis: \ddisabled^n");
        case 1: formatex(szMsg, charsmax(szMsg), "Invis: \rhide players^n");
        case 2: formatex(szMsg, charsmax(szMsg), "Invis: \rhide water^n");
        default: {
            formatex(szMsg, charsmax(szMsg), "Invis: \rhide water and players^n");
        }
    }
    
    menu_additem(iMenu, szMsg, "2", 0);

    UTIL_PrepareBooleanMenuOption(szMsg, charsmax(szMsg), "Show FOG", g_UserData[id][ud_fog]);
    menu_additem(iMenu, szMsg, "5", 0);
    
    UTIL_PrepareBooleanMenuOption(szMsg, charsmax(szMsg), "Allow teleport to you", g_UserData[id][ud_allowGoto]);
    menu_additem(iMenu, szMsg, "7", 0);

    UTIL_PrepareBooleanMenuOption(szMsg, charsmax(szMsg), "Radio commands", !g_UserData[id][ud_blockRadio], .nextLine = true);
    menu_additem(iMenu, szMsg, "3", 0);

    UTIL_PrepareBooleanMenuOption(szMsg, charsmax(szMsg), "Stop sound on connect", g_UserData[id][ud_stopSound]);
    menu_additem(iMenu, szMsg, "4", 0);

    UTIL_PrepareBooleanMenuOption(szMsg, charsmax(szMsg), "Show menu on connect", g_UserData[id][ud_showMenu]);
    menu_additem(iMenu, szMsg, "6", 0);

    formatex(szMsg, charsmax(szMsg), "Hook speed: \y%.0f \du/s", g_UserData[id][ud_hookSpeed]);
    menu_additem(iMenu, szMsg, "8", 0);

    formatex(szMsg, charsmax(szMsg), "Noclip speed: \y%.0f \du/s^n", g_UserData[id][ud_noclipSpeed]);
    menu_additem(iMenu, szMsg, "9", 0);
    

    switch (g_UserData[id][ud_mkeyBehavior]) {
        case 0: formatex(szMsg, charsmax(szMsg), "M key behavior: \yopen menu");
        case 1: formatex(szMsg, charsmax(szMsg), "M key behavior: \rgo to spec/ct");
    }
    
    menu_additem(iMenu, szMsg, "10", 0);

    menu_display(id, iMenu, page);

    return PLUGIN_HANDLED;
}

@settingsMenuHandler(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    static szData[16], i_Access;
    menu_item_getinfo(menu, item, i_Access, szData, charsmax(szData));
    new iItem = str_to_num(szData);
    
    menu_destroy(menu);
    
    switch (iItem) {
        case 1: {
            g_UserData[id][ud_anglesMode] = (g_UserData[id][ud_anglesMode] + 1) % 4;

            set_option_cell(id, g_Options[optIntSaveAngles], g_UserData[id][ud_anglesMode]);
        }
        case 2: {
            g_UserData[id][ud_invisMode] = (g_UserData[id][ud_invisMode] + 1) % 4;

            set_option_cell(id, g_Options[optIntInvisMode], g_UserData[id][ud_invisMode]);
        }
        case 3: {
            g_UserData[id][ud_blockRadio] = !g_UserData[id][ud_blockRadio];

            set_option_cell(id, g_Options[optBoolBlockRadio], g_UserData[id][ud_blockRadio]);
        }
        case 4: {
            g_UserData[id][ud_stopSound] = !g_UserData[id][ud_stopSound];

            set_option_cell(id, g_Options[optBoolStopSound], g_UserData[id][ud_stopSound]);
        }
        case 5: {
            g_UserData[id][ud_fog] = !g_UserData[id][ud_fog];

            set_option_cell(id, g_Options[optBoolFog], g_UserData[id][ud_fog]);
        }
        case 6: {
            g_UserData[id][ud_showMenu] = !g_UserData[id][ud_showMenu];
            
            set_option_cell(id, g_Options[optBoolShowMenu], g_UserData[id][ud_showMenu]);
        }
        case 7: {
            g_UserData[id][ud_allowGoto] = !g_UserData[id][ud_allowGoto];
            
            set_option_cell(id, g_Options[optBoolAllowGoto], g_UserData[id][ud_allowGoto]);
        }
        case 8: {
	        client_cmd(id, "messagemode ^"set_hook_speed^"");
        }
        case 9: {
	        client_cmd(id, "messagemode ^"set_noclip_speed^"");
        }
        case 10: {
            g_UserData[id][ud_mkeyBehavior] = (g_UserData[id][ud_mkeyBehavior] + 1) % 2;
            
            set_option_cell(id, g_Options[optIntMkeyBehavior], g_UserData[id][ud_mkeyBehavior]);
        }
    }

    settingsMenu(id, item / 7);

    return PLUGIN_HANDLED;
}

public taskInitialized(taskId) {
    new id = taskId - TASK_USER_INITIALIZED;

    g_UserData[id][ud_initialized] = true;
}

public fwdOnSpawn(id) {
    if (!is_user_alive(id)) return;

    if (g_UserData[id][ud_showMenu]) {
        amxclient_cmd(id, "menu");
    }
}

public cmdSetHookSpeed(id) {
    if (!is_user_connected(id)) return PLUGIN_HANDLED;

    if (read_argc() < 2) return PLUGIN_HANDLED;

    enum { arg_value = 1 };

    new szValue[16], Float:newValue;
    read_argv(arg_value, szValue, charsmax(szValue));

    if (!is_str_num(szValue)) return PLUGIN_HANDLED;

    newValue = str_to_float(szValue);

    if (newValue < 200.0) newValue = 200.0;
    if (newValue > 1200.0) newValue = 1200.0;

    g_UserData[id][ud_hookSpeed] = newValue;
            
    set_option_cell(id, g_Options[optFloatHookSpeed], _:g_UserData[id][ud_hookSpeed]);

    settingsMenu(id, 1);

    return PLUGIN_HANDLED;
}

public cmdSetNoclipSpeed(id) {
    if (!is_user_connected(id)) return PLUGIN_HANDLED;

    if (read_argc() < 2) return PLUGIN_HANDLED;

    enum { arg_value = 1 };

    new szValue[16], Float:newValue;
    read_argv(arg_value, szValue, charsmax(szValue));

    if (!is_str_num(szValue)) return PLUGIN_HANDLED;

    newValue = str_to_float(szValue);

    if (newValue < 200.0) newValue = 200.0;
    if (newValue > 400.0) newValue = 400.0;

    g_UserData[id][ud_noclipSpeed] = newValue;
            
    set_option_cell(id, g_Options[optFloatNoclipSpeed], _:g_UserData[id][ud_noclipSpeed]);

    settingsMenu(id, 1);

    return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Utility
*	------------------------------------------------------------------
*/

stock UTIL_PrepareBooleanMenuOption(
    szMsg[], len, szTitle[], bool:flag, szTrue[] = "enabled", szFalse[] = "disabled", bool:nextLine = false
    ) {
    if (flag)
        formatex(szMsg, len, "%s: \y%s", szTitle, szTrue);
    else
        formatex(szMsg, len, "%s: \d%s", szTitle, szFalse);

    if (nextLine) {
        add(szMsg, len, "^n");
    }
}
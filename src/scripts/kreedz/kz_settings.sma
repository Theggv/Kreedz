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
    optBoolSpecList,
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
    bool:ud_specList,

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

    register_dictionary("kreedz_lang.txt");
    register_dictionary("common.txt");
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

    // Show spec list:
    // 
    // default: true
    g_Options[optBoolSpecList] = register_players_option_cell("spec_list", FIELD_TYPE_BOOL, true);
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
    g_UserData[id][ud_specList] = true;

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
    else if (optionId == g_Options[optBoolSpecList]) {
        g_UserData[id][ud_specList] = !!newValue;
    }
}

public cmdSettings(id) {
    settingsMenu(id);

    return PLUGIN_HANDLED;
}

stock settingsMenu(id, page = 0) {
    new szMsg[256];
    formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_TITLE");
    
    new iMenu = menu_create(szMsg, "@settingsMenuHandler");

    switch (g_UserData[id][ud_anglesMode]) {
        case 0: formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_ANGLES_NONE");
        case 1: formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_ANGLES_ONLY_TP");
        case 2: formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_ANGLES_ONLY_START");
        default: {
            formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_ANGLES_START_AND_TP");
        }
    }
    menu_additem(iMenu, szMsg);

    switch (g_UserData[id][ud_invisMode]) {
        case 0: formatex(szMsg, charsmax(szMsg), "%L^n", id, "SETTINGSMENU_OPT_INVIS_DISABLE");
        case 1: formatex(szMsg, charsmax(szMsg), "%L^n", id, "SETTINGSMENU_OPT_INVIS_PLAYERS");
        case 2: formatex(szMsg, charsmax(szMsg), "%L^n", id, "SETTINGSMENU_OPT_INVIS_WATER");
        default: {
            formatex(szMsg, charsmax(szMsg), "%L^n", id, "SETTINGSMENU_OPT_INVIS_PL_AND_WATER");
        }
    }
    menu_additem(iMenu, szMsg);

    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_SHOWMENU", g_UserData[id][ud_showMenu]);
    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_STOPSOUND", g_UserData[id][ud_stopSound]);
    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_SPECLIST", g_UserData[id][ud_specList], .nextLine = true);

    formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_HOOKSPEED", g_UserData[id][ud_hookSpeed]);
    menu_additem(iMenu, szMsg);

    formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_NOCLIPSPEED", g_UserData[id][ud_noclipSpeed]);
    menu_additem(iMenu, szMsg);

    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_FOG", g_UserData[id][ud_fog]);
    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_GOTO", g_UserData[id][ud_allowGoto]);
    addBoolOption(id, iMenu, szMsg, charsmax(szMsg), "SETTINGSMENU_OPT_RADIO", !g_UserData[id][ud_blockRadio]);

    switch (g_UserData[id][ud_mkeyBehavior]) {
        case 0: formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_MKEY_OPEN_MENU");
        case 1: formatex(szMsg, charsmax(szMsg), "%L", id, "SETTINGSMENU_OPT_MKEY_SPEC_CT");
    }
    
    menu_additem(iMenu, szMsg);

    formatex(szMsg, charsmax(szMsg), "%L", id, "BACK");
    menu_setprop(iMenu, MPROP_BACKNAME, szMsg);

    formatex(szMsg, charsmax(szMsg), "%L", id, "MORE");
    menu_setprop(iMenu, MPROP_NEXTNAME, szMsg);

    formatex(szMsg, charsmax(szMsg), "%L", id, "EXIT");
    menu_setprop(iMenu, MPROP_EXITNAME, szMsg);

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
    
    menu_destroy(menu);
    
    switch (item) {
        case 0: {
            g_UserData[id][ud_anglesMode] = (g_UserData[id][ud_anglesMode] + 1) % 4;
            set_option_cell(id, g_Options[optIntSaveAngles], g_UserData[id][ud_anglesMode]);
        }
        case 1: {
            g_UserData[id][ud_invisMode] = (g_UserData[id][ud_invisMode] + 1) % 4;
            set_option_cell(id, g_Options[optIntInvisMode], g_UserData[id][ud_invisMode]);
        }
        case 2: {
            g_UserData[id][ud_showMenu] = !g_UserData[id][ud_showMenu];
            set_option_cell(id, g_Options[optBoolShowMenu], g_UserData[id][ud_showMenu]);
        }
        case 3: {
            g_UserData[id][ud_stopSound] = !g_UserData[id][ud_stopSound];
            set_option_cell(id, g_Options[optBoolStopSound], g_UserData[id][ud_stopSound]);
        }
        case 4: {
            g_UserData[id][ud_specList] = !g_UserData[id][ud_specList];
            set_option_cell(id, g_Options[optBoolSpecList], g_UserData[id][ud_specList]);
        }
        case 5: {
	        client_cmd(id, "messagemode ^"set_hook_speed^"");
        }
        case 6: {
	        client_cmd(id, "messagemode ^"set_noclip_speed^"");
        }
        case 7: {
            g_UserData[id][ud_fog] = !g_UserData[id][ud_fog];
            set_option_cell(id, g_Options[optBoolFog], g_UserData[id][ud_fog]);
        }
        case 8: {
            g_UserData[id][ud_allowGoto] = !g_UserData[id][ud_allowGoto];
            set_option_cell(id, g_Options[optBoolAllowGoto], g_UserData[id][ud_allowGoto]);
        }
        case 9: {
            g_UserData[id][ud_blockRadio] = !g_UserData[id][ud_blockRadio];
            set_option_cell(id, g_Options[optBoolBlockRadio], g_UserData[id][ud_blockRadio]);
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

    settingsMenu(id, 0);

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

    settingsMenu(id, 0);

    return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Utility
*	------------------------------------------------------------------
*/

stock addBoolOption(
    id, iMenu, szMsg[], len, szTitleML[], bool:flag, bool:nextLine = false
    ) {
    if (flag)
        formatex(szMsg, len, "%L: \y%L", id, szTitleML, id, "SETTINGSMENU_ENABLE");
    else
        formatex(szMsg, len, "%L: \d%L", id, szTitleML, id, "SETTINGSMENU_DISABLE");

    if (nextLine) {
        add(szMsg, len, "^n");
    }

    menu_additem(iMenu, szMsg);
}
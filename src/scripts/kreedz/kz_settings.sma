#include <amxmodx>

#include <kreedz_util>
#include <settings_api>

#define PLUGIN 			"[KZ] Settings"
#define VERSION 		__DATE__
#define AUTHOR 			"ggv"


enum OptionsEnum {
    optBoolStopSound,
    optIntSaveAngles,
    optBoolBlockRadio,
    optIntInvisMode,
    optFloatNoclipSpeed,
    optBoolFog,
};

new g_Options[OptionsEnum];


enum UserDataStruct {
    bool:ud_stopSound,
    ud_anglesMode,
    bool:ud_blockRadio,
    ud_invisMode,
    Float:ud_noclipSpeed,
    bool:ud_fog,
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];


public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    kz_register_cmd("settings", "cmdSettings");
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
    // default: 600.0
    g_Options[optFloatNoclipSpeed] = register_players_option_cell("noclip_speed", FIELD_TYPE_FLOAT, 600.0);

    // enable fog:
    // 
    // default: false
    g_Options[optBoolFog] = register_players_option_cell("fog", FIELD_TYPE_BOOL, false);
}

public client_putinserver(id) {
    g_UserData[id][ud_stopSound] = false;
    g_UserData[id][ud_anglesMode] = 3;
    g_UserData[id][ud_blockRadio] = false;
    g_UserData[id][ud_invisMode] = 0;
    g_UserData[id][ud_noclipSpeed] = 600.0;
    g_UserData[id][ud_fog] = false;
}

public OnCellValueChanged(id, optionId, newValue) {
    if (optionId == g_Options[optBoolStopSound]) {
        g_UserData[id][ud_stopSound] = !!newValue;

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
    else if (optionId == g_Options[optBoolFog]) {
        g_UserData[id][ud_fog] = !!newValue;
    }
}

public cmdSettings(id) {
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

    switch (g_UserData[id][ud_fog]) {
        case true: formatex(szMsg, charsmax(szMsg), "Show FOG: \yenabled^n");
        case false: formatex(szMsg, charsmax(szMsg), "Show FOG: \ddisabled^n");
    }
    
    menu_additem(iMenu, szMsg, "5", 0);

    switch (g_UserData[id][ud_blockRadio]) {
        case true: formatex(szMsg, charsmax(szMsg), "Radio commands: \ddisabled");
        case false: formatex(szMsg, charsmax(szMsg), "Radio commands: \yenabled");
    }
    
    menu_additem(iMenu, szMsg, "3", 0);

    switch (g_UserData[id][ud_stopSound]) {
        case true: formatex(szMsg, charsmax(szMsg), "Stop sound on connect: \yenabled");
        case false: formatex(szMsg, charsmax(szMsg), "Stop sound on connect: \ddisabled");
    }
    
    menu_additem(iMenu, szMsg, "4", 0);

    menu_display(id, iMenu, 0);

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
    }

    cmdSettings(id);

    return PLUGIN_HANDLED;
}
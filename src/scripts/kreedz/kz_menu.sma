#include <amxmodx>

#include <kreedz_util>
#include <settings_api>

#define PLUGIN 	 	"[Kreedz] Menu"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

enum OptionsEnum {
    optIntMkeyBehavior,
};

new g_Options[OptionsEnum];

enum UserDataStruct {
	ud_mkeyBehavior,
};

new g_UserData[MAX_PLAYERS + 1][UserDataStruct];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("menu", "cmdMainMenu");
	// dlya dalbichey
	kz_register_cmd("ьутг", "cmdMainMenu");
	
	register_clcmd("jointeam", "cmdMkeyHandler");
	register_clcmd("chooseteam", "cmdMkeyHandler");

	register_dictionary("kreedz_lang.txt");
	register_dictionary("common.txt");

	bindOptions();
}

bindOptions() {
	g_Options[optIntMkeyBehavior] = find_option_by_name("mkey_behavior");
}

public OnCellValueChanged(id, optionId, newValue) {
	if (optionId == g_Options[optIntMkeyBehavior]) {
		g_UserData[id][ud_mkeyBehavior] = newValue;
	}
}

public client_putinserver(id) {
	g_UserData[id][ud_mkeyBehavior] = 0;
}

// 
// Commands
// 

public cmdMkeyHandler(id) {
	switch (g_UserData[id][ud_mkeyBehavior]) {
		case 1: amxclient_cmd(id, "spec");
		default: {
			cmdMainMenu(id);
		}
	}

	return PLUGIN_HANDLED;
}

public cmdMainMenu(id) {
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_TITLE");

	new iMenu = menu_create(szMsg, "MainMenu_Handler");

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_CP");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L^n", id, "MAINMENU_TP");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L^n", id, "MAINMENU_PAUSE");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_START");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L^n", id, "MAINMENU_NOCLIP");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_SPEC");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_INVIS");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_LJS");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_SETTINGS");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MAINMENU_MUTE");
	menu_additem(iMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "BACK");
	menu_setprop(iMenu, MPROP_BACKNAME, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "MORE");
	menu_setprop(iMenu, MPROP_NEXTNAME, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", id, "EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szMsg);

	menu_display(id, iMenu);

	return PLUGIN_HANDLED;
}

public MainMenu_Handler(id, menu, item) {
	menu_destroy(menu);

	switch(item) {
		case 0: amxclient_cmd(id, "cp");
		case 1: amxclient_cmd(id, "tp");
		case 2: amxclient_cmd(id, "p");
		case 3: amxclient_cmd(id, "start");
		case 4: amxclient_cmd(id, "nc");
		case 5: amxclient_cmd(id, "spec");
		case 6: {
			amxclient_cmd(id, "invis");
			return PLUGIN_HANDLED;
		}
		case 7: {
			amxclient_cmd(id, "say", "/ljsmenu");
			return PLUGIN_HANDLED;
		}
		case 8: {
			amxclient_cmd(id, "settings");
			return PLUGIN_HANDLED;
		}
		case 9: {
			amxclient_cmd(id, "mute");
			return PLUGIN_HANDLED;
		}
		default: return PLUGIN_HANDLED;
	}

	cmdMainMenu(id);

	return PLUGIN_HANDLED;
}


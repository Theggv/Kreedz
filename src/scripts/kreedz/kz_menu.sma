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

	register_dictionary("kz_mode.txt");

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
	formatex(szMsg, charsmax(szMsg), "Menu");
	
	new iMenu = menu_create(szMsg, "MainMenu_Handler");
	
	formatex(szMsg, charsmax(szMsg), "Checkpoint");
	menu_additem(iMenu, szMsg, "1", 0);
	
	formatex(szMsg, charsmax(szMsg), "Teleport^n");
	menu_additem(iMenu, szMsg, "2", 0);
	
	formatex(szMsg, charsmax(szMsg), "Pause / unpause^n");
	menu_additem(iMenu, szMsg, "3", 0);

	formatex(szMsg, charsmax(szMsg), "Start");
	menu_additem(iMenu, szMsg, "4", 0);

	formatex(szMsg, charsmax(szMsg), "Noclip^n");
	menu_additem(iMenu, szMsg, "5", 0);

	formatex(szMsg, charsmax(szMsg), "Spec");
	menu_additem(iMenu, szMsg, "6", 0);

	formatex(szMsg, charsmax(szMsg), "Invis");
	menu_additem(iMenu, szMsg, "7", 0);

	formatex(szMsg, charsmax(szMsg), "Ljsmenu");
	menu_additem(iMenu, szMsg, "8", 0);

	formatex(szMsg, charsmax(szMsg), "Settings");
	menu_additem(iMenu, szMsg, "9", 0);

	formatex(szMsg, charsmax(szMsg), "Mute");
	menu_additem(iMenu, szMsg, "10", 0);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public MainMenu_Handler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);
	
	switch(iItem) {
		case 1: amxclient_cmd(id, "cp");
		case 2: amxclient_cmd(id, "tp");
		case 3: amxclient_cmd(id, "p");
		case 4: amxclient_cmd(id, "start");
		case 5: amxclient_cmd(id, "nc");
		case 6: amxclient_cmd(id, "spec");
		case 7: {
			amxclient_cmd(id, "invis");
			return PLUGIN_HANDLED;
		}
		case 8: {
			amxclient_cmd(id, "say", "/ljsmenu");
			return PLUGIN_HANDLED;
		}
		case 9: {
			amxclient_cmd(id, "settings");
			return PLUGIN_HANDLED;
		}
		case 10: {
			amxclient_cmd(id, "mute");
			return PLUGIN_HANDLED;
		}
	}

	cmdMainMenu(id);

	return PLUGIN_HANDLED;
}


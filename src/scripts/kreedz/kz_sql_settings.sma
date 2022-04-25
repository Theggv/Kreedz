#include <amxmodx>
#include <cstrike>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>

#define PLUGIN 	 	"[Kreedz] Settings"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

new Handle:SQL_Tuple;

enum _:UserData
{
	ud_Settings[SettingsStruct],
	Float:ud_AntiFlood,
	bool:ud_isSaved
}

new g_UserData[MAX_PLAYERS + 1][UserData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("settings", "cmd_Settings");
}

public plugin_natives()
{
	register_native("kz_is_radio_enable", "native_is_radio_enable", 1);
}

public native_is_radio_enable(id)
{
	return g_UserData[id][ud_Settings][set_IsRadioEnable];
}

public client_disconnected(id)
{
	g_UserData[id][ud_AntiFlood] = 0.0;
	g_UserData[id][ud_Settings][set_IsSaveAngles] = true;
	g_UserData[id][ud_Settings][set_IsRadioEnable] = false;
	g_UserData[id][ud_isSaved] = true;
}

public client_putinserver(id)
{
	g_UserData[id][ud_AntiFlood] = 0.0;
	g_UserData[id][ud_Settings][set_IsSaveAngles] = true;
	g_UserData[id][ud_Settings][set_IsRadioEnable] = false;
	g_UserData[id][ud_isSaved] = true;
}

public kz_sql_initialized()
{
	SQL_Tuple = kz_sql_get_tuple();
}

public kz_sql_data_recv(id)
{
	new szQuery[512];
	formatex(szQuery, charsmax(szQuery), "\
		SELECT * FROM `kz_settings` \
		WHERE `uid` = %d;",
		kz_sql_get_user_uid(id));

	new szData[5];
	num_to_str(id, szData, charsmax(szData));
	SQL_ThreadQuery(SQL_Tuple, "@UserRun_Callback", szQuery, szData, charsmax(szData));
}

@UserRun_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "UserRun_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	if(SQL_NumResults(hQuery) > 0)
	{
		g_UserData[id][ud_Settings][set_IsSaveAngles] = bool:SQL_ReadResult(hQuery, 1);
		g_UserData[id][ud_Settings][set_IsRadioEnable] = bool:SQL_ReadResult(hQuery, 2);

		save_settings(id);
	}
	else
	{
		new szQuery[512];
		formatex(szQuery, charsmax(szQuery), "\
			INSERT INTO `kz_settings` (`uid`) \
			VALUES (%d);",
			kz_sql_get_user_uid(id));

		SQL_ThreadQuery(SQL_Tuple, "@WithoutAnswer_Callback", szQuery);

		kz_sql_data_recv(id);
	}

	return PLUGIN_HANDLED;
}

public cmd_Settings(id)
{
	new szMsg[256];
	formatex(szMsg, charsmax(szMsg), "\yKZ Settings");
	
	new iMenu = menu_create(szMsg, "Settings_Handler");
	
	formatex(szMsg, charsmax(szMsg), "Save angles: %s",
		g_UserData[id][ud_Settings][set_IsSaveAngles] ? "\yenable" : "\ddisable");
	
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "Radio commands: %s^n",
		g_UserData[id][ud_Settings][set_IsRadioEnable] ? "\yenable" : "\ddisable");
	
	menu_additem(iMenu, szMsg, "2", 0);

	formatex(szMsg, charsmax(szMsg), "Timer customization^n");
	menu_additem(iMenu, szMsg, "3", 0);

	if(!g_UserData[id][ud_isSaved])
	{
		formatex(szMsg, charsmax(szMsg), "\rSave settings");
		menu_additem(iMenu, szMsg, "4", 0);
	}

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public Settings_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);
	
	menu_destroy(menu);
	
	switch(iItem)
	{
		case 1:
		{
			g_UserData[id][ud_Settings][set_IsSaveAngles] = 
				!g_UserData[id][ud_Settings][set_IsSaveAngles];

			save_settings(id);
			g_UserData[id][ud_isSaved] = false;
		}
		case 2:
		{
			g_UserData[id][ud_Settings][set_IsRadioEnable] = 
				!g_UserData[id][set_IsRadioEnable];

			save_settings(id);
			g_UserData[id][ud_isSaved] = false;
		}
		case 3:
		{
			amxclient_cmd(id, "timersettings");

			return PLUGIN_HANDLED;
		}
		case 4:
		{
			if(g_UserData[id][ud_AntiFlood] > get_gametime() - 1.0)
			{
				client_print_color(id, print_team_default, "^4[KZ] ^1Please wait 1 second.");
			}
			else
			{
				g_UserData[id][ud_AntiFlood] = get_gametime();

				new szQuery[512];
				formatex(szQuery, charsmax(szQuery), "\
					UPDATE `kz_settings` \
					SET `is_save_angles` = %d, `is_radio_enable` = %d \
					WHERE `uid` = %d;",
					g_UserData[id][ud_Settings][set_IsSaveAngles], 
					g_UserData[id][ud_Settings][set_IsRadioEnable],
					kz_sql_get_user_uid(id));

				new szData[5];
				num_to_str(id, szData, charsmax(szData));
				SQL_ThreadQuery(SQL_Tuple, "@Save_Callback", szQuery, szData, charsmax(szData));
			}
		}
	}

	cmd_Settings(id);

	return PLUGIN_HANDLED;
}

@Save_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "Save_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	new id = str_to_num(szData);

	client_print_color(id, print_team_default, "^4[KZ] ^1Settings have been saved.");

	g_UserData[id][ud_isSaved] = true;
	cmd_Settings(id);

	return PLUGIN_HANDLED;
}

@WithoutAnswer_Callback(QueryState, Handle:hQuery, szError[], iError, szData[], iLen, Float:fQueryTime)
{
	switch(QueryState)
	{
		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:
		{
			UTIL_LogToFile(MYSQL_LOG, "ERROR", "WithoutAnswer_Callback", "[%d] %s (%.2f sec)", iError, szError, fQueryTime);
			SQL_FreeHandle(hQuery);
			
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

save_settings(id)
{
	new settings[SettingsStruct];
	settings[set_IsSaveAngles] = g_UserData[id][ud_Settings][set_IsSaveAngles];
	settings[set_IsRadioEnable] = g_UserData[id][ud_Settings][set_IsRadioEnable];
	kz_set_settings(id, settings);
}
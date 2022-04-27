#include <amxmodx>
#include <cstrike>
#include <sqlx>

#include <kreedz_api>
#include <kreedz_sql>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Settings: Timer"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

new Handle:SQL_Tuple;

enum _:UserData
{
	ud_Settings[TimerStruct],
	Float:ud_AntiFlood,
	bool:ud_isSaved
}

new g_UserData[MAX_PLAYERS + 1][UserData];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	kz_register_cmd("timer", "cmd_Settings");
	kz_register_cmd("timersettings", "cmd_Settings");

	register_clcmd("timer_var", "cmd_TimerVariable");
}

public client_disconnected(id)
{
	g_UserData[id][ud_AntiFlood] = 0.0;
	g_UserData[id][ud_isSaved] = true;
}

public client_putinserver(id)
{
	g_UserData[id][ud_AntiFlood] = 0.0;
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
		SELECT * FROM `kz_settings_timer` \
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
		g_UserData[id][ud_Settings][timer_RGB] = SQL_ReadResult(hQuery, 1);
		g_UserData[id][ud_Settings][timer_X] = Float:SQL_ReadResult(hQuery, 2);
		g_UserData[id][ud_Settings][timer_Y] = Float:SQL_ReadResult(hQuery, 3);
		g_UserData[id][ud_Settings][timer_isDhud] = bool:SQL_ReadResult(hQuery, 4);
		g_UserData[id][ud_Settings][timer_Type] = SQL_ReadResult(hQuery, 5); // ne ispol'zuetsya
		g_UserData[id][ud_Settings][timer_MS] = bool:SQL_ReadResult(hQuery, 6);

		save_settings(id);
	}
	else
	{
		new szQuery[512];
		formatex(szQuery, charsmax(szQuery), "\
			INSERT INTO `kz_settings_timer` (`uid`) \
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
	formatex(szMsg, charsmax(szMsg), "\yTimer customization");
	
	new iMenu = menu_create(szMsg, "Settings_Handler");
	
	new rgb[3];
	rgb = UTIL_RGBUnpack(g_UserData[id][ud_Settings][timer_RGB]);

	formatex(szMsg, charsmax(szMsg), "Red: \y%d \d| (0 - 255)", rgb[0]);
	menu_additem(iMenu, szMsg, "1", 0);

	formatex(szMsg, charsmax(szMsg), "Green: \y%d \d| (0 - 255)", rgb[1]);
	menu_additem(iMenu, szMsg, "2", 0);

	formatex(szMsg, charsmax(szMsg), "Blue: \y%d \d| (0 - 255)^n", rgb[2]);
	menu_additem(iMenu, szMsg, "3", 0);

	formatex(szMsg, charsmax(szMsg), "X: %.2f \d| (0.00 - 1.00, -1.0)", 
		g_UserData[id][ud_Settings][timer_X]);
	menu_additem(iMenu, szMsg, "4", 0);

	formatex(szMsg, charsmax(szMsg), "Y: %.2f \d| (0.00 - 1.00, -1.0)^n", 
		g_UserData[id][ud_Settings][timer_Y]);
	menu_additem(iMenu, szMsg, "5", 0);

	formatex(szMsg, charsmax(szMsg), "Director hud: %s^n", 
		g_UserData[id][ud_Settings][timer_isDhud] ? "\yenable" : "\ddisable");

	menu_additem(iMenu, szMsg, "6", 0);

	if(!g_UserData[id][ud_isSaved])
	{
		formatex(szMsg, charsmax(szMsg), "\rSave settings");
		menu_additem(iMenu, szMsg, "7", 0);
	}

	formatex(szMsg, charsmax(szMsg), "Milliseconds: %s^n", 
		g_UserData[id][ud_Settings][timer_MS] ? "\yenable" : "\ddisable");

	menu_additem(iMenu, szMsg, "9", 0);

	formatex(szMsg, charsmax(szMsg), "Back to default");
	menu_additem(iMenu, szMsg, "8", 0);

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
			client_cmd(id, "messagemode ^"timer_var red^"");
		}
		case 2:
		{
			client_cmd(id, "messagemode ^"timer_var green^"");
		}
		case 3:
		{
			client_cmd(id, "messagemode ^"timer_var blue^"");
		}
		case 4:
		{
			client_cmd(id, "messagemode ^"timer_var x^"");
		}
		case 5:
		{
			client_cmd(id, "messagemode ^"timer_var y^"");
		}
		case 6:
		{
			g_UserData[id][ud_Settings][timer_isDhud] = 
				!g_UserData[id][ud_Settings][timer_isDhud];

			g_UserData[id][ud_isSaved] = false;

			save_settings(id);
			cmd_Settings(id);
		}
		case 7:
		{
			if(g_UserData[id][ud_AntiFlood] > get_gametime() - 1.0)
			{
				client_print_color(id, print_team_default, "^4[KZ] ^1Please wait 1 second.");
				cmd_Settings(id);
			}
			else
			{
				g_UserData[id][ud_AntiFlood] = get_gametime();

				new szQuery[512];
				formatex(szQuery, charsmax(szQuery), "\
					UPDATE `kz_settings_timer` \
					SET `rgb` = %d, `x` = %d, `y` = %d, `is_dhud` = %d, `type` = %d, `is_ms` = %d \
					WHERE `uid` = %d;",
					g_UserData[id][ud_Settings][timer_RGB], 
					g_UserData[id][ud_Settings][timer_X],
					g_UserData[id][ud_Settings][timer_Y],
					g_UserData[id][ud_Settings][timer_isDhud],
					g_UserData[id][ud_Settings][timer_Type],
					g_UserData[id][ud_Settings][timer_MS],
					kz_sql_get_user_uid(id));

				new szData[5];
				num_to_str(id, szData, charsmax(szData));
				SQL_ThreadQuery(SQL_Tuple, "@Save_Callback", szQuery, szData, charsmax(szData));
			}
		}
		case 8:
		{
			g_UserData[id][ud_Settings][timer_RGB] = 51200;
			g_UserData[id][ud_Settings][timer_X] = 0.02;
			g_UserData[id][ud_Settings][timer_Y] = 0.2;
			g_UserData[id][ud_Settings][timer_isDhud] = false;
			g_UserData[id][ud_Settings][timer_MS] = false;
			g_UserData[id][ud_isSaved] = false;

			save_settings(id);
			cmd_Settings(id);
		}
		case 9:
		{
			g_UserData[id][ud_Settings][timer_MS] = 
				!g_UserData[id][ud_Settings][timer_MS];

			g_UserData[id][ud_isSaved] = false;

			save_settings(id);
			cmd_Settings(id);
		}
	}

	return PLUGIN_HANDLED;
}

public cmd_TimerVariable(id)
{
	new szOption[16], szValue[16];
	read_argv(1, szOption, charsmax(szOption));
	read_argv(2, szValue, charsmax(szValue));

	if(equal(szOption, "red"))
	{
		if(is_str_num(szValue))
		{
			new rgb[3];
			rgb = UTIL_RGBUnpack(g_UserData[id][ud_Settings][timer_RGB]);
			rgb[0] = clamp(str_to_num(szValue), 0, 255);

			g_UserData[id][ud_Settings][timer_RGB] = UTIL_RGBPack(rgb[0], rgb[1], rgb[2]);
		}
	}
	else if(equal(szOption, "green"))
	{
		if(is_str_num(szValue))
		{
			new rgb[3];
			rgb = UTIL_RGBUnpack(g_UserData[id][ud_Settings][timer_RGB]);
			rgb[1] = clamp(str_to_num(szValue), 0, 255);

			g_UserData[id][ud_Settings][timer_RGB] = UTIL_RGBPack(rgb[0], rgb[1], rgb[2]);
		}
	}
	else if(equal(szOption, "blue"))
	{
		if(is_str_num(szValue))
		{
			new rgb[3];
			rgb = UTIL_RGBUnpack(g_UserData[id][ud_Settings][timer_RGB]);
			rgb[2] = clamp(str_to_num(szValue), 0, 255);

			g_UserData[id][ud_Settings][timer_RGB] = UTIL_RGBPack(rgb[0], rgb[1], rgb[2]);
		}
	}
	else if(equal(szOption, "x"))
	{
		if(str_to_float(szValue))
		{
			if(str_to_float(szValue) == -1.0)
				g_UserData[id][ud_Settings][timer_X] = -1.0;
			else
			{
				g_UserData[id][ud_Settings][timer_X] =
					floatclamp(str_to_float(szValue), 0.0, 1.0);
			}
		}
	}
	else if(equal(szOption, "y"))
	{
		if(str_to_float(szValue))
		{
			if(str_to_float(szValue) == -1.0)
				g_UserData[id][ud_Settings][timer_Y] = -1.0;
			else
			{
				g_UserData[id][ud_Settings][timer_Y] =
					floatclamp(str_to_float(szValue), 0.0, 1.0);
			}
		}
	}

	g_UserData[id][ud_isSaved] = false;
	save_settings(id);

	// r g b x y dhud

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
	new settings[TimerStruct];
	settings[timer_RGB] = g_UserData[id][ud_Settings][timer_RGB];
	settings[timer_X] = g_UserData[id][ud_Settings][timer_X];
	settings[timer_Y] = g_UserData[id][ud_Settings][timer_Y];
	settings[timer_isDhud] = g_UserData[id][ud_Settings][timer_isDhud];
	settings[timer_Type] = g_UserData[id][ud_Settings][timer_Type];
	settings[timer_MS] = g_UserData[id][ud_Settings][timer_MS];
	kz_set_timer_data(id, settings);
}
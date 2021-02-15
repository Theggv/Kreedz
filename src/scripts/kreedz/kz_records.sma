#include <amxmodx>
#include <curl>

#include <kreedz/kz_api>

#pragma semicolon 1

#define PLUGIN "KZ Records"
#define VERSION "1.6b"
#define AUTHOR "SchlumPF"

#define ADMIN_FLAG ADMIN_KICK

#define MAX 3
#define SAY 2
#define EXT 6

new g_CountryAdjective[MAX][] =
{
	"World",
	"Cosy",
	"KZ-Rush"
};

new g_SayCommands[MAX][SAY][] =
{
	{ "/xj", "/wr" },
	{ "/cosy", "" },
	{ "/ru", "/rush" }
};

new g_DownloadLink[MAX][] =
{
	"https://xtreme-jumps.eu/demos.txt",
	"https://cosy-climbing.net/demos.txt",
	"https://kz-rush.ru/demos.txt"
};

new g_RecordsFileSuffix[MAX][] =
{
	"xj",
	"cosy",
	"ru"
};

new g_Skip[MAX][] =
{
	"Xtreme-Jumps.eu ",
	"www.cosy-climbing.net",
	"kz-rush.ru - International Kreedz Community"
};

new g_flRecordsFile[MAX][256];

new g_iColors[3] = { 255, 255, 255 };
new Float:g_fShowtime = 3.0;
new Float:g_fCoords[2] = { 0.01, 0.2 };

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_clcmd( "say", "hookSay" );
	
	// register_concmd( "kz_records_coords", "cmdChangeShowtime"  );
	// register_concmd( "kz_records_coords", "cmdChangeCoords"  );
	// register_concmd( "kz_records_color", "cmdChangeColor" );
}

public write(data[], size, nmemb, file)
{
   new actual_size = size * nmemb;
   
   fwrite_blocks(file, data, actual_size, BLOCK_CHAR);
   
   return actual_size;
}

public complite(CURL:curl, CURLcode:code, data[])
{
	if(code == CURLE_WRITE_ERROR)
		server_print("transfer aborted");
	else
		server_print("curl complete");

	fclose(data[0]);
	curl_easy_cleanup(curl);
}

public plugin_cfg( )
{
	new temp[256];
	get_localinfo( "amxx_datadir", temp, 255 );
	format( temp, 255, "%s/kz_records", temp );
	
	if( !dir_exists( temp ) )
	{
		mkdir( temp );
	}
	
	for( new i ; i < MAX ; i++ )
	{
		format( g_flRecordsFile[i], 255, "%s/demos_%s.txt", temp, g_RecordsFileSuffix[i] );
	}
	
	format( temp, 255, "%s/last_update.ini", temp );
	
	if( !file_exists( temp ) )
	{
		fnUpdate( );
		return PLUGIN_CONTINUE;
	}
	
	new year, month, day;
	date( year, month, day );
	
	new f = fopen( temp, "rt" );
	fgets( f, temp, 255 );
	fclose( f );
	
	if( str_to_num( temp[0] ) > year || str_to_num( temp[5] ) > month || str_to_num( temp[8] ) > day )
	{
		fnUpdate( );
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public hookSay( plr )
{
	static msg[512], cmd[32], map[32];
	read_args( cmd, 31 );
	remove_quotes( cmd );
	
	if( !cmd[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	for( new i ; i < MAX ; i++ )
	{
		for( new j ; j < SAY ; j++ )
		{
			if( !equali( cmd, g_SayCommands[i][j] ) )
			{
				continue;
			}
			
			new author[EXT][32], Float:kztime[8], extension[EXT][8], len, founds;
			
			get_mapname( map, 31 );
			founds = get_record_data( i, map, author, kztime, extension );
			len = format( msg, 511, "%s Record of %s:", g_CountryAdjective[i], map );
			
			if( author[0][0] )
			{
				for( new x ; x < founds ; x++ )
				{
					if( !author[x][0] )
						break;
					
					new szTime[64];
					UTIL_FormatTime(kztime[x], szTime, charsmax(szTime), true);

					if( extension[x][0] )
					{
						// len += format( msg[len], 511 - len, "^n   [%s] %s (%s) ", extension[x], author[x], szTime);
						continue;
					}
					else
					{
						len += format( msg[len], 511 - len, "^n   %s (%s) ", author[x], szTime);
						break;
					}
				}
			}
			else
			{
				add(msg[len], 511, fmt("^n   N/A (**:**)"));
			}
			
			set_hudmessage( g_iColors[0], g_iColors[1], g_iColors[2], g_fCoords[0], g_fCoords[1], _, _, g_fShowtime, _, _, 3 );
			show_hudmessage( plr, msg );

			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public get_record_data( i, map[], author[][32], Float:kztime[8], extension[][8] )
{
	static szData[256], szMap[64], szTime[8], szExtension[8], szTemp[32], szAuthor[32];
	new founds, f;
	
	f = fopen( g_flRecordsFile[i], "rt" );
	while( !feof( f ) )
	{
		fgets( f, szData, charsmax(szData) );
		
		if( equali( szData, g_Skip[i] ) )
			continue;
		
		if( !equali( szData, map, strlen( map ) ) )
			continue;

		replace_all(szData, charsmax(szData), "^n", "");

		switch(i)
		{
			case 0:
				parse(szData, szMap, 63, szTime, 7, szAuthor, 31, szTemp, 31, szTemp, 31);
			case 1:
				parse(szData, szMap, 63, szTime, 7, szTemp, 31, szTemp, 31,
					szTemp, 31, szTemp, 31, szAuthor, 31);
			case 2:
				parse(szData, szMap, 63, szTime, 7, szAuthor, 31, szTemp, 31);
		}
		
		kztime[founds] = str_to_float( szTime );
		copy( author[founds], 32, szAuthor );
		
		if( containi( szMap, "[" ) && containi( szMap, "]" ) )
		{
			strtok(szMap, szMap, charsmax(szMap), szExtension, charsmax(szExtension), '[');
			replace_all(szExtension, charsmax(szExtension), "]", "");
			
			copy(extension[founds], 32, szExtension);
		}
		
		founds++;
	}

	fclose( f );
	
	return founds;
}

public fnUpdate( )
{
	for(new i; i < MAX; ++i)
	{
		new data[1];
		data[0] = fopen(g_flRecordsFile[i], "wb");

		new CURL:curl = curl_easy_init();

		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1);
		curl_easy_setopt(curl, CURLOPT_CAINFO, "cstrike/addons/amxmodx/data/cert/cacert.pem");
		curl_easy_setopt(curl, CURLOPT_BUFFERSIZE, 512);
		curl_easy_setopt(curl, CURLOPT_URL, g_DownloadLink[i]);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, data[0]);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, "write");
		curl_easy_perform(curl, "complite", data, sizeof(data));
	}

	new temp[256];
	get_localinfo( "amxx_datadir", temp, 255 );
	format( temp, 255, "%s/kz_records/last_update.ini", temp );
	
	new year, month, day;
	date( year, month, day );
	
	if( file_exists( temp ) )
	{
		delete_file( temp );
	}
	
	new f = fopen( temp, "wt" );
	format( temp, 255, "%04ix%02ix%02i", year, month, day );
	fputs( f, temp );
	fclose( f );
}

public cmdChangeShowTime( plr )
{
	if( !( get_user_flags( plr ) & ADMIN_FLAG ) )
	{
		client_print( plr, print_console, "* You have no access to this command" );
		return PLUGIN_HANDLED;
	}
	
	if( read_argc( ) != 2 )
	{
		client_print( plr, print_console, "Usage: kz_godmode_showtime <time>" );
		return PLUGIN_HANDLED;
	}
	
	new showtime[32];
	read_argv( 1, showtime, 31 );
	
	g_fShowtime = floatclamp( str_to_float( showtime ), 0.0, 1000000.0 );
	
	client_print( plr, print_console, "kz_godmode_showtime changed to ^"%f^"", g_fShowtime );
	
	return PLUGIN_HANDLED;
}

public cmdChangeCoords( plr )
{	
	if( !( get_user_flags( plr ) & ADMIN_FLAG ) )
	{
		client_print( plr, print_console, "* You have no access to this command" );
		return PLUGIN_HANDLED;
	}
	
	if( read_argc( ) != 3 )
	{
		client_print( plr, print_console, "Usage: kz_records_coords <x> <y>" );
		return PLUGIN_HANDLED;
	}
	
	new x_str[6], y_str[6];
	read_argv( 1, x_str, 5 );
	read_argv( 2, y_str, 5 );
	
	g_fCoords[0] = floatclamp( str_to_float( x_str ), -1.0, 1.0 );
	g_fCoords[1] = floatclamp( str_to_float( y_str ), -1.0, 1.0 );
	
	client_print( plr, print_console, "kz_records_coords changed to ^"%f %f^"", g_fCoords[0], g_fCoords[1] );
	
	return PLUGIN_HANDLED;
}

public cmdChangeColor( plr )
{
	if( !( get_user_flags( plr ) & ADMIN_FLAG ) )
	{
		client_print( plr, print_console, "* You have no access to this command" );
		return PLUGIN_HANDLED;
	}
	
	if( read_argc( ) != 4 )
	{
		client_print( plr, print_console, "Usage: kz_records_color <red> <green> <blue>" );
		return PLUGIN_HANDLED;
	}
		
	new r_str[4], g_str[4], b_str[4];
	read_argv( 1, r_str, 3 );
	read_argv( 2, g_str, 3 );
	read_argv( 3, b_str, 3 );
	
	g_iColors[0] = clamp( str_to_num( r_str ), 0, 255 );
	g_iColors[1] = clamp( str_to_num( g_str ), 0, 255 );
	g_iColors[2] = clamp( str_to_num( b_str ), 0, 255 );
	
	client_print( plr, print_console, "kz_records_color changed to ^"%i %i %i^"", g_iColors[0], g_iColors[1], g_iColors[2] );	
	
	return PLUGIN_HANDLED;
}

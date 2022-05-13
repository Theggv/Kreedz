#include <amxmodx>
#include <fakemeta>
#include <xs>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Measure"
#define VERSION 	"3.4"
#define AUTHOR	 	"SchlumPF"


#pragma semicolon 1

#define TASK_BEAM 45896

new Float:g_vFirstLoc[33][3];
new Float:g_vSecondLoc[33][3];

new bool:g_bReturnFloat[33];
new bool:g_bShowBeams[33];
new bool:g_bDetailedResults[33];
new bool:g_bAutoSetting[33];

new g_iColors[3] = { 255, 85, 0 };

new g_flBeam;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_concmd( "measure_color", "cmdChangeColor" );
	
	kz_register_cmd("measure", "cmdMeasure");
	kz_register_cmd("dist", "cmdMeasure");
	kz_register_cmd("distance", "cmdMeasure");
	
	register_menucmd( register_menuid( "\rMeasure - SchlumPF^n^n" ), 1023, "menuAction" );
}

public plugin_precache( )
{
	g_flBeam = precache_model( "sprites/zbeam4.spr" );
}

public cmdMeasure( plr )
{
	pev( plr, pev_origin, g_vFirstLoc[plr] );
	g_vFirstLoc[plr][2] -= is_user_ducking( plr ) ? 18 : 36;
	g_vSecondLoc[plr] = g_vFirstLoc[plr];

	if( g_bShowBeams[plr] && !task_exists( plr + TASK_BEAM ) )
	{
		set_task( 0.1, "tskBeam", plr + TASK_BEAM, _, _, "ab" );
	}
	
	menuDisplay( plr );
	
	//return PLUGIN_HANDLED;
}


public cmdChangeColor( plr )
{
	if( !( get_user_flags( plr ) & ADMIN_KICK ) )
	{
		client_print( plr, print_console, "* You have no access to this command" );
		return PLUGIN_HANDLED;
	}
	
	if( read_argc( ) != 4 )
	{
		client_print( plr, print_console, "Usage: measure_color <red> <green> <blue>" );
		return PLUGIN_HANDLED;
	}
		
	new r_str[4], g_str[4], b_str[4];
	read_argv( 1, r_str, 3 );
	read_argv( 2, g_str, 3 );
	read_argv( 3, b_str, 3 );
	
	g_iColors[0] = clamp( str_to_num( r_str ), 0, 255 );
	g_iColors[1] = clamp( str_to_num( g_str ), 0, 255 );
	g_iColors[2] = clamp( str_to_num( b_str ), 0, 255 );
	
	client_print( plr, print_console, "measure_color changed to ^"%i %i %i^"", g_iColors[0], g_iColors[1], g_iColors[2] );	
	
	return PLUGIN_HANDLED;
}	
public menuDisplay( plr )
{
	static menu[2048];
	
	new len = format( menu, 2047, "\rMeasure - SchlumPF^n^n" );
	
	if( g_bReturnFloat[plr] )
	{
		len += format( menu[len], 2047 - len, "\r01. \wSet Loc #1 \d< %.03f | %.03f | %.03f >^n", g_vFirstLoc[plr][0], g_vFirstLoc[plr][1], g_vFirstLoc[plr][2] );
		len += format( menu[len], 2047 - len, "\r02. \wSet Loc #2 \d< %.03f | %.03f | %.03f >^n^n", g_vSecondLoc[plr][0], g_vSecondLoc[plr][1], g_vSecondLoc[plr][2] );
		len += format( menu[len], 2047 - len, "\r03. \wAutomatical setting of the other Loc: \d%s^n^n", g_bAutoSetting[plr] ? "on" : "off" );
		len += format( menu[len], 2047 - len, "\r04. \wDetailed results: \d%s^n", g_bDetailedResults[plr] ? "on" : "off" );
		len += format( menu[len], 2047 - len, "\r05. \wReturned values: \ddecimal^n^n" );
		len += format( menu[len], 2047 - len, "\r      \wResults:^n" );
		
		if( g_bDetailedResults[plr] )
		{
			len += format( menu[len], 2047 - len, "\r      \wX-Distance: \d%f^n", floatabs( g_vFirstLoc[plr][0] - g_vSecondLoc[plr][0] ) );
			len += format( menu[len], 2047 - len, "\r      \wY-Distance: \d%f^n", floatabs( g_vFirstLoc[plr][1] - g_vSecondLoc[plr][1] ) );
		}
		
		len += format( menu[len], 2047 - len, "\r      \wHeight difference: \d%f^n", floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) );
		len += format( menu[len], 2047 - len, "\r      \wReal distance: \d%f^n^n", get_distance_f( g_vFirstLoc[plr], g_vSecondLoc[plr] ) );
	}
	else
	{
		len += format( menu[len], 2047 - len, "\r01. \wSet Loc #1 \d< %i | %i | %i >^n", floatround( g_vFirstLoc[plr][0], floatround_round ), floatround( g_vFirstLoc[plr][1], floatround_round ), floatround( g_vFirstLoc[plr][2], floatround_round ) );
		len += format( menu[len], 2047 - len, "\r02. \wSet Loc #2 \d< %i | %i | %i >^n^n", floatround( g_vSecondLoc[plr][0], floatround_round ), floatround( g_vSecondLoc[plr][1], floatround_round ), floatround( g_vSecondLoc[plr][2], floatround_round ) );
		len += format( menu[len], 2047 - len, "\r03. \wAutomatical setting of the other Loc: \d%s^n^n", g_bAutoSetting[plr] ? "on" : "off" );
		len += format( menu[len], 2047 - len, "\r04. \wDetailed results: \d%s^n", g_bDetailedResults[plr] ? "on" : "off" );
		len += format( menu[len], 2047 - len, "\r05 \wReturned values: \drounded^n^n" );
		len += format( menu[len], 2047 - len, "\r      \wResults:^n" );
		
		if( g_bDetailedResults[plr] )
		{
			len += format( menu[len], 2047 - len, "\r      \wX-Distance: \d%i^n", floatround( floatabs( g_vFirstLoc[plr][0] - g_vSecondLoc[plr][0] ), floatround_round ) );
			len += format( menu[len], 2047 - len, "\r      \wY-Distance: \d%i^n", floatround( floatabs( g_vFirstLoc[plr][1] - g_vSecondLoc[plr][1] ), floatround_round ) );
		}
		
		len += format( menu[len], 2047 - len, "\r      \wHeight difference: \d%i^n", floatround( floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ), floatround_round ) );
		len += format( menu[len], 2047 - len, "\r      \wReal distance: \d%i^n^n", floatround( get_distance_f( g_vFirstLoc[plr], g_vSecondLoc[plr] ), floatround_round ) );
		
	}
	
	len += format( menu[len], 2047 - len, "\r06. \wShow beams: \d%s^n^n", g_bShowBeams[plr] ? "on" : "off" );
	len += format( menu[len], 2047 - len, "\r00. \wExit" );
	
	show_menu( plr, ( 1<<0 | 1<<1 | 1<<2 | 1<<3 | 1<<4 | 1<<9 ), menu, -1 );
}

public menuAction( plr, key )
{
	switch( key )
	{
		case 0:
		{
			fm_get_aim_origin( plr, g_vFirstLoc[plr] );
			
			if( g_bAutoSetting[plr] )
			{
				get_tr2( 0, TR_vecPlaneNormal, g_vSecondLoc[plr] );
				
				xs_vec_mul_scalar( g_vSecondLoc[plr], 9999.0, g_vSecondLoc[plr] );
				xs_vec_add( g_vFirstLoc[plr], g_vSecondLoc[plr], g_vSecondLoc[plr] );

				fm_trace_line( plr, g_vFirstLoc[plr], g_vSecondLoc[plr], g_vSecondLoc[plr] );
			}

			menuDisplay( plr );
		}
		case 1:
		{
			fm_get_aim_origin( plr, g_vSecondLoc[plr] );

			if( g_bAutoSetting[plr] )
			{
				get_tr2( 0, TR_vecPlaneNormal, g_vFirstLoc[plr] );

				xs_vec_mul_scalar( g_vFirstLoc[plr], 9999.0, g_vFirstLoc[plr] );
				xs_vec_add( g_vFirstLoc[plr], g_vSecondLoc[plr], g_vFirstLoc[plr] );

				fm_trace_line( plr, g_vSecondLoc[plr], g_vFirstLoc[plr], g_vFirstLoc[plr] );
			}

			menuDisplay( plr );
		}
		case 2:
		{
			g_bAutoSetting[plr] = !g_bAutoSetting[plr];
			menuDisplay( plr );
		}
		case 3:
		{
			g_bDetailedResults[plr] = !g_bDetailedResults[plr];
			menuDisplay( plr );
		}
		case 4:
		{
			g_bReturnFloat[plr] = !g_bReturnFloat[plr];
			menuDisplay( plr );
		}
		case 5:
		{
			g_bShowBeams[plr] = !g_bShowBeams[plr];
			
			if( !g_bShowBeams[plr] && task_exists( plr + TASK_BEAM ) )
			{
				remove_task( plr + TASK_BEAM );
			}
			else
			{
				set_task( 0.1, "tskBeam", plr + TASK_BEAM, _, _, "ab" );
			}

			menuDisplay( plr );
		}
		case 9:
		{
			remove_task( plr + TASK_BEAM );
			show_menu( plr, 0, "" );
		}
	}
}

public tskBeam( plr )
{
	plr -= TASK_BEAM;
	
	draw_beam( plr, g_vFirstLoc[plr], g_vSecondLoc[plr], g_iColors[0], g_iColors[1], g_iColors[2] );
	
	if( floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) >= 2 )
	{
		static Float:temp[3];
		temp[0] = g_vSecondLoc[plr][0];
		temp[1] = g_vSecondLoc[plr][1];
		temp[2] = g_vFirstLoc[plr][2];
		
		draw_beam( plr, g_vFirstLoc[plr], temp, g_iColors[0], g_iColors[1], g_iColors[2] );
		draw_beam( plr, temp, g_vSecondLoc[plr], g_iColors[0], g_iColors[1], g_iColors[2] );
	}
}

public draw_beam( plr, Float:aorigin[3], Float:borigin[3], r, g, b )
{	

	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0.0, 0.0, 0.0 }, plr );
	write_byte( TE_BEAMPOINTS );
	engfunc( EngFunc_WriteCoord, aorigin[0] );
	engfunc( EngFunc_WriteCoord, aorigin[1] );
	engfunc( EngFunc_WriteCoord, aorigin[2] );
	engfunc( EngFunc_WriteCoord, borigin[0] );
	engfunc( EngFunc_WriteCoord, borigin[1] );
	engfunc( EngFunc_WriteCoord, borigin[2] );
	write_short( g_flBeam );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 2 );
	write_byte( 20 );
	write_byte( 0 );
	write_byte( r );
	write_byte( g );
	write_byte( b );
	write_byte( 150 );
	write_byte( 0 );
	message_end( );
}

public client_connect( plr )
{
	g_bShowBeams[plr] = true;
	g_bReturnFloat[plr] = true;
	g_bDetailedResults[plr] = false;
	g_bAutoSetting[plr] = false;
}

is_user_ducking( plr )
{
	if( !pev_valid( plr )  )
	{
		return 0;
	}
	
	new Float:abs_min[3], Float:abs_max[3];
	pev( plr, pev_absmin, abs_min );
	pev( plr, pev_absmax, abs_max );
	
	abs_min[2] += 64.0;
	
	if( abs_min[2] < abs_max[2] )
	{
		return 0;
	}
	
	return 1;
}

fm_get_aim_origin( plr, Float:origin[3] )
{
	new Float:start[3], Float:view_ofs[3];
	pev( plr, pev_origin, start );
	pev( plr, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );

	new Float:dest[3];
	pev( plr, pev_v_angle, dest );
	engfunc( EngFunc_MakeVectors, dest);
	global_get( glb_v_forward, dest );
	xs_vec_mul_scalar( dest, 9999.0, dest );
	xs_vec_add( start, dest, dest );

	engfunc( EngFunc_TraceLine, start, dest, 0, plr, 0 );
	get_tr2( 0, TR_vecEndPos, origin );

	return 1;
}

fm_trace_line( ignoreent, const Float:start[3], const Float:end[3], Float:ret[3] )
{
	engfunc( EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0 );
	
	new ent = get_tr2( 0, TR_pHit );
	get_tr2( 0, TR_vecEndPos, ret );
	
	return pev_valid( ent ) ? ent : 0;
}

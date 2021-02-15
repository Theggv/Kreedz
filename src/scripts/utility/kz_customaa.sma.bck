#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <reapi>

// api
#include <kreedz/kz_api>

#define PLUGIN 	 	"[Kreedz] Custom aa"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

new Float:g_CustomAirAccelerate[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /10", "cmd_10aa");
	register_clcmd("say /100", "cmd_100aa");

	// RegisterHookChain(RG_PM_Move, "PM_Move_Pre", false);
	RegisterHookChain(RG_PM_AirMove, "PM_AirMove_Pre", false);
	RegisterHookChain(RG_PM_AirMove, "PM_AirMove_Post", true);
	RegisterHam(Ham_Player_PreThink, "player", "RG_UpdateClientData_Pre");
	// RegisterHookChain(RG_CBasePlayer_UpdateClientData, "RG_UpdateClientData_Pre", true);
}

public cmd_10aa(id)
{
	g_CustomAirAccelerate[id] = 10.0;

	message_begin( MSG_ONE, SVC_NEWMOVEVARS, .player = id);
	{
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_gravity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stopspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_spectatormaxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_accelerate" ) ));
		write_long( floatround(g_CustomAirAccelerate[id]));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateraccelerate" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_friction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "edgefriction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_waterfriction" ) ));
		write_long( _:1.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_bounce" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stepsize" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxvelocity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_zmax" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateramp" ) ));
		write_byte( !!get_pcvar_float(get_cvar_pointer( "mp_footsteps" ) ));
		write_long( _:0.0 );
		write_long( _:0.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_r" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_g" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_b" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_x" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_y" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_z" ) ));
		write_string( "blue" );
	}
	message_end();

	return PLUGIN_HANDLED;
}

public cmd_100aa(id)
{
	g_CustomAirAccelerate[id] = 100.0;

	message_begin( MSG_ONE, SVC_NEWMOVEVARS, .player = id);
	{
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_gravity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stopspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_spectatormaxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_accelerate" ) ));
		write_long( floatround(g_CustomAirAccelerate[id]) );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateraccelerate" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_friction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "edgefriction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_waterfriction" ) ));
		write_long( _:1.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_bounce" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stepsize" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxvelocity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_zmax" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateramp" ) ));
		write_byte( !!get_pcvar_float(get_cvar_pointer( "mp_footsteps" ) ));
		write_long( _:0.0 );
		write_long( _:0.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_r" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_g" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_b" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_x" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_y" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_z" ) ));
		write_string( "blue" );
	}
	message_end();

	return PLUGIN_HANDLED;
}

public client_connect(id)
{
	g_CustomAirAccelerate[id] = 10.0;
}

// public PM_Move_Pre(const PlayerMove:ppmove, const server)
// {

// }

public PM_AirMove_Pre(const playerIndex)
{
	set_movevar(mv_airaccelerate, g_CustomAirAccelerate[playerIndex]);
}

public PM_AirMove_Post(const playerIndex)
{
	set_movevar(mv_airaccelerate, 10.0);
}

public RG_UpdateClientData_Pre(const playerIndex)
{
	message_begin( MSG_ONE, SVC_NEWMOVEVARS, .player = playerIndex);
	{
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_gravity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stopspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_spectatormaxspeed" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_accelerate" ) ));
		write_long( floatround(g_CustomAirAccelerate[playerIndex]) );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateraccelerate" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_friction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "edgefriction" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_waterfriction" ) ));
		write_long( _:1.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_bounce" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_stepsize" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_maxvelocity" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_zmax" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_wateramp" ) ));
		write_byte( !!get_pcvar_float(get_cvar_pointer( "mp_footsteps" ) ));
		write_long( _:0.0 );
		write_long( _:0.0 );
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_r" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_g" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skycolor_b" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_x" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_y" ) ));
		write_long( _:get_pcvar_float(get_cvar_pointer( "sv_skyvec_z" ) ));
		write_string( "blue" );
	}
	message_end();
}
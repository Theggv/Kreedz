#if defined _kreedz_api_included
	#endinput
#endif

#define _kreedz_api_included

enum _:KZReturn {
	KZ_CONTINUE = 0,
	KZ_SUPERCEDE,
};

enum TimerState {
	TIMER_DISABLED,
	TIMER_PAUSED,
	TIMER_ENABLED,
};

enum _:PosStruct {
	Float:pos_x,
	Float:pos_y,
	Float:pos_z,
};

enum _:RunStruct {
	Float:run_time,
	run_cpCount,
	run_tpCount,
	run_weapon,
	run_airaccelerate,
};

enum _: {
    CHANNEL_HUD = 2,
};

enum _:AirAccelerateEnum {
	AIR_ACCELERATE_10 = 0,
	AIR_ACCELERATE_100 = 1,
};

enum _:WeaponsEnum {
	WPN_AWP = 0,
    WPN_M249 = 1,
    WPN_M4A1 = 2,
    WPN_SG552 = 3,
    WPN_FAMAS = 4,
    WPN_P90 = 5,
    WPN_USP = 6,
    WPN_SCOUT = 7,
};

enum _:JumpStatsOptionFlags {
	flagHasColorChat = 	(1 << 0), 	// a
	flagLjStats = 		(1 << 1), 	// b
	flagShowSpeed =		(1 << 2), 	// c
	flagShowPre = 		(1 << 3), 	// d
	flagStrafeStats = 	(1 << 4), 	// e
	flagBeam = 			(1 << 5), 	// f
	flagStatsPre = 		(1 << 6), 	// g
	flagFailEarly = 	(1 << 7), 	// h
	flagMultiBhopPre = 	(1 << 8), 	// i 
	flagShowDuck = 		(1 << 9), 	// j
	flagLjPre = 		(1 << 10),	// k
	flagShowEdge = 		(1 << 11),	// l
	flagShowEdgeFail = 	(1 << 12),	// m
	flagEnableSounds = 	(1 << 13),	// n
	flagIngameStrafes = (1 << 14),	// o
	flagJumpOff = 		(1 << 15),
	flagJumpHeight = 	(1 << 16),
};

// 
// Core section
// 

forward kz_timer_start_pre(id);

forward kz_timer_start_post(id);

forward kz_timer_pause_pre(id);

forward kz_timer_pause_post(id);

forward kz_timer_finish_pre(id, runInfo[RunStruct]);

forward kz_timer_finish_post(id, runInfo[RunStruct]);

forward kz_timer_stop_pre(id);

forward kz_timer_stop_post(id);

forward kz_cp_pre(id);

forward kz_cp_post(id);

forward kz_tp_pre(id);

forward kz_tp_post(id);

forward kz_starttp_pre(id);

forward kz_starttp_post(id);


native TimerState:kz_get_timer_state(id);

native kz_start_timer(id);
native kz_end_timer(id);

native kz_set_pause(id);

native kz_tp_last_pos(id);

native kz_get_cp_num(id);
native kz_set_cp_num(id, value);

native kz_get_tp_num(id);
native kz_set_tp_num(id, value);

native kz_get_last_pos(id, value[PosStruct]);
native kz_set_last_pos(id, value[PosStruct]);

native kz_get_last_vel(id, value[PosStruct]);
native kz_set_last_vel(id, value[PosStruct]);

native kz_get_last_cp(id, value[PosStruct]);
native kz_set_last_cp(id, value[PosStruct]);

native Float:kz_get_actual_time(id);
native kz_set_start_time(id, Float:value);

/**
 *	Checks is player has start position
 *	
 *	@param id
 *
 * 	@return bool
 */
native bool:kz_has_start_pos(id);

//
// Hook & noclip section
// 

forward kz_noclip_pre(id);

forward kz_noclip_post(id);

forward kz_hook_pre(id);

forward kz_hook_post(id);

native kz_in_hook(id);
native kz_in_noclip(id);

//
// Spec section
// 

forward kz_spectator_pre(id);

forward kz_spectator_post(id);

//
// Weapons section
// 

native kz_get_min_rank(id);

native kz_set_min_rank(id, value);

native kz_get_weapon_name(iRank, szWeapon[], iLen);

native kz_get_usp(id);

// 
// Records section
// 

/**
 *	Checks is map has pro record
 *
 *	@param aa check AirAccelerateEnum constants
 *
 *	@return true if record exists, false otherwise
 */
native bool:kz_has_map_pro_rec(aa = AIR_ACCELERATE_10);
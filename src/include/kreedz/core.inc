#if defined _kreedz_core_included
	#endinput
#endif

#define _kreedz_core_included

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

enum _:SettingsStruct {
	bool:set_IsSaveAngles,
	bool:set_IsRadioEnable
};

enum _:TimerStruct {
	timer_RGB,
	Float:timer_X,
	Float:timer_Y,
	bool:timer_isDhud,
	timer_Type,
	bool:timer_MS
};

/**
 *
 */
forward kz_timer_start_pre(id);

/**
 *
 */
forward kz_timer_start_post(id);

/**
 *
 */
forward kz_timer_pause_pre(id);

/**
 *
 */
forward kz_timer_pause_post(id);

/**
 *
 */
forward kz_timer_finish_pre(id, Float:time);

/**
 *
 */
forward kz_timer_finish_post(id, Float:time);

/**
 *
 */
forward kz_timer_stop_pre(id);

/**
 *
 */
forward kz_timer_stop_post(id);

/**
 *
 */
forward kz_cp_pre(id);

/**
 *
 */
forward kz_cp_post(id);

/**
 *
 */
forward kz_tp_pre(id);

/**
 *
 */
forward kz_tp_post(id);

/**
 *
 */
forward kz_starttp_pre(id);

/**
 *
 */
forward kz_starttp_post(id);


native TimerState:kz_get_timer_state(id);

native kz_start_timer(id);

native kz_set_pause(id);

native kz_tp_last_pos(id);

native kz_get_cp_num(id);
native kz_set_cp_num(id, value);

native kz_get_tp_num(id);
native kz_set_tp_num(id, value);

native kz_get_last_pos(id, value[PosStruct]);
native kz_set_last_pos(id, value[PosStruct]);

native kz_get_last_cp(id, value[PosStruct]);
native kz_set_last_cp(id, value[PosStruct]);

native Float:kz_get_actual_time(id);
native kz_set_start_time(id, Float:value);

native kz_get_settings(id, value[SettingsStruct]);
native kz_set_settings(id, value[SettingsStruct]);

native kz_set_timer_data(id, value[TimerStruct]);

native kz_is_radio_enable(id);
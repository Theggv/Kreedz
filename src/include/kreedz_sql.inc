#if defined _kreedz_sql_included
	#endinput
#endif

#define _kreedz_sql_included

#define MYSQL_LOG "addons/amxmodx/logs/kz_db_log/main.log"

forward kz_sql_initialized();

forward kz_sql_data_recv(id);

forward kz_sql_start_pos_loaded(id, Float:vOrigin[3], Float:vAngle[3]);

forward kz_top_new_pro_rec(id, Float:fTime);

forward kz_top_new_nub_rec(id, Float:fTime, checkpointsCount, teleportsCount);

native kz_sql_get_user_uid(id);

native kz_sql_get_map_uid();

native Handle:kz_sql_get_tuple();

native kz_sql_save_start_pos(id, Float:vOrigin[3], Float:vAngle[3]);

native kz_sql_reset_start_pos(id);

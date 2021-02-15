#define MYSQL_LOG "addons/amxmodx/logs/kz_db_log/main.log"

forward kz_sql_initialized();

forward kz_sql_data_recv(id);

forward kz_top_new_pro_rec(id, Float:fTime);

native kz_sql_get_user_uid(id);

native kz_sql_get_map_uid();

native Handle:kz_sql_get_tuple();

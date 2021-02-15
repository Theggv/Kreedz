#if defined _map_manager_blocklist_included
    #endinput
#endif
#define _map_manager_blocklist_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib map_manager_blocklist
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib map_manager_blocklist
    #endif
#else
    #pragma library map_manager_blocklist
#endif

/**
 * Check map if it in blocklist.
 *
 * @param map                   Map name
 * 
 * @return                      Blocked count
 */
native mapm_get_blocked_count(map[]);
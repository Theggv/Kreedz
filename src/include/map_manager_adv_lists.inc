#if defined _map_manager_adv_lists_included
    #endinput
#endif
#define _map_manager_adv_lists_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib map_manager_adv_lists
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib map_manager_adv_lists
    #endif
#else
    #pragma library map_manager_adv_lists
#endif

/**
 * Array size of advanced list.
 * 
 * @return                      Number of active lists
 */
native mapm_advl_get_active_lists();

/**
 * Get list name.
 *
 * @param item                  Number of active list
 * @param list_name             String for list name
 * @param size                  String size
 * 
 * @noreturn
 */
native mapm_advl_get_list_name(item, list_name[], size);

/**
 * Get Array pointer by index
 *
 * @param item                  Number of active list
 * 
 * @return                      Array pointer
 */
native Array:mapm_advl_get_list_array(item);

#if defined _map_manager_nom_included
    #endinput
#endif
#define _map_manager_nom_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib map_manager_nomination
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib map_manager_nomination
    #endif
#else
    #pragma library map_manager_nomination
#endif

/**
 * Returns true if nomination ignore vote.
 *
 * @return                      true/false
 */
native bool:is_nomination_ignore_vote();

/**
 * Set ignore or not adding nominated maps to vote.
 *
 * @param ignore                Yes or not
 *
 * @noreturn
 */
native map_nomination_set_ignore(bool:ignore);

/**
 * Called when player want to nominate map.
 *
 * @param id                    Player index
 * @param map                   Map which player want to nominate
 * 
 * @return                      NOMINATION_ALLOWED to allow nomination
 *                              NOMINATION_BLOCKED to block nomination
 */
forward mapm_can_be_nominated(id, map[]);

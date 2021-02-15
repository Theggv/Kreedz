#if defined _map_manager_scheduler_included
  #endinput
#endif
#define _map_manager_scheduler_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib map_manager_scheduler
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib map_manager_scheduler
    #endif
#else
    #pragma library map_manager_scheduler
#endif

/**
 * Start vote by scheduler, work with own cvars.
 * 
 * @param type                  Type of vote, used const VOTE_BY_*
 *
 * @noreturn
 */
native map_scheduler_start_vote(type);

/**
 * Returns true if vote will in next round.
 *
 * @return                      true/false
 */
native bool:is_vote_will_in_next_round();

/**
 * Returns true if now is last round.
 *
 * @return                      true/false
 */
native bool:is_last_round();

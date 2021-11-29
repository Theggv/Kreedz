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

enum IgnoreFlags (<<=1) {
    IGNORE_DISABLED = 0,
    IGNORE_TIMER_CHECK = 1 << 0,
    IGNORE_ROUND_CHECK,
    IGNORE_FRAGS_CHECK
};

/**
 * Get ignore flags for starting vote.
 *
 * @return                      Ignore flags
 */
native IgnoreFlags:map_scheduler_get_ignore_check();

/**
 * Set ignore flags for starting vote.
 * 
 * @param flags                 Flags from IgnoreFlags enum
 *
 * @noreturn
 */
native map_scheduler_set_ignore_check(IgnoreFlags:flags);

/**
 * Start vote by scheduler, work with own cvars.
 * 
 * @param type                  Type of vote, used const VOTE_BY_*
 *
 * @noreturn
 */
native map_scheduler_start_vote(type);

/**
 * Extend current map time.
 * 
 * @param count                 Extend time param, bonus time = count * cvarnum(extend_time)
 *
 * @noreturn
 */
native map_scheduler_extend_map(count = 1);

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

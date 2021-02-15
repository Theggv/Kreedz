#if defined _map_manager_core_included
    #endinput
#endif
#define _map_manager_core_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib map_manager_core
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib map_manager_core
    #endif
#else
    #pragma library map_manager_core
#endif

#include <map_manager_consts>
#include <map_manager_stocks>

/**
 * Load maps from file.
 * File loads from configs dir. 
 *
 * @param filename              File name
 * @param clearlist             Clear old maplist before new load.
 * @param silent                If false then will be call forward mapm_maplist_loaded.
 *
 * @noreturn
 */
native mapm_load_maplist(filename[], bool:clearlist = true, bool:silent = false);

/**
 * Load maps from file.
 * File loads from configs dir. 
 *
 * @param array                 Array with item size MapStruct. 
 * @param filename              File name
 *
 * @return                      1 if success load, 0 otherwise
 */
native mapm_load_maplist_to_array(Array:array, filename[]);

/**
 * Block default load maplist.
 * Use before call plugin_cfg().
 *
 * @noreturn
 */
native mapm_block_load_maplist();

/**
 * Add map to maplist
 *
 * @param name                  Map name
 * @param minplayers            Min players for sort
 * @param maxplayers            Max players for sort
 *
 * @return                      0 if invalid map or already in array
 */
native mapm_add_map_to_list(name[], minplayers = 0, maxplayers = 32);

/**
 * Get map index in mapslist array.
 *
 * @param map                   Map name
 *
 * @return                      Map index or INVALID_MAP_INDEX if map not exist in mapslist
 */
native mapm_get_map_index(map[]);

/**
 * Get prefix from core.
 * 
 * @param prefix                Prefix string
 * @param len                   String lenght
 *
 * @noreturn
 */
native mapm_get_prefix(prefix[], len);

/**
 * Set value for vote finished variable.
 * 
 * @param value                 Bool value
 *
 * @noreturn
 */
native mapm_set_vote_finished(bool:value);

/**
 * Start vote.
 * 
 * @param type                  Vote type, use const VOTE_BY_*
 *
 * @noreturn
 */
native mapm_start_vote(type);

/**
 * Stop vote.
 * 
 * @noreturn
 */
native mapm_stop_vote();

/**
 * Blocks show vote menu from core.
 * 
 * @noreturn
 */
native mapm_block_show_vote();

/**
 * Get votelist size const from core.
 * 
 * @return Votelist size
 */
native mapm_get_votelist_size();

/**
 * Set max items in vote.
 *
 * @param value                 Amount items in vote
 * 
 * @noreturn
 */
native mapm_set_votelist_max_items(value);

/**
 * Push map in votelist.
 *
 * @note Use native in forward mapm_prepare_votelist().
 *
 * @param map                   Map name
 * @param type                  Type for addons
 * @param ignore_check          Allow ignore some checks, bit sum, use const CHECK_*
 * 
 * @return                      Result of pushing, const PUSH_*
 */
native mapm_push_map_to_votelist(map[], type = PUSH_BY_NATIVE, ignore_check = CHECK_NOT_IGNORED);

/**
 * Get amount maps in votelist.
 *
 * @note Use in mapm_analysis_of_results()
 * 
 * @noreturn
 */
native mapm_get_count_maps_in_vote();

/**
 * Get info about votelist item.
 *
 * @note Use in mapm_analysis_of_results()
 *
 * @param item                  Index in votelist
 * @param map                   Map name
 * @param len                   Map name string lenght
 * 
 * @return                      Votes
 */
native mapm_get_voteitem_info(item, map[], len);

/**
 * Returns vote type.
 * 
 * @return                      Type of vote, used const VOTE_BY_*
 */
native mapm_get_vote_type();

/**
 * Adds votes to vote item.
 *
 * @note Use while vote continues.
 *
 * @param item                  Index in votelist
 * @param value                 Map name
 * 
 * @return                      1 if success
 */
native mapm_add_vote_to_item(item, value);

/**
 * Returns if vote started.
 * 
 * @return                      true/false
 */
native bool:is_vote_started();

/**
 * Returns if vote finished.
 * 
 * @return                      true/false
 */
native bool:is_vote_finished();

/**
 * Called after load maps from file.
 * 
 * @param maplist               Array with loaded maps
 * @param file                  Load file
 * @param cleared               True if cleared old list before load
 *
 * @noreturn
 */
forward mapm_maplist_loaded(Array:maplist);

/**
 * Called after clear maplist.
 *
 * @noreturn
 */
forward mapm_maplist_unloaded();

/**
 * Called every second before vote or in vote.
 *
 * @param type                  Type of countdown, used const COUNTDOWN_*
 * @param time                  Current second of countdown
 * 
 * @noreturn
 */
forward mapm_countdown(type, time);

/**
 * Called before vote.
 *
 * @param type                  Type of vote, used const VOTE_BY_*
 * 
 * @noreturn
 */
forward mapm_prepare_votelist(type);

/**
 * Called when core or addons are trying add map in votelist.
 *
 * @param map                   Map name
 * @param type                  Type of vote, used const VOTE_BY_*
 * @param index                 Index in mapslist array
 * 
 * @return                      MAP_ALLOWED
 *                              MAP_BLOCKED
 */
forward mapm_can_be_in_votelist(const map[], type, index);

/**
 * Called for permission to extend current map.
 *
 * @param type                  Type of vote, used const VOTE_BY_*
 *
 * @return                      EXTEND_ALLOWED to allow extend current map
 *                              EXTEND_BLOCKED to block extend current map
 */
forward mapm_can_be_extended(type);

/**
 * Called when core start show menu with vote.
 *
 * @param type                  Type of vote, used const VOTE_BY_*
 * 
 * @noreturn
 */
forward mapm_vote_started(type);

/**
 * Called when core canceled vote.
 *
 * @param type                  Type of vote, used const VOTE_BY_*
 * 
 * @noreturn
 */
forward mapm_vote_canceled(type);

/**
 * Called before vote finish.
 *
 * @param type                  Type of vote, used const VOTE_BY_*
 * @param total_votes           Count of players votes
 * 
 * @return                      ALLOW_VOTE to allow finish vote
 *                              ABORT_VOTE to block finish vote, forward mapm_vote_finished() will not be called
 */
forward mapm_analysis_of_results(type, total_votes);

/**
 * Called when vote finished.
 *
 * @note Can be blocked in forward mapm_analysis_of_results()
 *
 * @param map                   Nextmap
 * @param type                  Type of vote, used const VOTE_BY_*
 * @param total_votes           Count of players votes
 * 
 * @noreturn
 */
forward mapm_vote_finished(const map[], type, total_votes);

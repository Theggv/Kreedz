#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: Online sorter"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
    CHECK_NOMINATED_MAPS
};

new g_pCvars[Cvars];

new Array:g_aMapsList;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pCvars[CHECK_NOMINATED_MAPS] = register_cvar("mapm_sort_check_nominated_maps", "0"); // 0 - disable, 1 - enable
}
public mapm_maplist_loaded(Array:maplist)
{
    g_aMapsList = maplist;
}
public mapm_prepare_votelist(type)
{
    if(type == VOTE_BY_SCHEDULER_SECOND) {
        return;
    }

    new players_num = get_players_num();

    new Array:array = ArrayCreate(MAPNAME_LENGTH, 1);
    new map_info[MapStruct], size = ArraySize(g_aMapsList);

    for(new i; i < size; i++) {
        ArrayGetArray(g_aMapsList, i, map_info);
        if(map_info[MinPlayers] <= players_num <= map_info[MaxPlayers]) {
            ArrayPushString(array, map_info[Map]);
        }
    }

    new map[MAPNAME_LENGTH], max_items = mapm_get_votelist_size();
    for(new i, index; i < max_items && ArraySize(array); i++) {
        index = random_num(0, ArraySize(array) - 1);
        ArrayGetString(array, index, map, charsmax(map));
        ArrayDeleteItem(array, index);
        if(mapm_push_map_to_votelist(map, PUSH_BY_ONLINE_SORTER) == PUSH_BLOCKED) {
            i--;
        }
    }

    ArrayDestroy(array);
}
public mapm_can_be_in_votelist(const map[], type, index)
{
    // add online checks for another addons?

    if(type == PUSH_BY_NOMINATION && index != INVALID_MAP_INDEX && get_num(CHECK_NOMINATED_MAPS)) {
        new map_info[MapStruct]; ArrayGetArray(g_aMapsList, index, map_info);
        new players_num = get_players_num();
        if(map_info[MinPlayers] > players_num || map_info[MaxPlayers] < players_num) {
            return MAP_BLOCKED;
        }
    }
    return MAP_ALLOWED;
}

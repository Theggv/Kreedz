#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: Priority"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
    IGNORE_NOMINATION
};

new g_pCvars[Cvars];
new Array:g_aMapList;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[IGNORE_NOMINATION] = register_cvar("mapm_priority_ignore_nomination", "1");
}

public mapm_maplist_loaded(Array:maplist, const nextmap[])
{
    g_aMapList = maplist;
}

public mapm_can_be_in_votelist(const map[], type, index)
{
    if(type == PUSH_BY_NOMINATION && get_num(IGNORE_NOMINATION)) {
        return MAP_ALLOWED;
    }
    
    new map_info[MapStruct];
    ArrayGetArray(g_aMapList, index, map_info);
    new rnd = random_num(0, 99);
    
    return rnd < map_info[MapPriority] ? MAP_ALLOWED : MAP_BLOCKED;
}

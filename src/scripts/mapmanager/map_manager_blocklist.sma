#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: BlockList"
#define VERSION "0.0.3"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
    BAN_LAST_MAPS
};

new g_pCvars[Cvars];

new const FILE_BLOCKED_MAPS[] = "blockedmaps.ini"; //datadir

new Trie:g_tBlockedList;
new g_iMaxItems;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[BAN_LAST_MAPS] = register_cvar("mapm_blocklist_ban_last_maps", "10");
}
public plugin_natives()
{
    register_library("map_manager_blocklist");
    register_native("mapm_get_blocked_count", "native_get_blocked_count");
}
public native_get_blocked_count(plugin, params)
{
    enum { arg_map = 1 };

    new map[MAPNAME_LENGTH];
    get_string(arg_map, map, charsmax(map));
    strtolower(map);

    if(!TrieKeyExists(g_tBlockedList, map)) {
        return 0;
    }

    new count; TrieGetCell(g_tBlockedList, map, count);

    return count;
}
public mapm_maplist_loaded(Array:mapslist)
{
    if(!g_tBlockedList) {
        g_tBlockedList = TrieCreate();
        load_blocklist();
    }

    new map_info[MapStruct], blocked, size = ArraySize(mapslist);
    for(new i; i < size; i++) {
        ArrayGetArray(mapslist, i, map_info);
        if(TrieKeyExists(g_tBlockedList, map_info[Map])) {
            blocked++;
        }
    }

    new votelist_size = min(mapm_get_votelist_size(), size);
    new valid_maps = size - blocked;

    g_iMaxItems = 0;

    if(valid_maps <= 0) {
        TrieClear(g_tBlockedList);
    }
    else if(valid_maps < votelist_size) {
        g_iMaxItems = valid_maps;
    }
}
load_blocklist()
{
    new file_dir[128]; get_localinfo("amxx_datadir", file_dir, charsmax(file_dir));
    new file_path[128]; formatex(file_path, charsmax(file_path), "%s/%s", file_dir, FILE_BLOCKED_MAPS);

    new block_value = get_num(BAN_LAST_MAPS);

    new cur_map[MAPNAME_LENGTH]; get_mapname(cur_map, charsmax(cur_map)); strtolower(cur_map);
    TrieSetCell(g_tBlockedList, cur_map, block_value);

    new f, temp;

    if(file_exists(file_path)) {
        new temp_file_path[128]; formatex(temp_file_path, charsmax(temp_file_path), "%s/temp.ini", file_dir);
        f = fopen(file_path, "rt");
        temp = fopen(temp_file_path, "wt");

        new buffer[40], map[MAPNAME_LENGTH], str_count[6], count;
        
        while(!feof(f)) {
            fgets(f, buffer, charsmax(buffer));
            parse(buffer, map, charsmax(map), str_count, charsmax(str_count));
            strtolower(map);
            
            if(!is_map_valid(map) || TrieKeyExists(g_tBlockedList, map)) continue;
            
            count = min(str_to_num(str_count) - 1, block_value);
            
            if(count <= 0) continue;

            fprintf(temp, "^"%s^" ^"%d^"^n", map, count);
            strtolower(map);
            TrieSetCell(g_tBlockedList, map, count);
        }
        
        fprintf(temp, "^"%s^" ^"%d^"^n", cur_map, block_value);
        
        fclose(f);
        fclose(temp);
        
        delete_file(file_path);
        rename_file(temp_file_path, file_path, 1);
    } else {
        f = fopen(file_path, "wt");
        if(f) {
            fprintf(f, "^"%s^" ^"%d^"^n", cur_map, block_value);
        }
        fclose(f);
    }
}
public mapm_prepare_votelist(type)
{
    if(type == VOTE_BY_SCHEDULER_SECOND) {
        return;
    }
    if(g_iMaxItems) {
        mapm_set_votelist_max_items(g_iMaxItems);
    }
}
public mapm_can_be_in_votelist(const map[])
{
    new lower[MAPNAME_LENGTH];
    copy(lower, charsmax(lower), map);
    strtolower(lower);
    return TrieKeyExists(g_tBlockedList, lower) ? MAP_BLOCKED : MAP_ALLOWED;
}

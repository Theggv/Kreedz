#include <amxmodx>
#include <map_manager>
#include <map_manager_blocklist>
#include <map_manager_adv_lists>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Nomination"
#define VERSION "0.1.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

enum {
    NOMINATION_FAIL,
    NOMINATION_SUCCESS,
    NOMINATION_REMOVED
};

enum {
    TYPE_STANDART,
    TYPE_FIXED
};

enum Cvars {
    TYPE,
    MAPS_IN_VOTE,
    MAPS_PER_PLAYER,
    DONT_CLOSE_MENU,
    DENOMINATE_TIME,
    RANDOM_SORT,
    REMOVE_MAPS,
    SHOW_LISTS
};

new g_pCvars[Cvars];

enum Forwards {
    CAN_BE_NOMINATED
};

new g_hForwards[Forwards];

new Array:g_aNomList;
new Array:g_aMapsList;
new g_hCallbackDisabled;
new g_iNomMaps[33];
new g_iLastDenominate[33];
new bool:g_bIgnoreVote = false;

new g_sPrefix[48];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pCvars[TYPE] = register_cvar("mapm_nom_type", "0"); // 0 - standart, 1 - fixed
    g_pCvars[MAPS_IN_VOTE] = register_cvar("mapm_nom_maps_in_vote", "3");
    g_pCvars[MAPS_PER_PLAYER] = register_cvar("mapm_nom_maps_per_player", "3");
    g_pCvars[DONT_CLOSE_MENU] = register_cvar("mapm_nom_dont_close_menu", "1"); // 0 - disable, 1 - enable
    g_pCvars[DENOMINATE_TIME] = register_cvar("mapm_nom_denominate_time", "5"); // seconds
    g_pCvars[RANDOM_SORT] = register_cvar("mapm_nom_random_sort", "0"); // 0 - disable, 1 - enable
    g_pCvars[REMOVE_MAPS] = register_cvar("mapm_nom_remove_maps", "1"); // 0 - disable, 1 - enable
    g_pCvars[SHOW_LISTS] = register_cvar("mapm_nom_show_lists", "0"); // 0 - disable, 1 - enable

    g_hForwards[CAN_BE_NOMINATED] = CreateMultiForward("mapm_can_be_nominated", ET_CONTINUE, FP_CELL, FP_STRING);

    register_clcmd("say", "clcmd_say");
    register_clcmd("say_team", "clcmd_say");
    register_clcmd("say maps", "clcmd_mapslist");
    register_clcmd("say /maps", "clcmd_mapslist");

    g_hCallbackDisabled = menu_makecallback("callback_disable_item");
}
public plugin_natives()
{
    set_module_filter("module_filter_handler");
    set_native_filter("native_filter_handler");

    register_library("map_manager_nomination");
    register_native("is_nomination_ignore_vote", "native_get_ignore");
    register_native("map_nomination_set_ignore", "native_set_ignore");
}
public module_filter_handler(const library[], LibType:type)
{
    if(equal(library, "map_manager_blocklist")) {
        return PLUGIN_HANDLED;
    }
    if(equal(library, "map_manager_adv_lists")) {
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}
public native_filter_handler(const native_func[], index, trap)
{
    if(equal(native_func, "mapm_get_blocked_count")) {
        return PLUGIN_HANDLED;
    }
    if(equal(native_func, "mapm_advl_get_active_lists")) {
        return PLUGIN_HANDLED;
    }
    if(equal(native_func, "mapm_advl_get_list_name")) {
        return PLUGIN_HANDLED;
    }
    if(equal(native_func, "mapm_advl_get_list_array")) {
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}
public native_get_ignore(plugin, params)
{
    return g_bIgnoreVote;
}
public native_set_ignore(plugin, params)
{
    enum { arg_ignore = 1 };
    g_bIgnoreVote = bool:get_param(arg_ignore);
}
public callback_disable_item()
{
    return ITEM_DISABLED;
}
public mapm_maplist_loaded(Array:maplist)
{
    g_aMapsList = maplist;

    if(!g_aNomList) {
        g_aNomList = ArrayCreate(NomStruct, 1);
    }

    if(get_num(REMOVE_MAPS)) {
        remove_maps();
    }

    mapm_get_prefix(g_sPrefix, charsmax(g_sPrefix));
}
public client_disconnected(id)
{
    if(g_iNomMaps[id]) {
        clear_nominated_maps(id);
    }
}
public clcmd_say(id)
{
    new text[MAPNAME_LENGTH]; read_args(text, charsmax(text));
    remove_quotes(text); trim(text); strtolower(text);
    
    if(is_string_with_space(text)) return PLUGIN_CONTINUE;
    
    new map_index = mapm_get_map_index(text);

    if(map_index != INVALID_MAP_INDEX) {
        nominate_map(id, text);
    } else if(strlen(text) >= 4) {
        new Array:nominate_list = ArrayCreate(1, 1), array_size;

        map_index = 0;
        while( (map_index = find_similar_map(map_index, text)) != INVALID_MAP_INDEX ) {
            ArrayPushCell(nominate_list, map_index);
            array_size++;
            map_index++;
        }
        
        if(array_size == 1) {
            map_index = ArrayGetCell(nominate_list, 0);
            new map_info[MapStruct]; ArrayGetArray(g_aMapsList, map_index, map_info);
            nominate_map(id, map_info[Map]);
        } else if(array_size > 1) {
            show_nomlist(id, nominate_list, array_size);
        }
        
        ArrayDestroy(nominate_list);
    }

    return PLUGIN_CONTINUE;
}
nominate_map(id, map[])
{
    if(mapm_get_blocked_count(map)) {
        client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_NOM_NOT_AVAILABLE_MAP");
        return NOMINATION_FAIL;
    }

    if(get_num(TYPE) == TYPE_FIXED && ArraySize(g_aNomList) >= get_num(MAPS_IN_VOTE)) {
        client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_NOM_CANT_NOM2");
        return NOMINATION_FAIL;
    }
    
    new nom_info[NomStruct], name[32];
    get_user_name(id, name, charsmax(name));
    
    new nom_index = map_nominated(map);
    if(nom_index != INVALID_MAP_INDEX) {
        ArrayGetArray(g_aNomList, nom_index, nom_info);
        if(id != nom_info[NomPlayer]) {
            client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_NOM_ALREADY_NOM");
            return NOMINATION_FAIL;
        }

        new systime = get_systime();
        if(g_iLastDenominate[id] + get_num(DENOMINATE_TIME) >= systime) {
            client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_NOM_SPAM");
            return NOMINATION_FAIL;
        }

        g_iLastDenominate[id] = systime;
        g_iNomMaps[id]--;
        ArrayDeleteItem(g_aNomList, nom_index);
        
        client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_NOM_REMOVE_NOM", name, map);
        return NOMINATION_REMOVED;
    }
    
    if(g_iNomMaps[id] >= get_num(MAPS_PER_PLAYER)) {
        client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_NOM_CANT_NOM");
        return NOMINATION_FAIL;
    }

    new ret;
    ExecuteForward(g_hForwards[CAN_BE_NOMINATED], ret, id, map);

    if(ret == NOMINATION_BLOCKED) {
        return NOMINATION_FAIL;
    }
    
    copy(nom_info[NomMap], charsmax(nom_info[NomMap]), map);
    nom_info[NomPlayer] = id;
    ArrayPushArray(g_aNomList, nom_info);
    
    g_iNomMaps[id]++;
    
    client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_NOM_MAP", name, map);
    
    return NOMINATION_SUCCESS;
}
show_nomlist(id, Array: array, size)
{
    new text[64]; formatex(text, charsmax(text), "%L", LANG_PLAYER, "MAPM_MENU_FAST_NOM");
    new menu = menu_create(text, "nomlist_handler");
    new map_info[MapStruct], item_name[MAPNAME_LENGTH + 16], map_index, nom_index, block_count;
    
    for(new i, str_num[6]; i < size; i++) {
        map_index = ArrayGetCell(array, i);
        ArrayGetArray(g_aMapsList, map_index, map_info);
        
        num_to_str(map_index, str_num, charsmax(str_num));
        nom_index = map_nominated(map_info[Map]);
        block_count = mapm_get_blocked_count(map_info[Map]);

        if(block_count) {
            formatex(item_name, charsmax(item_name), "%s[\r%d\d]", map_info[Map], block_count);
            menu_additem(menu, item_name, .callback = g_hCallbackDisabled);
        } else if(nom_index != INVALID_MAP_INDEX) {
            new nom_info[NomStruct]; ArrayGetArray(g_aNomList, nom_index, nom_info);
            if(id == nom_info[NomPlayer]) {
                formatex(item_name, charsmax(item_name), "%s[\y*\w]", map_info[Map]);
                menu_additem(menu, item_name);
            } else {
                formatex(item_name, charsmax(item_name), "%s[\y*\d]", map_info[Map]);
                menu_additem(menu, item_name, .callback = g_hCallbackDisabled);
            }
        } else {
            menu_additem(menu, map_info[Map]);
        }
    }
    
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_BACK");
    menu_setprop(menu, MPROP_BACKNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_NEXT");
    menu_setprop(menu, MPROP_NEXTNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_EXIT");
    menu_setprop(menu, MPROP_EXITNAME, text);
    
    menu_display(id, menu);
}
public nomlist_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new item_info[8], item_name[MAPNAME_LENGTH + 16], access, callback;
    menu_item_getinfo(menu, item, access, item_info, charsmax(item_info), item_name, charsmax(item_name), callback);

    trim_bracket(item_name);
    new nominated = nominate_map(id, item_name);
    
    if(nominated == NOMINATION_REMOVED || get_num(DONT_CLOSE_MENU)) {
        if(nominated == NOMINATION_SUCCESS) {
            format(item_name, charsmax(item_name), "%s[\y*\w]", item_name);
            menu_item_setname(menu, item, item_name);
        } else if(nominated == NOMINATION_REMOVED) {
            menu_item_setname(menu, item, item_name);
        }
        menu_display(id, menu);
    } else {
        menu_destroy(menu);
    }
    
    return PLUGIN_HANDLED;
}
public clcmd_mapslist(id)
{
    if(get_num(SHOW_LISTS) && mapm_advl_get_active_lists() > 1) {
        show_lists_menu(id);
    } else {
        show_nomination_menu(id, g_aMapsList);
    }
}
show_lists_menu(id)
{
    new text[64];
    // TODO: add ML
    new menu = menu_create("Maps lists:", "lists_handler");

    new list[32], size = mapm_advl_get_active_lists();
    for(new i; i < size; i++) {
        mapm_advl_get_list_name(i, list, charsmax(list));
        menu_additem(menu, list);
    }

    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_BACK");
    menu_setprop(menu, MPROP_BACKNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_NEXT");
    menu_setprop(menu, MPROP_NEXTNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_EXIT");
    menu_setprop(menu, MPROP_EXITNAME, text);
    
    menu_display(id, menu);
}
public lists_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    menu_destroy(menu);

    if(item >= mapm_advl_get_active_lists()) {
        clcmd_mapslist(id);
        return PLUGIN_HANDLED;
    }
    
    new list_name[32];
    mapm_advl_get_list_name(item, list_name, charsmax(list_name));
    new Array:maplist = mapm_advl_get_list_array(item);
    show_nomination_menu(id, maplist, list_name);

    return PLUGIN_HANDLED;
}
show_nomination_menu(id, Array:maplist, custom_title[] = "")
{
    new text[64];
    if(!custom_title[0]) {
        formatex(text, charsmax(text), "%L", LANG_PLAYER, "MAPM_MENU_MAP_LIST");
    } else {
        formatex(text, charsmax(text), "%s", custom_title);
    }
    new menu = menu_create(text, "mapslist_handler");
    
    new map_info[MapStruct], item_name[MAPNAME_LENGTH + 16], block_count, size = ArraySize(maplist);
    new random_sort = get_num(RANDOM_SORT), Array:array = ArrayCreate(1, 1);

    for(new i = 0, index, nom_index; i < size; i++) {
        if(random_sort) {
            do {
                index = random_num(0, size - 1);
            } while(in_array(array, index));
            ArrayPushCell(array, index);
        } else {
            index = i;
        }

        ArrayGetArray(maplist, index, map_info);
        nom_index = map_nominated(map_info[Map]);
        block_count = mapm_get_blocked_count(map_info[Map]);
        
        if(block_count) {
            formatex(item_name, charsmax(item_name), "%s[\r%d\d]", map_info[Map], block_count);
            menu_additem(menu, item_name, .callback = g_hCallbackDisabled);
        } else if(nom_index != INVALID_MAP_INDEX) {
            new nom_info[NomStruct]; ArrayGetArray(g_aNomList, nom_index, nom_info);
            if(id == nom_info[NomPlayer]) {
                formatex(item_name, charsmax(item_name), "%s[\y*\w]", map_info[Map]);
                menu_additem(menu, item_name);
            } else {
                formatex(item_name, charsmax(item_name), "%s[\y*\d]", map_info[Map]);
                menu_additem(menu, item_name, .callback = g_hCallbackDisabled);
            }
        } else {
            menu_additem(menu, map_info[Map]);
        }
    }

    ArrayDestroy(array);

    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_BACK");
    menu_setprop(menu, MPROP_BACKNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_NEXT");
    menu_setprop(menu, MPROP_NEXTNAME, text);
    formatex(text, charsmax(text), "%L", id, "MAPM_MENU_EXIT");
    menu_setprop(menu, MPROP_EXITNAME, text);
    
    menu_display(id, menu);
}
bool:in_array(Array:array, index)
{
    for(new i, size = ArraySize(array); i < size; i++) {
        if(ArrayGetCell(array, i) == index) {
            return true;
        }
    }
    return false;
}
public mapslist_handler(id, menu, item)
{
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }
    
    new item_info[8], item_name[MAPNAME_LENGTH + 16], access, callback;
    menu_item_getinfo(menu, item, access, item_info, charsmax(item_info), item_name, charsmax(item_name), callback);
    
    trim_bracket(item_name);
    new nominated = nominate_map(id, item_name);
    
    if(g_iNomMaps[id] < get_num(MAPS_PER_PLAYER) || get_num(DONT_CLOSE_MENU)) {
        if(nominated == NOMINATION_SUCCESS) {
            format(item_name, charsmax(item_name), "%s[\y*\w]", item_name);
            menu_item_setname(menu, item, item_name);
        } else if(nominated == NOMINATION_REMOVED) {
            menu_item_setname(menu, item, item_name);
        }
        menu_display(id, menu, item / 7);
    } else {
        menu_destroy(menu);
    }
    
    return PLUGIN_HANDLED;
}

public mapm_prepare_votelist(type)
{
    if(g_bIgnoreVote) {
        return;
    }
    new nom_info[NomStruct];
    new max_items = mapm_get_votelist_size();
    for(new i = mapm_get_count_maps_in_vote(), index; i < max_items && ArraySize(g_aNomList); i++) {
        index = random_num(0, ArraySize(g_aNomList) - 1);
        ArrayGetArray(g_aNomList, index, nom_info);
        ArrayDeleteItem(g_aNomList, index);
        g_iNomMaps[nom_info[NomPlayer]]--;

        if(mapm_push_map_to_votelist(nom_info[NomMap], PUSH_BY_NOMINATION) != PUSH_SUCCESS) {
            i--;
        }
    }
}

map_nominated(map[])
{
    new nom_info[NomStruct], size = ArraySize(g_aNomList);
    for(new i; i < size; i++) {
        ArrayGetArray(g_aNomList, i, nom_info);
        if(equali(map, nom_info[NomMap])) {
            return i;
        }
    }
    return INVALID_MAP_INDEX;
}
clear_nominated_maps(id)
{
    new nom_info[NomStruct];
    for(new i = 0; i < ArraySize(g_aNomList); i++) {
        ArrayGetArray(g_aNomList, i, nom_info);
        if(id == nom_info[NomPlayer]) {
            ArrayDeleteItem(g_aNomList, i--);
            if(!--g_iNomMaps[id]) {
                break;
            }
        }
    }
}
find_similar_map(map_index, string[MAPNAME_LENGTH])
{
    new map_info[MapStruct], end = ArraySize(g_aMapsList);
    for(new i = map_index; i < end; i++) {
        ArrayGetArray(g_aMapsList, i, map_info);
        if(containi(map_info[Map], string) != -1) {
            return i;
        }
    }
    return INVALID_MAP_INDEX;
}
remove_maps()
{
    new nom_info[NomStruct];
    for(new i; i < ArraySize(g_aNomList); i++) {
        ArrayGetArray(g_aNomList, i, nom_info);
        if(mapm_get_map_index(nom_info[NomMap]) == INVALID_MAP_INDEX) {
            g_iNomMaps[nom_info[NomPlayer]]--;
            ArrayDeleteItem(g_aNomList, i--);
        }
    }
}

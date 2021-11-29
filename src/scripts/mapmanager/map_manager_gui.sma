/*
Credits: [WPMG]PRoSToTeM@, Sanlerus
Models, sprites for test by 8dp
*/
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#include <dhudmessage>
#endif

#define PLUGIN "Map Manager: GUI"
#define VERSION "0.0.5"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])
#define get_float(%0) get_pcvar_float(g_pCvars[%0])
#define hide_ent(%0) set_pev(%0, pev_effects, pev(%0, pev_effects) | EF_NODRAW)
#define show_ent(%0) set_pev(%0, pev_effects, pev(%0, pev_effects) & ~EF_NODRAW)

#define BOX_MODEL               "models/map_manager/blackbox2.mdl"
#define MODEL_CURSOR            "sprites/map_manager/cursor2.spr"

#define FILE_PACKS              "mappacks.ini"

#define MAX_MAP_CUBES           9

#define MAX_CURSOR_X            140.0
#define MAX_CURSOR_Y            103.0
#define CURSOR_SENSITIVITY      2.2

#define UNKNOWN_MAP_FRAME       0.0
#define EXTEND_MAP_FRAME        1.0

#define COORD_X                 0
#define COORD_Y                 1

new const SELECTED_COLOR[3] = {55, 200, 55};

enum _:FramesStruct {
    BeginFrame,
    EndFrame
};

enum {
    UNKNOWN_MAP,
    PACK_MAP,
    CURRENT_MAP
};

enum Cvars {
    CURSOR_SENS,
    HIDE_MAP_PREFIX,
    SHOW_SELECTS,
    SHOW_PERCENT
};

new g_pCvars[Cvars];

new g_pPointOfView;
new g_pCursorEntity;

new Float:g_vecCursorPos[33][3];
new Float:g_vecPOVOrigin[3];

new g_bShowGUI[33];
new g_iCurEnt[33];

enum _:CubeInfo {
    Name[MAPNAME_LENGTH],
    Float:Begin,
    Float:End
};

new g_eCubesInfo[MAX_MAP_CUBES][CubeInfo];
new g_pMapCubes[MAX_MAP_CUBES];
new Float:g_fMapCubesOrigin[MAX_MAP_CUBES][3];

new Float:g_fDhudCoords[MAX_MAP_CUBES][2];
new g_bShowName[MAX_MAP_CUBES];

new g_iMapsCount;
new g_bVoted[33];

new g_iCurPos[33];
new Float:g_fCurFrame[33];

enum _:PackStruct {
    Path[64],
    Float:Scale,
    Trie:Maps
};

new Array:g_aPacks;

new bool:g_bShowSelects;
new g_iCurMap;

new g_sCurMap[MAPNAME_LENGTH];
new g_sPrefix[32];

new Float:g_fCursorSens = CURSOR_SENSITIVITY;

enum Forwards {
    AddToFullPack_Pre,
    AddToFullPack_Post,
    CmdStart_Post,
    CheckVisibility_Pre
};

new g_hForwards[Forwards];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[CURSOR_SENS] = register_cvar("mapm_cursor_sens", "2.5");

    // TODO: cvars
    // g_pCvars[HIDE_MAP_PREFIX] = register_cvar("mapm_hide_map_prefix", "1");
}
public plugin_cfg()
{
    mapm_get_prefix(g_sPrefix, charsmax(g_sPrefix));

    g_pCvars[SHOW_SELECTS] = get_cvar_pointer("mapm_show_selects");
    g_pCvars[SHOW_PERCENT] = get_cvar_pointer("mapm_show_percent");

    g_fCursorSens = get_float(CURSOR_SENS);
}
public plugin_precache()
{
    precache_model(BOX_MODEL);
    precache_model(MODEL_CURSOR);

    g_pPointOfView = create_entity("info_target");
    set_pev(g_pPointOfView, pev_classname, "PointOfView");
    entity_set_model(g_pPointOfView, BOX_MODEL);
    entity_set_size(g_pPointOfView, Float:{ -5.0, -5.0, -5.0 }, Float:{ 5.0, 5.0, 5.0 });
    set_pev(g_pPointOfView, pev_effects, EF_BRIGHTLIGHT);

    g_pCursorEntity = create_entity("info_target");
    set_pev(g_pCursorEntity, pev_classname, "CursorEntity");
    set_pev(g_pCursorEntity, pev_scale, 0.1);
    entity_set_model(g_pCursorEntity, MODEL_CURSOR);

    for(new i; i < sizeof(g_pMapCubes); i++) {
        g_pMapCubes[i] = create_entity("info_target");
        set_pev(g_pMapCubes[i], pev_classname, "MapCube");
        set_pev(g_pMapCubes[i], pev_scale, 0.2);
        set_pev(g_pMapCubes[i], pev_effects, EF_BRIGHTLIGHT);
        entity_set_size(g_pMapCubes[i], Float:{ -5.0, -5.0, -5.0 }, Float:{ 5.0, 5.0, 5.0 });
    }

    new Float:origin[3] = { -4000.0, -3800.0, -4000.0 };

    entity_set_origin(g_pPointOfView, origin);
    g_vecPOVOrigin = origin;

    // TODO: Move offsets to defines
    origin[0] += 144.0;
    origin[1] += 96.0;
    origin[2] += 48.0;

    for(new i; i < sizeof(g_pMapCubes); i++) {
        entity_set_origin(g_pMapCubes[i], origin);
        g_fMapCubesOrigin[i] = origin;

        origin[1] -= 96.0;

        if((i + 1) % 3 == 0) {
            origin[2] -= 48.0;
            origin[1] += 96.0 * 3.0;
        }
    }

    get_mapname(g_sCurMap, charsmax(g_sCurMap));

    load_packs();

    get_dhud_coords();
    hide_gui();
}

get_dhud_coords()
{
    new Float:start[3];
    pev(g_pPointOfView, pev_origin, start);
    start[1] += MAX_CURSOR_X;
    start[2] += MAX_CURSOR_Y;

    new Float:cube[3], Float:diff[2];

    for(new i; i < sizeof(g_pMapCubes); i++) {
        cube = g_fMapCubesOrigin[i];
        diff[COORD_X] = start[1] - cube[1];
        diff[COORD_Y] = start[2] - cube[2];
        
        g_fDhudCoords[i][COORD_X] = diff[COORD_X] / (MAX_CURSOR_X * 2.0) - 0.07;
        g_fDhudCoords[i][COORD_Y] = diff[COORD_Y] / (MAX_CURSOR_Y * 2.0);
        g_fDhudCoords[i][COORD_Y] += (g_fDhudCoords[i][COORD_Y] > 0.5) ? 0.058 : 0.073;

        // server_print("%d - %f %f", i, g_fDhudCoords[i][COORD_X], g_fDhudCoords[i][COORD_Y]);
    }
}

load_packs()
{
    new file_path[256]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
    format(file_path, charsmax(file_path), "%s/%s", file_path, FILE_PACKS);

    if(!file_exists(file_path)) {
        new error[192]; formatex(error, charsmax(error), "File doesn't exist ^"%s^".", file_path);
        set_fail_state(error);
        return 0;
    }

    new f = fopen(file_path, "rt");
    
    if(!f) {
        set_fail_state("Can't read map packs file.");
        return 0;
    }

    g_aPacks = ArrayCreate(PackStruct, 1);

    new text[128], pack_info[PackStruct], map[MAPNAME_LENGTH], frames_info[FramesStruct], cur_frame, frames, str_frames[8];

    while(!feof(f)) {
        fgets(f, text, charsmax(text));
        trim(text);
        
        if(!text[0] || text[0] == ';') {
            continue;
        }

        // found new pack
        if(containi(text, ".spr") != -1) {
            new Float:scale, str_scale[8];
            parse(text, pack_info[Path], charsmax(pack_info[Path]), str_scale, charsmax(str_scale));

            scale = str_to_float(str_scale);
            if(!scale) {
                scale = 0.1;
            }

            pack_info[Scale] = _:scale;
            pack_info[Maps] = _:TrieCreate();
            ArrayPushArray(g_aPacks, pack_info);
            precache_model(pack_info[Path]);
            cur_frame = 2;
            // log_amx("pack: %s, scale: %f", pack_info[Path], scale);
            continue;
        }

        parse(text, map, charsmax(map), str_frames, charsmax(str_frames));

        frames = str_to_num(str_frames);
        if(!frames) {
            frames = 1;
        }

        frames_info[BeginFrame] = cur_frame;
        frames_info[EndFrame] = cur_frame + frames - 1;

        // load maps to last pack
        TrieSetArray(pack_info[Maps], map, frames_info, sizeof(frames_info));
        // log_amx("map: %s, begin: %d, end: %d", map, frames_info[BeginFrame], frames_info[EndFrame]);

        cur_frame = frames_info[EndFrame] + 1;
        str_frames = "";
    }
    fclose(f);

    return 1;
}

find_map_frame(map[], pack[], plen, &Float:scale,&Float:begin, &Float:end)
{
    new pack_info[PackStruct];
    if(equali(map, g_sCurMap)) {
        ArrayGetArray(g_aPacks, 0, pack_info);
        copy(pack, plen, pack_info[Path]);
        scale = pack_info[Scale];
        begin = end = EXTEND_MAP_FRAME;
        return CURRENT_MAP;
    }

    new size = ArraySize(g_aPacks), frames_info[FramesStruct];
    for(new i; i < size; i++) {
        ArrayGetArray(g_aPacks, i, pack_info);
        if(TrieGetArray(pack_info[Maps], map, frames_info, sizeof(frames_info))) {
            copy(pack, plen, pack_info[Path]);
            scale = pack_info[Scale];
            begin = float(frames_info[BeginFrame]);
            end = float(frames_info[EndFrame]);
            return PACK_MAP;
        }
    }

    copy(pack, plen, pack_info[Path]);
    scale = pack_info[Scale];
    begin = end = UNKNOWN_MAP_FRAME;

    return UNKNOWN_MAP;
}

public mapm_vote_started(type)
{
    mapm_block_show_vote();

    show_gui();

    g_iMapsCount = mapm_get_count_maps_in_vote();
    g_iCurMap = -1;

    new map[MAPNAME_LENGTH];
    new pack[64], Float:scale, Float:frames_begin, Float:frames_end, ret;

    for(new i; i < g_iMapsCount; i++) {
        mapm_get_voteitem_info(i, map, charsmax(map));
        
        ret = find_map_frame(map, pack, charsmax(pack), scale, frames_begin, frames_end);

        if(ret == CURRENT_MAP) {
            g_iCurMap = i;
        }

        g_bShowName[i] = !ret;

        entity_set_model(g_pMapCubes[i], pack);
        set_pev(g_pMapCubes[i], pev_frame, frames_begin);
        set_pev(g_pMapCubes[i], pev_scale, scale);

        copy(g_eCubesInfo[i][Name], charsmax(g_eCubesInfo[][Name]), map);
        g_eCubesInfo[i][Begin] = _:frames_begin;
        g_eCubesInfo[i][End] = _:frames_end;
    }

    arrayset(g_bVoted, false, sizeof(g_bVoted));

    new players[32], pnum;
    get_players(players, pnum, "ch");

    for(new i, id; i < pnum; i++) {
        id = players[i];
        g_bShowGUI[id] = true;
        attach_view(id, g_pPointOfView);
    }

    g_bShowSelects = bool:get_num(SHOW_SELECTS);

    switch_hud(0, false);
    
    g_hForwards[AddToFullPack_Pre] = register_forward(FM_AddToFullPack, "fm_add_to_full_pack_pre", false);
    g_hForwards[AddToFullPack_Post] = register_forward(FM_AddToFullPack, "fm_add_to_full_pack_post", true);
    g_hForwards[CmdStart_Post] = register_forward(FM_CmdStart, "fm_cmd_start_post", true);
    g_hForwards[CheckVisibility_Pre] = register_forward(FM_CheckVisibility, "fm_check_visibility_pre", false);
}

public mapm_countdown(type, time)
{
    if(type != COUNTDOWN_VOTETIME) {
        return;
    }

    const Float:TIME = 1.0;

    for(new i; i < g_iMapsCount; i++) {
        // TODO: show percent
        if(!g_bShowName[i]) {
            continue;
        }
        set_dhudmessage(255, 255, 255, g_fDhudCoords[i][COORD_X], g_fDhudCoords[i][COORD_Y], 0, _, TIME);
        show_dhudmessage(0, "%s", g_eCubesInfo[i][Name]);
    }
}

hide_gui()
{
    for(new i; i < MAX_MAP_CUBES; i++) {
        hide_ent(g_pMapCubes[i]);
    }
    hide_ent(g_pCursorEntity);
    hide_ent(g_pPointOfView);
}

show_gui()
{
    for(new i; i < MAX_MAP_CUBES; i++) {
        show_ent(g_pMapCubes[i]);
    }
    show_ent(g_pCursorEntity);
    show_ent(g_pPointOfView);
}

disable_gui()
{
    new players[32], pnum;
    get_players(players, pnum, "ch");

    for(new i, id; i < pnum; i++) {
        id = players[i];
        g_bShowGUI[id] = false;
        attach_view(id, id);
    }

    for(new i; i < 8; i++) {
        show_dhudmessage(0, "");
    }

    switch_hud(0, true);

    unregister_forward(FM_AddToFullPack, g_hForwards[AddToFullPack_Pre], false);
    unregister_forward(FM_AddToFullPack, g_hForwards[AddToFullPack_Post], true);
    unregister_forward(FM_CmdStart, g_hForwards[CmdStart_Post], true);
    unregister_forward(FM_CheckVisibility, g_hForwards[CheckVisibility_Pre], false);

    hide_gui();
}

public mapm_vote_finished(const map[], type, total_votes)
{
    disable_gui();
}

public mapm_vote_canceled(type)
{
    disable_gui();
}

stock is_inside(Float:corigin[3], Float:borigin[3], Float:w, Float:h)
{
    if(floatabs(corigin[1] - borigin[1]) <= w && floatabs(corigin[2] - borigin[2]) <= h) {
        return true;
    }
    return false;
}

public fm_cmd_start_post(id, cmd, seed)
{
    if (!g_bShowGUI[id]) {
        return FMRES_IGNORED;
    }

    static Float:old_viewangles[33][3], old_buttons[33];
    new Float:view_angles[3], buttons;
    get_uc(cmd, UC_ViewAngles, view_angles);
    buttons = get_uc(cmd, UC_Buttons);
    
    new Float:flDelta = (view_angles[1] - old_viewangles[id][1]);
    if (flDelta > 180.0) {
        flDelta -= 360.0;
    } else if (flDelta < -180.0) {
        flDelta += 360.0;
    }

    g_vecCursorPos[id][1] += flDelta * g_fCursorSens;
    g_vecCursorPos[id][2] += -(view_angles[0] - old_viewangles[id][0]) * g_fCursorSens;

    g_vecCursorPos[id][1] = floatclamp(g_vecCursorPos[id][1], -MAX_CURSOR_X, MAX_CURSOR_X);
    g_vecCursorPos[id][2] = floatclamp(g_vecCursorPos[id][2], -MAX_CURSOR_Y, MAX_CURSOR_Y);

    if(!g_bVoted[id]) {
        new Float:origin[3], Float:coord[3];
        coord[0] = g_vecCursorPos[id][0] + g_vecPOVOrigin[0] + 144.0;
        coord[1] = g_vecCursorPos[id][1] + g_vecPOVOrigin[1];
        coord[2] = g_vecCursorPos[id][2] + g_vecPOVOrigin[2];

        new pos = -1;
        for(new i; i < g_iMapsCount; i++) {
            origin = g_fMapCubesOrigin[i];
            // TODO: find better sizes
            if(is_inside(coord, origin, 28.0, 24.0)) {
                pos = i;
            }
        }

        if(pos >= 0 && pos != g_iCurPos[id]) {
            g_iCurPos[id] = pos;
            g_iCurEnt[id] = g_pMapCubes[pos];
            g_fCurFrame[id] = g_eCubesInfo[pos][Begin];
        } else if (pos == -1 && g_iCurPos[id] >= 0) {
            g_iCurPos[id] = -1;
            g_iCurEnt[id] = 0;
        }

        if(buttons & IN_ATTACK && !(old_buttons[id] & IN_ATTACK) && pos != -1) {
            // console_print(id, "x: %f, y: %f, z: %f", coord[0], coord[1], coord[2]);
            if(g_bShowSelects) {
                new name[32]; get_user_name(id, name, charsmax(name));
                if(pos == g_iCurMap) {
                    client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_CHOSE_EXTEND", name);
                } else {
                    client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_CHOSE_MAP", name, g_eCubesInfo[pos][Name]);
                }
            }
            g_bVoted[id] = true;
            mapm_add_vote_to_item(pos, 1);
        }
    }

    old_viewangles[id] = view_angles;
    old_buttons[id] = buttons;

    return FMRES_IGNORED;
}

is_gui_part(ent)
{
    if(ent == g_pCursorEntity || ent == g_pPointOfView) {
        return true;
    }
    for(new i; i < sizeof(g_pMapCubes); i++) {
        if(ent == g_pMapCubes[i]) {
            return true;
        }
    }
    return false;
}
is_not_included(ent)
{
    for(new i = g_iMapsCount; i < sizeof(g_pMapCubes); i++) {
        if(ent == g_pMapCubes[i]) {
            return true;
        }
    }
    return false;
}

public fm_add_to_full_pack_pre(es, e, ent, host, flags, player, pSet)
{
    if(!g_bShowGUI[host] && is_gui_part(ent)) {
        return FMRES_SUPERCEDE;
    }
    if(g_bShowGUI[host] && is_not_included(ent)) {
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}

public fm_add_to_full_pack_post(es, e, ent, host, flags, player, pSet)
{
    if(g_bShowGUI[host])
    {
        if(ent == g_iCurEnt[host] /* && !g_bVoted[host] */)
        {
            // set_rendering(g_pMapCubes[pos], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 20);
            set_es(es, ES_RenderMode, kRenderNormal);
            set_es(es, ES_RenderAmt, 20);
            set_es(es, ES_RenderColor, SELECTED_COLOR);
            set_es(es, ES_RenderFx, kRenderFxGlowShell);

            new pos = g_iCurPos[host];

            if(g_bVoted[host] || g_eCubesInfo[pos][Begin] == g_eCubesInfo[pos][End]) {
                return FMRES_IGNORED;
            }

            static Float:frame_rate = 0.5;
            static Float:last_anim[33];
            
            new Float:ftime = get_gametime();

            if(ftime - last_anim[host] >= frame_rate) {
                last_anim[host] = ftime;
                if(g_fCurFrame[host] < g_eCubesInfo[pos][End]) {
                    g_fCurFrame[host]++;
                } else if(g_fCurFrame[host] == g_eCubesInfo[pos][End]) {
                    g_fCurFrame[host] = g_eCubesInfo[pos][Begin];
                }
                // log_amx("pos: %d, cur fr %f", pos, g_fCurFrame[host]);
            }
            set_es(es, ES_Frame, g_fCurFrame[host]);
        }
        else if(ent == g_pCursorEntity) {
            new Float:origin[3];
            origin[0] = g_vecCursorPos[host][0] + g_vecPOVOrigin[0] + 143.0;
            origin[1] = g_vecCursorPos[host][1] + g_vecPOVOrigin[1];
            origin[2] = g_vecCursorPos[host][2] + g_vecPOVOrigin[2];

            set_es(es, ES_Origin, origin);
        }
    }
    return FMRES_IGNORED;
}

public fm_check_visibility_pre(pEnt, pSet)
{
    if (is_gui_part(pEnt)) {
        forward_return(FMV_CELL, 1);
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}

public switch_hud(id, enable)
{
    static msg_hide_weapon;
    static hud_flags = (1<<0) | (1<<1) | (1<<3) | (1<<4) | (1<<5) | (1<<6);
    if(!msg_hide_weapon) {
        msg_hide_weapon = get_user_msgid("HideWeapon");
    }
    message_begin((id) ? MSG_ONE : MSG_ALL, msg_hide_weapon, _, id);
    write_byte(enable ? 0 : hud_flags);
    message_end();
}

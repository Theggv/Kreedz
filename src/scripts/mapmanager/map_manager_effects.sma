#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <map_manager>

#define PLUGIN "Map Manager: Effects"
#define VERSION "0.0.10"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])
#define set_num(%0,%1) set_pcvar_num(g_pCvars[%0],%1)
#define get_float(%0) get_pcvar_float(g_pCvars[%0])
#define set_float(%0,%1) set_pcvar_float(g_pCvars[%0],%1)

enum (+=100) {
    TASK_FULLBLACK = 100
};

enum Cvars {
    BLACK_SCREEN,
    BLOCK_CHAT,
    BLOCK_VOICE,
    FREEZE_IN_VOTE,
    VOICE_ENABLED,
    FREEZETIME,
    VOTE_IN_NEW_ROUND,
    PREPARE_TIME,
    VOTE_TIME,
    CHANGE_TYPE,
    LAST_ROUND
};

enum {
    FREEZE_DISABLED,
    FREEZE_TIME_ENABLED,
    FREEZE_FORCE_USE_FLAGS
};

new g_pCvars[Cvars];
new bool:g_bBlockChat;
new bool:g_bFreezeTimeChanged;
new bool:g_bFreezeFlagsChanged;
new HamHook:g_hHamSpawn;

new const g_sSound[][] = {
    "sound/fvox/one.wav", "sound/fvox/two.wav", "sound/fvox/three.wav", "sound/fvox/four.wav", "sound/fvox/five.wav",
    "sound/fvox/six.wav", "sound/fvox/seven.wav", "sound/fvox/eight.wav", "sound/fvox/nine.wav", "sound/fvox/ten.wav"
};

public plugin_init()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[BLACK_SCREEN] = register_cvar("mapm_black_screen", "1"); // 0 - disable, 1 - enable
    g_pCvars[BLOCK_CHAT] = register_cvar("mapm_block_chat", "1"); // 0 - disable, 1 - enable
    g_pCvars[BLOCK_VOICE] = register_cvar("mapm_block_voice", "1"); // 0 - disable, 1 - enable
    g_pCvars[FREEZE_IN_VOTE] = register_cvar("mapm_freeze_in_vote", "1"); //0 - disable, 1 - enable, 2 - force use flags

    g_pCvars[VOICE_ENABLED] = get_cvar_pointer("sv_voiceenable");

    DisableHamForward(g_hHamSpawn = RegisterHam(Ham_Spawn, "player", "player_spawn_post", 1));
}
public plugin_precache()
{
    register_clcmd("say", "clcmd_say");
    register_clcmd("say_team", "clcmd_say");
}
public plugin_cfg()
{
    if(get_num(FREEZE_IN_VOTE)) {
        g_pCvars[FREEZETIME] = get_cvar_pointer("mp_freezetime");
        g_pCvars[VOTE_IN_NEW_ROUND] = get_cvar_pointer("mapm_vote_in_new_round");
        g_pCvars[PREPARE_TIME] = get_cvar_pointer("mapm_prepare_time");
        g_pCvars[VOTE_TIME] = get_cvar_pointer("mapm_vote_time");
        g_pCvars[CHANGE_TYPE] = get_cvar_pointer("mapm_change_type");
        g_pCvars[LAST_ROUND] = get_cvar_pointer("mapm_last_round");
    }
}
public plugin_end()
{
    if(g_bFreezeTimeChanged) {
        set_float(FREEZETIME, get_float(FREEZETIME) - get_float(PREPARE_TIME) - get_float(VOTE_TIME) - 1);
    }
}
public clcmd_say(id)
{
    if(!g_bBlockChat) return PLUGIN_CONTINUE;

    new args[2]; read_args(args, charsmax(args));

    return (args[0] == '/') ? PLUGIN_HANDLED_MAIN : PLUGIN_HANDLED;
}
public player_spawn_post(id)
{
    if(get_num(FREEZE_IN_VOTE) == FREEZE_FORCE_USE_FLAGS || get_num(FREEZE_IN_VOTE) && !get_num(VOTE_IN_NEW_ROUND)) {
        set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
    }
    if(get_num(BLACK_SCREEN)) {
        set_black_screenfade(1);
    }
}
public mapm_countdown(type, time)
{
    if(type == COUNTDOWN_PREPARE) {
        // hud timer
        new players[32], pnum; get_players(players, pnum, "ch");
        set_hudmessage(50, 255, 50, -1.0, 0.3, 0, 0.0, 1.0, 0.0, 0.0, 4);
        for(new i, id; i < pnum; i++) {
            id = players[i];
            show_hudmessage(id, "%L %L!", id, "MAPM_HUD_TIMER", time, id, "MAPM_SECONDS");
        }
        // sound
        if( 0 < time <= 10 ) {
            send_audio(0, g_sSound[time - 1], PITCH_NORM);
        }
    }
}
public mapm_prepare_votelist(type)
{
    if(get_num(BLACK_SCREEN)) {
        set_black_screenfade(2);
        set_task(1.0, "set_full_black", TASK_FULLBLACK);
    }
    if(get_num(BLOCK_CHAT)) {
        g_bBlockChat = true;
    }
    if(get_num(BLOCK_VOICE)) {
        set_num(VOICE_ENABLED, 0);
    }
    if(get_num(FREEZE_IN_VOTE)) {
        if(get_num(FREEZE_IN_VOTE) == FREEZE_TIME_ENABLED 
            && (type == VOTE_BY_SCHEDULER || type == VOTE_BY_RTV || type == VOTE_BY_CMD)
            && get_num(VOTE_IN_NEW_ROUND)) {
            // increase freezetime
            g_bFreezeTimeChanged = true;
            set_float(FREEZETIME, get_float(FREEZETIME) + get_float(PREPARE_TIME) + get_float(VOTE_TIME) + 1);
        } else {
            g_bFreezeFlagsChanged = true;
            freeze_unfreeze(0);
        }
    }
    EnableHamForward(g_hHamSpawn);
}
public mapm_vote_started(type)
{
    send_audio(0, "sound/Gman/Gman_Choose2.wav", PITCH_NORM);
}
public mapm_vote_finished(const map[], type, total_votes)
{
    disable_effects();
}
public mapm_vote_canceled(type)
{
    disable_effects();
}
disable_effects()
{
    if(get_num(BLACK_SCREEN)) {
        remove_task(TASK_FULLBLACK);
        set_black_screenfade(0);
    }
    if(get_num(BLOCK_CHAT)) {
        g_bBlockChat = false;
    }
    if(get_num(BLOCK_VOICE)) {
        set_num(VOICE_ENABLED, 1);
    }
    if(get_num(FREEZE_IN_VOTE) != FREEZE_DISABLED) {
        if(g_bFreezeTimeChanged) {
            // decrease freezetime
            g_bFreezeTimeChanged = false;
            set_float(FREEZETIME, get_float(FREEZETIME) - get_float(PREPARE_TIME) - get_float(VOTE_TIME) - 1);
        }
        if(g_bFreezeFlagsChanged) {
            g_bFreezeFlagsChanged = false;
            freeze_unfreeze(1);
        }
    }
    DisableHamForward(g_hHamSpawn);
}
public set_full_black(taskid)
{
    set_black_screenfade(1);
}
stock freeze_unfreeze(type)
{
    new players[32], pnum; get_players(players, pnum, "a");
    for(new id, i; i < pnum; i++) {
        id = players[i];
        set_pev(id, pev_flags, type ? (pev(id, pev_flags) & ~FL_FROZEN) : pev(id, pev_flags) | FL_FROZEN);
    }
}
stock set_black_screenfade(fade)
{
    new time, hold, flags;
    static msg_screenfade; if(!msg_screenfade) msg_screenfade = get_user_msgid("ScreenFade");
    
    switch (fade) {
        case 1: { time = 1; hold = 1; flags = 4; }
        case 2: { time = 4096; hold = 1024; flags = 1; }
        default: { time = 4096; hold = 1024; flags = 2; }
    }

    message_begin(MSG_ALL, msg_screenfade);
    write_short(time);
    write_short(hold);
    write_short(flags);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    write_byte(255);
    message_end();
}

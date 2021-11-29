#include <amxmodx>
#include <map_manager>
#include <map_manager_scheduler>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Rtv"
#define VERSION "0.1.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#if !defined client_disconnected
#define client_disconnected client_disconnect
#endif

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
    MODE,
    PERCENT,
    PLAYERS,
    DELAY,
    CHANGE_AFTER_VOTE,
    CHANGE_TYPE,
    ALLOW_EXTEND
};

enum {
    MODE_PERCENTS,
    MODE_PLAYERS
};

new g_pCvars[Cvars];
new g_iMapStartTime;
new bool:g_bVoted[33];
new g_iVotes;

new g_sPrefix[48];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[MODE] = register_cvar("mapm_rtv_mode", "0"); // 0 - percents, 1 - players
    g_pCvars[CHANGE_AFTER_VOTE] = register_cvar("mapm_rtv_change_after_vote", "0"); // 0 - disable, 1 - enable
    g_pCvars[PERCENT] = register_cvar("mapm_rtv_percent", "60");
    g_pCvars[PLAYERS] = register_cvar("mapm_rtv_players", "5");
    g_pCvars[DELAY] = register_cvar("mapm_rtv_delay", "0"); // minutes
    g_pCvars[ALLOW_EXTEND] = register_cvar("mapm_rtv_allow_extend", "0"); // 0 - disable, 1 - enable

    register_clcmd("say rtv", "clcmd_rtv");
    register_clcmd("say /rtv", "clcmd_rtv");

    // reset it with sv_restart?
    g_iMapStartTime = get_systime();
}
public plugin_cfg()
{
    mapm_get_prefix(g_sPrefix, charsmax(g_sPrefix));
    g_pCvars[CHANGE_TYPE] = get_cvar_pointer("mapm_change_type");
}
public client_disconnected(id)
{
    if(g_bVoted[id]) {
        g_bVoted[id] = false;
        g_iVotes--;
    }
}
public clcmd_rtv(id)
{
    if(is_vote_started() || is_vote_finished() || is_vote_will_in_next_round()) {
        // add msg?
        return PLUGIN_HANDLED;
    }

    new delay = get_num(DELAY) * 60 - (get_systime() - g_iMapStartTime);
    if(delay > 0) {
        client_print_color(id, print_team_default, "%s^1 %L", g_sPrefix, id, "MAPM_RTV_DELAY", delay / 60, delay % 60);
        return PLUGIN_HANDLED;
    }

    if(!g_bVoted[id]) {
        g_iVotes++;
    }

    new need_votes;
    if(get_num(MODE) == MODE_PERCENTS) {
        need_votes = floatround(get_players_num() * get_num(PERCENT) / 100.0, floatround_ceil) - g_iVotes;
    } else {
        need_votes = get_num(PLAYERS) - g_iVotes;
    }

    if(need_votes <= 0) {
        map_scheduler_start_vote(VOTE_BY_RTV);
        return PLUGIN_HANDLED;
    }

    if(!g_bVoted[id]) {
        g_bVoted[id] = true;
        new name[32]; get_user_name(id, name, charsmax(name));
        client_print_color(0, print_team_default, "%s^3 %L.", g_sPrefix, LANG_PLAYER, "MAPM_RTV_VOTED", name, need_votes);
    } else {
        client_print_color(id, print_team_default, "%s^1 %L.", g_sPrefix, id, "MAPM_RTV_ALREADY_VOTED", need_votes);
    }

    return PLUGIN_HANDLED;
}
public mapm_can_be_extended(type)
{
    if(type == VOTE_BY_RTV && !get_num(ALLOW_EXTEND)) {
        return EXTEND_BLOCKED;
    }
    return EXTEND_ALLOWED;
}
public mapm_vote_started(type)
{
    g_iVotes = 0;
    arrayset(g_bVoted, false, sizeof(g_bVoted));
}
public mapm_vote_finished(const map[], type, total_votes)
{
    if(type == VOTE_BY_RTV && get_num(CHANGE_TYPE) && get_num(CHANGE_AFTER_VOTE)) {
        intermission();
    }
}

#if defined _map_manager_stocks_included
  #endinput
#endif
#define _map_manager_stocks_included

stock valid_map(map[])
{
    if(is_map_valid(map)) return true;
    
    new len = strlen(map) - 4;
    
    if(len < 0) return false;
    
    if(equali(map[len], ".bsp")) {
        map[len] = '^0';
        if(is_map_valid(map)) return true;
    }
    
    return false;
}
stock get_map_prefix(map[], prefix[], size)
{
    copy(prefix, size, map);
    for(new i; prefix[i]; i++) {
        if(prefix[i] == '_') {
            prefix[i + 1] = 0;
            return 1;
        }
    }
    return 0;
}
stock bool:is_string_with_space(string[])
{
    for(new i; string[i]; i++) {
        if(string[i] == ' ') return true;
    }
    return false;
}
stock trim_bracket(text[])
{
    for(new i; text[i]; i++) {
        if(text[i] == '[') {
            text[i] = 0;
            break;
        }
    }
}
stock intermission()
{
    emessage_begin(MSG_ALL, SVC_INTERMISSION);
    emessage_end();
}
stock get_players_num(ignore = 0)
{
    static maxplayers;
    if(!maxplayers) {
        maxplayers = get_maxplayers();
    }
    new pnum;
    for(new i = 1; i <= maxplayers; i++) {
        if(ignore && i == ignore
            || !is_user_connected(i)
            || is_user_bot(i)
            || is_user_hltv(i)) {
            continue;
        }
        pnum++;
    }
    return pnum;
}
stock send_audio(id, audio[], pitch)
{
    static msg_send_audio;
    
    if(!msg_send_audio) {
        msg_send_audio = get_user_msgid("SendAudio");
    }

    message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msg_send_audio, _, id);
    write_byte(id);
    write_string(audio);
    write_short(pitch);
    message_end();
}
stock replace_color_tag(string[], len)
{
    while(replace(string, len, "^^1", "^1")) {}
    while(replace(string, len, "^^3", "^3")) {}
    while(replace(string, len, "^^4", "^4")) {}
    while(replace(string, len, "!d", "^1")) {}
    while(replace(string, len, "!t", "^3")) {}
    while(replace(string, len, "!g", "^4")) {}
}

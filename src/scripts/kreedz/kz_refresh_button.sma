#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN 	 	"[Kreedz] No Refresh Button"
#define VERSION 	__DATE__
#define AUTHOR	 	"PRoSToTeM@"

new HamHook:g_PlayerIsAlivePost;
new HamHook:g_TankUse;
new HamHook:g_PlayerImpulseCommands;
new HamHook:g_PlayerImpulseCommandsPost;

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Player_PostThink, "player", "PlayerPostThinkPre", .Post = false);
    RegisterHam(Ham_Player_PostThink, "player", "PlayerPostThinkPost", .Post = true);

    g_PlayerIsAlivePost = RegisterHam(Ham_IsAlive, "player", "PlayerIsAlivePost", .Post = true);
    DisableHamForward(g_PlayerIsAlivePost);
    g_TankUse = RegisterHam(Ham_Use, "func_tank", "TankUse");
    DisableHamForward(g_TankUse);
    g_PlayerImpulseCommands = RegisterHam(Ham_Player_ImpulseCommands, "player", "PlayerImpulseCommands");
    DisableHamForward(g_PlayerImpulseCommands);
    g_PlayerImpulseCommandsPost = RegisterHam(Ham_Player_ImpulseCommands, "player", "PlayerImpulseCommandsPost", .Post = true);
    DisableHamForward(g_PlayerImpulseCommandsPost);

    for (new i = 1; i < 32; ++i) {
        new weaponName[32];
        if (get_weaponname(i, weaponName, charsmax(weaponName)))
            RegisterHam(Ham_Item_PostFrame, weaponName, "ItemPostFrame", .Post = false);
    }
}

new Float:g_oldNextAttack;

public PlayerPostThinkPre(player) {
    EnableHamForward(g_PlayerIsAlivePost);
}

public PlayerIsAlivePost(player) {
    DisableHamForward(g_PlayerIsAlivePost);

    new ret;
    GetOrigHamReturnInteger(ret);
    if (ret == 0) {
        return;
    }

    if (get_pdata_ent(player, 1408) != -1 && pev_serial(get_pdata_ent(player, 1408)) == get_pdata_int(player, 1412/4)) {
        EnableHamForward(g_TankUse);
    } else {
        if (get_pdata_cbase(player, 373) == -1 || (get_pdata_int(player, 2043/4) & 0xFF000000) == 0 || get_pdata_int(get_pdata_cbase(player, 373), 216/4, 4) == 0 || (pev(player, pev_button) & IN_ATTACK2) == 0) {
            g_oldNextAttack = get_pdata_float(player, 83);
            if (g_oldNextAttack > 0.0) {
                set_pdata_float(player, 83, 0.0);
                EnableHamForward(g_PlayerImpulseCommands);
                EnableHamForward(g_PlayerImpulseCommandsPost);
            }
        }
    }
}

public TankUse(ent, caller, useType) {
    DisableHamForward(g_TankUse);

    if (useType == 0) {
        if (get_pdata_cbase(caller, 373) == -1 || (get_pdata_int(caller, 2043/4) & 0xFF000000) == 0 || get_pdata_int(get_pdata_cbase(caller, 373), 216/4, 4) == 0 || (pev(caller, pev_button) & IN_ATTACK2) == 0) {
            g_oldNextAttack = get_pdata_float(caller, 83);
            if (g_oldNextAttack > 0.0) {
                set_pdata_float(caller, 83, 0.0);
                EnableHamForward(g_PlayerImpulseCommands);
                EnableHamForward(g_PlayerImpulseCommandsPost);
            }
        }
    }
}

new g_oldImpulse;

public PlayerImpulseCommands(player) {
    DisableHamForward(g_PlayerImpulseCommands);

    g_oldImpulse = pev(player, pev_impulse);
    set_pev(player, pev_impulse, 0);
}

new bool:g_doActions = false;

public PlayerImpulseCommandsPost(player) {
    DisableHamForward(g_PlayerImpulseCommandsPost);

    set_pdata_float(player, 83, floatmax(get_pdata_float(player, 83), g_oldNextAttack));
    if (get_pdata_cbase(player, 373) != -1) {
        g_doActions = true;
    }
    set_pev(player, pev_impulse, g_oldImpulse);
}

public ItemPostFrame(ent) {
    if (!g_doActions) {
        return HAM_IGNORED;
    }

    g_doActions = false;
    return HAM_SUPERCEDE;
}

public PlayerPostThinkPost(player) {
    DisableHamForward(g_PlayerIsAlivePost);
}
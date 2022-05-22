/*
	stats by kzuq^BorJomi 
	version 2.42
	
	Big thanks developers of kz_ljs_xm and Exolent
	
	Visit  http://unique-kz.com/
	
		2011 year
*/

#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <uq_jumpstats_const.inc>
#include <uq_jumpstats_stocks.inc>
#include <celltrie>
// #include <dhudmessage>
#include <kreedz_api>
#include <settings_api>

#define VERSION "2.42"
#pragma semicolon 1

////////////////////////////////////Some shit varibeles////////////////////////////////////
new dd_sync[33],angles_arry[33],Float:old_angles[33][3],lost_frame_count[33][NSTRAFES],line_lost[33][NSTRAFES][NVAR],FullJumpFrames[33],heystats,max_players,bool:duckbhop_bug_pre[33],bool:dropupcj[33],Float:first_duck_z[33],screenshoot,Float:checkladdertime[33],bool:ladderbug[33],bool:login[33];
new uq_istrafe,kz_uq_istrafe,bug_check[33],bool:bug_true[33],bool:find_ladder[33],bool:Checkframes[33],type_button_what[33][100];
new min_pre,beam_type[33],min_prestrafe[33],dropbhop[33],ddnum[33],bool:dropaem[33],bool:ddforcj[33];
new kz_uq_min_other,bool:slide_protec[33],bool:UpcjFail[33],bool:upBhop[33],Float:upheight[33];
new beam_entity[33][NVAR],ent_count[33],kz_uq_extras,sql_stats,kz_sql,g_sql_pid[33],kz_top_rank_by,kz_uq_block_top;

new bool:height_show[33],bool:firstfall_ground[33],framecount[33],bool:firstladder[33];
new Float:FallTime[33],Float:FallTime1[33],multiscj[33],multidropcj[33],bool:enable_sound[33];
new jumpblock[33],Float:edgedist[33];
new bool:failed_jump[33],bool:started_multicj_pre[33],bool:sync_doubleduck[33],bhop_num[33],bool:Show_edge_Fail[33],bool:Show_edge[33],bool:fps_hight[33],bool:first_ground_bhopaem[33];

new line_erase[33][NSTRAFES],line_erase_strnum[33];

new max_edge,min_edge,NSTRAFES1,max_strafes,Float:nextbhoptime[33],Float:bhopaemtime[33],Float:ground_bhopaem_time[33],Float:SurfFrames[33],Float:oldSurfFrames[33],bool:first_air[33];
new bool:preessbutton[33],button_what[33],bool:gBeam_button[33][100],gBeam_button_what[33][100];
new bool:h_jumped[33],Float:heightoff_origin[33],web_stats,Float:x_heightland_origin[33],bool:x_jump[33],Float:laddertime[33],bool:edgedone[33];
new schetchik[33],Float:changetime[33],bool:edgeshow[33],bool:slide[33],pre_type[33][33];

new bool:ingame_strafe[33],bool:ljpre[33],Float:distance[33],detecthj[33],bool:doubleduck[33];
new Float:doubletime[33],bool:multibhoppre[33],kz_uq_fps,bool:duckbhop[33],MAX_DISTANCE,Float:upbhop_koeff[33];
new Float:rDistance[3],Float:frame2time,bool:touch_ent[33],bool:ddbeforwj[33],bool:gHasColorChat[33],Float:old_angle1[33];
new bool:g_lj_stats[33],strafe_num[33],bool:g_Jumped[33],bool:g_reset[33],ljsDir[64],ljsDir_weapon[8][64],ljsDir_block[64],Float:gBeam_points[33][100][3],gBeam_duck[33][100],gBeam_count[33];

new gBeam,waits[33],waits1[33],Float:slideland[33],bool:backwards[33],bool:hookcheck[33],Float:timeonground[33];
new map_dist[NTOP+1],map_syncc[NTOP+1],map_maxsped[NTOP+1], map_prestr[NTOP+1],map_names[NTOP+1][33],map_ip[NTOP+1][33],map_streif[NTOP+1],map_type[NTOP+1][33];
new kz_uq_lj,kz_uq_cj,kz_uq_dcj,kz_uq_mcj ,kz_uq_ladder,kz_uq_ldbj,kz_uq_bj,kz_uq_sbj,kz_uq_drbj,kz_uq_drsbj,kz_uq_drcj,kz_uq_wj;	

new oldpre[33],oldljpre[33],oldfail[33],Float:starthj[33][3],Float:stophj[33][3], Float:endhj[33][3];
new bool:landslide[33],strafecounter_oldbuttons[33],Float:Fulltime,Float:needslide[33],Float:groundslide[33];
new jj,sync_[33],goodSyncTemp,badSyncTemp,strafe_lost_frame[33][NSTRAFES],Float:time_,Float:strafe_stat_time[33][NSTRAFES],Float:strafe_stat_speed[33][NSTRAFES][2];
new strafe_stat_sync[33][NSTRAFES][2],strLen,strMess[40*NSTRAFES],strMessBuf[40*NSTRAFES],team[33];

new bool:g_pBot[33],strL,strM[40*NSTRAFES],strMBuf[40*NSTRAFES],Float:firstvel[33],Float:secvel[33],Float:firstorig[33][3],Float:secorig[33][3];
new Float:speed[33], Float:TempSpeed[33],Float:statsduckspeed[33][500]; 
new bool:slidim[33],Float:slidedist[33],edgefriction,mp_footsteps,sv_cheats,sv_airaccelerate,sv_maxspeed,sv_stepsize,sv_maxvelocity,sv_gravity;

new kz_min_dcj,kz_stats_x,kz_stats_y,Float:stats_x,Float:stats_y,taskslide[33],taskslide1[33],bool:failslide[33];
new Float:failslidez[33],kz_strafe_x,kz_strafe_y,Float:strafe_x,Float:strafe_y,Float:laddist[33],kz_duck_x;
new kz_duck_y,Float:duck_x,Float:duck_y,bool:bhopaem[33],bool:nextbhop[33],kz_stats_red,kz_stats_green, kz_stats_blue, kz_failstats_red,kz_failstats_green;
new kz_failstats_blue, kz_sounds, kz_airaccelerate,kz_uq_url,kz_prefix,kz_legal_settings;

new kz_good_lj,kz_pro_lj,kz_holy_lj,kz_leet_lj,kz_god_lj,kz_good_bj,kz_pro_bj,kz_holy_bj,kz_leet_bj,kz_god_bj;
new kz_good_cj,kz_pro_cj,kz_holy_cj,kz_leet_cj,kz_god_cj,kz_good_wj,kz_pro_wj,kz_holy_wj,kz_leet_wj,kz_god_wj;
new kz_good_dbj,kz_pro_dbj, kz_holy_dbj,kz_leet_dbj, kz_god_dbj,kz_good_scj,kz_pro_scj, kz_holy_scj,kz_leet_scj, kz_god_scj;
new kz_good_ladder,kz_pro_ladder,kz_holy_ladder, kz_leet_ladder,kz_god_ladder,kz_good_dcj,kz_pro_dcj,kz_holy_dcj,kz_leet_dcj,kz_god_dcj;

new kz_god_duckbhop,kz_holy_duckbhop,kz_pro_duckbhop,kz_good_duckbhop,kz_good_dropscj,kz_pro_dropscj,kz_holy_dropscj,kz_leet_dropscj,kz_god_dropscj;
new kz_good_real,kz_pro_real,kz_holy_real,kz_leet_real,kz_god_real,kz_good_bhopinduck,kz_pro_bhopinduck,kz_holy_bhopinduck,kz_leet_bhopinduck,kz_god_bhopinduck;
new kz_god_upbj,kz_leet_upbj,kz_good_upbj, kz_pro_upbj,kz_holy_upbj,kz_god_upsbj,kz_leet_upsbj,kz_good_upsbj, kz_pro_upsbj,kz_holy_upsbj;
new kz_uq_dscj,kz_uq_mscj,kz_leet_duckbhop,kz_uq_dropscj,kz_uq_dropdscj,kz_uq_dropmscj,kz_uq_duckbhop,kz_uq_bhopinduck,kz_uq_realldbhop,kz_uq_multibhop,kz_uq_upbj,kz_uq_upbhopinduck,kz_uq_upsbj,kz_uq_dropdcj,kz_uq_dropmcj;

new user_block[33][2],Float:slidez[33][4][3],prefix[64];

new CjafterJump[33],bool:ddafterJump[33],bool:cjjump[33],bool:serf_reset[33],entlist[256],ent,nLadder,Float:ladderxyz[256][3],Float:ladderminxyz[256][3], Float:laddersize[256][3], nashladder,bool:ladderjump[33];
new bool:kz_stats_pre[33], bool:kz_beam[33],bool:showpre[33],bool:showjofon[33],bool:speedon[33],bool:jofon[33];

new Float:dropbjorigin[33][3], Float:falloriginz[33],Float:origin[3],ducks[33], movetype[33];
static Float:maxspeed[33], Float:prestrafe[33],JumpType:jump_type[33],JumpType:old_type_dropbj[33], frames[33], frames_gained_speed[33], bool:turning_left[33];
static bool:turning_right[33],bool:started_cj_pre[33],bool:in_duck[33], bool:in_bhop[33],bool:in_air[33],bool:in_ladder[33];
new bool:player_admin[33],bool:failearly[33],bool:firstshow[33],bool:first_onground[33],bool:notjump[33],bool:OnGround[33],bool:donehook[33];

new bool:streifstat[33],Jtype[33][33],Jtype1[33][33],Jtype_old_dropbj[33][33],Jtype_old_dropbj1[33][33],Float:weapSpeed[33],Float:weapSpeedOld[33];
new airacel[33][33],bool:firstfr[33],kz_speed_x,kz_speed_y,hud_stats,hud_streif,hud_pre,hud_duck,hud_speed; 
new kz_uq_connect,kz_uq_light,bool:duckstring[33],kz_uq_top,kz_uq_maptop,bool:showduck[33],Float:surf[33];
new bool:first_surf[33],oldjump_type[33],oldjump_typ1[33],jump_typeOld[33],mapname[33],Float:duckstartz[33],direct_for_strafe[33];
new Float:height_difference[33],kz_uq_team,bool:jumpoffirst[33],bool:posibleScj[33];
new kz_uq_noslow,kz_prest_x,kz_prest_y,kz_speed_r,kz_speed_g,kz_speed_b,kz_prest_r,kz_prest_g,kz_prest_b;

new weapon_top,bool:touch_somthing[33],record_start[33],allow_info;
new showtime_st_stats[33];

new Float:jof[33],weapon_block_top;

new g_playername[33][64], g_playersteam[33][35], g_playerip[33][16], rankby,plugin_ver[33];

new ljsDir_block_weapon[8][64],uq_host,uq_user,uq_pass,uq_db,Handle:DB_TUPLE,Handle:SqlConnection,g_error[512],sql_Cvars_num[SQLCVARSNUM];
new sql_JumpType[33];
new Trie:JData,Trie:JData_Block,Float:oldjump_height[33],Float:jheight[33],bool:jheight_show[33];

new uq_lj,uq_cj,uq_dcj,uq_mcj,uq_ladder,uq_ldbj,uq_bj,uq_sbj,uq_drbj,uq_drsbj,uq_drcj;	
new uq_wj,uq_dscj,uq_mscj,uq_dropscj,uq_dropdscj,uq_dropmscj,uq_duckbhop,uq_bhopinduck;
new uq_realldbhop,uq_upbj,uq_upbhopinduck,uq_upsbj,uq_multibhop,uq_dropdcj,uq_dropmcj;
new dcj_god_dist,dcj_leet_dist,dcj_holy_dist,dcj_pro_dist,dcj_good_dist;
new lj_god_dist,lj_leet_dist,lj_holy_dist,lj_pro_dist,lj_good_dist;
new ladder_god_dist,ladder_leet_dist,ladder_holy_dist,ladder_pro_dist,ladder_good_dist;
new wj_god_dist,wj_leet_dist,wj_holy_dist,wj_pro_dist,wj_good_dist;
new bj_god_dist,bj_leet_dist,bj_holy_dist,bj_pro_dist,bj_good_dist;
new cj_god_dist,cj_leet_dist,cj_holy_dist,cj_pro_dist,cj_good_dist;
new dbj_god_dist,dbj_leet_dist,dbj_holy_dist,dbj_pro_dist,dbj_good_dist;
new scj_god_dist,scj_leet_dist,scj_holy_dist,scj_pro_dist,scj_good_dist;
new dropscj_god_dist,dropscj_leet_dist,dropscj_holy_dist,dropscj_pro_dist,dropscj_good_dist;
new bhopinduck_god_dist,bhopinduck_leet_dist,bhopinduck_holy_dist,bhopinduck_pro_dist,bhopinduck_good_dist;
new upbj_god_dist,upbj_leet_dist,upbj_holy_dist,upbj_pro_dist,upbj_good_dist;
new upsbj_god_dist,upsbj_leet_dist,upsbj_holy_dist,upsbj_pro_dist,upsbj_good_dist;
new real_god_dist,real_leet_dist,real_holy_dist,real_pro_dist,real_good_dist;
new duckbhop_god_dist,duckbhop_leet_dist,duckbhop_holy_dist,duckbhop_pro_dist,duckbhop_good_dist;
new web_sql,max_distance,min_distance_other,min_distance,uq_airaccel,leg_settings,uq_sounds;
new uq_maxedge,uq_minedge,uq_min_pre,speed_r,speed_g,speed_b,Float:speed_x,Float:speed_y,h_speed,kz_top,kz_extras,kz_weapon,kz_block_top;
new uq_team,prest_r,prest_g,prest_b,Float:prest_x,Float:prest_y,h_prest,h_stats,h_duck,h_streif;				
new uq_noslow,uq_light,uq_screen,uq_info,uq_fps,kz_map_top,kz_wpn_block_top,stats_r,stats_b,stats_g,f_stats_r,f_stats_b,f_stats_g;
//new uq_sv_maxvelocity,uq_sv_stepsize,uq_sv_maxspeed,uq_edgefriction,uq_mp_footsteps,uq_sv_cheats,uq_sv_gravity,uq_sv_airaccelerate;
new kz_uq_script_work,uq_script_work,uq_ban_minutes,kz_uq_ban_minutes,uq_bug,kz_uq_bug,uq_script_notify,kz_uq_script_notify,uq_admins,kz_uq_admins,kz_uq_script_detection,uq_script_detection,kz_uq_update_auth,uq_update_auth;
new doubleduck_stat_sync[33][2],logs_path[128],uq_script_punishment,kz_uq_script_punishment,uq_ban_authid,uq_ban_type,kz_uq_ban_authid,kz_uq_ban_type;
new kz_uq_block_chat_show,kz_uq_block_chat_min,uq_block_chat_show,uq_block_chat_min;


new bool:speedtype[33],ddforcjafterbhop[33],ddforcjafterladder[33],ddstandcj[33];
new bool:trigger_protection[33],kz_uq_speed_allteam,uq_speed_allteam;

new sql_Cvars[SQLCVARSNUM][] = { //cvars for db
	"kz_uq_save_extras_top",
	"kz_uq_top_by",
	"kz_uq_sql",
	"kz_uq_block_top"
};

new Trie:JumpPlayers;

new const KZ_CVARSDIR[] = "config.cfg";

enum OptionsEnum {
    optIntJumpStats,
};

new g_Options[OptionsEnum];
new g_OptionFlags[MAX_PLAYERS + 1];


public plugin_init()
{
	register_plugin( "JumpStats", VERSION, "BorJomi" );
	
	register_dictionary("uq_jumpstats.txt");
	
	kz_good_lj            = register_cvar("kz_uq_good_lj",            "240");	// lj hj
	kz_pro_lj            = register_cvar("kz_uq_pro_lj",             "245");
	kz_holy_lj            = register_cvar("kz_uq_holy_lj",            "250");
	kz_leet_lj           = register_cvar("kz_uq_leet_lj",            "253");
	kz_god_lj           = register_cvar("kz_uq_god_lj",            "255");
	
	kz_good_cj            = register_cvar("kz_uq_good_cj",            "250");	// cj
	kz_pro_cj            = register_cvar("kz_uq_pro_cj",             "255");
	kz_holy_cj            = register_cvar("kz_uq_holy_cj",            "260");
	kz_leet_cj           = register_cvar("kz_uq_leet_cj",            "265");
	kz_god_cj           = register_cvar("kz_uq_god_cj",            "267");
	
	kz_good_dcj            = register_cvar("kz_uq_good_dcj",            "250");	// dcj mcj
	kz_pro_dcj            = register_cvar("kz_uq_pro_dcj",             "255");
	kz_holy_dcj            = register_cvar("kz_uq_holy_dcj",            "260");
	kz_leet_dcj           = register_cvar("kz_uq_leet_dcj",            "265");
	kz_god_dcj           = register_cvar("kz_uq_god_dcj",            "270");
	
	kz_good_ladder           = register_cvar("kz_uq_good_ladder",            "150");	// ladder
	kz_pro_ladder           = register_cvar("kz_uq_pro_ladder",             "160");
	kz_holy_ladder           = register_cvar("kz_uq_holy_ladder",            "170");
	kz_leet_ladder           = register_cvar("kz_uq_leet_ladder",            "180");
	kz_god_ladder          = register_cvar("kz_uq_god_ladder",            "190");
	
	kz_good_bj           = register_cvar("kz_uq_good_bj",            "230");	// bj sbj
	kz_pro_bj           = register_cvar("kz_uq_pro_bj",             "235");
	kz_holy_bj           = register_cvar("kz_uq_holy_bj",            "240");
	kz_leet_bj           = register_cvar("kz_uq_leet_bj",            "245");
	kz_god_bj          = register_cvar("kz_uq_god_bj",            "247");
	
	kz_good_wj          = register_cvar("kz_uq_good_wj",            "255");	// wj dropcj ladderbhop
	kz_pro_wj           = register_cvar("kz_uq_pro_wj",             "260");
	kz_holy_wj           = register_cvar("kz_uq_holy_wj",            "265");
	kz_leet_wj           = register_cvar("kz_uq_leet_wj",            "270");
	kz_god_wj          = register_cvar("kz_uq_god_wj",            "272");
	
	kz_good_dbj          = register_cvar("kz_uq_good_dbj",            "240");	// 
	kz_pro_dbj          = register_cvar("kz_uq_pro_dbj",             "250");
	kz_holy_dbj          = register_cvar("kz_uq_holy_dbj",            "265");
	kz_leet_dbj           = register_cvar("kz_uq_leet_dbj",            "270");
	kz_god_dbj          = register_cvar("kz_uq_god_dbj",            "272");
	
	kz_good_scj          = register_cvar("kz_uq_good_scj",            "245");	// 
	kz_pro_scj          = register_cvar("kz_uq_pro_scj",             "250");
	kz_holy_scj          = register_cvar("kz_uq_holy_scj",            "255");
	kz_leet_scj           = register_cvar("kz_uq_leet_scj",            "260");
	kz_god_scj          = register_cvar("kz_uq_god_scj",            "262");
	
	kz_good_dropscj          = register_cvar("kz_uq_good_dropscj",            "255");	// 
	kz_pro_dropscj          = register_cvar("kz_uq_pro_dropscj",             "260");
	kz_holy_dropscj          = register_cvar("kz_uq_holy_dropscj",            "265");
	kz_leet_dropscj           = register_cvar("kz_uq_leet_dropscj",            "270");
	kz_god_dropscj          = register_cvar("kz_uq_god_dropscj",            "272");
	
	kz_good_duckbhop          = register_cvar("kz_uq_good_duckbhop",            "120");	// 
	kz_pro_duckbhop          = register_cvar("kz_uq_pro_duckbhop",             "130");
	kz_holy_duckbhop          = register_cvar("kz_uq_holy_duckbhop",            "140");
	kz_leet_duckbhop         = register_cvar("kz_uq_leet_duckbhop",            "150");
	kz_god_duckbhop         = register_cvar("kz_uq_god_duckbhop",            "160");
	
	kz_good_bhopinduck         = register_cvar("kz_uq_good_bhopinduck",            "205");	// 
	kz_pro_bhopinduck          = register_cvar("kz_uq_pro_bhopinduck",             "210");
	kz_holy_bhopinduck          = register_cvar("kz_uq_holy_bhopinduck",            "215");
	kz_leet_bhopinduck          = register_cvar("kz_uq_leet_bhopinduck",            "218");
	kz_god_bhopinduck         = register_cvar("kz_uq_god_bhopinduck",            "220");
	
	kz_good_real         = register_cvar("kz_uq_good_realldbhop",            "240");	// 
	kz_pro_real          = register_cvar("kz_uq_pro_realldbhop",             "250");
	kz_holy_real         = register_cvar("kz_uq_holy_realldbhop",            "265");
	kz_leet_real         = register_cvar("kz_uq_leet_realldbhop",            "270");
	kz_god_real         = register_cvar("kz_uq_god_realldbhop",            "272");
	
	kz_good_upbj         = register_cvar("kz_uq_good_upbj",            "225");	// 
	kz_pro_upbj          = register_cvar("kz_uq_pro_upbj",             "230");
	kz_holy_upbj          = register_cvar("kz_uq_holy_upbj",            "235");
	kz_leet_upbj          = register_cvar("kz_uq_leet_upbj",            "240");
	kz_god_upbj         = register_cvar("kz_uq_god_upbj",            "245");
	
	kz_good_upsbj         = register_cvar("kz_uq_good_upbj",            "230");	// 
	kz_pro_upsbj          = register_cvar("kz_uq_pro_upbj",             "235");
	kz_holy_upsbj          = register_cvar("kz_uq_holy_upbj",            "240");
	kz_leet_upsbj          = register_cvar("kz_uq_leet_upbj",            "244");
	kz_god_upsbj         = register_cvar("kz_uq_god_upbj",            "246");
	
	kz_min_dcj          = register_cvar("kz_uq_min_dist",            "215");
	MAX_DISTANCE         = register_cvar("kz_uq_max_dist",            "290");
	
	kz_stats_red        = register_cvar("kz_uq_stats_red",        "0");		
	kz_stats_green      = register_cvar("kz_uq_stats_green",      "255");
	kz_stats_blue       = register_cvar("kz_uq_stats_blue",       "159");
	kz_failstats_red        = register_cvar("kz_uq_failstats_red",        "255");		
	kz_failstats_green      = register_cvar("kz_uq_failstats_green",      "0");
	kz_failstats_blue       = register_cvar("kz_uq_failstats_blue",       "109");
	
	kz_sounds 	     = register_cvar("kz_uq_sounds",           "1");
	kz_top_rank_by        = register_cvar("kz_uq_top_by",        "1");		// How ranking will work? 0=name, 1=ip 2=steam
	kz_legal_settings     = register_cvar("kz_uq_legal_settings",     "1");
	kz_prefix 	       = register_cvar("kz_uq_prefix",       "unique-kz");
	kz_airaccelerate     = register_cvar("kz_uq_airaccelerate",     "10");
	
	kz_stats_x        = register_cvar("kz_uq_stats_x",        "-1.0");		
	kz_stats_y      = register_cvar("kz_uq_stats_y",      "0.70");
	kz_strafe_x        = register_cvar("kz_uq_strafe_x",        "0.70");		
	kz_strafe_y      = register_cvar("kz_uq_strafe_y",      "0.35");
	kz_duck_x        = register_cvar("kz_uq_duck_x",        "0.6");		
	kz_duck_y      = register_cvar("kz_uq_duck_y",      "0.78");
	kz_speed_x        = register_cvar("kz_uq_speed_x",        "-1.0");		
	kz_speed_y      = register_cvar("kz_uq_speed_y",      "0.83");
	kz_prest_x        = register_cvar("kz_uq_prestrafe_x",        "-1.0");		
	kz_prest_y      = register_cvar("kz_uq_prestrafe_y",      "0.65");
	
	kz_speed_r        = register_cvar("kz_uq_speed_red",        "255");		
	kz_speed_g        = register_cvar("kz_uq_speed_green",      "255");
	kz_speed_b          = register_cvar("kz_uq_speed_blue",        "255");		
	kz_prest_r        = register_cvar("kz_uq_prestrafe_red",        "255");		
	kz_prest_g      = register_cvar("kz_uq_prestrafe_green",      "255");
	kz_prest_b        = register_cvar("kz_uq_prestrafe_blue",        "255");
	
	hud_stats       = register_cvar("kz_uq_hud_stats",        "3");		
	hud_streif    = register_cvar("kz_uq_hud_strafe",      "4");
	hud_pre      = register_cvar("kz_uq_hud_pre",        "1");		
	hud_duck     = register_cvar("kz_uq_hud_duck",      "1");
	hud_speed     = register_cvar("kz_uq_hud_speed",      "2");
	
	kz_uq_lj       = register_cvar("kz_uq_lj",        "1");	
	kz_uq_cj       = register_cvar("kz_uq_cj",        "1");	
	kz_uq_dcj       = register_cvar("kz_uq_dcj",        "1");	
	kz_uq_mcj       = register_cvar("kz_uq_mcj",        "1");	
	kz_uq_ladder       = register_cvar("kz_uq_ladder",        "1");	
	kz_uq_ldbj       = register_cvar("kz_uq_ldbj",        "1");	
	kz_uq_bj       = register_cvar("kz_uq_bj",        "1");	
	kz_uq_sbj       = register_cvar("kz_uq_sbj",        "1");	
	kz_uq_drbj       = register_cvar("kz_uq_drbj",        "1");	
	kz_uq_drsbj       = register_cvar("kz_uq_scj",        "1");	
	kz_uq_drcj       = register_cvar("kz_uq_drcj",        "1");	
	kz_uq_wj       = register_cvar("kz_uq_wj",        "1");	
	
	kz_uq_dscj       = register_cvar("kz_uq_dscj",        "1");	
	kz_uq_mscj       = register_cvar("kz_uq_mscj",        "1");
	kz_uq_dropscj       = register_cvar("kz_uq_dropscj",        "1");
	kz_uq_dropdscj       = register_cvar("kz_uq_dropdscj",        "1");
	kz_uq_dropmscj       = register_cvar("kz_uq_dropmscj",        "1");
	kz_uq_duckbhop       = register_cvar("kz_uq_duckbhop",        "1");
	kz_uq_bhopinduck      = register_cvar("kz_uq_bhopinduck",        "1");
	kz_uq_realldbhop       = register_cvar("kz_uq_realldbhop",        "1");
	kz_uq_upbj      = register_cvar("kz_uq_upbj",        "1");
	kz_uq_upbhopinduck      = register_cvar("kz_uq_upbhopinduck",        "1");
	kz_uq_upsbj       = register_cvar("kz_uq_upsbj",        "1");
	kz_uq_multibhop      = register_cvar("kz_uq_multibhop",        "1");
	kz_uq_dropdcj      = register_cvar("kz_uq_dropdcj",        "1");
	kz_uq_dropmcj     = register_cvar("kz_uq_dropmcj",        "1");
	
	kz_uq_light    = register_cvar("kz_uq_light",      "0");
	kz_uq_connect = register_cvar("kz_uq_connect", "abdehklmn");
	kz_uq_fps = register_cvar("kz_uq_fps", "1");	
	kz_uq_top = register_cvar("kz_uq_save_top", "1");
	kz_uq_maptop = register_cvar("kz_uq_maptop", "1");
	kz_uq_team = register_cvar("kz_uq_team", "0");
	kz_uq_istrafe = register_cvar("kz_uq_istrafes", "0");
	
	max_edge = register_cvar("kz_uq_max_block", "290");
	min_edge = register_cvar("kz_uq_min_block", "100");
	min_pre = register_cvar("kz_uq_min_pre", "60");
	kz_uq_min_other = register_cvar("kz_uq_min_dist_other",            "120");
	kz_uq_extras = register_cvar("kz_uq_save_extras_top", "1");
	max_strafes = register_cvar("kz_uq_max_strafes", "14");
	screenshoot = register_cvar("kz_uq_screenshoot", "0");
	
	sql_stats = register_cvar("kz_uq_sql", "0");
	web_stats = register_cvar("kz_uq_web", "0");
	
	uq_host = register_cvar("kz_uq_host", "127.0.0.1");
	uq_user = register_cvar("kz_uq_user", "root");
	uq_pass = register_cvar("kz_uq_pass", "");
	uq_db = register_cvar("kz_uq_db", "uq_jumpstats");
		
	allow_info = register_cvar("kz_uq_demo_info", "1");
	weapon_top = register_cvar("kz_uq_weapons_top", "1");
	weapon_block_top = register_cvar("kz_uq_block_weapons", "1");
	kz_uq_url = register_cvar("kz_uq_url","http://localhost/uq_jumpstats/index.php?type=lj&from_game=true");
	kz_uq_block_top = register_cvar("kz_uq_block_top", "1");
	
	kz_uq_bug=register_cvar("kz_uq_bug_check", "1");
	kz_uq_noslow=register_cvar("kz_uq_noslowdown", "0");
	
	kz_uq_admins = register_cvar("kz_uq_only_admins", "0");
	kz_uq_script_detection = register_cvar("kz_uq_script_detection", "1");
	kz_uq_update_auth = register_cvar("kz_uq_update_auth", "1");
	kz_uq_script_notify = register_cvar("kz_uq_script_notify", "1");
	kz_uq_script_punishment = register_cvar("kz_uq_script_punishment", "0");
	kz_uq_script_work = register_cvar("kz_uq_script_work", "2");
	
	kz_uq_ban_type = register_cvar("kz_uq_ban_type", "0");
	kz_uq_ban_authid = register_cvar("kz_uq_ban_authid", "0");
	kz_uq_ban_minutes = register_cvar("kz_uq_ban_minutes", "45");
	
	kz_uq_block_chat_show = register_cvar("kz_uq_block_chat_show", "1");
	kz_uq_block_chat_min = register_cvar("kz_uq_block_chat_min", "1");
	
	kz_uq_speed_allteam = register_cvar("kz_uq_speed_allteam", "1");
	
	register_cvar( "uq_jumpstats", VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	
	register_concmd("amx_reset_uqtops","reset_tops",ADMIN_CVAR ,"reset all tops");
	
	register_clcmd( "say /strafe",	"streif_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /strafes",	"streif_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /strafestat",	"streif_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /strafestats",	"streif_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /showpre",	"show_pre" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /duck",	"pre_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /ducks",	"pre_stats" ,         ADMIN_ALL, "- enabled/disables");
	register_clcmd( "say /uqstats",		"cmdljStats",         ADMIN_ALL, "- enabled/disables" );
	register_clcmd( "say /ljstats",		"cmdljStats",         ADMIN_ALL, "- enabled/disables" );
	register_clcmd( "say /stats",		"cmdljStats",         ADMIN_ALL, "- enabled/disables" );
	register_clcmd( "say /heigh",		"heightshow",         ADMIN_ALL, "- enabled/disables" );
	register_clcmd( "say /fall",		"heightshow",         ADMIN_ALL, "- enabled/disables" );
	
	register_clcmd( "say /uqversion",	"cmdVersion",         ADMIN_ALL);
	register_clcmd( "say uqversion",	"cmdVersion",         ADMIN_ALL);
	register_clcmd("say /uqbeam",     "cmdljbeam",         ADMIN_ALL);
	register_clcmd("say /beam",     "cmdljbeam",         ADMIN_ALL);
	register_clcmd("say beam",     "cmdljbeam",         ADMIN_ALL);
	register_clcmd("say /ljbeam",     "cmdljbeam",         ADMIN_ALL);
	register_clcmd("say /speed",     "show_speed",         ADMIN_ALL);
	register_clcmd("say speed",     "show_speed",         ADMIN_ALL);
	register_clcmd("say /colorchat",     "cmdColorChat",         ADMIN_ALL);
	register_clcmd("say colorchat",     "cmdColorChat",         ADMIN_ALL);
	register_clcmd("say /bhopwarn",     "show_early",         ADMIN_ALL);
	register_clcmd("say /multibhop",     "multi_bhop",         ADMIN_ALL);
	register_clcmd("say /duckspre",     "duck_show",         ADMIN_ALL);
	register_clcmd("say /duckpre",     "duck_show",         ADMIN_ALL);
	register_clcmd("say /ljpre",     "lj_show",         ADMIN_ALL);
	register_clcmd("say /prelj",     "lj_show",         ADMIN_ALL);
	register_clcmd("say /uqsound",     "enable_sounds",         ADMIN_ALL);
	register_clcmd("say /uqsounds",     "enable_sounds",         ADMIN_ALL);
	
	register_clcmd("say /failedge",     "ShowedgeFail",         ADMIN_ALL);
	register_clcmd("say /failedg",     "ShowedgeFail",         ADMIN_ALL);
	register_clcmd("say /edgefail",     "ShowedgeFail",         ADMIN_ALL);
	register_clcmd("say /edgfail",     "ShowedgeFail",         ADMIN_ALL);
	register_clcmd("say /edge",     "Showedge",         ADMIN_ALL);
	register_clcmd("say /edg",     "Showedge",         ADMIN_ALL);
	
	register_clcmd("say /joftrainer",     "trainer_jof",         ADMIN_ALL);
	register_clcmd("say joftrainer",     "trainer_jof",         ADMIN_ALL);
	register_clcmd("say /joftr",     "trainer_jof",         ADMIN_ALL);
	register_clcmd("say joftr",     "trainer_jof",         ADMIN_ALL);
	
	register_clcmd("say /speedt",     "speed_type",         ADMIN_ALL);
	register_clcmd("say speedt",     "speed_type",         ADMIN_ALL);
	
	register_clcmd("say /jof",     "show_jof",         ADMIN_ALL);
	register_clcmd("say jof",     "show_jof",         ADMIN_ALL);
	
	register_clcmd("say /jheigh",     "show_jheight",         ADMIN_ALL);
	register_clcmd("say jheigh",     "show_jheight",         ADMIN_ALL);
	
	register_clcmd("say /istrafe",     "ingame_st_stats",         ADMIN_ALL);
	register_clcmd("say istrafe",     "ingame_st_stats",         ADMIN_ALL);
	
	register_clcmd("say /options",     "Option",         ADMIN_ALL);
	register_clcmd("say /ljsmenu",     "Option",         ADMIN_ALL);
	register_clcmd("say /ljsmenu2",     "Option2",         ADMIN_ALL);
	register_clcmd("say /uqmenu",     "Option",         ADMIN_ALL);
	register_clcmd("say /option",     "Option",         ADMIN_ALL);

	register_menucmd(register_menuid("StatsOptionMenu1"),          1023, "OptionMenu1");
	register_menucmd(register_menuid("StatsOptionMenu2"),          1023, "OptionMenu2");
	register_menucmd(register_menuid("StatsOptionMenu3"),          1023, "OptionMenu3");
	
	edgefriction          = get_cvar_pointer("edgefriction");
	mp_footsteps          = get_cvar_pointer("mp_footsteps");
	sv_cheats             = get_cvar_pointer("sv_cheats");
	sv_gravity            = get_cvar_pointer("sv_gravity");
	sv_airaccelerate      = get_cvar_pointer("sv_airaccelerate");
	sv_maxspeed           = get_cvar_pointer("sv_maxspeed");
	sv_stepsize           = get_cvar_pointer("sv_stepsize");
	sv_maxvelocity        = get_cvar_pointer("sv_maxvelocity");
	
	
	register_forward(FM_Touch,           "fwdTouch",           1);
	register_forward( FM_PlayerPreThink,	"fwdPreThink",	0 );
	register_forward( FM_PlayerPostThink,	"fwdPostThink",	0 );
	
	RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1);
	RegisterHam(Ham_Killed, "player", "FwdPlayerDeath", 1);
	RegisterHam(Ham_Touch, "player",	"HamTouch");
	
	register_event("ResetHUD","ResetHUD","b");
	
	
	
	max_players=get_maxplayers()+1;
	
	ent=find_ent_by_class(-1,"func_ladder");
	while( ent > 0 )
	{
		entity_get_vector ( ent, EV_VEC_maxs, ladderxyz[nLadder] );
		entity_get_vector ( ent, EV_VEC_mins, ladderminxyz[nLadder] );
		entity_get_vector ( ent, EV_VEC_size, laddersize[nLadder] );
		entlist[nLadder]=ent;
		
		ent = find_ent_by_class(ent,"func_ladder");
		nLadder++;
	}
	
	get_mapname(mapname, 32);
	
	// Logs
	new logs[64];
	get_localinfo("amxx_logs", logs, 63);
	formatex(logs_path, 127, "%s\uq_jumpstats.txt", logs);
	
	bindOptions();
}

public plugin_natives()
{
	register_native("kz_get_configsdir", "native_kz_get_configsdir", 1);
	
}
public plugin_cfg()
{
	new cvarfiles[100], uqpath[64];
	kz_get_configsdir(uqpath, 63);
	formatex(cvarfiles, 99, "%s/%s", uqpath, KZ_CVARSDIR);
	
	if( file_exists(cvarfiles) )
	{
		server_cmd("exec %s", cvarfiles);
		server_exec();
	}
	
	uq_min_pre=get_pcvar_num(min_pre);
	uq_maxedge=get_pcvar_num(max_edge);
	uq_minedge=get_pcvar_num(min_edge);
	kz_sql=get_pcvar_num(sql_stats);
	web_sql=get_pcvar_num(web_stats);
	rankby = get_pcvar_num(kz_top_rank_by);
	uq_team=get_pcvar_num(kz_uq_team);
	uq_istrafe=get_pcvar_num(kz_uq_istrafe);
	NSTRAFES1=get_pcvar_num(max_strafes);
	stats_x=get_pcvar_float(kz_stats_x);
	stats_y=get_pcvar_float(kz_stats_y);
	strafe_x=get_pcvar_float(kz_strafe_x);
	strafe_y=get_pcvar_float(kz_strafe_y);
	duck_x=get_pcvar_float(kz_duck_x);
	duck_y=get_pcvar_float(kz_duck_y);
	prest_r=get_pcvar_num(kz_prest_r);
	prest_g=get_pcvar_num(kz_prest_g);
	prest_b=get_pcvar_num(kz_prest_b);
	prest_x=get_pcvar_float(kz_prest_x);
	prest_y=get_pcvar_float(kz_prest_y);
	h_prest=get_pcvar_num(hud_pre);
	h_stats=get_pcvar_num(hud_stats);
	h_duck=get_pcvar_num(hud_duck);
	h_streif=get_pcvar_num(hud_streif);
	stats_r=get_pcvar_num(kz_stats_red);
	stats_b=get_pcvar_num(kz_stats_blue);
	stats_g=get_pcvar_num(kz_stats_green);
	f_stats_r=get_pcvar_num(kz_failstats_red);
	f_stats_b=get_pcvar_num(kz_failstats_blue);
	f_stats_g=get_pcvar_num(kz_failstats_green);
	uq_lj=get_pcvar_num(kz_uq_lj);	
	uq_cj=get_pcvar_num(kz_uq_cj);	
	uq_dcj=get_pcvar_num(kz_uq_dcj);	
	uq_mcj=get_pcvar_num(kz_uq_mcj);	
	uq_ladder=get_pcvar_num(kz_uq_ladder);	
	uq_ldbj=get_pcvar_num(kz_uq_ldbj);	
	uq_bj=get_pcvar_num(kz_uq_bj);	
	uq_sbj=get_pcvar_num(kz_uq_sbj);	
	uq_drbj=get_pcvar_num(kz_uq_drbj);	
	uq_drsbj=get_pcvar_num(kz_uq_drsbj);	
	uq_drcj=get_pcvar_num(kz_uq_drcj);	
	uq_wj=get_pcvar_num(kz_uq_wj);
	uq_dscj=get_pcvar_num(kz_uq_dscj);	
	uq_mscj=get_pcvar_num(kz_uq_mscj);
	uq_dropscj=get_pcvar_num(kz_uq_dropscj);
	uq_dropdscj=get_pcvar_num(kz_uq_dropdscj);
	uq_dropmscj=get_pcvar_num(kz_uq_dropmscj);
	uq_duckbhop=get_pcvar_num(kz_uq_duckbhop);
	uq_bhopinduck=get_pcvar_num(kz_uq_bhopinduck);
	uq_realldbhop=get_pcvar_num(kz_uq_realldbhop);
	uq_upbj=get_pcvar_num(kz_uq_upbj);
	uq_upbhopinduck=get_pcvar_num(kz_uq_upbhopinduck);
	uq_upsbj=get_pcvar_num(kz_uq_upsbj);
	uq_multibhop=get_pcvar_num(kz_uq_multibhop);
	uq_dropdcj=get_pcvar_num(kz_uq_dropdcj);
	uq_dropmcj=get_pcvar_num(kz_uq_dropmcj);
	dcj_god_dist=get_pcvar_num(kz_god_dcj);
	dcj_leet_dist=get_pcvar_num(kz_leet_dcj);
	dcj_holy_dist=get_pcvar_num(kz_holy_dcj);
	dcj_pro_dist=get_pcvar_num(kz_pro_dcj);
	dcj_good_dist=get_pcvar_num(kz_good_dcj);
	lj_god_dist=get_pcvar_num(kz_god_lj);
	lj_leet_dist=get_pcvar_num(kz_leet_lj);
	lj_holy_dist=get_pcvar_num(kz_holy_lj);
	lj_pro_dist=get_pcvar_num(kz_pro_lj);
	lj_good_dist=get_pcvar_num(kz_good_lj);
	ladder_god_dist=get_pcvar_num(kz_god_ladder);
	ladder_leet_dist=get_pcvar_num(kz_leet_ladder);
	ladder_holy_dist=get_pcvar_num(kz_holy_ladder);
	ladder_pro_dist=get_pcvar_num(kz_pro_ladder);
	ladder_good_dist=get_pcvar_num(kz_good_ladder);
	wj_god_dist=get_pcvar_num(kz_god_wj);
	wj_leet_dist=get_pcvar_num(kz_leet_wj);
	wj_holy_dist=get_pcvar_num(kz_holy_wj);
	wj_pro_dist=get_pcvar_num(kz_pro_wj);
	wj_good_dist=get_pcvar_num(kz_good_wj);
	bj_god_dist=get_pcvar_num(kz_god_bj);
	bj_leet_dist=get_pcvar_num(kz_leet_bj);
	bj_holy_dist=get_pcvar_num(kz_holy_bj);
	bj_pro_dist=get_pcvar_num(kz_pro_bj);
	bj_good_dist=get_pcvar_num(kz_good_bj);
	cj_god_dist=get_pcvar_num(kz_god_cj);
	cj_leet_dist=get_pcvar_num(kz_leet_cj);
	cj_holy_dist=get_pcvar_num(kz_holy_cj);
	cj_pro_dist=get_pcvar_num(kz_pro_cj);
	cj_good_dist=get_pcvar_num(kz_good_cj);
	dbj_god_dist=get_pcvar_num(kz_god_dbj);
	dbj_leet_dist=get_pcvar_num(kz_leet_dbj);
	dbj_holy_dist=get_pcvar_num(kz_holy_dbj);
	dbj_pro_dist=get_pcvar_num(kz_pro_dbj);
	dbj_good_dist=get_pcvar_num(kz_good_dbj);	
	scj_god_dist=get_pcvar_num(kz_god_scj);
	scj_leet_dist=get_pcvar_num(kz_leet_scj);
	scj_holy_dist=get_pcvar_num(kz_holy_scj);
	scj_pro_dist=get_pcvar_num(kz_pro_scj);
	scj_good_dist=get_pcvar_num(kz_good_scj);		
	dropscj_god_dist=get_pcvar_num(kz_god_dropscj);
	dropscj_leet_dist=get_pcvar_num(kz_leet_dropscj);
	dropscj_holy_dist=get_pcvar_num(kz_holy_dropscj);
	dropscj_pro_dist=get_pcvar_num(kz_pro_dropscj);
	dropscj_good_dist=get_pcvar_num(kz_good_dropscj);
	bhopinduck_god_dist=get_pcvar_num(kz_god_bhopinduck);
	bhopinduck_leet_dist=get_pcvar_num(kz_leet_bhopinduck);
	bhopinduck_holy_dist=get_pcvar_num(kz_holy_bhopinduck);
	bhopinduck_pro_dist=get_pcvar_num(kz_pro_bhopinduck);
	bhopinduck_good_dist=get_pcvar_num(kz_good_bhopinduck);
	upbj_god_dist=get_pcvar_num(kz_god_upbj);
	upbj_leet_dist=get_pcvar_num(kz_leet_upbj);
	upbj_holy_dist=get_pcvar_num(kz_holy_upbj);
	upbj_pro_dist=get_pcvar_num(kz_pro_upbj);
	upbj_good_dist=get_pcvar_num(kz_good_upbj);
	upsbj_god_dist=get_pcvar_num(kz_god_upsbj);
	upsbj_leet_dist=get_pcvar_num(kz_leet_upsbj);
	upsbj_holy_dist=get_pcvar_num(kz_holy_upsbj);
	upsbj_pro_dist=get_pcvar_num(kz_pro_upsbj);
	upsbj_good_dist=get_pcvar_num(kz_good_upsbj);
	real_god_dist=get_pcvar_num(kz_god_real);
	real_leet_dist=get_pcvar_num(kz_leet_real);
	real_holy_dist=get_pcvar_num(kz_holy_real);
	real_pro_dist=get_pcvar_num(kz_pro_real);
	real_good_dist=get_pcvar_num(kz_good_real);
	duckbhop_god_dist=get_pcvar_num(kz_god_duckbhop);
	duckbhop_leet_dist=get_pcvar_num(kz_leet_duckbhop);
	duckbhop_holy_dist=get_pcvar_num(kz_holy_duckbhop);
	duckbhop_pro_dist=get_pcvar_num(kz_pro_duckbhop);
	duckbhop_good_dist=get_pcvar_num(kz_good_duckbhop);
	leg_settings=get_pcvar_num(kz_legal_settings);	
	uq_airaccel=get_pcvar_num( kz_airaccelerate );
	min_distance=get_pcvar_num(kz_min_dcj);
	min_distance_other=get_pcvar_num(kz_uq_min_other);
	max_distance=get_pcvar_num(MAX_DISTANCE);
	uq_sounds=get_pcvar_num(kz_sounds);
	uq_light=get_pcvar_num( kz_uq_light);
	uq_screen=get_pcvar_num(screenshoot);
	uq_info=get_pcvar_num(allow_info);
	uq_fps=get_pcvar_num(kz_uq_fps);
	speed_r=get_pcvar_num(kz_speed_r);
	speed_g=get_pcvar_num(kz_speed_g);
	speed_b=get_pcvar_num(kz_speed_b);
	speed_x=get_pcvar_float(kz_speed_x);
	speed_y=get_pcvar_float(kz_speed_y);
	h_speed=get_pcvar_num(hud_speed);
	kz_top=get_pcvar_num(kz_uq_top);
	kz_extras=get_pcvar_num(kz_uq_extras);
	kz_weapon=get_pcvar_num(weapon_top);
	kz_block_top=get_pcvar_num(kz_uq_block_top);
	kz_map_top=get_pcvar_num(kz_uq_maptop);
	kz_wpn_block_top=get_pcvar_num(weapon_block_top);
	get_pcvar_string(kz_prefix, prefix, 63);
	uq_bug=get_pcvar_num(kz_uq_bug);
	uq_noslow=get_pcvar_num(kz_uq_noslow);
	uq_admins=get_pcvar_num(kz_uq_admins);
	uq_script_detection=get_pcvar_num(kz_uq_script_detection);
	uq_update_auth=get_pcvar_num(kz_uq_update_auth);
	uq_script_notify=get_pcvar_num(kz_uq_script_notify);
	uq_script_punishment=get_pcvar_num(kz_uq_script_punishment);
	uq_script_work=get_pcvar_num(kz_uq_script_work);
	uq_ban_authid=get_pcvar_num(kz_uq_ban_authid);
	uq_ban_type=get_pcvar_num(kz_uq_ban_type);
	uq_ban_minutes=get_pcvar_num(kz_uq_ban_minutes); 
	uq_block_chat_min=get_pcvar_num(kz_uq_block_chat_min); 
	uq_block_chat_show=get_pcvar_num(kz_uq_block_chat_show); 
	uq_speed_allteam=get_pcvar_num(kz_uq_speed_allteam);
	//uq_edgefriction=get_pcvar_num(edgefriction);
	//uq_mp_footsteps=get_pcvar_num(mp_footsteps);
	//uq_sv_cheats=get_pcvar_num(sv_cheats);
	//uq_sv_gravity=get_pcvar_num(sv_gravity);
	//uq_sv_airaccelerate=get_pcvar_num(sv_airaccelerate);
	//uq_sv_maxspeed=get_pcvar_num(sv_maxspeed);
	//uq_sv_stepsize=get_pcvar_num(sv_stepsize);
	//uq_sv_maxvelocity=get_pcvar_num(sv_maxvelocity);
	
	if(!file_exists(cvarfiles))
	{
		kz_make_cvarexec(cvarfiles);
	}
	
	new plugin_id=find_plugin_byfile("uq_jumpstats_tops.amxx");
	new filename[33],plugin_name[33],plugin_author[33],status[33];
	
	if(plugin_id==-1)
	{
		log_amx("Can't find uq_jumpstats_tops.amxx");
		server_print("[uq_jumpstats] Can't find uq_jumpstats_tops.amxx");
	}
	else
	{
		get_plugin(plugin_id,filename,32,plugin_name,32,plugin_ver,32,plugin_author,32,status,32); 
		
		if(!equali(plugin_ver,VERSION))
		{
			set_task(5.0,"Wrong_ver");
		}
	}

	if( leg_settings )
	{
		set_cvar_string("edgefriction", "2");
		set_cvar_string("mp_footsteps", "1");
		set_cvar_string("sv_cheats", "0");
		set_cvar_string("sv_gravity", "800");
		
		if(uq_airaccel==0 || uq_airaccel==10)
			set_cvar_string("sv_airaccelerate", "10");
		else if(uq_airaccel==1 || uq_airaccel==100)
			set_cvar_string("sv_airaccelerate", "100");
		else 
		{
			new str[10];
			num_to_str(uq_airaccel,str,9);
			set_cvar_string("sv_airaccelerate", str);
		}
		
		set_cvar_string("sv_maxspeed", "320");
		set_cvar_string("sv_stepsize", "18");
		set_cvar_string("sv_maxvelocity", "2000");
	}

	new dataDir[64];
	get_datadir(dataDir, 63);
	format(ljsDir, 63, "%s/Topljs", dataDir);
		
	if( !dir_exists(ljsDir) )
		mkdir(ljsDir);
			
	if(kz_sql==1)
	{
		set_task(0.2, "stats_sql");
		set_task(1.0, "save_info_sql");
		JumpPlayers = TrieCreate();
	}
	else if(kz_sql==0)
	{
		JData = TrieCreate();
		JData_Block = TrieCreate();
		
		format(ljsDir_block, 63, "%s/Topljs/block_tops", dataDir);
			
		if( !dir_exists(ljsDir_block) )
			mkdir(ljsDir_block);
			
		for(new i=0;i<NTECHNUM;i++)
		{
			read_tops(Type_List[i],i);
			read_tops_block(Type_List[i],i);
		}
			
		for(new j=0;j<8;j++)
		{
			new mxspd[11];
			num_to_str(weapon_maxspeed(j),mxspd,10);
			
			format(ljsDir_weapon[j], 63, "%s/Top_weapon_speed_%s", ljsDir,mxspd);
			format(ljsDir_block_weapon[j], 63, "%s/Top_weapon_speed_%s", ljsDir_block,mxspd);
			
			if( !dir_exists(ljsDir_weapon[j]) )
				mkdir(ljsDir_weapon[j]);
			if( !dir_exists(ljsDir_block_weapon[j]) )
				mkdir(ljsDir_block_weapon[j]);
				
			for(new i=0;i<NWPNTECHNUM;i++)
			{
				read_tops_weapon(Type_List_weapon[i],i,j);
				read_tops_block_weapon(Type_List_weapon[i],i,j);
			}
			read_tops_block_weapon("hj",9,j);	
		}
	}	
}
public Wrong_ver()
{
	for(new i=1;i<get_maxplayers();i++)
	{
		if(is_user_alive(i) && is_user_connected(i))
			ColorChat(i, BLUE, "^x04Version^x03 uq_jumpstats.amxx^x01(%s)^x04 different from^x03 uq_jumpstats_tops.amxx^x01(%s)",VERSION,plugin_ver);
	}
	set_task(5.0,"Wrong_ver");
}

#include <uq_jumpstats_sql.inc>

public plugin_precache()
{
	gBeam = precache_model( "sprites/zbeam6.spr" );
	precache_sound( "misc/impressive.wav" );
	precache_sound( "misc/perfect.wav" );
	precache_sound( "misc/mod_godlike.wav" );
	precache_sound( "misc/holyshit.wav" );
	precache_sound( "misc/mod_wickedsick.wav" );
	
	
	precache_model( "models/hairt.mdl" );
	heystats = precache_model( "sprites/zbeam6.spr" );
}

stock kz_make_cvarexec(const config[])
{
	new f = fopen(config, "wt");
	new stringscvars[256],s_host[101],s_pass[101],s_user[101],s_db[101];
	new s_x[10],s_y[10];
	
	fprintf(f, "// Config of JumpStats by BorJomi^n");
	fprintf(f, "// Version %s^n",VERSION);
	fprintf(f, "^n");
	
	fprintf(f, "// Players commands^n");
	fprintf(f, "^n");
	fprintf(f, "// say /strafes - on/off statistics Strafes^n"); 
	fprintf(f, "// say /showpre - on/off display prestrafe^n"); 
	fprintf(f, "// say /ducks - on/off statistics ducks for multi cj^n"); 
	fprintf(f, "// say /ljstats - on/off the main statistics^n"); 
	fprintf(f, "// say /uqversion - show version^n"); 
	fprintf(f, "// say /beam - on/off showing the trajectory of the jump^n"); 
	fprintf(f, "// say /speed - on/off display of speed player^n"); 
	fprintf(f, "// say /colorchat - on/off display of color in the chat messages from other players^n"); 
	fprintf(f, "// say /ljsmenu - open the configuration menu^n"); 
	fprintf(f, "// say /ljtop - open TOP10 menu^n");
	fprintf(f, "// say /bhopwarn - on/off show message when you bhop prestrafe is fail^n");
	fprintf(f, "// say /multibhop - on/off show multi bhop pre^n");
	fprintf(f, "// say /duckspre - on/off display prestrafe after each duck^n");
	fprintf(f, "// say /ljpre - on/off display prestrafe for LJ^n");
	fprintf(f, "// say /failedge - on/off display jumpoff wehn failed without bolock^n");
	fprintf(f, "// say /edge - on/off display jumpoff,block,landing^n");
	fprintf(f, "// say /heigh - on/off display heigh^n");
	fprintf(f, "// say /mylj - on/off myljtop menu^n");
	fprintf(f, "// say /wpnlj - on/off weapon top menu^n");
	fprintf(f, "// say /jof - on/off showing Jumpoff when press jump button^n");
	fprintf(f, "// say /joftr - on/off Jumpoff trainer^n");
	fprintf(f, "// say /blocktop - on/off block tops menu^n");
	fprintf(f, "// say /jheigh - on/off showing jump heigh^n");
	fprintf(f, "// say /istrafe - on/off InGame strafe stats^n");
	fprintf(f, "// say /speedt - Big/Small Speed Type^n");
	fprintf(f, "^n");
	
	fprintf(f, "// Admin command^n");
	fprintf(f, "^n");
	fprintf(f, "// amx_reset_uqtops � reset all tops^n");
	fprintf(f, "^n");
	
	fprintf(f, "// Cvars^n");
	fprintf(f, "^n");
	fprintf(f, "// What should work when players connect to the server:^n");
	fprintf(f, "// 	0 = none^n"); 
	fprintf(f, "// 	a = colorchat^n"); 
	fprintf(f, "// 	b = stats^n"); 
	fprintf(f, "// 	c = speed^n"); 
	fprintf(f, "// 	d = showpre^n"); 
	fprintf(f, "// 	e = strafe stats^n"); 
	fprintf(f, "// 	f = beam^n"); 
	fprintf(f, "// 	g = duck stats for mcj^n"); 
	fprintf(f, "// 	h = shows message when your bhop prestrafe is failed^n");
	fprintf(f, "// 	i = show multibhop pre^n");
	fprintf(f, "// 	j = show prestrafe after duck^n");
	fprintf(f, "// 	k = show lj prestrafe^n");
	fprintf(f, "// 	l = show edge^n");
	fprintf(f, "// 	m = show edge when fail (without block)^n");
	fprintf(f, "// 	n = enable sounds^n");
	fprintf(f, "// 	o = enable InGame strafe stats^n");
	
	get_pcvar_string(kz_uq_connect, stringscvars, 255);
	
	fprintf(f, "kz_uq_connect ^"%s^"^n", stringscvars);
	fprintf(f, "^n");
	
	fprintf(f, "// Min distance^n");
	fprintf(f, "kz_uq_min_dist %i^n", min_distance);
	fprintf(f, "^n");
	
	fprintf(f, "// Min distance (Ups bhop, MultiBhop, Real Ladder Bhop, Ducks Bhop, Ladder Jump)^n");
	fprintf(f, "kz_uq_min_dist_other %i^n", min_distance_other);
	fprintf(f, "^n");
	
	fprintf(f, "// Max distance^n");
	fprintf(f, "kz_uq_max_dist %i^n", max_distance);
	fprintf(f, "^n");
	
	fprintf(f, "// Showing info about block in ColorChat messages^n");
	fprintf(f, "kz_uq_block_chat_show %i^n", uq_block_chat_show);
	fprintf(f, "kz_uq_block_chat_min %i - minimum block to show (block more then 0=good,1=pro,2=holy,3=leet,4=god distance cvars)^n", uq_block_chat_min);
	fprintf(f, "^n");
	
	fprintf(f, "// Enable stats for admins only^n");
	fprintf(f, "kz_uq_only_admins %i^n", uq_admins);
	fprintf(f, "^n");
	
	fprintf(f, "// Enable stats for team (0=all,1=T,2=CT)^n");
	fprintf(f, "kz_uq_team %i^n", uq_team);
	fprintf(f, "^n");
	
	fprintf(f, "// Enable cmd /speed for all team^n");
	fprintf(f, "kz_uq_speed_allteam %i^n", uq_speed_allteam);
	fprintf(f, "^n");
	
	fprintf(f, "// Allow highlighting after landing (1 = on, 0 = off; works for holy, leet and god distances)^n");
	fprintf(f, "kz_uq_light %i^n", uq_light);
	fprintf(f, "^n");
	
	fprintf(f, "// Allow sounds (1 = on, 0 = off)^n");
	fprintf(f, "kz_uq_sounds %i^n",uq_sounds);
	fprintf(f, "^n");
	
	fprintf(f, "// Allow doing ScreenShot if Player going in Top (not work with kz_uq_sql <1> and for map top)^n");
	fprintf(f, "kz_uq_screenshoot %i^n",uq_screen);
	fprintf(f, "^n");
	
	fprintf(f, "// Allow showing info about stats when you record demo^n");
	fprintf(f, "kz_uq_demo_info %i^n",uq_info);
	fprintf(f, "^n");

	fprintf(f, "// How work Sql Module (1=SQL module enable, 0=disable)^n");
	fprintf(f, "kz_uq_sql %i^n",kz_sql);
	fprintf(f, "^n");

	fprintf(f, "// Enable/Disable Web Top (1=Enable,0=Disable) - if you want standart tops with sql module, turn of web mod^n");
	fprintf(f, "kz_uq_web %i^n",web_sql);
	fprintf(f, "^n");
	
	get_pcvar_string(uq_host, s_host, 100);
	get_pcvar_string(uq_user, s_user, 100);
	get_pcvar_string(uq_pass, s_pass, 100);
	get_pcvar_string(uq_db, s_db, 100);
	
	fprintf(f, "// Options for Sql Module^n");
	fprintf(f, "kz_uq_host ^"%s^"^n",s_host);
	fprintf(f, "kz_uq_user ^"%s^"^n",s_user);
	fprintf(f, "kz_uq_pass ^"%s^"^n",s_pass);
	fprintf(f, "kz_uq_db ^"%s^"^n",s_db);
	fprintf(f, "// This Option used only in Showing Top(sql), change this if you use another url on you web server^n");
	get_pcvar_string(kz_uq_url, stringscvars, 255);
	fprintf(f, "kz_uq_url ^"%s^"^n",stringscvars);
	fprintf(f, "kz_uq_update_auth %i - Update in DB Steam and Ip^n",uq_update_auth);
	fprintf(f, "^n");
		
	fprintf(f, "// How to save Top10 (2 = steamid, 1 = Ip, 0 = name)^n");
	fprintf(f, "kz_uq_top_by %i^n",rankby);
	fprintf(f, "^n");
	
	fprintf(f, "kz_uq_save_top %i - On/Off TOP10 (1 = on, 0 = off)^n",kz_top);  
	fprintf(f, "kz_uq_maptop %i  - On/Off MapTop (1 = on, 0 = off)^n",kz_map_top);
	fprintf(f, "kz_uq_save_extras_top %i  - On/Off Extra Tops (1 = on, 0 = off)^n",kz_extras);
	fprintf(f, "kz_uq_weapons_top %i  - On/Off Weapon Tops (1 = on, 0 = off)^n",kz_weapon);	
	fprintf(f, "kz_uq_block_top %i  - On/Off Block Tops (1 = on, 0 = off)^n",kz_block_top);	
	fprintf(f, "kz_uq_block_weapons %i  - On/Off Block Tops for other weapons (1 = on, 0 = off)^n",kz_wpn_block_top);	
	fprintf(f, "^n");
	
	fprintf(f, "// Allow check to legal settings (1 = on, 0 = off)^n");
	fprintf(f, "kz_uq_legal_settings %i^n",leg_settings);
	fprintf(f, "kz_uq_fps %i - (1=more than 100 FPS jump does not count, 0=count)^n",uq_fps); 
	fprintf(f, "kz_uq_bug_check %i - Allow checking for bug distance^n",uq_bug);
	fprintf(f, "^n");
	
	fprintf(f, "// Anti script(Beta)^n");
	fprintf(f, "kz_uq_script_detection %i^n",uq_script_detection);
	fprintf(f, "kz_uq_script_work %i - antiscript works if player distance more then (0=good,1=pro,2=holy,3=leet,4=god distance)^n",uq_script_work);
	fprintf(f, "kz_uq_script_notify %i - print messages to all people on server with scripter name^n",uq_script_notify);
	fprintf(f, "kz_uq_script_punishment %i - (0=nothing,1=kick,2=ban)^n",uq_script_punishment);
	fprintf(f, "kz_uq_ban_type %i - (0=standart bans, 1=amxbans)^n",uq_ban_type);
	fprintf(f, "kz_uq_ban_minutes %i - ban time in minutes^n",uq_ban_minutes);
	fprintf(f, "kz_uq_ban_authid %i - (ban by 0=name,1=ip,2=steam)^n",uq_ban_authid);
	fprintf(f, "^n");

	get_pcvar_string(kz_prefix, stringscvars, 255);
	
	fprintf(f, "// The prefix for all messages in chat^n"); 
	fprintf(f, "kz_uq_prefix ^"%s^"^n", stringscvars);
	fprintf(f, "^n");
	
	fprintf(f, "// How to set up a server by value sv_airaccelerate (Varible=xx, but var=0 reserved for 10aa, var=1 for 100aa)^n");
	fprintf(f, "kz_uq_airaccelerate %i^n",uq_airaccel);
	fprintf(f, "^n");
	
	fprintf(f, "// On/Off Showing stats with noslowdown^n");
	fprintf(f, "kz_uq_noslowdown %i^n",uq_noslow);
	fprintf(f, "^n");
	
	fprintf(f, "// Max strafes (if players strafes>Max, stats doesnt shows)^n");
	fprintf(f, "kz_uq_max_strafes %i^n",NSTRAFES1);
	fprintf(f, "^n");

	fprintf(f, "// Allow InGame Strafe Stats (laggy feature)^n");
	fprintf(f, "kz_uq_istrafes %i^n",uq_istrafe);
	fprintf(f, "^n");
	
	fprintf(f, "// Color Hud message statistics when you jump, in the RGB^n");
	fprintf(f, "kz_uq_stats_red %i^n",stats_r);	
	fprintf(f, "kz_uq_stats_green %i^n",stats_g);
	fprintf(f, "kz_uq_stats_blue %i^n",stats_b);
	fprintf(f, "^n");
	
	fprintf(f, "// Color Hud messages Fail statistics when you jump, in the RGB^n");
	fprintf(f, "kz_uq_failstats_red %i^n",f_stats_r);		
	fprintf(f, "kz_uq_failstats_green %i^n",f_stats_g);
	fprintf(f, "kz_uq_failstats_blue %i^n",f_stats_b);
	fprintf(f, "^n");
	
	fprintf(f, "// Color Hud messages prestrafe, in the RGB^n");
	fprintf(f, "kz_uq_prestrafe_red %i^n",prest_r);	
	fprintf(f, "kz_uq_prestrafe_green %i^n",prest_g);
	fprintf(f, "kz_uq_prestrafe_blue %i^n",prest_b);
	fprintf(f, "^n");
	
	fprintf(f, "// Color of speed, in the RGB^n");
	fprintf(f, "kz_uq_speed_red %i^n",speed_r);		
	fprintf(f, "kz_uq_speed_green %i^n",speed_g);
	fprintf(f, "kz_uq_speed_blue %i^n",speed_b);
	fprintf(f, "^n");
	
	fprintf(f, "//Coordinates Hud messages^n");
	fprintf(f, "^n");
	fprintf(f, "//General stats jump^n");
	
	get_pcvar_string(kz_stats_x, s_x, 9);
	get_pcvar_string(kz_stats_y, s_y, 9);
	
	fprintf(f, "kz_uq_stats_x ^"%s^"^n", s_x);
	fprintf(f, "kz_uq_stats_y ^"%s^"^n", s_y);
	fprintf(f, "^n");
	fprintf(f, "//Strafes Stats^n");
	
	get_pcvar_string(kz_strafe_x, s_x, 9);
	get_pcvar_string(kz_strafe_y, s_y, 9);
	
	fprintf(f, "kz_uq_strafe_x ^"%s^"^n", s_x);
	fprintf(f, "kz_uq_strafe_y ^"%s^"^n", s_y);
	fprintf(f, "^n");
	fprintf(f, "//Ducks Stats for Multi dd^n");
	
	get_pcvar_string(kz_duck_x, s_x, 9);
	get_pcvar_string(kz_duck_y, s_y, 9);
	
	fprintf(f, "kz_uq_duck_x ^"%s^"^n", s_x);
	fprintf(f, "kz_uq_duck_y ^"%s^"^n", s_y); 
	fprintf(f, "^n");
	fprintf(f, "//Speed^n");
	
	get_pcvar_string(kz_speed_x, s_x, 9);
	get_pcvar_string(kz_speed_y, s_y, 9);
	
	fprintf(f, "kz_uq_speed_x ^"%s^"^n", s_x);
	fprintf(f, "kz_uq_speed_y ^"%s^"^n", s_y); 
	fprintf(f, "^n");
	fprintf(f, "//Prestrafe^n");
	
	get_pcvar_string(kz_prest_x, s_x, 9);
	get_pcvar_string(kz_prest_y, s_y, 9);
	
	fprintf(f, "kz_uq_prestrafe_x ^"%s^"^n", s_x);
	fprintf(f, "kz_uq_prestrafe_y ^"%s^"^n", s_y); 
	fprintf(f, "^n");
	
	fprintf(f, "// Channel Hud messages of general stats jump^n");
	fprintf(f, "kz_uq_hud_stats %i^n",h_stats);
	fprintf(f, "^n");
	fprintf(f, "// Channel Hud messages of strafes Stats^n");
	fprintf(f, "kz_uq_hud_strafe %i^n",h_streif);
	fprintf(f, "^n");
	fprintf(f, "// Channel Hud messages of ducks Stats for Multi CountJump^n");
	fprintf(f, "kz_uq_hud_duck %i^n",h_duck);
	fprintf(f, "^n");
	fprintf(f, "// Channel Hud messages of speed^n");
	fprintf(f, "kz_uq_hud_speed %i^n",h_speed);
	fprintf(f, "^n");
	fprintf(f, "// Channel Hud messages of prestafe^n");
	fprintf(f, "kz_uq_hud_pre %i^n",h_prest);
	fprintf(f, "^n");
	
	fprintf(f, "// For what technique stats enable^n");
	fprintf(f, "kz_uq_lj %i^n",uq_lj);	
	fprintf(f, "kz_uq_cj %i^n",uq_cj);	
	fprintf(f, "kz_uq_bj %i^n",uq_bj);	
	fprintf(f, "kz_uq_sbj %i^n",uq_sbj);	
	fprintf(f, "kz_uq_wj %i^n",uq_wj);	
	fprintf(f, "kz_uq_dcj %i^n",uq_dcj);	
	fprintf(f, "kz_uq_mcj %i^n",uq_mcj);	
	fprintf(f, "kz_uq_drbj %i^n",uq_drbj);		
	fprintf(f, "kz_uq_drcj %i^n",uq_drcj);	
	fprintf(f, "kz_uq_ladder %i^n",uq_ladder);	
	fprintf(f, "kz_uq_ldbj %i^n",uq_ldbj);	
	fprintf(f, "^n");
	
	fprintf(f, "// Max,Min block to show in edge^n");
	fprintf(f, "kz_uq_max_block %i^n",uq_maxedge);	
	fprintf(f, "kz_uq_min_block %i^n",uq_minedge);	
	fprintf(f, "^n");
	
	fprintf(f, "// Minimum Prestrafe to show^n");
	fprintf(f, "kz_uq_min_pre %i^n",uq_min_pre);		
	fprintf(f, "^n");
	
	fprintf(f, "// For what Extra technique stats enable^n");
	fprintf(f, "kz_uq_scj %i^n",uq_drsbj);
	fprintf(f, "kz_uq_dscj %i^n",uq_dscj);	
	fprintf(f, "kz_uq_mscj %i^n",uq_mscj);	
	fprintf(f, "kz_uq_dropscj %i^n",uq_dropscj);	
	fprintf(f, "kz_uq_dropdscj %i^n",uq_dropdscj);	
	fprintf(f, "kz_uq_dropmscj %i^n",uq_dropmscj);	
	fprintf(f, "kz_uq_duckbhop %i^n",uq_duckbhop);	
	fprintf(f, "kz_uq_bhopinduck %i^n",uq_bhopinduck);	
	fprintf(f, "kz_uq_realldbhop %i^n",uq_realldbhop);	
	fprintf(f, "kz_uq_upbj %i^n",uq_upbj);	
	fprintf(f, "kz_uq_upsbj %i^n",uq_upsbj);	
	fprintf(f, "kz_uq_upbhopinduck %i^n",uq_upbhopinduck);	
	fprintf(f, "kz_uq_multibhop %i^n",uq_multibhop);
	fprintf(f, "kz_uq_dropdcj %i^n",uq_dropdcj);	
	fprintf(f, "kz_uq_dropmcj %i^n",uq_dropmcj);	
	fprintf(f, "^n");
	
	fprintf(f, "// Color for chat messages of jump distances (good = grey, pro = green, holy = blue, leet = red, god = red (with sound godlike for all players))^n");
	fprintf(f, "// LongJump/HighJump^n");
	fprintf(f, "kz_uq_good_lj %i^n",lj_good_dist);	
	fprintf(f, "kz_uq_pro_lj %i^n",lj_pro_dist);
	fprintf(f, "kz_uq_holy_lj %i^n",lj_holy_dist);
	fprintf(f, "kz_uq_leet_lj %i^n",lj_leet_dist);
	fprintf(f, "kz_uq_god_lj %i^n",lj_god_dist);
	fprintf(f, "^n");

	fprintf(f, "// CountJump^n");
	fprintf(f, "kz_uq_good_cj %i^n",cj_good_dist);	
	fprintf(f, "kz_uq_pro_cj %i^n",cj_pro_dist);
	fprintf(f, "kz_uq_holy_cj %i^n",cj_holy_dist);
	fprintf(f, "kz_uq_leet_cj %i^n",cj_leet_dist);
	fprintf(f, "kz_uq_god_cj %i^n",cj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Double CountJump/Multi CountJump^n");
	fprintf(f, "kz_uq_good_dcj %i^n",dcj_good_dist);	
	fprintf(f, "kz_uq_pro_dcj %i^n",dcj_pro_dist);
	fprintf(f, "kz_uq_holy_dcj %i^n",dcj_holy_dist);
	fprintf(f, "kz_uq_leet_dcj %i^n",dcj_leet_dist);
	fprintf(f, "kz_uq_god_dcj %i^n",dcj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// LadderJump^n");
	fprintf(f, "kz_uq_good_ladder %i^n",ladder_good_dist);	
	fprintf(f, "kz_uq_pro_ladder %i^n",ladder_pro_dist);
	fprintf(f, "kz_uq_holy_ladder %i^n",ladder_holy_dist);
	fprintf(f, "kz_uq_leet_ladder %i^n",ladder_leet_dist);
	fprintf(f, "kz_uq_god_ladder %i^n",ladder_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// BhopJump/StandUp BhopJump^n");
	fprintf(f, "kz_uq_good_bj %i^n",bj_good_dist);	
	fprintf(f, "kz_uq_pro_bj %i^n",bj_pro_dist);
	fprintf(f, "kz_uq_holy_bj %i^n",bj_holy_dist);
	fprintf(f, "kz_uq_leet_bj %i^n",bj_leet_dist);
	fprintf(f, "kz_uq_god_bj %i^n",bj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// WeirdJump/Drop CountJump(double,multi)/Ladder BhopJump^n");
	fprintf(f, "kz_uq_good_wj %i^n",wj_good_dist);	
	fprintf(f, "kz_uq_pro_wj %i^n",wj_pro_dist);
	fprintf(f, "kz_uq_holy_wj %i^n",wj_holy_dist);
	fprintf(f, "kz_uq_leet_wj %i^n",wj_leet_dist);
	fprintf(f, "kz_uq_god_wj %i^n",wj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Drop BhopJump^n");
	fprintf(f, "kz_uq_good_dbj %i^n",dbj_good_dist);	
	fprintf(f, "kz_uq_pro_dbj %i^n",dbj_pro_dist);
	fprintf(f, "kz_uq_holy_dbj %i^n",dbj_holy_dist);
	fprintf(f, "kz_uq_leet_dbj %i^n",dbj_leet_dist);
	fprintf(f, "kz_uq_god_dbj %i^n",dbj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// StandUp CountJump (Double or Multi StandUp CountJump=SCJ+10units)(if 100aa all cvar dist +10 units)^n");
	fprintf(f, "kz_uq_good_scj %i^n",scj_good_dist);	
	fprintf(f, "kz_uq_pro_scj %i^n",scj_pro_dist);
	fprintf(f, "kz_uq_holy_scj %i^n",scj_holy_dist);
	fprintf(f, "kz_uq_leet_scj %i^n",scj_leet_dist);
	fprintf(f, "kz_uq_god_scj %i^n",scj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Drop StandUp CountJump(double,multi)^n");
	fprintf(f, "kz_uq_good_dropscj %i^n",dropscj_good_dist);	
	fprintf(f, "kz_uq_pro_dropscj %i^n",dropscj_pro_dist);
	fprintf(f, "kz_uq_holy_dropscj %i^n",dropscj_holy_dist);
	fprintf(f, "kz_uq_leet_dropscj %i^n",dropscj_leet_dist);
	fprintf(f, "kz_uq_god_dropscj %i^n",dropscj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Up Bhop^n");
	fprintf(f, "kz_uq_good_upbj %i^n",upbj_good_dist);	
	fprintf(f, "kz_uq_pro_upbj %i^n",upbj_pro_dist);
	fprintf(f, "kz_uq_holy_upbj %i^n",upbj_holy_dist);
	fprintf(f, "kz_uq_leet_upbj %i^n",upbj_leet_dist);
	fprintf(f, "kz_uq_god_upbj %i^n",upbj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Up StandBhop^n");
	fprintf(f, "kz_uq_good_upsbj %i^n",upsbj_good_dist);	
	fprintf(f, "kz_uq_pro_upsbj %i^n",upsbj_pro_dist);
	fprintf(f, "kz_uq_holy_upsbj %i^n",upsbj_holy_dist);
	fprintf(f, "kz_uq_leet_upsbj %i^n",upsbj_leet_dist);
	fprintf(f, "kz_uq_god_upsbj %i^n",upsbj_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Bhop In Duck(Up Bhop In Duck)^n");
	fprintf(f, "kz_uq_good_bhopinduck %i^n",bhopinduck_good_dist);	
	fprintf(f, "kz_uq_pro_bhopinduck %i^n",bhopinduck_pro_dist);
	fprintf(f, "kz_uq_holy_bhopinduck %i^n",bhopinduck_holy_dist);
	fprintf(f, "kz_uq_leet_bhopinduck %i^n",bhopinduck_leet_dist);
	fprintf(f, "kz_uq_god_bhopinduck %i^n",bhopinduck_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Duck Bhop^n");
	fprintf(f, "kz_uq_good_duckbhop %i^n",duckbhop_good_dist);	
	fprintf(f, "kz_uq_pro_duckbhop %i^n",duckbhop_pro_dist);
	fprintf(f, "kz_uq_holy_duckbhop %i^n",duckbhop_holy_dist);
	fprintf(f, "kz_uq_leet_duckbhop %i^n",duckbhop_leet_dist);
	fprintf(f, "kz_uq_god_duckbhop %i^n",duckbhop_god_dist);
	fprintf(f, "^n");
	
	fprintf(f, "// Real Ladder Bhop^n");
	fprintf(f, "kz_uq_good_realldbhop %i^n",real_good_dist);	
	fprintf(f, "kz_uq_pro_realldbhop %i^n",real_pro_dist);
	fprintf(f, "kz_uq_holy_realldbhop %i^n",real_holy_dist);
	fprintf(f, "kz_uq_leet_realldbhop %i^n",real_leet_dist);
	fprintf(f, "kz_uq_god_realldbhop %i^n",real_god_dist);
	fprintf(f, "^n");
	
	fclose(f);
	
	server_cmd("exec %s", config);
	server_exec();
}
public Log_script(f_frames,cheated_frames,id,Float:log_dist,Float:log_max,Float:log_pre,log_str,log_sync,jump_type_str[],wpn_str[],punishments[],t_str[40*NSTRAFES])
{
	new Date[20];
	get_time("%m/%d/%y %H:%M:%S", Date, 19)	;
	new username[33];
	get_user_name(id, username, 32);
	new userip[16];
	get_user_ip(id, userip, 15, 1);
	new authid[35];
	get_user_authid(id, authid, 34);
	new main_text[512];
	
	write_file(logs_path, "---------------------------------------------------", -1);
	formatex(main_text, 511, "%s |%s |%s |%s |%s |%s ^n", Date,username, authid, userip, "Script",punishments);
	write_file(logs_path, main_text, -1);
	formatex(main_text, 511, "Type: %s ::: Weapon: %s^nDistance: %.03f Maxspeed: %.03f Prestrafe: %.03f Strafes: %d Sync: %d^n",jump_type_str,wpn_str,log_dist,log_max,log_pre,log_str,log_sync);
	write_file(logs_path, main_text, -1);
	formatex(main_text, 511, "Total Frames: %d^nCheated Frames: %d^n",f_frames,cheated_frames);
	write_file(logs_path, main_text, -1);
	
	new strf[40];
	for(new ll=INFO_ONE; (ll <= log_str) && (ll < NSTRAFES);ll++)
	{
		strtok(t_str,strf,40,t_str,40*NSTRAFES,'^n');
		replace(strf,40,"^n","");
		write_file(logs_path, strf, -1);
	}
	write_file(logs_path, "---------------------------------------------------", -1);
	
	if(uq_script_notify)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SCRIPTNOTIFY",prefix,username,jump_type_str);
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_SCRIPTNOTIFY",prefix,username,jump_type_str);
		Color_Chat_Lang(id,GREY,"%L",LANG_SERVER,"UQSTATS_SCRIPTNOTIFY",prefix,username,jump_type_str);
	}
}
public krasnota(id)
{                
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
		write_short(1<<10);
		write_short(1<<10);
		write_short(0x0000);
		write_byte(255);
		write_byte(0);
		write_byte(0);
		write_byte(110);
		message_end();
}

public sineva(id)
{                
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id);
		write_short(1<<10);
		write_short(1<<10);
		write_short(0x0000);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		write_byte(110);
		message_end();
}

public tskFps(id)
{
	if( leg_settings)
	{
		id-=434490;
		client_cmd(id, "developer 0;fps_max 99.5;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400");
	}
}
public server_frame()
{
	if( leg_settings )
	{
		if( get_pcvar_num(edgefriction) != 2 )
			set_pcvar_num(edgefriction, 2);
		
		if( get_pcvar_num(mp_footsteps) != 1 )
			set_pcvar_num(mp_footsteps, 1);
		
		if( get_pcvar_num(sv_cheats) != 0 )
			set_pcvar_num(sv_cheats, 0);
		
		if( get_pcvar_num(sv_gravity)!= 800 )
			set_pcvar_num(sv_gravity, 800);
		
		if((uq_airaccel==0 || uq_airaccel==10) && get_pcvar_num(sv_airaccelerate) != 10 )
			set_pcvar_num(sv_airaccelerate, 10);
		else if((uq_airaccel==1 || uq_airaccel==100) && get_pcvar_num(sv_airaccelerate) != 100 )
			set_pcvar_num(sv_airaccelerate, 100);
		else if(get_pcvar_num(sv_airaccelerate) != uq_airaccel && uq_airaccel!=0 && uq_airaccel!=1)
			set_pcvar_num(sv_airaccelerate, uq_airaccel);
		
		if( get_pcvar_num(sv_maxspeed) != 320 )
			set_pcvar_num(sv_maxspeed, 320);
		
		if( get_pcvar_num(sv_stepsize) != 18 )
			set_pcvar_num(sv_stepsize, 18);
		
		if( get_pcvar_num(sv_maxvelocity) != 2000 )
			set_pcvar_num(sv_maxvelocity, 2000);
	}
}
public client_putinserver(id)
{
	if(speedon[id] && !is_user_hltv(id) && !is_user_bot(id))// && is_user_alive(id) && is_user_bot(id) && is_user_hltv())
	{
		set_task(0.1, "DoSpeed", id+212299, "", 0, "b", 0);
	}
	
	get_user_name(id, g_playername[id], 63);
	get_user_ip(id, g_playerip[id], 15, 1);
	get_user_authid(id, g_playersteam[id], 35);

	if(kz_sql == 1)
	{
		player_load_info(id);
	}
	
	if(is_user_admin(id))
	{
		player_admin[id]=true;
	}
}
public Dojof(taskid)
{
	taskid-=212398;
	
	static alive, spectatedplayer;
	alive = g_alive[taskid];
	spectatedplayer = get_spectated_player(taskid);
	
	if( (alive || spectatedplayer > 0))
	{
		new show_id;
		
		if( alive )
		{
			show_id=taskid;
		}
		else
		{
			show_id=spectatedplayer;
		}
		
		if(jof[show_id]!=0.0)
		{	
			if(jof[show_id]>5.0)
			{
				set_hudmessage(255, 255, 255, -1.0, 0.6, 0, 0.0, 0.7, 0.0, 0.0, h_speed);
			}
			else
			{
				set_hudmessage(255, 0, 0, -1.0, 0.6, 0, 0.0, 0.7, 0.0, 0.0, h_speed);
			}
			show_hudmessage(taskid,"%L",LANG_SERVER,"UQSTATS_JOF", jof[show_id]);
		}
	}
}


public DoSpeed(taskid)
{
	taskid-=212299;
	
	static alive, spectatedplayer;
	alive = g_alive[taskid];
	spectatedplayer = get_spectated_player(taskid);
	
	if( (alive || spectatedplayer > 0))
	{
		new show_id;
		
		if( alive )
		{
			show_id=taskid;
		}
		else
		{
			show_id=spectatedplayer;
		}
		
		new Float:velocity[3];
		pev(show_id, pev_velocity, velocity);
			
		if( velocity[2] != 0 )
			velocity[2]-=velocity[2];
					
		new Float:speedy = vector_length(velocity);
		
		if(speedtype[taskid])
		{
			set_dhudmessage(speed_r, speed_g, speed_b, speed_x, speed_y, 0, 0.0, 0.1, 0.0, 0.0);
			show_dhudmessage(taskid, "%L",LANG_SERVER,"UQSTATS_SPEEDSHOW", floatround(speedy, floatround_floor));
		}
		else
		{
			set_hudmessage(speed_r, speed_g, speed_b, speed_x, speed_y, 0, 0.0, 0.2, 0.0, 0.0, h_speed);
			show_hudmessage(taskid, "%L",LANG_SERVER,"UQSTATS_SPEEDSHOW", floatround(speedy, floatround_floor));		
		}
	}
}
public wait(id)
{
	id-=3313;
	waits[id]=1;

}

public wait1(id)
{
	id-=3214;
	waits1[id]=1;

}

public client_command(id)
{
	static command[32];
	read_argv( 0, command, 31 );

	static const forbidden[][] = {
		"tele", "tp", "gocheck", "gc", "stuck", "unstuck", "start", "reset", "restart",
		"spawn", "respawn"
	};
	if(uq_info)
	{
		if(record_start[id]==0 && equali( command, "fullupdate" ))
		{
			record_start[id]=1;
		}
		else if(record_start[id]==1 && equali( command, "specmode" ))
		{
			set_hudmessage(255, 255, 255, 0.72, 0.0, 0, 6.0, 1.0);
			show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_INFOSTS",VERSION);
			
			record_start[id]=0;
		}
	}
	
	if( equali( command, "say" ) )
	{
		read_args( command, 31 );
		remove_quotes( command );
	}
	
	if( equali( command, "+hook" ) )
	{
		JumpReset(id,0);
		donehook[id]=true;
		hookcheck[id]=false;
	}
	else if( command[0] == '/' || command[0] == '.' )
	{
		copy( command, 31, command[1] );
		
		for( new i ; i < sizeof( forbidden ) ; i++ )
		{
			if( equali( command, forbidden[i] ) )
			{
				JumpReset(id,1);
				break;
			}
		}
	}
}
public remove_beam_ent(id)
{
	for(new i=0;i<ent_count[id];i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(99);
		write_short(beam_entity[id][i]);
		message_end();
		
		remove_entity(beam_entity[id][i]);
	}
	ent_count[id]=0;
}
public epta(id,Float:or[3],direct_strafe,l_lost[NSTRAFES][NVAR],full,ducked,str_num,strafe_frame1[NSTRAFES],strafe_frame2[NSTRAFES],strafe_lost[NSTRAFES])
{	
	new Float:os_start,Float:temp_or[3],direct[2];
	
	switch(direct_strafe)
	{
		case 1:
		{
			temp_or[0]=or[0];
			temp_or[1]=or[1]+48.0;
			
			if(ducked)
			{
				temp_or[2]=or[2]+16+18;
			}
			else temp_or[2]=or[2]+18;
		}
		case 2:
		{
			temp_or[0]=or[0];
			temp_or[1]=or[1]-48.0;
			
			if(ducked)
			{
				temp_or[2]=or[2]+16+18;
			}
			else temp_or[2]=or[2]+18;
			
			direct[1]=1;
		}
		case 3:
		{
			temp_or[0]=or[1];
			temp_or[1]=or[0]+48.0;
			
			if(ducked)
			{
				temp_or[2]=or[2]+16+18;
			}
			else temp_or[2]=or[2]+18;
			
			direct[0]=1;
			direct[1]=1;
		}
		case 4:
		{
			temp_or[0]=or[1];
			temp_or[1]=or[0]-48.0;
			
			if(ducked)
			{
				temp_or[2]=or[2]+16+18;
			}
			else temp_or[2]=or[2]+18;
			
			direct[0]=1;
		}
	}
	
	os_start=temp_or[0]-(full/2);

	if(direct[1])
	{
		new Float:temp_start=os_start+full;
			
		beam_entity[id][ent_count[id]] = create_entity("info_target");
		
		//entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
		entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
		
		new Float:ent_or[3];
		if(direct[0])
		{
			ent_or[0]=temp_or[1];
			ent_or[1]=temp_start;
		}
		else 
		{
			ent_or[0]=temp_start;
			ent_or[1]=temp_or[1];
		}
		ent_or[2]=temp_or[2];
		
		entity_set_origin(beam_entity[id][ent_count[id]], ent_or);
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
		
		write_byte(TE_BEAMENTPOINT);
		write_short(beam_entity[id][ent_count[id]]);
	
///////////////////////////////////////////	
		if(direct[0])
		{
			write_coord(floatround(temp_or[1]));
			write_coord(floatround(temp_start-full));
		}
		else 
		{
			write_coord(floatround(temp_start-full));
			write_coord(floatround(temp_or[1]));
		}
		write_coord(floatround(temp_or[2]));
///////////////////////////////////////////	
		write_short(heystats);
		write_byte(0);
		write_byte(5);
		write_byte(showtime_st_stats[id]);
		write_byte(1);
		write_byte(0);
			
		
		write_byte(0);
		write_byte(0);
		write_byte(255);
	
		write_byte(150);
		write_byte(1);
		message_end();
		
		ent_count[id]++;
		
		for(new i=0;i<2;i++)
		{
			beam_entity[id][ent_count[id]] = create_entity("info_target");
			
			//entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
			entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
			
			new Float:ent_org[3];
			if(direct[0])
			{
				ent_org[0]=temp_or[1];
				
				if(i==1)
					ent_org[1]=temp_start-full;
				else
					ent_org[1]=temp_start;
			}
			else 
			{
				if(i==1)
					ent_org[0]=temp_start-full;
				else
					ent_org[0]=temp_start;
					
				ent_org[1]=temp_or[1];
			}
			ent_org[2]=temp_or[2]-10.0;
			
			entity_set_origin(beam_entity[id][ent_count[id]], ent_org);
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
			
			write_byte(TE_BEAMENTPOINT);
			write_short(beam_entity[id][ent_count[id]]);
			
	///////////////////////////////////////////	
			if(direct[0])
			{
				write_coord(floatround(temp_or[1]));
				
				if(i==1)
					write_coord(floatround(temp_start-full));
				else
					write_coord(floatround(temp_start));
			}
			else 
			{
				if(i==1)
					write_coord(floatround(temp_start-full));
				else
					write_coord(floatround(temp_start));
					
				write_coord(floatround(temp_or[1]));
			}
			write_coord(floatround(temp_or[2]+10.0));
	///////////////////////////////////////////	
			write_short(heystats);
			write_byte(0);
			write_byte(5);
			write_byte(showtime_st_stats[id]);
			write_byte(5);
			write_byte(0);
				
			
			write_byte(0);
			write_byte(0);
			write_byte(255);
		
			write_byte(150);
			write_byte(1);
			message_end();
			
			ent_count[id]++;
		}
		
		for(new i=1;i<=str_num;i++)
		{
			new Float:st_start,Float:st_finish;
			
			st_finish=temp_start-strafe_lost[i]-strafe_frame1[i]-strafe_frame2[i];
			st_start=temp_start-strafe_lost[i];
			
			for(new Float:j=st_start,count_l=0;j>st_finish;j=j-1.0)
			{
				beam_entity[id][ent_count[id]] = create_entity("info_target");
		
				//entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
				entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
				
				new Float:ent_org[3];
				if(direct[0])
				{
					ent_org[0]=temp_or[1];
					ent_org[1]=j;
				}
				else 
				{
					ent_org[0]=j;
					ent_org[1]=temp_or[1];
				}
				
				if(i%2!=0)
					ent_org[2]=temp_or[2];
				else 
					ent_org[2]=temp_or[2]-4.0;
				
				entity_set_origin(beam_entity[id][ent_count[id]], ent_org);
				
				message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
				
				write_byte(TE_BEAMENTPOINT);
				write_short(beam_entity[id][ent_count[id]]);
				
		///////////////////////////////////////////	
				if(direct[0])
				{
					write_coord(floatround(temp_or[1]));
					write_coord(floatround(j));
				}
				else 
				{
					write_coord(floatround(j));
					write_coord(floatround(temp_or[1]));
				}
				
				if(i%2!=0)
					write_coord(floatround(temp_or[2]+4.0));
				else 
					write_coord(floatround(temp_or[2]));
		///////////////////////////////////////////	
				write_short(heystats);
				write_byte(0);
				write_byte(5);
				write_byte(showtime_st_stats[id]);
				write_byte(5);
				write_byte(0);
					
				if(l_lost[i][count_l])
				{
					write_byte(255);
					write_byte(0);
					write_byte(0);
					line_lost[id][i][count_l]=0;
				}
				else
				{
					write_byte(0);
					write_byte(255);
					write_byte(0);
				}
				
				write_byte(200);
				write_byte(1);
				message_end();
				count_l++;
				ent_count[id]++;
			}
			temp_start=st_finish;
			
		}
	}
	else
	{
		new Float:temp_start=os_start;
		
		beam_entity[id][ent_count[id]] = create_entity("info_target");
		
	//	entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
		entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
		
		new Float:ent_or[3];
		if(direct[0])
		{
			ent_or[0]=temp_or[1];
			ent_or[1]=temp_start;
		}
		else 
		{
			ent_or[0]=temp_start;
			ent_or[1]=temp_or[1];
		}
		ent_or[2]=temp_or[2];
		
		entity_set_origin(beam_entity[id][ent_count[id]], ent_or);
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
		
		write_byte(TE_BEAMENTPOINT);
		write_short(beam_entity[id][ent_count[id]]);
		
///////////////////////////////////////////	
		if(direct[0])
		{
			write_coord(floatround(temp_or[1]));
			write_coord(floatround(temp_start+full));
		}
		else 
		{
			write_coord(floatround(temp_start+full));
			write_coord(floatround(temp_or[1]));
		}
		write_coord(floatround(temp_or[2]));
///////////////////////////////////////////	
		write_short(heystats);
		write_byte(0);
		write_byte(5);
		write_byte(showtime_st_stats[id]);
		write_byte(1);
		write_byte(0);
			
		
		write_byte(0);
		write_byte(0);
		write_byte(255);
	
		write_byte(150);
		write_byte(1);
		message_end();
		
		ent_count[id]++;
		
		for(new i=0;i<2;i++)
		{
			beam_entity[id][ent_count[id]] = create_entity("info_target");
		
			//entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
			entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
			
			new Float:ent_org[3];
			if(direct[0])
			{
				ent_org[0]=temp_or[1];
				
				if(i==1)
					ent_org[1]=temp_start+full;
				else
					ent_org[1]=temp_start;
			}
			else 
			{
				if(i==1)
					ent_org[0]=temp_start+full;
				else
					ent_org[0]=temp_start;
					
				ent_org[1]=temp_or[1];
			}
			ent_org[2]=temp_or[2]-10.0;
			
			entity_set_origin(beam_entity[id][ent_count[id]], ent_org);
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
			
			write_byte(TE_BEAMENTPOINT);
			write_short(beam_entity[id][ent_count[id]]);
	///////////////////////////////////////////	
			if(direct[0])
			{
				write_coord(floatround(temp_or[1]));
				
				if(i==1)
					write_coord(floatround(temp_start+full));
				else
					write_coord(floatround(temp_start));
			}
			else 
			{
				if(i==1)
					write_coord(floatround(temp_start+full));
				else
					write_coord(floatround(temp_start));
					
				write_coord(floatround(temp_or[1]));
			}
			write_coord(floatround(temp_or[2]+10.0));
	///////////////////////////////////////////	
			write_short(heystats);
			write_byte(0);
			write_byte(5);
			write_byte(showtime_st_stats[id]);
			write_byte(5);
			write_byte(0);
				
			
			write_byte(0);
			write_byte(0);
			write_byte(255);
		
			write_byte(150);
			write_byte(1);
			message_end();
			
			ent_count[id]++;
		}
		
		for(new i=1;i<=str_num;i++)
		{
			new Float:st_start,Float:st_finish;
			
			st_finish=temp_start+strafe_lost[i]+strafe_frame1[i]+strafe_frame2[i];
			st_start=temp_start+strafe_lost[i];
			//ColorChat(id,RED,"start=%f tempstart=%f st_start=%f st_finish=%f",os_start,temp_start, st_start,st_finish);
			
			for(new Float:j=st_start,count_l=0;j<st_finish;j++)
			{
				beam_entity[id][ent_count[id]] = create_entity("info_target");
		
			//	entity_set_int(beam_entity[id][ent_count[id]], EV_INT_solid, SOLID_NOT);
				entity_set_model(beam_entity[id][ent_count[id]], "models/hairt.mdl");
				
				new Float:ent_org[3];
				if(direct[0])
				{
					ent_org[0]=temp_or[1];
					ent_org[1]=j;
				}
				else 
				{
					ent_org[0]=j;
					ent_org[1]=temp_or[1];
				}
				
				if(i%2!=0)
					ent_org[2]=temp_or[2];
				else 
					ent_org[2]=temp_or[2]-4.0;
				
				entity_set_origin(beam_entity[id][ent_count[id]], ent_org);
				
				message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
				
				write_byte(TE_BEAMENTPOINT);
				write_short(beam_entity[id][ent_count[id]]);

		///////////////////////////////////////////	
				if(direct[0])
				{
					write_coord(floatround(temp_or[1]));
					write_coord(floatround(j));
				}
				else 
				{
					write_coord(floatround(j));
					write_coord(floatround(temp_or[1]));
				}
				
				if(i%2!=0)
					write_coord(floatround(temp_or[2]+4.0));
				else 
					write_coord(floatround(temp_or[2]));
		///////////////////////////////////////////	
				write_short(heystats);
				write_byte(0);
				write_byte(5);
				write_byte(showtime_st_stats[id]);
				write_byte(5);
				write_byte(0);
					
				if(l_lost[i][count_l])
				{
					write_byte(255);
					write_byte(0);
					write_byte(0);
					line_lost[id][i][count_l]=0;
				}
				else
				{
					write_byte(0);
					write_byte(255);
					write_byte(0);
				}
				
				write_byte(200);
				write_byte(1);
				message_end();
				count_l++;
				ent_count[id]++;
			}
			temp_start=st_finish;
		}
	}
}


public fwdPreThink( id )
{
	if(g_userConnected[id]==true && g_pBot[id]==false)
	{	
		if(uq_admins==1 && !player_admin[id])
		{
			return FMRES_IGNORED;
		}
		else
		{
			new tmpTeam[33],dead_flag;	
			get_user_team(id,tmpTeam,32);
			dead_flag=pev(id, pev_deadflag);
			
			if(equali(tmpTeam,"SPECTATOR") && g_alive[id])
			{
				g_alive[id]=false;
				
				if( task_exists(id, 0) )
					remove_task(id, 0);
					
				if( task_exists(id+434490, 0) )
					remove_task(id+434490, 0);
					
				if( task_exists(id, 0) )
					remove_task(id, 0);
				
				if( task_exists(id+89012, 0) )
					remove_task(id+89012, 0);
				
				if( task_exists(id+3313, 0) )
					remove_task(id+3313, 0);
				
				if( task_exists(id+3214, 0) )
					remove_task(id+3214, 0);
					
				if( task_exists(id+15237, 0) )
					remove_task(id+15237, 0);
				
				if( task_exists(id+212398, 0) )
					remove_task(id+212398, 0);
			}
			else if(equali(tmpTeam,"TERRORIST") || equali(tmpTeam,"CT"))
			{
				if(dead_flag==2 && g_alive[id])
				{
					g_alive[id]=false;
					
					if( task_exists(id, 0) )
						remove_task(id, 0);
						
					if( task_exists(id+434490, 0) )
						remove_task(id+434490, 0);
						
					if( task_exists(id, 0) )
						remove_task(id, 0);
					
					if( task_exists(id+89012, 0) )
						remove_task(id+89012, 0);
					
					if( task_exists(id+3313, 0) )
						remove_task(id+3313, 0);
					
					if( task_exists(id+3214, 0) )
						remove_task(id+3214, 0);
						
					if( task_exists(id+15237, 0) )
						remove_task(id+15237, 0);
					
					if( task_exists(id+212398, 0) )
						remove_task(id+212398, 0);
				}
				else if(dead_flag==0 && g_alive[id]==false)
				{
					g_alive[id]=true;
				}
			}
			
			
			
			if(uq_team==0)
			{
				team[id]=0;
			}
			else if(equali(tmpTeam,"TERRORIST"))
			{
				team[id]=1;
			}
			else if(equali(tmpTeam,"CT"))
			{
				team[id]=2;
			}
			else
			{
				team[id]=uq_team;
			}
			
			if( g_alive[id] && team[id]==uq_team)
			{
				static bool:failed_ducking[33];
				static bool:first_frame[33];
				static Float:duckoff_time[33];
				static Float:duckoff_origin[33][3], Float:pre_jumpoff_origin[33][3];
				static Float:jumpoff_foot_height[33];	
				static Float:prest[33],Float:prest1[33],Float:jumpoff_origin[33][3],Float:failed_velocity[33][3],Float:failed_origin[33][3];
				static Float:frame_origin[33][2][3], Float:frame_velocity[33][2][3], Float:jumpoff_time[33], Float:last_land_time[33];
				
				new entlist1[1];
				
				weapSpeedOld[id] = weapSpeed[id];
				
				if( g_reset[id] ==true)
				{
					angles_arry[id]=0;
					dd_sync[id]=0;
					g_reset[id]	= false;
					g_Jumped[id]	= false;
					cjjump[id] =false;
					in_air[id]	= false;
					in_duck[id]	= false;
					in_bhop[id]	= false;
					ducks[id]=0;
					first_duck_z[id]=0.0;
					backwards[id]=false;
					dropaem[id]=false;
					failed_jump[id] = false;
					prest[id]=0.0;
					bug_true[id]=false;
					detecthj[id]=0;
					edgedone[id]=false;
					jumpblock[id]=1000;
					schetchik[id]=0;
					CjafterJump[id]=0;
					upBhop[id]=false;
					old_type_dropbj[id]=Type_Null;
					first_surf[id]=false;
					surf[id]=0.0;
					ddbeforwj[id]=false;
					duckstring[id]=false;
					notjump[id]=false;
					frames_gained_speed[id] = 0;
					frames[id]	= 0;
					strafe_num[id] = 0;
					ladderjump[id]=false;
					started_multicj_pre[id]	= false;
					started_cj_pre[id]		= false;
					jumpoffirst[id]=false;
					jump_type[id]	= Type_None;
					gBeam_count[id] = 0;
					edgedist[id]=0.0;
					oldjump_height[id]=0.0;
					jheight[id]=0.0;
					duckbhop_bug_pre[id]=false;
					FullJumpFrames[id]=0;
					direct_for_strafe[id]=0;
					ddstandcj[id]=false;
					
					for( new i = 0; i < 100; i++ )
					{
						gBeam_points[id][i][0]	= 0.0;
						gBeam_points[id][i][1]	= 0.0;
						gBeam_points[id][i][2]	= 0.0;
						gBeam_duck[id][i]	= false;
						gBeam_button[id][i]=false;
						
					}
					Checkframes[id]=false;
					for(new i=0;i<NSTRAFES;i++)
					{
						type_button_what[id][i]=0;
						if(uq_istrafe)
							lost_frame_count[id][i]=0;						
					}
					
					if(uq_istrafe)
					{
						for(new i=0;i<=line_erase_strnum[id];i++)
						{
							for( new j = 0; j <= line_erase[id][i]; j++ )
							{
								if(i<NSTRAFES && j<NVAR)
									line_lost[id][i][j]=0;
							}
						}
					}
				}
				
				static button, oldbuttons, flags;
				pev(id, pev_maxspeed, weapSpeed[id]);
				pev(id, pev_origin, origin);
				button = pev(id, pev_button );
				flags = pev(id, pev_flags );
				oldbuttons = pev( id, pev_oldbuttons );
				
				static Float:fGravity,Pmaxspeed;
				pev(id, pev_gravity, fGravity);
				Pmaxspeed=pev( id, pev_maxspeed );
				new Float:velocity[3];
				pev(id, pev_velocity, velocity);
				movetype[id] = pev(id, pev_movetype);
				
				if( flags&FL_ONGROUND && flags&FL_INWATER )  
						velocity[2] = 0.0;
				if( velocity[2] != 0 )
					velocity[2]-=velocity[2];
					
				speed[id] = vector_length(velocity);	
				
				new is_spec_user[33];
				for( new i = INFO_ONE; i < max_players; i++ )
				{
					is_spec_user[i]=is_user_spectating_player(i, id);
				}
				if(strafe_num[id]>NSTRAFES1)
				{
					g_reset[id]=true;
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{
							set_hudmessage( 255, 255, 255, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
							show_hudmessage(i,"%L",LANG_SERVER,"UQSTATS_STR1",NSTRAFES1,strafe_num[id]);	
						}
					}
					return FMRES_IGNORED;
				}
				
				
				if((button&IN_RIGHT || button&IN_LEFT) && !(flags&FL_ONGROUND))
				{
					for(new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{
							client_print(i,print_center,"%L",LANG_SERVER,"UQSTATS_STR2");
							JumpReset(id,28);
							return FMRES_IGNORED;
						}
					}
				}
				new airace,aircj;
				if(uq_airaccel<=10 && uq_airaccel!=1)
				{
					if(uq_airaccel==0)
						airace=10;
					else
						airace=uq_airaccel;
						
					aircj=0;
					formatex(airacel[id],32,"");
				}
				else
				{
					if(uq_airaccel==1)
					{
						airace=100;
						formatex(airacel[id],32,"(100aa)");
					}
					else
					{
						airace=uq_airaccel;
						formatex(airacel[id],32,"(%daa)",uq_airaccel);
					}
					aircj=10;
				}
				
				new spd;
				if(equali(mapname,"slide_gs_longjumps") || equali(mapname,"b2j_slide_longjumps"))
				{
					spd=1400;
				}
				else spd=450;
				
				if(speed[id]> spd || weapSpeedOld[id] != weapSpeed[id])
				{
					if(weapSpeedOld[id] != weapSpeed[id])
					{
						
						changetime[id]=get_gametime();
					}
					JumpReset(id,29);
					return FMRES_IGNORED;
				}
				
				if(leg_settings==1 && (get_pcvar_num(edgefriction) != 2 || fGravity != 1.0 || get_pcvar_num(mp_footsteps) != 1
					|| get_pcvar_num(sv_cheats) != 0
					|| get_pcvar_num(sv_gravity) != 800
					|| get_pcvar_num(sv_airaccelerate) != airace
					|| get_pcvar_num(sv_maxspeed) != 320
					|| get_pcvar_num(sv_stepsize) != 18
					|| get_pcvar_num(sv_maxvelocity) != 2000
					|| pev(id, pev_waterlevel) >= 2 ))
					{
						JumpReset(id,99);
						return FMRES_IGNORED;
					}
			
				if(!(button&IN_MOVELEFT)
				&& oldbuttons&IN_MOVELEFT)
				{
					preessbutton[id]=false;
					button_what[id]=0;
				}
				else if(oldbuttons&IN_MOVERIGHT
				&& !(button&IN_MOVERIGHT))
				{
					button_what[id]=0;
					preessbutton[id]=false;
				}
				else if(oldbuttons&IN_BACK
				&& !(button&IN_BACK))
				{
					preessbutton[id]=false;
					button_what[id]=0;
				}
				else if(oldbuttons&IN_FORWARD
				&& !(button&IN_FORWARD))
				{
					preessbutton[id]=false;
					button_what[id]=0;
				}
					
				if( !(flags&FL_ONGROUND) )
				{
					last_land_time[id] = get_gametime();
					jof[id]=0.0;
				}
					
				
				if(bhopaem[id]==true && !(flags&FL_ONGROUND) && movetype[id] != MOVETYPE_FLY)
				{
					bhopaemtime[id]=get_gametime();
				}
				else if(bhopaem[id]==true && flags&FL_ONGROUND && get_gametime()-bhopaemtime[id]>0.1 && movetype[id] != MOVETYPE_FLY)
				{
			
					bhopaem[id]=false;
				}
				
				if(nextbhop[id]==true && flags&FL_ONGROUND && first_ground_bhopaem[id]==false)
				{
					first_ground_bhopaem[id]=true;
					ground_bhopaem_time[id]=get_gametime();
				}
				else if(nextbhop[id]==true && !(flags&FL_ONGROUND) && first_ground_bhopaem[id]==true && movetype[id] != MOVETYPE_FLY)
				{
					first_ground_bhopaem[id]=false;
				}
				
				if(nextbhop[id]==true && flags&FL_ONGROUND && first_ground_bhopaem[id]==true && (get_gametime()-ground_bhopaem_time[id]>0.1) && movetype[id] != MOVETYPE_FLY)
				{
					first_ground_bhopaem[id]=false;
					bhopaem[id]=false;
					nextbhop[id]=false;
				}
				
				if(nextbhop[id]==true && !(flags&FL_ONGROUND) && movetype[id] != MOVETYPE_FLY)
				{
					nextbhoptime[id]=get_gametime();
				}
				if(nextbhop[id]==true && flags&FL_ONGROUND && get_gametime()-nextbhoptime[id]>0.1 && movetype[id] != MOVETYPE_FLY)
				{
					nextbhop[id]=false;
				}
				if(flags & FL_ONGROUND && h_jumped[id]==false && movetype[id] != MOVETYPE_FLY)
				{
					heightoff_origin[id]=0.0;
				}
				
				if(!g_Jumped[id] && flags & FL_ONGROUND && button&IN_BACK && backwards[id]==false)
				{
					backwards[id]=true;
				}
				else if(!g_Jumped[id] && flags & FL_ONGROUND && button&IN_FORWARD && backwards[id])
				{
					backwards[id]=false;
				}
				
				if(flags & FL_ONGROUND && button&IN_JUMP && !(oldbuttons&IN_JUMP) && movetype[id] != MOVETYPE_FLY)
				{
					if(is_user_ducking(id))
					{
						heightoff_origin[id]=origin[2]+18;
					}
					else heightoff_origin[id]=origin[2];
					
					h_jumped[id]=true;
				}
				else if(flags & FL_ONGROUND && h_jumped[id] && movetype[id] != MOVETYPE_FLY)
				{
					new Float:heightland_origin;
					if(is_user_ducking(id))
					{
						heightland_origin=origin[2]+18;
					}
					else heightland_origin=origin[2];
					
					
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{	
							if(height_show[i]==true )
							{
								if(heightland_origin-heightoff_origin[id]==0.0)
								{
									set_hudmessage(prest_r,prest_g, prest_b, stats_x, stats_y, 0, 0.0, 0.7, 0.1, 0.1, h_stats);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_FJHEIGH1");
								}
								else if(heightland_origin-heightoff_origin[id]>0.0)
								{
									set_hudmessage(prest_r,prest_g, prest_b, stats_x, stats_y, 0, 0.0, 0.7, 0.1, 0.1, h_stats);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_FJHEIGH2",heightland_origin-heightoff_origin[id]);
								}
								else if(heightland_origin-heightoff_origin[id]<0.0)
								{
									set_hudmessage(prest_r,prest_g, prest_b, stats_x, stats_y, 0, 0.0, 0.7, 0.1, 0.1, h_stats);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_FJHEIGH3",floatabs(heightland_origin-heightoff_origin[id]));
								}
							}
						}
					}
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{
							if(height_show[i]==true )
							{
								if(heightland_origin-heightoff_origin[id]==0.0)
								{
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_FJHEIGH1");
								}
								else if(heightland_origin-heightoff_origin[id]>0.0)
								{
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_FJHEIGH2",heightland_origin-heightoff_origin[id]);
								}
								else if(heightland_origin-heightoff_origin[id]<0.0)
								{
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_FJHEIGH3",floatabs(heightland_origin-heightoff_origin[id]));
								}
							}
						}
					}
					h_jumped[id]=false;
				}
				
				if((movetype[id] != MOVETYPE_FLY))	
				{
					if(firstfr[id]==false)
					{
						firstfr[id]=true;
						pev(id, pev_velocity, velocity);
						pev(id, pev_origin, origin);
						if((g_Jumped[id]==true || !(flags&FL_ONGROUND)))
						{
							firstvel[id]=velocity[2];
						}
						firstorig[id]=origin;
					}
					else if(firstfr[id]==true )
					{
						pev(id, pev_origin, origin);
						pev(id, pev_velocity, velocity);
			
						secorig[id]=origin;
						if((g_Jumped[id]==true || !(flags&FL_ONGROUND)))
						{
							secvel[id]=velocity[2];
						}
						firstfr[id]=false;	
					}
					if(!(flags&FL_ONGROUND) && first_air[id]==false)
					{
						framecount[id]++;
						if(framecount[id]==2)
						{
							first_air[id]=true;
						}
						
						SurfFrames[id]=floatabs(firstvel[id]-secvel[id]);
						
						if(floatabs(firstvel[id]-secvel[id])>41)
						{
							SurfFrames[id]=oldSurfFrames[id];
						}
						oldSurfFrames[id]=SurfFrames[id];
					}
					if(flags&FL_ONGROUND && first_air[id]==true)
					{
						first_air[id]=false;
						framecount[id]=0;
					}
					if(!(flags&FL_ONGROUND) && SurfFrames[id]<7.9 && uq_fps==1 && fps_hight[id]==false)
					{
						fps_hight[id]=true;
					}
					if((flags&FL_ONGROUND) && SurfFrames[id]>7.9 && fps_hight[id])
					{
						fps_hight[id]=false;
					}
			
					if(!(flags&FL_ONGROUND) && 1.7*floatabs(firstvel[id]-secvel[id])<SurfFrames[id] && floatabs(firstvel[id]-secvel[id])!=4.0)
					{
						if(equali(mapname,"slide_gs_longjumps") || equali(mapname,"b2j_slide_longjumps"))
						{
							slide[id]=true;
						}
						else if(!ladderjump[id] && movetype[id] != MOVETYPE_FLY)
						{
							find_sphere_class (id, "func_ladder",200.0, entlist1, 1);
							if(!entlist1[0])
							{
								JumpReset(id,30);
								slide_protec[id]=true;
								return FMRES_IGNORED;
							}
						}
					}
					else 
					{
						if(slide[id]==true && ((oldbuttons&IN_MOVELEFT && button&IN_MOVERIGHT) || (oldbuttons&IN_MOVERIGHT && button&IN_MOVELEFT)))
						{
							if(touch_ent[id])
							{
								JumpReset(id,102);
							}
							
							if(task_exists(id)) remove_task(id);
							
							set_task(1.5,"JumpReset1", id);
							
							pev(id, pev_origin, origin);
							
							slidim[id]=true;
							jump_type[id]=Type_Slide;
							
							g_Jumped[id]	= true;
							prestrafe[id]	= speed[id];
			
							if(showpre[id]==true)
							{
								set_hudmessage(255,255, 255, -1.0, 0.85, 0, 0.0, 0.7, 0.1, 0.1, 2);
								show_hudmessage(id, "Slide pre: %.03f",speed);
							}
							slide[id]=false;
						}
					}
					
					firstorig[id][2]=0.0;
					secorig[id][2]=0.0;
					
					if((slidim[id]==true || slide[id]==true) && get_distance_f(firstorig[id],secorig[id])>20.0)
					{
						groundslide[id]=0.0;
						waits[id]=0;
						slidim[id]=false;
						taskslide[id]=0;
						failslide[id]=false;
						slide[id]=false;
						g_Jumped[id]	= false;
						
						return FMRES_IGNORED;
					}
					
					if((g_Jumped[id]==true || h_jumped[id]) && get_distance_f(firstorig[id],secorig[id])>6.0)
					{
						h_jumped[id]=false;
						JumpReset(id,31);
						return FMRES_IGNORED;
					}
				}
				if(slidim[id]==true)
				{
					
					//if(Pmaxspeed != 250.0)
					//{
					//	client_print(id,print_center,"Slide works only withs weapons 250.0 speed"); 
					//	return FMRES_IGNORED;
					//}
					
					pev(id, pev_origin, origin);
					new Float:start[33][3],Float:end[33][3];
					
				
					start[id][0]=origin[0];
					start[id][1]=origin[1]+16.0;
					start[id][2]=origin[2];
					end[id][0]=origin[0];
					end[id][1]=origin[1]+16.0;
					end[id][2]=origin[2]-500.0;
					
					engfunc(EngFunc_TraceLine, start[id], end[id], IGNORE_GLASS, id, 0); 
					get_tr2( 0, TR_vecEndPos, slidez[id][0]);
			
					start[id][0]=origin[0];
					start[id][1]=origin[1]-16.0;
					start[id][2]=origin[2];
					end[id][0]=origin[0];
					end[id][1]=origin[1]-16.0;
					end[id][2]=origin[2]-500.0;
					
					engfunc(EngFunc_TraceLine, start[id], end[id], IGNORE_GLASS, id, 0); 
					get_tr2( 0, TR_vecEndPos, slidez[id][1]);
					
					start[id][0]=origin[0]+16.0;
					start[id][1]=origin[1];
					start[id][2]=origin[2];
					end[id][0]=origin[0]+16.0;
					end[id][1]=origin[1];
					end[id][2]=origin[2]-500.0;
					
					engfunc(EngFunc_TraceLine, start[id], end[id], IGNORE_GLASS, id, 0); 
					get_tr2( 0, TR_vecEndPos, slidez[id][2]);
					
					start[id][0]=origin[0]-16.0;
					start[id][1]=origin[1];
					start[id][2]=origin[2];
					end[id][0]=origin[0]-16.0;
					end[id][1]=origin[1];
					end[id][2]=origin[2]-500.0;
					
					engfunc(EngFunc_TraceLine, start[id], end[id], IGNORE_GLASS, id, 0); 
					get_tr2( 0, TR_vecEndPos, slidez[id][3]);
					
					for(new i=0;i<4;i++)
					{		
						if(i!=3)
						{
							if(slidez[id][i][2]>slidez[id][i+1][2])
							{
								needslide[id]=slidez[id][i][2];
								groundslide[id]=slidez[id][i+1][2];
							
								if(needslide[id]-groundslide[id]>149.0 && landslide[id]==false)
								{
									landslide[id]=true;
									pev(id, pev_origin, origin);
									if( !(is_user_ducking(id)) )
									{
										origin[2]-=36.0;
									}
									else origin[2]-=18.0;
									
									slideland[id]=origin[2];
									slidedist[id]=slideland[id]-groundslide[id];
									maxspeed[id]=speed[id];
								}
							}
						}
					}
				
					if(taskslide[id]==0)
					{
						set_task(0.4,"wait", id+3313);
						taskslide[id]=1;
					}
					
					pev(id, pev_velocity, velocity);
					if(velocity[1]==0.0 && failslide[id]==false && !(flags&FL_ONGROUND) && waits[id]==1 )
					{
						if( !(is_user_ducking(id)) )
						{
							origin[2]-=36.0;
						}
						else origin[2]-=18.0;
						failslidez[id]=origin[2];
						failslide[id]=true;			
					}
				}
				
				if(flags&FL_ONGROUND && slidim[id]==true && Pmaxspeed == 250.0)
				{
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]) && g_lj_stats[i]==true)
						{
							if(needslide[id]-groundslide[id]==slidedist[id])
							{
								client_print(i, print_console, "Slide Distance: %d.xxx",floatround(slidedist[id], floatround_floor));
								set_hudmessage( stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );	
								show_hudmessage( i, "Slide Distance: %d.xxx",floatround(slidedist[id], floatround_floor));
							}
							else
							{
								client_print(i, print_console, "Slide Distance: %f",slidedist[id]);
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );	
								show_hudmessage( i, "Slide Distance: %f",slidedist[id]);
							
							}
						}
					}
									
					new iPlayers[32],iNum; 
					get_players ( iPlayers, iNum,"ch") ;
					for(new i=0;i<iNum;i++) 
					{ 
						new ids=iPlayers[i]; 
						if(gHasColorChat[ids] ==true || ids==id)
						{
							if(needslide[id]-groundslide[id]==slidedist[id])
							{
								ColorChat(ids, GREY, "[%s] %s jumped %d.xxx units with Slide lj!^x01%s",prefix, g_playername[id], floatround(slidedist[id], floatround_floor),airacel[id]);
							}
							else 
							ColorChat(ids, GREY, "[%s] %s jumped %.3f units with Slide lj!^x01%s",prefix, g_playername[id], slidedist[id],airacel[id]);				
						}
					}
										
					slidim[id]=false;
					groundslide[id]=0.0;
					waits[id]=0;
					slidim[id]=false;
					taskslide[id]=0;
					taskslide1[id]=0;
					
					message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
					write_byte ( TE_BEAMPOINTS );
					write_coord(floatround(origin[0]));
					write_coord(floatround(origin[1]));
					write_coord(floatround(slideland[id]));
					write_coord(floatround(origin[0]));
					write_coord(floatround(origin[1]+52.0));
					write_coord(floatround(slideland[id]));
				
					write_short(gBeam);
					write_byte(1);
					write_byte(5);
					write_byte(1130);
					write_byte(20);
					write_byte(0);
					write_byte(255);
					write_byte(0);
					write_byte(0);
					
					write_byte(200);
					write_byte(200);
					message_end();
					landslide[id]=false;
				}
				if((failslide[id]==true) && slidim[id]==true)
				{
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]) && g_lj_stats[i]==true)
						{
							client_print(i, print_console, "Slide Distance: %f Prestrafe: %f",failslidez[id]-groundslide[id],prestrafe[id]);
					
							set_hudmessage( f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
							show_hudmessage( i, "Slide Distance: %f^nPrestrafe: %f",failslidez[id]-groundslide[id],prestrafe[id]);
						}
					}
					
					message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
					write_byte ( TE_BEAMPOINTS );
					write_coord(floatround(origin[0]));
					write_coord(floatround(origin[1]));
					write_coord(floatround(failslidez[id]));
					write_coord(floatround(origin[0]));
					write_coord(floatround(origin[1]+52.0));
					write_coord(floatround(failslidez[id]));
					
					write_short(gBeam);
					write_byte(1);
					write_byte(5);
					write_byte(1130);
					write_byte(20);
					write_byte(0);
					write_byte(255);
					write_byte(0);
					write_byte(0);
					
					write_byte(200);
					write_byte(200);
					message_end();
			
					failslide[id]=false;
					slidim[id]=false;
					groundslide[id]=0.0;
					waits[id]=0;
					taskslide[id]=0;
					taskslide1[id]=0;
				}
			
				if( (in_air[id]==true || in_bhop[id] == true) && !(flags&FL_ONGROUND) )
				{
					static i;
					for( i = INFO_ZERO; i < 2; i++ )
					{
						if( (i == 1) 
						|| (frame_origin[id][i][0] == 0
						&& frame_origin[id][i][1] == 0
						&& frame_origin[id][i][2] == 0 
						&& frame_velocity[id][i][0] == 0
						&& frame_velocity[id][i][1] == 0
						&& frame_velocity[id][i][2] == 0 )) 
						{
							frame_origin[id][i][0] = origin[0];
							frame_origin[id][i][1] = origin[1];
							frame_origin[id][i][2] = origin[2];
							
							pev(id, pev_velocity, velocity);
							frame_velocity[id][i][0] = velocity[0];
							frame_velocity[id][i][1] = velocity[1];
							frame_velocity[id][i][2] = velocity[2];
							i=2;
						}
					}
					
				}
				
				if( (in_air[id]) && !( flags & FL_ONGROUND ) && !failed_jump[id])
				{	
					if(uq_script_detection)
					{
						new Float:angles[3];
						pev(id,pev_angles,angles);
						
						if(floatabs(angles[0]-old_angles[id][0])==0.0)
						{
							angles_arry[id]++;
						}
						//if()
						//{
						//	angles_arry1[id]++;
						//}
						
						//client_print(id,print_chat,"%f",floatabs(vector_length(angles)-vector_length(old_angles[id])));	
					
						old_angles[id]=angles;
					}
					
					new Float:jh_origin;
					
					jh_origin=origin[2];
					
					if(floatabs(jumpoff_origin[id][2]-jh_origin)<oldjump_height[id] && jheight[id]==0.0)
					{
						
						if(is_user_ducking(id))
						{
							jheight[id]=oldjump_height[id]+18.0;
						}
						else jheight[id]=oldjump_height[id];
						
						for( new i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{	
								if(jheight_show[i]==true )
								{
									set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE39",jheight[id]);
									
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_PRE39",jheight[id]);
								}
							}
						}
						
						if(!direct_for_strafe[id])
						{
							if(velocity[1]>0 && floatabs(velocity[1])>floatabs(velocity[0]))
							{
								direct_for_strafe[id]=1;
							}
							else if(velocity[1]<0 && floatabs(velocity[1])>floatabs(velocity[0]))
							{
								direct_for_strafe[id]=2;
							}
							else if(velocity[0]>0 && floatabs(velocity[0])>floatabs(velocity[1]))
							{
								direct_for_strafe[id]=3;
							}
							else if(velocity[0]<0 && floatabs(velocity[0])>floatabs(velocity[1]))
							{
								direct_for_strafe[id]=4;
							}
						}
					}
					
					
					
					oldjump_height[id]=floatabs(jumpoff_origin[id][2]-origin[2]);
					
					if(bug_check[id]==0 && floatfract(velocity[2])==0)
					{
						bug_check[id]=1;
					}
					else if(bug_check[id]==1 && floatfract(velocity[2])==0)
					{
						bug_true[id]=true;
						bug_check[id]=0;
					}
					if( !in_bhop[id] )
					{
						fnSaveBeamPos( id );
					}
					static Float:old_speed[33];
					if( speed[id] > old_speed[id] )
					{
						frames_gained_speed[id]++;
					}
					frames[id]++;
					
					old_speed[id] = speed[id];
			
					if( speed[id] > maxspeed[id] )
					{
						if (strafe_num[id] < NSTRAFES)
						{
							strafe_stat_speed[id][strafe_num[id]][0] += speed[id] - maxspeed[id];
						}
						maxspeed[id] = speed[id];
					}
					if ((speed[id] < TempSpeed[id]) && (strafe_num[id] < NSTRAFES))
					{
						strafe_stat_speed[id][strafe_num[id]][1] += TempSpeed[id] - speed[id];
						if(strafe_stat_speed[id][strafe_num[id]][1]>5)
						{
							if(floatabs(firstvel[id]-secvel[id])<SurfFrames[id]-0.1)
							{
								Checkframes[id]=true;
							}
							else if(floatabs(firstvel[id]-secvel[id])>SurfFrames[id])
							{
								Checkframes[id]=true;
							}
						}
						
						
					}
					TempSpeed[id] = speed[id];
					
					if((origin[2] + 18.0 - jumpoff_origin[id][2] < 0))
					{
						failed_jump[id] = true;
					}
					else if( (is_user_ducking(id) ? (origin[2]+18) : origin[2]) >= jumpoff_origin[id][2] )
					{
						failed_origin[id] = origin;
						failed_ducking[id] = is_user_ducking( id );
						failed_velocity[id] = velocity;
						
						origin[2] = pre_jumpoff_origin[id][2];	
					}
					if( first_frame[id] ) 
					{
						first_frame[id] = false;
						frame_velocity[id][0] = velocity;
						
						gBeam_count[id] = 0;
						for( new i = 0; i < 100; i++ )
						{
							gBeam_points[id][i][0]	= 0.0;
							gBeam_points[id][i][1]	= 0.0;
							gBeam_points[id][i][2]	= 0.0;
							gBeam_duck[id][i]	= false;
							gBeam_button[id][i]=false;
						}
						
						if(in_bhop[id] && jump_type[id]!=Type_DuckBhop)
						{
							if(upBhop[id])
							{
								if(jump_type[id]==Type_Up_Bhop_In_Duck)
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_UBID");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_UBID");
								}
								else if(velocity[2] < upbhop_koeff[id])
								{
									jump_type[id]=Type_Up_Bhop;
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_UBJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_UBJ");
								}
								else
								{
									jump_type[id]=Type_Up_Stand_Bhop;
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_USBJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_USBJ");
								}
								upBhop[id]=false;
							}
							else if(jump_type[id]==Type_Bhop_In_Duck)
							{
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_BID");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_BID");
							}
							else if( velocity[2] < 229.0)
							{
								jump_type[id] = Type_BhopLongJump;
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_BJ");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_BJ");
							}
							else 
							{
							
								jump_type[id] = Type_StandupBhopLongJump;
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_SBJ");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_SBJ");
								jumpoff_origin[id][2] = pre_jumpoff_origin[id][2];
							}
							
							for( new i = INFO_ONE; i < max_players; i++ )
							{
								if( (i == id || is_spec_user[i]))
								{	
									if(showpre[i]==true && prestrafe[id]>min_prestrafe[id])
									{
										if((Pmaxspeed * 1.2)>prestrafe[id] )
										{
											if(jump_type[id]==Type_Up_Bhop_In_Duck && (uq_upbhopinduck==1 ))
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE33",prestrafe[id]);
											}
											else if(jump_type[id]==Type_Up_Bhop && (uq_upbj==1 ))
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE34",prestrafe[id]);
											}
											else if(jump_type[id]==Type_Up_Stand_Bhop && (uq_upsbj==1 ))
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE35",prestrafe[id]);
											}
											else if(jump_type[id]==Type_Bhop_In_Duck   &&  uq_bhopinduck==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE36",prestrafe[id]);
											}
											else if(jump_type[id]==Type_BhopLongJump   &&  uq_bj==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE37",prestrafe[id]);
											}
											else if(jump_type[id]==Type_StandupBhopLongJump  && uq_sbj==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE38",prestrafe[id]);
											}
										}
										else
										{	
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 1.5, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PREHIGH",prestrafe[id],Pmaxspeed * 1.2);
										}
									}
								}
							}
						}
						else if(jump_type[id]==Type_DuckBhop)
						{
							for( new i = INFO_ONE; i < max_players; i++ )
							{
								if( (i == id || is_spec_user[i]))
								{	
									if(showpre[i]==true && speed[id]>50.0)
									{
										if((Pmaxspeed * 1.2)>speed[id] )
										{
											if(prestrafe[id]<200)
											{
												if(jump_type[id]==Type_DuckBhop && (uq_duckbhop==1))
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE32",prestrafe[id]);
												}
											}
										}
									}
								}
							}
						}
					} 
					else
					{	
						frame_velocity[id][1] = velocity;
					}
					
					if( in_bhop[id] )
						fnSaveBeamPos( id );
			
					if(detecthj[id]!=1)
					{	
						starthj[id][0] = origin[0];
						starthj[id][1] = origin[1];
						starthj[id][2] = jumpoff_origin[id][2]+28.0;
						stophj[id][0] = origin[0];
						stophj[id][1] = origin[1];
						stophj[id][2] = starthj[id][2] - 133.0; 
							
						engfunc( EngFunc_TraceLine, starthj[id], stophj[id], IGNORE_MONSTERS, id, 0 );
						get_tr2( 0, TR_vecEndPos, endhj[id]);
						
						if(starthj[id][2]-endhj[id][2]<133.0 && (starthj[id][2]-endhj[id][2]-64)!=0 && (starthj[id][2]-endhj[id][2]-64)>0 && detecthj[id]!=1)
						{
							detecthj[id]=2;
						}
						
						if(starthj[id][2]-endhj[id][2]>=133.0 && detecthj[id]!=2)
						{
							detecthj[id]=1;
						}
					}
					
					if(ddafterJump[id])
						ddafterJump[id]=false;	
				}
				
				if(notjump[id] && bhopaem[id])
				{
					notjump[id]=false;
				}
				
				if( flags&FL_ONGROUND )
				{
					surf[id]=0.0;
					if (!pev( id, pev_solid ))
					{
						static ClassName[32];
						pev(pev(id, pev_groundentity), pev_classname, ClassName, 32);
			
						if( equali(ClassName, "func_train")
							|| equali(ClassName, "func_conveyor") 
							|| equali(ClassName, "trigger_push") || equali(ClassName, "trigger_gravity"))
						{
							JumpReset(id,32);
							set_task(0.4,"JumpReset1", id);
						}
						else if(equali(ClassName, "func_door") || equali(ClassName, "func_door_rotating") )
						{
							JumpReset(id,33);
							set_task(0.4,"JumpReset1", id);	
						}
					}
					
					pev(id, pev_origin, origin);
					notjump[id]=true;
					if(is_user_ducking(id))
					{
						falloriginz[id]=origin[2]+18;
					}
					else falloriginz[id]=origin[2];
					
					if( OnGround[id] == false)
					{	
						if (dropbhop[id] || in_ladder[id] || jump_type[id] == Type_WeirdLongJump || jump_type[id]==Type_ladderBhop || jump_type[id]==Type_Drop_BhopLongJump)
						{
							FallTime[id]=get_gametime();
							
						}
						OnGround[id] = true;
					}
				}
				
				if( !(flags&FL_ONGROUND) && notjump[id]==true && (movetype[id] != MOVETYPE_FLY) && jump_type[id]!=Type_ladderBhop )//&& jump_type[id] != Type_Drop_CountJump)
				{	
					pev(id, pev_origin, origin);
			
					OnGround[id] = false;
					
					pev(id, pev_velocity, velocity);
					
					new Float:tempfall;
					
					if(is_user_ducking(id))
					{
						tempfall=origin[2]+18;
					}
					else tempfall=origin[2];
					
					if( falloriginz[id]-tempfall>1.0 && !cjjump[id] && (ddforcj[id] || jump_type[id] == Type_Drop_CountJump || jump_type[id] == Type_StandUp_CountJump || jump_type[id] == Type_None || jump_type[id] == Type_CountJump || jump_type[id] == Type_Multi_CountJump || jump_type[id] == Type_Double_CountJump))
					{
						oldjump_type[id]=0;
			
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_WJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_WJ");
						
						if(ddforcj[id])
						ddforcj[id]=false;
						
						jump_type[id] = Type_WeirdLongJump;
						
					}
					
					if (velocity[2] == -240.0)
					{
						oldjump_type[id]=0;
						ddbeforwj[id]=true;
						jump_type[id] = Type_WeirdLongJump;
						
						
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DDWJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DDWJ");
					}
				}
				else if(!(flags&FL_ONGROUND) && notjump[id]==false && (movetype[id] != MOVETYPE_FLY) && in_ladder[id]==false && jump_type[id] != Type_Slide)
				{
					oldjump_type[id]=0;
					OnGround[id] = false;
			
					pev(id, pev_velocity, velocity);
					pev(id, pev_origin, origin);
					
					new Float:drbh;
					if(is_user_ducking(id))
					{
						drbh=origin[2]+18;
					}
					else drbh=origin[2];
			
					if(dropbjorigin[id][2]-drbh>2.0)
					{
						if(dropbjorigin[id][2]-drbh<30 && jump_type[id] != Type_Drop_BhopLongJump && jump_type[id] != Type_None)
						{
							old_type_dropbj[id]=jump_type[id];
							formatex(Jtype_old_dropbj[id],32,Jtype[id]);
							formatex(Jtype_old_dropbj1[id],32,Jtype1[id]);
						}
						
						jump_type[id] = Type_Drop_BhopLongJump;
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DRBJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DRBJ");
						nextbhop[id]=false;
						bhopaem[id]=false;
						dropbhop[id]=true;
					}
				}
				
				if( movetype[id] == MOVETYPE_FLY) 
				{
					OnGround[id] = false;
					firstvel[id]=8.0;
					secvel[id]=0.0;
					checkladdertime[id]=get_gametime();
				}
				if( movetype[id] == MOVETYPE_FLY && firstladder[id]==false) 
				{
					firstladder[id]=true;
					nextbhop[id]=false;
					bhopaem[id]=false;
					h_jumped[id]=false;
					JumpReset(id,34);
					return FMRES_IGNORED;
				}
				if( movetype[id] != MOVETYPE_FLY && firstladder[id]==true && flags&FL_ONGROUND) 
				{
					firstladder[id]=false;
				}
				if( (movetype[id] == MOVETYPE_FLY) &&  (button&IN_FORWARD || button&IN_BACK || button&IN_LEFT || button&IN_RIGHT ) )
				{
					ladderjump[id]=true;
					find_sphere_class (id, "func_ladder",18.0, entlist1, 1);
					
					if(entlist1[0]!=0)
					{
						for(new i=0;i<nLadder;i++)
						{
							if(entlist[i]==entlist1[0])
							{
								nashladder=i;	
							}
						}
					}
			
					prestrafe[id]	= speed[id];
					maxspeed[id]	= speed[id];
				}
				
				if( (movetype[id] == MOVETYPE_FLY) &&  button&IN_JUMP )
				{
					jump_type[id]=Type_ladderBhop;
					formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_LDBJ");
					formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_LDBJ");
					ladderjump[id]=false;
					in_air[id]=false;
					in_ladder[id]=false;
					bhopaem[id]=false;
					notjump[id]=true;
					dropbhop[id]=false;		
				}
				
				if( movetype[id] != MOVETYPE_FLY && ladderjump[id]==true)
				{
					if(touch_ent[id])
					{
						JumpReset(id,103);
					}
					notjump[id]=true;
					dropbhop[id]=false;
					pev(id, pev_origin, origin);
					jumpoff_origin[id] = origin;
					jumpoff_origin[id][2]=ladderxyz[nashladder][2]+35.031250;
					
					jumpoff_time[id] = get_gametime( );
					strafecounter_oldbuttons[id] = INFO_ZERO;
					
					jump_type[id]=Type_ladder;
					laddertime[id]=get_gametime();
			
					formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_LDJ");
					formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_LDJ");
					
					if(laddersize[nashladder][0]<=laddersize[nashladder][1])
					{
						laddist[id]=laddersize[nashladder][0]+0.03125;
					}
					else if(laddersize[nashladder][0]>laddersize[nashladder][1])
					{
						laddist[id]=laddersize[nashladder][1]+0.03125;
					}
					
					if(laddist[id]>10)
					{
						laddist[id]=4.0;
					}
					ladderjump[id]=false;	
					TempSpeed[id] = 0.0;
					static i;
					for( i = INFO_ZERO; i < NSTRAFES; i++ )
					{
						strafe_stat_speed[id][i][0] = 0.0;
						strafe_stat_speed[id][i][1] = 0.0;
						strafe_stat_sync[id][i][0] = INFO_ZERO;
						strafe_stat_sync[id][i][1] = INFO_ZERO;
						strafe_stat_time[id][i] = 0.0;
						strafe_lost_frame[id][i] = 0;
						
					}
					in_air[id]	= true;
					in_ladder[id]=true;
					g_Jumped[id]	= true;
					first_frame[id] = true;
					
					turning_right[id] = false;
					turning_left[id] = false;
					
					for( i = INFO_ZERO; i < 2; i++ )
					{
						frame_origin[id][i][0] = 0.0;
						frame_origin[id][i][1] = 0.0;
						frame_origin[id][i][2] = 0.0;
						
						frame_velocity[id][i][0] = 0.0;
						frame_velocity[id][i][1] = 0.0;
						frame_velocity[id][i][2] = 0.0;
					}
					for( i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{
							if(showpre[id]==true && uq_ladder==1 )
							{
								set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 1.0, 0.1, 0.1, h_prest);
								show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE31",prestrafe[id]);
							}
						}
					}
				}
				
				
				if((button & IN_JUMP && flags & FL_ONGROUND) || in_ladder[id])
				{
					x_jump[id]=true;
					if(is_user_ducking(id))
					{
						x_heightland_origin[id]=origin[2]+18;
					}
					else x_heightland_origin[id]=origin[2];
				}
				
				if((x_jump[id]==true || in_ladder[id]) && button & IN_DUCK && !(oldbuttons &IN_DUCK) && flags & FL_ONGROUND )
				{
					if(x_jump[id])
					{
						x_jump[id]=false;
						
						new Float:heightland_origin;
						if(is_user_ducking(id))
						{
							heightland_origin=origin[2]+18;
						}
						else heightland_origin=origin[2];
						if(heightland_origin-x_heightland_origin[id]>0 && !in_ladder[id])
						{
							JumpReset(id,45);
							
							UpcjFail[id]=true;
								
							return FMRES_IGNORED;
						}
						
						if(bhopaem[id] && !ddforcjafterbhop[id])
						{
							ddforcjafterbhop[id]=true;
						}
						else ddforcjafterbhop[id]=false;
						
						if(in_ladder[id] && !ddforcjafterladder[id])
						{
							ddforcjafterladder[id]=true;
						}
						else ddforcjafterladder[id]=false;
						
						ddforcj[id]=true;
					}
					
				}
				
				if(cjjump[id]==false && (button & IN_DUCK || oldbuttons & IN_DUCK) && (jump_type[id] == Type_Drop_CountJump || ddforcj[id] || ddafterJump[id] || jump_type[id]==Type_CountJump || jump_type[id]==Type_Multi_CountJump || jump_type[id]==Type_Double_CountJump))
				{
					if(origin[2]-duckstartz[id]<-1.21 && origin[2]-duckstartz[id]>-2.0)
					{
						if(ddstandcj[id])
						{
							nextbhop[id]=false;
							bhopaem[id]=false;
						}
						if(jump_typeOld[id]==1)
						{
							multiscj[id]=0;	
						}
						else if(jump_typeOld[id]==2)
						{
							multiscj[id]=1;	
						}
						else if(jump_typeOld[id]==3)
						{
							multiscj[id]=2;	
						}
						jump_type[id] = Type_StandUp_CountJump;
												
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_SCJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_SCJ");
							
						FallTime[id]=get_gametime();
					}
				}
				if( button & IN_DUCK && !(oldbuttons &IN_DUCK) && flags & FL_ONGROUND)
				{
					nextbhop[id]=false;
					bhopaem[id]=false;
					doubleduck[id]=true;
					
					sync_doubleduck[id]=true;
					
					doubletime[id]=get_gametime();
					FallTime1[id]=get_gametime();
					ddnum[id]++;
				}
				if(sync_doubleduck[id] && g_Jumped[id])
				{
					sync_doubleduck[id]=false;
					doubleduck_stat_sync[id][0]=0;
					doubleduck_stat_sync[id][1]=0;
				}
				if(flags & FL_ONGROUND)
				{
					if(duckstartz[id]-origin[2]<18.0 && doubleduck[id]==true && (get_gametime()-doubletime[id]>0.4) && ddbeforwj[id]==false && (jump_type[id]==Type_CountJump || jump_type[id]==Type_Multi_CountJump || jump_type[id]==Type_Double_CountJump))
					{
						JumpReset(id,2);
						doubleduck[id]=false;
					}	
				}
				pev(id, pev_origin, origin);
				
				if(slide_protec[id]==false && button & IN_JUMP && !( oldbuttons & IN_JUMP ) && flags & FL_ONGROUND && bhopaem[id]==false && UpcjFail[id]==false)
				{	
					bhop_num[id]=0;
					notjump[id]=false;
					if(ddforcj[id]==true)
					{
						if(jump_type[id] == Type_StandUp_CountJump)
						{
							ddstandcj[id]=true;
						}
							
						ddforcj[id]=false;
							
						if(jump_type[id] != Type_StandUp_CountJump && (jump_type[id]!=Type_Drop_CountJump || ddforcjafterladder[id]))
						{
							if(ddnum[id]==1)
							{
								jump_type[id]=Type_CountJump;
								CjafterJump[id]=1;
							}
							else if(ddnum[id]==2)
							{
								jump_type[id] = Type_Double_CountJump ;
								CjafterJump[id]=2;
							}
							else if(ddnum[id]>=3)
							{
								jump_type[id] = Type_Multi_CountJump;
								CjafterJump[id]=3;
							}
							
							ddnum[id]=0;
							nextbhop[id]=false;
							bhopaem[id]=false;
						}
					}
					
					oldjump_height[id]=0.0;
					jheight[id]=0.0;
					
					if(nextbhop[id] && ddafterJump[id]==false)
					{
						FullJumpFrames[id]=0;
						direct_for_strafe[id]=0;
						angles_arry[id]=0;
						
						if(uq_istrafe)
						{
							for(new i=0;i<=line_erase_strnum[id];i++)
							{
								for( new j = 0; j <= line_erase[id][i]; j++ )
								{
									line_lost[id][i][j]=0;
									lost_frame_count[id][i]=0;
								}
							}
						}
						
						edgedone[id]=false;
						if(get_gametime()-checkladdertime[id]<0.5)
						{
							ladderbug[id]=true;
						}
						
						if(touch_ent[id])
						{
							JumpReset(id,105);
						}
						ddnum[id]=0;
						
						if(cjjump[id]==true && (get_gametime()-duckoff_time[id])<0.2)
						{
							JumpReset(id,35);
							return FMRES_IGNORED;
							
						}
					
						if(oldbuttons & IN_DUCK && button & IN_DUCK && duckbhop[id]==true && (jump_type[id]==Type_HighJump || jump_type[id]==Type_LongJump || jump_type[id]==Type_None))
						{
							jump_type[id]=Type_DuckBhop;
							formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DKBJ");
							formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DKBJ");
							duckbhop[id]=false;
						}
						
						bhopaem[id]=true;
						
						pev(id, pev_origin, origin);
						static bool:ducking;
						ducking = is_user_ducking( id ); 
						strafecounter_oldbuttons[id] = INFO_ZERO;
					
						strafe_num[id] = 0;
						TempSpeed[id] = 0.0;
						in_bhop[id] = true;
						pre_jumpoff_origin[id] = jumpoff_origin[id];
						jumpoff_foot_height[id] = ducking ? origin[2] - 18.0 : origin[2] - 36.0; //todo:think about this gavno
						
						jumpoff_time[id] = get_gametime( );
						
						new Float:checkbhop;
						
						if(is_user_ducking(id)==true)
						{
							checkbhop=jumpoff_origin[id][2]-origin[2]-18.0;
						}
						else checkbhop=jumpoff_origin[id][2]-origin[2];
						
						if(checkbhop<-1.0)
						{
							if(button & IN_DUCK )
							{
								jump_type[id]=Type_Up_Bhop_In_Duck;
							}
							upbhop_koeff[id]=UpBhop_calc(floatabs(checkbhop));
							upheight[id]=floatabs(checkbhop);
							upBhop[id]=true;
						}
						else if(jump_type[id]!=Type_DuckBhop)
						{
							if(button & IN_DUCK )
							{
								jump_type[id]=Type_Bhop_In_Duck;
							}
						}
						
						jumpoff_origin[id] = origin;
						if(is_user_ducking( id )==true)
						{
							
							jumpoff_origin[id][2] = origin[2]+18.0;
						}
						else jumpoff_origin[id][2] = origin[2];
						
						pev(id, pev_velocity, velocity);
						first_frame[id] = true;
						
						prestrafe[id] = speed[id];
						maxspeed[id] = speed[id];
						
						static i;
						for( i = INFO_ZERO; i < NSTRAFES; i++ )
						{
							strafe_stat_speed[id][i][0] = 0.0;
							strafe_stat_speed[id][i][1] = 0.0;
							strafe_stat_sync[id][i][0] = INFO_ZERO;
							strafe_stat_sync[id][i][1] = INFO_ZERO;
							strafe_stat_time[id][i] = 0.0;
							strafe_lost_frame[id][i] = 0;
						}
						for( i = INFO_ZERO; i < 2; i++ )
						{
							frame_origin[id][i][0] = 0.0;
							frame_origin[id][i][1] = 0.0;
							frame_origin[id][i][2] = 0.0;
							
							frame_velocity[id][i][0] = 0.0;
							frame_velocity[id][i][1] = 0.0;
							frame_velocity[id][i][2] = 0.0;
						}
						in_air[id]	= true;
						g_Jumped[id]	= true;
						turning_right[id] = false;
						turning_left[id] = false;
					}
					else 
					{
						if(get_gametime()-checkladdertime[id]<0.5 && jump_type[id]!=Type_ladderBhop)
						{
							ladderbug[id]=true;
						}
						
						if(touch_ent[id])
						{
							JumpReset(id,106);
						}	
						ddnum[id]=0;
						if(in_ladder[id]==true)
						{
							in_ladder[id]=false;
							
							jump_type[id]=Type_Real_ladder_Bhop;
							
							formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_RLDBJ");
							formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_RLDBJ");
							
						}
						
						strafe_num[id]=0;
						
						if(get_gametime()-changetime[id]<0.5)
						{
							JumpReset(id,38);
							return FMRES_IGNORED;
						}
						
						if(task_exists(id+2311))
							remove_task(id+2311);
						
						pev(id, pev_velocity, velocity);
						
						if(jump_type[id]!=Type_ladderBhop)
						{
							if(oldjump_typ1[id]==1)
							{
								jump_type[id]=Type_ladderBhop;
								oldjump_typ1[id]=0;
							}
						}
						
						
						
						jumpoff_origin[id] = origin;
						
						if(is_user_ducking(id))
						{
							jumpoff_origin[id][2] = origin[2]+18.0;
						}
						else jumpoff_origin[id][2] = origin[2];
						
						jumpoff_time[id] = get_gametime( );
						strafecounter_oldbuttons[id] = INFO_ZERO;
						
						pev(id, pev_origin, origin);
						if(is_user_ducking(id))
						{
							dropbjorigin[id][2]=origin[2]+18;
						}
						else dropbjorigin[id][2]=origin[2];
						dropbjorigin[id][0]=origin[0];
						dropbjorigin[id][1]=origin[1];
						pev(id, pev_velocity, velocity);
						secorig[id]=origin;
						
						nextbhop[id]=true;
						
						
						if(dropbhop[id] && jump_type[id] != Type_Drop_CountJump && jump_type[id] != Type_StandUp_CountJump)
						{
							dropbhop[id]=false;
							jump_type[id] = Type_Drop_BhopLongJump; 
						}
						else dropbhop[id]=false;
						
						if(jump_type[id]==Type_CountJump || jump_type[id]==Type_Multi_CountJump || jump_type[id]==Type_Double_CountJump)
						{
							cjjump[id]=true;
						}
						if (!ddstandcj[id] && !CjafterJump[id] && (jump_type[id] == Type_CountJump || jump_type[id] == Type_Multi_CountJump || jump_type[id] == Type_Double_CountJump) && floatabs(duckstartz[id]-jumpoff_origin[id][2])>4.0)
						{
							if(speed[id]<200.0)
							{
								jump_type[id] = Type_LongJump;
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_LJ");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_LJ");
							}
							else
							{
								jump_type[id] = Type_WeirdLongJump;
																
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_WJ");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_WJ");
							}
						}
						if(jump_type[id] == Type_Drop_CountJump && multidropcj[id]==0 && (origin[2]-first_duck_z[id])>4)
						{
							JumpReset(id,146);
							return FMRES_IGNORED;
						}
						prestrafe[id]	= speed[id];
						maxspeed[id]	= speed[id];
						new Float:kkk;
							
						kkk=1.112*Pmaxspeed;
						
						if(prestrafe[id]<kkk && jump_type[id] !=Type_ladderBhop && jump_type[id] != Type_Drop_BhopLongJump && jump_type[id] != Type_WeirdLongJump && jump_type[id] != Type_CountJump && jump_type[id] != Type_Multi_CountJump && jump_type[id] != Type_Double_CountJump && jump_type[id] != Type_BhopLongJump && jump_type[id] != Type_StandupBhopLongJump && jump_type[id] != Type_Drop_CountJump)
						{
							if(jump_type[id] != Type_Drop_CountJump && jump_type[id] != Type_StandUp_CountJump && jump_type[id] !=Type_Real_ladder_Bhop)
							{
								jump_type[id] = Type_LongJump;
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_LJ");
								formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_LJ");
								
								if((jumpoff_origin[id][2]-origin[2])==18.0 && oldbuttons & IN_DUCK && button & IN_DUCK && duckbhop[id]==false)
								{
									duckbhop[id]=true;
									//client_print(id,print_chat,"%f",jumpoff_origin[id][2]-origin[2]);
									
									find_sphere_class (id, "func_ladder",100.0, entlist1, 1);
									if(entlist1[0]!=0)
									{
										if(get_gametime()-checkladdertime[id]<0.1 || prestrafe[id]>110)
										{
											ladderbug[id]=true;
										}
										else if(entlist1[0]!=0)
										{
											ladderbug[id]=true;
										}
										find_ladder[id]=true;
									}
								}
								else duckbhop[id]=false;
							}
						}
						
						TempSpeed[id] = 0.0;
						
						static i;
						for( i = INFO_ZERO; i < NSTRAFES; i++ )
						{
							strafe_stat_speed[id][i][0] = 0.0;
							strafe_stat_speed[id][i][1] = 0.0;
							strafe_stat_sync[id][i][0] = INFO_ZERO;
							strafe_stat_sync[id][i][1] = INFO_ZERO;
							strafe_stat_time[id][i] = 0.0;
							strafe_lost_frame[id][i] = 0;
						}
						in_air[id]	= true;
						g_Jumped[id]	= true;
						first_frame[id] = true;
						
						prestrafe[id]	= speed[id];
						maxspeed[id]	= speed[id];
						
						turning_right[id] = false;
						turning_left[id] = false;
						
						for( i = INFO_ZERO; i < 2; i++ )
						{
							frame_origin[id][i][0] = 0.0;
							frame_origin[id][i][1] = 0.0;
							frame_origin[id][i][2] = 0.0;
							
							frame_velocity[id][i][0] = 0.0;
							frame_velocity[id][i][1] = 0.0;
							frame_velocity[id][i][2] = 0.0;
						}
						
						if(jump_type[id]==Type_LongJump && prestrafe[id]>kkk)
						{
							jump_type[id] = Type_WeirdLongJump;
							
							
							formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_WJ");
							formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_WJ");
						}
						
						
						if ((doubleduck_stat_sync[id][0]+doubleduck_stat_sync[id][1]) > 0)
						{
							dd_sync[id] =(doubleduck_stat_sync[id][0] * 100)/(doubleduck_stat_sync[id][0]+doubleduck_stat_sync[id][1]);
							
							if(dd_sync[id]<96)
								dd_sync[id] =5+dd_sync[id]; 		
							
						}				
						else
						{
							dd_sync[id] = 0;
						}
						
						for( i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{
								if((Pmaxspeed * 1.2)>prestrafe[id])
								{	
									if(prestrafe[id]>min_prestrafe[id])
									{
										if(jump_type[id] == Type_Double_CountJump && showpre[id]==true && uq_dcj==1)
										{
											if(CjafterJump[id]==2)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												
												if(ddforcjafterbhop[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE1",prestrafe[id]);	
												else if(ddforcjafterladder[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE2",prestrafe[id]);
												else
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE3",prestrafe[id]);	
											
											}
											else
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE4",prestrafe[id]);
											}
										}
										else if(jump_type[id] == Type_CountJump && showpre[id]==true && uq_cj==1)
										{
											if(CjafterJump[id]==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												
												if(ddforcjafterbhop[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE5",prestrafe[id]);	
												else if(ddforcjafterladder[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE6",prestrafe[id]);
												else
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE7",prestrafe[id]);
											}
											else
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE8",prestrafe[id]);
											}
										}
										else if(jump_type[id] == Type_Multi_CountJump  && showpre[id]==true  && uq_mcj==1)
										{
											if(CjafterJump[id]==3)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												
												if(ddforcjafterbhop[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE9",prestrafe[id]);	
												else if(ddforcjafterladder[id])
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE10",prestrafe[id]);
												else
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE11",prestrafe[id]);	
											}
											else
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE12",prestrafe[id]);
											}
										}
										else if(jump_type[id] == Type_LongJump && showpre[id]==true && ljpre[id]==true && uq_lj==1)
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE13",prestrafe[id]);
										}
										else if(jump_type[id] == Type_WeirdLongJump && showpre[id]==true && ddbeforwj[id]==true  && uq_wj==1)
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE14",prestrafe[id]);
										}
										else if(jump_type[id] == Type_WeirdLongJump && showpre[id]==true && ddbeforwj[id]==false && uq_wj==1)
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE15",prestrafe[id]);
										}
										else if((jump_type[id] == Type_Drop_BhopLongJump)&& showpre[id]==true && uq_drbj==1 )
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE16",prestrafe[id]);
										}
										else if((jump_type[id] == Type_ladderBhop)&& showpre[id]==true && uq_ldbj==1 )
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE17",prestrafe[id]);
										}
										else if((jump_type[id]==Type_Drop_CountJump)&& showpre[id]==true)
										{
											if(multidropcj[id]==0 && uq_drcj==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE18",prestrafe[id]);
											}
											else if(multidropcj[id]==1 && uq_dropdcj==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE19",prestrafe[id]);
											}
											else if(multidropcj[id]==2 && uq_dropmcj==1)
											{
												set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
												show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE20",prestrafe[id]);
											}
										}
										else if((jump_type[id]==Type_StandUp_CountJump) && showpre[id]==true && uq_drsbj==1)
										{
											if(dropaem[id])
											{
												if(multiscj[id]==0 && uq_dropscj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE21",prestrafe[id]);
												}
												else if(multiscj[id]==1 && uq_dropdscj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE22",prestrafe[id]);
												}
												else if(multiscj[id]==2 && uq_dropmscj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE23",prestrafe[id]);
												}
											}
											else if(ddstandcj[id])
											{
												if(multiscj[id]==0)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE24",prestrafe[id]);
												}
												else if(multiscj[id]==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE25",prestrafe[id]);
												}
												else if(multiscj[id]==2)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE26",prestrafe[id]);
												}
											}
											else
											{
												if(multiscj[id]==0 && uq_drsbj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE27",prestrafe[id]);
												}
												else if(multiscj[id]==1 && uq_dscj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE28",prestrafe[id]);
												}
												else if(multiscj[id]==2 && uq_mscj==1)
												{
													set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
													show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE29",prestrafe[id]);
												}
											}
										}
										else if((jump_type[id]==Type_Real_ladder_Bhop) && showpre[id]==true && uq_realldbhop==1)
										{
											set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
											show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PRE30",prestrafe[id]);
										}
									}
								}
								else if(showpre[id]==true)
								{
									set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 1.5, 0.1, 0.1, h_prest);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PREHIGH",prestrafe[id],Pmaxspeed * 1.2);
								}
							}
						}
					}
				}
				else if(slide_protec[id]==false && ddafterJump[id]==false && UpcjFail[id]==false && bhopaem[id]==true && button & IN_JUMP && !( oldbuttons & IN_JUMP ) && flags & FL_ONGROUND)
				{
					if(touch_ent[id])
					{
						JumpReset(id,106);
					}
					ddnum[id]=0;
					if(ddforcj[id]==true)
					{
						ddforcj[id]=false;
						JumpReset(id,46);
						return FMRES_IGNORED;
					}
					pev(id, pev_origin, origin);
					static bool:ducking;
					ducking = is_user_ducking( id );
					strafecounter_oldbuttons[id] = INFO_ZERO;
				
					strafe_num[id] = 0;
					TempSpeed[id] = 0.0;
					
					pre_jumpoff_origin[id] = jumpoff_origin[id];
					jumpoff_foot_height[id] = ducking ? origin[2] - 18.0 : origin[2] - 36.0;
					
					jumpoff_time[id] = get_gametime( );
					
					jumpoff_origin[id] = origin;
					if(is_user_ducking( id )==true)
					{
						jumpoff_origin[id][2] = origin[2]+18.0;
					}
					else jumpoff_origin[id][2] = origin[2];
					pev(id, pev_velocity, velocity);
					
					first_frame[id] = true;
					
					prestrafe[id] = speed[id];
					maxspeed[id] = speed[id];
					
					static i;
					for( i = INFO_ZERO; i < NSTRAFES; i++ )
					{
						strafe_stat_speed[id][i][0] = 0.0;
						strafe_stat_speed[id][i][1] = 0.0;
						strafe_stat_sync[id][i][0] = INFO_ZERO;
						strafe_stat_sync[id][i][1] = INFO_ZERO;
						strafe_stat_time[id][i] = 0.0;
						strafe_lost_frame[id][i] = 0;
					}
					for( i = INFO_ZERO; i < 2; i++ )
					{
						frame_origin[id][i][0] = 0.0;
						frame_origin[id][i][1] = 0.0;
						frame_origin[id][i][2] = 0.0;
						
						frame_velocity[id][i][0] = 0.0;
						frame_velocity[id][i][1] = 0.0;
						frame_velocity[id][i][2] = 0.0;
					}
					in_air[id]	= true;
					g_Jumped[id]	= true;
					turning_right[id] = false;
					turning_left[id] = false;
					jump_type[id]=Type_Multi_Bhop;
					formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MBJ");
					formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MBJ");
				
					bhop_num[id]++;
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{	
							if(showpre[i]==true && multibhoppre[id] && speed[id]>50.0)
							{
								if((Pmaxspeed * 1.2)>speed[id] && (uq_bj==1 || uq_sbj==1))
								{
									set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_MBPRE",speed[id]);
								}
								else
								{	if((uq_bj==1 || uq_sbj==1))
									{
										set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 1.5, 0.1, 0.1, h_prest);
										show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_PREHIGH",prestrafe[id],Pmaxspeed * 1.2);
									}
								}
							}
						}
					}
				}
				else if(slide_protec[id]==false && ddafterJump[id]==false && UpcjFail[id]==false && !(button&IN_JUMP) && oldbuttons&IN_JUMP && flags & FL_ONGROUND && nextbhop[id]==true && cjjump[id]==false && bhopaem[id]==false && jump_type[id]!=Type_Drop_BhopLongJump)	
				{		
					if(touch_ent[id])
					{
						JumpReset(id,109);
					}
					ddnum[id]=0;
					if(ddforcj[id]==true)
					{
						JumpReset(id,46);
						return FMRES_IGNORED;
					}
					bhop_num[id]=0;
			
					if(oldbuttons & IN_DUCK && button & IN_DUCK && duckbhop[id]==true && (jump_type[id]==Type_LongJump || jump_type[id]==Type_None))
					{
						jump_type[id]=Type_DuckBhop;
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DKBJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DKBJ");
						duckbhop[id]=false;
					}
					else
					{
						bhopaem[id]=true;
						
						static i;
						for( i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{	
								if(showpre[id]==true && failearly[id]==true && (uq_bj==1 || uq_sbj==1))
								{
									set_hudmessage(255, 0, 109, -1.0, 0.70, 0, 0.0, 0.5, 0.1, 0.1, h_stats);
									show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_JEARLY");
								}
							}
						}
					}
				}
				else if( ( failed_jump[id] || flags&FL_ONGROUND)&& in_air[id] )
				{	
					if(old_type_dropbj[id]!=Type_Null && jump_type[id]==Type_Drop_BhopLongJump)
					{
						jump_type[id]=old_type_dropbj[id];
						
						formatex(Jtype[id],32,Jtype_old_dropbj[id]);
						formatex(Jtype1[id],32,Jtype_old_dropbj1[id]);
					}
					if(bug_true[id])
					{
						JumpReset(id,322);
						return FMRES_IGNORED;
					}
					if(prestrafe[id]>200 && jump_type[id]==Type_DuckBhop)
					{
						duckbhop_bug_pre[id]=true;
						set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 1.5, 0.1, 0.1, h_prest);
						show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_PROBBUG",prestrafe[id]);
					}
					new summad,summws;
					for(new i=0;i<NSTRAFES;i++)
					{
						if(type_button_what[id][i]==1)
						summad++;
						if(type_button_what[id][i]==2)
						summws++;
					}
					if(summws>summad)
					{
						if(backwards[id])
						{
							formatex(pre_type[id],32,"%L",LANG_SERVER,"UQSTATS_PRETYPE1"); //Back-Side?? don't know...
						}
						else formatex(pre_type[id],32,"%L",LANG_SERVER,"UQSTATS_PRETYPE1");
					}
					else if(backwards[id])
					{
						formatex(pre_type[id],32,"%L",LANG_SERVER,"UQSTATS_PRETYPE2");
					}
					else pre_type[id] = "";
			
					static bool:ducking;
					
					static type[33];
					type[0] = '^0';
					new bool:failed;
					if (failed_jump[id] == true)
					{
						formatex( type, 32, "" );
						failed=true;
						origin=failed_origin[id];
					}
					else
					{
						pev(id, pev_origin, origin);
						ducking = is_user_ducking( id );
						failed=false;
					}
					
					if(donehook[id])
					{
						donehook[id]=false;
						failed_jump[id]=true;
						client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_HOOKPROTECT");		
					}	
					if(failed==false)
					{
						height_difference[id] =  ducking ? jumpoff_origin[id][2] - origin[2] - 18.0 : jumpoff_origin[id][2] - origin[2];
						if(jump_type[id] == Type_BhopLongJump || jump_type[id] == Type_StandupBhopLongJump || jump_type[id]==Type_Bhop_In_Duck)
						{
							if(height_difference[id] <-22.0)
							{
								JumpReset(id,4);
								return FMRES_IGNORED;
							}
							
							if(height_difference[id] > -18.0)
							{
								if(height_difference[id] <= -1.0)
								{
									JumpReset(id,5);
									return FMRES_IGNORED;
								}	
							}
						}
						else
						{
							if(height_difference[id] < -1.0)
							{
								if((jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_StandUp_CountJump) && height_difference[id]==-18.0)
								{
									//ColorChat(id, GREEN, "ne reset");
								}
								else
								{	
									JumpReset(id,6);
									return FMRES_IGNORED;	
								}
							}	
						}
						if(jump_type[id]==Type_StandupBhopLongJump)
						{
							if(height_difference[id] > 1.0)
							failed_jump[id]=true; 
						}
						else if(height_difference[id] > 0.0 && jump_type[id]!=Type_Drop_BhopLongJump )
						{
							JumpReset(id,7);
							return FMRES_IGNORED; 
						}
						else if(height_difference[id] > 0.02 && jump_type[id]==Type_Drop_BhopLongJump )
						{
							failed_jump[id]=true; 
						}
					}
					
					if( is_user_ducking(id))
					{
						origin[2]+=18.0;
					}
					
					static Float:distance1;
					if(jump_type[id] == Type_ladder)
					{
						if(floatabs(jumpoff_origin[id][2]-origin[2])>4.0)
						{
							failed_jump[id]=true;
						}
						
						distance1 = get_distance_f( jumpoff_origin[id], origin )+laddist[id];
					}
					else distance1 = get_distance_f( jumpoff_origin[id], origin ) + 32.0;
					
					if( is_user_ducking(id) )
					{
						origin[2]-=18.0;
					}
					
					if( frame_velocity[id][1][0] < 0.0 ) frame_velocity[id][1][0] *= -1.0;
					if( frame_velocity[id][1][1] < 0.0 ) frame_velocity[id][1][1] *= -1.0;
					
					static Float:land_origin[3];
					
					land_origin[2] = frame_velocity[id][0][2] * frame_velocity[id][0][2] + (2 * get_pcvar_float(sv_gravity) * (frame_origin[id][0][2] - origin[2]));
					
					rDistance[0] = (floatsqroot(land_origin[2]) * -1) - frame_velocity[id][1][2];
					rDistance[1] = get_pcvar_float(sv_gravity)*-1;
					
					frame2time = floatdiv(rDistance[0], rDistance[1]);
					if(frame_velocity[id][1][0] < 0 )
					frame_velocity[id][1][0] = frame_velocity[id][1][0]*-1;
					rDistance[0] = frame2time*frame_velocity[id][1][0];
						
					if( frame_velocity[id][1][1] < 0 )
					frame_velocity[id][1][1] = frame_velocity[id][1][1]*-1;
					rDistance[1] = frame2time*frame_velocity[id][1][1];
			
					if( frame_velocity[id][1][2] < 0 )
					frame_velocity[id][1][2] = frame_velocity[id][1][2]*-1;
					rDistance[2] = frame2time*frame_velocity[id][1][2];
					
					if( frame_origin[id][1][0] < origin[0] )
					land_origin[0] = frame_origin[id][1][0] + rDistance[0];
					else
					land_origin[0] = frame_origin[id][1][0] - rDistance[0];
					if( frame_origin[id][1][1] < origin[1] )
					land_origin[1] = frame_origin[id][1][1] + rDistance[1];
					else
					land_origin[1] = frame_origin[id][1][1] - rDistance[1];
					
					if( is_user_ducking(id) )
					{
						origin[2]+=18.0;
						duckstring[id]=true;
					}
			
					land_origin[2] = origin[2];
					
					frame2time += (last_land_time[id]-jumpoff_time[id]);
					
					static Float:distance2;
					if(jump_type[id] == Type_ladder)
					{
						distance2 = get_distance_f( jumpoff_origin[id], land_origin ) +laddist[id];
					}
					else distance2 = get_distance_f( jumpoff_origin[id], land_origin ) + 32.0;
					
					if(failed==true)
					{
						if(jump_type[id] == Type_ladder)
						{
							distance[id] = GetFailedDistance(laddist[id],failed_ducking[id], GRAVITY, jumpoff_origin[id], velocity, failed_origin[id], failed_velocity[id]);
						}
						else distance[id] = GetFailedDistance(32.0,failed_ducking[id], GRAVITY, jumpoff_origin[id], velocity, failed_origin[id], failed_velocity[id]);
					}
					else distance[id] = distance1 > distance2 ? distance2 : distance1; //distance
					
					
					new Float:Landing,bool:land_bug;
					
					if(jump_type[id]!=Type_ladder && distance[id]>64.0)
					{
						new Float:landing_orig[3];
						
						landing_orig=origin;
						landing_orig[2]=landing_orig[2]-36.1;
						
						Landing=LandingCalculate(id,landing_orig,jumpoff_origin[id]);
						if(distance[id]<(jumpblock[id]+edgedist[id]+Landing))
						{
							landing_orig=land_origin;
							landing_orig[2]=landing_orig[2]-36.1;
							
							Landing=LandingCalculate(id,landing_orig,jumpoff_origin[id]);
							Landing=Landing-0.06250;
							land_bug=true;
						}
						else land_bug=false;
					}
					
					if(!uq_noslow && entity_get_float(id,EV_FL_fuser2)==0.0 && jump_type[id] != Type_ladder)
					{
						failed_jump[id]=true;
					}
					if(fps_hight[id] && jump_type[id]!=Type_ladder)
					{
						failed_jump[id]=true;
					}
					if(duckbhop_bug_pre[id])
					{
						failed_jump[id]=true;
					}
					
					new tmp_dist,tmp_min_dist,tmp_maxdist,tmp_mindist_other;
					if(Pmaxspeed != 250.0 && jump_type[id]!=Type_ladder)
					{
						tmp_dist=floatround((250.0-Pmaxspeed)*0.73,floatround_floor);
						
						tmp_min_dist=min_distance-tmp_dist;
						
					}
					else tmp_min_dist=min_distance;
					
					tmp_maxdist=max_distance;
					tmp_mindist_other=min_distance_other;
					
					if(jump_type[id]!=Type_Bhop_In_Duck && jump_type[id]!=Type_Up_Bhop_In_Duck && jump_type[id]!=Type_Up_Stand_Bhop  && jump_type[id] != Type_Up_Bhop && jump_type[id] != Type_ladder && jump_type[id] != Type_Multi_Bhop && jump_type[id]!=Type_DuckBhop && jump_type[id]!=Type_Real_ladder_Bhop)
					{
						if( distance[id] < tmp_min_dist || tmp_maxdist < distance[id] )
						{
							JumpReset(id,8);
							return FMRES_IGNORED;
						}
					}
					else if( jump_type[id] == Type_ladder && (distance[id] > tmp_maxdist || distance[id] < tmp_mindist_other))
					{
						JumpReset(id,9);
						return FMRES_IGNORED;
					}
					else if( (jump_type[id] == Type_Multi_Bhop || jump_type[id]==Type_Real_ladder_Bhop) && (distance[id] > tmp_maxdist || distance[id] < tmp_mindist_other))
					{
						JumpReset(id,10);
						return FMRES_IGNORED;
					}
					else if( (jump_type[id]==Type_Bhop_In_Duck || jump_type[id]==Type_Up_Bhop_In_Duck || jump_type[id]==Type_Up_Stand_Bhop ||  jump_type[id] == Type_Up_Bhop || jump_type[id]==Type_Real_ladder_Bhop)&& (distance[id] > tmp_maxdist || distance[id] < tmp_mindist_other))
					{
						JumpReset(id,11);
						return FMRES_IGNORED;
					}
					else if( jump_type[id]==Type_DuckBhop && (distance[id] > tmp_maxdist || distance[id] < tmp_min_dist-150))
					{
						JumpReset(id,1111);
						return FMRES_IGNORED;
					}
					
					
					
					if( jump_type[id] == Type_LongJump ) 
					{			
						oldjump_type[id]=1;
					}
					else oldjump_type[id]=0;
					
					if(jump_type[id] == Type_LongJump && detecthj[id]==1) 
					{
						jump_type[id] = Type_HighJump;
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_HJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_HJ");
					}
					new Float:kkk;
							
					kkk=1.112*Pmaxspeed;
					
					if((jump_type[id] == Type_LongJump || jump_type[id] == Type_HighJump) && prestrafe[id]>kkk)
					{
						jump_type[id] = Type_Drop_BhopLongJump;
						formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DRBJ");
						formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DRBJ");
					}
					if(touch_somthing[id])
					{
						failed_jump[id]=true;
					}
					if(trigger_protection[id])
					{
						failed_jump[id]=true;
					}
					new wpn,weapon_name[21],weapon_name1[21],clip,ammo;
					
					wpn = get_user_weapon(id,clip,ammo);
					if(wpn)
					{
						get_weaponname(wpn,weapon_name,20);
						get_weaponname(wpn,weapon_name1,20);
						
						replace(weapon_name,20,"weapon_","");
					}
					else formatex(weapon_name,20,"Unknow");
	
					new t_type;
					t_type=0;
					
					switch(jump_type[id])
					{
						case 0: t_type=1;
						case 1: t_type=1;
						case 2: t_type=2;
						case 9: t_type=2;
						case 11:t_type=2;
						case 6: t_type=2;
						case 7: t_type=2;
						case 15: t_type=2;
						case 17: t_type=2;
						case 18: t_type=2;
						case 19: t_type=2;
						case 3: t_type=3;
						case 5: t_type=3;
						case 21: t_type=3;
						case 22: t_type=3;
						case 13: t_type=4;
						case 23: t_type=5;
						case 24:t_type=5;
						case 12: t_type=6;
					}
					
					if(uq_bug==1 && check_for_bug_distance(distance[id],t_type,Pmaxspeed))
					{
						JumpReset(id,2311);
						return FMRES_IGNORED;
					}
					if(uq_bug==1)
					{
						new Float:b_check=2.1;
						
						if(jump_type[id]==Type_ladder)
						{
							b_check=b_check-0.1;
						}
						
						if((maxspeed[id]+prestrafe[id])/distance[id]<b_check)
						{
							JumpReset(id,23451);
							return FMRES_IGNORED;
						}
					}
					new god_dist,leet_dist,holy_dist,pro_dist,good_dist;
					new d_array[5];
					
					d_array=get_colorchat_by_distance(jump_type[id],Pmaxspeed,tmp_dist,dropaem[id],multiscj[id],aircj);
					god_dist=d_array[4];
					leet_dist=d_array[3];
					holy_dist=d_array[2];
					pro_dist=d_array[1];
					good_dist=d_array[0];
					
					new script_dist;
					if(angles_arry[id]>SCRIPTFRAMES && uq_script_detection)
					{
						script_dist=god_dist;
						
						switch(uq_script_work)
						{
							case 0:
								script_dist=good_dist;
							case 1:
								script_dist=pro_dist;
							case 2:
								script_dist=holy_dist;
							case 3:
								script_dist=leet_dist;
							case 4:
								script_dist=god_dist;
						}
					}
					
					new bool:not_save;
					if((jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump) && prestrafe[id]>kkk && !uq_noslow)
					{
						not_save=true;
					}
					else if(prestrafe[id]>Pmaxspeed*1.2 && !uq_noslow)
					{
						not_save=true;
					}
					else not_save=false;
					
					new bool:find_script;
					
					if(strafe_num[id]>4 && angles_arry[id]>SCRIPTFRAMES && uq_script_detection && distance[id]>script_dist && !not_save)
					{
						if(FullJumpFrames[id]>80)
							failed_jump[id]=true;
						else
							find_script=true;
					}
					
					//streifs stat
					sync_[id] = INFO_ZERO;
					strMess[0] = '^0'; //unnecessary?
					strMessBuf[0] = '^0'; //unnecessary?
					strLen = INFO_ZERO;
					badSyncTemp = INFO_ZERO;
					goodSyncTemp = INFO_ZERO;
					new Float:tmpstatspeed[NSTRAFES],Float:tmpstatpoteri[NSTRAFES];
								
					Fulltime = last_land_time[id]-jumpoff_time[id];
					if(strafe_num[id] < NSTRAFES)
					{
						strafe_stat_time[id][0] = jumpoff_time[id];
						strafe_stat_time[id][strafe_num[id]] =last_land_time[id];
						for(jj = 1;jj <= strafe_num[id]; jj++)
						{
							//client_print(id,print_chat,"%d=%d,%d - %d",jj,strafe_stat_sync[id][jj][0],strafe_stat_sync[id][jj][1],strafe_lost_frame[id][jj]);

							time_ = ((strafe_stat_time[id][jj] - strafe_stat_time[id][jj-1])*100) / (Fulltime);
							if ((strafe_stat_sync[id][jj][0]+strafe_stat_sync[id][jj][1]) > 0)
							{
								sync_[id] =(strafe_stat_sync[id][jj][0] * 100)/(strafe_stat_sync[id][jj][0]+strafe_stat_sync[id][jj][1]); //using like a buffer		
							}				
							else
							{
								sync_[id] = 0;
							}
							strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS1", jj, strafe_stat_speed[id][jj][0], strafe_stat_speed[id][jj][1], time_, sync_[id]);
							goodSyncTemp += strafe_stat_sync[id][jj][0];
							badSyncTemp += strafe_stat_sync[id][jj][1];
							tmpstatspeed[jj]=strafe_stat_speed[id][jj][0];
							tmpstatpoteri[jj]=strafe_stat_speed[id][jj][1];
							
							if(tmpstatpoteri[jj]>200)
							{
								if(duckstring[id]==false)
								duckstring[id]=true;
							}
							if(tmpstatpoteri[jj]>200 && Checkframes[id])
							{
								Checkframes[id]=false;
								failed_jump[id]=true;
							}
						}
						//client_print(id,print_chat,"full=%d - %d,%d",FullJumpFrames[id],strafe_stat_sync[id][0][0],strafe_stat_sync[id][0][1]);

						if(strafe_num[id]!=0)
						{
							if (jump_type[id]==Type_ladder && strafe_stat_speed[id][0][0]!=0)
							{	
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS2",strafe_stat_speed[id][0][0]);
							}
							if (duckstring[id]==false)
							{							
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS3");
							}
							if (jump_type[id]==Type_StandupBhopLongJump || jump_type[id]==Type_Up_Stand_Bhop)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS4");
							}
							if(wpn!=29 && wpn!=17 && wpn!=16)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS5",weapon_name);
							}
							
							if(Show_edge[id] && failed_jump[id]==false && jump_type[id]!=Type_ladder && jumpblock[id]<user_block[id][0] && jumpblock[id]>user_block[id][1] && edgedist[id]<100.0 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
							{
								if((jumpblock[id]+Landing+edgedist[id])>(distance[id]+10.0) || Landing<=0.0)
								{
									strLen =strLen+format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS6",jumpblock[id],edgedist[id]);
								}
								else if(land_bug)
								{
									strLen =strLen+format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS7",jumpblock[id],edgedist[id],Landing);
								}
								else strLen =strLen+format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS8",jumpblock[id],edgedist[id],Landing);
							}
							else if(Show_edge[id] && failed_jump[id] && jump_type[id]!=Type_ladder && jumpblock[id]<user_block[id][0] && jumpblock[id]>user_block[id][1] && edgedist[id]<100.0 && edgedist[id]!=0.0)
							{
								strLen =strLen+format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS9",jumpblock[id],edgedist[id]);
							}
							else if(Show_edge_Fail[id] && failed_jump[id] && jump_type[id]!=Type_ladder && edgedist[id]<100.0 && edgedist[id]!=0.0)
							{
								strLen =strLen+format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS10",edgedist[id]);	
							}
							if(jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop_In_Duck)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS11",upheight[id]);
							}
							if(fps_hight[id] && jump_type[id]!=Type_ladder)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS12");
							}
							if(ladderbug[id])
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS13");
								failed_jump[id]=true;
							}
							if(find_ladder[id] && jump_type[id]==Type_DuckBhop)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS14");
								failed_jump[id]=true;
							}
							if(touch_somthing[id])
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS15");
							}
							if(find_script)
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_HUDSTRSTATS16");
								failed_jump[id]=true;
							}
							if(trigger_protection[id])
							{
								strLen += format(strMess[strLen],(40*NSTRAFES)-strLen-1, "%L",LANG_SERVER,"UQSTATS_TRIGGERPROTECT");
							}
						}
					}
					//Sync
					if( goodSyncTemp > 0 ) sync_[id]= (goodSyncTemp*100/(goodSyncTemp+badSyncTemp));
					else sync_[id] = INFO_ZERO;
					
					switch( jump_type[id] )
					{
						case 0: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE1"); //Lj
						case 1: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE2" ); //hj
						case 2: 
						{
							if(CjafterJump[id]==1)
							{
								if(ddforcjafterbhop[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE3" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_CJAB");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_CJAB");
								}
								else if(ddforcjafterladder[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE4" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_CJAL");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_CJAL");
								}
								else
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE5" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_CJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_CJAJ");
								}
							}
							else formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE6" ); //cj
						}
						case 3: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE7" );//bj
						case 4: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE8" );//??
						case 5: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE9" );//sbj
						case 6: 
						{
							if(ddbeforwj[id]==false)
							{
								formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE10" ); //wj
							}
							else
							{
								formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE11" );
							}
						}
						case 7: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE12" );
						case 9:
						{
							if(CjafterJump[id]==2)
							{
								if(ddforcjafterbhop[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE13" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DCJAB");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DCJAB");
								}
								else if(ddforcjafterladder[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE14" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DCJAL");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DCJAL");
								}
								else
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE15" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DCJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DCJAJ");
								}
							}
							else formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE16" ); //dcj
						}
						case 11: 
						{
							if(CjafterJump[id]==3)
							{
								if(ddforcjafterbhop[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE17" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MCJAB");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MCJAB");
								}
								else if(ddforcjafterladder[id])
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE18" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MCJAL");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MCJAL");
								}
								else
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE19" );
									
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MCJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MCJAJ");
								}
							}
							else formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE20" );//mcj
						}
						case 12: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE21" );//nothing
						case 13: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE22" );//ld
						case 15: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE23" );
						case 16: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE24" );
						case 17: formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE25" );
						case 18:
						{	
							if(multidropcj[id]==0)
							{
								formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE26" );
							}
							else if(multidropcj[id]==1)
							{
								formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE27" );
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DROPDCJ");
							}
							else if(multidropcj[id]==2)
							{
								formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE28" );
								formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DROPMCJ");
							}
						}
						case 19:
						{	if(dropaem[id])
							{
								if(multiscj[id]==0)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE29" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DROPSCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DROPSCJ");
								}
								else if(multiscj[id]==1)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE30" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DROPDSCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DROPDSCJ");
								}
								else if(multiscj[id]==2)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE31" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DROPMSCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DROPMSCJ");
									
								}
							}
							else if(ddstandcj[id])
							{
								if(multiscj[id]==0)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE32" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_SCJAF");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_SCJAF");
								}
								else if(multiscj[id]==1)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE33" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DSCJAF");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DSCJAF");
								}
								else if(multiscj[id]==2)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE34" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MSCJAF");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MSCJAF");
								}
							}
							else
							{
								if(multiscj[id]==0)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE35" );
								}
								else if(multiscj[id]==1)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE36" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DSCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DSCJ");
								}
								else if(multiscj[id]==2)
								{
									formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE37" );
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MSCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MSCJ");
								}
							}
						}
						case 20:formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE38" );
						case 21:formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE39" );
						case 22:formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE40" );
						case 23:formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE41");
						case 24:formatex( type, 32, "%L",LANG_SERVER,"UQSTATS_HUD_JUMPTYPE42");
					}
					//gain
					
					
					
					new Float:gain[33];
					gain[id] = floatsub( maxspeed[id], prestrafe[id] );
			
					if(jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==0 && uq_drsbj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==1 && uq_dscj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==2 && uq_mscj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==0 && uq_dropscj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==1 && uq_dropdscj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==2 && uq_dropmscj==0)
					{
						JumpReset(id,12);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Double_CountJump&& uq_dcj==0)
					{
						JumpReset(id,13);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Multi_CountJump && uq_mcj==0)
					{
						JumpReset(id,14);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_CountJump && uq_cj==0)
					{
						JumpReset(id,15);
						return FMRES_IGNORED;
					}
					else if((jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump) && uq_lj==0)
					{
						JumpReset(id,16);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_ladder && uq_ladder==0)
					{
						JumpReset(id,17);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Bhop_In_Duck && (uq_bhopinduck==0 )) 
					{
						JumpReset(id,18);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_DuckBhop && (uq_duckbhop==0 )) 
					{
						JumpReset(id,18);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Up_Bhop && (uq_upbj==0) ) 
					{
						JumpReset(id,18);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Up_Bhop_In_Duck && (uq_upbhopinduck==0 )) 
					{
						JumpReset(id,18);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_BhopLongJump && uq_bj==0) 
					{
						JumpReset(id,19);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_ladderBhop && uq_ldbj==0)
					{
						JumpReset(id,20);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Real_ladder_Bhop && uq_realldbhop==0)
					{
						JumpReset(id,20);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_WeirdLongJump && uq_wj==0) 
					{
						JumpReset(id,21);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==0 && uq_drcj==0)
					{
						JumpReset(id,22);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==1 && uq_dropdcj==0)
					{
						JumpReset(id,22);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==2 && uq_dropmcj==0)
					{
						JumpReset(id,22);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Drop_BhopLongJump && uq_drbj==0)
					{
						JumpReset(id,23);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_StandupBhopLongJump && uq_sbj==0)
					{
						JumpReset(id,24);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Up_Stand_Bhop && uq_upsbj==0)
					{
						JumpReset(id,24);
						return FMRES_IGNORED;
					}
					else if(jump_type[id]==Type_Multi_Bhop && uq_multibhop==0)
					{
						JumpReset(id,242);
						return FMRES_IGNORED;
					}
					
					for(new i=1;i<NSTRAFES;i++)
					{
						if(tmpstatspeed[i]>40 && jump_type[id]!=Type_ladder && jump_type[id]!=Type_Real_ladder_Bhop && jump_type[id]!=Type_Slide)
						{
							JumpReset(id,40);
							return FMRES_IGNORED;
						}
					}
					
					if(jump_type[id]==Type_Multi_Bhop && multibhoppre[id]==false)
					{
						g_reset[id]=true;
						return FMRES_IGNORED;
					}
					if(!failed_jump[id] && !not_save)
					{
						new tmp_type_num=-1;
						
						//saving tops
						if(!ddstandcj[id] && !CjafterJump[id] && jump_type[id]!=Type_None && jump_type[id]!=Type_Null && jump_type[id]!=Type_Nothing && jump_type[id]!=Type_Nothing2 && Pmaxspeed==250.0 && kz_top==1 && kz_map_top==1)
						{
							checkmap( id, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],Jtype1[id]); 
						}
						
						if(!CjafterJump[id] && jump_type[id]==Type_Double_CountJump && kz_top==1 && uq_dcj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[10],10, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[10],10, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[6],6, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
									
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[6],6,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"doublecj_top");
								tmp_type_num=10;
							}
						}
						else if(!CjafterJump[id] && jump_type[id]==Type_Multi_CountJump && kz_top==1 && uq_mcj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops2( id,Type_List[21],21, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],ducks[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[21],21, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[7],7, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
									
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[7],7,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"multicj_top");
								tmp_type_num=21;
							}
						}
						else if(!CjafterJump[id] && jump_type[id]==Type_CountJump && kz_top==1 && uq_cj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[2],2, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[2],2, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[1],1, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
									
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[1],1,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"cj_top");
								tmp_type_num=2;
							}
						}
						else if((jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump) && kz_top==1 && uq_lj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[0],0, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										if(jump_type[id]==Type_HighJump)
										{
											checktops_block( id,"hj",6, distance[id], edgedist[id], jumpblock[id]); 
										}
										else checktops_block( id,Type_List[0],0, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[0],0, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
								
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										if(jump_type[id]==Type_HighJump)
										{
											checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),"hj",9,distance[id],edgedist[id],jumpblock[id],weapon_name); 
										}
										else checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[0],0,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"lj_top");
								tmp_type_num=0;
							}
						}
						else if(jump_type[id]==Type_ladder && kz_top==1 && uq_ladder==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[6],6, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
								}
								
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"ladder_top");
								tmp_type_num=6;
							}
						}
						else if(jump_type[id]==Type_BhopLongJump && kz_top==1 && uq_bj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[4],4, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[4],4, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[3],3, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
								
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[3],3,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"bj_top");
								tmp_type_num=4;
							}
						}
						else if(jump_type[id]==Type_ladderBhop && kz_top==1 && uq_ldbj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0) 
								{
									checktops1( id,Type_List[7],7, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[7],7, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"ladderbhop_top");
								tmp_type_num=7;
							}
						}
						else if(jump_type[id]==Type_WeirdLongJump && kz_top==1 && uq_wj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[3],3, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[3],3, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[2],2, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
									
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[2],2,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"wj_top");
								tmp_type_num=3;
							}
						}
						else if(jump_type[id]==Type_Drop_BhopLongJump && kz_top==1 && uq_drbj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[9],9, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]);  
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[9],9, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[5],5, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
								
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[5],5,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"dropbj_top");
								tmp_type_num=9;
							}
						}
						else if(jump_type[id]==Type_StandupBhopLongJump && kz_top==1 && uq_sbj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[5],5, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]);  
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[5],5, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[4],4, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
								
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[4],4,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"sbj_top");
								tmp_type_num=5;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==0 && kz_extras==1 && kz_top==1 && uq_drsbj==1)
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[1],1, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]);   
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[1],1, distance[id], edgedist[id], jumpblock[id]); 
									}
								
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"scj_top");
								tmp_type_num=1;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==1 && kz_extras==1 && kz_top==1 && uq_dscj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[11],11, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[11],11, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"doublescj_top");
								tmp_type_num=11;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id]==false && multiscj[id]==2 && kz_extras==1 && kz_top==1 && uq_mscj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0) 
								{
									checktops2( id,Type_List[22],22, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],ducks[id]);  
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[22],22, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"multiscj_top");
								tmp_type_num=22;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==0 && kz_extras==1 && kz_top==1 && uq_dropscj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[12],12, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]);  
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[12],12, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"dropscj_top");
								tmp_type_num=12;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==1 && kz_extras==1 && kz_top==1 && uq_dropdscj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[13],13, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[13],13, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"dropdoublescj_top");
								tmp_type_num=13;
							}
						}
						else if(!ddstandcj[id] && jump_type[id]==Type_StandUp_CountJump && dropaem[id] && multiscj[id]==2 && kz_extras==1 && kz_top==1 && uq_dropmscj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops2( id,Type_List[23],23, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],ducks[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[23],23, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"dropmultiscj_top");
								tmp_type_num=23;
							}
						}
						else if(jump_type[id]==Type_DuckBhop && kz_extras==1 && kz_top==1 && uq_duckbhop==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[14],14, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[14],14, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"duckbhop_top");
								tmp_type_num=14;
							}
						}
						else if(jump_type[id]==Type_Bhop_In_Duck && kz_extras==1 && kz_top==1 && uq_bhopinduck==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[15],15, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[15],15, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"bhopinduck_top");
								tmp_type_num=15;
							}
						}
						else if(jump_type[id]==Type_Real_ladder_Bhop && kz_extras==1 && kz_top==1 && uq_realldbhop==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[16],16, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[16],16, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"realladderbhop_top");
								tmp_type_num=16;
							}
						}
						else if(jump_type[id]==Type_Up_Bhop && kz_extras==1 && kz_top==1 && uq_upbj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[17],17, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[17],17, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"upbj_top");
								tmp_type_num=17;
							}
						}
						else if(jump_type[id]==Type_Up_Bhop_In_Duck && kz_extras==1 && kz_top==1 && uq_upbhopinduck==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[19],19, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[19],19, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"upbhopinduck_top");
								tmp_type_num=19;
							}
						}
						else if(jump_type[id]==Type_Up_Stand_Bhop && kz_extras==1 && kz_top==1 && uq_upsbj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[18],18, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[18],18, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"upsbj_top");
								tmp_type_num=18;
							}
						}
						else if(jump_type[id]==Type_Multi_Bhop && kz_extras==1 && kz_top==1 && uq_multibhop==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops2( id,Type_List[24],24, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],bhop_num[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[24],24, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"multibhop_top");
								tmp_type_num=24;
							}
						}
						else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==2 && kz_extras==1 && kz_top==1 && uq_dropmcj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops2( id,Type_List[25],25, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],ducks[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[25],25, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"multidropcj_top");
								tmp_type_num=25;
							}
						}
						else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==1 && kz_extras==1 && kz_top==1 && uq_dropdcj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[20],20, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[20],20, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"doubledropcj_top");
								
								tmp_type_num=20;
							}
						}
						else if(jump_type[id]==Type_Drop_CountJump && multidropcj[id]==0 && kz_top==1 && uq_drcj==1) 
						{
							if(kz_sql==0) 
							{
								if(Pmaxspeed==250.0)
								{
									checktops1( id,Type_List[8],8, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id]); 
									
									if(kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block( id,Type_List[8],8, distance[id], edgedist[id], jumpblock[id]); 
									}
								}
								else if(Pmaxspeed!=250.0 && kz_weapon)
								{
									checktops_weapon( id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[8],8, distance[id], maxspeed[id], prestrafe[id], strafe_num[id], sync_[id],weapon_name); 
								
									if(kz_wpn_block_top && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
									{
										checktops_block_weapon(id,Pmaxspeed,weapon_rank(Pmaxspeed),Type_List_weapon[8],8,distance[id],edgedist[id],jumpblock[id],weapon_name); 
									}
								}
							}
							if(kz_sql==1)
							{
								formatex(sql_JumpType[id],25,"dropcj_top");
								
								tmp_type_num=8;
							}
						}
						
					
						if(tmp_type_num!=-1 && !ddstandcj[id] && !CjafterJump[id] && kz_sql==1 && jump_type[id]!=Type_None && jump_type[id]!=Type_Null && jump_type[id]!=Type_Nothing && jump_type[id]!=Type_Nothing2) 
						{
							if(jumpblock[id]>100 && kz_block_top==1 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
							{
								new cData[6];
								
								cData[0] = floatround(distance[id]*1000000);
								cData[1] = floatround(edgedist[id]*1000000);
								cData[2] = jumpblock[id];
								
								if(jump_type[id]==Type_HighJump)
								{
									cData[3]=6;
								}
								else cData[3] = tmp_type_num;
								
								cData[4] = Pmaxspeed;
								cData[5] = wpn;
								
								PlayerSaveData_to_SQL_block(id, cData);
							}
							
							new cData[9];
							cData[0] = floatround(distance[id]*1000000);
							cData[1] = floatround(maxspeed[id]*1000000);
							cData[2] = floatround(prestrafe[id]*1000000);
							cData[3] = strafe_num[id];
							cData[4] = sync_[id];
							
							
							if(jump_type[id]==Type_Multi_Bhop)
							{
								cData[5]=bhop_num[id];
							}
							else cData[5] = ducks[id];
							
							cData[6] = tmp_type_num;
							cData[7] = Pmaxspeed;
							cData[8] = wpn;
							
							PlayerSaveData_to_SQL(id, cData);
						}
					}
					
			
					if(kz_stats_pre[id]==true)//ducks stat for mcj
					{
						strM[0] = '^0'; 
						strMBuf[0] = '^0'; 
						strL = INFO_ZERO;
						for(jj = 2;jj <= ducks[id]; jj++)
						{
							strL += format(strM[strL],(40*NSTRAFES)-strL-1, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT8", jj-1,statsduckspeed[id][jj]);
						}
						copy(strMBuf,strL,strM);//dlya stat ducks
					}
					if(uq_istrafe)
					{
						new st1[NSTRAFES],st2[NSTRAFES];
						for(new i = 1;i <= strafe_num[id]; i++)
						{
							if(i<NSTRAFES)
							{
								st1[i]=strafe_stat_sync[id][i][0];
								st2[i]=strafe_stat_sync[id][i][1];
							}
						}
						
						for( new i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{
								if(ingame_strafe[i])
								{
									new Float:or[3];
									pev(id,pev_origin,or);
									
									remove_beam_ent(i);
									
									epta(i,or,direct_for_strafe[id],line_lost[id],FullJumpFrames[id],is_user_ducking(id),strafe_num[id],st1,st2,strafe_lost_frame[id]);
								}
							}
						}
					}
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]) && g_lj_stats[i]==true)
						{	
							copy(strMessBuf,strLen,strMess);
							//stats
							if(jump_type[id]==Type_Multi_Bhop &&!failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats  );	
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT1", type, distance[id], maxspeed[id], gain[id], prestrafe[id],strafe_num[id], sync_[id],bhop_num[id]);
							}
							else if((jump_type[id]==Type_Double_CountJump || (multiscj[id]==1 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==1 && jump_type[id] == Type_Drop_CountJump)) &&!failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );	
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT2", type, distance[id], maxspeed[id], gain[id], prest1[id],prest[id], prestrafe[id],strafe_num[id], sync_[id],dd_sync[id]);
							}
							else if((jump_type[id]==Type_ladderBhop || jump_type[id]==Type_ladder || jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_WeirdLongJump || jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump) &&!failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats  );	
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT0", type, distance[id], maxspeed[id], gain[id], prestrafe[id],strafe_num[id], sync_[id]);
							}
							else if((jump_type[id]==Type_CountJump || (multiscj[id]==0 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==0 && jump_type[id] == Type_Drop_CountJump)) && !failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats);
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT4", type, distance[id], maxspeed[id], gain[id], prest1[id],prestrafe[id],strafe_num[id], sync_[id],dd_sync[id]);
							}
							else if((jump_type[id]==Type_Bhop_In_Duck || jump_type[id]==Type_Up_Bhop_In_Duck || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_Real_ladder_Bhop || jump_type[id]==Type_DuckBhop || jump_type[id] == Type_BhopLongJump || jump_type[id] == Type_StandupBhopLongJump ) && !failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats);
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT0", type, distance[id], maxspeed[id], gain[id],prestrafe[id],strafe_num[id], sync_[id]);
							}
							else if((jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump)) && !failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT6", type, distance[id], maxspeed[id], gain[id], prest1[id],prestrafe[id],ducks[id], strafe_num[id], sync_[id],dd_sync[id]);
							}
							
							if(jump_type[id] != Type_Slide && streifstat[id]==true && jump_type[id]!=Type_None && !failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, strafe_x, strafe_y, 0, 6.0, 2.5, 0.1, 0.3, h_streif);
								show_hudmessage(i,"%L",LANG_SERVER,"UQSTATS_HUD_PRINT7",strMessBuf); //stata streifof
							}
							
							if(kz_stats_pre[id]==true && (jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump)) && !failed_jump[id])
							{
								set_hudmessage(stats_r, stats_g, stats_b, duck_x,duck_y, 0, 6.0, 2.5, 0.1, 0.3, h_duck);	
								show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT7",strMBuf);//stata duckov
							}
							
							//failstats
							if(jump_type[id]==Type_Multi_Bhop  && (failed_jump[id]))
							{
								set_hudmessage( f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT1", type, distance[id], maxspeed[id], gain[id], prestrafe[id],strafe_num[id], sync_[id],bhop_num[id]);
							}
							else if((jump_type[id]==Type_ladderBhop || jump_type[id]==Type_ladder || jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_WeirdLongJump || jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump)  && (failed_jump[id]))
							{
								set_hudmessage( f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT0", type, distance[id], maxspeed[id], gain[id], prestrafe[id],strafe_num[id], sync_[id]);
							}
							else if((jump_type[id]==Type_CountJump || (multiscj[id]==0 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==0 && jump_type[id] == Type_Drop_CountJump)) && (failed_jump[id]))
							{
								set_hudmessage(f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT4", type, distance[id], maxspeed[id], gain[id], prest1[id],prestrafe[id],strafe_num[id], sync_[id],dd_sync[id]);
							}
							else if((jump_type[id]==Type_Bhop_In_Duck || jump_type[id]==Type_Up_Bhop_In_Duck || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_Real_ladder_Bhop || jump_type[id]==Type_DuckBhop || jump_type[id] == Type_BhopLongJump || jump_type[id] == Type_StandupBhopLongJump ) && (failed_jump[id]))
							{
								set_hudmessage(f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT0", type, distance[id], maxspeed[id], gain[id], prestrafe[id],strafe_num[id], sync_[id]);
							}
							else if((jump_type[id]==Type_Double_CountJump || (multiscj[id]==1 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==1 && jump_type[id] == Type_Drop_CountJump)) && (failed_jump[id]))
							{
								set_hudmessage( f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT2", type, distance[id], maxspeed[id], gain[id], prest1[id],prest[id], prestrafe[id],strafe_num[id], sync_[id],dd_sync[id]);
							}
							else if((jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump)) && (failed_jump[id]))
							{
								set_hudmessage(f_stats_r, f_stats_g, f_stats_b, stats_x, stats_y, 0, 6.0, 2.5, 0.1, 0.3, h_stats );
								show_hudmessage( i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT6", type, distance[id], maxspeed[id], gain[id], prest1[id],prestrafe[id],ducks[id],strafe_num[id], sync_[id],dd_sync[id]);
							}
													
							if(jump_type[id] != Type_Slide && streifstat[id]==true && jump_type[id]!=Type_None && (failed_jump[id]))
							{
								set_hudmessage(f_stats_r, f_stats_g, f_stats_b, strafe_x, strafe_y, 0, 6.0, 2.5, 0.1, 0.3, h_streif );
								show_hudmessage(i,"%L",LANG_SERVER,"UQSTATS_HUD_PRINT7",strMessBuf);  //stata streifof fail
							}
							
							if(kz_stats_pre[id]==true && (jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump)) && (failed_jump[id]))
							{
								set_hudmessage(f_stats_r, f_stats_g, f_stats_b, duck_x,duck_y, 0, 6.0, 2.5, 0.1, 0.3, h_duck);	
								show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_HUD_PRINT7",strMBuf); //stata duckov fail
							}					
						}
					}
					
					//console prints
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]) && g_lj_stats[i]==true)
						{
							copy(strMessBuf,strLen,strMess);
							if((jump_type[id]==Type_ladderBhop || jump_type[id]==Type_ladder || jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_WeirdLongJump || jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump) )
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT1", type, distance[id], maxspeed[id], gain[id], prestrafe[id], strafe_num[id],sync_[id] );
							}
							else if(jump_type[id]==Type_Multi_Bhop )
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT2", type, distance[id], maxspeed[id], gain[id], prestrafe[id], strafe_num[id],sync_[id] ,bhop_num[id]);
							
							}
							else if(jump_type[id]==Type_CountJump || (multiscj[id]==0 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==0 && jump_type[id] == Type_Drop_CountJump))
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT3", type, distance[id], maxspeed[id], gain[id], prest1[id], prestrafe[id], strafe_num[id],sync_[id],dd_sync[id] );
							}
							else if(jump_type[id]==Type_Bhop_In_Duck || jump_type[id]==Type_Up_Bhop_In_Duck || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_Real_ladder_Bhop || jump_type[id]==Type_DuckBhop || jump_type[id] == Type_BhopLongJump || jump_type[id] == Type_StandupBhopLongJump)
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT1", type, distance[id], maxspeed[id], gain[id], prestrafe[id], strafe_num[id],sync_[id] );
							}
							else if(jump_type[id]==Type_Double_CountJump || (multiscj[id]==1 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==1 && jump_type[id] == Type_Drop_CountJump))
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT4", type, distance[id], maxspeed[id], gain[id], prest1[id],prest[id], prestrafe[id], strafe_num[id],sync_[id],dd_sync[id] );
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT5",dd_sync[id]);
							
							}
							else if(jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump))
							{
								client_print( i, print_console, " ");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT6", type, distance[id], maxspeed[id], gain[id], prest1[id],prestrafe[id],ducks[id],strafe_num[id], sync_[id]);
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT5",dd_sync[id]);
							
							}
							
							if(jump_type[id]!=Type_None)
							{
								static strMessHalf[40];
								for(jj=INFO_ONE; (jj <= strafe_num[id]) && (jj < NSTRAFES);jj++)
								{
										strtok(strMessBuf,strMessHalf,40,strMessBuf,40*NSTRAFES,'^n');
										replace(strMessHalf,40,"^n","");
										client_print(i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT7", strMessHalf);
								}
							}
							
							if(jump_type[id]==Type_ladder && strafe_stat_speed[id][0][0]!=0)
							{
								client_print(i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT12", strafe_stat_speed[id][0][0]);
							}
							else if(jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id] == Type_Drop_CountJump))
							{
								client_print( i, print_console, "..................................................");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT8",prest1[id]);
								for(new ss=2;ss<=ducks[id];ss++)
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT9",ss-1,statsduckspeed[id][ss]);
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT10",prestrafe[id]);
								client_print( i, print_console, "..................................................");
							}
							else if(jump_type[id]==Type_Double_CountJump || (multiscj[id]==1 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==1 && jump_type[id] == Type_Drop_CountJump))
							{
								client_print( i, print_console, "..................................................");
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT8",prest1[id]);
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT11",prest[id]);
								client_print( i, print_console, "%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT10",prestrafe[id]);
								client_print( i, print_console, "..................................................");
							}
							else if(jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop_In_Duck)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT13",upheight[id]);
							}
							if(wpn!=29 && wpn!=17 && wpn!=16)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT14",weapon_name);
							}
							if(fps_hight[id] && jump_type[id]!=Type_ladder)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT15");
								fps_hight[id]=false;
							}
							if(ladderbug[id])
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT16");
								ladderbug[id]=false;
							}
							if(find_ladder[id] && jump_type[id]==Type_DuckBhop)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT17");
								find_ladder[id]=false;
							}
							if(touch_somthing[id])
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT18");
							}
							if(Show_edge[id] && failed_jump[id]==false && jump_type[id]!=Type_ladder && jumpblock[id]<user_block[id][0] && jumpblock[id]>user_block[id][1] && edgedist[id]<100.0 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
							{
								if((jumpblock[id]+Landing+edgedist[id])>(distance[id]+10.0) || Landing<=0.0)
								{
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT21",jumpblock[id],edgedist[id]);
								}
								else if(land_bug )
								{
									client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT19",jumpblock[id],edgedist[id],Landing);
								}
								else client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT20",jumpblock[id],edgedist[id],Landing);
							}
							else if(Show_edge[id] && failed_jump[id] && jump_type[id]!=Type_ladder && jumpblock[id]<user_block[id][0] && jumpblock[id]>user_block[id][1] && edgedist[id]<100.0 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT21",jumpblock[id],edgedist[id]);
							}
							else if(Show_edge_Fail[id] && failed_jump[id] && jump_type[id]!=Type_ladder && edgedist[id]<100.0 && edgedist[id]!=0.0)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CONSOLE_PRINT22",edgedist[id]);	
							}
							if(find_script)
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_PROBSCRIPT");
								
							}
							if(trigger_protection[id])
							{
								client_print( i, print_console,"%L",LANG_SERVER,"UQSTATS_CTRIGGERPROTECT");
								trigger_protection[id]=false;
							}
						}
					}
					
					if(wpn==29 || wpn==17 || wpn==16 || wpn==4 || wpn==9 || wpn==25)
					{
						formatex(weapon_name,20,"");
					}
					else
					{
						new tmp_str[21];
						
						formatex(tmp_str,20,"[");
						add(weapon_name, 20, "]");
						add(tmp_str, 20, weapon_name);
						formatex(weapon_name,20,tmp_str);
					}
					
					if(find_script)
					{
						new punishment[64];
						formatex(punishment,63,"%L",LANG_SERVER,"UQSTATS_PUNISHBLOCK");
						
						switch(uq_script_punishment)
						{
							case 1:
							{
								formatex(punishment,63,"%L",LANG_SERVER,"UQSTATS_PUNISHKICK");
							}
							case 2:
							{
								formatex(punishment,63,"%L",LANG_SERVER,"UQSTATS_PUNISHBAN",uq_ban_minutes);
							}
						}
						
						if(jump_type[id]!=Type_None)
						{
							Log_script(FullJumpFrames[id],angles_arry[id],id,distance[id],maxspeed[id],prestrafe[id],strafe_num[id],goodSyncTemp*100/(goodSyncTemp+badSyncTemp),Jtype[id],weapon_name1,punishment,strMess);
					
							switch(uq_script_punishment)
							{
								case 1:
								{
									kick_function(id,Jtype[id]);										
								}
								case 2:
								{
									ban_function(id,Jtype[id]);
								}
							}
						}
					}
					
					
					new block_colorchat_dist;
					if(uq_block_chat_show)
					{
						block_colorchat_dist=god_dist;
						
						switch(uq_block_chat_min)
						{
							case 0:
								block_colorchat_dist=good_dist;
							case 1:
								block_colorchat_dist=pro_dist;
							case 2:
								block_colorchat_dist=holy_dist;
							case 3:
								block_colorchat_dist=leet_dist;
							case 4:
								block_colorchat_dist=god_dist;
						}
					}
					
					new block_str[20];
					
					if(jumpblock[id]>=block_colorchat_dist && uq_block_chat_show && jumpblock[id]<user_block[id][0] && jumpblock[id]>user_block[id][1] && edgedist[id]<100.0 && edgedist[id]!=0.0 && (jumpblock[id]+edgedist[id])<distance[id])
					{
						formatex(block_str,19,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_BLOCK",jumpblock[id]);
					}
					else
					{
						formatex(block_str,19,"");
					}
					
					new iPlayers[32],iNum; 
					get_players( iPlayers, iNum,"ch") ;
					
					for(new i=0;i<iNum;i++) 
					{ 
						new ids=iPlayers[i]; 
						if(gHasColorChat[ids] ==true || ids==id)
						{	
							if( !failed_jump[id] )
							{
								if((jump_type[id]==Type_Bhop_In_Duck || jump_type[id]==Type_Up_Bhop_In_Duck || jump_type[id]==Type_Up_Stand_Bhop || jump_type[id]==Type_Up_Bhop || jump_type[id]==Type_DuckBhop || jump_type[id]==Type_Real_ladder_Bhop || jump_type[id]==Type_Double_CountJump
										     || (multiscj[id]!=2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]!=2 && jump_type[id]==Type_Drop_CountJump) || jump_type[id]==Type_CountJump
										     || jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_BhopLongJump || jump_type[id]==Type_StandupBhopLongJump || jump_type[id]==Type_WeirdLongJump
										     || jump_type[id]==Type_ladderBhop || jump_type[id]==Type_ladder || jump_type[id]==Type_LongJump || jump_type[id]==Type_HighJump))
								{
									if ( distance[id] >= god_dist ) {
										if( uq_sounds && enable_sound[ids]==true )
										{
											client_cmd(ids, "speak misc/mod_godlike");
										}
										if( uq_light ) krasnota(id);
										Color_Chat_Lang(ids, RED, "%L",LANG_SERVER,"UQSTATS_CCHAT_NORMALA",prefix, g_playername[id], distance[id],Jtype[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= leet_dist  ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/mod_wickedsick");
									
										if( uq_light ) krasnota(id);
										Color_Chat_Lang(ids, RED, "%L",LANG_SERVER,"UQSTATS_CCHAT_NORMALA",prefix, g_playername[id], distance[id],Jtype[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= holy_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/holyshit");
									
										if( uq_light ) sineva(id);
										Color_Chat_Lang(ids, BLUE, "%L",LANG_SERVER,"UQSTATS_CCHAT_NORMALA",prefix, g_playername[id], distance[id],Jtype[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= pro_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/perfect");
									
										Color_Chat_Lang(ids, GREEN, "%L",LANG_SERVER,"UQSTATS_CCHAT_NORMALB",prefix, g_playername[id], distance[id],Jtype[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >=good_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/impressive");
									
										Color_Chat_Lang(ids, GREY, "%L",LANG_SERVER,"UQSTATS_CCHAT_NORMALA",prefix, g_playername[id], distance[id],Jtype[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
								}
								else if(jump_type[id]==Type_Multi_CountJump || (multiscj[id]==2 && jump_type[id]==Type_StandUp_CountJump) || (multidropcj[id]==2 && jump_type[id]==Type_Drop_CountJump))
								{
									if ( distance[id] >= god_dist ) {
										if( uq_sounds && enable_sound[ids]==true )
										{
											client_cmd(ids, "speak misc/mod_godlike");
										}
										if( uq_light ) krasnota(id);
										Color_Chat_Lang(ids,RED,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_MULTIDUCKA",prefix, g_playername[id], distance[id],Jtype[id],ducks[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= leet_dist  ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/mod_wickedsick");
									
										if( uq_light ) krasnota(id);
										Color_Chat_Lang(ids,RED,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_MULTIDUCKA",prefix, g_playername[id], distance[id],Jtype[id],ducks[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= holy_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/holyshit");
									
										if( uq_light ) sineva(id);
										Color_Chat_Lang(ids,BLUE,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_MULTIDUCKA",prefix, g_playername[id], distance[id],Jtype[id],ducks[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >= pro_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/perfect");
									
										Color_Chat_Lang(ids,GREEN,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_MULTIDUCKB",prefix, g_playername[id], distance[id],Jtype[id],ducks[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
									else if ( distance[id] >=good_dist ) {
										if( uq_sounds && enable_sound[id]==true ) client_cmd(id, "speak misc/impressive");
									
										Color_Chat_Lang(ids,GREY,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_MULTIDUCKA",prefix, g_playername[id], distance[id],Jtype[id],ducks[id],block_str,weapon_name,pre_type[id],airacel[id]);
									}
								}
							}	
						}
					}
					
					// UberBeam start
					if( kz_beam[id]==true)
						{
						for( new i = 0; i < 100; i++ ) {
							if( gBeam_points[id][i][0] == 0.0
							&& gBeam_points[id][i][1] == 0.0
							&& gBeam_points[id][i][2] == 0.0 ) {
								continue;
							}
						
							message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id);
							write_byte ( TE_BEAMPOINTS );
							if( i == 100 ) {
								write_coord(floatround(gBeam_points[id][i][0]));
								write_coord(floatround(gBeam_points[id][i][1]));
								write_coord(floatround(jumpoff_origin[id][2]-34.0));
								write_coord(floatround(land_origin[0]));
								write_coord(floatround(land_origin[1]));
								write_coord(floatround(jumpoff_origin[id][2]-34.0));
							} else {
								if ( i > 2 ) {
									write_coord(floatround(gBeam_points[id][i-1][0]));
									write_coord(floatround(gBeam_points[id][i-1][1]));
									write_coord(floatround(jumpoff_origin[id][2]-34.0));
								} else {
									write_coord(floatround(jumpoff_origin[id][0]));
									write_coord(floatround(jumpoff_origin[id][1]));
									write_coord(floatround(jumpoff_origin[id][2]-34.0));
								}
								write_coord(floatround(gBeam_points[id][i][0]));
								write_coord(floatround(gBeam_points[id][i][1]));
								write_coord(floatround(jumpoff_origin[id][2]-34.0));
							}
							write_short(gBeam);
							write_byte(1);
							write_byte(5);
							write_byte(30);
							write_byte(20);
							write_byte(0);
							if(gBeam_duck[id][i])
							{
								
								write_byte(255);
								write_byte(0);
								write_byte(0);
							}
							else if(beam_type[id]==2 && gBeam_button[id][i])
							{
								if(gBeam_button_what[id][i]==1)
								{
									write_byte(0);
									write_byte(255);
									write_byte(0);
								}
								else if(gBeam_button_what[id][i]==2)
								{
									write_byte(0);
									write_byte(0);
									write_byte(255);
								}
							}
							else 
							{
								write_byte(255);
								write_byte(255);
								write_byte(0);
							}
							write_byte(200);
							write_byte(200);
							message_end();
							
						}
					}
					
					JumpReset(id,25);
			
				}
				
				new bool:posible_dropcj;
				if(button & IN_DUCK && !(oldbuttons &IN_DUCK) && (jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_WeirdLongJump))
				{
					new Float:tmpdropcj_start[3],Float:tmpdropcj_end[3],Float:tmpdropcj_frame[3];
					pev(id, pev_origin, origin);
					
					tmpdropcj_start=origin;
					tmpdropcj_start[2]=tmpdropcj_start[2]-36.0;
					
					tmpdropcj_end=tmpdropcj_start;
					tmpdropcj_end[2]=tmpdropcj_end[2]-20;
					
					engfunc(EngFunc_TraceLine,origin,tmpdropcj_end, IGNORE_GLASS, id, 0); 
					get_tr2( 0, TR_vecEndPos, tmpdropcj_frame);
					
					if(tmpdropcj_start[2]-tmpdropcj_frame[2]<=18.0)
					{
						posible_dropcj=true;
						in_duck[id]=false;
					}
					else posible_dropcj=false;
					
				}
				
				if(!in_air[id] && button & IN_DUCK && !(oldbuttons &IN_DUCK) && (flags & FL_ONGROUND || posible_dropcj) && !in_duck[id] && UpcjFail[id]==false)
				{	
					if( get_gametime( ) - duckoff_time[id] < 0.3 )
					{
						started_multicj_pre[id] = true;
						prest[id]= speed[id]; 
						ducks[id]++;
						statsduckspeed[id][ducks[id]]=speed[id];
						new Float:tmporg_z;
						if(is_user_ducking(id))
						{
							tmporg_z=origin[2]+18.0;
						}
						else tmporg_z=origin[2];
						
						if(tmporg_z-first_duck_z[id]>4.0)
						{
							JumpReset(id,654);
							if(dropbhop[id])
								dropbhop[id]=false;
							if(in_ladder[id])
								in_ladder[id]=false;
								
							dropupcj[id]=true;
							
							return FMRES_IGNORED;
						}
						
						for( new i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{
								if(showpre[id]==true && showduck[id]==true)
								{
									set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_DUCKPRE",speed[i]);
								}
							}
						}
					}
					else
					{
						pev(id, pev_origin, origin);
						
						ducks[id]=0;
						prest1[id]= speed[id]; //ground pre
						ducks[id]++;//schetchik duckov
						duckstartz[id]=origin[2];
						statsduckspeed[id][ducks[id]]=speed[id];//dlya vivoda stati po ducka
						
						started_cj_pre[id] = true;
						nextbhop[id]=false;
						bhopaem[id]=false;
						if(first_duck_z[id] && (origin[2]-first_duck_z[id])>4)
						{
							dropupcj[id]=true;
							
							JumpReset(id,655);
							if(dropbhop[id])
								dropbhop[id]=false;
							if(in_ladder[id])
								in_ladder[id]=false;
								
							return FMRES_IGNORED;
						}
						if(ducks[id]==1) 
						{
							if(is_user_ducking(id))
							{
								first_duck_z[id]=origin[2]+18.0;
							}
							else first_duck_z[id]=origin[2];
						}
						if(dropupcj[id]==false && get_gametime()-FallTime[id]<0.3 && (in_ladder[id] || jump_type[id]==Type_ladderBhop || jump_type[id]==Type_Drop_BhopLongJump || jump_type[id]==Type_WeirdLongJump || dropbhop[id]))
						{
							in_ladder[id]=false;
							jump_type[id] = Type_Drop_CountJump;
							formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DRCJ");
							formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DRCJ");
							multidropcj[id]=0;
							dropaem[id]=true;
							
							if(dropbhop[id])
								dropbhop[id]=false;
							if(in_ladder[id])
								in_ladder[id]=false;
						}
						
						for( new i = INFO_ONE; i < max_players; i++ )
						{
							if( (i == id || is_spec_user[i]))
							{
								if(showpre[id]==true && showduck[id]==true)
								{
									set_hudmessage(prest_r,prest_g, prest_b, prest_x, prest_y, 0, 0.0, 0.7, 0.1, 0.1, h_prest);
									show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_DUCKPRE",speed[i]);
								}
							}
						}
					}
					
					in_duck[id] = true;
				}
				else if( !in_air[id] && oldbuttons & IN_DUCK && (flags & FL_ONGROUND || posible_dropcj) && UpcjFail[id]==false)
				{
					if( !is_user_ducking( id ) )
					{	
						in_duck[id] = false;
						if( started_cj_pre[id] )
						{
							started_cj_pre[id] = false;
							
							duckoff_time[id] = get_gametime( );
							duckoff_origin[id] = origin;
							FallTime1[id]=get_gametime();
						
							strafe_num[id] = 0;
							TempSpeed[id] = 0.0;
							
							if(jump_type[id] != Type_Drop_CountJump)
							{
								jump_type[id] = Type_CountJump;
								jump_typeOld[id]=1;			
								if(nextbhop[id] || bhopaem[id])
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_CJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_CJAJ");
									
									CjafterJump[id]=1;
			
									ddafterJump[id]=true;
								}
								else
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_CJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_CJ");
									
									CjafterJump[id]=0;
									ddafterJump[id]=false;
								}
								
							}
							else 
							{
								FallTime[id]=get_gametime();
								multidropcj[id]=0;
								jump_typeOld[id]=1;
							}
						}
						else if( started_multicj_pre[id] )
						{
							started_multicj_pre[id] = false;
							
							duckoff_time[id] = get_gametime( );
							duckoff_origin[id] = origin;
							FallTime1[id]=get_gametime();
							
							strafe_num[id] = 0;
							TempSpeed[id] = 0.0;
							
							if(jump_type[id] != Type_Drop_CountJump)
							{
								jump_type[id] = Type_Double_CountJump;
								jump_typeOld[id]=2;
								if(nextbhop[id] || bhopaem[id])
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DCJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DCJAJ");
									
									CjafterJump[id]=2;
									ddafterJump[id]=true;
								}
								else
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_DCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_DCJ");
									
									CjafterJump[id]=0;
									ddafterJump[id]=false;
								}
							}
							else 
							{	
								multidropcj[id]=1;
								FallTime[id]=get_gametime();
								jump_typeOld[id]=2;
							}
						}
						if(ducks[id]>2)
						{	
							if(jump_type[id] != Type_Drop_CountJump)
							{
								jump_type[id] = Type_Multi_CountJump; //detect mcj
								jump_typeOld[id]=3;
								if(nextbhop[id] || bhopaem[id])
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MCJAJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MCJAJ");
									
									CjafterJump[id]=3;
									ddafterJump[id]=true;
								}
								else
								{
									formatex(Jtype[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE_MCJ");
									formatex(Jtype1[id],32,"%L",LANG_SERVER,"UQSTATS_JTYPE1_MCJ");
									
									CjafterJump[id]=0;
									ddafterJump[id]=false;
								}
							}
							else 
							{	
								multidropcj[id]=2;
								FallTime[id]=get_gametime();
								jump_typeOld[id]=3;
							}	
						}
					}
				}
				
				
				if(flags&FL_ONGROUND && g_Jumped[id]==false && jofon[id] && movetype[id] != MOVETYPE_FLY)
				{
					new Float:new_origin[3],Float:tmpOrigin[3], Float:tmpOrigin2[3];
						
					pev(id,pev_origin,new_origin);
					new_origin[2]=new_origin[2]-36.1;
					
					pev(id, pev_velocity, velocity);
					
					for(new i=0,j=-18;i<3;i++,j=j+18)
					{
						tmpOrigin=new_origin;
						tmpOrigin2=new_origin;
						
						if(velocity[1]>0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							tmpOrigin[1]=new_origin[1]+200;
							tmpOrigin2[1]=new_origin[1]-16;
							
							tmpOrigin[0]=tmpOrigin[0]+j;
							tmpOrigin2[0]=tmpOrigin2[0]+j;
							
						}
						else if(velocity[1]<0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							tmpOrigin[1]=new_origin[1]-200;
							tmpOrigin2[1]=new_origin[1]+16;
							
							tmpOrigin[0]=tmpOrigin[0]+j;
							tmpOrigin2[0]=tmpOrigin2[0]+j;
						}
						else if(velocity[0]>0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							tmpOrigin[0]=new_origin[0]+200;
							tmpOrigin2[0]=new_origin[0]-16;
							
							tmpOrigin[1]=tmpOrigin[1]+j;
							tmpOrigin2[1]=tmpOrigin2[1]+j;
						}
						else if(velocity[0]<0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							tmpOrigin[0]=new_origin[0]-200;
							tmpOrigin2[0]=new_origin[0]+16;
							
							tmpOrigin[1]=tmpOrigin[1]+j;
							tmpOrigin2[1]=tmpOrigin2[1]+j;
						}
						
						new Float:tmpEdgeOrigin[3];
						
						engfunc(EngFunc_TraceLine,tmpOrigin,tmpOrigin2, IGNORE_GLASS, id, 0); 
						get_tr2( 0, TR_vecEndPos, tmpEdgeOrigin);
					
						if(get_distance_f(tmpEdgeOrigin,tmpOrigin2)!=0.0)
						{
							jof[id]=get_distance_f(tmpEdgeOrigin,tmpOrigin2)-0.031250;
						}
					}
				}
				else if(!(flags&FL_ONGROUND) && g_Jumped[id] && edgedone[id]==false && movetype[id] != MOVETYPE_FLY)
				{
					new onbhopblock,bhop_block[1];
					
					find_sphere_class(id,"func_door", 48.0, bhop_block, 1, Float:{0.0, 0.0, 0.0} );
					
					if(bhop_block[0])
					{
						onbhopblock=true;
					}
					else
					{
						onbhopblock=false;
					}
					
					
					new Float:tmpblock[3],tmpjblock[3],Float:new_origin[3],Float:tmpOrigin[3], Float:tmpOrigin2[3];
						
					new_origin=jumpoff_origin[id];
					if(onbhopblock)
					{
						new_origin[2]=new_origin[2]-40.0;
					}
					else new_origin[2]=new_origin[2]-36.1;
					
					pev(id, pev_velocity, velocity);
					
					new block_checking[3];
					
					for(new i=0,j=-18;i<3;i++,j=j+18)
					{
						tmpOrigin=new_origin;
						tmpOrigin2=new_origin;
						tmpblock=new_origin;
						if(velocity[1]>0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							tmpOrigin[1]=new_origin[1]+100;
							tmpOrigin2[1]=new_origin[1]-16;
							
							tmpOrigin[0]=tmpOrigin[0]+j;
							tmpOrigin2[0]=tmpOrigin2[0]+j;
							
							tmpblock[1]=new_origin[1]+uq_maxedge+1;
							tmpblock[0]=tmpblock[0]+j;
						}
						else if(velocity[1]<0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							tmpOrigin[1]=new_origin[1]-100;
							tmpOrigin2[1]=new_origin[1]+16;
							
							tmpOrigin[0]=tmpOrigin[0]+j;
							tmpOrigin2[0]=tmpOrigin2[0]+j;
							
							tmpblock[1]=new_origin[1]-uq_maxedge+1;
							tmpblock[0]=tmpblock[0]+j;
						}
						else if(velocity[0]>0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							tmpOrigin[0]=new_origin[0]+100;
							tmpOrigin2[0]=new_origin[0]-16;
							
							tmpOrigin[1]=tmpOrigin[1]+j;
							tmpOrigin2[1]=tmpOrigin2[1]+j;
							
							tmpblock[0]=new_origin[0]+uq_maxedge+1;
							tmpblock[1]=tmpblock[1]+j;
						}
						else if(velocity[0]<0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							tmpOrigin[0]=new_origin[0]-100;
							tmpOrigin2[0]=new_origin[0]+16;
							
							tmpOrigin[1]=tmpOrigin[1]+j;
							tmpOrigin2[1]=tmpOrigin2[1]+j;
							
							tmpblock[0]=new_origin[0]-uq_maxedge+1;
							tmpblock[1]=tmpblock[1]+j;
						}
						
						new Float:tmpEdgeOrigin[3];
						
						engfunc(EngFunc_TraceLine,tmpOrigin,tmpOrigin2, IGNORE_GLASS, id, 0); 
						get_tr2( 0, TR_vecEndPos, tmpEdgeOrigin);
								
						if(get_distance_f(tmpEdgeOrigin,tmpOrigin2)!=0.0)
						{
							edgedist[id]=get_distance_f(tmpEdgeOrigin,tmpOrigin2)-0.031250;
						}
						
						new Float:tmpblockOrigin[3];
						
						engfunc(EngFunc_TraceLine,tmpEdgeOrigin,tmpblock, IGNORE_GLASS, id, 0); 
						get_tr2( 0, TR_vecEndPos, tmpblockOrigin);
						
						if(get_distance_f(tmpblockOrigin,tmpEdgeOrigin)!=0.0)
						{
							tmpjblock[i]=floatround(get_distance_f(tmpblockOrigin,tmpEdgeOrigin),floatround_floor)+1;
						}
						
						new Float:checkblock1[3],Float:checkblock2[3];
						tmpblockOrigin[2]=tmpblockOrigin[2]-1.0;
						
						checkblock1=tmpblockOrigin;
						
						if(velocity[1]>0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							checkblock1[1]=checkblock1[1]+2.0;
						}
						else if(velocity[1]<0 && floatabs(velocity[1])>floatabs(velocity[0]))
						{
							checkblock1[1]=checkblock1[1]-2.0;
						}
						else if(velocity[0]>0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							checkblock1[0]=checkblock1[0]+2.0;
						}
						else if(velocity[0]<0 && floatabs(velocity[0])>floatabs(velocity[1]))
						{
							checkblock1[0]=checkblock1[0]-2.0;
						}
						
						checkblock2=checkblock1;
						checkblock2[2]=checkblock2[2]+18.0;
						
						new Float:tmpcheckblock[3];
						engfunc(EngFunc_TraceLine,checkblock2,checkblock1, IGNORE_GLASS, id, 0); 
						get_tr2( 0, TR_vecEndPos, tmpcheckblock);
						
						if(floatabs(tmpblockOrigin[2]-tmpcheckblock[2])==0.0)
						{
							block_checking[i]=1;
						}
						
						edgedone[id]=true;
					}
					
					if(tmpjblock[0]!=0 && tmpjblock[0]<=tmpjblock[1] && tmpjblock[0]<=tmpjblock[2])
					{
						if(!block_checking[0])
							jumpblock[id]=tmpjblock[0];
					}
					else if(tmpjblock[1]!=0 && tmpjblock[1]<=tmpjblock[2] && tmpjblock[0]<=tmpjblock[0])
					{
						if(!block_checking[1])
							jumpblock[id]=tmpjblock[1];
					}
					else if(tmpjblock[2]!=0 && tmpjblock[2]<=tmpjblock[1] && tmpjblock[0]<=tmpjblock[0])
					{
						if(!block_checking[2])
							jumpblock[id]=tmpjblock[2];
					}
					else jumpblock[id]=0;
					
					if(equali(mapname,"prochallenge_longjump"))
					{
						jumpblock[id]=jumpblock[id]-1;
					}
					
					new h_jof;
					
					if(jofon[id])
					{
						h_jof=h_speed;
					}
					else h_jof=4;
					
					for( new i = INFO_ONE; i < max_players; i++ )
					{
						if( (i == id || is_spec_user[i]))
						{	
							if(edgedist[i]!=0.0 && (showjofon[i] || jofon[id])) 
							{
								if(edgedist[i]>5.0)
								{
									set_hudmessage(255, 255, 255, -1.0, 0.6, 0, 0.0, 0.7, 0.0, 0.0, h_jof);
								}
								else
								{
									set_hudmessage(255, 0, 0, -1.0, 0.6, 0, 0.0, 0.7, 0.0, 0.0, h_jof);
								}
								show_hudmessage(i, "%L",LANG_SERVER,"UQSTATS_JOF", edgedist[id]);
							}
						}
					}
				}
				
				new Float:checkfall;
				if(jump_type[id]==Type_Drop_CountJump)
				{
					checkfall=0.5;
				}
				else checkfall=0.4;
				
				if(flags&FL_ONGROUND && firstfall_ground[id]==true && get_gametime()-FallTime1[id]>checkfall)
				{
					touch_ent[id]=false;		
					JumpReset(id,26);
					dropbhop[id]=false;
					ddnum[id]=0;
					x_jump[id]=false;
					firstfall_ground[id]=false;
					in_ladder[id]=false;
					nextbhop[id]=false;
					bhopaem[id]=false;
					UpcjFail[id]=false;
					slide_protec[id]=false;
					backwards[id]=false;
					ladderbug[id]=false;
					find_ladder[id]=false;
					touch_somthing[id]=false;
					duckbhop[id]=false;
					dropupcj[id]=false;
					ddstandcj[id]=false;
					ddforcjafterbhop[id]=false;
					ddforcjafterladder[id]=false;
					//if(donehook[id]) ColorChat(id, RED, "reset ground %d %f",jump_type[id],get_gametime()-FallTime1[id]);
					return FMRES_IGNORED;
				}
				
				if(flags&FL_ONGROUND && firstfall_ground[id]==false)
				{
					FallTime1[id]=get_gametime();
					firstfall_ground[id]=true;
				}
				else if(!(flags&FL_ONGROUND) && firstfall_ground[id]==true)
				{
					firstfall_ground[id]=false;
				}
				
				if(flags&FL_ONGROUND && donehook[id] && hookcheck[id]==false)
				{
					timeonground[id]=get_gametime();
					hookcheck[id]=true;
				}
				else if(!(flags&FL_ONGROUND) && donehook[id] && hookcheck[id])
				{
					timeonground[id]=get_gametime()-timeonground[id];
					hookcheck[id]=false;
					
					if(timeonground[id]>0.4)
					donehook[id]=false;
				}
			}
		}
	}
	return FMRES_IGNORED;
}
public kick_function(id,j_type_str[])
{
	new szReason[64];
	formatex(szReason,63,"%L",LANG_SERVER,"UQSTATS_KICKREASON",j_type_str);
	
	emessage_begin( MSG_ONE, SVC_DISCONNECT, _, id );
	ewrite_string( szReason );
	emessage_end( );
}
public ban_function(id,j_type_str[])
{
	new szReason[64];
	formatex(szReason,63,"%s_script",j_type_str);
	
	new ban_authid[64];
	
	switch(uq_ban_authid)
	{
		case 0:
			get_user_name(id,ban_authid,63);
		case 1:
			get_user_ip(id,ban_authid,63,1);
		case 2:
			get_user_authid(id,ban_authid,63);
	}	
	
	switch(uq_ban_type)
	{
		case 0:
		{
			switch(uq_ban_authid)
			{
				case 0:
					server_cmd("amx_ban %s %d %s",ban_authid,uq_ban_minutes,szReason);
				case 1:
					server_cmd("amx_addban %s %d %s",ban_authid,uq_ban_minutes,szReason);
				case 2:
					server_cmd("amx_addban ^"%s^" %d %s",ban_authid,uq_ban_minutes,szReason);
			}
		}
		case 1:
		{
			if(uq_ban_authid==2)
				server_cmd("amx_ban %d ^"%s^" %s",uq_ban_minutes,ban_authid,szReason);
			else if(uq_ban_authid==1 && uq_ban_authid==0)
				server_cmd("amx_ban %d %s %s",uq_ban_minutes,ban_authid,szReason);
		}
	}
}
public ScreenShoot(id)
{
	id=id-15237;
	client_cmd(id,"snapshot");
}

public HamTouch( id, entity )
{
	if ( g_alive[id] )
	{
		static Float:Vvelocity[3];
		pev(id, pev_velocity, Vvelocity);
		if(!equali(mapname,"slide_gs_longjumps") && !equali(mapname,"b2j_slide_longjumps"))
		{
			if(g_Jumped[id] && !(pev(id, pev_flags)&FL_ONGROUND) && floatround(Vvelocity[2], floatround_floor) < 0)
			{
				touch_somthing[id]=true;
			}
		}
	}
}
public fwdTouch(ent, id)
{
	static ClassName[32];
	if( pev_valid(ent) )
	{
		pev(ent, pev_classname, ClassName, 31);
	}
	
	static ClassName2[32];
	if( valid_id(id) )
	{
		pev(id, pev_classname, ClassName2, 31);
	}
	if( equali(ClassName2, "player") )
	{
		if( equali(ClassName, "func_train")
			|| equali(ClassName, "func_conveyor") 
			|| equali(ClassName, "trigger_push") || equali(ClassName, "trigger_gravity"))
		{
			if(valid_id(id))
			{
				touch_ent[id]=true;
				trigger_protection[id]=true;
				JumpReset(id,41);
				set_task(0.4,"JumpReset1", id);
			}
		}
	}
}

////////////////////////////////////////Save Tops///////////////////////////////////
public save_tops(type[],type_num,tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_maxspeed[NTOP+1],tmp_prestrafe[NTOP+1],tmp_strafes[NTOP+1],tmp_sync[NTOP+1],tmp_ddbh[NTOP+1])
{
	new profile[128];
	formatex(profile, 127, "%s/Top10_%s.dat", ljsDir,type);
	
	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	new Data[256];
	new f = fopen(profile, "at");
	for(new i = 0; i < NTOP; i++)
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "name", tmp_names[i]);
		TrieSetString(JumpStat, "authid", tmp_ip[i]);
		TrieSetCell(JumpStat, "distance", tmp_distance[i]);
		TrieSetCell(JumpStat, "maxspeed", tmp_maxspeed[i]);
		TrieSetCell(JumpStat, "prestrafe", tmp_prestrafe[i]);
		TrieSetCell(JumpStat, "strafes", tmp_strafes[i]);
		TrieSetCell(JumpStat, "sync", tmp_sync[i]);
		
		if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
		{
			TrieSetCell(JumpStat, "ddbh", tmp_ddbh[i]);
			formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%d^"^n",tmp_names[i],tmp_ip[i], tmp_distance[i],tmp_maxspeed[i],tmp_prestrafe[i],tmp_strafes[i],tmp_sync[i],tmp_ddbh[i]);	
		}
		else formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%d^"^n",tmp_names[i],tmp_ip[i], tmp_distance[i],tmp_maxspeed[i],tmp_prestrafe[i],tmp_strafes[i],tmp_sync[i]);
		fputs(f, Data);
		
		new tmp_type[33];
		format(tmp_type, 32, "%s_%d_250", type, i);

		TrieSetCell(JData, tmp_type, JumpStat);
	}
	fclose(f);
}
public save_tops_block(type[],type_num,tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_block[NTOP+1],Float:tmp_jumpoff[NTOP+1])
{
	new profile[128];
	formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block,type);
	
	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	new Data[256];
	new f = fopen(profile, "at");
	for(new i = 0; i < NTOP; i++)
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "name", tmp_names[i]);
		TrieSetString(JumpStat, "authid", tmp_ip[i]);
		TrieSetCell(JumpStat, "distance", tmp_distance[i]);
		TrieSetCell(JumpStat, "block", tmp_block[i]);
		TrieSetCell(JumpStat, "jumpoff", tmp_jumpoff[i]);
		
		new tmp_type[33];
		format(tmp_type, 32, "block_%s_%d_250", type, i);

		TrieSetCell(JData_Block, tmp_type, JumpStat);
		
		formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%f^"^n",tmp_names[i],tmp_ip[i],tmp_block[i],tmp_distance[i],tmp_jumpoff[i]);
		fputs(f, Data);
	}
	fclose(f);
}
public save_tops_block_weapon(type[],type_num,wpn_rank,tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_block[NTOP+1],Float:tmp_jumpoff[NTOP+1],tmp_weap_name[NTOP+1][33])
{
	new profile[128];
	formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block_weapon[wpn_rank],type);
	
	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	new Data[256];
	new f = fopen(profile, "at");
	for(new i = 0; i < NTOP; i++)
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "name", tmp_names[i]);
		TrieSetString(JumpStat, "authid", tmp_ip[i]);
		TrieSetCell(JumpStat, "distance", tmp_distance[i]);
		TrieSetCell(JumpStat, "block", tmp_block[i]);
		TrieSetCell(JumpStat, "jumpoff", tmp_jumpoff[i]);
		TrieSetCell(JumpStat, "pspeed", weapon_maxspeed(wpn_rank));
		TrieSetString(JumpStat, "wpn_name", tmp_weap_name[i]);
		
		new tmp_type[33];
		format(tmp_type, 32, "block_%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));

		TrieSetCell(JData_Block, tmp_type, JumpStat);
		
		formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%f^" ^"%s^"^n",tmp_names[i],tmp_ip[i],tmp_block[i],tmp_distance[i],tmp_jumpoff[i],tmp_weap_name[i]);
		fputs(f, Data);
	}
	fclose(f);
}
public save_tops_weapon(type[],type_num,wpn_rank,tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_maxspeed[NTOP+1],tmp_prestrafe[NTOP+1],tmp_strafes[NTOP+1],tmp_sync[NTOP+1],tmp_weap_name[NTOP+1][33])
{
	new profile[128];

	formatex(profile, 127, "%s/Top10_%s.dat",ljsDir_weapon[wpn_rank],type);

	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	new Data[256];
	new f = fopen(profile, "at");
	for(new i = 0; i < NTOP; i++)
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "name", tmp_names[i]);
		TrieSetString(JumpStat, "authid", tmp_ip[i]);
		TrieSetCell(JumpStat, "distance", tmp_distance[i]);
		TrieSetCell(JumpStat, "maxspeed", tmp_maxspeed[i]);
		TrieSetCell(JumpStat, "prestrafe", tmp_prestrafe[i]);
		TrieSetCell(JumpStat, "strafes", tmp_strafes[i]);
		TrieSetCell(JumpStat, "sync", tmp_sync[i]);
		TrieSetCell(JumpStat, "pspeed", weapon_maxspeed(wpn_rank));
		TrieSetString(JumpStat, "wpn_name", tmp_weap_name[i]);
		
		new tmp_type[33];
		format(tmp_type, 32, "%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));

		TrieSetCell(JData, tmp_type, JumpStat);
		
		formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%s^"^n",tmp_names[i],tmp_ip[i], tmp_distance[i],tmp_maxspeed[i],tmp_prestrafe[i],tmp_strafes[i],tmp_sync[i],tmp_weap_name[i]);
		fputs(f, Data);
	}
	fclose(f);
}
public save_maptop()
{
	new profile[128];
	formatex(profile, 127, "%s/Top10_maptop.dat", ljsDir);
	
	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	new Data[256];
	new f = fopen(profile, "at");
	for(new i = 0; i < NTOP; i++)
	{
		formatex(Data, 255, "^"%s^" ^"%s^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%d^" ^"%s^"^n",map_names[i],map_ip[i], map_dist[i],map_maxsped[i],map_prestr[i],map_streif[i],map_syncc[i],map_type[i]);
		fputs(f, Data);
	}
	fclose(f);
}
////////////////////////////////////////Read Tops///////////////////////////////////
public read_tops(type[],type_num)
{
	new profile[128],prodata[256];
	formatex(profile, 127, "%s/Top10_%s.dat", ljsDir,type);
	
	new tmp_names[33],tmp_ip[33];

	new f = fopen(profile, "rt" );
	new i = 0;
	while( !feof(f) && i < (NTOP))
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		fgets(f, prodata, 255);
		new d[25], m[25], p[25], sf[25],s[25];
		new duk[25];
		
		if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
		{
			parse(prodata, tmp_names, 32, tmp_ip, 32,  d, 25, m, 25, p, 25, sf, 25,s, 25, duk, 25);	
		}
		else 
		{
			parse(prodata, tmp_names, 32, tmp_ip, 32,  d, 25, m, 25, p, 25, sf, 25,s, 25);	
		}
				
		TrieSetString(JumpStat, "name", tmp_names);
		TrieSetString(JumpStat, "authid", tmp_ip);
		TrieSetCell(JumpStat, "distance", str_to_num(d));
		TrieSetCell(JumpStat, "maxspeed", str_to_num(m));
		TrieSetCell(JumpStat, "prestrafe", str_to_num(p));
		TrieSetCell(JumpStat, "strafes", str_to_num(sf));
		TrieSetCell(JumpStat, "sync", str_to_num(s));
		
		if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
		{
			TrieSetCell(JumpStat, "ddbh", str_to_num(duk));
		}
		
		new tmp_type[33];
		format(tmp_type, 32, "%s_%d_250", type, i);

		TrieSetCell(JData, tmp_type, JumpStat);
		
		i++;
	}
	fclose(f);
}
public read_tops_block(type[],type_num)
{
	new profile[128],prodata[256];
	
	if(type_num==6)
	{
		formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block);	
	}
	else formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block,type);
	
	new tmp_names[33],tmp_ip[33];
	
	new f = fopen(profile, "rt" );
	new i = 0;
	
	while( !feof(f) && i < (NTOP))
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		fgets(f, prodata, 255);
		new d[25], b[25], j[25];
		
		parse(prodata, tmp_names, 32, tmp_ip, 32,  b, 25, d, 25, j, 25);
		
		TrieSetString(JumpStat, "name", tmp_names);
		TrieSetString(JumpStat, "authid", tmp_ip);
		TrieSetCell(JumpStat, "block", str_to_num(b));
		TrieSetCell(JumpStat, "distance", str_to_num(d));
		TrieSetCell(JumpStat, "jumpoff", str_to_float(j));
		
		
		new tmp_type[33];
		if(type_num==6)
		{
			format(tmp_type, 32, "block_hj_%d_250", i);
		}
		else format(tmp_type, 32, "block_%s_%d_250", type, i);

		TrieSetCell(JData_Block, tmp_type, JumpStat);
		i++;
	}
	fclose(f);
}
public read_tops_block_weapon(type[],type_num,wpn_rank)
{
	new profile[128],prodata[256];
	
	if(type_num==9)
	{
		formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block_weapon[wpn_rank]);	
	}
	else formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block_weapon[wpn_rank],type);
	
	new tmp_names[33],tmp_ip[33],tmp_weap_name[33];
	
	new f = fopen(profile, "rt" );
	new i = 0;
	
	while( !feof(f) && i < (NTOP))
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		fgets(f, prodata, 255);
		new d[25], b[25], j[25];
		
		parse(prodata, tmp_names, 32, tmp_ip, 32,  b, 25, d, 25, j, 25,tmp_weap_name,32);
		
		TrieSetString(JumpStat, "name", tmp_names);
		TrieSetString(JumpStat, "authid", tmp_ip);
		TrieSetCell(JumpStat, "block", str_to_num(b));
		TrieSetCell(JumpStat, "distance", str_to_num(d));
		TrieSetCell(JumpStat, "jumpoff", str_to_float(j));
		TrieSetCell(JumpStat, "pspeed", weapon_maxspeed(wpn_rank));
		TrieSetString(JumpStat, "wpn_name", tmp_weap_name);
		
		new tmp_type[33];
		format(tmp_type, 32, "block_%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));

		TrieSetCell(JData_Block, tmp_type, JumpStat);
		i++;
	}
	fclose(f);
}
public read_tops_weapon(type[],type_num,wpn_rank)
{	
	new profile[128],prodata[256];

	formatex(profile, 127, "%s/Top10_%s.dat",ljsDir_weapon[wpn_rank],type);
	
	new f = fopen(profile, "rt" );
	new i = 0;
	new tmp_names[33],tmp_ip[33],tmp_weap_name[33];
	
	while( !feof(f) && i < (NTOP))
	{
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		fgets(f, prodata, 255);
		new d[25], m[25], p[25], sf[25],s[25];
		
		parse(prodata, tmp_names, 32, tmp_ip, 32,  d, 25, m, 25, p, 25, sf, 25,s, 25,tmp_weap_name,32);
		
		TrieSetString(JumpStat, "name", tmp_names);
		TrieSetString(JumpStat, "authid", tmp_ip);
		TrieSetString(JumpStat, "wpn_name", tmp_weap_name);
		TrieSetCell(JumpStat, "distance", str_to_num(d));
		TrieSetCell(JumpStat, "maxspeed", str_to_num(m));
		TrieSetCell(JumpStat, "prestrafe", str_to_num(p));
		TrieSetCell(JumpStat, "strafes", str_to_num(sf));
		TrieSetCell(JumpStat, "sync", str_to_num(s));
		TrieSetCell(JumpStat, "pspeed", weapon_maxspeed(wpn_rank));
		
		
		new tmp_type[33];
		format(tmp_type, 32, "%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
		TrieSetCell(JData, tmp_type, JumpStat);
		i++;
	}
	fclose(f);
}
////////////////////////////////////////Sort Tops///////////////////////////////////
public checktops1(id,type[],type_num,Float:dd,Float:mm,Float:pp,sf,s) 
{	
	new d,m,p,rb[64];
	
	d=floatround(dd*1000000);// todo: zdelat poproshe)
	m=floatround(mm*1000000);
	p=floatround(pp*1000000);
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}
	
	new tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_maxspeed[NTOP+1],tmp_prestrafe[NTOP+1],tmp_strafes[NTOP+1],tmp_sync[NTOP+1];
		
	for (new i = 0; i < NTOP; i++)
	{
		new Trie:JS;
		new tmp_type[33];
	
		format(tmp_type, 32, "%s_%d_250", type, i);
		
		if(TrieKeyExists(JData, tmp_type))
		{	
			TrieGetCell(JData, tmp_type, JS);
			
			TrieGetString(JS,"name",tmp_names[i],32);
			TrieGetString(JS,"authid",tmp_ip[i],32);
			TrieGetCell(JS, "distance", tmp_distance[i]);
			TrieGetCell(JS, "maxspeed", tmp_maxspeed[i]);
			TrieGetCell(JS, "prestrafe", tmp_prestrafe[i]);
			TrieGetCell(JS, "strafes", tmp_strafes[i]);
			TrieGetCell(JS, "sync", tmp_sync[i]);
			
		}
		//server_print("%s",tmp_ip[i]);
	}
	
	for (new i = 0; i < NTOP; i++)
	{
		if( d > tmp_distance[i] )
		{
			new pos = i;	
			while( !equali(tmp_ip[pos], rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(tmp_ip[j], 32, tmp_ip[j-1]);
				formatex(tmp_names[j], 32, tmp_names[j-1]);
				tmp_distance[j] = tmp_distance[j-1];
				tmp_maxspeed[j] = tmp_maxspeed[j-1];
				tmp_prestrafe[j] = tmp_prestrafe[j-1];
				tmp_strafes[j] = tmp_strafes[j-1];
				tmp_sync[j] = tmp_sync[j-1];
			}
			
			formatex(tmp_ip[i], 32, rb);
			formatex(tmp_names[i], 32, g_playername[id]);
			tmp_distance[i]=d;
			tmp_maxspeed[i] = m;
			tmp_prestrafe[i] = p;
			tmp_strafes[i] = sf;
			tmp_sync[i] = s;
			
			new tmp_ddbh[NTOP+1];
			save_tops(type,type_num,tmp_names,tmp_ip,tmp_distance,tmp_maxspeed,tmp_prestrafe,tmp_strafes,tmp_sync,tmp_ddbh);
			
			client_print(0,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP1",prefix,g_playername[id],(i+1),type,dd);				
			
			if((i+1)<11 && uq_screen==1)
			{
				set_task(0.1,"ScreenShoot", id+15237);
			}
			break;
		}
		else if( equali(tmp_ip[i], rb)) break;	
	}
}

public checktops2(id,type[],type_num,Float:dd,Float:mm,Float:pp,sf,s,duk) 
{	
	new d,m,p,rb[64];
	
	d=floatround(dd*1000000);// todo: zdelat poproshe)
	m=floatround(mm*1000000);
	p=floatround(pp*1000000);
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}
	
	new tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_maxspeed[NTOP+1],tmp_prestrafe[NTOP+1],tmp_strafes[NTOP+1],tmp_sync[NTOP+1],tmp_ddbh[NTOP+1];
		
	for (new i = 0; i < NTOP; i++)
	{
		new Trie:JS;
		new tmp_type[33];
	
		format(tmp_type, 32, "%s_%d_250", type, i);
		
		if(TrieKeyExists(JData, tmp_type))
		{	
			TrieGetCell(JData, tmp_type, JS);
			
			TrieGetString(JS,"name",tmp_names[i],32);
			TrieGetString(JS,"authid",tmp_ip[i],32);
			TrieGetCell(JS, "distance", tmp_distance[i]);
			TrieGetCell(JS, "maxspeed", tmp_maxspeed[i]);
			TrieGetCell(JS, "prestrafe", tmp_prestrafe[i]);
			TrieGetCell(JS, "strafes", tmp_strafes[i]);
			TrieGetCell(JS, "sync", tmp_sync[i]);
			TrieGetCell(JS, "ddbh", tmp_ddbh[i]);
		}
	}
	
	for (new i = 0; i < NTOP; i++)
	{
		if( d > tmp_distance[i] )
		{
			new pos = i;	
			while( !equali(tmp_ip[pos], rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(tmp_ip[j], 32, tmp_ip[j-1]);
				formatex(tmp_names[j], 32, tmp_names[j-1]);
				tmp_distance[j] = tmp_distance[j-1];
				tmp_maxspeed[j] = tmp_maxspeed[j-1];
				tmp_prestrafe[j] = tmp_prestrafe[j-1];
				tmp_strafes[j] = tmp_strafes[j-1];
				tmp_sync[j] = tmp_sync[j-1];
				tmp_ddbh[j] = tmp_ddbh[j-1];
			}
			
			formatex(tmp_ip[i], 32, rb);
			formatex(tmp_names[i], 32, g_playername[id]);
			tmp_distance[i]=d;
			tmp_maxspeed[i] = m;
			tmp_prestrafe[i] = p;
			tmp_strafes[i] = sf;
			tmp_sync[i] = s;
			tmp_ddbh[i] = duk;
			
			save_tops(type,type_num,tmp_names,tmp_ip,tmp_distance,tmp_maxspeed,tmp_prestrafe,tmp_strafes,tmp_sync,tmp_ddbh);
			
			client_print(0,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP1",prefix,g_playername[id],(i+1),type,dd);				
			
			if((i+1)<11 && uq_screen==1)
			{
				set_task(0.1,"ScreenShoot", id+15237);
			}
			break;
		}
		else if( equali(tmp_ip[i], rb)) break;	
	}
}
public checktops_block(id,type[],type_num,Float:dd,Float:jj,bb) 
{	
	new d,rb[64];
	
	d=floatround(dd*1000000);// todo: zdelat poproshe)
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}
	
	new tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_block[NTOP+1],Float:tmp_jumpoff[NTOP+1];
		
	for (new i = 0; i < NTOP; i++)
	{
		new Trie:JS;
		new tmp_type[33];
	
		format(tmp_type, 32, "block_%s_%d_250", type, i);
		
		if(TrieKeyExists(JData_Block, tmp_type))
		{	
			TrieGetCell(JData_Block, tmp_type, JS);
			
			TrieGetString(JS,"name",tmp_names[i],32);
			TrieGetString(JS,"authid",tmp_ip[i],32);
			TrieGetCell(JS, "distance", tmp_distance[i]);
			TrieGetCell(JS, "block", tmp_block[i]);
			TrieGetCell(JS, "jumpoff", tmp_jumpoff[i]);
		}
	}
	
	
	new tmp_dist;
	for (new j = 0; j < NTOP; j++)
	{	
		if(bb==tmp_block[j] && equali(tmp_ip[j],rb))
		{
			tmp_dist=tmp_distance[j];
			break;
		}
		else tmp_dist=0;
	}
	
	for (new i = 0; i < NTOP; i++)
	{
		if( bb >= tmp_block[i] && d>tmp_dist)
		{
			new pos = i;	
			while( !equali(tmp_ip[pos],rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(tmp_ip[j], 32, tmp_ip[j-1]);
				formatex(tmp_names[j], 32, tmp_names[j-1]);
				tmp_distance[j] = tmp_distance[j-1];
				tmp_block[j] = tmp_block[j-1];
				tmp_jumpoff[j] = tmp_jumpoff[j-1];
			}
			
			formatex(tmp_ip[i], 32, rb);
			formatex(tmp_names[i], 32, g_playername[id]);
			tmp_distance[i]=d;
			tmp_block[i] = bb;
			tmp_jumpoff[i] = jj;
			
			
			new oldBlock,start_array;
			oldBlock=tmp_block[0];
			start_array=0;
			
			for (new ii = 0; ii < NTOP; ii++)
			{
				if(tmp_block[ii]!=oldBlock)
				{
					new bool:check=true;
					while(check)
					{
						check=false;
						for(new jjj=start_array;jjj<ii-1;jjj++)
						{
							if(tmp_distance[jjj]<tmp_distance[jjj+1])
							{
								new buf1;
								buf1=tmp_distance[jjj];
								tmp_distance[jjj]=tmp_distance[jjj+1];
								tmp_distance[jjj+1]=buf1;
								
								new Float:buf2;
								buf2=tmp_jumpoff[jjj];
								tmp_jumpoff[jjj]=tmp_jumpoff[jjj+1];
								tmp_jumpoff[jjj+1]=buf2;
								
								new buf3[33];
								formatex(buf3,32,tmp_names[jjj]);
								formatex(tmp_names[jjj],32,tmp_names[jjj+1]);
								formatex(tmp_names[jjj+1],32,buf3);
								
								formatex(buf3,32,tmp_ip[jjj]);
								formatex(tmp_ip[jjj],32,tmp_ip[jjj+1]);
								formatex(tmp_ip[jjj+1],32,buf3);
								
								check=true;
							}
						}
					}
					start_array=ii;
				}
				oldBlock=tmp_block[ii];
			}
			
			save_tops_block(type,type_num,tmp_names,tmp_ip,tmp_distance,tmp_block,tmp_jumpoff);
			
			for (new j = 0; j < NTOP; j++)
			{	
				if(d==tmp_distance[j] && equali(tmp_ip[j],rb))
				{
					client_print(0,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP2",prefix,g_playername[id],(j+1),type,bb);				
				}
			}
			if((i+1)<11 && uq_screen==1)
			{
				set_task(0.1,"ScreenShoot", id+15237);
			}
			break;
		}
		else if( equali(tmp_ip[i], rb)) break;	
	}
}
public checktops_block_weapon(id,pev_max_speed,wpn_rank,type[],type_num,Float:dd,Float:jj,bb,wpn_name[]) 
{	
	new d,rb[64];
	
	d=floatround(dd*1000000);// todo: zdelat poproshe)
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}
	
	new tmp_weap_name[NTOP+1][33],tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_block[NTOP+1],Float:tmp_jumpoff[NTOP+1];
		
	for (new i = 0; i < NTOP; i++)
	{
		new Trie:JS;
		new tmp_type[33];
	
		format(tmp_type, 32, "block_%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
		if(TrieKeyExists(JData_Block, tmp_type))
		{	
			TrieGetCell(JData_Block, tmp_type, JS);
			
			TrieGetString(JS,"name",tmp_names[i],32);
			TrieGetString(JS,"authid",tmp_ip[i],32);
			TrieGetCell(JS, "distance", tmp_distance[i]);
			TrieGetCell(JS, "block", tmp_block[i]);
			TrieGetCell(JS, "jumpoff", tmp_jumpoff[i]);
			TrieGetString(JS, "wpn_name", tmp_weap_name[i],32);
		}
	}
	
	new tmp_dist;
	for (new j = 0; j < NTOP; j++)
	{	
		if(bb==tmp_block[j] && equali(tmp_ip[j],rb))
		{
			tmp_dist=tmp_distance[j];
			break;
		}
		else tmp_dist=0;
	}
	
	for (new i = 0; i < NTOP; i++)
	{
		if( bb >= tmp_block[i] && d>tmp_dist)
		{
			new pos = i;	
			while( !equali(tmp_ip[pos],rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(tmp_ip[j], 32, tmp_ip[j-1]);
				formatex(tmp_names[j], 32, tmp_names[j-1]);
				formatex(tmp_weap_name[j], 32, tmp_weap_name[j-1]);
				tmp_distance[j] = tmp_distance[j-1];
				tmp_block[j] = tmp_block[j-1];
				tmp_jumpoff[j] = tmp_jumpoff[j-1];
			}
			
			formatex(tmp_ip[i], 32, rb);
			formatex(tmp_names[i], 32, g_playername[id]);
			formatex(tmp_weap_name[i], 32, wpn_name);
			tmp_distance[i]=d;
			tmp_block[i] = bb;
			tmp_jumpoff[i] = jj;
			
			
			new oldBlock,start_array;
			oldBlock=tmp_block[0];
			start_array=0;
			
			for (new ii = 0; ii < NTOP; ii++)
			{
				if(tmp_block[ii]!=oldBlock)
				{
					new bool:check=true;
					while(check)
					{
						check=false;
						for(new jjj=start_array;jjj<ii-1;jjj++)
						{
							if(tmp_distance[jjj]<tmp_distance[jjj+1])
							{
								new buf1;
								buf1=tmp_distance[jjj];
								tmp_distance[jjj]=tmp_distance[jjj+1];
								tmp_distance[jjj+1]=buf1;
								
								new Float:buf2;
								buf2=tmp_jumpoff[jjj];
								tmp_jumpoff[jjj]=tmp_jumpoff[jjj+1];
								tmp_jumpoff[jjj+1]=buf2;
								
								new buf3[33];
								formatex(buf3,32,tmp_names[jjj]);
								formatex(tmp_names[jjj],32,tmp_names[jjj+1]);
								formatex(tmp_names[jjj+1],32,buf3);
								
								formatex(buf3,32,tmp_ip[jjj]);
								formatex(tmp_ip[jjj],32,tmp_ip[jjj+1]);
								formatex(tmp_ip[jjj+1],32,buf3);
								
								formatex(buf3,32,tmp_weap_name[jjj]);
								formatex(tmp_weap_name[jjj],32,tmp_weap_name[jjj+1]);
								formatex(tmp_weap_name[jjj+1],32,buf3);
								
								check=true;
							}
						}
					}
					start_array=ii;
				}
				oldBlock=tmp_block[ii];
			}
			
			save_tops_block_weapon(type,type_num,wpn_rank,tmp_names,tmp_ip,tmp_distance,tmp_block,tmp_jumpoff,tmp_weap_name);
			
			for (new j = 0; j < NTOP; j++)
			{	
				if(d==tmp_distance[j] && equali(tmp_ip[j],rb))
				{
					client_print(0,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP3",prefix,g_playername[id],(j+1),type,pev_max_speed,bb);				
				}
			}
			if((i+1)<11 && uq_screen==1)
			{
				set_task(0.1,"ScreenShoot", id+15237);
			}
			break;
		}
		else if( equali(tmp_ip[i], rb)) break;	
	}
}
public checktops_weapon(id,pev_max_speed,wpn_rank,type[],type_num,Float:dd,Float:mm,Float:pp,sf,s,wpn_name[]) 
{	
	new d,m,p,rb[64];
	
	d=floatround(dd*1000000);
	m=floatround(mm*1000000);
	p=floatround(pp*1000000);
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}

	new tmp_weap_name[NTOP+1][33],tmp_names[NTOP+1][33],tmp_ip[NTOP+1][33],tmp_distance[NTOP+1],tmp_maxspeed[NTOP+1],tmp_prestrafe[NTOP+1],tmp_strafes[NTOP+1],tmp_sync[NTOP+1],tmp_wpnrank[NTOP+1];
		
	for (new i = 0; i < NTOP; i++)
	{
		new Trie:JS;
		new tmp_type[33];
	
		format(tmp_type, 32, "%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
		if(TrieKeyExists(JData, tmp_type))
		{	
			TrieGetCell(JData, tmp_type, JS);
			
			TrieGetString(JS,"name",tmp_names[i],32);
			TrieGetString(JS,"authid",tmp_ip[i],32);
			TrieGetCell(JS, "distance", tmp_distance[i]);
			TrieGetCell(JS, "maxspeed", tmp_maxspeed[i]);
			TrieGetCell(JS, "prestrafe", tmp_prestrafe[i]);
			TrieGetCell(JS, "strafes", tmp_strafes[i]);
			TrieGetCell(JS, "sync", tmp_sync[i]);
			TrieGetCell(JS, "pspeed", tmp_wpnrank[i]);
			TrieGetString(JS, "wpn_name", tmp_weap_name[i],32);
		}
	}
	
	for (new i = 0; i < NTOP; i++)
	{
		if( d > tmp_distance[i] )
		{
			new pos = i;

			while( !equali(tmp_ip[pos],rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(tmp_ip[j], 32, tmp_ip[j-1]);
				formatex(tmp_names[j], 32, tmp_names[j-1]);
				formatex(tmp_weap_name[j], 32, tmp_weap_name[j-1]);
				tmp_distance[j] = tmp_distance[j-1];
				tmp_maxspeed[j] = tmp_maxspeed[j-1];
				tmp_prestrafe[j] = tmp_prestrafe[j-1];
				tmp_strafes[j] = tmp_strafes[j-1];
				tmp_sync[j] = tmp_sync[j-1];
			}
			
			formatex(tmp_ip[i], 32, rb);
			formatex(tmp_names[i], 32, g_playername[id]);
			formatex(tmp_weap_name[i], 32, wpn_name);
			tmp_distance[i]=d;
			tmp_maxspeed[i] = m;
			tmp_prestrafe[i] = p;
			tmp_strafes[i] = sf;
			tmp_sync[i] = s;
			
			save_tops_weapon(type,type_num,wpn_rank,tmp_names,tmp_ip,tmp_distance,tmp_maxspeed,tmp_prestrafe,tmp_strafes,tmp_sync,tmp_weap_name);

			client_print(0,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP4",prefix,g_playername[id],(i+1),type,pev_max_speed,dd);				
			
			break;
		}
		else if( equali(tmp_ip[i], rb)) break;	
	}
}
public checkmap(id,Float:dd,Float:mm,Float:pp,sf,s,typ[]) 
{	new d,m,p,rb[64];
	
	d=floatround(dd*1000000);// todo: zdelat poproshe)
	m=floatround(mm*1000000);
	p=floatround(pp*1000000);
	
	switch(rankby) {
		case 0: {
			formatex(rb, 63, "%s", g_playername[id]);
		}
		case 1: {
			formatex(rb, 63, "%s", g_playerip[id]);
		}
		case 2: {
			formatex(rb, 63, "%s", g_playersteam[id]);
		}
	}

	for (new i = 0; i < NTOP; i++)
	{
		if( d > map_dist[i] )
		{
			new pos = i;	
			while( !equali(map_ip[pos],rb) && pos < NTOP )
			{
				pos++;
			}
			
			for (new j = pos; j > i; j--)
			{
				formatex(map_ip[j], 32, map_ip[j-1]);
				formatex(map_names[j], 32, map_names[j-1]);
				map_dist[j] = map_dist[j-1];
				map_maxsped[j] =map_maxsped[j-1];
				map_prestr[j] = map_prestr[j-1];
				map_streif[j] = map_streif[j-1];
				map_syncc[j] = map_syncc[j-1];
				formatex(map_type[j], 32, map_type[j-1]);
			}
			
			formatex(map_ip[i], 32, rb);
			formatex(map_names[i], 32, g_playername[id]);
			map_dist[i]=d;
			map_maxsped[i] = m;
			map_prestr[i] = p;
			map_streif[i] = sf;
			map_syncc[i] = s;
			formatex(map_type[i], 32, typ);
			
			save_maptop();
			
			new iPlayers[32],iNum; 
			get_players( iPlayers, iNum,"ch") ;
			for(new p=0;p<iNum;p++) 
			{ 
				new ids=iPlayers[p]; 
				if(gHasColorChat[ids] ==true)
				{	
					client_print(ids,print_chat,"%L",LANG_SERVER,"UQSTATS_PRINTTOP5",prefix,g_playername[id],(i+1),dd,typ);	
				}
			}
			break;
		}
		else if( equali(map_ip[i], rb)) break;	
	}
}
public fwdPostThink( id ) 
{
	if( g_alive[id] && g_userConnected[id] && g_pBot[id]==false)
	{
		if( g_Jumped[id] ) 
		{
			
			FullJumpFrames[id]++;
			
			static buttonsNew;
			
			static buttons;
			static Float:angle[3];
	
			buttonsNew = pev(id, pev_button);
			buttons = pev(id, pev_button);
			pev(id, pev_angles, angle);
			
			new Float:velocity[3];
			pev(id, pev_velocity, velocity);
			velocity[2] = 0.0;
			
			new Float:fSpeed = vector_length(velocity);
			
			
			if( old_angle1[id] > angle[1] ) {
				turning_left[id] = false;
				turning_right[id] = true;
			}
			else if( old_angle1[id] < angle[1] ) {
				turning_left[id] = true;
				turning_right[id] = false;
			} else {
				turning_left[id] = false;
				turning_right[id] = false;
			}
			//schetchik streifof
			if( !(strafecounter_oldbuttons[id]&IN_MOVELEFT) && buttonsNew&IN_MOVELEFT
			&& !(buttonsNew&IN_MOVERIGHT) && !(buttonsNew&IN_BACK) && !(buttonsNew&IN_FORWARD)
			&& (turning_left[id] || turning_right[id]) )
			{
				preessbutton[id]=true;
				button_what[id]=1;
				
				if(strafe_num[id] < NSTRAFES)
					strafe_stat_time[id][strafe_num[id]] = get_gametime();
				strafe_num[id] += INFO_ONE;
				
				if(strafe_num[id]>0 && strafe_num[id]<100) type_button_what[id][strafe_num[id]]=1;
			}
			else if( !(strafecounter_oldbuttons[id]&IN_MOVERIGHT) && buttonsNew&IN_MOVERIGHT
			&& !(buttonsNew&IN_MOVELEFT) && !(buttonsNew&IN_BACK) && !(buttonsNew&IN_FORWARD)
			&& (turning_left[id] || turning_right[id]) )
			{
				preessbutton[id]=true;
				button_what[id]=2;
				
				if(strafe_num[id] < NSTRAFES)
					strafe_stat_time[id][strafe_num[id]] = get_gametime();
				strafe_num[id] += INFO_ONE;
				
				if(strafe_num[id]>0 && strafe_num[id]<100) type_button_what[id][strafe_num[id]]=1;
			}
			else if( !(strafecounter_oldbuttons[id]&IN_BACK) && buttonsNew&IN_BACK
			&& !(buttonsNew&IN_MOVELEFT) && !(buttonsNew&IN_MOVERIGHT) && !(buttonsNew&IN_FORWARD)
			&& (turning_left[id] || turning_right[id]) )
			{
				preessbutton[id]=true;
				button_what[id]=1;
				
				if(strafe_num[id] < NSTRAFES)
					strafe_stat_time[id][strafe_num[id]] = get_gametime();
				strafe_num[id] += INFO_ONE;
				
				if(strafe_num[id]>0 && strafe_num[id]<100) type_button_what[id][strafe_num[id]]=2;
			}
			else if( !(strafecounter_oldbuttons[id]&IN_FORWARD) && buttonsNew&IN_FORWARD
			&& !(buttonsNew&IN_MOVELEFT) && !(buttonsNew&IN_MOVERIGHT) && !(buttonsNew&IN_BACK)
			&& (turning_left[id] || turning_right[id]) )
			{
				preessbutton[id]=true;
				button_what[id]=2;
		
				if(strafe_num[id] < NSTRAFES)
					strafe_stat_time[id][strafe_num[id]] = get_gametime();
				strafe_num[id] += INFO_ONE;
				
				if(strafe_num[id]>0 && strafe_num[id]<100) type_button_what[id][strafe_num[id]]=2;
			}
			
			if( buttonsNew&IN_MOVERIGHT
			|| buttonsNew&IN_MOVELEFT
			|| buttonsNew&IN_FORWARD
			|| buttonsNew&IN_BACK )
			{	
				//tskFps(id);
				if(strafe_num[id] < NSTRAFES)
				{
					if( fSpeed > speed[id])
					{
						strafe_stat_sync[id][strafe_num[id]][0] += INFO_ONE; 
					}
					else
					{
						strafe_stat_sync[id][strafe_num[id]][1] += INFO_ONE;
						if(uq_istrafe && strafe_num[id]<NSTRAFES && lost_frame_count[id][strafe_num[id]]<NVAR)
							line_lost[id][strafe_num[id]][lost_frame_count[id][strafe_num[id]]]=1;
					}
					
					if(uq_istrafe)
					{
						line_erase[id][strafe_num[id]]=lost_frame_count[id][strafe_num[id]];
						line_erase_strnum[id]=strafe_num[id];
					
						lost_frame_count[id][strafe_num[id]]++;
					}
				}
				
			}
			else if(uq_istrafe && strafe_num[id]<NSTRAFES)
				strafe_lost_frame[id][strafe_num[id]] += INFO_ONE;
			
			if( buttons&IN_MOVERIGHT && (buttons&IN_MOVELEFT || buttons&IN_FORWARD || buttons&IN_BACK) )
				strafecounter_oldbuttons[id] = INFO_ZERO;
			else if( buttons&IN_MOVELEFT && (buttons&IN_FORWARD || buttons&IN_BACK || buttons&IN_MOVERIGHT) )
				strafecounter_oldbuttons[id] = INFO_ZERO;
			else if( buttons&IN_FORWARD && (buttons&IN_BACK || buttons&IN_MOVERIGHT || buttons&IN_MOVELEFT) )
				strafecounter_oldbuttons[id] = INFO_ZERO;
			else if( buttons&IN_BACK && (buttons&IN_MOVERIGHT || buttons&IN_MOVELEFT || buttons&IN_FORWARD) )
				strafecounter_oldbuttons[id] = INFO_ZERO;
			else if( turning_left[id] || turning_right[id] )
				strafecounter_oldbuttons[id] = buttons;
		}
		else
		{	
			if(sync_doubleduck[id])
			{
				new Float:velocity[3];
				pev(id, pev_velocity, velocity);
				velocity[2] = 0.0;
				
				new Float:fSpeed = vector_length(velocity);
				
				if( fSpeed > speed[id])
				{
					doubleduck_stat_sync[id][0]++;
				}
				else
				{
					doubleduck_stat_sync[id][1]++;
				}
			}
		}
	}
}
public get_colorchat_by_distance(JumpType:type_jump,mSpeed,t_dist,bool:drop_a,multiscj_a,aircj)
{
	new dist_array[5];
	
	dist_array[2]=280;
		
	if(type_jump==Type_Double_CountJump || type_jump==Type_Multi_CountJump )
	{	
		dist_array[4]=dcj_god_dist;
		dist_array[3]=dcj_leet_dist;
		dist_array[2]=dcj_holy_dist;
		dist_array[1]=dcj_pro_dist;
		dist_array[0]=dcj_good_dist;
	}
	else if(type_jump==Type_LongJump || type_jump==Type_HighJump)
	{	
		dist_array[4]=lj_god_dist;
		dist_array[3]=lj_leet_dist;
		dist_array[2]=lj_holy_dist;
		dist_array[1]=lj_pro_dist;
		dist_array[0]=lj_good_dist;
	}
	else if(type_jump==Type_ladder)
	{	
		dist_array[4]=ladder_god_dist;
		dist_array[3]=ladder_leet_dist;
		dist_array[2]=ladder_holy_dist;
		dist_array[1]=ladder_pro_dist;
		dist_array[0]=ladder_good_dist;
	}
	else if(type_jump==Type_WeirdLongJump || type_jump==Type_Drop_CountJump || type_jump==Type_ladderBhop)
	{	
		dist_array[4]=wj_god_dist;
		dist_array[3]=wj_leet_dist;
		dist_array[2]=wj_holy_dist;
		dist_array[1]=wj_pro_dist;
		dist_array[0]=wj_good_dist;
	}
	else if(type_jump==Type_BhopLongJump || type_jump==Type_StandupBhopLongJump)
	{	
		dist_array[4]=bj_god_dist;
		dist_array[3]=bj_leet_dist;
		dist_array[2]=bj_holy_dist;
		dist_array[1]=bj_pro_dist;
		dist_array[0]=bj_good_dist;
	}
	else if(type_jump==Type_CountJump)
	{	
		dist_array[4]=cj_god_dist;
		dist_array[3]=cj_leet_dist;
		dist_array[2]=cj_holy_dist;
		dist_array[1]=cj_pro_dist;
		dist_array[0]=cj_good_dist;
	}
	else if(type_jump==Type_Drop_BhopLongJump)
	{	
		dist_array[4]=dbj_god_dist;
		dist_array[3]=dbj_leet_dist;
		dist_array[2]=dbj_holy_dist;
		dist_array[1]=dbj_pro_dist;
		dist_array[0]=dbj_good_dist;
	}
	else if(type_jump==Type_StandUp_CountJump && drop_a==false)
	{	
		if(multiscj_a==0)
		{
			dist_array[4]=scj_god_dist+aircj;
			dist_array[3]=scj_leet_dist+aircj;
			dist_array[2]=scj_holy_dist+aircj;
			dist_array[1]=scj_pro_dist+aircj;
			dist_array[0]=scj_good_dist+aircj;
		}
		else if(multiscj_a==1 || multiscj_a==2)
		{
			dist_array[4]=scj_god_dist+aircj+10;
			dist_array[3]=scj_leet_dist+aircj+10;
			dist_array[2]=scj_holy_dist+aircj+10;
			dist_array[1]=scj_pro_dist+aircj+10;
			dist_array[0]=scj_good_dist+aircj+10;
		}
	}
	else if(type_jump==Type_StandUp_CountJump && drop_a)
	{	
		dist_array[4]=dropscj_god_dist;
		dist_array[3]=dropscj_leet_dist;
		dist_array[2]=dropscj_holy_dist;
		dist_array[1]=dropscj_pro_dist;
		dist_array[0]=dropscj_good_dist;
	}
	else if(type_jump==Type_Bhop_In_Duck || type_jump==Type_Up_Bhop_In_Duck)
	{	
		dist_array[4]=bhopinduck_god_dist;
		dist_array[3]=bhopinduck_leet_dist;
		dist_array[2]=bhopinduck_holy_dist;
		dist_array[1]=bhopinduck_pro_dist;
		dist_array[0]=bhopinduck_good_dist;
	}
	else if(type_jump==Type_Up_Bhop)
	{	
		dist_array[4]=upbj_god_dist;
		dist_array[3]=upbj_leet_dist;
		dist_array[2]=upbj_holy_dist;
		dist_array[1]=upbj_pro_dist;
		dist_array[0]=upbj_good_dist;
	}
	else if(type_jump==Type_Up_Stand_Bhop)
	{	
		dist_array[4]=upsbj_god_dist;
		dist_array[3]=upsbj_leet_dist;
		dist_array[2]=upsbj_holy_dist;
		dist_array[1]=upsbj_pro_dist;
		dist_array[0]=upsbj_good_dist;
	}
	else if(type_jump==Type_Real_ladder_Bhop)
	{	
		dist_array[4]=real_god_dist;
		dist_array[3]=real_leet_dist;
		dist_array[2]=real_holy_dist;
		dist_array[1]=real_pro_dist;
		dist_array[0]=real_good_dist;
	}
	else if(type_jump==Type_DuckBhop)
	{	
		dist_array[4]=duckbhop_god_dist;
		dist_array[3]=duckbhop_leet_dist;
		dist_array[2]=duckbhop_holy_dist;
		dist_array[1]=duckbhop_pro_dist;
		dist_array[0]=duckbhop_good_dist;
	}
	
	if(mSpeed != 250.0 && type_jump!=Type_ladder)
	{
		dist_array[4]=dist_array[4]-t_dist;
		dist_array[3]=dist_array[3]-t_dist;
		dist_array[2]=dist_array[2]-t_dist;
		dist_array[1]=dist_array[1]-t_dist;
		dist_array[0]=dist_array[0]-t_dist;
	}
	return dist_array;
}
public fnSaveBeamPos( client ) {
	if( g_Jumped[client] ) {
		new Float:vOrigin[3];
		pev(client, pev_origin, vOrigin);
		
		if( gBeam_count[client] < 100 ) {
			gBeam_points[client][gBeam_count[client]][0] = vOrigin[0];
			gBeam_points[client][gBeam_count[client]][1] = vOrigin[1];
			gBeam_points[client][gBeam_count[client]][2] = vOrigin[2];
			
			if(preessbutton[client])
			{
				gBeam_button[client][gBeam_count[client]]=true;
				
				if(button_what[client]==1)
				{
					gBeam_button_what[client][gBeam_count[client]]=1;
				}
				else if(button_what[client]==2)
				{
					gBeam_button_what[client][gBeam_count[client]]=2;
				}
			}
			
			if(is_user_ducking( client ))
				gBeam_duck[client][gBeam_count[client]] = true;
			
			gBeam_count[client]++;
		}
	}
}
public JumpReset(id,num)
{
	g_reset[id] = true;
	//if(num!=26 && num!=1 && num!=29)
	//ColorChat(id,GREEN,"jump reset %d",num);
}

public JumpReset1(id)
{
	g_reset[id] = true;
}
public ddReset(id)
{
	id=id-2311;
	JumpReset(id,27);
	//ColorChat(id, GREEN, "reset dd");
}
public Color_Chat_Lang(id,Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	new message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);
	
	replace_colors(message,191);
	
	ColorChat(id, type, "%s",message);
}
public cmdColorChat(id)
{	
	if( !gHasColorChat[id] )
	{
		gHasColorChat[id] = true;
		
		Color_Chat_Lang(id,GREEN,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_E", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagHasColorChat);
	}
	else 
	{
		gHasColorChat[id] = false;
		
		Color_Chat_Lang(id,GREEN,"%L",LANG_SERVER,"UQSTATS_COLORCHAT_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagHasColorChat);
	}
	
	return PLUGIN_CONTINUE;
}
public cmdljStats( id ) {
	
	if(g_lj_stats[id]==true) 
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_LJSTATS_D", prefix);
		g_lj_stats[id]=false;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagLjStats);
		
		if(showpre[id]==true)
		{
			showpre[id]=false;
			oldpre[id]=1;
		}
		if(failearly[id]==true)
		{
			failearly[id]=false;
			oldfail[id]=1;
		}
		if(ljpre[id]==true)
		{
			ljpre[id]=false;
			oldljpre[id]=1;
		}
	}
	else 
	{
		if(oldpre[id]==1)
		{
			showpre[id]=true;
			oldpre[id]=0;
		}
		if(oldfail[id]==1)
		{
			failearly[id]=true;
			oldfail[id]=0;
		}
		if(oldljpre[id]==1)
		{
			ljpre[id]=true;
			oldljpre[id]=0;
		}
		g_lj_stats[id]=true;
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_LJSTATS_E", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagLjStats);
	}

}


public cmdVersion( id )
{		
	Color_Chat_Lang(id,GREY,"%L",LANG_SERVER,"UQSTATS_VERSION_1", prefix,VERSION);
	
	if(kz_sql==1)
	{
		Color_Chat_Lang(id,GREY,"%L",LANG_SERVER,"UQSTATS_VERSION_SQL1", prefix);
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_VERSION_SQL2", prefix);
	}
	else Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_VERSION_2", prefix);
}
public pre_stats(id)
{	
	if(kz_stats_pre[id]==true) 
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_PRESTATS_D", prefix);
		kz_stats_pre[id]=false;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagStatsPre);
	}
	else 
	{
		kz_stats_pre[id]=true;
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_PRESTATS_E", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagStatsPre);
	}
}
public streif_stats(id)
{	
	if(streifstat[id]==true) 
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_STRAFESTATS_D", prefix);
		streifstat[id]=false;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagStrafeStats);
	}
	else 
	{
		streifstat[id]=true;
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_STRAFESTATS_E", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagStrafeStats);
	}
}
public cmdljbeam(id)
{
	if(ingame_strafe[id])
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_BEAMDONTWORK", prefix);
	}
	else
	{
		if(kz_beam[id]==true) 
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_BEAMSTATS_D", prefix);
			kz_beam[id]=false;
			set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagBeam);
		}
		else 
		{
			kz_beam[id]=true;
			Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_BEAMSTATS_E", prefix);
			set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagBeam);
		}
	}

	return PLUGIN_HANDLED;
}
public show_pre(id)
{
	if(showpre[id]==true) 
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SHOWPRE_D", prefix);
		showpre[id]=false;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagShowPre);
	}
	else 
	{
		showpre[id]=true;
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_SHOWPRE_E", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagShowPre);
	}
}
public show_speed(id)
{
	new tmpTeam[33],g_team;	
	get_user_team(id,tmpTeam,32);
	
	if(uq_team==0)
	{
		g_team=0;
	}
	else if(equali(tmpTeam,"TERRORIST"))
	{
		g_team=1;
	}
	else if(equali(tmpTeam,"CT"))
	{
		g_team=2;
	}
	else
	{
		g_team=uq_team;
	}
	
	if(uq_admins==1 && !player_admin[id])
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SPEED_D1", prefix);
	}
	else if(g_team!=uq_team && !uq_speed_allteam)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SPEED_D2", prefix);
	}
	else
	{
		if(jofon[id])
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SPEED_D3", prefix);
		}
		else
		{
			if(speedon[id]==false) 
			{
				Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_SPEED_E", prefix);
				speedon[id]=true;
				set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagShowSpeed);
				
				set_task(0.1, "DoSpeed", id+212299, "", 0, "b", 0);
			}
			else 
			{
				speedon[id]=false;
				set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagShowSpeed);
				
				if( task_exists(id+212299, 0) )
					remove_task(id+212299, 0);
					
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SPEED_D", prefix);
			}
		}
	}
}
public trainer_jof(id)
{
	new tmpTeam[33],g_team;	
	get_user_team(id,tmpTeam,32);
	
	if(uq_team==0)
	{
		g_team=0;
	}
	else if(equali(tmpTeam,"TERRORIST"))
	{
		g_team=1;
	}
	else if(equali(tmpTeam,"CT"))
	{
		g_team=2;
	}
	else
	{
		g_team=uq_team;
	}
	
	if(uq_admins==1 && !player_admin[id])
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JOFTR_D1", prefix);
	}
	else if(g_team!=uq_team)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JOFTR_D2", prefix);
	}
	else
	{
		if(speedon[id])
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JOFTR_D3", prefix);
		}
		else
		{
			if(jofon[id]==false) 
			{
				Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_JOFTR_E", prefix);
				jofon[id]=true;
				jof[id]=0.0;
				set_task(0.1, "Dojof", id+212398, "", 0, "b", 0);
			}
			else 
			{
				jofon[id]=false;
				
				if( task_exists(id+212398, 0) )
					remove_task(id+212398, 0);
					
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JOFTR_D", prefix);
			}
		}
	}
}
public speed_type(id)
{
	if(speedtype[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_SPEED_B", prefix);
		speedtype[id]=true;
	}
	else 
	{
		speedtype[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SPEED_S", prefix);
	}
}
public show_jheight(id)
{
	if(jheight_show[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_JHEIGH_E", prefix);
		jheight_show[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagJumpHeight);
	}
	else 
	{
		jheight_show[id]=false;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagJumpHeight);
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JHEIGH_D", prefix);
	}
}
public show_jof(id)
{
	if(showjofon[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_JOF_E", prefix);
		showjofon[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagJumpOff);
	}
	else 
	{
		showjofon[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_JOF_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagJumpOff);
	}
}
public show_early(id)
{
	if(failearly[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_BHOPWARN_E", prefix);
		failearly[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagFailEarly);
	}
	else 
	{
		failearly[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_BHOPWARN_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagFailEarly);
	}
}
public multi_bhop(id)
{
	if(multibhoppre[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_MULTIBHOP_E", prefix);
		multibhoppre[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagMultiBhopPre);
	}
	else 
	{
		multibhoppre[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_MULTIBHOP_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagMultiBhopPre);
	}
}
public duck_show(id)
{
	if(showduck[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_DUCKSPRE_E", prefix);
		showduck[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagShowDuck);
	}
	else 
	{
		showduck[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_DUCKSPRE_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagShowDuck);
	}
}
public lj_show(id)
{
	if(ljpre[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_LJPRE_E", prefix);
		ljpre[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagLjPre);
	}
	else 
	{
		ljpre[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_LJPRE_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagLjPre);
	}
}
public enable_sounds(id)
{
	if(uq_sounds)
	{
		if(enable_sound[id]==false) 
		{
			Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_SOUND_E", prefix);
			enable_sound[id]=true;
			set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagEnableSounds);
		}
		else 
		{
			enable_sound[id]=false;
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SOUND_D", prefix);
			set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagEnableSounds);
		}
	}
	else Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SOUND_D1", prefix);
}
public ShowedgeFail(id)
{
	if(Show_edge_Fail[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_EDGEF_E", prefix);
		Show_edge_Fail[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagShowEdgeFail);
	}
	else 
	{
		Show_edge_Fail[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_EDGEF_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagShowEdgeFail);
	}
}
public Showedge(id)
{
	if(Show_edge[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_EDGE_E", prefix);
		Show_edge[id]=true;
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagShowEdge);
	}
	else 
	{
		Show_edge[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_EDGE_D", prefix);
		set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagShowEdge);
	}
}
public heightshow(id)
{
	if(height_show[id]==false) 
	{
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_FALLH_E", prefix);
		height_show[id]=true;
	}
	else 
	{
		height_show[id]=false;
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_FALLH_D", prefix);
	}
}
public ingame_st_stats(id)
{
	if(uq_istrafe)
	{
		if(kz_beam[id])
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_ISTRAFE_D1", prefix);
		}
		else
		{
			if(ingame_strafe[id]==false) 
			{
				Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_ISTRAFE_E", prefix);
				ingame_strafe[id]=true;
				set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] | flagIngameStrafes);
			}
			else 
			{
				ingame_strafe[id]=false;
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_ISTRAFE_D", prefix);
				set_option_cell(id, g_Options[optIntJumpStats], g_OptionFlags[id] & ~flagIngameStrafes);
			}
		}
	}
	else Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_ISTRAFE_D2", prefix);
	
}

public client_connect( id )
{
	oldljpre[id]=0;
	oldpre[id]=0;
	oldfail[id]=0;
	g_userConnected[id]=true;
	g_pBot[id]=false;
	
	static connectt[30];
	get_pcvar_string(kz_uq_connect, connectt, 30);
	
	format(connectt, 30, "_%s", connectt);

	if( contain(connectt, "a") > 0 )
		gHasColorChat[id] =true;
	else
		gHasColorChat[id] = false;
	if( contain(connectt, "b") > 0 )
		g_lj_stats[id] = true;
	else
		g_lj_stats[id] = false;
	if( contain(connectt, "c") > 0 )
		speedon[id]=true;
	else 
		speedon[id]=false;
	if( contain(connectt, "d") > 0 )
		showpre[id]=true;
	else
		showpre[id]=false;
	if( contain(connectt, "e") > 0 )
		streifstat[id]=true;
	else
		streifstat[id]=false;
	if( contain(connectt, "f") > 0 )
		kz_beam[id]=true;
	else
		kz_beam[id]=false;
	if( contain(connectt, "g") > 0 )
		kz_stats_pre[id]=true;
	else
		kz_stats_pre[id]=false;
	if( contain(connectt, "h") > 0 )
		failearly[id]=true;
	else
		failearly[id]=false;
	if( contain(connectt, "i") > 0 )
		multibhoppre[id]=true;
	else
		multibhoppre[id]=false;
	if( contain(connectt, "j") > 0 )
		showduck[id]=true;
	else
		showduck[id]=false;
	if( contain(connectt, "k") > 0 )
		ljpre[id]=true;
	else
		ljpre[id]=false;
	if( contain(connectt, "l") > 0 )
		Show_edge[id]=true;
	else
		Show_edge[id]=false;
	if( contain(connectt, "m") > 0 )
		Show_edge_Fail[id]=true;
	else
		Show_edge_Fail[id]=false;
	if( contain(connectt, "n") > 0 )
		enable_sound[id]=true;
	else
		enable_sound[id]=false;
	if( contain(connectt, "o") > 0 )
		ingame_strafe[id]=true;
	else
		ingame_strafe[id]=false;
	
	//for beta
	//ingame_strafe[id]=true;
	
	user_block[id][0]=uq_maxedge;
	user_block[id][1]=uq_minedge;
	min_prestrafe[id]=uq_min_pre;
	beam_type[id]=1;
	edgeshow[id]=true;	
	first_ground_bhopaem[id]=false;
	donehook[id]=false;
	OnGround[id]=false;
	serf_reset[id]=false;
	first_onground[id]=false;
	duckstring[id]=false;
	firstshow[id]=false;
	height_show[id]=false;
	Checkframes[id]=false;
	firstfall_ground[id]=false;
	h_jumped[id]=false;
	touch_ent[id]=false;
	ddafterJump[id]=false;
	ddstandcj[id]=false;
	UpcjFail[id]=false;
	slide_protec[id]=false;
	posibleScj[id]=false;
	x_jump[id]=false;
	ddforcj[id]=false;
	dropbhop[id]=false;
	ddnum[id]=0;
	hookcheck[id]=false;
	backwards[id]=false;
	ladderbug[id]=false;
	touch_somthing[id]=false;
	record_start[id]=0;
	duckbhop_bug_pre[id]=false;
	showtime_st_stats[id]=40;
	speedtype[id]=false;
	trigger_protection[id]=false;
	
	if(is_user_bot(id))
	{
		g_pBot[id]=true;
	}
	
	if( task_exists(id+434490, 0) )
		remove_task(id+434490, 0);
		
	if( task_exists(id, 0) )
		remove_task(id, 0);
	
	if( task_exists(id+89012, 0) )
		remove_task(id+89012, 0);

	if( task_exists(id+3313, 0) )
		remove_task(id+3313, 0);
	
	if( task_exists(id+3214, 0) )
		remove_task(id+3214, 0);
		
	if( task_exists(id+15237, 0) )
		remove_task(id+15237, 0);
		
	if( task_exists(id+212299, 0) )
		remove_task(id+212299, 0);
		
	if( task_exists(id+212398, 0) )
		remove_task(id+212398, 0);
		
	if( task_exists(id, 0) )
		remove_task(id, 0);
	
}


public client_infochanged(id) {
	new name[65];
	
	get_user_info(id, "name", name,64); 
	
	if(!equali(name, g_playername[id]))
		copy(g_playername[id], 64, name);
}

public ResetHUD(id)
{
	if(is_user_alive(id) && !is_user_bot(id) && !is_user_hltv(id) )
	{
		if(firstshow[id]==false)
		{
			if( uq_airaccel==1 || uq_airaccel==100)
			{
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_AIRACCEL100", prefix);
			}
			else if( uq_airaccel==0 || uq_airaccel==10)
			{
				Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_AIRACCEL10", prefix);
			}
			else 
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_AIRACCEL", prefix,uq_airaccel);		
				
			firstshow[id]=true;
			
			if(equali(mapname,"slide_gs_longjumps") || equali(mapname,"b2j_slide_longjumps"))
			{
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_SLIDE", prefix);
			}
		}
		
		firstfall_ground[id]=false;
		h_jumped[id]=false;
		
		ddafterJump[id]=false;
		UpcjFail[id]=false;
		slide_protec[id]=false;
		posibleScj[id]=false;
		x_jump[id]=false;
		ddforcj[id]=false;
		dropbhop[id]=false;
		ddnum[id]=0;
		donehook[id]=false;
		hookcheck[id]=false;
		backwards[id]=false;
		Checkframes[id]=false;
		first_ground_bhopaem[id]=false;
		touch_ent[id]=false;
		ladderbug[id]=false;
		touch_somthing[id]=false;
		ddstandcj[id]=false;
	}
	
}
public FwdPlayerSpawn(id)
{
	if( is_user_alive(id) && !is_user_bot(id) && !is_user_hltv(id))
	{
		// if( !task_exists(id+434490, 0) )
		// 	set_task(1.0, "tskFps", id+434490, "", 0, "b", 0);
			
		g_alive[id] = true;
		strafe_num[id]=0;
	}
}

public FwdPlayerDeath(id)
{
	if( task_exists(id, 0) )
		remove_task(id, 0);
		
	if( task_exists(id+434490, 0) )
		remove_task(id+434490, 0);
		
	if( task_exists(id, 0) )
		remove_task(id, 0);
	
	if( task_exists(id+89012, 0) )
		remove_task(id+89012, 0);
	
	if( task_exists(id+3313, 0) )
		remove_task(id+3313, 0);
	
	if( task_exists(id+3214, 0) )
		remove_task(id+3214, 0);
		
	if( task_exists(id+15237, 0) )
		remove_task(id+15237, 0);
	
	if( task_exists(id+212398, 0) )
		remove_task(id+212398, 0);
		
	g_alive[id] = false;
}

public client_disconnected(id)
{
	if(kz_sql == 1 || kz_sql == 2)
	{
		new tmp_str[12];
		num_to_str(g_sql_pid[id], tmp_str, 11);
		if(TrieKeyExists(JumpPlayers, tmp_str))
			TrieDeleteKey(JumpPlayers, tmp_str);
	}
	
	remove_beam_ent(id);
	
	player_admin[id]=false;
	g_pBot[id]=false;
	login[id]=false;
	g_userConnected[id]=false;
	OnGround[id]=false;
	g_alive[id]=false;
	
	
	if( task_exists(id, 0) )
		remove_task(id);
	
	firstshow[id]=false;
	if( task_exists(id+434490, 0) )
		remove_task(id+434490, 0);
		
	if( task_exists(id, 0) )
		remove_task(id, 0);
	
	if( task_exists(id+89012, 0) )
		remove_task(id+89012, 0);

	if( task_exists(id+3313, 0) )
		remove_task(id+3313, 0);
	
	if( task_exists(id+3214, 0) )
		remove_task(id+3214, 0);
		
	if( task_exists(id+15237, 0) )
		remove_task(id+15237, 0);
		
	if( task_exists(id+212299, 0) )
		remove_task(id+212299, 0);
		
	if( task_exists(id+212398, 0) )
		remove_task(id+212398, 0);
		
	if( task_exists(id, 0) )
		remove_task(id, 0);
}
public reset_tops(id, level, cid)
{	
	if( !cmd_access(id, level, cid, 1) ) return PLUGIN_HANDLED;
	
	if(kz_sql == 0)
	{
		client_print(id,print_console,"%L",LANG_SERVER,"UQSTATS_RESET");
		server_print("%L",LANG_SERVER,"UQSTATS_RESET");
		
		TrieClear(JData);
		TrieClear(JData_Block);
	}
	else if(kz_sql == 1)
	{
		client_print(id,print_console,"%L",LANG_SERVER,"UQSTATS_RESETF");
		server_print("%L",LANG_SERVER,"UQSTATS_RESETF");
	}
		
	return PLUGIN_CONTINUE;
}
public Option(id)
{	
	new MenuBody[512], len, keys;
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU1");
	
	if(g_lj_stats[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU11a");
		keys |= (1<<0);
	}
	else
	{
		keys |= (1<<0);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU11b");
	}
	
	if(gHasColorChat[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU12a");
		keys |= (1<<1);
	}
	else
	{
		keys |= (1<<1);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU12b");
	}
	
	if(speedon[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU13a");
		keys |= (1<<2);
	}
	else
	{
		keys |= (1<<2);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU13b");
	}
	
	if(showpre[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU14a");
		keys |= (1<<3);
	}
	else
	{
		keys |= (1<<3);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU14b");
	}
	
	if(streifstat[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU15a");
		keys |= (1<<4);
	}
	else
	{
		keys |= (1<<4);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU15b");
	}
	
	if(kz_beam[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU16a");
		keys |= (1<<5);
	}
	else
	{
		keys |= (1<<5);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU16b");
	}
	
	if(showduck[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU17a");
		keys |= (1<<6);
	}
	else
	{
		keys |= (1<<6);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU17b");
	}
	if(failearly[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU18a");
		keys |= (1<<7);
	}
	else
	{
		keys |= (1<<7);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU18b");
	}

	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENUNEXT");
	keys |= (1<<8);
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENUEXIT");
	keys |= (1<<9);
	
	show_menu(id, keys, MenuBody, -1, "StatsOptionMenu1");	
}

public OptionMenu1(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			cmdljStats(id);
			Option(id);
			
		}
		case 2:
		{
			cmdColorChat(id);
			Option(id);
		}
		case 3:
		{
			show_speed(id);
			Option(id);
		}
		case 4:
		{
			show_pre(id);
			Option(id);
		}
		case 5:
		{
			streif_stats(id);
			Option(id);
		}
		case 6:
		{
			cmdljbeam(id);
			Option(id);
		}
		case 7:
		{
			duck_show(id);
			Option(id);
		}
		case 8:
		{
			show_early(id);
			Option(id);
		}
		case 9:
		{
			Option2(id);
		}

	}
	return PLUGIN_HANDLED;
}
public Option2(id)
{	
	new MenuBody[512], len, keys;
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU2");
	
	if(multibhoppre[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU21a");
		keys |= (1<<0);
	}
	else
	{
		keys |= (1<<0);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU21b");
	}
	if(Show_edge[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU22a");
		keys |= (1<<1);
	}
	else
	{
		keys |= (1<<1);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU22b");
	}
	if(Show_edge_Fail[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU23a");
		keys |= (1<<2);
	}
	else
	{
		keys |= (1<<2);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU23b");
	}
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU24",user_block[id][1]);
	keys |= (1<<3);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU25",user_block[id][0]);
	keys |= (1<<4);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU26",min_prestrafe[id]);
	keys |= (1<<5);
	
	if(beam_type[id]==1)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU27a");
		keys |= (1<<6);
	}
	else if(beam_type[id]==2)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU27b");
		keys |= (1<<6);
	}
	
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU2BACK");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU2NEXT");
	keys |= (1<<8);	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENUEXIT");
	keys |= (1<<9);
	
	show_menu(id, keys, MenuBody, -1, "StatsOptionMenu2");
		
}

public OptionMenu2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			multi_bhop(id);
			Option2(id);	
		}
		case 2:
		{
			Showedge(id);
			Option2(id);	
		}
		case 3:
		{
			ShowedgeFail(id);
			Option2(id);	
		}
		case 4:
		{
			user_block[id][1]=user_block[id][1]+10;
			if(user_block[id][1]>=user_block[id][0])
			{
				user_block[id][1]=uq_minedge;
			}
			Option2(id);	
		}
		case 5:
		{
			if(user_block[id][0]==uq_maxedge)
			{
				user_block[id][0]=user_block[id][1];
				client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_OPTIONMENU2MAXVALUE1",uq_maxedge);
			}
			user_block[id][0]=user_block[id][0]+10;
			Option2(id);	
		}
		case 6:
		{
			if(min_prestrafe[id]>=320)
			{
				min_prestrafe[id]=0;
				client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_OPTIONMENU2MAXVALUE2");
			}
			min_prestrafe[id]=min_prestrafe[id]+20;
			Option2(id);	
		}
		case 7:
		{
			if(beam_type[id]==1)
			{
				beam_type[id]=2;
				client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_OPTIONMENU2BEAMT1");
			}
			else
			{
				beam_type[id]=1;
				client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_OPTIONMENU2BEAMT2");
			}
			Option2(id);	
		}
		case 8:
		{
			Option(id);	
		}
		case 9:
		{
			Option3(id);	
		}
	}
	return PLUGIN_HANDLED;
}
public Option3(id)
{	
	new MenuBody[512], len, keys;
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU3");
	
	if(enable_sound[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU31a");
		keys |= (1<<0);
	}
	else
	{
		keys |= (1<<0);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU31b");
	}
	if(showjofon[id]==true)
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU32a");
		keys |= (1<<1);
	}
	else
	{
		keys |= (1<<1);
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU32b");
	}
	if(height_show[id])
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU33a");
		keys |= (1<<2);
	}
	else
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU33b");
		keys |= (1<<2);
	}
	if(jofon[id])
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU34a");
		keys |= (1<<3);
	}
	else
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU34b");
		keys |= (1<<3);
	}
	if(jheight_show[id])
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU35a");
		keys |= (1<<4);
	}
	else
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU35b");
		keys |= (1<<4);
	}
	if(uq_istrafe)
	{
		if(ingame_strafe[id])
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU36a");
			keys |= (1<<5);
		}
		else
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU36b");
			keys |= (1<<5);
		}
		
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU38",showtime_st_stats[id]/10);
	
		keys |= (1<<6);
	}
	else
	{
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU37");
		len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU38F",showtime_st_stats[id]/10);
	}
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENU3BACK");
	keys |= (1<<8);
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_OPTIONMENUEXIT");
	keys |= (1<<9);
	
	show_menu(id, keys, MenuBody, -1, "StatsOptionMenu3");
		
}
public OptionMenu3(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			enable_sounds(id);
			Option3(id);	
		}
		case 2:
		{
			show_jof(id);
			Option3(id);	
		}
		case 3:
		{
			heightshow(id);
			Option3(id);	
		}
		case 4:
		{
			trainer_jof(id);
			Option3(id);
		}
		case 5:
		{
			show_jheight(id);
			Option3(id);
		}
		case 6:
		{
			ingame_st_stats(id);
			Option3(id);
		}
		case 7:
		{
			if(showtime_st_stats[id]==200)
			{
				client_print(id,print_center,"%L",LANG_SERVER,"UQSTATS_OPTIONMENU3MAXSEC");
				showtime_st_stats[id]=0;
			}
			showtime_st_stats[id]=showtime_st_stats[id]+10;

			Option3(id);
		}
	
		case 9:
		{
			Option2(id);	
		}
	}
	return PLUGIN_HANDLED;
}
public native_kz_get_configsdir(name[], len)
{
	param_convert(1);
	new lalin[64];
	get_localinfo("amxx_configsdir", lalin,63);
	return formatex(name, len, "%s/%s", lalin, KZ_DIR);
}

public plugin_end() 
{ 
	if(kz_sql == 1)
	{
		if(DB_TUPLE)
			SQL_FreeHandle(DB_TUPLE);
		if(SqlConnection)
			SQL_FreeHandle(SqlConnection);
		
		TrieDestroy(JumpPlayers);
	}
	else if(kz_sql == 0)
	{
		TrieDestroy(JData);
		TrieDestroy(JData_Block);
	}
}

/**
*	------------------------------------------------------------------
*	Options
*	------------------------------------------------------------------
*/

bindOptions() {
	g_Options[optIntJumpStats] = find_option_by_name("jump_stats");
}

public OnCellValueChanged(id, optionId, newValue) {
	if (optionId == g_Options[optIntJumpStats]) {
		g_OptionFlags[id] = newValue;

		gHasColorChat[id] =	!!(newValue & flagHasColorChat);
		g_lj_stats[id] = 	!!(newValue & flagLjStats);
		speedon[id]= 		!!(newValue & flagShowSpeed);
		showpre[id]=		!!(newValue & flagShowPre);
		streifstat[id]=		!!(newValue & flagStrafeStats);
		kz_beam[id]=		!!(newValue & flagBeam);
		kz_stats_pre[id]=	!!(newValue & flagStatsPre);
		failearly[id]=		!!(newValue & flagFailEarly);
		multibhoppre[id]=	!!(newValue & flagMultiBhopPre);
		showduck[id]=		!!(newValue & flagShowDuck);
		ljpre[id]=			!!(newValue & flagLjPre);
		Show_edge[id]=		!!(newValue & flagShowEdge);
		Show_edge_Fail[id]=	!!(newValue & flagShowEdgeFail);
		enable_sound[id]=	!!(newValue & flagEnableSounds);
		ingame_strafe[id]=	!!(newValue & flagIngameStrafes);
		showjofon[id]=		!!(newValue & flagJumpOff);
		jheight_show[id]=	!!(newValue & flagJumpHeight);

		if (speedon[id]) {
			set_task(0.1, "DoSpeed", id+212299, "", 0, "b", 0);
		}
	}
}
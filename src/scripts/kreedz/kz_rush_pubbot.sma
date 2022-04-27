#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <hamsandwich>

#include <kreedz_api>
#include <kreedz_util>

#pragma semicolon 1

#define PLUGIN	"KZ Rush PubBot"
#define VERSION "1.3"
#define AUTHOR	"Kpoluk"

#define FLAG_GROUND 	(1 << 7)
#define FLAG_JUMP 		(1 << 6)
#define FLAG_DUCK 		(1 << 5)
#define FLAG_USE  		(1 << 4)
#define FLAG_FORWARD	(1 << 3)
#define FLAG_BACK  		(1 << 2)
#define FLAG_MOVELEFT	(1 << 1)
#define FLAG_MOVERIGHT	(1 << 0)

new Array:g_aOrigins;	// player origins
new Array:g_aAngles;	// player angles
new Array:g_aBytes;		// movement flags

new const g_szBotClass[] = "PubBotThink";
new g_iBotEnt;
new const g_szNavParseClass[] = "NavParseThink";
new g_iParseEnt;

new g_iBotID;

new bool:g_bBotSpeeded;
new bool:g_bBotPaused;

new g_szMapName[32];
new g_szBotName[128];

new g_szBotDir[128];
new const g_szBotFolder[] = "pubbot";
new g_szBotFile[128];

new g_iFrameCounter;
new g_iFinishFrame;

new g_iPlrSound;
new g_iStepLeft;
new bool:g_bOldJump;

new Float:g_fOrigin[3];
new Float:g_fAngle[3];
new g_iByte;

new g_hFile[33];
new g_szNavName[33][128];
new g_hNavFile;


public plugin_precache()
{
	precache_sound("player/pl_step1.wav");
	precache_sound("player/pl_step3.wav");
	precache_sound("player/pl_step2.wav");
	precache_sound("player/pl_step4.wav");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	get_mapname(g_szMapName, charsmax(g_szMapName));
	strtolower(g_szMapName);

	get_localinfo("amxx_datadir", g_szBotDir, charsmax(g_szBotDir));
	format(g_szBotDir, charsmax(g_szBotDir), "%s/%s", g_szBotDir, g_szBotFolder);
	if(!dir_exists(g_szBotDir))
		mkdir(g_szBotDir);

	format(g_szBotDir, charsmax(g_szBotDir), "%s/%s", g_szBotDir, g_szMapName);
	if(!dir_exists(g_szBotDir))
		mkdir(g_szBotDir);

	RegisterHam(Ham_TakeDamage, "player", "hamPlayerTakeDamage", false);
	register_forward(FM_PlayerPreThink, "fmPlayerPreThink");
	register_forward(FM_CheckVisibility, "fmCheckVisibility");

	g_iBotEnt = create_entity("info_target");
	if(g_iBotEnt == 0)
		log_amx("cannot create info_target for pubbot");
	register_think(g_szBotClass, "fwdBotThink");
	set_pev(g_iBotEnt, pev_classname, g_szBotClass);

	g_iParseEnt = create_entity("info_target");
	if(g_iParseEnt == 0)
		log_amx("Cannot create info_target for bot parsing");
	register_think(g_szNavParseClass, "fwdNavParseThink");
	set_pev(g_iParseEnt, pev_classname, g_szNavParseClass);

	g_aOrigins = ArrayCreate(3);
	g_aAngles = ArrayCreate(3);
	g_aBytes = ArrayCreate(1);

	g_iBotID = 0;

	g_iPlrSound = 0;
	g_iStepLeft = 0;
	g_bOldJump = false;

	g_bBotSpeeded = false;
	g_bBotPaused = false;

	retrieveName();
	parseNav();

	// register_saycmd("started", "fwPubStarted");
	// register_saycmd("rejected", "fwPubRejected");
	// register_saycmd("paused", "fwPubPaused");
	// register_saycmd("unpaused", "fwPubUnpaused");
	// register_saycmd("finished", "fwPubFinished");

	kz_register_cmd("pubbot", "cmdPubBotMenu");
	kz_register_cmd("pubbotmenu", "cmdPubBotMenu");

	register_menucmd(register_menuid("PubBotMenu", 0), 1023, "handlePubBotMenu");
}

public kz_timer_start_post(id) {
	fwPubStarted(id);
}

public kz_timer_pause_post(id) {
	if(kz_get_timer_state(id) == TIMER_PAUSED)
		fwPubPaused(id);
	else if(kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubUnpaused(id);
}

public kz_top_new_pro_rec(id, Float:fTime) {
	fwPubFinished(id, fTime);
}

public kz_timer_stop_post(id) {
	fwPubRejected(id);
}

public kz_starttp_pre(id) {
	if (kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubPaused(id);

	return KZ_CONTINUE;
}

public kz_tp_post(id) {
	if (kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubRejected(id);

	return KZ_CONTINUE;
}

public kz_noclip_pre(id)
{
	if(kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubPaused(id);

	return KZ_CONTINUE;
}

public kz_hook_pre(id)
{
	if(kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubPaused(id);

	return KZ_CONTINUE;
}

public kz_spectator_pre(id)
{
	if(kz_get_timer_state(id) == TIMER_ENABLED)
		fwPubPaused(id);

	return KZ_CONTINUE;
}

public cmdPubBotMenu(id)
{
	if(!(get_user_flags(id) & ADMIN_VOTE))
	{
		return PLUGIN_HANDLED;	
	}

	new szMenu[300];
	formatex(szMenu, charsmax(szMenu), "\rPubBot \yMenu^n^n");

	if(g_iBotID > 0)
	{
		if(g_bBotPaused)
			format(szMenu, charsmax(szMenu), "%s\r1. \wPlay^n", szMenu);
		else
			format(szMenu, charsmax(szMenu), "%s\r1. \wPause^n", szMenu);

		if(g_bBotSpeeded)
			format(szMenu, charsmax(szMenu), "%s\r2. \wSpeed: \y2x^n", szMenu);
		else
			format(szMenu, charsmax(szMenu), "%s\r2. \wSpeed: \y1x^n", szMenu);

		format(szMenu, charsmax(szMenu), "%s\r3. \w-20 seconds^n\r4. \w+20 seconds^n\r5. \wReset^n^n^n", szMenu);
		format(szMenu, charsmax(szMenu), "%s\r8. \wKick^n^n\r0. \wExit", szMenu);
	}
	else
	{
		format(szMenu, charsmax(szMenu), "%s\r1. \dPlay^n\r2. \dSpeed: 1x^n", szMenu);
		format(szMenu, charsmax(szMenu), "%s\r3. \d-20 seconds^n\r4. \d+20 seconds^n\r5. \dReset^n^n^n", szMenu);
		format(szMenu, charsmax(szMenu), "%s\r8. \wCreate^n^n\r0. \wExit", szMenu);
	}

	show_menu(id, MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_8|MENU_KEY_0, szMenu, -1, "PubBotMenu");

	return PLUGIN_HANDLED;
}

public handlePubBotMenu(id, item) 
{
	switch(item) 
	{
		case 0:
		{
			if(g_iBotID > 0)
				g_bBotPaused = !g_bBotPaused;
		}
		case 1:
		{
			if(g_iBotID > 0)
				g_bBotSpeeded = !g_bBotSpeeded;
		}
		case 2:
		{
			if(g_iBotID > 0 && g_iFinishFrame > 2000)
			{
				if(g_iFrameCounter - 2000 <= 0)
					g_iFrameCounter = g_iFinishFrame + g_iFrameCounter - 2000;
				else
					g_iFrameCounter -= 2000;
			}
		}
		case 3:
		{
			if(g_iBotID > 0 && g_iFinishFrame > 2000)
			{
				if(g_iFrameCounter + 2000 >= g_iFinishFrame)
					g_iFrameCounter = g_iFrameCounter + 2000 - g_iFinishFrame;
				else
					g_iFrameCounter += 2000;
			}
		}
		case 4:
		{
			if(g_iBotID > 0)
				g_iFrameCounter = 0;
		}
		case 7:
		{
			if(g_iBotID > 0)
			{
				if(is_user_bot(g_iBotID))
					kickBot();
			}
			else
			{
				if(ArraySize(g_aOrigins) > 0)
					createBot();
			}
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	cmdPubBotMenu(id);
	return PLUGIN_HANDLED;
}

public client_putinserver(id)
{
	g_hFile[id] = 0;

	new szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID));
	replace_all(szAuthID, charsmax(szAuthID), ":", "_"); // : is not allowed in Windows names

	formatex(g_szNavName[id], charsmax(g_szNavName[]), "%s/%s.nav", g_szBotDir, szAuthID);
}

public client_disconnected(id)
{
	if(g_hFile[id])
	{
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}
}

public fwPubStarted(id) // when user started the timer
{
	// close file (if opened) and open from start
	if(g_hFile[id])
	{
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}
	
	g_hFile[id] = fopen(g_szNavName[id], "wb");
}

public fwPubRejected(id) // when gocheck done or user disconnects without savepos
{
	// close file and remove it
	if(g_hFile[id])
	{
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}

	if(file_exists(g_szNavName[id]))
		delete_file(g_szNavName[id]);
}

public fwPubPaused(id) // when user paused timer and didn't use gochecks 
{
	// close file
	if(g_hFile[id])
	{
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}
}

public fwPubUnpaused(id) // when user unpaused timer and didn't use gochecks 
{
	// close file just to be safe and open to add
	if(g_hFile[id])
	{
		log_amx("file should not be opened: %s", g_szNavName[id]);
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}

	g_hFile[id] = fopen(g_szNavName[id], "ab");
}

public fwPubFinished(id, Float:flTime) // when user finished the map without gochecks; flTime should be zero if this is not top1
{
	// close file
	if(g_hFile[id])
	{
		fclose(g_hFile[id]);
		g_hFile[id] = 0;
	}

	if(flTime <= 0.0)
	{
		// not the first place, remove file
		if(file_exists(g_szNavName[id]))
			delete_file(g_szNavName[id]);
		return;
	}

	// remove current bot
	if(g_iBotID)
		kickBot();

	ArrayClear(g_aOrigins);
	ArrayClear(g_aAngles);
	ArrayClear(g_aBytes);

	// remove current record
	new szFullName[200];
	formatex(szFullName, charsmax(szFullName), "%s/%s", g_szBotDir, g_szBotFile);

	if(file_exists(szFullName))
		delete_file(szFullName);

	// close and rename new nav
	new name[32];
	get_user_name(id, name, charsmax(name));
	trim(name);
	replace_all(name, charsmax(name), "\", ""); 
	replace_all(name, charsmax(name), "/", ""); 
	replace_all(name, charsmax(name), "%", "");
	replace_all(name, charsmax(name), "&", "");
	replace_all(name, charsmax(name), "?", "");
	replace_all(name, charsmax(name), "^"", ""); 
	replace_all(name, charsmax(name), "'", "");
	replace_all(name, charsmax(name), " ", "_");  
	replace_all(name, charsmax(name), ",", "");
	replace_all(name, charsmax(name), "|", "_");
	replace_all(name, charsmax(name), ":", "");	
	replace_all(name, charsmax(name), "*", "");	
	replace_all(name, charsmax(name), "<", "");	
	replace_all(name, charsmax(name), ">", "");

	new szTime[20];
	stringTimer(flTime, szTime, charsmax(szTime), 2, false);
	replace(szTime, charsmax(szTime), ":", "");

	formatex(g_szBotFile, charsmax(g_szBotFile), "%s_%s_%s.nav", g_szMapName, name, szTime);

	formatex(szFullName, charsmax(szFullName), "%s/%s", g_szBotDir, g_szBotFile);

	if(file_exists(g_szNavName[id]))
	{
		new szOldName[128];
		formatex(szOldName, charsmax(szOldName), "cstrike/%s", g_szNavName[id]);
		new szNewName[128];
		formatex(szNewName, charsmax(szNewName), "cstrike/%s", szFullName);

		rename_file(szOldName, szNewName);
	}

	// create new bot
	parseNav();
}

public kickBot()
{
	server_cmd("kick #%d", get_user_userid(g_iBotID));	

	g_iBotID = 0;

	g_iPlrSound = 0;
	g_iStepLeft = 0;
	g_bOldJump = false;

	g_bBotSpeeded = false;
	g_bBotPaused = false;
}

public fmPlayerPreThink(id)
{
	if(is_user_bot(id))
		return PLUGIN_HANDLED;

	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(is_user_alive(id) && g_hFile[id])
	{
		new Float:flOrigin[3];
		new Float:flAngle[3];

		pev(id, pev_origin, flOrigin);
		pev(id, pev_v_angle, flAngle);
		new iButton = pev(id, pev_button);
		
		fwrite(g_hFile[id], _:flOrigin[0], BLOCK_INT);
		fwrite(g_hFile[id], _:flOrigin[1], BLOCK_INT);
		fwrite(g_hFile[id], _:flOrigin[2], BLOCK_INT);

		fwrite(g_hFile[id], _:flAngle[0], BLOCK_INT);
		fwrite(g_hFile[id], _:flAngle[1], BLOCK_INT);
		fwrite(g_hFile[id], _:flAngle[2], BLOCK_INT);

		new navbuttons = 0;
		if(pev(id, pev_flags) & FL_ONGROUND)
			navbuttons |= FLAG_GROUND;
		if(iButton & IN_JUMP)
			navbuttons |= FLAG_JUMP;
		if(iButton & IN_DUCK)
			navbuttons |= FLAG_DUCK;
		if(iButton & IN_USE)
			navbuttons |= FLAG_USE;
		if(iButton & IN_FORWARD)
			navbuttons |= FLAG_FORWARD;
		if(iButton & IN_BACK)
			navbuttons |= FLAG_BACK;
		if(iButton & IN_MOVELEFT)
			navbuttons |= FLAG_MOVELEFT;
		if(iButton & IN_MOVERIGHT)
			navbuttons |= FLAG_MOVERIGHT;

		fwrite(g_hFile[id], navbuttons, BLOCK_BYTE);
	}

	return PLUGIN_HANDLED;
}

public taskCreateBot(id)
{
	if(g_iBotID == 0 && ArraySize(g_aOrigins) > 0) // bot exists but not created
		createBot();
}

public retrieveName()
{
	new szFileName[200];
	new hDir = open_dir(g_szBotDir, szFileName, charsmax(szFileName)); 
	if(!hDir)
	{
		log_amx("cannot open data/%s/%s directory", g_szBotFolder, g_szMapName);
		return;
	}

	do
	{
		if(szFileName[0] == '.')
			continue;

		if(contain(szFileName, ".nav") < 0)
			continue;

		if(contain(szFileName, g_szMapName) != 0)
			continue;

		copy(g_szBotFile, charsmax(g_szBotFile), szFileName);
	}
	while(next_file(hDir, szFileName, charsmax(szFileName)));

	close_dir(hDir);
}

public parseNav()
{
	if(!g_szBotFile[0])
		return;

	parseFilename();

	new szFullName[200];
	formatex(szFullName, charsmax(szFullName), "%s/%s", g_szBotDir, g_szBotFile);

	g_hNavFile = fopen(szFullName, "rb");
	if(!g_hNavFile)
	{
		log_amx("cannot open pubbot file. Map name is %s", g_szMapName);
		return;
	}

	set_pev(g_iParseEnt, pev_nextthink, get_gametime() + 0.01);
}

#define NUM_THREADS 100

public fwdNavParseThink(iEnt)
{
	for(new i = 0; i < NUM_THREADS; i++)
	{
		fread(g_hNavFile, _:g_fOrigin[0], BLOCK_INT);
		fread(g_hNavFile, _:g_fOrigin[1], BLOCK_INT);
		fread(g_hNavFile, _:g_fOrigin[2], BLOCK_INT);
		ArrayPushArray(g_aOrigins, g_fOrigin);

		fread(g_hNavFile, _:g_fAngle[0], BLOCK_INT);
		fread(g_hNavFile, _:g_fAngle[1], BLOCK_INT);
		fread(g_hNavFile, _:g_fAngle[2], BLOCK_INT);
		ArrayPushArray(g_aAngles, g_fAngle);

		fread(g_hNavFile, g_iByte, BLOCK_BYTE);
		ArrayPushCell(g_aBytes, g_iByte);

		if(feof(g_hNavFile))
			break;
	}

	if(feof(g_hNavFile))
	{
		g_iFinishFrame = ArraySize(g_aBytes) - 1;

		fclose(g_hNavFile);

		set_task(1.5, "taskCreateBot", 415637);
	}
	else
	{
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01);
	}
}

public parseFilename()
{
	new curr, last = 0, szTemp[120];
	g_szBotName[0] = 0;

	// find last '_' in g_szBotFile
	copy(szTemp, charsmax(szTemp), g_szBotFile);
	while((curr = contain(szTemp, "_")) >= 0)
	{
		copy(szTemp, charsmax(szTemp), szTemp[curr + 1]);
		last += curr + 1;
	}
	if(last < 4)
	{
		simpleName();
		return;
	}

	// time in format 0000.00
	new szTime[30];
	copy(szTime, charsmax(szTime), g_szBotFile[last]);
	szTime[contain(szTemp, ".nav")] = 0;

	// time in format 00:00.00
	new szFixedTime[30];
	new pos;
	copy(szFixedTime, charsmax(szFixedTime), szTime);
	pos = contain(szTime, ".") - 2;
	if(pos < 2)
	{
		simpleName();
		return;
	}
	szFixedTime[pos] = 0;
	format(szFixedTime, charsmax(szFixedTime), "%s:%s", szFixedTime, szTime[pos]);

	// g_szBotFile without time
	copy(szTemp, charsmax(szTemp), g_szBotFile);
	szTemp[last - 1] = 0;

	// + without g_szMapName
	if(strlen(szTemp) < strlen(g_szMapName) + 2 || containi(szTemp, g_szMapName) != 0) // we should at least have '_' and one letter of nick, plus szTemp should start with mapname
	{
		simpleName();
		return;
	}
	copy(szTemp, charsmax(szTemp), szTemp[strlen(g_szMapName)]);

	// now if the first symbol is '[', than we have a route
	new szRoute[60];
	if(szTemp[0] == '[')
	{
		copy(szRoute, charsmax(szRoute), szTemp);
		pos = contain(szRoute, "]");
		if(pos < 2 || strlen(szRoute) < 5) // we should at least have '[', one letter of route, ']', '_' and one letter of nick
		{
			simpleName();
			return;
		}
		szRoute[pos + 1] = 0; // cut off everything after route
		copy(szTemp, charsmax(szTemp), szTemp[pos + 1]); // leave '_name' in szTemp
	}

	if(szTemp[0] == '_')
	{
		copy(g_szBotName, charsmax(g_szBotName), szTemp[1]);
		replace_all(g_szBotName, charsmax(g_szBotName), "_", " ");
	}
	else
	{
		simpleName();
		return;
	}

	// add szFixedTime and szRoute
	if(equali(szRoute, ""))
		format(g_szBotName, charsmax(g_szBotName), "%s [%s]", g_szBotName, szFixedTime);
	else
		format(g_szBotName, charsmax(g_szBotName), "%s [%s] %s", g_szBotName, szFixedTime, szRoute);
}

public simpleName()
{
	copy(g_szBotName, charsmax(g_szBotName), g_szBotFile);
	new pos = contain(g_szBotName, ".nav");
	g_szBotName[pos] = 0;
}

public fmCheckVisibility(id, pset)
{		
	if(id == g_iBotID)
	{
		forward_return(FMV_CELL, 1);	
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED; 
}

public hamPlayerTakeDamage(victim, weapon, attacker, Float:damage, damagebits)
{
	if(victim == g_iBotID)
		return(HAM_SUPERCEDE);

	return(HAM_IGNORED);
}

public createBot()
{
	if(ArraySize(g_aBytes) == 0)
	{
		log_amx("pubbot arrays are empty. Map name is %s", g_szMapName);
		return;
	}

	g_iBotID = engfunc(EngFunc_CreateFakeClient, g_szBotName);
	if(!g_iBotID) 
	{
		log_amx("cannot create pubbot. Map name is %s", g_szMapName);
		g_iBotID = 0;
		return;
	}
	
	set_user_info(g_iBotID, "model", "urban");
	set_user_info(g_iBotID, "rate", "3500");
	set_user_info(g_iBotID, "cl_updaterate", "30");
	set_user_info(g_iBotID, "cl_lw", "0");
	set_user_info(g_iBotID, "cl_lc",	"0");
	set_user_info(g_iBotID, "tracker", "0");
	set_user_info(g_iBotID, "cl_dlmax", "128");
	set_user_info(g_iBotID, "lefthand", "1");
	set_user_info(g_iBotID, "friends", "0");
	set_user_info(g_iBotID, "dm", "0");
	set_user_info(g_iBotID, "ah", "1");

	set_user_info(g_iBotID, "*bot", "1");
	set_user_info(g_iBotID, "_cl_autowepswitch", "1");
	set_user_info(g_iBotID, "_vgui_menu", "0");
	set_user_info(g_iBotID, "_vgui_menus", "0");

	new szRejectReason[120];
	dllfunc(DLLFunc_ClientConnect, g_iBotID, g_szBotName ,"127.0.0.1", szRejectReason);
	if(!is_user_connected(g_iBotID)) 
	{
		log_amx("pubbot connection rejected. Reason: %s", szRejectReason);
		g_iBotID = 0;
		return;
	}

	dllfunc(DLLFunc_ClientPutInServer, g_iBotID);

	if(!is_user_connected(g_iBotID)) 
	{
		log_amx("pubbot failed to put in server");
		g_iBotID = 0;
		return;
	}

	set_pev(g_iBotID, pev_spawnflags, pev(g_iBotID, pev_spawnflags) | FL_FAKECLIENT);
	set_pev(g_iBotID, pev_flags, pev(g_iBotID, pev_flags) | FL_FAKECLIENT);
	set_pev(g_iBotID, pev_rendermode, kRenderTransTexture);
	set_pev(g_iBotID, pev_renderamt, 150.0);

	cs_set_user_team(g_iBotID, CS_TEAM_CT);
	fm_cs_user_spawn(g_iBotID);
	fm_give_item(g_iBotID, "weapon_knife");
	fm_set_user_godmode(g_iBotID, 1);

	set_pev(g_iBotID, pev_framerate, 1.0);

	set_pev(g_iBotEnt, pev_nextthink, get_gametime() + 0.01);

	g_iFrameCounter = 0;
}

public fwdBotThink(iEnt)
{
	if(g_iBotID > 0)
	{
		if(is_user_bot(g_iBotID))
		{
			botThink(g_iBotID);
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.01);
		}
		else
		{
			log_amx("this is not a bot!");
			g_iBotID = 0;
		}
	}
}


public botThink(id)
{
	if(g_bBotPaused)
		return;

	g_iByte = ArrayGetCell(g_aBytes, g_iFrameCounter);

	new bool:bGround = (g_iByte & FLAG_GROUND)? true : false;
	new bool:bJump = (g_iByte & FLAG_JUMP)? true : false;
	new bool:bDuck = (g_iByte & FLAG_DUCK)? true : false;

	new Float:oldX = g_fOrigin[0];
	new Float:oldY = g_fOrigin[1];

	ArrayGetArray(g_aOrigins, g_iFrameCounter, g_fOrigin);
	ArrayGetArray(g_aAngles, g_iFrameCounter, g_fAngle);

	new Float:sqr_speed = (g_fOrigin[0] - oldX) * (g_fOrigin[0] - oldX) + (g_fOrigin[1] - oldY) * (g_fOrigin[1] - oldY);

	new Float:flVelocity[3];
	flVelocity[0] = (g_fOrigin[0] - oldX) * 100.0;
	flVelocity[1] = (g_fOrigin[1] - oldY) * 100.0;
	flVelocity[2] = 0.0;
	set_pev(id, pev_velocity, flVelocity);	
	set_pev(id, pev_origin, g_fOrigin);

	set_pev(id, pev_v_angle, g_fAngle);
	g_fAngle[0] /= -3.0;
	set_pev(id, pev_angles, g_fAngle);
	set_pev(id, pev_fixangle, 1);

	set_pev(id, pev_movetype, MOVETYPE_NONE); // prevent lj stats
	set_pev(id, pev_solid, SOLID_NOT);

	new iButton = 0;

	if(bDuck)
		iButton |= IN_DUCK;
	if(bJump)
		iButton |= IN_JUMP;
	if(g_iByte & FLAG_FORWARD)
		iButton |= IN_FORWARD;
	if(g_iByte & FLAG_BACK)
		iButton |= IN_BACK;
	if(g_iByte & FLAG_MOVELEFT)
		iButton |= IN_MOVELEFT;
	if(g_iByte & FLAG_MOVERIGHT)
		iButton |= IN_MOVERIGHT;

	set_pev(id, pev_button, iButton);
	
	set_pev(id, pev_sequence, 19);

	new bool:bDucking = bDuck;

	new Float:dest[3];
	dest[0] = g_fOrigin[0];
	dest[1] = g_fOrigin[1];
	dest[2] = g_fOrigin[2] - 18.0;

	new ptr = create_tr2();
	engfunc(EngFunc_TraceHull, g_fOrigin, dest, 0, HULL_HEAD, id, ptr);
	new Float:flFraction;
	get_tr2(ptr, TR_flFraction, flFraction);
	get_tr2(ptr, TR_vecPlaneNormal, dest);
	free_tr2(ptr);

	if(flFraction < dest[2] - 0.01)
	{
		bDucking = true;
	}

	// 1 = idle
	// 2 = duck
	// 3 = walk
	// 4 = run
	// 5 = duck + walk
	// 6 = jump
	// 7 = 6?
	// 8 = swim

	if(bGround)
	{
		if(bJump)
		{
			set_pev(id, pev_gaitsequence, 6);
		}
		else
		{
			if(bDucking)
			{
				if(sqr_speed > 0.0)
					set_pev(id, pev_gaitsequence, 5);
				else
					set_pev(id, pev_gaitsequence, 2);
			}
			else
			{
				if(sqr_speed > 1.35 * 1.35)
					set_pev(id, pev_gaitsequence, 4);
				else if(sqr_speed > 0.0)
					set_pev(id, pev_gaitsequence, 3);
				else
					set_pev(id, pev_gaitsequence, 1);
			}
		}
	}
	else
	{
		if(bDuck)
			set_pev(id, pev_gaitsequence, 2);
		else
			set_pev(id, pev_gaitsequence, 6);
	}


	if(bGround && sqr_speed > 1.5 * 1.5)
	{			
		if(bJump && !g_bOldJump)
		{			
			g_iPlrSound = 0;
		}

		playbackSound(id);
	}

	g_iPlrSound -= 10;

	g_bOldJump = bJump;

	if(g_bBotSpeeded)
		g_iFrameCounter += 2;
	else
		g_iFrameCounter++;

	if(g_iFrameCounter >= g_iFinishFrame)
		g_iFrameCounter = 0;

	return;
}

public playbackSound(id)
{
	if(g_iPlrSound > 0)
		return;
	
	g_iStepLeft = !g_iStepLeft;
	new irand = random_num(0, 1) + (g_iStepLeft * 2);

	g_iPlrSound = 300;
	
	switch(irand)
	{
		// right foot
		case 0:	emit_sound(id, CHAN_BODY, "player/pl_step1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		case 1:	emit_sound(id, CHAN_BODY, "player/pl_step3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		// left foot
		case 2:	emit_sound(id, CHAN_BODY, "player/pl_step2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		case 3:	emit_sound(id, CHAN_BODY, "player/pl_step4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	
	return;
}

public plugin_end()
{
	ArrayDestroy(g_aOrigins);
	ArrayDestroy(g_aAngles);
	ArrayDestroy(g_aBytes);
}

stock stringTimer(const Float:flRealTime, szOutPut[], const iSizeOutPut, iMilliSecNumber = 2, gametime = true)
{
	static Float:flTime, iMinutes, iSeconds;
	
	if(gametime)
		flTime = get_gametime() - flRealTime;
	else
		flTime = flRealTime;
	
	if(flTime < 0.0)
		flTime = -flTime;
	
	iMinutes = floatround(flTime / 60, floatround_floor);
	iSeconds = floatround(flTime - (iMinutes * 60), floatround_floor);

	if(iMinutes <= 99)
		formatex(szOutPut, iSizeOutPut, "%02d:%02d", iMinutes, iSeconds);
	else
		formatex(szOutPut, iSizeOutPut, "%d:%02d", iMinutes, iSeconds);
	
	static iMilliSeconds;
	
	if(iMilliSecNumber == 1)
	{
		iMilliSeconds = floatround((flTime - (iMinutes * 60 + iSeconds)) * 10, floatround_floor);
		format(szOutPut, iSizeOutPut, "%s.%01d", szOutPut, iMilliSeconds);
	}
	else if(iMilliSecNumber == 2)
	{
		iMilliSeconds = floatround((flTime - (iMinutes * 60 + iSeconds)) * 100, floatround_floor);
		format(szOutPut, iSizeOutPut, "%s.%02d", szOutPut, iMilliSeconds);
	}
	else if(iMilliSecNumber == 3)
	{
		iMilliSeconds = floatround((flTime - (iMinutes * 60 + iSeconds)) * 1000, floatround_floor);
		format(szOutPut, iSizeOutPut, "%s.%03d", szOutPut, iMilliSeconds);
	}
}

stock Float:floatTimer(const szInPut[])
{
	new Float:flTime = 0.0;
	
	if(szInPut[2] == ':' && szInPut[5] == '.')
	{
		flTime+= ((szInPut[0] - 48) * 600.0) + ((szInPut[1] - 48) * 60.0);
		flTime+= ((szInPut[3] - 48) * 10.0) + (szInPut[4] - 48);
		flTime+= ((szInPut[6] - 48) / 10.0) + ((szInPut[7] - 48) / 100.0);
	}
	else
	{
		flTime = str_to_float(szInPut);
	}
	return flTime;
}
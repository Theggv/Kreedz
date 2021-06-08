#include <amxmodx>
#include <curl>
#include <amxxarch>

#define PLUGIN 		"[KZ] Map downloader"
#define VERSION 	"1.0"
#define AUTHOR 		"ggv/Destroman"

/**
*	------------------------------------------------------------------
*	Globals section
*	------------------------------------------------------------------
*/


#define KZMAPDL_LEVEL ADMIN_KICK 
#define _DEBUG

#pragma dynamic 131071
#pragma semicolon 1

new Array:g_Maps, g_iLoadMaps;
new g_szCurrentMap[64];
new g_szPrefix[64];
new g_szDlMap[64];

new g_szDlFile[128];
new g_hDlFile;

new archive_dir[] 	= "addons/amxmodx/data/kz_downloader/archives";
new temp_dir[] 		= "addons/amxmodx/data/kz_downloader/temp";
new kzdl_dir[] 		= "addons/amxmodx/data/kz_downloader";
new root_dir[] 		= "/";
new config_dir[] 	= "addons/amxmodx/configs/mapdownloader";

enum _:GetMapState {
	State_NoTask,
	State_Checking,
	State_Found,
	State_Downloading,
	State_Unpacking,
	State_NotFound,
	State_Finished,
	State_Failed,
};

new g_State;

enum _:SourceStruct {
	ServiceName[128],		// Name of the source
	CheckPath[256],			// Path to check map existence
	DownloadPath[256],		// Path to download map
	FileExtension[16],		// File extension
	bool:IsRequireSSL,		// Is ssl required
};

new Array:g_Sources;
new g_CurSourceIndex;

enum _:pCvars {
	CvarCanOverride,
	CvarCanDeleteSource,
	CvarMapsFile,
	CvarPrefix,
};

new g_Cvars[pCvars];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say", "hook_Say");

	g_Cvars[CvarCanOverride] = register_cvar("kz_mapdl_override", "1");																	 ///// kz_mapdl_override <0/1>  0 - keep files if exists, 1 - override all existing files
	g_Cvars[CvarCanDeleteSource] = register_cvar("kz_mapdl_delete_source", "1");   														 ///// kz_mapdl_delete_source <0/1>  0 - save rar file, 1 - delete rar file
	g_Cvars[CvarMapsFile] = register_cvar("kz_mapdl_maps_file", "addons/amxmodx/configs/mapdownloader/maps.ini");        				 ///// file must exist !!! file for mapcycle or mapmanager *.ini, append line with mapname
	g_Cvars[CvarPrefix] = register_cvar("kz_madlp_chat_prefix", "[KZ_MAPDL]");

	get_pcvar_string(g_Cvars[CvarPrefix], g_szPrefix, charsmax(g_szPrefix));
}

public plugin_cfg()
{
	new szConfigPath[256];

	if (!dir_exists(config_dir))
		mkdir(config_dir);
	
	formatex(szConfigPath, charsmax(szConfigPath), "%s/kz_mapdl.cfg", config_dir);
        
	if (file_exists(szConfigPath))
	{
		server_cmd("exec %s",szConfigPath);
		server_exec();
	}

	// remove temporary files
	rmdir_recursive(temp_dir);

	if (!dir_exists(kzdl_dir))
		mkdir(kzdl_dir); 
	if (!dir_exists(archive_dir))
		mkdir(archive_dir); 
	if (!dir_exists(temp_dir))
		mkdir(temp_dir);

	// load map list
	get_mapname(g_szCurrentMap, charsmax(g_szCurrentMap));
	Load_MapList();

	InitServices();
}

public InitServices()
{
	g_Sources = ArrayCreate(SourceStruct);

	ArrayPushArray(g_Sources, InitXJ());
	ArrayPushArray(g_Sources, InitCosy());
	ArrayPushArray(g_Sources, InitKZRush());
}

public InitXJ()
{
	new data[SourceStruct];

	data[ServiceName] = 		"Xtreme Jumps";
	data[CheckPath] = 			"http://files.xtreme-jumps.eu/maps/";
	data[DownloadPath] = 		"http://files.xtreme-jumps.eu/maps/";
	data[FileExtension] = 		".rar";
	data[IsRequireSSL] = 			false;

	return data;
}

public InitCosy()
{
	new data[SourceStruct];

	data[ServiceName] = 		"Cosy Climbing";
	data[CheckPath] = 			"https://cosy-climbing.net/files/maps/";
	data[DownloadPath] = 		"https://cosy-climbing.net/files/maps/";
	data[FileExtension] = 		".rar";
	data[IsRequireSSL] = 			true;

	return data;
}

public InitKZRush()
{
	new data[SourceStruct];

	data[ServiceName] = 		"KZ Rush";
	data[CheckPath] = 			"https://kz-rush.ru/download/map/cs16/";
	data[DownloadPath] = 		"https://kz-rush.ru/download/map/cs16/";
	data[FileExtension] = 		"";
	data[IsRequireSSL] = 			true;

	return data;
}

public hook_Say(id)
{
	new szMsg[192];
	read_args(szMsg, charsmax(szMsg));
	remove_quotes(szMsg);
	trim(szMsg);
	
	if (equal(szMsg, "") || szMsg[0] == 0x40) // '@'
	{
		return PLUGIN_HANDLED_MAIN;
	}
	
	if (equali(szMsg, "/dl", 3))
	{
		if (!(get_user_flags(id) & KZMAPDL_LEVEL)) {
			client_print( id, print_chat, "%s* You have no access to this command", g_szPrefix );
			return PLUGIN_HANDLED;
		}

		parse(szMsg, szMsg, 3, g_szDlMap, charsmax(g_szDlMap));

		if (g_szDlMap[0])
		{
			if (equali(g_szDlMap, g_szCurrentMap) || in_maps_array(g_szDlMap))
				client_print( id, print_chat, "%s %s exists in maps folder", g_szPrefix, g_szDlMap );
			else if (g_State != State_NoTask)
				Show_DownloadMenu(id);
			else if (!is_empty_str(g_szDlMap))
				Show_DownloadMenu(id);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public Show_DownloadMenu(id)
{
	if (g_State == State_NoTask)
	{
		g_State = State_Checking;
		Start_Find(id, true);
	}

	new szMsg[256];

	switch(g_State)
	{
		case State_Checking: 	formatex(szMsg, charsmax(szMsg), "\yTrying to find %s...", g_szDlMap);
		case State_Found:
		{
			new serviceData[SourceStruct];
			ArrayGetArray(g_Sources, g_CurSourceIndex, serviceData);
			formatex(szMsg, charsmax(szMsg), "\y%s was found on %s. Download it?", 
				g_szDlMap, serviceData[ServiceName]);
		}
		case State_Downloading: formatex(szMsg, charsmax(szMsg), "\yDownloading %s...", g_szDlMap);
		case State_Unpacking: 	formatex(szMsg, charsmax(szMsg), "\yUnpacking %s...", g_szDlMap);
		case State_NotFound: 	formatex(szMsg, charsmax(szMsg), "\y%s was not found", g_szDlMap);
		case State_Finished: 	formatex(szMsg, charsmax(szMsg), "\y%s was successfully installed!", g_szDlMap);
		case State_Failed: 		formatex(szMsg, charsmax(szMsg), "\yFailed to unpack %s. Archive corrupted.", g_szDlMap);
	}
	
	new iMenu = menu_create(szMsg, "DLMenu_Handler");

	switch(g_State)
	{
		case State_Found:
		{
			menu_additem(iMenu, "Yes", "1", 0);
			menu_additem(iMenu, "No", "2", 0);
		}
		case State_Finished, State_Failed, State_NotFound:
		{
			if (g_State == State_Finished)
			{
				formatex(szMsg, charsmax(szMsg), "Change to %s", g_szDlMap);
				menu_additem(iMenu, szMsg, "4", 0);
			}

			menu_additem(iMenu, "Quit", "3", 0);
		}
		default:
		{
			menu_additem(iMenu, "Cancel", "3", 0);
		}
	}

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, iMenu, 0);

	return PLUGIN_HANDLED;
}

public DLMenu_Handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		
		return PLUGIN_HANDLED;
	}
	
	static s_Data[6], s_Name[64], i_Access, i_Callback;
	menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);
	new iItem = str_to_num(s_Data);

	switch(iItem)
	{
		case 1:
		{
			if (g_State == State_Found)
			{
				g_State = State_Downloading;
				Show_DownloadMenu(id);
				Start_Download(id);
			}
			else
			{
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if (g_State == State_Found)
				g_State = State_NoTask;

			g_szDlMap = "";
		}
		case 3:
		{
			g_State = State_NoTask;
			g_szDlMap = "";
		}
		case 4:
		{
			new szCmd[128];
			formatex(szCmd, charsmax(szCmd), "amx_map %s", g_szDlMap);
			server_cmd(szCmd);
		}
	}
	
	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

stock Start_Find(id, isFirst = false)
{
	if (isFirst)
		g_CurSourceIndex = 0;
	else
		g_CurSourceIndex++;

	if (g_CurSourceIndex == ArraySize(g_Sources))
	{
		g_State = State_NotFound;
		Show_DownloadMenu(id);
		return;
	}

	new serviceData[SourceStruct];
	ArrayGetArray(g_Sources, g_CurSourceIndex, serviceData);

	new szPath[256];

	formatex(szPath, charsmax(szPath), "%s%s%s", serviceData[CheckPath], g_szDlMap, 
		serviceData[FileExtension]);

	new CURL:hCurl;

	if ((hCurl = curl_easy_init()))
	{
		curl_easy_setopt(hCurl, CURLOPT_URL, szPath);
		curl_easy_setopt(hCurl, CURLOPT_NOBODY, 1);
		curl_easy_setopt(hCurl, CURLOPT_TIMEOUT, 3);

		if (serviceData[IsRequireSSL])
		{
			curl_easy_setopt(hCurl, CURLOPT_SSL_VERIFYPEER, 1);
			curl_easy_setopt(hCurl, CURLOPT_CAINFO, "cstrike/addons/amxmodx/data/cert/cacert.pem");
		}

		new szData[1];
		szData[0] = id;

		#if defined _DEBUG
		server_print("Finding in %s", szPath);
		#endif

		curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, "@Find_Write_Callback");

		curl_easy_perform(hCurl, "@Find_Callback", szData, sizeof(szData));
	}
}

@Find_Callback(const CURL:hCurl, const CURLcode:iCode, const data[])
{
	new iResponceCode;
	curl_easy_getinfo(hCurl, CURLINFO_RESPONSE_CODE, iResponceCode);

	new id = data[0];

	#if defined _DEBUG
	server_print("Responce code: %d", iResponceCode);
	#endif

	curl_easy_cleanup(hCurl);

	if (g_State == State_NoTask)
		return;

	if (iCode != CURLE_OK || iResponceCode >= 400)
		Start_Find(id);
	else
	{
		g_State = State_Found;

		Show_DownloadMenu(id);

		g_State = State_Downloading;
		Show_DownloadMenu(id);
		Start_Download(id);
	}
}

@Find_Write_Callback(const data[], const size, const nmemb)
{
	return size * nmemb;
}

public Start_Download(id)
{
	new serviceData[SourceStruct];
	ArrayGetArray(g_Sources, g_CurSourceIndex, serviceData);

	new szPath[256];

	formatex(szPath, charsmax(szPath), "%s%s%s", serviceData[DownloadPath], g_szDlMap, 
		serviceData[FileExtension]);

	new CURL:hCurl;

	if ((hCurl = curl_easy_init()))
	{
		// setup file
		formatex(g_szDlFile, charsmax(g_szDlFile), "%s/%s.txt", archive_dir, g_szDlMap);

		delete_file(g_szDlFile);
		g_hDlFile = fopen(g_szDlFile, "wb");

		// setup curl

		curl_easy_setopt(hCurl, CURLOPT_BUFFERSIZE, 512);
		curl_easy_setopt(hCurl, CURLOPT_URL, szPath);
		curl_easy_setopt(hCurl, CURLOPT_FAILONERROR, 1);

		if (serviceData[IsRequireSSL])
		{
			curl_easy_setopt(hCurl, CURLOPT_SSL_VERIFYPEER, 1);
			curl_easy_setopt(hCurl, CURLOPT_CAINFO, "cstrike/addons/amxmodx/data/cert/cacert.pem");
		}

		new szData[1];
		szData[0] = id;

		curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, "@Download_Write_Callback");

		curl_easy_perform(hCurl, "@Download_Complete_Callback", szData, sizeof(szData));
	}
}

@Download_Write_Callback(const data[], const size, const nmemb)
{
	new real_size = size * nmemb;

	fwrite_blocks(g_hDlFile, data, real_size, BLOCK_CHAR);

	return real_size;
}

@Download_Complete_Callback(const CURL:hCurl, const CURLcode:iCode, const szData[])
{
	new id = szData[0];

	// redirect check
	new iResponceCode;
	curl_easy_getinfo(hCurl, CURLINFO_RESPONSE_CODE, iResponceCode);

	if (iResponceCode >= 300 && iResponceCode <= 302)
	{
		new szRedirect[256];
		curl_easy_getinfo(hCurl, CURLINFO_REDIRECT_URL, szRedirect, charsmax(szRedirect));

		#if defined _DEBUG
		server_print("redirect: %s", szRedirect);
		#endif

		curl_easy_setopt(hCurl, CURLOPT_URL, szRedirect);
		curl_easy_perform(hCurl, "@Download_Complete_Callback", szData, 1);

		return;
	}

	curl_easy_cleanup(hCurl);
	fclose(g_hDlFile);

	if (g_State == State_NoTask)
		return;

	if (iCode != CURLE_OK)
	{
		#if defined _DEBUG
		server_print("[Error] http code: %d", iResponceCode);
		#endif
	}
	else
	{
		OnArchiveComplete(id);
	}
}

public OnArchiveComplete(id)
{
	g_State = State_Unpacking;
	Show_DownloadMenu(id);

	new szDataDir[128], szArchivePath[256];
	get_localinfo("amxx_datadir", szDataDir, charsmax(szDataDir));
	formatex(szArchivePath, charsmax(szArchivePath), "%s/kz_downloader/archives/%s.txt", szDataDir, g_szDlMap);

	#if defined _DEBUG
	server_print("Trying to unarchive %s...", szArchivePath);
	#endif

	if (g_State == State_NoTask)
		return;

	AA_Unarchive(szArchivePath, temp_dir, "@OnComplete", id);
}

@OnComplete(id, iError)
{
	if (iError != AA_NO_ERROR)
	{
		#if defined _DEBUG
		server_print("Failed to unpack. Error code: %d", iError);
		#endif

		g_State = State_Failed;
		Show_DownloadMenu(id);
	}
	else
	{
		#if defined _DEBUG
		server_print("Done. Moving files to the directory.");
		#endif

		if (g_State == State_NoTask)
			return;

		g_State = State_Finished;
		Show_DownloadMenu(id);

		if (get_pcvar_num(g_Cvars[CvarCanDeleteSource]))
			delete_file(g_szDlFile);

		new strmapsfile[64];

		get_pcvar_string(g_Cvars[CvarMapsFile], strmapsfile, 63);

		if (file_exists(strmapsfile))
			write_file(strmapsfile, g_szDlMap, -1);
		
		MoveFiles_Recursive(temp_dir);
		set_task(1.0, "tsk_finish", id);
	}
}

public tsk_finish(id)
{
	rmdir_recursive(temp_dir);

	ArrayPushString(g_Maps, g_szDlMap);

	g_State = State_Finished;
	Show_DownloadMenu(id);

	client_print(id, print_console, "%s %s was successfully installed.", g_szPrefix, g_szDlMap);

	#if defined _DEBUG
	server_print("Finished.");
	#endif
}

///////////////////////////////////////

public MoveFiles_Recursive( work_dir[] )
{
	new szFileName[64];
	new hDir = open_dir(work_dir, szFileName, charsmax(szFileName));

	if (!hDir)
	{
		new file = fopen(work_dir, "rb");

		if (file)
			fclose(file);

		return;
	}

	do
	{
		if (szFileName[0] != '.' && szFileName[1] != '.')
		{
			new szDest[512], szDest1[512], copyfile[512], copydir[512]; 

			format(szDest, 511, "%s/%s", work_dir, szFileName);
			
	//		server_print("%s", szFileName)
		//	server_print("%s", szDest)
			///wad files
			
			if (containi(szDest, ".wad") != -1 )
			{
				//filename
				format(copyfile, 511, "%s/%s",root_dir, szFileName );
				if (get_pcvar_num(g_Cvars[CvarCanOverride])) {
					fmove(szDest, copyfile);
				}
				else {
					if (!file_exists(copyfile)) {
						fmove(szDest, copyfile);
					}
				}
				//server_print("szdest - %s and copyfile - %s", szDest, copyfile);
			}
			
			///maps
			
			if ((containi(szDest, ".bsp") != -1 || containi(szDest, ".res") != -1 || containi(szDest, ".txt") != -1 || containi(szDest, ".nav") != -1 ||  containi(szDest, "maps/") != -1) && (containi(szDest, "taskfiledownload") == -1 ))
			{
				new iPos = strfind(szDest, "/");
				new LastPos = iPos;
				// addons/amxmodx/data/kz_downloader/temp/hb_Zzz/hb_Zzz.bsp
				// Find base filename from path ex: hb_Zzz.bsp ^
				while(iPos != -1)
				{
					LastPos = iPos;
					iPos = strfind(szDest, "/", .pos = iPos+1);					
				}
				
				substr(szDest1,511, szDest, LastPos, 0);
				format(copyfile, 511, "maps%s", szDest1 );
				fmove(szDest, copyfile);
				server_print("szdest1 - %s and copyfile - %s", szDest1, copyfile); // tak je ? ny davai tak :)
			}
			
			
			///gfx
			
			if (((containi(szDest, ".tga") != -1 || containi(szDest, ".bmp") != -1 || containi(szDest, ".lst") != -1) || containi(szDest, "gfx/") != -1))
			{
				//foldername
				if (containi(szFileName, ".") == -1) {
					new iPos = strfind(szDest, "gfx/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copydir, 511, "%s/%s",root_dir, szDest1 );
					if (!dir_exists(copydir)){
						mkdir(copydir);
						
					}
					//server_print("szdest1 - %s and copydir - %s", szDest1, copydir);
				}
				//filename
				if (containi(szFileName, ".") != -1) {
					new iPos = strfind(szDest, "gfx/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copyfile, 511, "%s/%s",root_dir, szDest1 );
					
					if (get_pcvar_num(g_Cvars[CvarCanOverride])) {
						fmove(szDest, copyfile);
					}
					else {
						if (!file_exists(copyfile)){
							fmove(szDest, copyfile);
						}
					}
					//server_print("szdest - %s and copyfile - %s", szDest, copyfile);
				}
			}
			
			///sound
			
			if ((containi(szDest, ".wav") != -1 || containi(szDest, "sound/") != -1 )) 
			{
				//foldername
				if (containi(szFileName, ".") == -1) {
					new iPos = strfind(szDest, "sound/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copydir, 511, "%s/%s",root_dir, szDest1 );
					if (!dir_exists(copydir)){
						mkdir(copydir);
					}
					//server_print("szdest - %s and copydir - %s", szDest, copydir);
				}
				//filename
				if (containi(szFileName, ".wav") != -1) {
					new iPos = strfind(szDest, "sound/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copyfile, 511, "%s/%s",root_dir, szDest1 );
					fmove(szDest, copyfile);
					//server_print("szdest - %s and copyfile - %s", szDest, copyfile);
				}
			}
			
			///models
			if ((containi(szDest, ".mdl") != -1 || containi(szDest, "models/") != -1))
			{
				//foldername
				if (containi(szFileName, ".") == -1) {
					new iPos = strfind(szDest, "models/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copydir, 511, "%s/%s",root_dir, szDest1 );
					if (!dir_exists(copydir)){
						mkdir(copydir);
					}
					//server_print("szdest - %s and copydir - %s", szDest, copydir);
				}
				//filename
				if (containi(szFileName, ".mdl") != -1) {
					new iPos = strfind(szDest, "models/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copyfile, 511, "%s/%s",root_dir, szDest1 );
					
					if (get_pcvar_num(g_Cvars[CvarCanOverride])) {
						fmove(szDest, copyfile);
					}
					else {
						if (!file_exists(copyfile)){
							fmove(szDest, copyfile);
						}
					}
					//server_print("szdest - %s and copyfile - %s", szDest, copyfile);
				}
			}

			///sprites
			if ((containi(szDest, ".spr") != -1 || containi(szDest, "sprites/") != -1))
			{
				//foldername
				if (containi(szFileName, ".") == -1) {
					new iPos = strfind(szDest, "sprites/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copydir, 511, "%s/%s",root_dir, szDest1 );
					if (!dir_exists(copydir)){
						mkdir(copydir);
					}
					//server_print("szdest - %s and copydir - %s", szDest, copydir);
				}
				//filename
				if (containi(szFileName, ".spr") != -1) {
					new iPos = strfind(szDest, "sprites/");
					substr(szDest1,511, szDest, iPos, 0);
					format(copyfile, 511, "%s/%s",root_dir, szDest1 );
					
					if (get_pcvar_num(g_Cvars[CvarCanOverride])) {
						fmove(szDest, copyfile);
					}
					else {
						if (!file_exists(copyfile)){
							fmove(szDest, copyfile);
						}
					}
					//server_print("szdest - %s and copyfile - %s", szDest, copyfile);
				}
			}


			MoveFiles_Recursive(szDest);
		}
	}
	while ( next_file( hDir, szFileName, charsmax( szFileName ) ) );
  	close_dir(hDir);
}

stock fmove(const read_path[], const dest_path[]) 
{ 
	static buffer[256];
	static readsize;
	new fp_read = fopen(read_path, "rb");
	if (file_exists(dest_path)){
		delete_file(dest_path);
	}
	new fp_write = fopen(dest_path, "wb");
	 
	if (!fp_read) 
   	 	return 0;
	 
	fseek(fp_read, 0, SEEK_END); 
	new fsize = ftell(fp_read); 
	fseek(fp_read, 0, SEEK_SET); 
	 
	// Here we copy the files from xxx.wav to our wave 
	for (new j = 0; j < fsize; j += 256) 
	{ 
		readsize = fread_blocks(fp_read, buffer, 256, BLOCK_CHAR); 
		fwrite_blocks(fp_write, buffer, readsize, BLOCK_CHAR); 
	} 
	fclose(fp_read);
	fclose(fp_write);

	delete_file(read_path);

	return 1;
}



bool:substr(dst[], const size, const src[], start, len = 0) {
   new srclen = strlen(src);
   start = (start < 0) ? srclen + start : start;

   if (start < 0 || start > srclen)
      return false;

   if (len == 0)
      len = srclen;
   else if (len < 0) {
      if ((len = srclen - start + len) < 0)
         return false;
   }

   len = min(len, size);

   copy(dst, len, src[start]);
   return true;
}



// For load maplist
public ExplodeString( p_szOutput[][], p_nMax, p_nSize, p_szInput[], p_szDelimiter )
{
	new nIdx    = 0, l = strlen( p_szInput );
	new nLen    = (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput, p_szDelimiter ) );
	while ( (nLen < l) && (++nIdx < p_nMax) )
		nLen += (1 + copyc( p_szOutput[nIdx], p_nSize, p_szInput[nLen], p_szDelimiter ) );
	return(nIdx);
}


stock is_empty_str(const str[], fl_spacecheck = false)
{
	new i = 0;
	if (fl_spacecheck)
		while(str[i] == 32)
			i++;
	return !str[i];
}

public Load_MapList()
{
	g_iLoadMaps = 0;
	g_Maps = ArrayCreate(33);
	new iDir, iLen, szFileName[64];
	new DirName[] = "maps";
	iDir = open_dir(DirName, szFileName, charsmax(szFileName));
	
	if (iDir)
	{
		while(next_file(iDir, szFileName, charsmax(szFileName)))
		{
			iLen = strlen(szFileName) - 4;
			
			if (iLen < 0) continue;
			
			if (equali(szFileName[iLen], ".bsp") && !equali(szFileName, g_szCurrentMap))
			{
				szFileName[iLen] = '^0';
				
				g_iLoadMaps++;
				
				ArrayPushString(g_Maps, szFileName);
			}
		}
		close_dir(iDir);
	}
	if (!g_iLoadMaps)
	{
		set_fail_state("LOAD_MAPS: Nothing loaded");
		return;
	}
}


bool:in_maps_array(map[])
{
	new szMap[33], iMax = ArraySize(g_Maps);
	for(new i = 0; i < iMax; i++)
	{
		ArrayGetString(g_Maps, i, szMap, charsmax(szMap));
		if (equali(szMap, map))
		{
			return true;
		}
	}
	return false;
}

public rmdir_recursive(temp_dir[])
{
	new szFileName[64], szDest[512];
	new hDir = open_dir(temp_dir, szFileName, charsmax(szFileName));
	if (!hDir)
	{
		new file = fopen(temp_dir, "rb");
		if (file)
		{
			fclose(file);
		}
		return;
	}
	do
	{
		if (szFileName[0] != '.' && szFileName[1] != '.')
		{
			format(szDest, 511, "%s/%s", temp_dir, szFileName);
			
			if (!dir_exists(szDest)) 
			{
				delete_file(szDest);				
			}
			else 
			{
				rmdir(szDest);	
				rmdir_recursive(szDest);			
			}
		}
	}	
	while ( next_file( hDir, szFileName, charsmax( szFileName ) ) );
  	close_dir(hDir);
	delete_file(g_szDlFile);
}
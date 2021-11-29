#include <amxmodx>
#include <curl>

#include <kreedz/kz_api>

#define PLUGIN 	"[Kreedz] Records"
#define VERSION "1.0"
#define AUTHOR 	"ggv"

enum _:SourceStruct {
	Title[64],
	Link[128],
	Suffix[16],
	RecordsFile[256],
	SkipString[128],
};

new Array:ga_Sources;

enum _:RecordsStruct {
	RecordsTitle[64],
	RecordsList[512],
};

new Array:ga_Records;

new g_szWorkDir[256];
new g_hDlFile;
new g_szMapName[64];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	kz_register_cmd("wr", "cmd_WorldRecord");
	kz_register_cmd("ru", "cmd_WorldRecord");
}

public plugin_cfg( )
{
	get_localinfo("amxx_datadir", g_szWorkDir, charsmax(g_szWorkDir));
	format(g_szWorkDir, charsmax(g_szWorkDir), "%s/kz_records", g_szWorkDir);
	
	if( !dir_exists( g_szWorkDir ) ) {
		mkdir( g_szWorkDir );
	}

	get_mapname(g_szMapName, charsmax(g_szMapName));
	strtolower(g_szMapName);

	ga_Sources = ArrayCreate(SourceStruct);
	ga_Records = ArrayCreate(RecordsStruct);
	InitSources();
	
	for (new i = 0; i < ArraySize(ga_Sources); ++i) {
		fnParseInfo(i);
	}

	// new temp[256];
	// format( temp, 255, "%s/last_update.ini", g_szWorkDir );
	
	// if( !file_exists( temp ) )
	// {
	// 	fnUpdate( );
	// 	return PLUGIN_CONTINUE;
	// }
	
	// new year, month, day;
	// date( year, month, day );
	
	// new f = fopen( temp, "rt" );
	// fgets( f, temp, 255 );
	// fclose( f );
	
	// if( str_to_num( temp[0] ) > year || str_to_num( temp[5] ) > month || str_to_num( temp[8] ) > day ) {
	// 	fnUpdate( );
	// 	return PLUGIN_CONTINUE;
	// }
	
	return PLUGIN_CONTINUE;
}

public cmd_WorldRecord(id) {
	new szText[512], iLen = 0;

	iLen = formatex(szText, charsmax(szText), "%s^n", g_szMapName);

	new recordsInfo[RecordsStruct];

	for (new i = 0; i < ArraySize(ga_Records); ++i) {
		ArrayGetArray(ga_Records, i, recordsInfo);

		iLen += formatex(szText[iLen], charsmax(szText) - iLen, "^n%s %s", 
			recordsInfo[RecordsTitle], recordsInfo[RecordsList]);
	}

	set_hudmessage(255, 0, 255, 0.01, 0.2, _, _, 3.0, _, _, 4);
	show_hudmessage(id, szText);

	return PLUGIN_HANDLED;
}

/**
*	------------------------------------------------------------------
*	Download interfaces
*	------------------------------------------------------------------
*/

public fnDownload(sourceIndex) {
	if (sourceIndex < 0 || sourceIndex >= ArraySize(ga_Sources)) return;

	new source[SourceStruct];
	ArrayGetArray(ga_Sources, sourceIndex, source);

	new CURL:hCurl;

	if ((hCurl = curl_easy_init())) {
		// Setup file
		delete_file(source[RecordsFile]);
		g_hDlFile = fopen(source[RecordsFile], "wb");

		// Setup curl

		curl_easy_setopt(hCurl, CURLOPT_BUFFERSIZE, 512);
		curl_easy_setopt(hCurl, CURLOPT_URL, source[Link]);
		curl_easy_setopt(hCurl, CURLOPT_FAILONERROR, 1);

		curl_easy_setopt(hCurl, CURLOPT_SSL_VERIFYPEER, 1);
		curl_easy_setopt(hCurl, CURLOPT_CAINFO, "cstrike/addons/amxmodx/data/cert/cacert.pem");

		new szData[1];
		szData[0] = sourceIndex;

		curl_easy_setopt(hCurl, CURLOPT_WRITEFUNCTION, "@fnDownloadWriteCallback");

		curl_easy_perform(hCurl, "@fnDownloadOnFinishCallback", szData, sizeof(szData));
	}
}

@fnDownloadOnFinishCallback(const CURL:hCurl, const CURLcode:iCode, const data[]) {
	new iResponceCode;
	curl_easy_getinfo(hCurl, CURLINFO_RESPONSE_CODE, iResponceCode); 

	if (iCode != CURLE_OK) {
		server_print("[Error] http code: %d", iResponceCode);
	}

	curl_easy_cleanup(hCurl);
	fclose(g_hDlFile);

	new idx = str_to_num(data);

	OnSourceUpdated(idx);
}

@fnDownloadWriteCallback(const data[], const size, const nmemb) {
	new real_size = size * nmemb;

	fwrite_blocks(g_hDlFile, data, real_size, BLOCK_CHAR);

	return real_size;
}

public OnSourceUpdated(sourceIndex) {
	if (sourceIndex < 0 || sourceIndex >= ArraySize(ga_Sources)) return;

	new source[SourceStruct];
	ArrayGetArray(ga_Sources, sourceIndex, source);

	// Parse current
	fnParseInfo(sourceIndex);

	// Update next
	fnDownload(sourceIndex + 1);
}

public fnUpdate( )
{
	ArrayClear(ga_Records);
	fnDownload(0);
	
	new temp[256];
	get_localinfo( "amxx_datadir", temp, 255 );
	format( temp, 255, "%s/kz_records/last_update.ini", temp );
	
	new year, month, day;
	date( year, month, day );
	
	if( file_exists( temp ) )
	{
		delete_file( temp );
	}
	
	new f = fopen( temp, "wt" );
	format( temp, 255, "%04ix%02ix%02i", year, month, day );
	fputs( f, temp );
	fclose( f );
}

/**
*	------------------------------------------------------------------
*	Sources section
*	------------------------------------------------------------------
*/

public InitSources() {
	ArrayPushArray(ga_Sources, InitXJ());
	ArrayPushArray(ga_Sources, InitCosy());
	ArrayPushArray(ga_Sources, InitKZRush());
}

InitXJ() {
	new data[SourceStruct];

	data[Title] = "XJ";
	data[Link] = "https://xtreme-jumps.eu/demos.txt";
	data[Suffix] = "xj";
	formatex(data[RecordsFile], charsmax(data[RecordsFile]), 
		"%s/demos_xj.txt", g_szWorkDir);
	data[SkipString] = "Xtreme-Jumps.eu";

	return data;
}

InitCosy() {
	new data[SourceStruct];

	data[Title] = "Cosy Climbing";
	data[Link] = "https://cosy-climbing.net/demos.txt";
	data[Suffix] = "cc";
	formatex(data[RecordsFile], charsmax(data[RecordsFile]), 
		"%s/demos_cc.txt", g_szWorkDir);
	data[SkipString] = "www.cosy-climbing.net";

	return data;
}

InitKZRush() {
	new data[SourceStruct];

	data[Title] = "KZ Rush";
	data[Link] = "https://kz-rush.ru/demos.txt";
	data[Suffix] = "ru";
	formatex(data[RecordsFile], charsmax(data[RecordsFile]), 
		"%s/demos_ru.txt", g_szWorkDir);
	data[SkipString] = "kz-rush.ru - International Kreedz Community";

	return data;
}

public fnParseInfo(sourceIndex) {
	if (sourceIndex < 0 || sourceIndex >= ArraySize(ga_Sources)) return;

	new source[SourceStruct];
	ArrayGetArray(ga_Sources, sourceIndex, source);

	if (!file_exists(source[RecordsFile])) return;

	new hFile = fopen(source[RecordsFile], "rt");
	new szData[256];

	new szMap[32], szAuthor[32], szTime[32], szExtension[16];

	new recordsInfo[RecordsStruct];

	formatex(recordsInfo[RecordsTitle], charsmax(recordsInfo[RecordsTitle]), "%s:", source[Title]);
	new szRecords[512], iLen = 0;

	while (!feof(hFile)) {
		fgets(hFile, szData, charsmax(szData));

		if (equali(szData, source[SkipString])) continue;

		fnParseInterface(szData, source[Suffix], szMap, szAuthor, szTime, szExtension);
		strtolower(szMap);

		if (!equal(szMap, g_szMapName)) continue;

		new szFormattedTime[32];
		UTIL_FormatTime(str_to_float(szTime), szFormattedTime, 31, true);

		if (equal(szExtension, "")) {
			iLen += formatex(szRecords[iLen], charsmax(szRecords) - iLen, 
				"^n   %s (%s) ", szAuthor, szFormattedTime);
		} else {
			iLen += formatex(szRecords[iLen], charsmax(szRecords) - iLen, 
				"^n   [%s] %s (%s) ", szExtension, szAuthor, szFormattedTime);
		}
	}

	if(equal(szRecords, "")) {
		szRecords = "^n   N/A (**:**)";
	}

	copy(recordsInfo[RecordsList], charsmax(recordsInfo[RecordsList]), szRecords);
	ArrayPushArray(ga_Records, recordsInfo);
}

public fnParseInterface(const szData[256], const suffix[], szMap[32], szAuthor[32], szTime[32], szExtension[16]) {
	new szMapWithExt[64], tmp[16];

	if (equal(suffix, "xj")) {
		// map[ext] time nickname country ???
		parse(szData, szMapWithExt, 63, szTime, 31, szAuthor, 31);
	} else if (equal(suffix, "cc")) {
		// map[ext] time ??? ??? ??? country nickname
		parse(szData, szMapWithExt, 63, szTime, 31, 
			tmp, 15, tmp, 15, tmp, 15, tmp, 15, 
			szAuthor, 31);
	} else if (equal(suffix, "ru")) {
		// map[ext] time nickname country
		parse(szData, szMapWithExt, 63, szTime, 31, szAuthor, 31);
	}

	if (equal(szMapWithExt, "")) return;

	if (containi(szMapWithExt, "[") && containi(szMapWithExt, "[")) {
		strtok2(szMapWithExt, szMap, 31, tmp, 15, '[');
		replace_all(tmp, 15, "]", "");

		copy(szExtension, 15, tmp);
	} else {
		copy(szMap, 31, szMapWithExt);
		szExtension = "";
	}
}
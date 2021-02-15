#include <sqlx>

#define TASK_CHECK_SQL_PLAYER 13378
///////////////////////////////////////sql code///////////////////
public stats_sql()
{
	new host[64], user[64], pass[64], db[64];

	get_pcvar_string(uq_host, host, 63);
	get_pcvar_string(uq_user, user, 63);
	get_pcvar_string(uq_pass, pass, 63);
	get_pcvar_string(uq_db, db, 63);
	
	DB_TUPLE = SQL_MakeDbTuple(host, user, pass, db);
	
	new error;
	SqlConnection = SQL_Connect(DB_TUPLE,error,g_error,511);
	
	if(!SqlConnection) 
	{
		server_print("uq_jumpstats: Could not connect to SQL database; Error #%d: %s", error, g_error);
		log_amx("uq_jumpstats: Could not connect to SQL database; Error #%d: %s", error, g_error);
		return pause("a");
	}
	
	new CreateInto[1001];
	
	formatex(CreateInto, 1000, "CREATE TABLE IF NOT EXISTS uq_players (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,name VARCHAR(64) NOT NULL,ip VARCHAR(39) NOT NULL,authid VARCHAR(35) NOT NULL, lastseen INT(10) NOT NULL,INDEX(name,authid))");
	SQL_ThreadQuery(DB_TUPLE,"QueryHandle", CreateInto);
	
	formatex(CreateInto, 1000, "CREATE TABLE IF NOT EXISTS uq_jumps (pid INT(11) NOT NULL,type VARCHAR(32) NOT NULL,distance INT(10) NOT NULL,maxspeed INT(10) NOT NULL,prestrafe INT(10) NOT NULL,strafes INT(2) NOT NULL,sync INT(3) NOT NULL,ddbh INT(3) NOT NULL DEFAULT '0',pspeed INT(3) NOT NULL,wpn VARCHAR(32) NOT NULL,INDEX(pid,type,distance,maxspeed,prestrafe,strafes,sync,ddbh,pspeed,wpn))");
	SQL_ThreadQuery(DB_TUPLE,"QueryHandle", CreateInto);
	
	formatex(CreateInto, 1000, "CREATE TABLE IF NOT EXISTS uq_block_tops (pid INT(11) NOT NULL,type VARCHAR(32) NOT NULL,distance INT(10) NOT NULL,jumpoff INT(10) NOT NULL,block VARCHAR(5) NOT NULL,pspeed INT(3) NOT NULL,wpn VARCHAR(32) NOT NULL,INDEX(pid,type,distance,jumpoff,pspeed,wpn))");
	SQL_ThreadQuery(DB_TUPLE,"QueryHandle", CreateInto);
	
	formatex(CreateInto, 1000, "CREATE TABLE IF NOT EXISTS info_stats (cvar varchar(32) NOT NULL,val varchar(16) NOT NULL, UNIQUE(cvar))");
	SQL_ThreadQuery(DB_TUPLE,"QueryHandle", CreateInto);
	
	return PLUGIN_CONTINUE;
}

public QueryHandle(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if( iFailState != TQUERY_SUCCESS )
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		client_print(0,print_chat, "SQL error. Data has not been not saved.");
	}
	
	SQL_FreeHandle(hQuery);
	return PLUGIN_CONTINUE;
}
public retrying_getinfo(id)
{
	id=id-213134;
	player_load_info(id);
}
public player_load_info(id)
{
	new Handle:query,sql_rankby[128],error[128],sql_query[128],quoted_name[65];
	
	SQL_QuoteString(SqlConnection, quoted_name, 64, g_playername[id]);
	
	switch(rankby)
	{
		case 0:
		{ // by name
			// bugfix (happened once o_O)
			if(strlen(g_playername[id]) < 1)
			{
				log_amx("NAME BUG; output: %s; player id: %d", g_playername[id], get_user_userid(id));
				get_user_name(id, g_playername[id], 64);
			}
			
			formatex(sql_rankby, 127, "name LIKE '%s'", quoted_name);
		}
		case 1:
		{ // by ip
		
			// bugfix (o_O)
			if(strlen(g_playerip[id]) < 1)
			{
				log_amx("IP BUG; output: %s; player id: %d", g_playerip[id], get_user_userid(id));
				get_user_ip(id, g_playerip[id], 64);
			}
		
			formatex(sql_rankby, 127, "ip LIKE '%s'", g_playerip[id]);
		}
		case 2:
		{ // steamid
		
			// bugfix (o_O)
			if(strlen(g_playerip[id]) < 1)
			{
				log_amx("STEAM BUG; output: %s; player id: %d", g_playersteam[id], get_user_userid(id));
				get_user_authid(id, g_playersteam[id], 64);
			}
		
			formatex(sql_rankby, 127, "authid LIKE '%s'", g_playersteam[id]);
		}
	}
	
	query = SQL_PrepareQuery(SqlConnection, "SELECT `id` FROM uq_players WHERE %s", sql_rankby);
	
	if (!SQL_Execute(query))
	{
		SQL_QueryError(query, error, 127);
		
		new tmp_error;
		SqlConnection = SQL_Connect(DB_TUPLE,tmp_error,g_error,511);
		
		set_task(2.0,"retrying_getinfo",213134+id);
	} 
	else if (!SQL_NumResults(query))
	{
		new cData[1];
		cData[0] = id;
		formatex(sql_query, 511, "INSERT INTO uq_players(name,ip,authid,lastseen) VALUES('%s','%s','%s',UNIX_TIMESTAMP())", quoted_name, g_playerip[id], g_playersteam[id]);
		SQL_ThreadQuery(DB_TUPLE,"QueryHandle_newPlayer", sql_query, cData, strlen(cData[0]));
	} else {
		new cData[1];
		cData[0] = id;
		g_sql_pid[id] = SQL_ReadResult(query, 0);
		
		format(sql_query, 511, "SELECT type,distance,maxspeed,prestrafe,strafes,sync,ddbh,pspeed,wpn FROM uq_jumps WHERE pid=%d", g_sql_pid[id]);
		SQL_ThreadQuery(DB_TUPLE,"QueryHandle_LoadPlayerTops", sql_query, cData, strlen(cData[0]));
		format(sql_query, 511, "SELECT type,distance,jumpoff,block,pspeed,wpn FROM uq_block_tops WHERE pid=%d", g_sql_pid[id]);
		SQL_ThreadQuery(DB_TUPLE,"QueryHandle_LoadPlayerTopsBlock", sql_query, cData, strlen(cData[0]));
		
		if(get_pcvar_num(kz_uq_update_auth) <= 0)
			format(sql_query, 511, "UPDATE uq_players SET lastseen=UNIX_TIMESTAMP() WHERE `id`=%d", g_sql_pid[id]);
		else
			format(sql_query, 511, "UPDATE uq_players SET name='%s',ip='%s',authid='%s',lastseen=UNIX_TIMESTAMP() WHERE `id`=%d", quoted_name, g_playerip[id], g_playersteam[id], g_sql_pid[id]);
			
		SQL_ThreadQuery(DB_TUPLE,"QueryHandle",sql_query);
	}
	
	return PLUGIN_CONTINUE;
}

public QueryHandle_LoadPlayerTops(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new type[64], distance, maxspeed, prestrafe, strafes, sync, ddbh, tmp_str[12], pspeed, wpn[33];
	
	while(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery,0,type,64);
		distance = SQL_ReadResult(hQuery,1);
		maxspeed = SQL_ReadResult(hQuery,2);
		prestrafe = SQL_ReadResult(hQuery,3);
		strafes = SQL_ReadResult(hQuery,4);
		sync = SQL_ReadResult(hQuery,5);
		ddbh = SQL_ReadResult(hQuery,6);
		pspeed = SQL_ReadResult(hQuery,7);
		SQL_ReadResult(hQuery,8,wpn,32);
		
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "type", type);
		TrieSetCell(JumpStat, "distance", distance);
		TrieSetCell(JumpStat, "maxspeed", maxspeed);
		TrieSetCell(JumpStat, "prestrafe", prestrafe);
		TrieSetCell(JumpStat, "strafes", strafes);
		TrieSetCell(JumpStat, "sync", sync);
		TrieSetCell(JumpStat, "ddbh", ddbh);
		TrieSetCell(JumpStat, "pspeed", pspeed);
		TrieSetString(JumpStat, "wpn", wpn);
		
		num_to_str(g_sql_pid[cData[0]],tmp_str,11);
		
		format(type, 64, "%s_%s_%d", tmp_str, type, pspeed);
		TrieSetCell(JumpPlayers, type, JumpStat);
		
		SQL_NextRow(hQuery);
	}
	
	SQL_FreeHandle(hQuery);
	return PLUGIN_CONTINUE;
}

public QueryHandle_LoadPlayerTopsBlock(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new type[65],distance,jumpoff,block,tmp_str[12],pspeed,wpn[33];
	
	while(SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery,0,type,64);
		distance = SQL_ReadResult(hQuery,1);
		jumpoff = SQL_ReadResult(hQuery,2);
		block = SQL_ReadResult(hQuery,3);
		pspeed = SQL_ReadResult(hQuery,4);
		SQL_ReadResult(hQuery,5,wpn,32);
		
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		TrieSetString(JumpStat, "type", type);
		TrieSetCell(JumpStat, "distance", distance);
		TrieSetCell(JumpStat, "jumpoff", jumpoff);
		TrieSetCell(JumpStat, "block", block);
		TrieSetCell(JumpStat, "pspeed", pspeed);
		TrieSetString(JumpStat, "wpn", wpn);
		
		num_to_str(g_sql_pid[cData[0]],tmp_str,11);
		format(type, 64, "block_%s_%s_%d", tmp_str, type, pspeed);
		
		TrieSetCell(JumpPlayers, type, JumpStat); // Array[] => ["id"] = Datas
		
		SQL_NextRow(hQuery);
	}
	
	SQL_FreeHandle(hQuery);
	return PLUGIN_CONTINUE;
}

public QueryHandle_newPlayer(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if( iFailState != TQUERY_SUCCESS )
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new task_data[2];
	task_data[0] = SQL_GetInsertId(hQuery);
	task_data[1] = cData[0];
	
	set_task(1.0,"sql_check_reg",TASK_CHECK_SQL_PLAYER+cData[0],task_data,2);
	
	SQL_FreeHandle(hQuery);
	return PLUGIN_CONTINUE;
}

public sql_check_reg(args[]) {
	new id = args[1];
	new inserted_id = args[0];
	
	if(0 > id || id > get_maxplayers())
	{
		log_amx("Invalid id (%d) in sql_check_reg()", id);
		return PLUGIN_HANDLED;
	}
	else
	{
		if(inserted_id > 0)
		{			
			new tmp_str[12];
			new Trie:JumpData;
			JumpData = TrieCreate();
			
			g_sql_pid[id] = inserted_id;
			num_to_str(inserted_id,tmp_str,11);
			TrieSetCell(JumpPlayers, tmp_str, JumpData);
		} 
		else
		{
			log_amx("Bug? %s sql_id is %d; Retrying.",g_playername[id],inserted_id);
			player_load_info(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

/////////////////////////For future use/////////////////////////////
public save_info_sql()
{
	new createinto[256];
	
	for(new i=0;i<SQLCVARSNUM;i++)
	{
		formatex(createinto, 255, "INSERT INTO info_stats(cvar,val) VALUES('%s', '%d') ON DUPLICATE KEY UPDATE cvar='%s', val=%d",sql_Cvars[i], sql_Cvars_num[i],sql_Cvars[i], sql_Cvars_num[i]);
		SQL_ThreadQuery(DB_TUPLE, "QueryHandle", createinto);	
	}
	
	return PLUGIN_CONTINUE;
}

public PlayerSaveData_to_SQL(id, cData[]) {
	new jt_str[65], Trie:JS, tmp_str[12], distance, query[512], wpn[33], type[33];
	num_to_str(g_sql_pid[id],tmp_str,11);
	
	if(cData[8])
	{
		get_weaponname(cData[8],wpn,32);
		replace(wpn,32,"weapon_","");
	}
	else formatex(wpn,32,"Unknow");
	
	formatex(type,32,"%s",Type_List[cData[6]]);
	formatex(jt_str,64,"%s_%s_%d",tmp_str,Type_List[cData[6]],cData[7]);
	
	if(TrieKeyExists(JumpPlayers, jt_str)) // player is in trie
	{
		TrieGetCell(JumpPlayers, jt_str, JS);
		
		if(TrieKeyExists(JS, "distance")) // get distance
		{
			TrieGetCell(JS, "distance", distance);
			
			if(distance < cData[0]) // jumpdist > old jumpdist, updating
			{
				formatex(query, 511, "UPDATE uq_jumps SET distance=%d,maxspeed=%d,prestrafe=%d,strafes=%d,sync=%d,ddbh=%d,pspeed=%d,wpn='%s' WHERE pid=%d AND type LIKE '%s' AND pspeed=%d", cData[0], cData[1], cData[2], cData[3], cData[4], cData[5], cData[7], wpn, g_sql_pid[id], type, cData[7]);
					
				SQL_ThreadQuery(DB_TUPLE,"QueryHandle", query);
				TrieSetString(JS, "type", type);
				TrieSetCell(JS, "distance", cData[0]);
				TrieSetCell(JS, "maxspeed", cData[1]);
				TrieSetCell(JS, "prestrafe", cData[2]);
				TrieSetCell(JS, "strafes", cData[3]);
				TrieSetCell(JS, "sync", cData[4]);
				TrieSetCell(JS, "ddbh", cData[5]);
				TrieSetCell(JS, "pspeed", cData[7]);
				TrieSetString(JS, "wpn", wpn);
				
				TrieSetCell(JumpPlayers, jt_str, JS);
			}
		}
		else
		{
			log_amx("WTF?!");
		}
	}
	else // new jumptype to player, insert
	{
		formatex(query, 511, "INSERT INTO uq_jumps(pid,type,distance,maxspeed,prestrafe,strafes,sync,ddbh,pspeed,wpn) VALUES(%d,'%s',%d,%d,%d,%d,%d,%d,%d,'%s')", g_sql_pid[id], type, cData[0], cData[1], cData[2], cData[3], cData[4], cData[5], cData[7], wpn);
		
		new Trie:JumpStat;
		JumpStat = TrieCreate();
		
		SQL_ThreadQuery(DB_TUPLE,"QueryHandle", query);
		TrieSetString(JumpStat, "type", type);
		TrieSetCell(JumpStat, "distance", cData[0]);
		TrieSetCell(JumpStat, "maxspeed", cData[1]);
		TrieSetCell(JumpStat, "prestrafe", cData[2]);
		TrieSetCell(JumpStat, "strafes", cData[3]);
		TrieSetCell(JumpStat, "sync", cData[4]);
		TrieSetCell(JumpStat, "ddbh", cData[5]);
		TrieSetCell(JumpStat, "pspeed", cData[7]);
		TrieSetString(JumpStat, "wpn", wpn);
		
		TrieSetCell(JumpPlayers, jt_str, JumpStat);
	}
}
public PlayerSaveData_to_SQL_block(id, cData[]) {
	new block,jt_str[65], Trie:JS, tmp_str[12], distance, query[512], wpn[33], type[33];
	num_to_str(g_sql_pid[id],tmp_str,11);
	
	if(cData[5]) 
	{
		get_weaponname(cData[5],wpn,32);
		replace(wpn,32,"weapon_","");
	}
	else formatex(wpn,32,"Unknow");
	
	if(cData[3]==6)
	{
		formatex(type,32,"hj");
		formatex(jt_str,64,"block_%s_hj_%d",tmp_str,cData[4]);
	}
	else
	{
		formatex(type,32,"%s",Type_List[cData[3]]);
		formatex(jt_str,64,"block_%s_%s_%d",tmp_str,Type_List[cData[3]],cData[4]);
	}
	
	
	if(TrieKeyExists(JumpPlayers, jt_str)) // player is in trie
	{
		TrieGetCell(JumpPlayers, jt_str, JS);
			
		if(TrieKeyExists(JS, "block")) // get block
		{
			TrieGetCell(JS, "block", block);
			
			if(block <= cData[2]) //  block >= oldblock
			{
				if(TrieKeyExists(JS, "distance")) // get distance
				{
					TrieGetCell(JS, "distance", distance);
					
					if((distance < cData[0] && block==cData[2]) || (block<cData[2])) // jumpdist > old jumpdist if block=oldblock or update if block<oldblock, updating
					{
						
						formatex(query, 511, "UPDATE uq_block_tops SET distance=%d,jumpoff=%d,block=%d,pspeed=%d,wpn='%s' WHERE pid=%d AND type LIKE '%s' AND pspeed=%d", cData[0], cData[1], cData[2], cData[4], wpn, g_sql_pid[id], type, cData[4]);
						
						SQL_ThreadQuery(DB_TUPLE,"QueryHandle", query);
						TrieSetString(JS, "type", type);
						TrieSetCell(JS, "distance", cData[0]);
						TrieSetCell(JS, "jumpoff", cData[1]);
						TrieSetCell(JS, "block", cData[2]);
						TrieSetCell(JS, "pspeed", cData[4]);
						TrieSetString(JS, "wpn", wpn);
						
						TrieSetCell(JumpPlayers, jt_str, JS);
					}
				}
				else
				{
					log_amx("WTF?!");
				}
			}
		}
		else
		{
			log_amx("WTF?!");
		}
	}
	else // new jumptype to player, insert
	{
		
			formatex(query, 511, "INSERT INTO uq_block_tops(pid,type,distance,jumpoff,block,pspeed,wpn) VALUES(%d,'%s',%d,%d,%d,%d,'%s')", g_sql_pid[id], type, cData[0], cData[1], cData[2], cData[4], wpn);
			
			new Trie:JumpStat;
			JumpStat = TrieCreate();
			
			SQL_ThreadQuery(DB_TUPLE,"QueryHandle", query);
			TrieSetString(JumpStat, "type", type);
			TrieSetCell(JumpStat, "distance", cData[0]);
			TrieSetCell(JumpStat, "jumpoff", cData[1]);
			TrieSetCell(JumpStat, "block", cData[2]);
			TrieSetCell(JumpStat, "pspeed", cData[4]);
			TrieSetString(JumpStat, "wpn", wpn);
			
			TrieSetCell(JumpPlayers, jt_str, JumpStat);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <celltrie>
#include <sqlx>

#include <uq_jumpstats_const.inc>

#pragma semicolon 1

#define TOPS_VERSION "2.42"

new map_dist[NTOP+1],map_syncc[NTOP+1],map_maxsped[NTOP+1], map_prestr[NTOP+1],map_names[NTOP+1][33],map_ip[NTOP+1][33],map_streif[NTOP+1],map_type[NTOP+1][33];

new tmp_wpn_rank[33];
new ljsDir[64],ljsDir_weapon[8][64],ljsDir_block[64],ljsDir_block_weapon[8][64],plugin_version[33];

new pcvar_block_wpn,pcvar_extra,pcvar_block,pcvar_wpn,pcvar_top,pcvar_map,pcvar_prefix,pcvar_sql,pcvar_web,kz_sql,kz_web,Trie:JumpData,Trie:JumpData_Block;

new Handle:DB_TUPLE1,Handle:SqlConnection1,g_error[512];

new bool:loading_tops[33];
new prefix[64],top,maptop,wpn_top,block_top,extra_top,block_wpn_top;

public plugin_init()
{
	register_plugin( "Tops_JumpStats", TOPS_VERSION, "BorJomi" );
	
	register_dictionary("uq_jumpstats.txt");
	
	new dataDir[64];
	get_datadir(dataDir, 63);
	format(ljsDir, 63, "%s/Topljs", dataDir);
	format(ljsDir_block, 63, "%s/Topljs/block_tops", dataDir);
	
	if( !dir_exists(ljsDir) )
		mkdir(ljsDir);
		
	if( !dir_exists(ljsDir_block) )
		mkdir(ljsDir_block);
		
/////////////////////////////////////Standart Tops/////////////////////////////////////////////////////
		
	register_menucmd(register_menuid("StatsTopMenu1"),          1023, "TopMenu1");
	register_menucmd(register_menuid("StatsTopMenu2"),          1023, "TopMenu2");
	
	register_menucmd(register_menuid("ExtraMenu1"),          1023, "ExtraMenu1");
	register_menucmd(register_menuid("ExtraMenu2"),          1023, "ExtraMenu2");
	
	register_menucmd(register_menuid("Extra1"),          1023, "Extra1");
/////////////////////////////////////Block Tops/////////////////////////////////////////////////////
	
	register_menucmd(register_menuid("BlockMenu1"),          1023, "BlockTopMenu1");
	register_menucmd(register_menuid("BlockMenu2"),          1023, "BlockTopMenu2");
	
	register_menucmd(register_menuid("BlockExMenu1"),          1023, "BlockTopExMenu1");
	register_menucmd(register_menuid("BlockExMenu2"),          1023, "BlockTopExMenu2");
	
	register_menucmd(register_menuid("BlockEx1"),          1023, "BlockTopEx1");
/////////////////////////////////////Standart Weapon Tops/////////////////////////////////////////////////////	
	
	register_menucmd(register_menuid("WeaponMenu1"),          1023, "WeaponMenu1");
	register_menucmd(register_menuid("WeaponMenu2"),          1023, "WeaponMenu2");
	
	register_menucmd(register_menuid("StatsMainWpnMenu"),          1023, "MainWpnMenu");
/////////////////////////////////////Block Weapon Tops/////////////////////////////////////////////////////

	register_menucmd(register_menuid("BlockWpnMenu1"),          1023, "BlockWpnTopMenu1");
	register_menucmd(register_menuid("BlockWpnMenu2"),          1023, "BlockWpnTopMenu2");
	
	register_menucmd(register_menuid("BlockMainWpnMenu"),          1023, "BlockTopMainWpnMenu");
//////////////////////////////////////////////////////////////////////////////////////////	
	
	register_menucmd(register_menuid("BlockMainMenu"),          1023, "BlockMenu");
	
	register_clcmd( "say /myljtop",	"Mytops" );
	register_clcmd( "say /myljtops",	"Mytops" );
	register_clcmd( "say /mylj",	"Mytops" );
	
	register_clcmd( "say /weaponljtop",	"uqMainWpnMenu" );
	register_clcmd( "say /weaponsljtop",	"uqMainWpnMenu" );
	register_clcmd( "say /weaponlj",	"uqMainWpnMenu" );
	register_clcmd( "say /weaponslj",	"uqMainWpnMenu" );
	register_clcmd( "say /wpnlj",	"uqMainWpnMenu" );
	register_clcmd( "say /wpnljtop",	"uqMainWpnMenu" );
	register_clcmd( "say /wpnlj10",	"uqMainWpnMenu" );
	register_clcmd( "say /wpn10",	"uqMainWpnMenu" );
	
	register_clcmd( "say /dcj10",	"uqTopmenu1" );
	register_clcmd( "say /dcj15",	"uqTopmenu1" );
	register_clcmd( "say /dcjtop",	"uqTopmenu1" );
	register_clcmd( "say /dcjtop10", "uqTopmenu1" );
	register_clcmd( "say /dcjtop15", "uqTopmenu1" );
	register_clcmd( "say /lj10",	"uqTopmenu1" );
	register_clcmd( "say /lj15",	"uqTopmenu1" );
	register_clcmd( "say /ljtop",	"uqTopmenu1" );
	register_clcmd( "say /ljtop10", "uqTopmenu1" );
	register_clcmd( "say /ljtop15", "uqTopmenu1" );
	register_clcmd( "say /cj10",	"uqTopmenu1" );
	register_clcmd( "say /cj15",	"uqTopmenu1" );
	register_clcmd( "say /cjtop",	"uqTopmenu1" );
	register_clcmd( "say /cjtop10", "uqTopmenu1" );
	register_clcmd( "say /cjtop15", "uqTopmenu1" );
	register_clcmd( "say /hj10",	"uqTopmenu1" );
	register_clcmd( "say /hj15",	"uqTopmenu1" );
	register_clcmd( "say /hjtop",	"uqTopmenu1" );
	register_clcmd( "say /hjtop10", "uqTopmenu1" );
	register_clcmd( "say /hjtop15", "uqTopmenu1" );
	register_clcmd( "say /wj10",	"uqTopmenu1" );
	register_clcmd( "say /wj15",	"uqTopmenu1" );
	register_clcmd( "say /wjtop",	"uqTopmenu1" );
	register_clcmd( "say /wjtop10", "uqTopmenu1" );
	register_clcmd( "say /wjtop15", "uqTopmenu1" );
	register_clcmd( "say /bj10",	"uqTopmenu1" );
	register_clcmd( "say /bj15",	"uqTopmenu1" );
	register_clcmd( "say /bjtop",	"uqTopmenu1" );
	register_clcmd( "say /bjtop10", "uqTopmenu1" );
	register_clcmd( "say /bjtop15", "uqTopmenu1" );
	
	register_clcmd( "say /block10", "uqTopmenublocks" );
	register_clcmd( "say /blocktop", "uqTopmenublocks" );
	register_clcmd( "say /blocktops", "uqTopmenublocks" );
	
	register_concmd("amx_reset_uqtops","reset_tops",ADMIN_CVAR ,"reset all tops");
		
	
}
public plugin_cfg()
{
	new plugin_id=find_plugin_byfile("uq_jumpstats.amxx");
	new filename[33],plugin_name[33],plugin_author[33],status[33];
	
	get_plugin(plugin_id,filename,32,plugin_name,32,plugin_version,32,plugin_author,32,status,32); 
	
	if(!equali(plugin_version,TOPS_VERSION))
	{
		set_task(5.0,"Wrong_version");
	}
	
	pcvar_sql=get_cvar_pointer("kz_uq_sql");
	pcvar_web=get_cvar_pointer("kz_uq_web");
	pcvar_prefix=get_cvar_pointer("kz_uq_prefix");
	pcvar_top=get_cvar_pointer("kz_uq_save_top");
	pcvar_map=get_cvar_pointer("kz_uq_maptop");
	pcvar_wpn=get_cvar_pointer("kz_uq_weapons_top");
	pcvar_block=get_cvar_pointer("kz_uq_block_top");
	pcvar_extra=get_cvar_pointer("kz_uq_save_extras_top");
	pcvar_block_wpn=get_cvar_pointer("kz_uq_block_weapons");
	
	block_wpn_top=get_pcvar_num(pcvar_block_wpn);
	extra_top=get_pcvar_num(pcvar_extra);
	block_top=get_pcvar_num(pcvar_block);
	wpn_top=get_pcvar_num(pcvar_wpn);
	top=get_pcvar_num(pcvar_top);
	maptop=get_pcvar_num(pcvar_map);
	kz_sql=get_pcvar_num(pcvar_sql);
	kz_web=get_pcvar_num(pcvar_web);
	get_pcvar_string(pcvar_prefix,prefix,63);
	
	//rank=get_cvar_num("kz_uq_top_by");
	new profile[128];
	formatex(profile, 127, "%s/Top10_maptop.dat", ljsDir);
	
	if( file_exists(profile) )
	{
		delete_file(profile);
	}
	
	if(kz_sql==1)
	{
		set_task(0.3, "tops_sql");
		
		JumpData = TrieCreate();
		JumpData_Block = TrieCreate();
	}
	else if(kz_sql==0)
	{
		JumpData = TrieCreate();
		JumpData_Block = TrieCreate();
			
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
		}
	}
}
public tops_sql()
{
	new host[64], user[64], pass[64], db[64];

	get_cvar_string("kz_uq_host", host, 63);
	get_cvar_string("kz_uq_user", user, 63);
	get_cvar_string("kz_uq_pass", pass, 63);
	get_cvar_string("kz_uq_db", db, 63);
	
	DB_TUPLE1 = SQL_MakeDbTuple(host, user, pass, db);
	
	new error;
	SqlConnection1 = SQL_Connect(DB_TUPLE1,error,g_error,511);
	
	if(!SqlConnection1) 
	{
		server_print("uq_jumpstats: Could not connect to SQL database; Error #%d: %s", error, g_error);
		log_amx("uq_jumpstats: Could not connect to SQL database; Error #%d: %s", error, g_error);
		return pause("a");
	}
	
	return PLUGIN_CONTINUE;
}
public client_connect(id)
{
	loading_tops[id]=false;
}
public Wrong_version()
{
	for(new i=1;i<get_maxplayers();i++)
	{
		if(is_user_alive(i) && is_user_connected(i))
			ColorChat(i, RED, "^x04Version^x03 uq_jumpstats.amxx^x01(%s)^x04 different from^x03 uq_jumpstats_tops.amxx^x01(%s)",plugin_version,TOPS_VERSION);	
	}
	
	set_task(5.0,"Wrong_version");
}
public Mytops(id)
{
	if(kz_web==1)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS1");
	}
	else
	{
		static rankby;	
		new authid[32];
		
		rankby = get_cvar_num("kz_uq_top_by");
		
		if( rankby == 0 )
			get_user_name(id, authid, 31);
		if( rankby == 1 )
			get_user_ip(id, authid, 31, 1);
		if( rankby == 2 )
			get_user_authid(id, authid ,32);
			
		new tech_num;
		new my_dist[NTECHNUM+1],my_technique[NTECHNUM+1][33],topPlace[NTECHNUM+1];
		for(new i=0;i<NTECHNUM;i++)
		{
			if(kz_sql==1)
			{
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS2",prefix);
				return PLUGIN_HANDLED;
			}
			else if(kz_sql==0)
			{
				read_tops(Type_List[i],i,0,id,0);
			}
			else
			{
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS3",prefix);
				
				return PLUGIN_HANDLED;
			}
			
			
			for(new j=0;j<NTOP;j++)
			{
				new Trie:JS;
				new tmp_ip[33],distance;
				new tmp_type[33];
			
				format(tmp_type, 32, "%s_%d_250", Type_List[i], j);
				
				if(TrieKeyExists(JumpData, tmp_type))
				{	
					TrieGetCell(JumpData, tmp_type, JS);
					
					TrieGetCell(JS, "distance", distance);
					TrieGetString(JS,"authid",tmp_ip,32);
				}
				
				if(equali(tmp_ip,authid))
				{
					formatex(my_technique[tech_num],32,Type_List[i]);
					my_dist[tech_num]=distance;
					topPlace[tech_num]=j+1;
					tech_num++;
				}
			}
		}
		show_mytop(id,authid,my_technique,my_dist,topPlace,tech_num);
	}
	return PLUGIN_CONTINUE;
}
public pid_in_name(mode,max_place,num,id,type[],pspeed,type_num,pid, distance, maxspeed, prestrafe, strafes, sync, ddbh,wpn[])
{
	
	new tmp_type[33];

	format(tmp_type, 32, "%s_%d_%d", type, num,pspeed);
	
	new sql_query[512],cData[44];
	formatex(cData,17,type);	
	cData[18]=id;
	cData[19]=num;
	cData[20]=pspeed;
	cData[21]=type_num;
	cData[22]=distance;
	cData[23]=maxspeed;
	cData[24]=prestrafe;
	cData[25]=strafes;
	cData[26]=sync;
	cData[27]=ddbh;
	cData[28]=max_place;
	cData[29]=mode;
	
	for(new i=0;i<14;i++)
	{
		formatex(cData[30+i],1,wpn[i]);
		
	}
	
	formatex(sql_query, 511, "SELECT name FROM uq_players WHERE id=%d",pid);
	SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_pidName", sql_query, cData, 45);
	
}
public QueryHandle_pidName(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new mode,num,type[18],id,type_num,pspeed,max_place,wpn[14];
	new name[33],distance, maxspeed, prestrafe, strafes, sync, ddbh;

	formatex(type,17,cData);
	type_num=cData[21];
	pspeed=cData[20];
	num=cData[19];
	id=cData[18];
	distance=cData[22];
	maxspeed=cData[23];
	prestrafe=cData[24];
	strafes=cData[25];
	sync=cData[26];
	ddbh=cData[27];
	max_place=cData[28];
	mode=cData[29];
	
	for(new i=0;i<14;i++)
	{
		formatex(wpn[i],1,cData[30+i]);
	}
	
	if (!SQL_NumResults(hQuery))
	{
		log_amx("Bug with id=0");
		
		name="unknow";
	}
	else
	{
		SQL_ReadResult(hQuery,0,name,33);
	}

	new Trie:JumpStat;
	JumpStat = TrieCreate();
	
	TrieSetString(JumpStat, "name", name);
	TrieSetCell(JumpStat, "distance", distance);
	TrieSetCell(JumpStat, "maxspeed", maxspeed);
	TrieSetCell(JumpStat, "prestrafe", prestrafe);
	TrieSetCell(JumpStat, "strafes", strafes);
	TrieSetCell(JumpStat, "sync", sync);
	TrieSetCell(JumpStat, "ddbh", ddbh);
	TrieSetCell(JumpStat, "pspeed", pspeed);
	TrieSetString(JumpStat, "wpn", wpn);
	
	new tmp_type[33];
	formatex(tmp_type,32,"%s_%d_%d",type,num,pspeed);
	
	TrieSetCell(JumpData, tmp_type, JumpStat);
	
	SQL_FreeHandle(hQuery);
	
	if(num==max_place-1) 
	{
		if(pspeed==250)
		{
			show_tops_tmp(id,type,type_num);
			switch(mode)
			{
				case 0:
					uqTopmenu1(id);
				case 1:
					uqTopmenu2(id);
				case 2:
					uqmenuExtra1(id);
				case 3:
					uqmenuExtra2(id);
				case 4:
					uqExtra1(id);
			}
		}
		else 
		{
			tmp_show_tops_weapon(id,type,type_num,weapon_rank(pspeed));
			switch(mode)
			{
				case 0:
					uqTopmenuWpn1(id,weapon_rank(pspeed));
				case 1:
					uqTopmenuWpn2(id,weapon_rank(pspeed));
			}
		}
		loading_tops[id]=false;
	}
	else
	{
		new load=100/max_place;
		
		if(pspeed==250)
		{
			set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
			show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS4",type,(num+2)*load);
		}
		else
		{
			set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
			show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS5",type,pspeed,(num+2)*load);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public show_mytop(id,authid[32],my_technique[][33],my_dist[],topPlace[],tech_num)
{	
	static buffer[2368], len, i;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;font-size:12px}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS6");
		
	for( i = INFO_ZERO; i < tech_num; i++ )
	{		
		if( my_dist[i] == 0)
		{
			len += format(buffer[len], 2367-len, "<tr align=center%s><td align=left> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", "-", "-", "-");
			i=tech_num;
		}
		else
		{
			if(topPlace[i]==1)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td align=left> %s <td> %d.%01d <td><font color=red> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", my_technique[i], (my_dist[i]/1000000), (my_dist[i]%1000000/100000),topPlace[i]);
			}
			else if(topPlace[i]==2)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td align=left> %s <td> %d.%01d <td><font color=green> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", my_technique[i], (my_dist[i]/1000000), (my_dist[i]%1000000/100000),topPlace[i]);
			}
			else if(topPlace[i]==3)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td align=left> %s <td> %d.%01d <td><font color=orange> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", my_technique[i], (my_dist[i]/1000000), (my_dist[i]%1000000/100000),topPlace[i]);
			}
			else len += format(buffer[len], 2367-len, "<tr align=center%s><td align=left> %s <td> %d.%01d <td> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", my_technique[i], (my_dist[i]/1000000), (my_dist[i]%1000000/100000),topPlace[i]);
	
		}
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	
	new name[33];
	static strin[86];
	
	get_user_name(id,name,32);
	format(strin,85, "%L",LANG_SERVER,"UQSTATS_TOPS7",name,authid);
	show_motd(id, buffer, strin);
}
public sql_show(id,mode)
{
	new stringscvar[356];
	static buffer[356];
	get_cvar_string("kz_uq_url", stringscvar, 355);
	
	if(mode==0)
	{
		formatex(buffer, 355, "%s", stringscvar);
	}
	else
	{
		new tmp_str[]="&sort=block&p=0&speed=250&subtype=block";
		formatex(buffer, 355, "%s", stringscvar);
		add(buffer,355,tmp_str);
	}
	show_motd(id,buffer,"JumpStats Tops");
}
public read_maptop()
{
	new profile[128],prodata[256];
	formatex(profile, 127, "%s/Top10_maptop.dat", ljsDir);
	
	new f = fopen(profile, "rt" );
	new i = 0;
	while( !feof(f) && i < NTOP)
	{
		fgets(f, prodata, 255);
		new d[25], m[25], p[25], sf[25],s[25];
		parse(prodata, map_names[i], 31, map_ip[i], 31,  d, 25, m, 25, p, 25, sf, 25,s, 25,map_type[i], 31);
		map_dist[i]= str_to_num(d);
		map_maxsped[i]= str_to_num(m);
		map_prestr[i] = str_to_num(p);
		map_streif[i] = str_to_num(sf);
		map_syncc[i] = str_to_num(s);
		i++;
	}
	fclose(f);
}
public read_tops(type[],type_num,mode,id,show_mode)
{
	switch(mode)
	{
		case 0:
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
		
				TrieSetCell(JumpData, tmp_type, JumpStat);
				
				i++;
			}
			fclose(f);
		}
		case 1:
		{
			new sql_query[512],cData[24];
			formatex(cData,17,type);
			cData[19]=id;
			cData[20]=show_mode;
			cData[21]=0;
			cData[22]=250;
			
			formatex(sql_query, 511, "SELECT pid FROM uq_jumps WHERE type='%s' and pspeed=250 LIMIT %d", type,NSHOW);
			SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_type_place", sql_query, cData, 23);
		}
	}
}
public QueryHandle_type_place(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new id=cData[19];
	new mode=cData[20];
	new weapon_top=cData[21];
	new pspeed=cData[22];
	
	formatex(cData,17,cData);
	
	
	new i=0;
	while(SQL_MoreResults(hQuery))
	{
		i++;
		SQL_NextRow(hQuery);
	}
	
	SQL_FreeHandle(hQuery);
	
	new sql_query[512],bData[25];
	formatex(bData,17,cData);
	bData[19]=id;
	bData[20]=i;
	bData[21]=mode;
	bData[22]=weapon_top;
	bData[23]=pspeed;
	
	if(weapon_top==0)
	{
		set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
		show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS9",cData);
	}
	else
	{
		set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
		show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS10",cData,pspeed);
	}
	
	formatex(sql_query, 511, "SELECT pid,distance,maxspeed,prestrafe,strafes,sync,ddbh,pspeed,wpn FROM uq_jumps WHERE type='%s' and pspeed=%d ORDER BY distance DESC LIMIT %d", cData,pspeed,NSHOW);
	SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_LoadTops", sql_query, bData, 24);
	
	return PLUGIN_CONTINUE;
}
public QueryHandle_LoadTops(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new id=cData[19];
	new max_place=cData[20];
	new mode=cData[21];
	new weapon_top=cData[22];
	new pspeed=cData[23];
	
	
	formatex(cData,17,cData);
	
	new t_pspeed[NSHOW+1],pid[NSHOW+1], distance[NSHOW+1], maxspeed[NSHOW+1], prestrafe[NSHOW+1], strafes[NSHOW+1], sync[NSHOW+1], ddbh[NSHOW+1],wpn[NSHOW+1][15];
	new tmp_type;
	
	if(weapon_top==0)
	{
		for(new i=0;i<NTECHNUM;i++)
		{
			if(equali(cData,Type_List[i]))
			{
				tmp_type=i;
			}
		}
	}
	else
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			if(equali(cData,Type_List_weapon[i]))
			{
				tmp_type=i;
			}
		}
	}

	new i=0;
	while(SQL_MoreResults(hQuery))
	{
		pid[i] = SQL_ReadResult(hQuery,0);
		distance[i] = SQL_ReadResult(hQuery,1);
		maxspeed[i] = SQL_ReadResult(hQuery,2);
		prestrafe[i] = SQL_ReadResult(hQuery,3);
		strafes[i] = SQL_ReadResult(hQuery,4);
		sync[i] = SQL_ReadResult(hQuery,5);
		ddbh[i] = SQL_ReadResult(hQuery,6);
		t_pspeed[i] = SQL_ReadResult(hQuery,7);
		SQL_ReadResult(hQuery,8,wpn[i],24);

		pid_in_name(mode,max_place,i,id,cData,t_pspeed[i],tmp_type,pid[i], distance[i], maxspeed[i], prestrafe[i], strafes[i], sync[i], ddbh[i],wpn[i]);
		
		i++;
		SQL_NextRow(hQuery);
	}
	
	if(i==0)
	{
		if(weapon_top==0)
		{
			show_tops_tmp(id,cData,tmp_type);
			switch(mode)
			{
				case 0:
					uqTopmenu1(id);
				case 1:
					uqTopmenu2(id);
				case 2:
					uqmenuExtra1(id);
				case 3:
					uqmenuExtra2(id);
				case 4:
					uqExtra1(id);
			}
		}
		else 
		{
			tmp_show_tops_weapon(id,cData,tmp_type,weapon_rank(pspeed));
			switch(mode)
			{
				case 0:
					uqTopmenuWpn1(id,weapon_rank(pspeed));
				case 1:
					uqTopmenuWpn2(id,weapon_rank(pspeed));
			}
		}
		
		
		loading_tops[id]=false;	
	}
	SQL_FreeHandle(hQuery);
	
	
	
	return PLUGIN_CONTINUE;
}

public pid_in_name_block(mode,max_place,num,id,type[],pspeed,type_num,pid, distance, jumpoff, block,wpn[])
{
	
	new tmp_type[33];

	format(tmp_type, 32, "Block_%s_%d_%d", type, num,pspeed);
	
	new sql_query[512],cData[44];
	formatex(cData,17,type);	
	cData[18]=id;
	cData[19]=num;
	cData[20]=pspeed;
	cData[21]=type_num;
	cData[22]=distance;
	cData[23]=jumpoff;
	cData[24]=block;
	cData[25]=max_place;
	cData[26]=mode;
	
	for(new i=0;i<14;i++)
	{
		formatex(cData[27+i],1,wpn[i]);
		
	}
	
	formatex(sql_query, 511, "SELECT name FROM uq_players WHERE id=%d",pid);
	SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_pidName_block", sql_query, cData, 45);
	
}
public QueryHandle_pidName_block(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new block,mode,num,type[18],id,type_num,pspeed,max_place,wpn[14];
	new name[33],distance, Float:jumpoff;

	formatex(type,17,cData);
	type_num=cData[21];
	pspeed=cData[20];
	num=cData[19];
	id=cData[18];
	distance=cData[22];
	jumpoff=cData[23]/1000000.0;
	block=cData[24];
	max_place=cData[25];
	mode=cData[26];
	
	for(new i=0;i<14;i++)
	{
		formatex(wpn[i],1,cData[27+i]);
	}
	
	SQL_ReadResult(hQuery,0,name,33);
	
	new Trie:JumpStat;
	JumpStat = TrieCreate();
	
	TrieSetString(JumpStat, "name", name);
	TrieSetCell(JumpStat, "distance", distance);
	TrieSetCell(JumpStat, "jumpoff", jumpoff);
	TrieSetCell(JumpStat, "block", block);
	TrieSetCell(JumpStat, "pspeed", pspeed);
	TrieSetString(JumpStat, "wpn", wpn);
	
	new tmp_type[33];
	formatex(tmp_type,32,"block_%s_%d_%d",type,num,pspeed);
	
	TrieSetCell(JumpData_Block, tmp_type, JumpStat);
	
	SQL_FreeHandle(hQuery);
	
	if(num==max_place-1) 
	{
		if(pspeed==250)
		{
			show_tops_block_tmp(id,type,type_num);
			switch(mode)
			{
				case 0:
					uqBlockTopmenu1(id);
				case 1:
					uqBlockTopmenu2(id);
				case 2:
					uqmenuBlockEx1(id);
				case 3:
					uqmenuBlockEx2(id);
				case 4:
					uqBlockEx1(id);
			}
		}
		else 
		{
			show_tops_block_weapon_tmp(id,type,type_num,weapon_rank(pspeed));
			switch(mode)
			{
				case 0:
					uqBlockTopmenuWpn1(id,weapon_rank(pspeed));
				case 1:
					uqBlockTopmenuWpn2(id,weapon_rank(pspeed));
			}
		}
		loading_tops[id]=false;
	}
	else
	{
		new load=100/max_place;
		
		if(pspeed==250)
		{
			set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
			show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS11",type,(num+2)*load);
		}
		else
		{
			set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
			show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS12",type,pspeed,(num+2)*load);
		}
	}
		
	return PLUGIN_CONTINUE;
}
public read_tops_block(type[],type_num,mode,id,show_mode)
{
	switch(mode)
	{
		case 0:
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
				format(tmp_type, 32, "block_%s_%d_250", type, i);
		
				TrieSetCell(JumpData_Block, tmp_type, JumpStat);
				i++;
			}
			fclose(f);
		}
		case 1:
		{
			new sql_query[512],cData[24];
			if(type_num==6)
			{
				formatex(type,18,"hj");
			}			
			formatex(cData,17,type);
			
			cData[19]=id;
			cData[20]=show_mode;
			cData[21]=0;
			cData[22]=250;
			
			formatex(sql_query, 511, "SELECT pid FROM uq_block_tops WHERE type='%s' and pspeed=250 LIMIT %d", type,NSHOW);
			SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_type_place_block", sql_query, cData, 23);
		}
	}
}
public QueryHandle_type_place_block(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new id=cData[19];
	new mode=cData[20];
	new weapon_top=cData[21];
	new pspeed=cData[22];
	
	formatex(cData,17,cData);
	
	new i=0;
	while(SQL_MoreResults(hQuery))
	{
		i++;
		SQL_NextRow(hQuery);
	}
	
	SQL_FreeHandle(hQuery);
	
	new sql_query[512],bData[25];
	formatex(bData,17,cData);
	bData[19]=id;
	bData[20]=i;
	bData[21]=mode;
	bData[22]=weapon_top;
	bData[23]=pspeed;
	
	if(weapon_top==0)
	{
		set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
		show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS13",cData);
	}
	else
	{
		set_hudmessage(255, 0, 109, 0.05, 0.5, 0, 6.0, 0.3);
		show_hudmessage(id, "%L",LANG_SERVER,"UQSTATS_TOPS14",cData,pspeed);
	}
	
	formatex(sql_query, 511, "SELECT pid,distance,jumpoff,block,pspeed,wpn FROM uq_block_tops WHERE type='%s' and pspeed=%d ORDER BY block DESC,distance DESC LIMIT %d", cData,pspeed,NSHOW);
	SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_LoadTops_block", sql_query, bData, 24);
	
	return PLUGIN_CONTINUE;
}
public QueryHandle_LoadTops_block(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	
	if(iFailState != TQUERY_SUCCESS)
	{
		log_amx("uq_jumpstats: SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}
	
	new id=cData[19];
	new max_place=cData[20];
	new mode=cData[21];
	new weapon_top=cData[22];
	new pspeed=cData[23];
	
	
	formatex(cData,17,cData);
	
	new t_pspeed[NSHOW+1],pid[NSHOW+1], distance[NSHOW+1], jumpoff[NSHOW+1], block[NSHOW+1],wpn[NSHOW+1][15];
	new tmp_type;
	
	if(weapon_top==0)
	{
		for(new i=0;i<NTECHNUM;i++)
		{
			if(equali(cData,Type_List[i]))
			{
				tmp_type=i;
			}
		}
		if(equali(cData,"hj"))
		{
			tmp_type=6;
		}
	}
	else
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			if(equali(cData,Type_List_weapon[i]))
			{
				tmp_type=i;
			}
		}
		if(equali(cData,"hj"))
		{
			tmp_type=9;
		}
	}

	new i=0;
	while(SQL_MoreResults(hQuery))
	{
		pid[i] = SQL_ReadResult(hQuery,0);
		distance[i] = SQL_ReadResult(hQuery,1);
		jumpoff[i] = SQL_ReadResult(hQuery,2);
		block[i] = SQL_ReadResult(hQuery,3);
		t_pspeed[i] = SQL_ReadResult(hQuery,4);
		SQL_ReadResult(hQuery,5,wpn[i],24);

		pid_in_name_block(mode,max_place,i,id,cData,t_pspeed[i],tmp_type,pid[i], distance[i], jumpoff[i], block[i],wpn[i]);
		
		i++;
		SQL_NextRow(hQuery);
	}
	
	if(i==0)
	{
		if(weapon_top==0)
		{
			show_tops_block_tmp(id,cData,tmp_type);
			switch(mode)
			{
				case 0:
					uqBlockTopmenu1(id);
				case 1:
					uqBlockTopmenu2(id);
				case 2:
					uqmenuBlockEx1(id);
				case 3:
					uqmenuBlockEx2(id);
				case 4:
					uqBlockEx1(id);
			}
		}
		else 
		{
			show_tops_block_weapon_tmp(id,cData,tmp_type,weapon_rank(pspeed));
			switch(mode)
			{
				case 0:
					uqBlockTopmenuWpn1(id,weapon_rank(pspeed));
				case 1:
					uqBlockTopmenuWpn2(id,weapon_rank(pspeed));
			}
		}
		
		
		loading_tops[id]=false;	
	}
	SQL_FreeHandle(hQuery);
	
	
	
	return PLUGIN_CONTINUE;
}
public read_tops_block_weapon(type[],type_num,wpn_rank,mode,id,show_mode)
{
	switch(mode)
	{
		case 0:
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
				TrieSetString(JumpStat, "wpn", tmp_weap_name);
				
				new tmp_type[33];
				format(tmp_type, 32, "block_%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
				TrieSetCell(JumpData_Block, tmp_type, JumpStat);
				i++;
			}
			fclose(f);
		}
		case 1:
		{
			new sql_query[512],cData[24];
			formatex(cData,17,type);
			cData[19]=id;
			cData[20]=show_mode;
			cData[21]=1;
			cData[22]=weapon_maxspeed(wpn_rank);
			
			formatex(sql_query, 511, "SELECT pid FROM uq_jumps WHERE type='%s' and pspeed=%d LIMIT %d", type,weapon_maxspeed(wpn_rank),NSHOW);
			SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_type_place_block", sql_query, cData, 23);
		}
	}
}
public read_tops_weapon(type[],type_num,wpn_rank,mode,id,show_mode)
{	
	switch(mode)
	{
		case 0:
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
				TrieSetCell(JumpStat, "distance", str_to_num(d));
				TrieSetCell(JumpStat, "maxspeed", str_to_num(m));
				TrieSetCell(JumpStat, "prestrafe", str_to_num(p));
				TrieSetCell(JumpStat, "strafes", str_to_num(sf));
				TrieSetCell(JumpStat, "sync", str_to_num(s));
				TrieSetCell(JumpStat, "pspeed", weapon_maxspeed(wpn_rank));
				TrieSetString(JumpStat, "wpn", tmp_weap_name);
				
				new tmp_type[33];
				format(tmp_type, 32, "%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
				
				TrieSetCell(JumpData, tmp_type, JumpStat);
				i++;
			}
			fclose(f);
		}
		case 1:
		{
			new sql_query[512],cData[24];
			formatex(cData,17,type);
			cData[19]=id;
			cData[20]=show_mode;
			cData[21]=1;
			cData[22]=weapon_maxspeed(wpn_rank);
			
			formatex(sql_query, 511, "SELECT pid FROM uq_jumps WHERE type='%s' and pspeed=%d LIMIT %d", type,weapon_maxspeed(wpn_rank),NSHOW);
			SQL_ThreadQuery(DB_TUPLE1,"QueryHandle_type_place", sql_query, cData, 23);
			
		}
	}
}

public show_tops(id,type[],type_num,mode)
{
	loading_tops[id]=true;
	if(kz_sql==1 && kz_web==0)
	{
		read_tops(type,type_num,1,id,mode);
	}
	else show_tops_tmp(id,type,type_num);
}
public show_tops_tmp(id,type[],type_num)
{	
	loading_tops[id]=false;
	
	static buffer[2368], name[128], len, i;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;line-height:160%%;font-size:12px}.q{border:1px solid #4a4945}.b{background:#2a2a2a}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	
	if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
	{
		if(type_num==24)
		{
			len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS15");
		}
		else len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS16");
	}
	else len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS17");
		
	for( i = INFO_ZERO; i < NSHOW; i++ )
	{		
		
		new Trie:JS;
		new tmp_names[33],distance,maxspeed,prestrafe,strafes,sync,ddbh;
		new tmp_type[33];
	
		format(tmp_type, 32, "%s_%d_250", type, i);
		
		if(TrieKeyExists(JumpData, tmp_type))
		{	
			TrieGetCell(JumpData, tmp_type, JS);
			
			TrieGetCell(JS, "distance", distance);
			TrieGetCell(JS, "maxspeed", maxspeed);
			TrieGetCell(JS, "prestrafe", prestrafe);
			TrieGetCell(JS, "strafes", strafes);
			TrieGetCell(JS, "sync", sync);
			TrieGetString(JS,"name",tmp_names,32);
					
			if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
			{
				TrieGetCell(JS, "ddbh", ddbh);	
			}
		}
		
		
		if( distance == 0)
		{
			if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-", "-", "-", "-");
			}
			else len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-", "-", "-");
			
			i=NSHOW;
		}
		else
		{
			name = tmp_names;
			while( containi(name, "<") != -1 )
				replace(name, 127, "<", "&lt;");
			while( containi(name, ">") != -1 )
				replace(name, 127, ">", "&gt;");
				
			if(type_num==21 || type_num==22 || type_num==23 || type_num==24 || type_num==25)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d.%01d <td> %d.%01d <td> %d.%01d <td> %d <td> %d <td> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name, (distance/1000000), (distance%1000000/100000), (maxspeed/1000000), (maxspeed%1000000/100000), (prestrafe/1000000), (prestrafe%1000000/100000), strafes,sync,ddbh);
			}
			else len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d.%01d <td> %d.%01d <td> %d.%01d <td> %d <td> %d", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name, (distance/1000000), (distance%1000000/100000), (maxspeed/1000000), (maxspeed%1000000/100000), (prestrafe/1000000), (prestrafe%1000000/100000), strafes,sync);
		}
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	
	static strin[20];
	format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS18", NSHOW,Type_List[type_num]);
	
	show_motd(id, buffer, strin);
}
public show_tops_block(id,type[],type_num,mode)
{
	if(kz_sql==1 && kz_web==0)
	{
		read_tops_block(type,type_num,1,id,mode);
	}
	else show_tops_block_tmp(id,type,type_num);
}
public show_tops_block_tmp(id,type[],type_num)
{	
	static buffer[2368], name[128], len, i;
	new oldblock,Float:find_jumpoff[NTOP+1];
	
	new tmp_oldtype[33];
	new Trie:JS_old, block_for_old;
	
	for( i = INFO_ZERO; i < NSHOW; i++ )
	{
		format(tmp_oldtype, 32, "block_%s_%d_250", type,i);
			
		if(TrieKeyExists(JumpData_Block, tmp_oldtype))
		{	
			TrieGetCell(JumpData_Block, tmp_oldtype, JS_old);
			
			if(i==0) TrieGetCell(JS_old, "block", block_for_old);
			
			TrieGetCell(JS_old, "jumpoff", find_jumpoff[i]);
		}
	}
	
	new Float:minjof=find_min_jumpoff(find_jumpoff);
	oldblock=block_for_old;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;font-size:12px}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS19");
	
	new oldjj,jj;
	for( i = INFO_ZERO,jj=1; i < NSHOW; i++ )
	{	
		new Trie:JS;
		new tmp_names[33],distance,Float:jumpoff,block;
		new tmp_type[33];
	
		format(tmp_type, 32, "block_%s_%d_250", type, i);
		
		if(TrieKeyExists(JumpData_Block, tmp_type))
		{	
			TrieGetCell(JumpData_Block, tmp_type, JS);
			
			TrieGetCell(JS, "distance", distance);
			TrieGetCell(JS, "jumpoff", jumpoff);
			TrieGetCell(JS, "block", block);
			TrieGetString(JS,"name",tmp_names,32);
		}
		
		if(oldblock!=block)
		{
			len += format(buffer[len], 2367-len, "<tr><td COLSPAN=9><br></td></tr>");
			
			if((jj%2)==0)
			{
				jj=oldjj;
			}
		}
		if( block == 0)
		{
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-");
			i=NSHOW;
		}
		else
		{
			name = tmp_names;
			while( containi(name, "<") != -1 )
				replace(name, 127, "<", "&lt;");
			while( containi(name, ">") != -1 )
				replace(name, 127, ">", "&gt;");
			if(minjof==jumpoff)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d <td> %d.%01d <td><font color=red> %f <td>", ((jj%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name,block, (distance/1000000), (distance%1000000/100000), jumpoff);
			}
			else len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d <td> %d.%01d <td> %0.4f <td>", ((jj%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name,block, (distance/1000000), (distance%1000000/100000), jumpoff);
		}
		
		oldblock=block;
		oldjj=jj;
		jj++;
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	static strin[20];
	
	if(type_num==6)
	{
		format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS20",NSHOW);
	}
	else format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS21", NSHOW,type);
	
	show_motd(id, buffer, strin);
}
public show_tops_block_weapon(id,type[],type_num,wpn_rank,mode)
{
	if(kz_sql==1 && kz_web==0)
	{
		read_tops_block_weapon(type,type_num,wpn_rank,1,id,mode);
	}
	else show_tops_block_weapon_tmp(id,type,type_num,wpn_rank);
}
public show_tops_block_weapon_tmp(id,type[],type_num,wpn_rank)
{	
	static buffer[2368], name[128], len, i;
	new oldblock,Float:find_jumpoff[NTOP+1];
	
	new tmp_oldtype[33];
	new Trie:JS_old, block_for_old;
	
	for( i = INFO_ZERO; i < NSHOW; i++ )
	{
		format(tmp_oldtype, 32, "block_%s_%d_%d", type,i,weapon_maxspeed(wpn_rank));
			
		if(TrieKeyExists(JumpData_Block, tmp_oldtype))
		{	
			TrieGetCell(JumpData_Block, tmp_oldtype, JS_old);
			
			if(i==0) TrieGetCell(JS_old, "block", block_for_old);
			
			TrieGetCell(JS_old, "jumpoff", find_jumpoff[i]);
		}
	}
	
	new Float:minjof=find_min_jumpoff(find_jumpoff);
	oldblock=block_for_old;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;font-size:12px}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS22");
	
	new oldjj,jj;
	for( i = INFO_ZERO,jj=1; i < NSHOW-2; i++ )
	{	
		new Trie:JS;
		new tmp_names[33],tmp_weap_names[33],distance,Float:jumpoff,block;
		new tmp_type[33];
	
		format(tmp_type, 32, "block_%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
		if(TrieKeyExists(JumpData_Block, tmp_type))
		{	
			TrieGetCell(JumpData_Block, tmp_type, JS);
			
			TrieGetCell(JS, "distance", distance);
			TrieGetCell(JS, "jumpoff", jumpoff);
			TrieGetCell(JS, "block", block);
			TrieGetString(JS,"name",tmp_names,32);
			TrieGetString(JS,"wpn",tmp_weap_names,32);
		}
		
		if(oldblock!=block)
		{
			len += format(buffer[len], 2367-len, "<tr><td COLSPAN=9><br></td></tr>");
			
			if((jj%2)==0)
			{
				jj=oldjj;
			}
		}
		if( block == 0)
		{
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-", "-");
			i=NSHOW-2;
		}
		else
		{
			name = tmp_names;
			while( containi(name, "<") != -1 )
				replace(name, 127, "<", "&lt;");
			while( containi(name, ">") != -1 )
				replace(name, 127, ">", "&gt;");
			if(minjof==jumpoff)
			{
				len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d <td> %d.%01d <td><font color=red> %f <td> %s", ((jj%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name,block, (distance/1000000), (distance%1000000/100000), jumpoff,tmp_weap_names);
			}
			else len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d <td> %d.%01d <td> %0.4f <td> %s", ((jj%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name,block, (distance/1000000), (distance%1000000/100000), jumpoff,tmp_weap_names);
		}
		
		oldblock=block;
		oldjj=jj;
		jj++;
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	static strin[34];
	
	if(type_num==9)
	{
		format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS23",NSHOW-2,weapon_maxspeed(wpn_rank));
	}
	else format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS24", NSHOW-2,type,weapon_maxspeed(wpn_rank));
	
	show_motd(id, buffer, strin);
}
public show_tops_weapon(id,type[],type_num,wpn_rank,mode)
{
	loading_tops[id]=true;
	if(kz_sql==1 && kz_web==0)
	{
		read_tops_weapon(type,type_num,wpn_rank,1,id,mode);
	}
	else tmp_show_tops_weapon(id,type,type_num,wpn_rank);
}
public tmp_show_tops_weapon(id,type[],type_num,wpn_rank)
{	
	static buffer[2368], name[128], len, i;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;line-height:160%%;font-size:12px}.q{border:1px solid #4a4945}.b{background:#2a2a2a}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS25");
		
	for( i = INFO_ZERO; i < (NSHOW-2); i++ )
	{		
		new Trie:JS;
		new tmp_names[33],tmp_weap_names[33],distance,maxspeed,prestrafe,strafes,sync;
		new tmp_type[33];
	
		format(tmp_type, 32, "%s_%d_%d", type, i,weapon_maxspeed(wpn_rank));
		
		if(TrieKeyExists(JumpData, tmp_type))
		{	
			TrieGetCell(JumpData, tmp_type, JS);
			
			TrieGetCell(JS, "distance", distance);
			TrieGetCell(JS, "maxspeed", maxspeed);
			TrieGetCell(JS, "prestrafe", prestrafe);
			TrieGetCell(JS, "strafes", strafes);
			TrieGetCell(JS, "sync", sync);
			TrieGetString(JS,"name",tmp_names,32);
			TrieGetString(JS,"wpn",tmp_weap_names,32);
			//TrieGetCell(JS, "ddbh", ddbh);	
		}
		
		
		if( distance == 0)
		{
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-", "-", "-", "-");			
			i=NSHOW-2;
		}
		else
		{
			name = tmp_names;
			while( containi(name, "<") != -1 )
				replace(name, 127, "<", "&lt;");
			while( containi(name, ">") != -1 )
				replace(name, 127, ">", "&gt;");
				
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d.%01d <td> %d.%01d <td> %d.%01d <td> %d <td> %d <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name,(distance/1000000), (distance%1000000/100000), (maxspeed/1000000), (maxspeed%1000000/100000), (prestrafe/1000000), (prestrafe%1000000/100000), strafes,sync,tmp_weap_names);
		}
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	
	static strin[64];
	format(strin,63, "%L",LANG_SERVER,"UQSTATS_TOPS26",NSHOW-2,Type_List_weapon[type_num],weapon_maxspeed(wpn_rank));
	
	show_motd(id, buffer, strin);
}

public show_topmap(id)
{	
	static buffer[2368], name[128], len, i;
	
	len = format(buffer[len], 2367-len,"<STYLE>body{background:#232323;color:#cfcbc2;font-family:sans-serif}table{width:100%%;font-size:12px}</STYLE><table cellpadding=2 cellspacing=0 border=0>");
	len += format(buffer[len], 2367-len, "%L",LANG_SERVER,"UQSTATS_TOPS27");
		
	for( i = INFO_ZERO; i < NSHOW; i++ )
	{		
		if( map_dist[i] == 0)
		{
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %s <td> %s <td> %s <td> %s <td> %s <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), "-", "-", "-", "-", "-", "-", "-");
			i=NSHOW;
		}
		else
		{
			name = map_names[i];
			while( containi(name, "<") != -1 )
				replace(name, 127, "<", "&lt;");
			while( containi(name, ">") != -1 )
				replace(name, 127, ">", "&gt;");
			len += format(buffer[len], 2367-len, "<tr align=center%s><td> %d <td align=left> %s <td> %d.%01d <td> %d.%01d <td> %d.%01d <td> %d <td> %d <td> %s", ((i%2)==0) ? "" : " bgcolor=#2f3030", (i+1), name, (map_dist[i]/1000000), (map_dist[i]%1000000/100000), (map_maxsped[i]/1000000), (map_maxsped[i]%1000000/100000), (map_prestr[i]/1000000), (map_prestr[i]%1000000/100000), map_streif[i],map_syncc[i],map_type[i]);
	
		}
	}
	len += format(buffer[len], 2367-len, "</table></body>");
	static strin[20];
	format(strin,33, "%L",LANG_SERVER,"UQSTATS_TOPS28", NSHOW);
	show_motd(id, buffer, strin);
}

public uqTopmenu1(id)
{
	new ljtop,cjtop,dcjtop,bjtop,sbjtop;
			
	ljtop=get_cvar_num("kz_uq_lj");
	cjtop=get_cvar_num("kz_uq_cj");
	dcjtop=get_cvar_num("kz_uq_dcj");
	bjtop=get_cvar_num("kz_uq_bj");
	sbjtop=get_cvar_num("kz_uq_sbj");
			
	if(kz_web==0)
	{	
		if(loading_tops[id] && kz_sql==1)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS29",prefix);
			return PLUGIN_HANDLED;
		}
		
		read_maptop();
		if(kz_sql==0)
		{
			for(new i=0;i<NTECHNUM;i++)
			{
				read_tops(Type_List[i],i,0,id,0);
			}
		}
		else if(kz_sql!=1)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
		}
			
		if(top==1)
		{
			new MenuBody[512], len, keys;
			
			len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS31");
			if(kz_sql==0 && kz_web==0) len += format(MenuBody[len], 511, "%L",LANG_SERVER,"UQSTATS_TOPS32");
			if(block_top) len += format(MenuBody[len], 511, "%L",LANG_SERVER,"UQSTATS_TOPS33");
			if(wpn_top) len += format(MenuBody[len], 511, "%L",LANG_SERVER,"UQSTATS_TOPS34");
			
			if(maptop==0)
			{
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS35");
			}
			else if(maptop==1 && map_dist[0]!=0)
			{
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS36");
				keys = (1<<0);
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS37");
		
			if(ljtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/Top10_lj.dat", ljsDir);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS38");
					keys |= (1<<1);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS39");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS40");
			
			if(cjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/Top10_cj.dat", ljsDir);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS41");
					keys |= (1<<2);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS42");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS43");
			
			if(dcjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/Top10_dcj.dat", ljsDir);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS44");
					keys |= (1<<3);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS45");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS46");
			
			if(bjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/Top10_bj.dat", ljsDir);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS47");
					keys |= (1<<4);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS48");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS49");
			
			if(sbjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/Top10_sbj.dat", ljsDir);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS50");
					keys |= (1<<5);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS51");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS52");
			
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS53");
			keys |= (1<<6);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS54");
			keys |= (1<<7);
			if(extra_top==1)
			{
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS55");
				keys |= (1<<8);
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS56");
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
			keys |= (1<<9);
			show_menu(id, keys, MenuBody, -1, "StatsTopMenu1");
		}
		else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS58",prefix);				
	}
	else if(kz_web==1)
	{
		if(kz_sql==0)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS59",prefix);
		}
		else if(kz_sql==1)
		{
			if(top==1)
			{
				new MenuBody[512], len, keys;
					
				read_maptop();
				len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS60");
			
				if(maptop==0)
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS61");
				}
				else if(maptop==1 && map_dist[0]!=0)
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS62");
					keys = (1<<0);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS63");
				
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS64");
				keys |= (1<<1);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS65");
				keys |= (1<<2);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
				keys |= (1<<9);
				
				show_menu(id, keys, MenuBody, -1, "StatsTopMenu1");
			}
			else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS67",prefix);
		}
		else
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
		}
	}
	else
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS69",prefix);
	}
	return PLUGIN_HANDLED;
}
public TopMenu1(id, key)
{
	if(kz_web==0)
	{
		switch((key+1))
		{
			case 1:
			{
				show_topmap(id);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 2:
			{
				show_tops(id,Type_List[0],0,0);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 3:
			{
				show_tops(id,Type_List[2],2,0);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 4:
			{
				show_tops(id,Type_List[10],10,0);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 5:
			{
				show_tops(id,Type_List[4],4,0);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 6:
			{
				show_tops(id,Type_List[5],5,0);
				if(kz_sql==0 && kz_web==0) uqTopmenu1(id);
			}
			case 7:
			{
				uqTopmenu2(id);
			}
			case 8:
			{
				client_cmd(id,"say /ljsmenu");	
			}
			case 9:
			{
				uqmenuExtra1(id);
			}
		}
	}
	else if(kz_web==1)
	{
		switch((key+1))
		{
		
			case 1:
			{
				show_topmap(id);
				uqTopmenu1(id);
			}
			case 2:
			{
				sql_show(id,0);
				uqTopmenu1(id);
			}
			case 3:
			{
				client_cmd(id,"say /ljsmenu");
			}
		}
	}
	return PLUGIN_HANDLED;
}
public uqTopmenu2(id)
{
	new mcjtop,dropcjtop,dropbjtop,wjtop,laddertop,ladderbjtop;
	
	mcjtop=get_cvar_num("kz_uq_mcj");
	dropcjtop=get_cvar_num("kz_uq_drcj");
	dropbjtop=get_cvar_num("kz_uq_drbj");
	wjtop=get_cvar_num("kz_uq_wj");
	laddertop=get_cvar_num("kz_uq_ladder");
	ladderbjtop=get_cvar_num("kz_uq_ldbj");
			
	new MenuBody[512], len, keys;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS70");
	
	if(mcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_mcj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS71");
			keys = (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS72");		
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS73");
	
	if(dropcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropcj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS74");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS75");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS76");
	
	if(dropbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropbj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS77");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS78");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS79");
	
	
	if(wjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_wj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS80");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS81");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS82");
	
	if(laddertop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_ladder.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS83");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS84");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS85");
	
	if(ladderbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_ldbhop.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS86");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS87");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS88");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS89");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS54");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS91");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "StatsTopMenu2");	
}
public TopMenu2(id,key) 
{ 
	switch((key+1))
	{
	
		case 1: 
		{ 
			show_tops(id,Type_List[21],21,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 2: 
		{
			show_tops(id,Type_List[8],8,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 3: 
		{ 
			show_tops(id,Type_List[9],9,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 4: 
		{ 
			show_tops(id,Type_List[3],3,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 5: 
		{
			show_tops(id,Type_List[6],6,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 6: 
		{
			show_tops(id,Type_List[7],7,1);
			if(kz_sql==0 && kz_web==0) uqTopmenu2(id);
		} 
		case 7: 
		{ 
			uqTopmenu1(id);
		} 
		case 8:
		{
			client_cmd(id,"say /ljsmenu");
		}
		case 9:
		{
			uqTopmenu2(id);
			Versioncmd(id);
		}
	} 
	return PLUGIN_HANDLED;
}


public uqmenuExtra1(id)
{
	new scjtop,dscjtop,mscjtop,dropscjtop,dropdscjtop,dropmscjtop;
	
	scjtop=get_cvar_num("kz_uq_scj");
	dscjtop=get_cvar_num("kz_uq_dscj");
	mscjtop=get_cvar_num("kz_uq_mscj");
	dropscjtop=get_cvar_num("kz_uq_dropscj");
	dropdscjtop=get_cvar_num("kz_uq_dropdscj");
	dropmscjtop=get_cvar_num("kz_uq_dropmscj");
	
	new MenuBody[512], len, keys;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS93");

	if(scjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_scj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS94");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS95");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS96");
	
	if(dscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dscj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS97");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS98");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS99");
	
	if(mscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_mscj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS101");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS102");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS103");
	
	if(dropscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropscj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS104");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS105");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS106");
	
	if(dropdscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropdscj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS107");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS108");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS109");
	
	if(dropmscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropmscj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS110");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS111");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS112");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS113");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS54");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS115");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "ExtraMenu1");	
}

public ExtraMenu1(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops(id,Type_List[1],1,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);
		}
		case 2:
		{
			show_tops(id,Type_List[11],11,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);			
		}
		case 3:
		{
			show_tops(id,Type_List[22],22,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);
		}
		case 4:
		{
			show_tops(id,Type_List[12],12,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);
		}
		case 5:
		{
			show_tops(id,Type_List[13],13,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);	
		}
		case 6:
		{
			show_tops(id,Type_List[23],23,2);
			if(kz_sql==0 && kz_web==0) uqmenuExtra1(id);	
		}
		case 7:
		{
			uqmenuExtra2(id);
		}
		case 8:
		{
			client_cmd(id,"say /ljsmenu");
		}
		case 9:
		{
			uqTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqmenuExtra2(id)
{
	new dbhop,bhopd,reallb,upbj,upbd,upsbj;
	
	dbhop=get_cvar_num("kz_uq_duckbhop");
	bhopd=get_cvar_num("kz_uq_bhopinduck");
	reallb=get_cvar_num("kz_uq_realldbhop");
	upbj=get_cvar_num("kz_uq_upbj");
	upbd=get_cvar_num("kz_uq_upbhopinduck");
	upsbj=get_cvar_num("kz_uq_upsbj");

	new MenuBody[512], len, keys;
		
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS117");
	
	if(dbhop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_duckbhop.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS118");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS119");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS120");
	
	if(bhopd==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_bhopinduck.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS121");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS122");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS123");
	
	if(reallb==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_realldbhop.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS124");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS125");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS126");
	
	if(upbj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_upbj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS127");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS128");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS129");
	
	if(upsbj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_upsbj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS130");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS131");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS132");
	
	if(upbd==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_upbhopinduck.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS133");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS134");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS135");

	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS136");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS137");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS115");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "ExtraMenu2");	
}
public ExtraMenu2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops(id,Type_List[14],14,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 2:
		{
			show_tops(id,Type_List[15],15,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 3:
		{
			show_tops(id,Type_List[16],16,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 4:
		{
			show_tops(id,Type_List[17],17,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 5:
		{
			show_tops(id,Type_List[18],18,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 6:
		{
			show_tops(id,Type_List[19],19,3);
			if(kz_sql==0 && kz_web==0) uqmenuExtra2(id);
		}
		case 7:
		{
			uqExtra1(id);
		}
		case 8:
		{
			uqmenuExtra1(id);
		}
		case 9:
		{
			uqTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}

public uqExtra1(id)
{
	new mbhop,drdcj,drmcj;
	
	mbhop=get_cvar_num("kz_uq_multibhop");
	drdcj=get_cvar_num("kz_uq_dropdcj");
	drmcj=get_cvar_num("kz_uq_dropmcj");

	new MenuBody[512], len, keys;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS140");

	if(mbhop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_multibhop.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS141");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS142");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS143");
	
	if(drdcj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropdcj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS144");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS145");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS146");
	
	if(drmcj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropmcj.dat", ljsDir);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS147");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS148");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS149");

	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS150");
	keys |= (1<<3);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS151");
	keys |= (1<<4);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS152");
	keys |= (1<<5);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS153");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS154");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS115");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "Extra1");	
}
public Extra1(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops(id,Type_List[24],24,4);
			if(kz_sql==0 && kz_web==0) uqExtra1(id);
		}
		case 2:
		{
			show_tops(id,Type_List[20],20,4);
			if(kz_sql==0 && kz_web==0) uqExtra1(id);
		}
		case 3:
		{
			show_tops(id,Type_List[25],25,4);
			if(kz_sql==0 && kz_web==0) uqExtra1(id);
		}
		case 4:
		{
			uqExtra1(id);
		}
		case 5:
		{
			uqExtra1(id);
		}
		case 6:
		{
			uqExtra1(id);
		}
		case 7:
		{
			uqmenuExtra2(id);
		}
		case 8:
		{
			Versioncmd(id);
			uqExtra1(id);
		}
		case 9:
		{
			uqTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}
/*public uqExtra2(id)
{
	new prefix[64],top;
	get_cvar_string("kz_uq_prefix", prefix, 63);
	top=get_cvar_num("kz_uq_save_top");
	
	if(top==1)
	{
		new MenuBody[512], len, keys;
		len = format(MenuBody, 511, "\yExtra Stats Top Menu 4/4^n");
		
		len += format(MenuBody[len], 511-len, "^n\r1. \wStandUp CountJump After Jump Top");
		keys |= (1<<0);
		len += format(MenuBody[len], 511-len, "^n\r2. \wDouble StandUp CountJump After Jump Top");
		keys |= (1<<1);
		len += format(MenuBody[len], 511-len, "^n\r3. \wMulti StandUp CountJump After Jump Top");
		keys |= (1<<2);
		len += format(MenuBody[len], 511-len, "^n^n\r4. \wCountJump After Jump Top");
		keys |= (1<<3);
		len += format(MenuBody[len], 511-len, "^n\r5. \wDouble CountJump After Jump Top");
		keys |= (1<<4);
		len += format(MenuBody[len], 511-len, "^n\r6. \wMulti CountJump After Jump Top");
		keys |= (1<<5);
		len += format(MenuBody[len], 511-len, "^n^n\r6. \wPrint Plugin info");
		keys |= (1<<6);
		len += format(MenuBody[len], 511-len, "^n\r8. \wBack to the Third Page");
		keys |= (1<<7);
		len += format(MenuBody[len], 511-len, "^n^n\r9. \yGo to General Tops");
		keys |= (1<<8);
		len += format(MenuBody[len], 511-len, "^n^n\r0. \wExit");
		keys |= (1<<9);
		show_menu(id, keys, MenuBody, -1, "Extra2");
	}
	if(top==0) ColorChat(id, RED, "^x04[%s]^x03 Top10 disabled by server",prefix);
		
}
public Extra2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			uqExtra2(id,0);
		}
		case 2:
		{
			uqExtra2(id,0);
		}
		case 3:
		{
			uqExtra2(id,0);
		}
		case 4:
		{
			uqExtra2(id,0);
		}
		case 5:
		{
			uqExtra2(id,0);
		}
		case 6:
		{
			uqExtra2(id,0);
		}
		case 7:
		{
			uqExtra2(id,0);
		}
		case 8:
		{
			uqExtra1(id,0);
		}
		case 9:
		{
			uqTopmenu1(id,0);
		}
	}
	return PLUGIN_HANDLED;
}
*/

public uqMainWpnMenu(id)
{
	if(kz_web==0)
	{
		if(top==1)
		{
			if(wpn_top==1)
			{
				if(loading_tops[id] && kz_sql==1)
				{
					Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS157",prefix);
					return PLUGIN_HANDLED;
				}
				
				new MenuBody[512], len, keys;
				len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS158");
				
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS159");
				keys |= (1<<0);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS160");
				keys |= (1<<1);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS161");
				keys |= (1<<2);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS162");
				keys |= (1<<3);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS163");
				keys |= (1<<4);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS164");
				keys |= (1<<5);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS165");
				keys |= (1<<6);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS166");
				keys |= (1<<7);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS167");
				keys |= (1<<8);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
				keys |= (1<<9);
				show_menu(id, keys, MenuBody, -1, "StatsMainWpnMenu");
			}
			else if(wpn_top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS169",prefix);				
		}
		else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);				
	}
	else if(kz_web==1)
	{
		if(kz_sql==0)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS171",prefix);
		}
		else if(kz_sql==1)
		{
			if(top==1)
			{
				if(wpn_top==1)
				{
					new MenuBody[512], len, keys;
						
					//read_maptop();
					len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS172");
				
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS173");
					keys |= (1<<0);
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS174");
					keys |= (1<<1);
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS57");
					keys |= (1<<9);
					
					show_menu(id, keys, MenuBody, -1, "StatsMainWpnMenu");
				}
				else if(wpn_top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS169",prefix);				
			}
			else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);
		}
		else
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS1",prefix);
		}
	}
	else
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS69",prefix);
	}
	return PLUGIN_HANDLED;
}
public MainWpnMenu(id, key)
{
	if(kz_web==0)
	{
		switch((key+1))
		{
			case 1:
			{
				uqTopmenuWpn1(id,0);
			}
			case 2:
			{
				uqTopmenuWpn1(id,1);
			}
			case 3:
			{
				uqTopmenuWpn1(id,2);
			}
			case 4:
			{
				uqTopmenuWpn1(id,3);
			}
			case 5:
			{
				uqTopmenuWpn1(id,4);
			}
			case 6:
			{
				uqTopmenuWpn1(id,5);
			}
			case 7:
			{
				uqTopmenuWpn1(id,6);
			}
			case 8:
			{
				uqTopmenuWpn1(id,7);
			}
			case 9:
			{
				uqTopmenu1(id);
			}
		}
	}
	else if(kz_web==1)
	{
		switch((key+1))
		{
			case 1:
			{
				sql_show(id,0);
				uqMainWpnMenu(id);
			}
			case 2:
			{
				client_cmd(id,"say /ljsmenu");
			}
		}
	}
	return PLUGIN_HANDLED;
}
public uqTopmenuWpn1(id,wpn_rank)
{
	new ljtop,cjtop,dcjtop,bjtop,sbjtop,mcjtop,wjtop;
	
	ljtop=get_cvar_num("kz_uq_lj");
	cjtop=get_cvar_num("kz_uq_cj");
	dcjtop=get_cvar_num("kz_uq_dcj");
	bjtop=get_cvar_num("kz_uq_bj");
	sbjtop=get_cvar_num("kz_uq_sbj");
	mcjtop=get_cvar_num("kz_uq_mcj");
	wjtop=get_cvar_num("kz_uq_wj");
	
	if(kz_sql==0)
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			read_tops_weapon(Type_List_weapon[i],i,wpn_rank,0,id,0);
		}
	}
	else if(kz_sql!=1)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
	}
	
	new MenuBody[512], len, keys;
	tmp_wpn_rank[id]=wpn_rank;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS181",weapon_maxspeed(wpn_rank));
		
	if(ljtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_lj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS213");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS214");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS215");
	
	if(cjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_cj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS236");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS237");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS238");
	
	if(dcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dcj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS239");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS240");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS241");
	
	if(mcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_mcj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS182");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS183");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS184");
	
	if(bjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_bj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS185");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS186");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS187");
	
	if(sbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_sbj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS188");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS189");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS190");
	
	if(wjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_wj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS191");
			keys |= (1<<6);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS192");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS193");
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS194");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS195");
	keys |= (1<<8);			
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS196");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "WeaponMenu1");
}
public WeaponMenu1(id, key)
{
	switch((key+1))
	{		
		case 1:
		{
			show_tops_weapon(id,Type_List_weapon[0],0,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);	
		}
		case 2:
		{
			show_tops_weapon(id,Type_List_weapon[1],1,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 3:
		{
			show_tops_weapon(id,Type_List_weapon[6],6,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 4:
		{
			show_tops_weapon(id,Type_List_weapon[7],7,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 5:
		{
			show_tops_weapon(id,Type_List_weapon[3],3,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 6:
		{
			show_tops_weapon(id,Type_List_weapon[4],4,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 7:
		{	
			show_tops_weapon(id,Type_List_weapon[2],2,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 8:
		{
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 9:
		{
			uqMainWpnMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqTopmenuWpn2(id,wpn_rank)
{
	new dropcjtop,dropbjtop;

	dropcjtop=get_cvar_num("kz_uq_drcj");
	dropbjtop=get_cvar_num("kz_uq_drbj");
	
	if(kz_sql==0)
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			read_tops_weapon(Type_List_weapon[i],i,wpn_rank,0,id,0);
		}
	}
	else if(kz_sql!=1)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
	}
	
	new MenuBody[512], len, keys;
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS197",weapon_maxspeed(wpn_rank));
	
	tmp_wpn_rank[id]=wpn_rank;
	
	if(dropcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropcj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS198");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS199");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS200");
	
	if(dropbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/Top10_dropbj.dat", ljsDir_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS201");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS202");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS203");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS204");
	keys |= (1<<2);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS205");
	keys |= (1<<3);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS206");
	keys |= (1<<4);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS207");
	keys |= (1<<5);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS208");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS209");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS210");
	keys |= (1<<8);			
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS211");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "WeaponMenu2");
}

public WeaponMenu2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops_weapon(id,Type_List_weapon[8],8,tmp_wpn_rank[id],1);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 2:
		{
			show_tops_weapon(id,Type_List_weapon[5],5,tmp_wpn_rank[id],1);
			if(kz_sql==0 && kz_web==0) uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 3:
		{
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 4:
		{
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 5:
		{
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 6:
		{
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 7:
		{	
			uqTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 8:
		{
			uqTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 9:
		{
			uqMainWpnMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqBlockTopmenu1(id)
{
	new ljtop,cjtop,dcjtop,bjtop,sbjtop;
			
	ljtop=get_cvar_num("kz_uq_lj");
	cjtop=get_cvar_num("kz_uq_cj");
	dcjtop=get_cvar_num("kz_uq_dcj");
	bjtop=get_cvar_num("kz_uq_bj");
	sbjtop=get_cvar_num("kz_uq_sbj");
			
	if(kz_web==0)
	{
			
		if(kz_sql==0)
		{
			for(new i=0;i<NTECHNUM;i++)
			{
				read_tops_block(Type_List[i],i,0,id,0);
			}
		}
		else if(kz_sql!=1)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
		}
			
		if(top==1)
		{
			new MenuBody[512], len, keys;
			
			len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS212");
			
			if(ljtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_lj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS213");
					keys |= (1<<0);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS214");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS215");
			
			if(ljtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS216");
					keys |= (1<<1);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS217");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS218");
			
			if(cjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_cj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS219");
					keys |= (1<<2);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS220");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS221");
			
			if(dcjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_dcj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS222");
					keys |= (1<<3);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS223");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS224");
			
			if(bjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_bj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS225");
					keys |= (1<<4);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS226");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS227");
			
			if(sbjtop==1)
			{
				new profile[128];
				formatex(profile, 127, "%s/block20_sbj.dat", ljsDir_block);

				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS228");
					keys |= (1<<5);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS229");
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS230");
						
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS231");
			keys |= (1<<6);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS232");
			keys |= (1<<7);
			if(extra_top==1)
			{
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS233");
				keys |= (1<<8);
			}
			else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS234");
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS235");
			keys |= (1<<9);
			show_menu(id, keys, MenuBody, -1, "BlockMenu1");
		}
		else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);				
	}
	else if(kz_web==1)
	{
		if(kz_sql==0)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS171",prefix);
		}
		else if(kz_sql==1)
		{
			if(top==1)
			{
				new MenuBody[512], len, keys;
				
				len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS242");
				
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS243");
				keys |= (1<<0);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS244");
				keys |= (1<<1);
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS245");
				keys |= (1<<9);
				
				show_menu(id, keys, MenuBody, -1, "BlockMenu1");
			}
			else if(top==0) ColorChat(id, RED, "^x04[%s]^x03 Top10 disabled by server",prefix);
		}
		else
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
		}
	}
	else
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS69",prefix);
	}
}
public BlockTopMenu1(id, key)
{
	if(kz_web==0)
	{
		switch((key+1))
		{
			case 1:
			{	show_tops_block(id,Type_List[0],0,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);
			}
			case 2:
			{
				show_tops_block(id,Type_List[6],6,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);	
			}
			case 3:
			{
				show_tops_block(id,Type_List[2],2,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);
			}
			case 4:
			{
				show_tops_block(id,Type_List[10],10,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);
			}
			case 5:
			{
				show_tops_block(id,Type_List[4],4,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);
			}
			case 6:
			{
				show_tops_block(id,Type_List[5],5,0);
				if(kz_sql==0 && kz_web==0) uqBlockTopmenu1(id);
			}
			case 7:
			{	
				uqBlockTopmenu2(id);
			}
			case 8:
			{
				uqTopmenublocks(id);
			}
			case 9:
			{
				uqmenuBlockEx1(id);
			}
		}
	}
	else if(kz_web==1)
	{
		switch((key+1))
		{
			case 1:
			{
				sql_show(id,1);
				uqBlockTopmenu1(id);
			}
			case 2:
			{
				client_cmd(id,"say /ljsmenu");
			}
		}
	}
	return PLUGIN_HANDLED;
}

public uqBlockTopmenu2(id)
{
	new mcjtop,dropcjtop,dropbjtop,wjtop,ladderbjtop;
	
	mcjtop=get_cvar_num("kz_uq_mcj");
	dropcjtop=get_cvar_num("kz_uq_drcj");
	dropbjtop=get_cvar_num("kz_uq_drbj");
	wjtop=get_cvar_num("kz_uq_wj");
	ladderbjtop=get_cvar_num("kz_uq_ldbj");
	
	new MenuBody[512], len, keys;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS270");
	
	
	if(mcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_mcj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS246");
			keys = (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS247");		
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS248");
	
	if(dropcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropcj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS250");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS251");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS252");
	
	if(dropbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropbj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS253");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS254");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS255");
	
	
	if(wjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_wj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS256");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS257");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS258");
	
	if(ladderbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_ldbhop.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS259");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS260");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS261");

	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS262");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS263");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS264");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS265");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS266");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockMenu2");	
}
public BlockTopMenu2(id,key) 
{ 
	switch((key+1))
	{
	
		case 1: 
		{ 
			show_tops_block(id,Type_List[21],21,1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenu2(id);
		} 
		case 2: 
		{
			show_tops_block(id,Type_List[8],8,1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenu2(id);
		} 
		case 3: 
		{ 
			show_tops_block(id,Type_List[9],9,1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenu2(id);
		} 
		case 4: 
		{ 
			show_tops_block(id,Type_List[3],3,1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenu2(id);
		} 
		case 5: 
		{
			show_tops_block(id,Type_List[7],7,1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenu2(id);
		} 
		case 7: 
		{ 
			uqBlockTopmenu1(id);
		} 
		case 8:
		{
			client_cmd(id,"say /ljsmenu");
		}
		case 9:
		{
			uqBlockTopmenu2(id);
			Versioncmd(id);
		}
	} 
	return PLUGIN_HANDLED;
}
public uqmenuBlockEx1(id)
{
	new scjtop,dscjtop,mscjtop,dropscjtop,dropdscjtop,dropmscjtop;
	
	scjtop=get_cvar_num("kz_uq_scj");
	dscjtop=get_cvar_num("kz_uq_dscj");
	mscjtop=get_cvar_num("kz_uq_mscj");
	dropscjtop=get_cvar_num("kz_uq_dropscj");
	dropdscjtop=get_cvar_num("kz_uq_dropdscj");
	dropmscjtop=get_cvar_num("kz_uq_dropmscj");
	
	new MenuBody[512], len, keys;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS271");

	if(scjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_scj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS272");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS273");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS274");
	
	if(dscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dscj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS275");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS276");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS277");
	
	if(mscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_mscj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS278");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS279");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS280");
	
	if(dropscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropscj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS281");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS282");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS283");
	
	if(dropdscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropdscj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS284");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS285");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS286");
	
	if(dropmscjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropmscj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS287");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS288");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS289");
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS290");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS291");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS292");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS293");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockExMenu1");
}

public BlockTopExMenu1(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops_block(id,Type_List[1],1,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);
		}
		case 2:
		{
			show_tops_block(id,Type_List[11],11,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);			
		}
		case 3:
		{
			show_tops_block(id,Type_List[22],22,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);
		}
		case 4:
		{
			show_tops_block(id,Type_List[12],12,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);
		}
		case 5:
		{
			show_tops_block(id,Type_List[13],13,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);	
		}
		case 6:
		{
			show_tops_block(id,Type_List[23],23,2);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx1(id);	
		}
		case 7:
		{
			uqmenuBlockEx2(id);
		}
		case 8:
		{
			client_cmd(id,"say /ljsmenu");
		}
		case 9:
		{
			uqBlockTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqmenuBlockEx2(id)
{	
	new dbhop,bhopd,reallb,upbj,upbd,upsbj;
	
	dbhop=get_cvar_num("kz_uq_duckbhop");
	bhopd=get_cvar_num("kz_uq_bhopinduck");
	reallb=get_cvar_num("kz_uq_realldbhop");
	upbj=get_cvar_num("kz_uq_upbj");
	upbd=get_cvar_num("kz_uq_upbhopinduck");
	upsbj=get_cvar_num("kz_uq_upsbj");

	new MenuBody[512], len, keys;
		
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS294");
	
	if(dbhop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_duckbhop.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS295");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS296");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS297");
	
	if(bhopd==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_bhopinduck.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS298");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS299");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS300");
	
	if(reallb==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_realldbhop.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS301");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS302");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS303");
	
	if(upbj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_upbj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS304");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS305");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS306");
	
	if(upsbj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_upsbj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS307");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS308");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS309");
	
	if(upbd==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_upbhopinduck.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS310");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS311");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS312");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS313");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS314");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS315");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS316");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockExMenu2");	
}
public BlockTopExMenu2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops_block(id,Type_List[14],14,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 2:
		{
			show_tops_block(id,Type_List[15],15,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 3:
		{
			show_tops_block(id,Type_List[16],16,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 4:
		{
			show_tops_block(id,Type_List[17],17,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 5:
		{
			show_tops_block(id,Type_List[18],18,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 6:
		{
			show_tops_block(id,Type_List[19],19,3);
			if(kz_sql==0 && kz_web==0) uqmenuBlockEx2(id);
		}
		case 7:
		{
			uqBlockEx1(id);
		}
		case 8:
		{
			uqmenuBlockEx1(id);
		}
		case 9:
		{
			uqBlockTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}

public uqBlockEx1(id)
{
	new mbhop,drdcj,drmcj;
	
	mbhop=get_cvar_num("kz_uq_multibhop");
	drdcj=get_cvar_num("kz_uq_dropdcj");
	drmcj=get_cvar_num("kz_uq_dropmcj");

	new MenuBody[512], len, keys;
		
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS317");

	if(mbhop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_multibhop.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS318");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS319");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS320");
	
	if(drdcj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropdcj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS321");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS322");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS323");
	
	if(drmcj==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropmcj.dat", ljsDir_block);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS324");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS325");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS326");
		
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS327");
	keys |= (1<<3);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS328");
	keys |= (1<<4);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS329");
	keys |= (1<<5);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS330");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS331");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS332");
	keys |= (1<<8);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS333");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockEx1");
}
public BlockTopEx1(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops_block(id,Type_List[24],24,4);
			if(kz_sql==0 && kz_web==0) uqBlockEx1(id);
		}
		case 2:
		{
			show_tops_block(id,Type_List[20],20,4);
			if(kz_sql==0 && kz_web==0) uqBlockEx1(id);
		}
		case 3:
		{
			show_tops_block(id,Type_List[25],25,4);
			if(kz_sql==0 && kz_web==0) uqBlockEx1(id);
		}
		case 4:
		{
			uqBlockEx1(id);
		}
		case 5:
		{
			uqBlockEx1(id);
		}
		case 6:
		{
			uqBlockEx1(id);
		}
		case 7:
		{
			uqmenuBlockEx2(id);
		}
		case 8:
		{
			Versioncmd(id);
			uqBlockEx1(id);
		}
		case 9:
		{
			uqBlockTopmenu1(id);
		}
	}
	return PLUGIN_HANDLED;
}

public uqMainBlockWpnMenu(id)
{
	if(top==1)
	{
		if(wpn_top==1)
		{
			
			
			if(kz_sql==0)
			{
				for(new j=0;j<8;j++)
				{
					for(new i=0;i<NWPNTECHNUM;i++)
					{
						read_tops_block_weapon(Type_List_weapon[i],i,j,0,id,0);
					}
					read_tops_block_weapon("hj",9,j,0,id,0);
				}
			}
			else if(kz_sql!=1)
			{
				Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
			}
			
			new MenuBody[512], len, keys;
			len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS334");
			
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS335");
			keys |= (1<<0);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS336");
			keys |= (1<<1);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS337");
			keys |= (1<<2);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS338");
			keys |= (1<<3);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS339");
			keys |= (1<<4);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS340");
			keys |= (1<<5);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS341");
			keys |= (1<<6);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS342");
			keys |= (1<<7);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS343");
			keys |= (1<<8);
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS344");
			keys |= (1<<9);
			show_menu(id, keys, MenuBody, -1, "BlockMainWpnMenu");
		}
		else if(wpn_top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS345",prefix);				
	}
	else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);				
}
public BlockTopMainWpnMenu(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			uqBlockTopmenuWpn1(id,0);
		}
		case 2:
		{
			uqBlockTopmenuWpn1(id,1);
		}
		case 3:
		{
			uqBlockTopmenuWpn1(id,2);
		}
		case 4:
		{
			uqBlockTopmenuWpn1(id,3);
		}
		case 5:
		{
			uqBlockTopmenuWpn1(id,4);
		}
		case 6:
		{
			uqBlockTopmenuWpn1(id,5);
		}
		case 7:
		{
			uqBlockTopmenuWpn1(id,6);
		}
		case 8:
		{
			uqBlockTopmenuWpn1(id,7);
		}
		case 9:
		{
			uqTopmenublocks(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqBlockTopmenuWpn1(id,wpn_rank)
{
	new ljtop,cjtop,dcjtop,bjtop,sbjtop,mcjtop;
	
	ljtop=get_cvar_num("kz_uq_lj");
	cjtop=get_cvar_num("kz_uq_cj");
	dcjtop=get_cvar_num("kz_uq_dcj");
	bjtop=get_cvar_num("kz_uq_bj");
	sbjtop=get_cvar_num("kz_uq_sbj");
	mcjtop=get_cvar_num("kz_uq_mcj");
	
	
	if(kz_sql==0)
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			read_tops_block_weapon(Type_List_weapon[i],i,wpn_rank,0,id,0);
		}
	}
	else if(kz_sql!=1)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
	}
	
	new MenuBody[512], len, keys;
	tmp_wpn_rank[id]=wpn_rank;
	
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS346",weapon_maxspeed(wpn_rank));
		
	if(ljtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_lj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) || (kz_sql==1 && kz_web==0))
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS213");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS214");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS215");
	
	if(ljtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS216");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS217");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS218");
	
	if(cjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_cj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS219");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS220");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS221");
	
	if(dcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dcj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS222");
			keys |= (1<<3);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS223");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS224");
	
	if(mcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_mcj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS347");
			keys |= (1<<4);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS348");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS349");
	
	if(bjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_bj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS350");
			keys |= (1<<5);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS351");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS352");
	
	if(sbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_sbj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS353");
			keys |= (1<<6);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS354");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS355");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS356");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS357");
	keys |= (1<<8);			
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS358");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockWpnMenu1");
}
public BlockWpnTopMenu1(id, key)
{
	switch((key+1))
	{		
		case 1:
		{
			show_tops_block_weapon(id,Type_List_weapon[0],0,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);	
		}
		case 2:
		{
			show_tops_block_weapon(id,"hj",9,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 3:
		{
			show_tops_block_weapon(id,Type_List_weapon[1],1,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 4:
		{
			show_tops_block_weapon(id,Type_List_weapon[6],6,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 5:
		{
			show_tops_block_weapon(id,Type_List_weapon[7],7,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 6:
		{
			show_tops_block_weapon(id,Type_List_weapon[3],3,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 7:
		{	
			show_tops_block_weapon(id,Type_List_weapon[4],4,tmp_wpn_rank[id],0);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 8:
		{
			uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 9:
		{
			uqMainBlockWpnMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqBlockTopmenuWpn2(id,wpn_rank)
{
	new dropcjtop,dropbjtop,wjtop;

	dropcjtop=get_cvar_num("kz_uq_drcj");
	dropbjtop=get_cvar_num("kz_uq_drbj");
	wjtop=get_cvar_num("kz_uq_wj");
	
	
	if(kz_sql==0)
	{
		for(new i=0;i<NWPNTECHNUM;i++)
		{
			read_tops_block_weapon(Type_List_weapon[i],i,wpn_rank,0,id,0);
		}
	}
	else if(kz_sql!=1)
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
	}
	new MenuBody[512], len, keys;
	len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS359",weapon_maxspeed(wpn_rank));
	
	tmp_wpn_rank[id]=wpn_rank;
	
	if(wjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_wj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS360");
			keys |= (1<<0);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS361");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS362");
	
	if(dropcjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropcj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS363");
			keys |= (1<<1);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS364");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS365");
	
	if(dropbjtop==1)
	{
		new profile[128];
		formatex(profile, 127, "%s/block20_dropbj.dat", ljsDir_block_weapon[wpn_rank]);

		if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
		{
			len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS366");
			keys |= (1<<2);
		}
		else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS367");
	}
	else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS368");
	
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS369");
	keys |= (1<<3);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS370");
	keys |= (1<<4);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS371");
	keys |= (1<<5);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS372");
	keys |= (1<<6);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS373");
	keys |= (1<<7);
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS374");
	keys |= (1<<8);			
	len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS375");
	keys |= (1<<9);
	show_menu(id, keys, MenuBody, -1, "BlockWpnMenu2");
}

public BlockWpnTopMenu2(id, key)
{
	switch((key+1))
	{
		case 1:
		{
			show_tops_block_weapon(id,Type_List_weapon[2],2,tmp_wpn_rank[id],1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 2:
		{
			show_tops_block_weapon(id,Type_List_weapon[8],8,tmp_wpn_rank[id],1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 3:
		{
			show_tops_block_weapon(id,Type_List_weapon[5],5,tmp_wpn_rank[id],1);
			if(kz_sql==0 && kz_web==0) uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 4:
		{
			uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 5:
		{
			uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 6:
		{
			uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 7:
		{	
			uqBlockTopmenuWpn2(id,tmp_wpn_rank[id]);
		}
		case 8:
		{
			uqBlockTopmenuWpn1(id,tmp_wpn_rank[id]);
		}
		case 9:
		{
			uqMainBlockWpnMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}
public uqTopmenublocks(id)
{
	if(kz_web==0)
	{
		if(top==1)
		{
			if(block_top)
			{	
				if(loading_tops[id] && kz_sql==1)
				{
					Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS29",prefix);
					return PLUGIN_HANDLED;
				}
				
				new MenuBody[512], len, keys;
				len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS376");
				
				if(block_top)
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS377");
					keys |= (1<<0);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS378");
				
				if(block_wpn_top)
				{
					len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS379");
					keys |= (1<<1);
				}
				else len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS380");
					
				
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS381");
				keys |= (1<<2);	
				
				len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS382");
				keys |= (1<<9);
				show_menu(id, keys, MenuBody, -1, "BlockMainMenu");
			}
			else Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS383",prefix);				
		}
		else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);
	}
	else if(kz_web==1)
	{
		if(kz_sql==0)
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS171",prefix);
		}
		else if(kz_sql==1)
		{
			if(top==1)
			{
				if(block_top==1)
				{
						new MenuBody[512], len, keys;
						
						len = format(MenuBody, 511, "%L",LANG_SERVER,"UQSTATS_TOPS384");
					
						len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS385");
						keys |= (1<<0);
						len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS386");
						keys |= (1<<1);
						len += format(MenuBody[len], 511-len, "%L",LANG_SERVER,"UQSTATS_TOPS387");
						keys |= (1<<9);
						
						show_menu(id, keys, MenuBody, -1, "BlockMainMenu");
				}
				else if(block_top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS345",prefix);				
			}
			else if(top==0) Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS170",prefix);
		}
		else
		{
			Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS30",prefix);
		}
	}
	else
	{
		Color_Chat_Lang(id,RED,"%L",LANG_SERVER,"UQSTATS_TOPS69",prefix);
	}
	return PLUGIN_HANDLED;
}

public BlockMenu(id, key)
{
	if(kz_web==0)
	{
		switch((key+1))
		{
			case 1:
			{
				uqBlockTopmenu1(id);
			}
			case 2:
			{
				uqMainBlockWpnMenu(id);
			}
			case 3:
			{
				uqTopmenu1(id);
			}
		}
	}
	else if(kz_web==1)
	{
		switch((key+1))
		{
			case 1:
			{
				sql_show(id,1);
				uqTopmenublocks(id);
			}
			case 2:
			{
				client_cmd(id,"say /ljsmenu");
			}
		}
	}
	return PLUGIN_HANDLED;
}
public Versioncmd( id )
{	
	Color_Chat_Lang(id,GREY,"%L",LANG_SERVER,"UQSTATS_VERSION_1", prefix,TOPS_VERSION);
	
	if(kz_sql==1)
	{
		Color_Chat_Lang(id,GREY,"%L",LANG_SERVER,"UQSTATS_VERSION_SQL1", prefix);
		Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_VERSION_SQL2", prefix);
	}
	else Color_Chat_Lang(id,BLUE,"%L",LANG_SERVER,"UQSTATS_VERSION_2", prefix);
}
public weapon_maxspeed(rank)
{
	new maxspeed;
	
	switch(rank)
	{
		case 0:
			maxspeed = 210;
		case 1:
			maxspeed = 220;
		case 2:
			maxspeed = 221;
		case 3:
			maxspeed = 230;
		case 4:
			maxspeed = 235;
		case 5:
			maxspeed = 240;
		case 6:
			maxspeed = 245;
		case 7:
			maxspeed = 260;
	}
	
	return maxspeed;
}
public weapon_rank(maxspeed)
{
	new rank;
	
	switch(maxspeed)
	{	
		case 0:
			rank = -1;
		case 210:
			rank = 0;
		case 220:
			rank = 1;
		case 221:
			rank = 2;
		case 230:
			rank = 3;
		case 235:
			rank = 4;
		case 240:
			rank = 5;
		case 245:
			rank = 6;
		case 260:
			rank = 7;
	}
	
	return rank;
}
public Float:find_min_jumpoff(Float:TmpArray[NTOP+1])
{
	new num_min;
	num_min=0;
	for (new i = 0; i < NSHOW; i++)
	{
		if(TmpArray[num_min]>TmpArray[i] && TmpArray[i]!=0.0)
		{
			num_min=i;
		}
	}
	return TmpArray[num_min];
}


public reset_tops(id, level, cid)
{	
	if( !cmd_access(id, level, cid, 1) ) return PLUGIN_HANDLED;

	new name[64];
	get_user_name(id,name,63);
	
	if(kz_sql==0)
	{
		client_print(id,print_console,"%L",LANG_SERVER,"UQSTATS_TOPS3881");
		server_print("%L",LANG_SERVER,"UQSTATS_TOPS388");
		log_amx("Tops reseted by %s", name);
		
		new profile[128];
		
		for(new i=0;i<NTECHNUM;i++)
		{
			formatex(profile, 127, "%s/Top10_%s.dat", ljsDir,Type_List[i]);
			if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
			{
				delete_file(profile);
			}
			
			if(i==6)
			{
				formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block);
			}
			else formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block,Type_List[i]);
			
			if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
			{
				delete_file(profile);
			}
		}
		
		for(new k=0;k<8;k++)
		{	
			for(new i=0;i<NWPNTECHNUM;i++)
			{
				formatex(profile, 127, "%s/Top10_%s.dat", ljsDir_weapon[k],Type_List_weapon[i]);
				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					delete_file(profile);
				}
				
				formatex(profile, 127, "%s/block20_%s.dat", ljsDir_block_weapon[k],Type_List_weapon[i]);
				if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
				{
					delete_file(profile);
				}
			}
			
			formatex(profile, 127, "%s/block20_hj.dat", ljsDir_block_weapon[k]);
			if( file_exists(profile) || (kz_sql==1 && kz_web==0) )
			{
				delete_file(profile);
			}
		}
		
		TrieClear(JumpData);
		TrieClear(JumpData_Block);
	}
	
	return PLUGIN_CONTINUE;
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
stock replace_colors(message[], len)
{
	replace_all(message, len, "!g", "^x04");
	replace_all(message, len, "!t", "^x03");
	replace_all(message, len, "!y", "^x01");
}
public plugin_end() 
{ 

	if(kz_sql == 1)
	{
		if(DB_TUPLE1)
			SQL_FreeHandle(DB_TUPLE1);
		if(SqlConnection1)
			SQL_FreeHandle(SqlConnection1);
	}
	else if(kz_sql == 0)
	{
		TrieDestroy(JumpData);
		TrieDestroy(JumpData_Block);	
	}
}

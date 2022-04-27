#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <kreedz_api>
#include <kreedz_util>

#define PLUGIN 	 	"[Kreedz] Strafes analysis"
#define VERSION 	__DATE__
#define AUTHOR	 	"ggv"

#define MAX_FRAMES	500

enum _:FrameStruct
{
	Float:fs_ViewAngle[3],
	Float:fs_Velocity[3],
	fs_Buttons,
	Float:fs_Speed
}

new g_Frames[MAX_PLAYERS + 1][MAX_FRAMES][FrameStruct];
new g_NumFrame[MAX_PLAYERS + 1];
new bool:g_IsJump[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHookChain(RG_CBasePlayer_PostThink, "fw_PostThink_Pre", false);

}

public fw_PostThink_Pre(id)
{
	if(!is_user_alive(id))
		return HC_CONTINUE;

	if(get_entvar(id, var_flags) & FL_ONGROUND)
	{
		if(g_IsJump[id])
		{
			g_IsJump[id] = false;
			client_print(id, print_console, "---------[END]---------");
			client_print(id, print_console, "Min:^t%.2f %.2f | %.2f | %.2f %.2f %.2f^nMax:^t%.2f %.2f | %.2f | %.2f %.2f %.2f", 
				stat_min(id, 0), stat_min(id, 1), stat_min(id, 2), 
				stat_min(id, 3), stat_min(id, 4), stat_min(id, 5),
				stat_max(id, 0), stat_max(id, 1), stat_max(id, 2), 
				stat_max(id, 3), stat_max(id, 4), stat_max(id, 5));

			client_print(id, print_console, "Interval:^t%.2f %.2f | %.2f | %.2f %.2f %.2f", 
				stat_max(id, 0) - stat_min(id, 0), 
				stat_max(id, 1) - stat_min(id, 1), 
				stat_max(id, 2) - stat_min(id, 2), 
				stat_max(id, 3) - stat_min(id, 3), 
				stat_max(id, 4) - stat_min(id, 4), 
				stat_max(id, 5) - stat_min(id, 5));

			client_print(id, print_console, "Mean:^t%.2f %.2f | %.2f | %.2f %.2f %.2f^nStdev:^t%.2f %.2f | %.2f | %.2f %.2f %.2f", 
				mean(id, 0), mean(id, 1), mean(id, 2), 
				mean(id, 3), mean(id, 4), mean(id, 5),
				stdev(id, 0), stdev(id, 1), stdev(id, 2), 
				stdev(id, 3), stdev(id, 4), stdev(id, 5));
		}
	}
	else
	{
		if(!g_IsJump[id])
		{
			g_IsJump[id] = true;
			g_NumFrame[id] = 0;
			client_print(id, print_console, "--------[START]--------");
		}

		static Float:velocity[3];

		g_Frames[id][g_NumFrame[id]][fs_Buttons] = get_entvar(id, var_button);

		get_entvar(id, var_v_angle, g_Frames[id][g_NumFrame[id]][fs_ViewAngle]);
		get_entvar(id, var_velocity, velocity);

		g_Frames[id][g_NumFrame[id]][fs_Speed] = 
			floatsqroot(velocity[0] * velocity[0] + velocity[1] * velocity[1]);
		g_Frames[id][g_NumFrame[id]][fs_Velocity] = velocity;

		client_print(id, print_console, "[Frame %d] %.1f %.1f | %.1f | %.1f %.1f %.1f | %s", 
			g_NumFrame[id] + 1, 
			g_Frames[id][g_NumFrame[id]][fs_ViewAngle][0],
			g_Frames[id][g_NumFrame[id]][fs_ViewAngle][1],
			g_Frames[id][g_NumFrame[id]][fs_Speed],
			g_Frames[id][g_NumFrame[id]][fs_Velocity][0],
			g_Frames[id][g_NumFrame[id]][fs_Velocity][1],
			g_Frames[id][g_NumFrame[id]][fs_Velocity][2],
			convert_buttons(g_Frames[id][g_NumFrame[id]][fs_Buttons]));

		g_NumFrame[id]++;
	}

	return HC_CONTINUE;
}

stock convert_buttons(iButtons)
{
	static szMsg[64], szAdd[32];
	szMsg = "";

	if(iButtons & IN_MOVELEFT)
	{
		formatex(szAdd, charsmax(szAdd), "A ");
		add(szMsg, charsmax(szMsg), szAdd);
	}

	if(iButtons & IN_MOVERIGHT)
	{
		formatex(szAdd, charsmax(szAdd), "D ");
		add(szMsg, charsmax(szMsg), szAdd);
	}

	if(iButtons & IN_DUCK)
	{
		formatex(szAdd, charsmax(szAdd), "duck");
		add(szMsg, charsmax(szMsg), szAdd);
	}

	if(!szMsg[0])
		szMsg = "none";

	return szMsg;
}

stock Float:mean(id, param)
{
	new Float:fMean = 0.0;

	switch(param)
	{
		case 0:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_ViewAngle][0];
		}
		case 1:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_ViewAngle][1];
		}
		case 2:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_Speed];
		}
		case 3:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_Velocity][0];
		}
		case 4:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_Velocity][1];
		}
		case 5:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				fMean += g_Frames[id][i][fs_Velocity][2];
		}
	}
	return fMean / float(g_NumFrame[id]);
}

stock Float:stdev(id, param)
{
	new Float:fStdev = 0.0;
	new Float:fMean = mean(id, param);
	new Float:fTemp;

	switch(param)
	{
		case 0:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_ViewAngle][0] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
		case 1:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_ViewAngle][1] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
		case 2:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_Speed] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
		case 3:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_Velocity][0] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
		case 4:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_Velocity][1] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
		case 5:
		{
			for(new i; i < g_NumFrame[id]; ++i)
			{
				fTemp = g_Frames[id][i][fs_Velocity][2] - fMean;
				fStdev += (fTemp * fTemp);
			}
		}
	}

	return floatsqroot(fStdev / float(g_NumFrame[id]));
}

stock Float:stat_min(id, param)
{
	new Float:fMin = 100000.0;

	switch(param)
	{
		case 0:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_ViewAngle][0] < fMin)
					fMin = g_Frames[id][i][fs_ViewAngle][0];
		}
		case 1:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_ViewAngle][1] < fMin)
					fMin = g_Frames[id][i][fs_ViewAngle][1];
		}
		case 2:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Speed] < fMin)
					fMin = g_Frames[id][i][fs_Speed];
		}
		case 3:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][0] < fMin)
					fMin = g_Frames[id][i][fs_Velocity][0];
		}
		case 4:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][1] < fMin)
					fMin = g_Frames[id][i][fs_Velocity][1];
		}
		case 5:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][2] < fMin)
					fMin = g_Frames[id][i][fs_Velocity][2];
		}
	}

	return fMin;
}

stock Float:stat_max(id, param)
{
	new Float:fMax = -100000.0;

	switch(param)
	{
		case 0:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_ViewAngle][0] > fMax)
					fMax = g_Frames[id][i][fs_ViewAngle][0];
		}
		case 1:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_ViewAngle][1] > fMax)
					fMax = g_Frames[id][i][fs_ViewAngle][1];
		}
		case 2:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Speed] > fMax)
					fMax = g_Frames[id][i][fs_Speed];
		}
		case 3:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][0] > fMax)
					fMax = g_Frames[id][i][fs_Velocity][0];
		}
		case 4:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][1] > fMax)
					fMax = g_Frames[id][i][fs_Velocity][1];
		}
		case 5:
		{
			for(new i; i < g_NumFrame[id]; ++i)
				if(g_Frames[id][i][fs_Velocity][2] > fMax)
					fMax = g_Frames[id][i][fs_Velocity][2];
		}
	}
	
	return fMax;
}
//https://wiki.teamfortress.com/wiki/Scout
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_ScoutLevel;
ConVar g_ScoutSpeed;
ConVar g_ScoutJumpsPerLevel;
ConVar g_ScoutMaxJumps;

bool g_bUsedAllJumps[MAXPLAYERS + 1] =  { false, ... };
bool g_bPressedJump[MAXPLAYERS + 1] =  { false, ... };
bool g_bHasScout[MAXPLAYERS + 1];
int g_iTimesJumped[MAXPLAYERS + 1];
int g_iHeroIndex;

Handle g_HudSync;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Scout",
	author = PLUGIN_AUTHOR,
	description = "Scout hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/scout.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	g_ScoutLevel = CreateConVar("superheromod_scout_level", "0");
	g_ScoutSpeed = CreateConVar("superheromod_scout_speed", "1.5", "Amount of speed scout should have");
	g_ScoutJumpsPerLevel = CreateConVar("superheromod_scout_jumps_per_level", "0.25", "Amount of jumps player should get per level");
	g_ScoutMaxJumps = CreateConVar("superheromod_scout_max_jumps", "10", "Amount of jumps a player can perform as max");
	AutoExecConfig(true, "scout", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Scout", g_ScoutLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Multi Jump", "Perform mid air jumps to any direction\n(Amount of jumps scales with level)");
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_ScoutSpeed.FloatValue);
	
	g_HudSync = CreateHudSynchronizer();
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_ScoutLevel.IntValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_ScoutSpeed.FloatValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroindex, int mode)
{
	if(heroindex != g_iHeroIndex)
		return;
		
	g_bHasScout[client] = (mode ? true : false);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bHasScout[client])
	{
		int flags = GetEntityFlags(client);
		if(buttons & IN_JUMP)
		{
			if(!g_bPressedJump[client])
			{
				if(!(flags & FL_ONGROUND) && !g_bUsedAllJumps[client])
				{
					g_iTimesJumped[client]++;
					int maxJumps = clamp(1 + RoundToFloor((g_ScoutJumpsPerLevel.FloatValue * SuperHero_GetPlayerLevel(client))), 1, g_ScoutMaxJumps.IntValue);
					if(g_iTimesJumped[client] >= maxJumps)
						g_bUsedAllJumps[client] = true;	//Used all jumps
					
					SetHudTextParams(0.1, 0.7, 2.0, 0, 255, 0, 255);
					ShowSyncHudText(client, g_HudSync, "%t", "Scout Jumps", g_iTimesJumped[client], maxJumps);
					
					float eyePos[3];
					float fwd[3];
					GetClientEyeAngles(client, eyePos);
					eyePos[0] = 0.0;

					if(buttons & IN_FORWARD)
					{
						eyePos[1] = eyePos[1] + 0.0;
						if(buttons & IN_MOVELEFT)
							eyePos[1] = eyePos[1] + 45.0;
						else if(buttons & IN_MOVERIGHT)
							eyePos[1] = eyePos[1] + -45.0;
					}
					if(buttons & IN_BACK)
					{
						eyePos[1] = eyePos[1] + 180.0;
						if(buttons & IN_MOVELEFT)
							eyePos[1] = eyePos[1] + -45.0;
						else if(buttons & IN_MOVERIGHT)
							eyePos[1] = eyePos[1] + 45.0;
					}
					if(buttons & IN_MOVELEFT && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVERIGHT))
						eyePos[1] = eyePos[1] + 90.0;
					
					if(buttons & IN_MOVERIGHT && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVELEFT))
						eyePos[1] = eyePos[1] + -90.0;
					
					GetAngleVectors(eyePos, fwd, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(fwd, fwd);
					ScaleVector(fwd, 350.0);
					
					
					if(!(buttons & IN_MOVERIGHT) && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVELEFT))
					{
						fwd[1] = 0.0;
						fwd[0] = 0.0;
						
					}
					fwd[2] = fwd[2] + 280.0;
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fwd);
				}
				g_bPressedJump[client] = true;
			}
		}
		else
		{
			g_bPressedJump[client] = false;
		}
		
		if(flags & FL_ONGROUND)
		{
			g_bUsedAllJumps[client] = false;
			g_iTimesJumped[client] = 0;
		}
	}
}
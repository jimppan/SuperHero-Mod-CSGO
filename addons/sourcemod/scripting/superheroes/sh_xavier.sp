#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define MODEL_BEAM "materials/sprites/purplelaser1.vmt"
#define HALO_BEAM "materials/sprites/purplelaser1.vmt"
#define TRAIL_REFRESH_RATE 2.0

EngineVersion g_Game;

ConVar g_XavierLevel;
int g_iPathLaserModelIndex;
int g_iPathHaloModelIndex;
int g_iHeroIndex;
bool g_bHasXavier[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Xavier",
	author = PLUGIN_AUTHOR,
	description = "Xavier hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}

	g_XavierLevel = CreateConVar("superheromod_xavier_level", "7");
	AutoExecConfig(true, "xavier", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Xavier", g_XavierLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Team Detection", "Detect what team a player is on by glowing trail");
	
	CreateTimer(TRAIL_REFRESH_RATE, Timer_Trail,_, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_XavierLevel.IntValue);
}

public Action Timer_Trail(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
			
		if(!g_bHasXavier[i])
			continue;
			
		for (int j = 1; j <= MaxClients; j++)
		{
			if(!IsValidClient(j) || !IsPlayerAlive(j))
				continue;
			
			//If the enemy is the daredevil owner or if the enemy is a spectator
			if(i == j || GetClientTeam(j) == CS_TEAM_SPECTATOR)
				continue;
			
			float enemyPos[3];
			GetClientAbsOrigin(j, enemyPos);
			int color[4];
			if(GetClientTeam(j) == CS_TEAM_T)
				color =  { 255, 0, 0, 255 };
			else
				color =  { 0, 0, 255, 255 };
				
			enemyPos[2] += 40.0;
			TE_SetupBeamFollow(j, g_iPathLaserModelIndex, g_iPathHaloModelIndex, TRAIL_REFRESH_RATE, 20.0, 20.1, 0, color);
			TE_SendToClient(i);
		}
	}
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasXavier[client] = (mode ? true : false);
}

public void OnClientDisconnect(int client)
{
	g_bHasXavier[client] = false;
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasXavier[client] = false;
	return true;
}

public void OnMapStart()
{
	g_iPathHaloModelIndex = PrecacheModel(HALO_BEAM);
	g_iPathLaserModelIndex = PrecacheModel(MODEL_BEAM);
}
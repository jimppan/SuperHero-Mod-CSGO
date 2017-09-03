#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

#define MODEL_BEAM "materials/sprites/laserbeam.vmt"
#define HALO_BEAM "materials/sprites/purplelaser1.vmt"
#define BEACON_SPEED 2.0

EngineVersion g_Game;

ConVar g_DaredevilLevel;
ConVar g_DaredevilRingRadius;

int g_iHeroIndex;
int g_iPathLaserModelIndex;
int g_iPathHaloModelIndex;
bool g_bHasDaredevil[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Daredevil",
	author = PLUGIN_AUTHOR,
	description = "Daredevil hero",
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
	g_DaredevilLevel = CreateConVar("superheromod_daredevil_level", "0");
	g_DaredevilRingRadius = CreateConVar("superheromod_daredevil_ring_radius", "400", "Radius of the rings");
	AutoExecConfig(true, "daredevil", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Daredevil", g_DaredevilLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Radar Sense", "Rings show when other players are approaching");
	
	CreateTimer(BEACON_SPEED, Timer_Radar,_, TIMER_REPEAT);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasDaredevil[client] = (mode ? true : false);
}

public Action Timer_Radar(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
			
		if(!g_bHasDaredevil[i])
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
			int color[4] = { 255, 255, 255, 255 };
				
			enemyPos[2] += 40.0;
			TE_SetupBeamRingPoint(enemyPos, 0.0, g_DaredevilRingRadius.FloatValue, g_iPathLaserModelIndex, g_iPathHaloModelIndex, 0, 60, 1.0, 2.0, 0.0, color, 1, 0);
			TE_SendToClient(i);
		}
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasDaredevil[client] = false;
	return true;
}

public void OnMapStart()
{
	g_iPathHaloModelIndex = PrecacheModel(HALO_BEAM);
	g_iPathLaserModelIndex = PrecacheModel(MODEL_BEAM);
}


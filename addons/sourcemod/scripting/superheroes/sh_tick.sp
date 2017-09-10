#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_TickLevel;

int g_iHeroIndex;
bool g_bHasTick[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - The Tick",
	author = PLUGIN_AUTHOR,
	description = "The Tick hero",
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
	g_TickLevel = CreateConVar("superheromod_tick_level", "0");
	AutoExecConfig(true, "tick", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("The Tick", g_TickLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "No Fall Damage","SPOOOOOON! Take no damage from falling");
	AddNormalSoundHook(FallCheck);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_TickLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasTick[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(g_bHasTick[victim] && (damagetype & DMG_FALL))
		damage = 0.0;
}

public Action FallCheck(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) 
{
	if(!IsValidClient(entity))
		return Plugin_Continue;
		
	if(g_bHasTick[entity])
	{
		if(StrContains(sample, "damage1", false) != -1 || StrContains(sample, "damage2", false) != -1 || StrContains(sample, "damage3", false) != -1)
			return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasTick[client] = false;
	return true;
}



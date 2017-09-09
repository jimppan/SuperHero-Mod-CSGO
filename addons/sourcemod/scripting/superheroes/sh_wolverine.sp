#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_WolverineLevel;
ConVar g_WolverineKnifeSpeed;
ConVar g_WolverineDamageMultiplier;
ConVar g_WolverineHealPoints;

int g_iHeroIndex;
bool g_bHasWolverine[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Wolverine",
	author = PLUGIN_AUTHOR,
	description = "Wolverine hero",
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
	g_WolverineLevel = CreateConVar("superheromod_wolverine_level", "0");
	g_WolverineKnifeSpeed = CreateConVar("superheromod_wolverine_knife_speed", "1.5", "Speed when holding knife");
	g_WolverineDamageMultiplier = CreateConVar("superheromod_wolverine_knife_damage_multiplier", "1.35", "Amount if times damage knife should do");
	g_WolverineHealPoints = CreateConVar("superheromod_wolverine_health_per_seconds", "3", "Amount of health healed per second");
	AutoExecConfig(true, "wolverine", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Wolverine", g_WolverineLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Auto-Heal & Claws", "Auto-Heal, Extra knife damage and speed boost");
	
	int weapons[42];
	weapons[0] = view_as<int>(CSGOWeaponID_KNIFE);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_WolverineKnifeSpeed.FloatValue, weapons, 1);
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_WolverineDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_KNIFE));

	CreateTimer(1.0, Timer_Heal, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_WolverineLevel.IntValue);
}

public Action Timer_Heal(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
		
		if(g_bHasWolverine[i])
			SuperHero_AddHealth(i, g_WolverineHealPoints.IntValue);
	}
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasWolverine[client] = true;
			//Switch model
		}
		case SH_HERO_DROP:
		{
			g_bHasWolverine[client] = false;
		}
	}
	
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bHasWolverine[client] = false;
	return true;
}
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_DominoLevel;
ConVar g_DominoDamageMultiplierPerLevelDifference;

int g_iHeroIndex;
bool g_bHasDomino[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Domino",
	author = PLUGIN_AUTHOR,
	description = "Domino hero",
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
	g_DominoLevel = CreateConVar("superheromod_domino_level", "0");
	g_DominoDamageMultiplierPerLevelDifference = CreateConVar("superheromod_domino_damage_multiplier_per_level_difference", "0.1", "Amount of damage multiplier per level difference the damage should multiply by");
	AutoExecConfig(true, "domino", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Domino", g_DominoLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Even The Odds", "Do more damage to higher levels, the larger the difference the more damage");
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_DominoLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasDomino[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsValidClient(attacker))
		return;
	
	if(g_bHasDomino[attacker])
	{
		if(IsValidClient(victim))
		{
			int victimlevel = SuperHero_GetPlayerLevel(victim);
			int attackerlevel = SuperHero_GetPlayerLevel(attacker);
			
			if(victimlevel > attackerlevel)
			{
				int difference = victimlevel - attackerlevel;
				float damagemultiplier = difference * g_DominoDamageMultiplierPerLevelDifference.FloatValue;
				damage += (damage * damagemultiplier);
			}
		}
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasDomino[client] = false;
	return true;
}



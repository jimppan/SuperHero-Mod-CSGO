#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_BeastLevel;
ConVar g_BeastHealth;
ConVar g_BeastArmor;
ConVar g_BeastGravity;
ConVar g_BeastSpeed;
int g_iHeroIndex;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Beast",
	author = PLUGIN_AUTHOR,
	description = "Beast hero",
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
	g_BeastLevel = CreateConVar("superheromod_beast_level", "5");
	g_BeastHealth = CreateConVar("superheromod_beast_health", "175");
	g_BeastArmor = CreateConVar("superheromod_beast_armor", "200");
	g_BeastGravity = CreateConVar("superheromod_beast_gravity", "0.30");
	g_BeastSpeed = CreateConVar("superheromod_beast_speed", "2.3");
	
	AutoExecConfig(true, "Beast", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Beast", g_BeastLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Speed/Health/Armor/Gravity", "Faster than flash, more health, more armor, lower gravity");
	SuperHero_SetHeroHealth(g_iHeroIndex, g_BeastHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_BeastArmor.IntValue);
	SuperHero_SetHeroGravity(g_iHeroIndex, g_BeastGravity.FloatValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_BeastSpeed.FloatValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_BeastLevel.IntValue);
	SuperHero_SetHeroHealth(g_iHeroIndex, g_BeastHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_BeastArmor.IntValue);
	SuperHero_SetHeroGravity(g_iHeroIndex, g_BeastGravity.FloatValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_BeastSpeed.FloatValue);
}
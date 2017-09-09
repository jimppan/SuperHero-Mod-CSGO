#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_SupermanLevel;
ConVar g_SupermanHealth;
ConVar g_SupermanArmor;
ConVar g_SupermanGravity;
int g_iHeroIndex;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Superman",
	author = PLUGIN_AUTHOR,
	description = "Superman hero",
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
	g_SupermanLevel = CreateConVar("superheromod_superman_level", "0");
	g_SupermanHealth = CreateConVar("superheromod_superman_health", "150");
	g_SupermanArmor = CreateConVar("superheromod_superman_armor", "150");
	g_SupermanGravity = CreateConVar("superheromod_superman_gravity", "0.35");
	AutoExecConfig(true, "superman", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Superman", g_SupermanLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Health/Armor/Gravity", "More health, Free armor, Reduced gravity");
	SuperHero_SetHeroHealth(g_iHeroIndex, g_SupermanHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_SupermanArmor.IntValue);
	SuperHero_SetHeroGravity(g_iHeroIndex, g_SupermanGravity.FloatValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_SupermanLevel.IntValue);
}
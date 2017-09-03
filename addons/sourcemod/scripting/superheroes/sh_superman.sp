#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

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
	
	int heroIndex = SuperHero_CreateHero("Superman", g_SupermanLevel.IntValue);
	SuperHero_SetHeroInfo(heroIndex, "Health/Armor/Gravity", "More health, Free armor, Reduced gravity");
	SuperHero_SetHeroHealth(heroIndex, g_SupermanHealth.IntValue);
	SuperHero_SetHeroArmor(heroIndex, g_SupermanArmor.IntValue);
	SuperHero_SetHeroGravity(heroIndex, g_SupermanGravity.FloatValue);
}
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_FlashLevel;
ConVar g_FlashSpeed;
int g_iHeroIndex;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Flash",
	author = PLUGIN_AUTHOR,
	description = "Flash hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	g_FlashLevel = CreateConVar("superheromod_flash_level", "0");
	g_FlashSpeed = CreateConVar("superheromod_flash_speed", "2.0");
	AutoExecConfig(true, "flash", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Flash", g_FlashLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Super Speed", "You will run much faster with this hero");
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_FlashSpeed.FloatValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_FlashLevel.IntValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_FlashSpeed.FloatValue);
}
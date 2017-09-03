#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_FlashLevel;
ConVar g_FlashSpeed;

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
	
	int heroIndex = SuperHero_CreateHero("Flash", g_FlashLevel.IntValue);
	SuperHero_SetHeroInfo(heroIndex, "Super Speed", "You will run much faster with this hero");
	SuperHero_SetHeroSpeed(heroIndex, g_FlashSpeed.FloatValue);
}

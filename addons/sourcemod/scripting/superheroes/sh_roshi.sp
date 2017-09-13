#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_RoshiLevel;
ConVar g_RoshiHealth;
ConVar g_RoshiArmor;
ConVar g_RoshiSpeed;

int g_iHeroIndex;
bool g_bHasRoshi[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Master Roshi",
	author = PLUGIN_AUTHOR,
	description = "Master Roshi hero",
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
	
	HookEvent("player_blind", Event_PlayerBlind);
	
	g_RoshiLevel = CreateConVar("superheromod_roshi_level", "3");
	g_RoshiHealth = CreateConVar("superheromod_roshi_health", "150", "Amount of health roshi has");
	g_RoshiArmor = CreateConVar("superheromod_roshi_armor", "50", "Amount of armor roshi has");
	g_RoshiSpeed = CreateConVar("superheromod_roshi_speed", "1.3", "Amount of speed roshi has");
	
	AutoExecConfig(true, "roshi", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Master Roshi", g_RoshiLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "No Flash", "Equip sunglasses that blocks bright flashes");
	SuperHero_SetHeroHealth(g_iHeroIndex, g_RoshiHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_RoshiArmor.IntValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_RoshiSpeed.FloatValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_RoshiLevel.IntValue);
	SuperHero_SetHeroHealth(g_iHeroIndex, g_RoshiHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_RoshiArmor.IntValue);
	SuperHero_SetHeroSpeed(g_iHeroIndex, g_RoshiSpeed.FloatValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	g_bHasRoshi[client] = (mode ? true : false);
}

public Action Event_PlayerBlind(Event event, const char []name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bHasRoshi[client])
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0); 
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasRoshi[client] = false;
	return true;
}
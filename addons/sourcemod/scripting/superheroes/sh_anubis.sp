#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_AnubisLevel;

int g_iHeroIndex;
bool g_bHasAnubis[MAXPLAYERS + 1];

Handle g_hSyncMyDamage;
Handle g_hSyncEnemyDamage;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Anubis",
	author = PLUGIN_AUTHOR,
	description = "Anubis hero",
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
	g_AnubisLevel = CreateConVar("superheromod_anubis_level", "0");
	AutoExecConfig(true, "anubis", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Anubis", g_AnubisLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Dark Notices", "See Damage");
	
	g_hSyncMyDamage = CreateHudSynchronizer();
	g_hSyncEnemyDamage = CreateHudSynchronizer();
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasAnubis[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerTakeDamagePost(int victim, int attacker, int damagetype, int weapon, int damagetaken, int armortaken)
{
	if(GetClientTeam(victim) == GetClientTeam(attacker))
		return;
		
	if(g_bHasAnubis[attacker])
	{
		SetHudTextParams(0.49, 0.45, 3.0, 0, 100, 200, 100);
		ShowSyncHudText(attacker, g_hSyncMyDamage, "%d", damagetaken);
	}
	
	if(g_bHasAnubis[victim])
	{
		SetHudTextParams(0.49, 0.55, 3.0, 255, 0, 0, 100);
		ShowSyncHudText(victim, g_hSyncEnemyDamage, "%d", damagetaken);
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasAnubis[client] = false;
	return true;
}



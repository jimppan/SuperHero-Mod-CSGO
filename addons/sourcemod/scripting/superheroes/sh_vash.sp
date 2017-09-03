#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

#define FFADE_IN 0x0002        // Fade in
#define FFADE_MODULATE 0x0004  // Modulate

EngineVersion g_Game;

ConVar g_VashLevel;
ConVar g_VashDamageMultiplier;

int g_iHeroIndex;
bool g_bHasVash[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Vash The Stampede",
	author = PLUGIN_AUTHOR,
	description = "Vash The Stampede hero",
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
	g_VashLevel = CreateConVar("superheromod_vash_level", "4");
	g_VashDamageMultiplier = CreateConVar("superheromod_vash_damage_multiplier", "2.5", "Amount of times damage vash the stampede should do with his revolver");

	AutoExecConfig(true, "vash", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Vash The Stampede", g_VashLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Revolver & Evasion", "Deagle does more damage, evade by removing random hitzones");
	SuperHero_SetHeroSecondaryWeapon(g_iHeroIndex, view_as<int>(CSGOWeaponID_DEAGLE));
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_VashDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_DEAGLE));
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasVash[client] = true;
			//Change model
			if(SuperHero_GetHighestSecondaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_DEAGLE))
			{
				StripSecondary(client);
				GivePlayerItem(client, "weapon_deagle");
			}
			
		}
		case SH_HERO_DROP:
		{
			g_bHasVash[client] = false;
		}
	}	
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasVash[client])
		return;
		
	if(SuperHero_GetHighestSecondaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_DEAGLE))
	{
		StripSecondary(client);
		GivePlayerItem(client, "weapon_deagle");
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(g_bHasVash[victim])
	{
		if(hitgroup == GetRandomInt(0, 7))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasVash[client] = false;
	return true;
}
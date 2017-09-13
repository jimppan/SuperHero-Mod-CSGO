#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_RamboLevel;
ConVar g_RamboHealth;
ConVar g_RamboArmor;
ConVar g_RamboDamageMultiplier;

int g_iHeroIndex;
bool g_bHasRambo[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Rambo",
	author = PLUGIN_AUTHOR,
	description = "Rambo hero",
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
	g_RamboLevel = CreateConVar("superheromod_rambo_level", "7");
	g_RamboHealth = CreateConVar("superheromod_rambo_health", "125", "Amount of health rambo has");
	g_RamboArmor = CreateConVar("superheromod_rambo_armor", "150", "Amount of armor rambo has");
	g_RamboDamageMultiplier = CreateConVar("superheromod_rambo_damage_multiplier", "1.5", "Amount of times fire rate rambos M249 should have");
	
	AutoExecConfig(true, "rambo", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Rambo", g_RamboLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Rambo Style", "M249/Extra Damage/Extra Health & Armor\nSmoke/HE/Flash Grenade");
	SuperHero_SetHeroPrimaryWeapon(g_iHeroIndex, view_as<int>(CSGOWeaponID_M249));
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_RamboDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_M249));
	SuperHero_SetHeroHealth(g_iHeroIndex, g_RamboHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_RamboArmor.IntValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_RamboLevel.IntValue);
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_RamboDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_M249));
	SuperHero_SetHeroHealth(g_iHeroIndex, g_RamboHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_RamboArmor.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasRambo[client] = true;
			if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_M249))
			{
				StripPrimary(client);
				GivePlayerItem(client, "weapon_m249");
			}
			GivePlayerItem(client, "weapon_hegrenade");
			GivePlayerItem(client, "weapon_smokegrenade");
			GivePlayerItem(client, "weapon_flashbang");
		}
		case SH_HERO_DROP:
		{
			g_bHasRambo[client] = false;
		}
	}	
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasRambo[client])
		return;
	
	if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_M249))
	{
		StripPrimary(client);
		GivePlayerItem(client, "weapon_m249");
	}
	GivePlayerItem(client, "weapon_hegrenade");
	GivePlayerItem(client, "weapon_smokegrenade");
	GivePlayerItem(client, "weapon_flashbang");
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasRambo[client] = false;
	return true;
}
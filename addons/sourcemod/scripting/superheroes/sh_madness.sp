#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_MadnessLevel;
ConVar g_MadnessHealth;
ConVar g_MadnessArmor;
ConVar g_MadnessDamageMultiplier;

int g_iHeroIndex;
bool g_bHasMadness[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Madness",
	author = PLUGIN_AUTHOR,
	description = "Madness hero",
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
	g_MadnessLevel = CreateConVar("superheromod_madness_level", "9");
	g_MadnessHealth = CreateConVar("superheromod_madness_health", "200", "Amount of health madness has");
	g_MadnessArmor = CreateConVar("superheromod_madness_armor", "100", "Amount of armor madness has");
	g_MadnessDamageMultiplier = CreateConVar("superheromod_madness_damage_multiplier", "2.0", "Amount of times fire rate madness' sawed-off should have");
	
	AutoExecConfig(true, "madness", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Madness", g_MadnessLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Dual Sawed-Off's", "Dual Sawed-Off's/Extra HP and Armor/Extra Sawed-Off damage");
	SuperHero_SetHeroPrimaryWeapon(g_iHeroIndex, view_as<int>(CSGOWeaponID_SAWEDOFF));
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_MadnessDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_SAWEDOFF));
	SuperHero_SetHeroHealth(g_iHeroIndex, g_MadnessHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_MadnessArmor.IntValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_MadnessLevel.IntValue);
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_MadnessDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_SAWEDOFF));
	SuperHero_SetHeroHealth(g_iHeroIndex, g_MadnessHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_MadnessArmor.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasMadness[client] = true;
			//Change model
			if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_SAWEDOFF))
			{
				StripPrimary(client);
				GivePlayerItem(client, "weapon_sawedoff");
			}
			
		}
		case SH_HERO_DROP:
		{
			g_bHasMadness[client] = false;
		}
	}	
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasMadness[client])
		return;
	
	if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_SAWEDOFF))
	{
		StripPrimary(client);
		GivePlayerItem(client, "weapon_sawedoff");
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasMadness[client] = false;
	return true;
}
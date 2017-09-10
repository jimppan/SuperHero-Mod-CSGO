#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

#define FFADE_IN 0x0002        // Fade in
#define FFADE_MODULATE 0x0004  // Modulate

EngineVersion g_Game;

ConVar g_HobgoblinLevel;
ConVar g_HobgoblinDamageMultiplier;
ConVar g_HobgoblinReplenishCooldown;

int g_iHeroIndex;
bool g_bHasHobgoblin[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Hobgoblin",
	author = PLUGIN_AUTHOR,
	description = "Hobgoblin hero",
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
	g_HobgoblinLevel = CreateConVar("superheromod_hobgoblin_level", "0");
	g_HobgoblinDamageMultiplier = CreateConVar("superheromod_hobgoblin_grenade_damage", "1.5", "Amount of times damage the grenade should do");
	g_HobgoblinReplenishCooldown = CreateConVar("superheromod_hobgoblin_replenish_cooldown", "10", "Amount of seconds it should take until player recieves another nade");
	AutoExecConfig(true, "hobgoblin", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Hobgoblin", g_HobgoblinLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Hobgoblin Grenades", "Extra nade damage/Refill nade");
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_HobgoblinDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_HEGRENADE));
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_HobgoblinLevel.IntValue);
	SuperHero_SetHeroDamageMultiplier(g_iHeroIndex, g_HobgoblinDamageMultiplier.FloatValue, view_as<int>(CSGOWeaponID_HEGRENADE));
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasHobgoblin[client] = true;
			GiveGrenade(client);
			
		}
		case SH_HERO_DROP:
		{
			g_bHasHobgoblin[client] = false;
		}
	}	
	
	g_bHasHobgoblin[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasHobgoblin[client])
		return;
	
	GiveGrenade(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "hegrenade_projectile"))
		SDKHook(entity, SDKHook_SpawnPost, OnGrenadeSpawn);
}

public Action OnGrenadeSpawn(int entity)
{
	int thrower = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(!IsValidClient(thrower))
		return Plugin_Continue;

	if(!g_bHasHobgoblin[thrower])
		return Plugin_Continue;

	CreateTimer(g_HobgoblinReplenishCooldown.FloatValue, Timer_Grenade, GetClientUserId(thrower));
	return Plugin_Continue;
}

public Action Timer_Grenade(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
		
	if(!g_bHasHobgoblin[client])
		return Plugin_Stop;
		
	GiveGrenade(client);
	return Plugin_Continue;
}

public void GiveGrenade(int client)
{
	if(IsPlayerAlive(client))
		GivePlayerItem(client, "weapon_hegrenade");
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasHobgoblin[client] = false;
	return true;
}
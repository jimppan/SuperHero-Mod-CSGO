#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_PunisherLevel;
ConVar g_PunisherEnableZeus;

int g_iHeroIndex;
bool g_bHasPunisher[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Punisher",
	author = PLUGIN_AUTHOR,
	description = "Punisher hero",
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
	g_PunisherLevel = CreateConVar("superheromod_punisher_level", "0");
	g_PunisherEnableZeus = CreateConVar("superheromod_punisher_enable_zeus", "0", "Should infinite ammo be applied to zeus?");
	AutoExecConfig(true, "punisher", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Punisher", g_PunisherLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Unlimited Ammo", "Endless Bullets. No Reload! Keep Shooting");
	
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_PunisherLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasPunisher[client] = (mode ? true : false);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(g_bHasPunisher[client])
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != INVALID_ENT_REFERENCE)
		{
			if(!g_PunisherEnableZeus.BoolValue)
			{
				char szClassName[32];
				GetEntityClassname(weapon, szClassName, sizeof(szClassName));
				if(StrContains(szClassName, "zeus") != -1)
					return Plugin_Continue;
			}
			SetEntProp(weapon, Prop_Send, "m_iClip1", 30);
		}
	}
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasPunisher[client] = false;
	return true;
}



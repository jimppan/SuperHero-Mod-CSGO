#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_MorpheusLevel;
ConVar g_MorpheusGravity;
ConVar g_MorpheusFireRate;

int g_iHeroIndex;
bool g_bHasMorpheus[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Morpheus",
	author = PLUGIN_AUTHOR,
	description = "Morpheus hero",
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
	g_MorpheusLevel = CreateConVar("superheromod_morpheus_level", "8");
	g_MorpheusGravity = CreateConVar("superheromod_morpheus_gravity", "0.35", "Amount of gravity morpheus has");
	g_MorpheusFireRate = CreateConVar("superheromod_morpheus_attack_speed", "1.5", "Amount of times fire rate morpheus mp5 should have");
	AutoExecConfig(true, "morpheus", "sourcemod/superheromod");
	
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	
	g_iHeroIndex = SuperHero_CreateHero("Morpheus", g_MorpheusLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Dual MP7's", "Lower Gravity/Dual MP7's/Unlimited Ammo");
	SuperHero_SetHeroPrimaryWeapon(g_iHeroIndex, view_as<int>(CSGOWeaponID_MP7));
	SuperHero_SetHeroGravity(g_iHeroIndex, g_MorpheusGravity.FloatValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_MorpheusLevel.IntValue);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(SetNextPrimaryAttack, event.GetInt("userid"));
}

public void SetNextPrimaryAttack(any data)
{
	int client = GetClientOfUserId(data);
	
	if(!IsValidClient(client))
		return;
	
	if(!g_bHasMorpheus[client])
		return;
		
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon != INVALID_ENT_REFERENCE)
	{
		char szClassName[32];
		GetEntityClassname(weapon, szClassName, sizeof(szClassName));
		if(StrEqual(szClassName, "weapon_mp7"))
		{
			float nextAttack = GetGameTime() - GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
			nextAttack = FloatAbs(nextAttack);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + (nextAttack / g_MorpheusFireRate.FloatValue));
			SetEntProp(weapon, Prop_Send, "m_iClip1", 30);
		}
	}
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasMorpheus[client] = true;
			//Change model
			if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_MP7))
			{
				StripPrimary(client);
				GivePlayerItem(client, "weapon_mp7");
			}
			
		}
		case SH_HERO_DROP:
		{
			g_bHasMorpheus[client] = false;
		}
	}	
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasMorpheus[client])
		return;
	
	if(SuperHero_GetHighestPrimaryWeaponLevel(client) == view_as<int>(CSGOWeaponID_MP7))
	{
		StripPrimary(client);
		GivePlayerItem(client, "weapon_mp7");
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasMorpheus[client] = false;
	return true;
}
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define CRATE_MODEL "models/props/props_crates/wooden_crate_64x64.mdl"
#define CRATE_IMPACT_SOUND "physics/wood/wood_crate_impact_hard4.wav"
#define CRATE_BREAK_SOUND "physics/wood/wood_crate_break1.wav"

EngineVersion g_Game;

ConVar g_MorphLevel;

int g_iHeroIndex;
int g_iBox[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
bool g_bMorphed[MAXPLAYERS + 1];
Handle g_HudSync;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Morph",
	author = PLUGIN_AUTHOR,
	description = "Morph hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/morph.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_MorphLevel = CreateConVar("superheromod_morph_level", "2");
	
	AutoExecConfig(true, "morph", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Morph", g_MorphLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Shapeshift into a crate", "Press +POWER key to disguise yourself as a crate and\nblend into the environment!");
	SuperHero_SetHeroBind(g_iHeroIndex);
	
	g_HudSync = CreateHudSynchronizer();
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_MorphLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	RemoveBox(client);
}

public void SuperHero_OnPlayerDeath(int victim, int attacker, bool headshot)
{
	RemoveBox(victim);
}

public void SuperHero_OnHeroBind(int client, int heroIndex, int key)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	switch(key)
	{
		case SH_KEYDOWN:
		{
			if(IsFreezeTime() || !IsPlayerAlive(client))
				return;
			
			if(!g_bMorphed[client])
			{
				g_bMorphed[client] = true;
				
				SetHudTextParams(0.41, 0.8, 2.0, 0, 255, 0, 255);
				ShowSyncHudText(client, g_HudSync, "%t", "Morphed");
				g_iBox[client] = EntIndexToEntRef(CreateBox(client));
				EmitSoundToAllAny(CRATE_IMPACT_SOUND, client);
			}
			else
			{
				RemoveBox(client);
				EmitSoundToAllAny(CRATE_BREAK_SOUND, client);
				SetHudTextParams(0.36, 0.8, 2.0, 0, 255, 0, 255);
				ShowSyncHudText(client, g_HudSync, "%t", "Unmorphed");
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	RemoveBox(client);
}

stock int CreateBox(int client)
{
	g_bMorphed[client] = true;
	int entity = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(entity)) 
	{
		SetEntityModel(entity, CRATE_MODEL);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
		DispatchSpawn(entity);
		SetEntityMoveType(entity, MOVETYPE_NONE);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		
		float pos[3], angles[3];
		GetClientAbsOrigin(client, pos);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		TeleportEntity(entity, pos, angles, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
	}
	return entity;
}

stock void RemoveBox(int client)
{
	g_bMorphed[client] = false;
	int box = EntRefToEntIndex(g_iBox[client]);
	if(box != INVALID_ENT_REFERENCE)
		AcceptEntityInput(box, "Kill");
	g_iBox[client] = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
	PrecacheModel(CRATE_MODEL);
	PrecacheSoundAny(CRATE_IMPACT_SOUND, true);
	PrecacheSoundAny(CRATE_BREAK_SOUND, true);
}
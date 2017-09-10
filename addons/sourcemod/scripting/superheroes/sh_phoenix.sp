#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required
#define MODEL_BEAM "materials/sprites/laserbeam.vmt"
#define SOUND_PHOENIX "superheromod/phoenix.mp3"
EngineVersion g_Game;

ConVar g_PhoenixLevel;
ConVar g_PhoenixExplosionDamage;
ConVar g_PhoenixExplosionRadius;

int g_iHeroIndex;
int g_iPathLaserModelIndex;
bool g_bHasPhoenix[MAXPLAYERS + 1];
bool g_bHasRespawned[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Phoenix",
	author = PLUGIN_AUTHOR,
	description = "Phoenix hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/phoenix.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	g_PhoenixLevel = CreateConVar("superheromod_phoenix_level", "8");
	g_PhoenixExplosionDamage = CreateConVar("superheromod_phoenix_explosion_damage", "100", "Amount of damage the explosion should deal");
	g_PhoenixExplosionRadius = CreateConVar("superheromod_phoenix_explosion_radius", "300", "Amount of radius the explosion should have");
	
	AutoExecConfig(true, "phoenix", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Phoenix", g_PhoenixLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Re-Birth", "As the Phoenix you shall rise again from your burning ashes.");
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_PhoenixLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasPhoenix[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!IsGameLive())
		return;
		
	if(g_bHasPhoenix[client])
	{
		if(!newroundspawn)
			g_bHasRespawned[client] = true;
		else
			g_bHasRespawned[client] = false;
	}
}

public void SuperHero_OnPlayerDeath(int victim, int attacker, bool headshot)
{
	if(!IsGameLive())
		return;
		
	if(g_bHasPhoenix[victim] && !g_bHasRespawned[victim] && GetAliveCountTeam(GetClientTeam(victim)) > 1)
	{
		float playerPos[3];
		GetClientAbsOrigin(victim, playerPos);
		CS_CreateExplosion(victim, g_PhoenixExplosionDamage.IntValue, g_PhoenixExplosionRadius.IntValue, playerPos);
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasPhoenix[client] = false;
	return true;
}

public void OnMapStart()
{
	PrecacheSoundAny(SOUND_PHOENIX, true);
	AddFileToDownloadsTable("sound/superheromod/phoenix.mp3");
	g_iPathLaserModelIndex = PrecacheModel(MODEL_BEAM);
}

void CS_CreateExplosion(int client, int damage, int radius, float pos[3])
{
	int entity;
	if((entity = CreateEntityByName("env_explosion")) != -1)
	{
		DispatchKeyValue(entity, "spawnflags", "552");
		DispatchKeyValue(entity, "rendermode", "5");
		
		SetEntProp(entity, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(entity, Prop_Data, "m_iRadiusOverride", radius);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", GetClientTeam(client));
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);

		DispatchSpawn(entity);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		RequestFrame(TriggerExplosion, entity);
	}
}

public void TriggerExplosion(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	AcceptEntityInput(entity, "explode");
	float entityPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityPos);
	if(IsValidClient(owner))
	{
		CS_RespawnPlayer(owner);
		TeleportEntity(owner, entityPos, NULL_VECTOR, NULL_VECTOR);
		EmitSoundToAllAny(SOUND_PHOENIX, owner);
		PrintToChat(owner, "%t", "Respawned", SH_PREFIX, "[\x07Phoenix\x09]");
	}
	TE_SetupSmoke(entityPos, g_iPathLaserModelIndex, 10.0, 60);
	TE_SendToAll();
	
	TE_SetupSparks(entityPos, NULL_VECTOR, 10, 10);
	TE_SendToAll();
	AcceptEntityInput(entity, "Kill");
}

stock int GetAliveCountTeam(int team)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			count++;
	}
	return count;
}

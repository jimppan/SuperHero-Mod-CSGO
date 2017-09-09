#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

#define PENGUIN_REFRESH_RATE 0.1
#define MODEL_BEAM "materials/sprites/laserbeam.vmt"
#define HALO_BEAM "materials/sprites/purplelaser1.vmt"

EngineVersion g_Game;

ConVar g_PenguinLevel;
ConVar g_PenguinSpeed;
ConVar g_PenguinFuse;
ConVar g_PenguinTimeToSeek;
ConVar g_PenguinCooldown;

int g_iPathLaserModelIndex;
int g_iPathHaloModelIndex;
int g_iHeroIndex;
bool g_bHasPenguin[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Penguin",
	author = PLUGIN_AUTHOR,
	description = "Penguin hero",
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
	g_PenguinLevel = CreateConVar("superheromod_penguin_level", "0");
	g_PenguinSpeed = CreateConVar("superheromod_penguin_speed", "900", "Amount of speed the penguin seeks to his target");
	g_PenguinFuse = CreateConVar("superheromod_penguin_fuse", "5", "Amount of seconds until the penguin explodes if he havnt found his target");
	g_PenguinTimeToSeek = CreateConVar("superheromod_penguin_time_to_seek", "1", "Amount of seconds until the penguin starts seeking after thrown");
	g_PenguinCooldown = CreateConVar("superheromod_penguin_cooldown", "60", "Amount of seconds until penguin can be used again");
	
	AutoExecConfig(true, "penguin", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Penguin", g_PenguinLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Seeking HE-Penguins", "Throw a penguin strapped with a nade that seeks out your enemy");
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_PenguinLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	g_bHasPenguin[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(!g_bHasPenguin[client])
		return;
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
	
	if(SuperHero_IsPlayerHeroInCooldown(thrower, g_iHeroIndex))
		return Plugin_Continue;
	
	if(!g_bHasPenguin[thrower])
		return Plugin_Continue;
		
	RequestFrame(SetNextThink, EntIndexToEntRef(entity));
	CreateTimer(g_PenguinTimeToSeek.FloatValue, Timer_StartSeek, EntIndexToEntRef(entity));
	SuperHero_SetPlayerHeroCooldown(thrower, g_iHeroIndex, g_PenguinCooldown.FloatValue);

	return Plugin_Continue;
}

public void SetNextThink(any data)
{
	int grenade = EntRefToEntIndex(data);
	SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
	SetEntPropFloat(grenade, Prop_Data, "m_flElasticity", 5.0);
	SetEntPropFloat(grenade, Prop_Data, "m_flGroundSpeed", 100.0);
}

public Action Timer_StartSeek(Handle timer, any data)
{
	int grenade = EntRefToEntIndex(data);
	if(grenade == INVALID_ENT_REFERENCE)
		return Plugin_Stop;

	int client = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	if(!IsValidClient(client))
		return Plugin_Stop;
	
	if(!g_bHasPenguin[client])
		return Plugin_Stop;

	SetEntProp(grenade, Prop_Data, "m_takedamage", 2);
	SetEntProp(grenade, Prop_Data, "m_iHealth", 1);
	
	CreateTimer(g_PenguinFuse.FloatValue, Timer_Detonate, data);
	DataPack pack = CreateDataPack();
	CreateDataTimer(PENGUIN_REFRESH_RATE, Timer_Seek, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(grenade));
	pack.WriteCell(GetClientUserId(client));
	int target = FindClosestTarget(client);
	if(target != INVALID_ENT_REFERENCE)
		pack.WriteCell(GetClientOfUserId(target));
	else
		pack.WriteCell(target);
	
	return Plugin_Continue;
}

public Action Timer_Detonate(Handle timer, any data)
{
	int grenade = EntRefToEntIndex(data);
	if(grenade == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", 1);
	SDKHooks_TakeDamage(grenade, grenade, grenade, 1.0);
	
	return Plugin_Continue;
}

public Action Timer_Seek(Handle timer, DataPack pack)
{
	pack.Reset();
	int grenade = EntRefToEntIndex(pack.ReadCell());
	int thrower = GetClientOfUserId(pack.ReadCell());
	int target = pack.ReadCell();
	if(target == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	else
		target = GetClientOfUserId(target);
		
	if(grenade == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
	
	if(!IsValidClient(target) || !IsPlayerAlive(target))
	{
		target = FindClosestTarget(thrower);
		if(!IsValidClient(target))
			return Plugin_Stop;
	}

	float targetPos[3];
	float nadePos[3];
	float direction[3];
	GetEntPropVector(grenade, Prop_Send, "m_vecOrigin", nadePos);
	GetClientAbsOrigin(target, targetPos);
	targetPos[2] += 40.0;
	SubtractVectors(targetPos, nadePos, direction);
	
	NormalizeVector(direction, direction);
	ScaleVector(direction, g_PenguinSpeed.FloatValue);
	TeleportEntity(grenade, NULL_VECTOR, NULL_VECTOR, direction);
	
	int color[4] =  { 255, 80, 80, 255 };

	TE_SetupBeamFollow(grenade, g_iPathLaserModelIndex, g_iPathHaloModelIndex, 4.0, 4.1, 3.0, 5, color);
	TE_SendToAll();
	
	if(GetVectorDistance(targetPos, nadePos) <= 30.0)
	{
		SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", 1);
		SDKHooks_TakeDamage(grenade, grenade, grenade, 1.0);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public int FindClosestTarget(int client)
{
	float playerPos[3];
	float targetPos[3];
	float distance = 9999999999.0;
	int returnclient = -1;
	GetClientAbsOrigin(client, playerPos);
	
	for (int i = 1; i <= MaxClients;i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(client) == GetClientTeam(i))
			continue;
			
		GetClientAbsOrigin(i, targetPos);	
		float currentdistance = GetVectorDistance(playerPos, targetPos);
		distance = floatmin(distance, currentdistance);
		
		if(distance == currentdistance)
			returnclient = i;
	}
	
	return returnclient;
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasPenguin[client] = false;
	return true;
}

public void OnMapStart()
{
	g_iPathHaloModelIndex = PrecacheModel(HALO_BEAM);
	g_iPathLaserModelIndex = PrecacheModel(MODEL_BEAM);
}
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define RAY_BEAM "materials/effects/blueblacklargebeam.vmt"
#define RAY_HALO "materials/sprites/purplelaser1.vmt"
#define RAY_SOUND "superheromod/ray.mp3"
#define RAY_HIT_SOUND "superheromod/cyclopsbeamhit.mp3"

EngineVersion g_Game;

ConVar g_GoldenfriezaLevel;
ConVar g_GoldenfriezaDamage;
ConVar g_GoldenfriezaCooldown;
ConVar g_GoldenfriezaRayCount;
ConVar g_GoldenfriezaRaySpeed;
ConVar g_GoldenfriezaRaySpread;
ConVar g_GoldenfriezaHealth;
ConVar g_GoldenfriezaArmor;

int g_iPathLaserModelIndex;
int g_iPathHaloModelIndex;
int g_iHeroIndex;
int g_iBeamsFired[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Golden Frieza",
	author = PLUGIN_AUTHOR,
	description = "Golden Frieza hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/goldenfrieza.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_GoldenfriezaLevel = CreateConVar("superheromod_goldenfrieza_level", "11");
	g_GoldenfriezaDamage = CreateConVar("superheromod_goldenfrieza_damage", "50", "Amount of damage each ray should deal");
	g_GoldenfriezaCooldown = CreateConVar("superheromod_goldenfrieza_cooldown", "30", "Amount of time in seconds this ability should be on cooldown");
	g_GoldenfriezaRayCount = CreateConVar("superheromod_goldenfrieza_ray_count", "10", "Amount of rays golden frieza should fire");
	g_GoldenfriezaRaySpeed = CreateConVar("superheromod_goldenfrieza_ray_speed", "0.2", "Amount of time between each ray");
	g_GoldenfriezaRaySpread = CreateConVar("superheromod_goldenfrieza_ray_spread", "1.5", "Amount of spread the ray should have (0 for no spread)");
	g_GoldenfriezaHealth = CreateConVar("superheromod_goldenfrieza_health", "225", "Amount of health golden frieza has");
	g_GoldenfriezaArmor = CreateConVar("superheromod_goldenfrieza_armor", "200", "Amount of armor golden frieza has");
	
	AutoExecConfig(true, "goldenfrieza", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Golden Frieza", g_GoldenfriezaLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Emperor's Death Beam", "Press the +power key to fire many death beams");
	SuperHero_SetHeroBind(g_iHeroIndex);
	SuperHero_SetHeroHealth(g_iHeroIndex, g_GoldenfriezaHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_GoldenfriezaArmor.IntValue);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_GoldenfriezaLevel.IntValue);
	SuperHero_SetHeroHealth(g_iHeroIndex, g_GoldenfriezaHealth.IntValue);
	SuperHero_SetHeroArmor(g_iHeroIndex, g_GoldenfriezaArmor.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	if(mode == SH_HERO_ADD)
	{
		SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	}
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
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


			if (SuperHero_IsPlayerHeroInCooldown(client, g_iHeroIndex)) 
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
			int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(wep != INVALID_ENT_REFERENCE)
			{
				char szWeapon[32];
				GetEntityClassname(wep, szWeapon, sizeof(szWeapon));
				if(StrContains(szWeapon, "knife") == -1 && StrContains(szWeapon, "bayonet") == -1)
				{
					SetHudTextParams(0.35, 0.60, 3.0, 255, 255, 0, 255);
					ShowHudText(client, -1, "%t", "Equip Knife");
					return;
				}
			}
			
			g_iBeamsFired[client] = 0;
			
			FireBeam(client);
			CreateTimer(g_GoldenfriezaRaySpeed.FloatValue, Timer_Beam, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_GoldenfriezaCooldown.FloatValue);
		}
	}
}


public Action Timer_Beam(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(wep != INVALID_ENT_REFERENCE)
	{
		char szWeapon[32];
		GetEntityClassname(wep, szWeapon, sizeof(szWeapon));
		if(StrContains(szWeapon, "knife") == -1 && StrContains(szWeapon, "bayonet") == -1)
			return Plugin_Stop;
	}
	
	if(g_iBeamsFired[client] <= g_GoldenfriezaRayCount.IntValue)
		FireBeam(client);
	else
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public void FireBeam(int client)
{
	g_iBeamsFired[client]++;
	float eyeAngles[3], startPos[3], endPos[3];
	GetClientEyeAngles(client, eyeAngles);
	GetClientEyePosition(client, startPos);
	startPos[2] -= 15.0;
	eyeAngles[0] += GetRandomFloat(-g_GoldenfriezaRaySpread.FloatValue, g_GoldenfriezaRaySpread.FloatValue);
	eyeAngles[1] += GetRandomFloat(-g_GoldenfriezaRaySpread.FloatValue, g_GoldenfriezaRaySpread.FloatValue);
	eyeAngles[2] += GetRandomFloat(-g_GoldenfriezaRaySpread.FloatValue, g_GoldenfriezaRaySpread.FloatValue);
	
	Handle trace = TR_TraceRayFilterEx(startPos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
	if(TR_DidHit(trace))
	{
		int hit = TR_GetEntityIndex(trace);
		TR_GetEndPosition(endPos, trace);
		if(IsValidClient(hit) && IsPlayerAlive(hit) && (GetClientTeam(client) != GetClientTeam(hit)))
		{
			EmitSoundToClientAny(client, RAY_HIT_SOUND);
			// Deal the damage...
			SDKHooks_TakeDamage(hit, 0, client, g_GoldenfriezaDamage.FloatValue, DMG_ENERGYBEAM, -1);
		}
	}
	CloseHandle(trace);
	
	LaserEffects(client, startPos, endPos);
}

public void LaserEffects(int client, float startPos[3], float endPos[3])
{
	EmitAmbientSoundAny(RAY_SOUND, startPos, client);
	int color[4] =  { 220, 100, 30, 255 };
	TE_SetupBeamPoints(startPos, endPos, g_iPathLaserModelIndex, g_iPathHaloModelIndex, 0, 60, 1.0, 6.0, 6.1, 0, 0.0, color, 5);
	TE_SendToAll();

	TE_SetupSmoke(endPos, g_iPathHaloModelIndex, 10.0, 60);
	TE_SendToAll();
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	return true;
}

public void OnClientDisconnect(int client)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/ray.mp3");
	AddFileToDownloadsTable("sound/superheromod/cyclopsbeamhit.mp3");
	g_iPathHaloModelIndex = PrecacheModel(RAY_BEAM);
	g_iPathLaserModelIndex = PrecacheModel(RAY_HALO);
	PrecacheSoundAny(RAY_SOUND, true);
	PrecacheSoundAny(RAY_HIT_SOUND, true);
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity >= 0 && entityhit != entity)
		return true;
	
	return false;
}
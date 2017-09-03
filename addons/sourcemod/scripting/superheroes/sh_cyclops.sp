#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define HOOK_REFRESH_TIME 0.1
#define MODEL_BEAM "materials/sprites/laserbeam.vmt"
#define HALO_BEAM "materials/sprites/purplelaser1.vmt"
#define BEAM_SOUND "superheromod/cyclopsbeam.mp3"
#define BEAM_HIT_SOUND "superheromod/cyclopsbeamhit.mp3"
EngineVersion g_Game;

ConVar g_CyclopsLevel;
ConVar g_CyclopsBeamDamage;
ConVar g_CyclopsBeamAmmo;
ConVar g_CyclopsSmokeParticle;
ConVar g_CyclopsBeamCooldown;

int g_iPathLaserModelIndex;
int g_iPathHaloModelIndex;
int g_iBeamsLeft[MAXPLAYERS + 1];
int g_iHeroIndex;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Cyclops",
	author = PLUGIN_AUTHOR,
	description = "Cyclops hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/cyclops.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_CyclopsLevel = CreateConVar("superheromod_cyclops_level", "5");
	g_CyclopsBeamDamage = CreateConVar("superheromod_cyclops_beam_damage", "40", "Amount of damage cyclops beam should do");
	g_CyclopsBeamAmmo = CreateConVar("superheromod_cyclops_beam_ammo", "20", "Amount of shots given each round, -1 is unlimited");
	g_CyclopsSmokeParticle = CreateConVar("superheromod_cyclops_smoke_particle", "1", "Show smoke particle after beam");
	g_CyclopsBeamCooldown = CreateConVar("superheromod_cyclops_beam_cooldown", "0.20", "Cooldown between shots");
	AutoExecConfig(true, "cyclops", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Cyclops", g_CyclopsLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Optic Blast", "Press the +power key to fire your optic laser beam");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	if(mode == SH_HERO_ADD)
	{
		SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
		g_iBeamsLeft[client] = g_CyclopsBeamAmmo.IntValue;
	}
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	g_iBeamsLeft[client] = g_CyclopsBeamAmmo.IntValue;
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

			if (g_iBeamsLeft[client] == 0) 
			{
				SetHudTextParams(0.43, 0.60, 3.0, 255, 255, 0, 255);
				ShowHudText(client, -1, "%t", "No Optic Blasts");
				SuperHero_PlayDenySound(client);
				return;
			}

			if (SuperHero_IsPlayerHeroInCooldown(client, g_iHeroIndex)) 
			{
				SuperHero_PlayDenySound(client);
				return;
			}

			// shoot
			FireLaser(client);
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_CyclopsBeamCooldown.FloatValue);

		}
	}
}

public void FireLaser(int client)
{
	if (!IsPlayerAlive(client)) 
		return;

	// Do not decrement if unlimited shots are set
	if (g_iBeamsLeft[client] > 0) 
		g_iBeamsLeft[client]--;

	float eyeAngles[3], startPos[3], endPos[3];
	int enemy;
	GetClientEyeAngles(client, eyeAngles);
	GetClientEyePosition(client, startPos);
	enemy = GetClientAimTarget(client, true);
	
	Handle trace = TR_TraceRayFilterEx(startPos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	LaserEffects(client, startPos, endPos);
	
	if (IsValidClient(enemy) && IsPlayerAlive(enemy) && (GetClientTeam(client) != GetClientTeam(enemy)))
	{
		EmitSoundToClientAny(client, BEAM_HIT_SOUND);

		// Deal the damage...
		SDKHooks_TakeDamage(enemy, client, client, g_CyclopsBeamDamage.FloatValue, DMG_GENERIC, -1);
	}
}

public void LaserEffects(int client, float startPos[3], float endPos[3])
{
	EmitAmbientSoundAny(BEAM_SOUND, startPos);
	int color[4] =  { 255, 0, 0, 255 };
	TE_SetupBeamPoints(startPos, endPos, g_iPathLaserModelIndex, g_iPathHaloModelIndex, 0, 60, 1.0, 8.0, 8.1, 0, 0.0, color, 5);
	TE_SendToAll();
	if(g_CyclopsSmokeParticle.BoolValue)
	{
		TE_SetupSmoke(endPos, g_iPathHaloModelIndex, 4.0, 60);
		TE_SendToAll();
	}
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
	AddFileToDownloadsTable("sound/superheromod/cyclopsbeam.mp3");
	AddFileToDownloadsTable("sound/superheromod/cyclopsbeamhit.mp3");
	g_iPathHaloModelIndex = PrecacheModel(HALO_BEAM);
	g_iPathLaserModelIndex = PrecacheModel(MODEL_BEAM);
	PrecacheSoundAny(BEAM_SOUND, true);
	PrecacheSoundAny(BEAM_HIT_SOUND, true);
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity == 0 && entityhit != entity)
		return true;
	
	return false;
}
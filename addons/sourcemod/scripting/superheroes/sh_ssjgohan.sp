#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.04"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required
#define BEAM_REFRESH_RATE 0.1
#define BEAM_SOUND "superheromod/beamhead.mp3"
#define HA_SOUND "superheromod/gohan_ha.mp3"
#define KAMEHAME_SOUND "superheromod/gohan_kamehame.mp3"
#define BEAM_HEAD "materials/superheromod/kamehamehahead.vmt"
#define BEAM_EXPLOSION "materials/superheromod/kamehamehaexplosion.vmt"
#define BEAM_TRAIL "materials/effects/blueblacklargebeam.vmt"
EngineVersion g_Game;

ConVar g_SSJGohanLevel;
ConVar g_SSJGohanDamageMultiplier;
ConVar g_SSJGohanRadiusMultiplier;
ConVar g_SSJGohanCooldown;
ConVar g_SSJGohanBeamSpeed;
ConVar g_SSJGohanMinChargeTime;
ConVar g_SSJGohanMaxChargeTime;
ConVar g_SSJGohanParentPlayerWithBeam;

float g_fChargeTime[MAXPLAYERS + 1];
float g_fChargeAmount[MAXPLAYERS + 1];
int g_iTrail;
int g_iExplosion;
int g_iHeroIndex;
int g_iBeam[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iBeamHead[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
bool g_bFiringBeam[MAXPLAYERS + 1];
bool g_bCharging[MAXPLAYERS + 1];
Handle g_hTimerCharge[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle g_hHudCharge;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Super Sayian Gohan",
	author = PLUGIN_AUTHOR,
	description = "Super Sayian Gohan hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/ssjgohan.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_SSJGohanLevel = CreateConVar("superheromod_ssjgohan_level", "9");
	g_SSJGohanDamageMultiplier = CreateConVar("superheromod_ssjgohan_damage_multiplier", "50", "Amount of times charge time damage (If charged 2 seconds, then damage will be 2 * this convar)");
	g_SSJGohanRadiusMultiplier = CreateConVar("superheromod_ssjgohan_explosion_radius_multiplier", "90", "Amount of radius of the kamehameha wave (Charge time * this convar value)");
	g_SSJGohanCooldown = CreateConVar("superheromod_ssjgohan_cooldown", "30", "Seconds until next available kamehameha");
	g_SSJGohanBeamSpeed = CreateConVar("superheromod_ssjgohan_speed", "1500", "Speed of the kamehameha");
	g_SSJGohanMinChargeTime = CreateConVar("superheromod_ssjgohan_min_charge_time", "2", "Min amount of time in seconds you can charge the kamehameha");
	g_SSJGohanMaxChargeTime = CreateConVar("superheromod_ssjgohan_max_charge_time", "8", "Max amount of time in seconds you can charge the kamehameha");
	g_SSJGohanParentPlayerWithBeam = CreateConVar("superheromod_ssjgohan_parent_player_with_beam", "1", "Should the player fly with the beam if only the player gets hit and not world?");
	
	AutoExecConfig(true, "ssjgohan", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Super Saiyan Gohan", g_SSJGohanLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Guided Kamehameha", "Hold +POWER key down to charge, release to fire your Kamehameha!");
	SuperHero_SetHeroBind(g_iHeroIndex);
	
	g_hHudCharge = CreateHudSynchronizer();
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	g_bFiringBeam[client] = false;
	g_bCharging[client] = false;
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
			
			if(g_bFiringBeam[client] || g_bCharging[client])
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
					SetHudTextParams(0.38, 0.60, 3.0, 255, 255, 0, 255);
					ShowHudText(client, -1, "%t", "Equip Knife");
					return;
				}
			}

			EmitSoundToAllAny(KAMEHAME_SOUND, client);
			g_fChargeTime[client] = 0.0;
			g_bCharging[client] = true;
			g_hTimerCharge[client] = CreateTimer(BEAM_REFRESH_RATE, Timer_Charge, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		case SH_KEYUP:
		{
			if(g_fChargeTime[client] >= g_SSJGohanMinChargeTime.FloatValue && g_bCharging[client] && !g_bFiringBeam[client])
			{
				g_fChargeAmount[client] = g_fChargeTime[client];
				Kamehameha(client);
			}
			else
			{
				g_bCharging[client] = false;
				g_fChargeTime[client] = 0.0;
				StopSoundAny(client, SNDCHAN_AUTO, KAMEHAME_SOUND);
			}
		}
	}
}

public Action Timer_Charge(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{
		g_bFiringBeam[client] = false;
		g_bCharging[client] = false;
		g_hTimerCharge[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(!g_bCharging[client])
	{
		g_hTimerCharge[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(g_bFiringBeam[client])
	{
		g_hTimerCharge[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(g_fChargeTime[client] >= g_SSJGohanMaxChargeTime.FloatValue)
	{
		g_fChargeAmount[client] = g_fChargeTime[client];
		Kamehameha(client);
		g_hTimerCharge[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	float percentage = (g_fChargeTime[client] / g_SSJGohanMaxChargeTime.FloatValue) * 100.0;
	char strProgressBar[128];
	for(int i = 0; i < percentage / 5; i++)
			Format(strProgressBar, sizeof(strProgressBar), "%s█", strProgressBar);
	if(percentage > 25.0)
		SetHudTextParams(0.17, 0.04, 0.1, 0, 230, 230, 0, 0, 0.0, 0.0, 0.0);
	else
		SetHudTextParams(0.17, 0.04, 0.1, 255, 0, 0, 0, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hHudCharge, "%.0f%%\n%s", percentage, strProgressBar);
	
	g_fChargeTime[client] += 0.1;
	return Plugin_Continue;
}

public void Kamehameha(int client)
{
	SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_SSJGohanCooldown.FloatValue);
	g_bCharging[client] = false;
	g_bFiringBeam[client] = true;
	float pos[3];
	GetClientEyePosition(client, pos);
	StopSoundAny(client, SNDCHAN_AUTO, KAMEHAME_SOUND);
	EmitAmbientSoundAny(HA_SOUND, pos, client);
	CreateKameBeam(client);
}

stock void CreateKameBeam(int client)
{
	float vecView[3], vecFwd[3], vecPos[3];

	GetClientEyeAngles(client, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(client, vecPos);

	vecPos[0] += vecFwd[0] * 50.0;
	vecPos[1] += vecFwd[1] * 50.0;
	vecPos[2] += vecFwd[2] * 50.0;
	
	int prop = CreateEntityByName("prop_physics_override");
	g_iBeam[client] = EntIndexToEntRef(prop);
	DispatchKeyValue(prop, "targetname", "kamehameha"); 
	DispatchKeyValue(prop, "spawnflags", "4"); 
	DispatchKeyValue(prop, "model", "models/weapons/w_ied_dropped.mdl");
	DispatchSpawn(prop);
	ActivateEntity(prop);
	TeleportEntity(prop, vecPos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(prop, Prop_Data, "m_hOwnerEntity", client);
	SetEntProp(prop, Prop_Send, "m_fEffects", 32); //EF_NODRAW
	int ent = CreateEntityByName("env_sprite_oriented");
	g_iBeamHead[client] = EntIndexToEntRef(ent);
	DispatchKeyValue(ent, "spawnflags", "1");
	float fscale = g_fChargeAmount[client] * 0.3;
	char scale[32];
	Format(scale, sizeof(scale), "%f", fscale);
	DispatchKeyValue(ent, "scale", scale); 
	DispatchKeyValue(ent, "model", BEAM_HEAD); 
	DispatchSpawn(ent);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	TeleportEntity(ent, vecPos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", prop);
	
	g_hTimerCharge[client] = CreateTimer(0.1, Timer_Beam, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Beam(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if(IsValidClient(client))
	{
		int entity = EntRefToEntIndex(g_iBeam[client]);
		if(entity == INVALID_ENT_REFERENCE)
		{
			g_hTimerCharge[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		
		if(!IsPlayerAlive(client))
		{
			AcceptEntityInput(entity, "Kill");
			g_iBeam[client] = INVALID_ENT_REFERENCE;
			g_iBeamHead[client] = INVALID_ENT_REFERENCE;
			g_hTimerCharge[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}

		float entityPos[3], aimPos[3];
	
		float eyeAngles[3], eyePos[3];
		GetClientEyeAngles(client, eyeAngles);
		GetClientEyePosition(client, eyePos);
		Handle trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
		if(TR_DidHit(trace))
			TR_GetEndPosition(aimPos, trace);
		CloseHandle(trace);
		
		float entityVel[3];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
		float distance = GetVectorDistance(aimPos, entityPos);
		float time = distance / g_SSJGohanBeamSpeed.FloatValue;

		entityVel[0] = (aimPos[0] - entityPos[0]) / time;
		entityVel[1] = (aimPos[1] - entityPos[1]) / time;
		entityVel[2] = (aimPos[2] - entityPos[2]) / time;
		
		TeleportEntity(entity, NULL_VECTOR, view_as<float>({0.0,0.0,0.0}), entityVel);
		int color[4] =  { 0, 230, 230, 200 };
		
		float scale = g_fChargeAmount[client] * 6.0;
		TE_SetupBeamFollow(entity, g_iTrail, g_iTrail, 3.0, scale, scale+0.1, 0, color);
		TE_SendToAll();
		
		float vecMins[3], vecMaxs[3];
		vecMins[0] = -50.0;
		vecMins[1] = -50.0;
		vecMins[2] = -50.0;
		
		vecMaxs[0] = 50.0;
		vecMaxs[1] = 50.0;
		vecMaxs[2] = 50.0;
		entityPos[2] += 40.0;
		Handle ray = TR_TraceHullFilterEx(entityPos, entityPos, vecMins, vecMaxs, MASK_ALL, TraceFilterWorldPlayers, client);
		if(TR_DidHit(ray))
		{
			if(g_SSJGohanParentPlayerWithBeam.BoolValue)
			{
				int playerhit = TR_GetEntityIndex(ray);
				if(IsValidClient(playerhit) && GetClientTeam(playerhit) != GetClientTeam(client))
				{
					//Make the player fly with the beam, fuckin epic
					int sprite = EntRefToEntIndex(g_iBeamHead[client]);
					if(!IsValidClient(GetEntPropEnt(sprite, Prop_Data, "m_hMoveChild")))
					{
						SetEntityMoveType(playerhit, MOVETYPE_NONE);
						SetVariantString("!activator");
						AcceptEntityInput(playerhit, "SetParent", sprite);
					}
					
					StripWeapons(playerhit, false);
				}
				else
				{
					EndKameBeam(client, entity);
					g_hTimerCharge[client] = INVALID_HANDLE;
					return Plugin_Stop;
				}
			}
			else
			{
				EndKameBeam(client, entity);
				g_hTimerCharge[client] = INVALID_HANDLE;
				return Plugin_Stop;
			}
		}
	}
	else
	{
		int entity = EntRefToEntIndex(g_iBeam[client]);
		if(entity != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(entity, "Kill");
			g_iBeam[client] = INVALID_ENT_REFERENCE;
			g_iBeamHead[client] = INVALID_ENT_REFERENCE;
			g_hTimerCharge[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
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
	AcceptEntityInput(entity, "explode");
	AcceptEntityInput(entity, "Kill");
}

public void EndKameBeam(int client, int entity)
{
	float entityPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
	int sprite = EntRefToEntIndex(g_iBeamHead[client]);
	if(sprite != INVALID_ENT_REFERENCE)
	{
		int child = GetEntPropEnt(sprite, Prop_Data, "m_hMoveChild");
		if(child > 0)
		{
			SetEntityMoveType(child, MOVETYPE_WALK);
			AcceptEntityInput(child, "ClearParent");
			TeleportEntity(child, entityPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	//TE_SetupMuzzleFlash(entityPos, NULL_VECTOR, 20.0, 1);
	float scale = g_fChargeAmount[client] * 0.4;
	int chargeAmount = RoundToNearest(g_fChargeAmount[client]);
	CS_CreateExplosion(client, g_SSJGohanDamageMultiplier.IntValue * chargeAmount, g_SSJGohanRadiusMultiplier.IntValue * chargeAmount, entityPos);
	TE_SetupGlowSprite(entityPos, g_iExplosion, 3.0, scale, 50);
	TE_SendToAll();
	AcceptEntityInput(entity, "Kill");
	g_iBeam[client] = INVALID_ENT_REFERENCE;
	g_iBeamHead[client] = INVALID_ENT_REFERENCE;
	g_bCharging[client] = false;
	g_bFiringBeam[client] = false;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("materials/superheromod/kamehamehahead.vmt");
	AddFileToDownloadsTable("materials/superheromod/kamehamehahead.vtf");
	AddFileToDownloadsTable("materials/superheromod/kamehamehaexplosion.vmt");
	AddFileToDownloadsTable("materials/superheromod/kamehamehaexplosion.vtf");
	
	AddFileToDownloadsTable("sound/superheromod/beamhead.mp3");
	AddFileToDownloadsTable("sound/superheromod/gohan_ha.mp3");
	AddFileToDownloadsTable("sound/superheromod/gohan_kamehame.mp3");
	
	PrecacheSoundAny(BEAM_SOUND, true);
	PrecacheSoundAny(HA_SOUND, true);
	PrecacheSoundAny(KAMEHAME_SOUND, true);
	
	g_iTrail = PrecacheModel(BEAM_TRAIL);
	PrecacheModel(BEAM_HEAD);
	g_iExplosion = PrecacheModel(BEAM_EXPLOSION);
	PrecacheModel("models/weapons/w_ied_dropped.mdl");
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity == 0 && entityhit != entity)
		return true;
	
	return false;
}

public bool TraceFilterWorldPlayers(int entityhit, int mask, any entity)
{
	if(entityhit > -1 && entityhit <= MAXPLAYERS && entityhit != entity)
	{
		return true;
	}
	
	return false;
}
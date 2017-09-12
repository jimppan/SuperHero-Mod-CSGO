#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define PUSH_SOUND "superheromod/push.mp3"

EngineVersion g_Game;

ConVar g_YodaLevel;
ConVar g_YodaCooldown;
ConVar g_YodaRadius;
ConVar g_YodaPower;
ConVar g_YodaUpVelocity;
ConVar g_YodaDamage;

int g_iHeroIndex;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Yoda",
	author = PLUGIN_AUTHOR,
	description = "Yoda hero",
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
	
	g_YodaLevel = CreateConVar("superheromo_yoda_level", "5");
	g_YodaCooldown = CreateConVar("superheromo_yoda_cooldown", "10", "Amount of seconds yodas ability should be on cooldown");
	g_YodaRadius = CreateConVar("superheromo_yoda_radius", "400", "Amount of radius the push should cover around the player");
	g_YodaPower = CreateConVar("superheromo_yoda_power", "10", "Amount of power the push should have");
	g_YodaUpVelocity = CreateConVar("superheromo_yoda_up_velocity", "50", "Amount of up velocity when pushed");
	g_YodaDamage = CreateConVar("superheromo_yoda_damage", "10", "Amount of damage push deals");
	
	AutoExecConfig(true, "yoda", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Yoda", g_YodaLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Force Push", "Push enemies away with the power of the force");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_YodaLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
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

			if(SuperHero_IsPlayerHeroInCooldown(client, g_iHeroIndex))
				return;
			
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_YodaCooldown.FloatValue);
			ForcePush(client);
		}
	}
}

public void ForcePush(int client)
{
	float clientPos[3], enemyPos[3], pushVel[3];
	GetClientAbsOrigin(client, clientPos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
			
		if(GetClientTeam(i) == GetClientTeam(client))
			continue;
		
		GetClientAbsOrigin(i, enemyPos);
		float distance = GetVectorDistance(enemyPos, clientPos);
		//Avoid dividing by 0
		distance = (distance > 0.0) ? distance : 1.0;
		
		if(distance > g_YodaRadius.FloatValue)
			continue;
		
		SubtractVectors(clientPos, enemyPos, pushVel);
		
		pushVel[0] = -pushVel[0];
		pushVel[1] = -pushVel[1];
		pushVel[2] = g_YodaUpVelocity.FloatValue;

		ScaleVector(pushVel, g_YodaPower.FloatValue);
		TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, pushVel);
		EmitSoundToAllAny(PUSH_SOUND, i);
		SDKHooks_TakeDamage(i, client, client, g_YodaDamage.FloatValue, DMG_PARALYZE);
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/push.mp3");
	PrecacheSoundAny(PUSH_SOUND, true);
}
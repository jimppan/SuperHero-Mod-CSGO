#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define FREEZE_SOUND "superheromod/freeze.mp3"

EngineVersion g_Game;

ConVar g_FreezeLevel;
ConVar g_FreezeCooldown;
ConVar g_FreezeFreezeTime;

int g_iHeroIndex;
int g_iFrozenTeam = 0;
bool g_bHasFreeze[MAXPLAYERS + 1];
bool g_bGroundFrozen = false;
Handle g_FreezeTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Mr. Freeze",
	author = PLUGIN_AUTHOR,
	description = "Mr. Freeze hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/mrfreeze.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	HookEvent("round_end", Event_RoundStart);
	HookEvent("round_start", Event_RoundEnd);
	
	g_FreezeLevel = CreateConVar("superheromod_mrfreeze_level", "6");
	g_FreezeCooldown = CreateConVar("superheromod_mrfreeze_cooldown", "45", "Amount of seconds until Mr. Freeze can cover the ground in ice again");
	g_FreezeFreezeTime = CreateConVar("superheromod_mrfreeze_freeze_time", "16", "Amount of seconds ground should be covered in ice");
	
	AutoExecConfig(true, "mrfreeze", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Mr. Freeze", g_FreezeLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Freeze The Ground", "Press +POWER key to freeze the ground and make everyone slide\n around like on ice! Also be immune to it");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_FreezeLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasFreeze[client] = (mode ? true : false);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	KillFreezeTimer();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillFreezeTimer();
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
			
			if(g_bGroundFrozen)
			{
				PrintToChat(client, "t", "Ground Already Frozen", SH_PREFIX, "[\x0CMr. Freeze\x09]");
				SuperHero_PlayDenySound(client);
				return;
			}
			
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_FreezeCooldown.FloatValue);
			EmitSoundToAllAny(FREEZE_SOUND);
			g_bGroundFrozen = true;
			g_FreezeTimer = CreateTimer(g_FreezeFreezeTime.FloatValue, Timer_Freeze);
			g_iFrozenTeam = GetClientTeam(client);
			for (int i = 0; i <= MaxClients; i++)
				if(IsValidClient(i))
					SDKHook(i, SDKHook_PreThinkPost, OnPreThinkPost);
		}
	}
}

public Action Timer_Freeze(Handle timer, any data)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKUnhook(i, SDKHook_PreThinkPost, OnPreThinkPost);
			if(IsPlayerAlive(i))
				SuperHero_ResetMaxSpeed(i);
		}
	}
	g_iFrozenTeam = 0;
	g_bGroundFrozen = false;
	g_FreezeTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action OnPreThinkPost(int client)
{
	//Safety stuff
	if(!g_bGroundFrozen)
	{
		SDKUnhook(client, SDKHook_PreThinkPost, OnPreThinkPost);
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(g_bHasFreeze[client])
		return Plugin_Continue;
		
	if(GetClientTeam(client) != g_iFrozenTeam)
		return Plugin_Continue;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.4);
	else
		SuperHero_ResetMaxSpeed(client);
	
	return Plugin_Continue;
}

stock void KillFreezeTimer()
{
	if(g_FreezeTimer != INVALID_HANDLE)
		KillTimer(g_FreezeTimer);
	g_FreezeTimer = INVALID_HANDLE;
	g_bGroundFrozen = false;
	g_iFrozenTeam = 0;
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SDKUnhook(i, SDKHook_PreThinkPost, OnPreThinkPost);
			if(IsPlayerAlive(i))
				SuperHero_ResetMaxSpeed(i);
		}
	}
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/freeze.mp3");
	PrecacheSoundAny(FREEZE_SOUND, true);
	
	g_iFrozenTeam = 0;
	g_bGroundFrozen = false;
	g_FreezeTimer = INVALID_HANDLE;
}
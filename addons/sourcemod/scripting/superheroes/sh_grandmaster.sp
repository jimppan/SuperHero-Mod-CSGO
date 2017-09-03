#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define REVIVE_SOUND "superheromod/revive.mp3"

#define FFADE_OUT 0x0001        // Fade out

EngineVersion g_Game;

ConVar g_GrandmasterLevel;
ConVar g_GrandmasterCooldown;

int g_iHeroIndex;
bool g_bHasGrandmaster[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Grandmaster",
	author = PLUGIN_AUTHOR,
	description = "Grandmaster hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/grandmaster.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_GrandmasterLevel = CreateConVar("superheromod_grandmaster_level", "9");
	g_GrandmasterCooldown = CreateConVar("superheromod_grandmaster_cooldown", "600", "Amount of second for grandmaster cooldown");
	AutoExecConfig(true, "grandmaster", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Grandmaster", g_GrandmasterLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Revive Dead", "Revive a dead teammate after they die");
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasGrandmaster[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	if(IsGameLive())
		SuperHero_ForceSetPlayerHeroCooldown(client, g_iHeroIndex, true);
	else
		SuperHero_ForceSetPlayerHeroCooldown(client, g_iHeroIndex, false);
	
}

public void SuperHero_OnPlayerDeath(int victim, int attacker, bool headshot)
{
	if(!IsGameLive())
		return;
		
	int team = GetClientTeam(victim);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		
		if(i != victim && g_bHasGrandmaster[i] && !SuperHero_IsPlayerHeroInCooldown(i, g_iHeroIndex) && team == GetClientTeam(i))
		{
			if(g_GrandmasterCooldown.FloatValue > 0.0)
				SuperHero_SetPlayerHeroCooldown(i, g_iHeroIndex, g_GrandmasterCooldown.FloatValue);
			DataPack pack = CreateDataPack();
			CreateDataTimer(1.0, Timer_Delay, pack);
			pack.WriteCell(GetClientUserId(victim));
			pack.WriteCell(GetClientUserId(i));
			break;
		}
	}
}

public Action Timer_Delay(Handle timer, DataPack pack)
{
	pack.Reset();
	int victim = GetClientOfUserId(pack.ReadCell());
	int grandmaster = GetClientOfUserId(pack.ReadCell());
	
	if(!IsValidClient(victim) || !IsValidClient(grandmaster))
		return Plugin_Stop;
	
	if(IsPlayerAlive(victim) || !IsPlayerAlive(grandmaster))
		return Plugin_Stop;
		
	if(GetClientTeam(victim) != GetClientTeam(grandmaster))
		return Plugin_Stop;
	
	EmitSoundToClientAny(victim, REVIVE_SOUND);
	PrintToChatAll("%t", "Revive", SH_PREFIX, "[\x0CGrandmaster\x09]", grandmaster, victim);
	
	CS_RespawnPlayer(victim);
	ScreenEffect(victim, 100, 500, FFADE_OUT, 255, 255, 255, 250);
	
	return Plugin_Stop;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/revive.mp3");
	PrecacheSoundAny(REVIVE_SOUND, true);
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasGrandmaster[client] = false;
	return true;
}

stock void ScreenEffect(int client, int duration, int hold_time, int flag, int red, int green, int blue, int alpha)
{
	Handle hFade = INVALID_HANDLE;
	
	if(client)
	{
	   hFade = StartMessageOne("Fade", client);
	}
	else
	{
	   hFade = StartMessageAll("Fade");
	}
	
	if(hFade != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			int clr[4];
			clr[0]=red;
			clr[1]=green;
			clr[2]=blue;
			clr[3]=alpha;
			PbSetInt(hFade, "duration", duration);
			PbSetInt(hFade, "hold_time", hold_time);
			PbSetInt(hFade, "flags", flag);
			PbSetColor(hFade, "clr", clr);
		}
		EndMessage();
	}
}


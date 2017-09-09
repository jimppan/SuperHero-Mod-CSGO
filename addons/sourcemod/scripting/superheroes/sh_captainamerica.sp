#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

#define FFADE_IN 0x0002        // Fade in
#define FFADE_MODULATE 0x0004  // Modulate
EngineVersion g_Game;

ConVar g_CaptainamericaLevel;
ConVar g_CaptainamericaGodTime;
ConVar g_CaptainamericaPercentPerLevel;

int g_iHeroIndex;
float g_fMaxLevelFactor;
bool g_bHasCaptainAmerica[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Captain America",
	author = PLUGIN_AUTHOR,
	description = "Captain America hero",
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
	
	g_CaptainamericaLevel = CreateConVar("superheromod_captainamerica_level", "0");
	g_CaptainamericaGodTime = CreateConVar("superheromod_captainamerica_god_time", "1", "Amount of time in seconds hero should be in god mode");
	g_CaptainamericaPercentPerLevel = CreateConVar("superheromod_captainamerica_percent_per_level", "0.02", "Percentage that factors into godmode randomness");
	AutoExecConfig(true, "captainamerica", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Captain America", g_CaptainamericaLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Super Shield", "Random invincibility, the higher level, the better chance");
	
	CreateTimer(1.0, Timer_Invincibility,_, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_CaptainamericaLevel.IntValue);
	g_fMaxLevelFactor = (10.0 / SuperHero_GetLevelCount()) * 100.0;
}

public Action Timer_Invincibility(Handle timer, any data)
{
	int heroLevel;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		
		if(g_bHasCaptainAmerica[i] && !SuperHero_IsGodMode(i))
		{
			heroLevel = RoundToNearest(SuperHero_GetPlayerLevel(i) * g_CaptainamericaPercentPerLevel.FloatValue * g_fMaxLevelFactor);
			
			if(heroLevel >= GetRandomInt(0, 100))
			{
				SuperHero_SetGodMode(i, g_CaptainamericaGodTime.FloatValue);
				ScreenEffect(i, 100 * g_CaptainamericaGodTime.IntValue, g_CaptainamericaGodTime.IntValue * 350, FFADE_IN | FFADE_MODULATE, 0, 0, 255, 50);
			}
		}
	}
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasCaptainAmerica[client] = mode ? true : false;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bHasCaptainAmerica[client] = false;
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
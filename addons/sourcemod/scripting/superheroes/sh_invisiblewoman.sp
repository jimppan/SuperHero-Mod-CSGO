#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define CLOAK_SOUND "superheromod/cloak.mp3"
#define UNCLOAK_SOUND "superheromod/uncloak.mp3"

EngineVersion g_Game;

ConVar g_InvisiblewomanLevel;
ConVar g_InvisiblewomanCooldown;
ConVar g_InvisiblewomanAlpha;
ConVar g_InvisiblewomanTime;

int g_iHeroIndex;
bool g_bInvisible[MAXPLAYERS + 1];
Handle g_HudSync;
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Invisible Woman",
	author = PLUGIN_AUTHOR,
	description = "Invisible Woman hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/invisiblewoman.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_InvisiblewomanLevel = CreateConVar("superheromod_invisiblewoman_level", "6");
	g_InvisiblewomanCooldown = CreateConVar("superheromod_invisiblewoman_cooldown", "30", "Amount of seconds until invisibility can be used again");
	g_InvisiblewomanAlpha = CreateConVar("superheromod_invisiblewoman_alpha", "0", "Amount of visibility 0-255 (0 for invisible, 255 for completely visible)");
	g_InvisiblewomanTime = CreateConVar("superheromod_invisiblewoman_time", "5", "Amount of seconds invisible woman is invisible");
	
	AutoExecConfig(true, "invisiblewoman", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Invisible Woman", g_InvisiblewomanLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Invisibility", "Press +POWER key to become invisible for a short period of time");
	SuperHero_SetHeroBind(g_iHeroIndex);
	
	g_HudSync = CreateHudSynchronizer();
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_InvisiblewomanLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	EndInvisibility(client);
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
			
			if(g_bInvisible[client])
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
			if (SuperHero_IsPlayerHeroInCooldown(client, g_iHeroIndex)) 
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
			g_bInvisible[client] = true;
			
			int color[4];
			GetEntityRenderColor(client, color[0], color[1], color[2], color[3]);

			SetEntityRenderMode(client, RENDER_TRANSALPHA);
			SetEntityRenderColor(client, color[0], color[1], color[2], g_InvisiblewomanAlpha.IntValue);
			
			SetHudTextParams(0.43, 0.8, 2.0, 0, 255, 0, 255);
			ShowSyncHudText(client, g_HudSync, "%t", "Invisible On");
			
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_InvisiblewomanCooldown.FloatValue);
			EmitSoundToAllAny(CLOAK_SOUND, client);
			CreateTimer(g_InvisiblewomanTime.FloatValue, Timer_Invis, GetClientUserId(client));
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		}
	}
}


public Action Timer_Invis(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
		
	EndInvisibility(client);
	
	return Plugin_Stop;
}

stock void EndInvisibility(int client)
{
	int color[4];
	GetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] == g_InvisiblewomanAlpha.IntValue && g_bInvisible[client])
	{
		SetHudTextParams(0.4, 0.8, 2.0, 0, 255, 0, 255);
		ShowSyncHudText(client, g_HudSync, "%t", "Invisible Off");
		
		SetEntityRenderColor(client, color[0], color[1], color[2], 255);
		EmitSoundToAllAny(UNCLOAK_SOUND, client);
	}
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	g_bInvisible[client] = false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public Action OnPostThinkPost(int client)
{
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/cloak.mp3");
	AddFileToDownloadsTable("sound/superheromod/uncloak.mp3");
	PrecacheSoundAny(CLOAK_SOUND, true);
	PrecacheSoundAny(UNCLOAK_SOUND, true);
	
	//Setting player alpha doesnt work without this in csgo
	SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
}
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

ConVar g_DraculaLevel;
ConVar g_DraculaPercentPerLevel;

int g_iHeroIndex;
bool g_bHasDracula[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Dracula",
	author = PLUGIN_AUTHOR,
	description = "Dracula hero",
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
	g_DraculaLevel = CreateConVar("superheromod_dracula_level", "0");
	g_DraculaPercentPerLevel = CreateConVar("superheromod_dracula_percent_per_level", "0.03");
	AutoExecConfig(true, "dracula", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Dracula", g_DraculaLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Vampiric Drain", "Gain HP by attacking players - More HP per level");
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_DraculaLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasDracula[client] = (mode ? true : false);
}

public void SuperHero_OnPlayerTakeDamagePost(int victim, int attacker, int damagetype, int weapon, int damagetaken, int armortaken)
{
	if(weapon < 1)
		return;

	if(!IsValidClient(attacker))
		return;

	//Remove nade health drain
	char szClassName[32];
	if(StrContains(szClassName, "nade") != -1 || StrContains(szClassName, "molotov") != -1 || StrContains(szClassName, "flash") != -1)
		return;
		
	if(g_bHasDracula[attacker])
		DrainHealth(attacker, float(damagetaken));
}

public void DrainHealth(int attacker, float damage)
{
	if(IsPlayerAlive(attacker))
	{
		int givehp = RoundToNearest(damage * g_DraculaPercentPerLevel.FloatValue * SuperHero_GetPlayerLevel(attacker));
		
		int maxhp = SuperHero_GetMaxHealth(attacker);
		
		if (GetEntProp(attacker, Prop_Data, "m_iHealth") < maxhp && givehp > 0)
		{
			int alpha = clamp((RoundToNearest(damage)), 20, 120);
			SuperHero_AddHealth(attacker, givehp);
			ScreenEffect(attacker, 100, 350, FFADE_IN | FFADE_MODULATE, 255, 0, 0, alpha);
		}
	}
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasDracula[client] = false;
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


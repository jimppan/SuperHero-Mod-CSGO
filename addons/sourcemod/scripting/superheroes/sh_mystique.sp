#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define MORPH_SOUND "superheromod/morph.mp3"

EngineVersion g_Game;

ConVar g_MystiqueLevel;

char g_szHeroName[SH_HERO_NAME_SIZE] = "Mystique";
int g_iHeroIndex;
bool g_bMorphed[MAXPLAYERS + 1];

Handle g_hHudSync;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Mystique",
	author = PLUGIN_AUTHOR,
	description = "Mystique hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/mystique.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_MystiqueLevel = CreateConVar("superheromod_mystique_level", "0");
	AutoExecConfig(true, "mystique", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Mystique", g_MystiqueLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Morph into enemy", "Press the +power key to shapeshift into the enemy");
	SuperHero_SetHeroBind(g_iHeroIndex);
	
	g_hHudSync = CreateHudSynchronizer();
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_MystiqueLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	if(mode == SH_HERO_DROP && g_bMorphed[client] && IsValidClient(client))
	{
		MystiqueUnmorph(client);
	}
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	g_bMorphed[client] = false;
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

			if(g_bMorphed[client])
				MystiqueUnmorph(client);
			else
				MystiqueMorph(client);
			
		}
	}
}

public void MystiqueMorph(int client)
{
	if (!IsPlayerAlive(client) || g_bMorphed[client]) 
		return;

	switch(GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, SH_DEFAULT_MODEL_CT);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, SH_DEFAULT_MODEL_T);
		}
	}

	g_bMorphed[client] = true;
	EmitSoundToClientAny(client, MORPH_SOUND);

	// Message
	SetHudTextParams(0.35, 0.60, 3.0, 255, 255, 0, 255);
	ShowSyncHudText(client, g_hHudSync, "%t", "Morphed", g_szHeroName);
}

public void MystiqueUnmorph(int client)
{
	if (!g_bMorphed[client] || !IsValidClient(client)) 
		return;

	char szModel[PLATFORM_MAX_PATH];
	int heroIndex = SuperHero_GetHighestPlayerModelLevel(client, szModel, sizeof(szModel));
	if(heroIndex < 0)
	{
		int team = GetClientTeam(client);
		if(team == CS_TEAM_T)
			Format(szModel, sizeof(szModel), SH_DEFAULT_MODEL_T);
		else if(team == CS_TEAM_CT)
			Format(szModel, sizeof(szModel), SH_DEFAULT_MODEL_CT);
	}

	SetEntityModel(client, szModel);

	g_bMorphed[client] = false;

	if (!IsPlayerAlive(client)) 
		return;

	EmitSoundToClientAny(client, MORPH_SOUND);

	// Message
	SetHudTextParams(0.40, 0.60, 3.0, 255, 255, 0, 255);
	ShowSyncHudText(client, g_hHudSync, "%t", "Unmorphed", g_szHeroName);
}


public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/morph.mp3");
	PrecacheSoundAny(MORPH_SOUND, true);
}
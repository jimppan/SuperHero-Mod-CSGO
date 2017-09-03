#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <dhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_AgentzeroLevel;

ConVar g_Spread;

int g_iHeroIndex;
int g_iHookID[MAXPLAYERS + 1];
bool g_bHasAgentZero[MAXPLAYERS + 1];
Handle g_hInaccuracy = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Agent Zero",
	author = PLUGIN_AUTHOR,
	description = "Agent Zero hero",
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
	
	g_AgentzeroLevel = CreateConVar("superheromod_agentzero_level", "5");
	g_Spread = FindConVar("weapon_accuracy_nospread");
	g_iHeroIndex = SuperHero_CreateHero("Agent Zero", g_AgentzeroLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "No Recoil", "Get no recoil when shooting");
	
	Handle hConf = LoadGameConfigFile("superheromod.games/agentzero.games");
	int InaccuracyOffset = GameConfGetOffset(hConf, "InaccuracyOffset");
	//DHOOK CWeaponCSBase::GetInaccuracy 460
	g_hInaccuracy = DHookCreate(InaccuracyOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, CWeaponCSBase_GetInaccuracy);
}

public MRESReturn CWeaponCSBase_GetInaccuracy(int pThis, Handle hReturn, Handle hParams)
{
	DHookSetReturn(hReturn, 0.0);
	return MRES_Supercede;
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	if(mode == SH_HERO_ADD)
	{
		SendConVarValue(client, g_Spread, "1");
		g_bHasAgentZero[client] = true;
		int activewep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(activewep != INVALID_ENT_REFERENCE)
			g_iHookID[client] = DHookEntity(g_hInaccuracy, false, activewep);
	}
	else if(mode == SH_HERO_DROP)
	{
		SendConVarValue(client, g_Spread, "0");
		g_bHasAgentZero[client] = false;
		int activewep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(activewep != INVALID_ENT_REFERENCE)
		{
			if(g_iHookID[client] > 0)
				DHookRemoveHookID(g_iHookID[client]);
		}
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bHasAgentZero[client] = false;
	return true;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnPlayerWeaponSwitchPost);
}

public void OnPlayerWeaponSwitchPost(int client, int weaponid)
{
	if(!g_bHasAgentZero[client])
		return;
		
	int lastwep = GetEntPropEnt(client, Prop_Send, "m_hLastWeapon");
	if(lastwep != INVALID_ENT_REFERENCE)
	{
		if(g_iHookID[client] > 0)
			DHookRemoveHookID(g_iHookID[client]);
	}
	
	g_iHookID[client] = DHookEntity(g_hInaccuracy, false, weaponid);
}
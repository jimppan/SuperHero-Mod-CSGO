#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required
#define NOCLIP_SOUND "superheromod/noclip.mp3"

EngineVersion g_Game;

ConVar g_ShadowcatLevel;
ConVar g_ShadowcatCooldown;
ConVar g_ShadowcatNoclipTime;
ConVar g_ShadowcatNoclipSpeed;

int g_iHeroIndex;
int g_iShadowcatTimer[MAXPLAYERS + 1];
bool g_bHasShadowcat[MAXPLAYERS + 1];
Handle g_hHudSync;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Shadowcat",
	author = PLUGIN_AUTHOR,
	description = "Shadowcat hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/shadowcat.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	g_ShadowcatLevel = CreateConVar("superheromod_shadowcat_level", "0");
	g_ShadowcatCooldown = CreateConVar("superheromod_shadowcat_noclip_cooldown", "30", "Amount of seconds before shadowcat can noclip again");
	g_ShadowcatNoclipTime = CreateConVar("superheromod_shadowcat_noclip_time", "6", "Amount of seconds shadowcat has noclip");
	g_ShadowcatNoclipSpeed = CreateConVar("superheromod_shadowcat_speed", "0.3", "Amount of speed shadowcat should have in noclip");
	AutoExecConfig(true, "shadowcat", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Shadowcat", g_ShadowcatLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Walk Through Walls", "Can walk through walls for a short time\nGET STUCK = AUTO SLAIN");
	SuperHero_SetHeroBind(g_iHeroIndex);
	
	g_hHudSync = CreateHudSynchronizer();
	
	CreateTimer(1.0, Timer_Noclip, _, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_ShadowcatLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	switch(mode)
	{
		case SH_HERO_ADD:
		{
			g_bHasShadowcat[client] = true;
			g_iShadowcatTimer[client] = -1;
		}
		case SH_HERO_DROP:
		{
			g_bHasShadowcat[client] = false;
			if(g_iShadowcatTimer[client] >= 0)
				ShadowCatEndNoclip(client);
		}
	}
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_ForceSetPlayerHeroCooldown(client, g_iHeroIndex, false);
	g_iShadowcatTimer[client] = -1;
	
	if(g_bHasShadowcat[client])
		ShadowCatEndNoclip(client);
}

public void SuperHero_OnPlayerDeath(int victim, int attacker, bool headshot)
{
	SuperHero_ForceSetPlayerHeroCooldown(victim, g_iHeroIndex, false);
	g_iShadowcatTimer[victim] = -1;
	
	if(g_bHasShadowcat[victim])
		ShadowCatEndNoclip(victim);
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
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
			if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
			{
				PrintToChat(client, "%t", "Already In Noclip", SH_PREFIX, "[\x0CShadowcat\x09]");
				SuperHero_PlayDenySound(client);
				return;
			}
			
			g_iShadowcatTimer[client] = g_ShadowcatNoclipTime.IntValue;
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			EmitSoundToClientAny(client, NOCLIP_SOUND);
			SuperHero_SetChangeWeaponSpeedBool(client, false);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_ShadowcatNoclipSpeed.FloatValue);
		}
	}
}

public Action Timer_Noclip(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || !IsPlayerAlive(i))
			continue;
		
		if(!g_bHasShadowcat[i])
			continue;
		if(g_iShadowcatTimer[i] > 0)
		{
			SetHudTextParams(0.35, 0.60, 1.0, 255, 255, 0, 255);
			ShowSyncHudText(i, g_hHudSync, "%t", "Noclip", g_iShadowcatTimer[i], (g_iShadowcatTimer[i] == 1 ? "" : "s"));
			
			g_iShadowcatTimer[i]--;
		}
		else if(g_iShadowcatTimer[i] == 0)
		{
			if(g_ShadowcatCooldown.FloatValue > 0.0)
				SuperHero_SetPlayerHeroCooldown(i, g_iHeroIndex, g_ShadowcatCooldown.FloatValue);
			
			g_iShadowcatTimer[i]--;
			ShadowCatEndNoclip(i);
			EmitSoundToClientAny(i, NOCLIP_SOUND);
		}
	}
}

public void ShadowCatEndNoclip(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return;
	g_iShadowcatTimer[client] = -1;
	
	if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
	{
		SuperHero_SetChangeWeaponSpeedBool(client, true);
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		float clientPos[3], vecMins[3], vecMaxs[3];
		GetClientAbsOrigin(client, clientPos);
		GetClientMins(client, vecMins);
		GetClientMaxs(client, vecMaxs);
		
		Handle ray = TR_TraceHullFilterEx(clientPos, clientPos, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceFilterOnlyWorld, client);
		if(TR_DidHit(ray))
			ForcePlayerSuicide(client);
		else
		{
			//Reset player velocity so he dont fly away
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 1.0 }) );
			SuperHero_ResetMaxSpeed(client);
		}
	}
	
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bHasShadowcat[client] = false;
	return true;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/noclip.mp3");
	PrecacheSoundAny(NOCLIP_SOUND, true);
}

public bool TraceFilterOnlyWorld(int entityhit, int mask, any entity)
{
	if(entityhit == 0 && entityhit != entity)
		return true;
	
	return false;
}
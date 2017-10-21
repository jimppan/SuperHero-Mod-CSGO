//http://dragonball.wikia.com/wiki/Yardrat

#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.03"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required
#define INSTANT_TRANSMISSION_SOUND "superheromod/instanttransmission.mp3"
EngineVersion g_Game;

ConVar g_YadratLevel;
ConVar g_YadratCooldown;
ConVar g_YadratTeleportTime;
ConVar g_TimeUntilCanBeUsed;

int g_iHeroIndex;
bool g_bInTransmission[MAXPLAYERS + 1];
bool g_bCanBeUsed = false;
float g_vecPreviousPos[MAXPLAYERS + 1][3];
float g_vecWorldMaxs[3];
public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Yadrat",
	author = PLUGIN_AUTHOR,
	description = "Yadrat hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/yadrat.phrases");
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	
	g_YadratLevel = CreateConVar("superheromod_yadrat_level", "7");
	g_YadratCooldown = CreateConVar("superheromod_yadrat_cooldown", "30", "Seconds until next instant transmission");
	g_YadratTeleportTime = CreateConVar("superheromod_yadrat_teleport_time", "3", "Seconds until arrival");
	g_TimeUntilCanBeUsed = CreateConVar("superheromod_time_until_can_be_used", "10", "Seconds until yadrat can be used from round start");
	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	
	AutoExecConfig(true, "yadrat", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Yadrat", g_YadratLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Instant Transmission", "Press +POWER key to teleport to your nearest target \n(If he is above level 0)");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public Action Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_TimeUntilCanBeUsed.BoolValue)
	{
		g_bCanBeUsed = true;
		return Plugin_Continue;
	}
	g_bCanBeUsed = false;
	CreateTimer(g_TimeUntilCanBeUsed.FloatValue, Timer_CanBeUsed, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CanBeUsed(Handle timer, any data)
{
	g_bCanBeUsed = true;
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_YadratLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	g_bInTransmission[client] = false;
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
			
			if(g_bInTransmission[client] || !g_bCanBeUsed)
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
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
					SetHudTextParams(0.35, 0.60, 3.0, 255, 255, 0, 255);
					ShowHudText(client, -1, "%t", "Equip Knife");
					return;
				}
			}
			g_bInTransmission[client] = true;

			g_vecWorldMaxs[2] += 200.0;
			//Appearently 433 milliseconds is 1 second in csgo hehehehehehe
			ScreenEffect(client, 300, 433 * g_YadratTeleportTime.IntValue, 0, 0, 0, 0, 255);
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_YadratCooldown.FloatValue);
			GetClientAbsOrigin(client, g_vecPreviousPos[client]);
			EmitAmbientSoundAny(INSTANT_TRANSMISSION_SOUND, g_vecPreviousPos[client], client);
			TeleportEntity(client, g_vecWorldMaxs, NULL_VECTOR, NULL_VECTOR);
			CreateTimer(g_YadratTeleportTime.FloatValue, Timer_Teleport, GetClientUserId(client));
		}
	}
}

//Check if player can teleport infront of any other players that has powers (A power level)
public Action Timer_Teleport(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || !g_bInTransmission[client])
		return Plugin_Stop;
	g_bInTransmission[client] = false;
	
	ArrayList players = new ArrayList(); //Make sure to get a random player and not the player that has been playing on the server for the longest time
	ArrayList validPlayers = new ArrayList();
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || i == client || GetClientTeam(client) == GetClientTeam(i))
			continue;
		
		if(SuperHero_GetPlayerLevel(i) <= 0) //Testing for bots
			continue;
		
		players.Push(i);
	}

	if(players.Length <= 0)
	{
		PrintToChat(client, "%t", "No Players", SH_PREFIX);
		EmitAmbientSoundAny(INSTANT_TRANSMISSION_SOUND, g_vecPreviousPos[client], client);
		TeleportEntity(client, g_vecPreviousPos[client], NULL_VECTOR, NULL_VECTOR);
		return Plugin_Stop;
	}

	float vMins[3], vMaxs[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	float vecView[3], vecFwd[3], vecPos[3];
	for (int i = 0; i < players.Length; i++)
	{
		GetClientEyeAngles(players.Get(i), vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientAbsOrigin(players.Get(i), vecPos);

		vecPos[0] += vecFwd[0] * 100.0;
		vecPos[1] += vecFwd[1] * 100.0;
		Handle ray = TR_TraceHullFilterEx(vecPos, vecPos, vMins, vMaxs, MASK_ALL, TraceFilterWorldPlayers, client);
		if(TR_DidHit(ray))
			continue;
		validPlayers.Push(players.Get(i));
	}

	delete players;
	if(validPlayers.Length <= 0)
	{
		PrintToChat(client, "%t", "No Valid Players", SH_PREFIX);
		EmitAmbientSoundAny(INSTANT_TRANSMISSION_SOUND, g_vecPreviousPos[client], client);
		TeleportEntity(client, g_vecPreviousPos[client], NULL_VECTOR, NULL_VECTOR);
		return Plugin_Stop;
	}

	int randomPlayer = validPlayers.Get(GetRandomInt(0, validPlayers.Length - 1));
	GetClientEyeAngles(randomPlayer, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientAbsOrigin(randomPlayer, vecPos);

	vecPos[0] += vecFwd[0] * 100.0;
	vecPos[1] += vecFwd[1] * 100.0;
	
	EmitAmbientSoundAny(INSTANT_TRANSMISSION_SOUND, vecPos, client);
	TeleportEntity(client, vecPos, NULL_VECTOR, NULL_VECTOR); //Teleport client infront of enemy
	delete validPlayers;
	
	return Plugin_Stop;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/instanttransmission.mp3");
	PrecacheSoundAny(INSTANT_TRANSMISSION_SOUND, true);	
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", g_vecWorldMaxs);
	g_vecWorldMaxs[2] += 200.0;
}

public bool TraceFilterWorldPlayers(int entityhit, int mask, any entity)
{
	if(entityhit > -1 && entityhit <= MAXPLAYERS && entityhit != entity)
		return true;
	
	return false;
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
#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define HOOK_REFRESH_TIME 0.1
#define MODEL_BEAM "materials/sprites/purplelaser1.vmt"
#define HOOK_SOUND "superheromod/getoverhere.mp3"
#define HEADSHOT_SOUND "superheromod/headshot.mp3"
#define HIT_SOUND "superheromod/hit.mp3"
#define MODEL_BEAM "materials/sprites/purplelaser1.vmt"

EngineVersion g_Game;

ConVar g_ScorpionLevel;
ConVar g_ScorpionMaxHooks;
ConVar g_ScorpionReelSpeed;
ConVar g_ScorpionSpearDamage;
ConVar g_ScorpionStunTime;
ConVar g_ScorpionHookCooldown;

int g_iSprite;
int g_iHeroIndex;
int g_iHooked[MAXPLAYERS + 1];
int g_iHook[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHookProp[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHooksLeft[MAXPLAYERS + 1];
bool g_bHooked[MAXPLAYERS + 1];
Handle g_hTimerHook[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Scorpion",
	author = PLUGIN_AUTHOR,
	description = "Scorpion hero",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("superheromod/scorpion.phrases");
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_ScorpionLevel = CreateConVar("superheromod_scorpion_level", "9");
	g_ScorpionMaxHooks = CreateConVar("superheromod_scorpion_max_hooks", "30", "Max amount of spears/hooks allowed, -1 is unlimited");
	g_ScorpionReelSpeed = CreateConVar("superheromod_scorpion_reel_speed", "1000", "How fast hook line reels in speared users");
	g_ScorpionSpearDamage = CreateConVar("superheromod_scorpion_spear_damage", "20", "Amount of damage done when user is speared");
	g_ScorpionStunTime = CreateConVar("superheromod_scorpion_stun_time", "2", "Seconds to stun user when speared");
	g_ScorpionHookCooldown = CreateConVar("superheromod_scorpion_hook_cooldown", "5", "Seconds the hook should be on cooldown after firing");
	
	AutoExecConfig(true, "scorpion", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Scorpion", g_ScorpionLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Get Over Here!", "Hold +POWER key to harpoon and drag opponents to you");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_ScorpionLevel.IntValue);
}


public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
	
	if(g_bHooked[client])
		ScorpionHookOff(client);
	
	g_iHooksLeft[client] = g_ScorpionMaxHooks.IntValue;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	g_iHooksLeft[client] = g_ScorpionMaxHooks.IntValue;
	
	SuperHero_EndPlayerHeroCooldown(client, g_iHeroIndex);
	
	if(g_bHooked[client])
		ScorpionHookOff(client);
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
			
			if(g_iHooksLeft[client] == 0)
			{
				SetHudTextParams(0.43, 0.60, 3.0, 255, 255, 0, 255);
				ShowHudText(client, -1, "%t", "No Hooks Left");
				SuperHero_PlayDenySound(client);
				return;
			}
			
			if(g_iHooksLeft[client] > 0)
				g_iHooksLeft[client]--;
			
			if(g_bHooked[client])
				return;
			
			if (SuperHero_IsPlayerHeroInCooldown(client, g_iHeroIndex)) 
			{
				SuperHero_PlayDenySound(client);
				return;
			}
			
			ScorpionHookOn(client);
		}
		case SH_KEYUP:
		{
			if(g_bHooked[client])
				ScorpionHookOff(client);
		}
	}
}

stock void ScorpionHookOn(int client)
{
	int target = GetClientAimTarget(client, true);
	if (IsValidClient(target))
	{
		if(!IsPlayerAlive(target))
			return;
			
		if(GetClientTeam(client) == GetClientTeam(target))
			return;
		
		if(g_ScorpionHookCooldown.FloatValue > 0.0)
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_ScorpionHookCooldown.FloatValue);
		
		g_iHooksLeft[client]--;
		EmitSoundToClientAny(target, HIT_SOUND);
		float pos[3], victimPos[3];
		GetClientEyePosition(target, victimPos);
		GetClientEyePosition(client, pos);
		SDKHooks_TakeDamage(target, client, client, g_ScorpionSpearDamage.FloatValue);
		float maxspeed = 1.0;
		SuperHero_GetMaxSpeed(target, view_as<int>(CSGOWeaponID_NONE), maxspeed);
		SuperHero_SetStun(target, g_ScorpionStunTime.FloatValue, maxspeed);
		
		EmitAmbientSoundAny(HOOK_SOUND, pos,_,_,_,6.0);
		EmitSoundToClientAny(target, HOOK_SOUND);
		CreateHookBeam(client, target);
		g_iHooked[client] = GetClientUserId(target);
		g_bHooked[client] = true;
		g_hTimerHook[client] = CreateTimer(HOOK_REFRESH_TIME, Timer_Hook, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if(g_ScorpionHookCooldown.FloatValue > 0.0)
			SuperHero_SetPlayerHeroCooldown(client, g_iHeroIndex, g_ScorpionHookCooldown.FloatValue);
			
		g_iHooksLeft[client]--;
		CreateEmptyHook(client);
		g_bHooked[client] = true;
	}
}

public void OnGameFrame()
{
	//This is to make the player run smoothly off the ground, csgo make u stick to the ground unless u get high enough force of the ground
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			int victim = GetClientOfUserId(g_iHooked[i]);
			if (IsValidClient(victim))
				SetEntPropEnt(victim, Prop_Data, "m_hGroundEntity", -1);
		}
	}
}

public Action Timer_Hook(Handle timer, any data)
{
	// Drags player to you
	int hooker = GetClientOfUserId(data);
	int victim = GetClientOfUserId(g_iHooked[hooker]);

	if (!IsValidClient(victim) || !IsPlayerAlive(victim) || !IsValidClient(hooker) || !IsPlayerAlive(hooker))
	{
		ScorpionHookOff(hooker);
		g_hTimerHook[hooker] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	float victimVel[3];
	float hookerPos[3], victimPos[3], eyePos[3];
	
	GetClientAbsOrigin(victim, victimPos);
	GetClientAbsOrigin(hooker, hookerPos);
	GetClientEyePosition(victim, eyePos);
	eyePos[2] -= 40.0;
	int color[4] =  { 255, 0, 0, 255 };
	
	float x = GetRandomFloat(-1.0, 1.0);
	
	float dir[3];
	dir[0] = x;
	dir[1] = x;
	dir[2] = x;
	if(!SuperHero_IsGodMode(victim))
	{
		TE_SetupBloodSprite(eyePos, dir, color, 500, g_iSprite, g_iSprite);
		TE_SendToAll();
	}
	
	float distance = GetVectorDistance(hookerPos, victimPos);

	if ( distance > 5 ) 
	{
		float fl_Time = distance / g_ScorpionReelSpeed.FloatValue;

		victimVel[0] = (hookerPos[0] - victimPos[0]) / fl_Time;
		victimVel[1] = (hookerPos[1] - victimPos[1]) / fl_Time;
		victimVel[2] = (hookerPos[2] - victimPos[2]) / fl_Time;
	}
	else 
	{
		victimVel[0] = 0.0;
		victimVel[1] = 0.0;
		victimVel[2] = 0.0;
	}
	
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, victimVel);
	return Plugin_Continue;
}

stock void CreateHookBeam(int client, int victim)
{
	//BEAM
	int beam = CreateEntityByName("env_beam");

	char color[16];
	Format(color, sizeof(color), "255 255 25 255");
		
	SetEntityModel(beam, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
	DispatchKeyValue(beam, "rendercolor", color );
	DispatchKeyValue(beam, "renderamt", "200");
	DispatchKeyValue(beam, "decalname", "Bigshot"); 
	DispatchKeyValue(beam, "life", "0"); 
	DispatchKeyValue(beam, "TouchType", "0");
	DispatchSpawn(beam);
	
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", client);
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", victim, 1);
	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(beam, Prop_Send, "m_nBeamType", 2);
	
	SetEntPropFloat(beam, Prop_Data, "m_fWidth", 5.0); 
	SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", 5.0); 
	ActivateEntity(beam);
	AcceptEntityInput(beam, "TurnOn");

	g_iHook[client] = EntIndexToEntRef(beam);
}

stock void CreateEmptyHook(int client)
{
	float startPos[3];
	GetClientAbsOrigin(client, startPos);
	startPos[2] += 40.0;
	
	float eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	float endPos[3];
	Handle trace = TR_TraceRayFilterEx(startPos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	//BEAM
	int beam = CreateEntityByName("env_beam");

	char color[16];
	Format(color, sizeof(color), "255 255 25 255");
		
	SetEntityModel(beam, MODEL_BEAM); // This is where you would put the texture, ie "sprites/laser.vmt" or whatever.
	DispatchKeyValue(beam, "rendercolor", color );
	DispatchKeyValue(beam, "renderamt", "200");
	DispatchKeyValue(beam, "decalname", "Bigshot"); 
	DispatchKeyValue(beam, "life", "0"); 
	DispatchKeyValue(beam, "TouchType", "0");
	DispatchSpawn(beam);
	TeleportEntity(beam, startPos, NULL_VECTOR, NULL_VECTOR);
	
	//PROP
	int prop = CreateEntityByName("info_target");
	DispatchSpawn(prop);
	TeleportEntity(prop, endPos, NULL_VECTOR, NULL_VECTOR);
	//PROP END
	
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", beam);
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", prop, 1);
	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(beam, Prop_Send, "m_nBeamType", 2);
	
	SetEntPropFloat(beam, Prop_Data, "m_fWidth", 5.0); 
	SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", 5.0); 
	ActivateEntity(beam);
	AcceptEntityInput(beam, "TurnOn");
	
	SetVariantString("!activator");
	AcceptEntityInput(beam, "SetParent", client);

	g_iHookProp[client] = EntIndexToEntRef(prop);
	g_iHook[client] = EntIndexToEntRef(beam);
}

public void ScorpionHookOff(int client)
{
	g_bHooked[client] = false;
	int hook = EntRefToEntIndex(g_iHook[client]);
	if(hook != INVALID_ENT_REFERENCE)
		AcceptEntityInput(hook, "Kill");
	g_iHook[client] = INVALID_ENT_REFERENCE;
	
	int prop = EntRefToEntIndex(g_iHookProp[client]);
	if(prop != INVALID_ENT_REFERENCE)
		AcceptEntityInput(prop, "Kill");
	g_iHookProp[client] = INVALID_ENT_REFERENCE;
	
	g_iHooked[client] = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/getoverhere.mp3");
	AddFileToDownloadsTable("sound/superheromod/headshot.mp3");
	AddFileToDownloadsTable("sound/superheromod/hit.mp3");
	PrecacheSoundAny(HOOK_SOUND, true);
	PrecacheSoundAny(HEADSHOT_SOUND, true);
	PrecacheSoundAny(HIT_SOUND, true);
	g_iSprite = PrecacheModel(MODEL_BEAM);
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity == 0 && entityhit != entity)
		return true;
	
	return false;
}
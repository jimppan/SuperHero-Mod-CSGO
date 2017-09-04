#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define HOOKBEAMLIFE 100
#define HOOK_REFRESH_TIME 0.1
#define MODEL_BEAM "materials/sprites/purplelaser1.vmt"
#define HOOK_SOUND "superheromod/hook.mp3"
EngineVersion g_Game;

ConVar g_BatgirlLevel;
ConVar g_BatgirlReelSpeed;
ConVar g_BatgirlTeamColored;
ConVar g_BatgirlMaxHooks;

bool g_bHooked[MAXPLAYERS + 1];
int g_iHook[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHookProp[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHooksLeft[MAXPLAYERS + 1];
int g_iHeroIndex;
float g_fHookLength[MAXPLAYERS + 1];
float g_vecHookPos[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Batgirl",
	author = PLUGIN_AUTHOR,
	description = "Batgirl hero",
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
	
	g_BatgirlLevel = CreateConVar("superheromod_batgirl_level", "9");
	g_BatgirlReelSpeed = CreateConVar("superheromod_batgirl_reel_speed", "1000", "How fast hook line reels in");
	g_BatgirlTeamColored = CreateConVar("superheromod_spiderman_team_colored", "1", "1=teamcolored web lines 0=white web lines");
	g_BatgirlMaxHooks = CreateConVar("superheromod_spiderman_max_hooks", "-1", "Max ammout of hooks allowed (-1 is an unlimited ammount)");
	AutoExecConfig(true, "batgirl", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Batgirl", g_BatgirlLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Grappling Hook", "You now have the Bat-Grapple hook. Zipline to aim");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	if(g_bHooked[client])
		BatgirlHookOff(client);
	
	g_iHooksLeft[client] = g_BatgirlMaxHooks.IntValue;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	g_iHooksLeft[client] = g_BatgirlMaxHooks.IntValue;
	
	if(g_bHooked[client])
		BatgirlHookOff(client);
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
				SuperHero_PlayDenySound(client);
				return;
			}
			
			if(g_iHooksLeft[client] > 0)
				g_iHooksLeft[client]--;
				
			g_bHooked[client] = true;
			
			
			SetEntPropFloat(client, Prop_Data, "m_flGravity", 0.001);
			CreateWebBeam(client);
			
			SetVariantString("!activator");
			AcceptEntityInput(EntRefToEntIndex(g_iHook[client]), "SetParent", client);
			float pos[3];
			GetClientEyePosition(client, pos);
			EmitAmbientSoundAny(HOOK_SOUND, pos);
		}
		case SH_KEYUP:
		{
			if(g_bHooked[client])
				BatgirlHookOff(client);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bHooked[client])
		BatgirlCheapReel(client);
}

stock void BatgirlCheapReel(int client)
{
	// Cheat Web - just drags you where you shoot it...

	if (!g_bHooked[client]) 
		return;

	if (!IsPlayerAlive(client)) 
	{
		BatgirlHookOff(client);
		return;
	}
	

	float user_origin[3];
	float velocity[3];

	GetClientAbsOrigin(client, user_origin);

	float distance = GetVectorDistance(g_vecHookPos[client], user_origin);

	if ( distance > 60 ) {
		float inverseTime = g_BatgirlReelSpeed.FloatValue / distance;
		velocity[0] = (g_vecHookPos[client][0] - user_origin[0]) * inverseTime;
		velocity[1] = (g_vecHookPos[client][1] - user_origin[1]) * inverseTime;
		velocity[2] = (g_vecHookPos[client][2] - user_origin[2]) * inverseTime;
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public void BatgirlHookOff(int client)
{
	g_bHooked[client] = false;
	KillBeam(client);

	if (IsValidClient(client))
		SuperHero_ResetGravity(client);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/hook.mp3");
	PrecacheSoundAny(HOOK_SOUND, true);
}

stock void KillBeam(int client)
{
	int beam = EntRefToEntIndex(g_iHook[client]);
	int prop = EntRefToEntIndex(g_iHookProp[client]);
	if(beam != INVALID_ENT_REFERENCE)
		AcceptEntityInput(beam, "Kill");
	if(prop != INVALID_ENT_REFERENCE)
		AcceptEntityInput(prop, "Kill");
}

stock void CreateWebBeam(int client)
{
	float startPos[3];
	GetClientAbsOrigin(client, startPos);
	startPos[2] += 40.0;
	
	float eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);

	Handle trace = TR_TraceRayFilterEx(startPos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(g_vecHookPos[client], trace);
	CloseHandle(trace);
	
	g_fHookLength[client] = GetVectorDistance(startPos, g_vecHookPos[client]);
	//BEAM
	int beam = CreateEntityByName("env_beam");

	char color[16];
	
	if(g_BatgirlTeamColored.BoolValue)
	{
		if(GetClientTeam(client) == CS_TEAM_T)
			Format(color, sizeof(color), "255 0 0 255");
		else
			Format(color, sizeof(color), "0 0 255 255");
	}
	else
		Format(color, sizeof(color), "255 255 255 255");
		
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
	//DispatchKeyValue(prop, "model", "models/props/de_train/barrel.mdl");
	DispatchSpawn(prop);
	TeleportEntity(prop, g_vecHookPos[client], NULL_VECTOR, NULL_VECTOR);
	//PROP END
	
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", beam);
	SetEntPropEnt(beam, Prop_Send, "m_hAttachEntity", prop, 1);
	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(beam, Prop_Send, "m_nBeamType", 2);
	
	SetEntPropFloat(beam, Prop_Data, "m_fWidth", 5.0); 
	SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", 5.0); 
	ActivateEntity(beam);
	AcceptEntityInput(beam, "TurnOn");

	g_iHookProp[client] = EntIndexToEntRef(prop);
	g_iHook[client] = EntIndexToEntRef(beam);
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
	if(entity == 0 && entityhit != entity)
		return true;
	
	return false;
}
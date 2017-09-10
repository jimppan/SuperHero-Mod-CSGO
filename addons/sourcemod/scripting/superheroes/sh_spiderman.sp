#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.04"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>

#pragma newdecls required

#define HOOKBEAMLIFE 100
#define HOOK_REFRESH_TIME 0.1
#define MODEL_BEAM "materials/sprites/purplelaser1.vmt"
#define WEB_SOUND "superheromod/spiderweb.mp3"
EngineVersion g_Game;

ConVar g_SpidermanLevel;
ConVar g_SpidermanMoveAcceleration;
ConVar g_SpidermanReelSpeed;
ConVar g_SpidermanHookStyle;
ConVar g_SpidermanTeamColored;
ConVar g_SpidermanMaxHooks;

bool g_bHooked[MAXPLAYERS + 1];
int g_iHook[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHookProp[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHooksLeft[MAXPLAYERS + 1];
int g_iHeroIndex;
float g_fHookLength[MAXPLAYERS + 1];
float g_vecHookPos[MAXPLAYERS + 1][3];
Handle g_hTimerHook[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Spiderman",
	author = PLUGIN_AUTHOR,
	description = "Spiderman hero",
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
	
	g_SpidermanLevel = CreateConVar("superheromod_spiderman_level", "0");
	g_SpidermanMoveAcceleration = CreateConVar("superheromod_spiderman_move_acceleration", "140", "How quickly he can move while on the hook");
	g_SpidermanReelSpeed = CreateConVar("superheromod_spiderman_reel_speed", "400", "How fast hook line reels in");
	g_SpidermanHookStyle = CreateConVar("superheromod_spiderman_hook_style", "2", "1=spacedude, 2=spacedude auto reel (spiderman)");
	g_SpidermanTeamColored = CreateConVar("superheromod_spiderman_team_colored", "1", "1=teamcolored web lines 0=white web lines");
	g_SpidermanMaxHooks = CreateConVar("superheromod_spiderman_max_hooks", "-1", "Max ammout of hooks allowed (-1 is an unlimited ammount)");
	AutoExecConfig(true, "spiderman", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Spiderman", g_SpidermanLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Web Swing", "Shoot web to swing - Jump reels in, Duck reels out");
	SuperHero_SetHeroBind(g_iHeroIndex);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_SpidermanLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	if(g_bHooked[client])
		SpiderManHookOff(client);
	
	g_iHooksLeft[client] = g_SpidermanMaxHooks.IntValue;
}

public void SuperHero_OnPlayerSpawned(int client, bool newroundspawn)
{
	g_iHooksLeft[client] = g_SpidermanMaxHooks.IntValue;
	
	if(g_bHooked[client])
		SpiderManHookOff(client);
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
			g_hTimerHook[client] = CreateTimer(HOOK_REFRESH_TIME, Timer_Hook, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			float pos[3];
			GetClientEyePosition(client, pos);
			EmitAmbientSoundAny(WEB_SOUND, pos);
		}
		case SH_KEYUP:
		{
			if(g_bHooked[client])
				SpiderManHookOff(client);
		}
	}
}

public Action Timer_Hook(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
	{
		g_hTimerHook[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	switch(g_SpidermanHookStyle.IntValue)
	{
		case 1:
			SpidermanPhysics(client, false);
		case 2:
			SpidermanPhysics(client, true);
		default:
			SpidermanCheapReel(client);
	}
	
	return Plugin_Continue;
}


stock void SpidermanPhysics(int client, bool autoReel)
{
	if (!g_bHooked[client]) 
		return;

	if (!IsPlayerAlive(client)) 
	{
		SpiderManHookOff(client);
		return;
	}

	//if ( g_fHookCreated[client] + HOOKBEAMLIFE/10 <= GetGameTime())
	//	CreateWebBeam(client);

	float user_origin[3], A[3], D[3], buttonadjust[3];
	float vTowards_A, DvTowards_A, velocity[3];
	int buttons;
	
	GetClientAbsOrigin(client, user_origin);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	buttons = GetClientButtons(client);

	if (buttons & IN_FORWARD)++buttonadjust[0];
	if (buttons & IN_BACK)--buttonadjust[0];

	if (buttons & IN_MOVERIGHT)++buttonadjust[1];
	if (buttons & IN_MOVELEFT)--buttonadjust[1];

	if (buttons & IN_JUMP)++buttonadjust[2];
	if (buttons & IN_DUCK)--buttonadjust[2];

	if ( buttonadjust[0] || buttonadjust[1] ) 
	{
		float move_direction[3];
		
		float eyePos[3];
		GetClientEyePosition(client, eyePos);

		float user_look[3], eyeAngles[3];
		GetClientEyeAngles(client, eyeAngles);
	
		Handle trace = TR_TraceRayFilterEx(eyePos, eyeAngles, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
		if(TR_DidHit(trace))
			TR_GetEndPosition(user_look, trace);
		CloseHandle(trace);
		
		user_look[0] -= user_origin[0];
		user_look[1] -= user_origin[1];

		move_direction[0] = buttonadjust[0] * user_look[0] + user_look[1] * buttonadjust[1];
		move_direction[1] = buttonadjust[0] * user_look[1] - user_look[0] * buttonadjust[1];
		move_direction[2] = 0.0;

		float move_dist = GetVectorDistance(NULL_VECTOR, move_direction);
		float accel = g_SpidermanMoveAcceleration.FloatValue * HOOK_REFRESH_TIME;

		velocity[0] += move_direction[0] * accel / move_dist;
		velocity[1] += move_direction[1] * accel / move_dist;
	}

	if (buttonadjust[2] < 0 || (buttonadjust[2] && g_fHookLength[client] >= 60))
		g_fHookLength[client] -= RoundToNearest(buttonadjust[2] * g_SpidermanReelSpeed.FloatValue * HOOK_REFRESH_TIME);
	else if (autoReel && !(buttons&IN_DUCK) && g_fHookLength[client] >= 200) 
	{
		buttonadjust[2] += 1;
		g_fHookLength[client] -= RoundToNearest(buttonadjust[2] * g_SpidermanReelSpeed.FloatValue * HOOK_REFRESH_TIME);
	}

	A[0] = g_vecHookPos[client][0] - user_origin[0];
	A[1] = g_vecHookPos[client][1] - user_origin[1];
	A[2] = g_vecHookPos[client][2] - user_origin[2];

	float distA = GetVectorDistance(NULL_VECTOR, A);
	distA = distA ? distA : 1.0; // Avoid dividing by 0

	vTowards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / distA;
	DvTowards_A = (GetVectorDistance(user_origin, g_vecHookPos[client]) - g_fHookLength[client]) * 4.0;

	D[0] = A[0] * A[2] / distA;
	D[1] = A[1] * A[2] / distA;
	D[2] = -(A[1] * A[1] + A[0] * A[0]) / distA;

	float distD = GetVectorDistance(NULL_VECTOR, D);
	if ( distD > 10 ) 
	{
		float laggedspeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
		float acceleration = (((-GetConVarFloat(FindConVar("sv_gravity"))) * D[2] / distD) * HOOK_REFRESH_TIME) / laggedspeed;
		velocity[0] += (acceleration * D[0]) / distD;
		velocity[1] += (acceleration * D[1]) / distD;
		velocity[2] += (acceleration * D[2]) / distD;
	}

	float difference = DvTowards_A - vTowards_A;

	velocity[0] += ((difference * A[0]) / distA);
	velocity[1] += ((difference * A[1]) / distA);
	velocity[2] += ((difference * A[2]) / distA);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

stock void SpidermanCheapReel(int client)
{
	// Cheat Web - just drags you where you shoot it...

	if (!g_bHooked[client]) 
		return;

	if (!IsPlayerAlive(client)) 
	{
		SpiderManHookOff(client);
		return;
	}

	float user_origin[3];
	float velocity[3];

	GetClientAbsOrigin(client, user_origin);

	float distance = GetVectorDistance(g_vecHookPos[client], user_origin);

	if ( distance > 60 ) {
		float inverseTime = g_SpidermanReelSpeed.FloatValue / distance;
		velocity[0] = (g_vecHookPos[client][0] - user_origin[0]) * inverseTime;
		velocity[1] = (g_vecHookPos[client][1] - user_origin[1]) * inverseTime;
		velocity[2] = (g_vecHookPos[client][2] - user_origin[2]) * inverseTime;
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public void SpiderManHookOff(int client)
{
	g_bHooked[client] = false;

	KillBeam(client);

	if (IsValidClient(client)) 
		SuperHero_ResetGravity(client);
		
	if(g_hTimerHook[client] != INVALID_HANDLE)
		KillTimer(g_hTimerHook[client]);
	g_hTimerHook[client] = INVALID_HANDLE;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/superheromod/spiderweb.mp3");
	PrecacheSoundAny(WEB_SOUND, true);
	PrecacheModel("materials/sprites/purplelaser1.vmt");
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
	
	if(g_SpidermanTeamColored.BoolValue)
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
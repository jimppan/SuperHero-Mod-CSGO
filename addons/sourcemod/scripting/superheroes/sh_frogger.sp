#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_FroggerLevel;
ConVar g_FroggerPower;
ConVar g_FroggerUpVelocity;

bool g_bHasFrogger[MAXPLAYERS + 1];
int g_iHeroIndex;

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Frogger",
	author = PLUGIN_AUTHOR,
	description = "Frogger hero",
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
	
	g_FroggerLevel = CreateConVar("superheromod_frogger_level", "0");
	g_FroggerPower = CreateConVar("superheromod_frogger_power", "800", "Amount of force the jump should have");
	g_FroggerUpVelocity = CreateConVar("superheromod_frogger_up_velocity", "800", "Amount of up velocity frogger should jump");
	AutoExecConfig(true, "frogger", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Frogger", g_FroggerLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Long Jump", "While moving forward, hold duck to jump further");
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_FroggerLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasFrogger[client] = (mode ? true : false);
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bHasFrogger[client])
	{
		if((buttons & IN_JUMP) && (buttons & IN_DUCK) && GetEntityFlags(client) & FL_ONGROUND)
		{
			float eyePos[3];
			float fwd[3];
			GetClientEyeAngles(client, eyePos);
			eyePos[0] = 0.0;
			
			if(buttons & IN_FORWARD)
			{
				if(buttons & IN_MOVELEFT)
					eyePos[1] = eyePos[1] + 45.0;
				else if(buttons & IN_MOVERIGHT)
					eyePos[1] = eyePos[1] + -45.0;
			}
				
			if(buttons & IN_BACK)
			{
				eyePos[1] = eyePos[1] + 180.0;
				if(buttons & IN_MOVELEFT)
					eyePos[1] = eyePos[1] + -45.0;
				else if(buttons & IN_MOVERIGHT)
					eyePos[1] = eyePos[1] + 45.0;
			}
			
			if(buttons & IN_MOVELEFT && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVERIGHT))
				eyePos[1] = eyePos[1] + 90.0;
					
			if(buttons & IN_MOVERIGHT && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVELEFT))
				eyePos[1] = eyePos[1] + -90.0;
				
			GetAngleVectors(eyePos, fwd, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(fwd, fwd);
			ScaleVector(fwd, g_FroggerPower.FloatValue);
			
			
			if(!(buttons & IN_MOVERIGHT) && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVELEFT))
			{
				fwd[1] = 0.0;
				fwd[0] = 0.0;
			}
			fwd[2] = fwd[2] + g_FroggerUpVelocity.FloatValue;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fwd);
		}
	}
}
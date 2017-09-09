#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_BlackpantherLevel;
ConVar g_Footsteps;

int g_iHeroIndex;
bool g_bHasBlackPanther[MAXPLAYERS + 1];


public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO Hero - Black Panther",
	author = PLUGIN_AUTHOR,
	description = "Black Panther hero",
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
	g_BlackpantherLevel = CreateConVar("superheromod_blackpanther_level", "0");
	AutoExecConfig(true, "blackpanther", "sourcemod/superheromod");
	
	g_iHeroIndex = SuperHero_CreateHero("Black Panther", g_BlackpantherLevel.IntValue);
	SuperHero_SetHeroInfo(g_iHeroIndex, "Silent Boots", "Your boots have vibranium soles that absorbs sound");
	
	g_Footsteps = FindConVar("sv_footsteps");
	AddNormalSoundHook(FootstepCheck);
}

public void OnConfigsExecuted()
{
	SuperHero_SetHeroAvailableLevel(g_iHeroIndex, g_BlackpantherLevel.IntValue);
}

public void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode)
{
	if(heroIndex != g_iHeroIndex)
		return;
		
	g_bHasBlackPanther[client] = (mode ? true : false);
}
//https://forums.alliedmods.net/showpost.php?p=2349931&postcount=34
public Action FootstepCheck(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags) 
{ 
    // Player
    if (0 < entity <= MaxClients) 
    { 
        if(StrContains(sample, "footsteps") != -1 && StrContains(sample, "suit") == -1) 
        { 
            // Player not ninja, play footsteps 
            if(!g_bHasBlackPanther[entity]) 
            { 
                numClients = 0; 

                for(int i = 1; i <= MaxClients; i++) 
                { 
                    if(IsClientInGame(i) && !IsFakeClient(i)) 
                    { 
                        clients[numClients++] = i; 
                       // PrintToChat(i, "%s", sample);
                    } 
                } 

                EmitSound(clients, numClients, sample, entity); 
                //return Plugin_Changed; 
            } 
            return Plugin_Stop; 
        } 
    } 
    return Plugin_Continue; 
}  

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client))
		SendConVarValue(client, g_Footsteps, "0");
}

public bool OnClientConnect(int client, char[]rejectmsg, int maxlen)
{
	g_bHasBlackPanther[client] = false;
	return true;
}


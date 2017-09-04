#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.03"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <superheromod>
#include <emitsoundany>
//#include <sdkhooks>
#pragma newdecls required

#define DENY_SOUND "superheromod/deny.mp3"
#define LEVEL_SOUND "superheromod/level.mp3"

EngineVersion g_Game;

//Global variables
int g_iGlowEntities[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
int g_iHeroCount = 0; 																	//gSuperHeroCount
int g_iLevelExperience[SH_MAXLEVELS + 1]; 												//gXPLevel
int g_iGivenExperience[SH_MAXLEVELS + 1]; 												//gXPGiven
Handle g_hHeroes[SH_MAXHEROES][HeroEnum]; 												//gSuperHeros - The Big Array that holds all of the heroes, superpowers, help, and other important info
//Handle g_hHelpHudSync;																//gHelpHudSync
Handle g_hHeroHudSync;																	//gHeroHudSync
Handle g_hCoolDownTimers[MAXPLAYERS + 1][SH_MAXHEROES + 1];
Database g_hPlayerData;

//Player Variables
//bool g_bReadExperienceNextRound[MAXPLAYERS + 1];										//gReadXPNextRound
bool g_bChangedHeroes[MAXPLAYERS + 1];													//gChangedHeroes
bool g_bNewRoundSpawn[MAXPLAYERS + 1];													//gNewRoundSpawn
bool g_bPowerDown[MAXPLAYERS + 1][SH_MAXBINDPOWERS + 1];								//gInPowerDown
bool g_bPlayerInCooldown[MAXPLAYERS + 1][SH_MAXHEROES + 1];								//gPlayerInCooldown - See superheromod.inc (AMX version) line 840 - Edit: I have no clue what this is even supposed to do, so ima make it cool down per hero
bool g_bWeaponSwitchSpeedChange[MAXPLAYERS + 1] =  { true, ... }; 						//Should we change the speed of the player every time he changes weapons? (Useful for things like sh_shadowcat.sp noclip)
int g_iPlayerExperience[MAXPLAYERS + 1]; 												//gPlayerXP
int g_iPlayerLevel[MAXPLAYERS + 1]; 													//gPlayerLevel
int g_iPlayerPowers[MAXPLAYERS + 1][SH_MAXLEVELS + 1]; 									//gPlayerPowers - List of all Powers - Slot 0 is the superpower count 
//int g_iPlayerPowersLeft[MAXPLAYERS + 1][SH_MAXLEVELS + 1]; 								//gMaxPowersLeft
int g_iPlayerMenuChoices[MAXPLAYERS + 1][SH_MAXHEROES + 1];								//gPlayerMenuChoices - This will be filled in with # of heroes available
int g_iPlayerBinds[MAXPLAYERS + 1][SH_MAXBINDPOWERS + 1]; 								//gPlayerBinds - What superpowers are the bind keys bound
int g_iPlayerMaxHealth[MAXPLAYERS + 1];													//gMaxHealth
int g_iPlayerMaxArmor[MAXPLAYERS + 1];													//gMaxArmor
int g_iPlayerArmor[MAXPLAYERS + 1];														//CS:GO Armor value is a byte, custom variable has to be set
int g_iPlayerStunTimer[MAXPLAYERS + 1];													//gPlayerStunTimer
int g_iPlayerFlags[MAXPLAYERS + 1]; 													//gPlayerFlags
int g_iPlayerGodTimer[MAXPLAYERS + 1];													//gPlayerGodTimer
float g_fPlayerStunSpeed[MAXPLAYERS + 1];												//gPlayerStunSpeed

//Hero variables
int g_iHeroMaxHealth[SH_MAXHEROES];														//gHeroMaxHealth
int g_iHeroMaxArmor[SH_MAXHEROES];														//gHeroMaxArmor
float g_fHeroMaxDamageMultiplier[SH_MAXHEROES][view_as<int>(CSGOWeaponID_INCGRENADE)+1];//gHeroMaxDamageMult - CSGOWeapon_INCGRENADE is the last damaging item in the csgo weapon id enum (superheromod.inc)
float g_fHeroGravity[SH_MAXHEROES];														//gHeroMinGravity
float g_fHeroMaxSpeed[SH_MAXHEROES];													//gHeroMaxSpeed
bool g_bHeroSpeedWeapons[SH_MAXHEROES][view_as<int>(CSGOWeaponID_INCGRENADE)+1];		//gHeroSpeedWeapons
CSGOWeaponID g_HeroPrimaryWeapon[SH_MAXHEROES] =  { CSGOWeaponID_NONE, ... };			//Variable is used to calculate what primary weapon to give the player if he has more than 1 hero that gives him weapons
CSGOWeaponID g_HeroSecondaryWeapon[SH_MAXHEROES] =  { CSGOWeaponID_NONE, ... };			//Variable is used to calculate what secondary weapon to give the player if he has more than 1 hero that gives him weapons
char g_szHeroModel[SH_MAXHEROES][PLATFORM_MAX_PATH];									//Variable is used to calculate what player model to use (Highest hero level will get used)

//Memory Table Variables
int g_iMemoryTableCount = 33;															//gMemoryTableCount
int g_iMemoryTableExperience[SH_MEMORY_TABLE_SIZE]; 									//gMemoryTableXP - How much XP does a player have?
int g_iMemoryTableFlags[SH_MEMORY_TABLE_SIZE]; 											//gMemoryTableFlags - User flags for other settings (see below)
int g_iMemoryTablePowers[SH_MEMORY_TABLE_SIZE][SH_MAXLEVELS + 1]; 						//gMemoryTablePowers - 0=# of powers, 1=hero index, etc...
char g_szMemoryTableKeys[SH_MEMORY_TABLE_SIZE][32]; 									//gMemoryTableKeys - Table for storing xp lines that need to be flushed to file...
char g_szMemoryTableNames[SH_MEMORY_TABLE_SIZE][32]; 									//gMemoryTableNames - Stores players name for a key

//Convars
ConVar g_MaxPowers;
ConVar g_LongTermExperience;
ConVar g_Levels;
ConVar g_MaxBinds;
ConVar g_DropAlive;
ConVar g_HeadshotMultiplier;

//Forwards
Handle g_hOnHeroInitialized;
Handle g_hOnPlayerSpawned;
Handle g_hOnPlayerDeath;
Handle g_hOnPlayerTakeDamage;
Handle g_hOnPlayerTakeDamagePost;
Handle g_hOnHeroBind;

#include "superheromod-sql.sp"

public Plugin myinfo = 
{
	name = "SuperHero Mod CS:GO v1.03",
	author = PLUGIN_AUTHOR,
	description = "Remake/Port of SuperHero mod for AMX Mod (Counter-Strike 1.6) by vittu/batman",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("superheromod.phrases");
	
	if(!DirExists("cfg/sourcemod/superheromod"))
		CreateDirectory("cfg/sourcemod/superheromod", 511); //tbh I have no idea what im doing, but it works
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	HookEvent("player_spawn",			Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death",			Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_prestart",			Event_RoundPreStart, EventHookMode_Pre);
	HookEvent("round_freeze_end", 		Event_RoundFreezeEnd);
	
	RegAdminCmd("sm_shsetxp", 			Command_SetExperience, ADMFLAG_BAN, "Allows admins to set a players XP to a specified amount");
	RegAdminCmd("sm_shaddxp", 			Command_AddExperience, ADMFLAG_BAN, "Allows admins to give add XP to their current XP");
	RegAdminCmd("sm_shsetlevel", 		Command_SetLevel, ADMFLAG_BAN, "Allows admins to set a players level to a specified number");
	//RegAdminCmd("sm_shimmunexp", 		Command_Immune, ADMFLAG_BAN, "Allows admins to set/unset players immune from save days XP reset");
	//RegAdminCmd("sm_shresetxp",		Command_ResetExperience, ADMFLAG_BAN, "Allows admins with ADMIN_RCON to reset all the saved XP");
	
	RegConsoleCmd("sm_help", 			Command_Help, "Outputs all commands in console");
	RegConsoleCmd("sm_superherohelp", 	Command_Help, "Outputs all commands in console");
	RegConsoleCmd("sm_herolist", 		Command_HeroList, "Shows the list of available heros");
	RegConsoleCmd("sm_playerskills", 	Command_PlayerInfo, "Shows every player's superhero info");
	RegConsoleCmd("sm_playerpowers", 	Command_PlayerInfo, "Shows every player's superhero info");
	RegConsoleCmd("sm_playerheroes", 	Command_PlayerInfo, "Shows every player's superhero info");
	RegConsoleCmd("sm_playerinfo", 		Command_PlayerInfo, "Shows every player's superhero info");
	RegConsoleCmd("sm_myheroes", 		Command_MyHeroes, "Shows the heros you have already chosen and the binds that you have already made");
	RegConsoleCmd("sm_clearheroes", 	Command_ClearHeroes, "Is used to erase all your heroes (in case you want to chose other heroes)");
	RegConsoleCmd("sm_clearpowers", 	Command_ClearHeroes, "Is used to erase all your heroes (in case you want to chose other heroes)");
	RegConsoleCmd("sm_clearskills", 	Command_ClearHeroes, "Is used to erase all your heroes (in case you want to chose other heroes)");
	RegConsoleCmd("sm_showmenu", 		Command_Heroes, "Shows you the powers menu in case you can chose heroes");
	RegConsoleCmd("sm_heroes", 			Command_Heroes, "Shows you the powers menu in case you can chose heroes");
	RegConsoleCmd("sm_heromenu", 		Command_Heroes, "Shows you the powers menu in case you can chose heroes");
	RegConsoleCmd("sm_drophero", 		Command_Drop, "Is used to remove a hero from your hero list in case you want another");
	RegConsoleCmd("sm_drop", 			Command_Drop, "Is used to remove a hero from your hero list in case you want another");
	RegConsoleCmd("sm_whohas", 			Command_WhoHas, "Shows you who has the named heroes in the current game");
	
	char powerDown[10], powerUp[10];
	for (int i = 1; i <= SH_MAXBINDPOWERS; i++)
	{
		Format(powerDown, sizeof(powerDown), "+power%d", i);
		Format(powerUp, sizeof(powerUp), "-power%d", i);
		
		RegConsoleCmd(powerDown, PowerKeyDown);
		RegConsoleCmd(powerUp, PowerKeyUp);
	}
	
	
	g_MaxPowers = 						CreateConVar("superheromod_max_powers", "20", "Max amount of powers a player can have");
	g_LongTermExperience = 				CreateConVar("superheromod_long_term_experience", "1", "Should XP be saved");
	g_MaxBinds = 						CreateConVar("superheromod_max_binds", "3", "Max amount of super power binds");
	g_DropAlive =						CreateConVar("superheromod_drop_alive", "0", "Drop power while alive");
	g_HeadshotMultiplier = 				CreateConVar("superheromod_headshot_multiplier", "1.5", "Amount of times points you should get for killing with a headshot");
	
	g_hOnHeroInitialized =				CreateGlobalForward("SuperHero_OnHeroInitialized", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnPlayerSpawned = 				CreateGlobalForward("SuperHero_OnPlayerSpawned", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnPlayerDeath = 					CreateGlobalForward("SuperHero_OnPlayerDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnPlayerTakeDamage = 			CreateGlobalForward("SuperHero_OnPlayerTakeDamage", ET_Ignore, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array);
	g_hOnPlayerTakeDamagePost =			CreateGlobalForward("SuperHero_OnPlayerTakeDamagePost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hOnHeroBind = 					CreateGlobalForward("SuperHero_OnHeroBind", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	//g_hHelpHudSync = 					CreateHudSynchronizer();
	g_hHeroHudSync = 					CreateHudSynchronizer();
	
	//Database.Connect(SQLConnection_Callback, "superheromod");
	KeyValues kv = CreateKeyValues("");
	kv.SetString("driver", "sqlite");
	kv.SetString("database", "sourcemod");
	
	char wedontcareaboutnoerrorscuh[420];
	g_hPlayerData = SQL_ConnectCustom(kv, wedontcareaboutnoerrorscuh, sizeof(wedontcareaboutnoerrorscuh), true);
	delete kv;
	ReadINI();
	CvarCheck();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
			
		for (int j = 0; j <= SH_MAXHEROES;j++)
			g_hCoolDownTimers[i][j] = INVALID_HANDLE;
	}
	
	CreateTimer(1.0, Timer_All, _, TIMER_REPEAT);
	AutoExecConfig(true, "superheromod");
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	CreateNative("SuperHero_CreateHero", Native_CreateHero);
	CreateNative("SuperHero_SetHeroInfo", Native_SetHeroInfo);
	CreateNative("SuperHero_SetHeroBind", Native_SetHeroBind);
	CreateNative("SuperHero_SetHeroHealth", Native_SetHeroHealth);
	CreateNative("SuperHero_SetHeroArmor", Native_SetHeroArmor);
	CreateNative("SuperHero_SetHeroGravity", Native_SetHeroGravity);
	CreateNative("SuperHero_SetHeroSpeed", Native_SetHeroSpeed);
	CreateNative("SuperHero_SetHeroDamageMultiplier", Native_SetHeroDamageMultiplier);
	CreateNative("SuperHero_GetMaxHealth", Native_GetMaxHealth);
	CreateNative("SuperHero_GetMaxArmor", Native_GetMaxArmor);
	CreateNative("SuperHero_GetMaxSpeed", Native_GetMaxSpeed);
	CreateNative("SuperHero_GetGravity", Native_GetGravity);
	CreateNative("SuperHero_GetLevelCount", Native_GetLevelCount);
	CreateNative("SuperHero_GetLevelExperience", Native_GetLevelExperience);
	CreateNative("SuperHero_GetPlayerLevel", Native_GetPlayerLevel);
	CreateNative("SuperHero_SetPlayerLevel", Native_SetPlayerLevel);
	CreateNative("SuperHero_GetPlayerExperience", Native_GetPlayerExperience);
	CreateNative("SuperHero_SetPlayerExperience", Native_SetPlayerExperience);
	CreateNative("SuperHero_AddKillExperience", Native_AddKillExperience);
	CreateNative("SuperHero_GetHeroIndex", Native_GetHeroIndex);
	CreateNative("SuperHero_PlayerHasHero", Native_PlayerHasHero);
	CreateNative("SuperHero_SetStun", Native_SetStun);
	CreateNative("SuperHero_GetStun", Native_GetStun);
	CreateNative("SuperHero_SetGodMode", Native_SetGodMode);
	CreateNative("SuperHero_IsGodMode", Native_IsGodMode);
	CreateNative("SuperHero_ResetMaxSpeed", Native_ResetMaxSpeed);
	CreateNative("SuperHero_ResetGravity", Native_ResetGravity);
	//NEW NATIVES IN CSGO VERSION
	CreateNative("SuperHero_SetPlayerHeroCooldown", Native_SetPlayerHeroCooldown);
	CreateNative("SuperHero_EndPlayerHeroCooldown", Native_EndPlayerHeroCooldown);
	CreateNative("SuperHero_IsPlayerHeroInCooldown", Native_IsPlayerHeroInCooldown);
	CreateNative("SuperHero_ForceSetPlayerHeroCooldown", Native_ForceSetPlayerHeroCooldown);
	CreateNative("SuperHero_AddHealth", Native_AddHealth);
	CreateNative("SuperHero_AddArmor", Native_AddArmor);
	CreateNative("SuperHero_PlayDenySound", Native_PlayDenySound);
	CreateNative("SuperHero_SetChangeWeaponSpeedBool", Native_SetChangeWeaponSpeedBool);
	CreateNative("SuperHero_SetHeroPrimaryWeapon", Native_SetHeroPrimaryWeapon);
	CreateNative("SuperHero_SetHeroSecondaryWeapon", Native_SetHeroSecondaryWeapon);
	CreateNative("SuperHero_GetHighestPrimaryWeaponLevel", Native_GetHighestPrimaryWeaponLevel);
	CreateNative("SuperHero_GetHighestSecondaryWeaponLevel", Native_GetHighestSecondaryWeaponLevel);
	CreateNative("SuperHero_GetHighestLevelHero", Native_GetHighestLevelHero);
	CreateNative("SuperHero_SetHeroPlayerModel", Native_SetHeroPlayerModel);
	CreateNative("SuperHero_GetHeroPlayerModel", Native_GetHeroPlayerModel);
	CreateNative("SuperHero_HeroHasPlayerModel", Native_HeroHasPlayerModel);
	CreateNative("SuperHero_GetHighestPlayerModelLevel", Native_GetHighestPlayerModelLevel);
	
	RegPluginLibrary("superheromod");

	return APLRes_Success;
}

//////////////
//	NATIVES	//
//////////////
public int Native_CreateHero(Handle plugin, int numParams)
{
	if(g_iHeroCount >= SH_MAXHEROES)
		SetFailState("[superheromod.smx] Error: Exceeded SH_MAXHEROES");
		
	char hero[64];
	GetNativeString(1, hero, sizeof(hero));
		
	int heroIndex = g_iHeroCount;
	PrintToServer("[superheromod.smx] Hero: '%s' loaded successfully. ID: %d", hero, heroIndex);
	g_hHeroes[heroIndex][availableLevel] = GetNativeCell(2);
	strcopy(g_hHeroes[heroIndex][szHero], SH_HERO_NAME_SIZE, hero);
	++g_iHeroCount;
	
	return heroIndex;
}

public int Native_SetHeroInfo(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
	
	char superpower[SH_SUPERPOWER_SIZE], help[SH_HELP_SIZE];
	GetNativeString(2, superpower, sizeof(superpower));
	GetNativeString(3, help, sizeof(help));
	
	strcopy(g_hHeroes[heroIndex][szSuperPower], SH_SUPERPOWER_SIZE, superpower);
	strcopy(g_hHeroes[heroIndex][szHelp], SH_HELP_SIZE, help);
}

public int Native_SetHeroBind(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
		
	g_hHeroes[heroIndex][requiresBind] = true;
}

public int Native_SetHeroHealth(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
	
	int health = GetNativeCell(2);
	
	if(health != 0)
		g_iHeroMaxHealth[heroIndex] = health;
}

public int Native_SetHeroArmor(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
	
	int armor = GetNativeCell(2);
	
	if(armor != 0)
		g_iHeroMaxArmor[heroIndex] = armor;
}

public int Native_SetHeroGravity(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
		
	float gravity = GetNativeCell(2);
	
	g_fHeroGravity[heroIndex] = gravity;
}

public int Native_SetHeroSpeed(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
	int weaponcount = GetNativeCell(4);
	float speed = GetNativeCell(2);
	int weapons[42]; //view_as<int>(CSGOWeapon_INCGRENADE) + 1 doesnt work because hehehehehehe fun fun fun fun
	GetNativeArray(3, weapons, weaponcount);
	
	g_fHeroMaxSpeed[heroIndex] = speed;
	if(weaponcount <= 0)
		g_bHeroSpeedWeapons[heroIndex][0] = false;
	else
	{
		g_bHeroSpeedWeapons[heroIndex][0] = true;
		for (int i = 0; i < weaponcount; i++)
			g_bHeroSpeedWeapons[heroIndex][weapons[i]] = true;
	}
}

public int Native_SetHeroDamageMultiplier(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	
	if(heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;
	
	float dmgmulti = GetNativeCell(2);
	int weaponid = GetNativeCell(3);

	g_fHeroMaxDamageMultiplier[heroIndex][weaponid] = dmgmulti;
}

public int Native_GetMaxHealth(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return 0;
	
	return g_iPlayerMaxHealth[client];
}

public int Native_GetMaxArmor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return 0;
	
	return g_iPlayerMaxArmor[client];
}

public int Native_GetMaxSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int weaponid = GetNativeCell(2);
	if(!IsValidClient(client))
		return;
	
	float speed = GetMaxSpeed(client, weaponid);
	SetNativeCellRef(3, speed);
	
}

public int Native_GetGravity(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return;
	
	float gravity = GetGravity(client);
	SetNativeCellRef(2, gravity);
}

public int Native_GetLevelCount(Handle plugin, int numParams)
{
	return g_Levels.IntValue;
}

public int Native_GetLevelExperience(Handle plugin, int numParams)
{
	int level = GetNativeCell(1);
	if(level < 0 || level > g_Levels.IntValue)
		return -1;
	
	return g_iLevelExperience[level];
}

public int Native_GetPlayerLevel(Handle plugins, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return -1;
		
	//if(g_bReadExperienceNextRound[client])
	//	return -1;
	
	return g_iPlayerLevel[client];
}

public int Native_SetPlayerLevel(Handle plugins, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return -1;
	
	int setLevel = GetNativeCell(2);
	
	if(setLevel < 0 || setLevel > g_Levels.IntValue)
		return -1;
		
	g_iPlayerExperience[client] = g_iLevelExperience[setLevel];
	DisplayPowers(client, false);
	return g_iPlayerLevel[client];
}

public int Native_GetPlayerExperience(Handle plugins, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return -1;
		
	return g_iPlayerExperience[client];
}

public int Native_SetPlayerExperience(Handle plugins, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return -1;
		
	int experience = GetNativeCell(2);
	if(GetNativeCell(3))
		LocalAddExperience(client, experience);
	else
	{
		//Set to xp, by finding what must be added to users current xp
		LocalAddExperience(client, (experience - g_iPlayerExperience[client]));
	}
	
	DisplayPowers(client, false);
	return g_iPlayerExperience[client];
	
}

public int Native_AddKillExperience(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int victim = GetNativeCell(2);
	
	if(!IsValidClient(client) || !IsValidClient(victim))
		return;
		
	LocalAddExperience(client, RoundToNearest(GetNativeCell(3) * g_iGivenExperience[victim]));
	DisplayPowers(client, false);
}

public int Native_GetHeroIndex(Handle plugin, int numParams)
{
	char hero[SH_HERO_NAME_SIZE];
	GetNativeString(1, hero, sizeof(hero));
	
	return GetHeroIndex(hero);
}

public int Native_PlayerHasHero(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return 0;
		
	int heroIndex = GetNativeCell(2);
	
	if(-1 < heroIndex < g_iHeroCount)
		return PlayerHasPower(client, heroIndex);
	
	return false;
}

public int Native_SetStun(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerAlive(client))
		return;
	
	float duration = GetNativeCell(2);
	
	if(duration > g_iPlayerStunTimer[client])
	{
		float speed = GetNativeCell(3);
		g_iPlayerStunTimer[client] = RoundToNearest(duration);
		g_fPlayerStunSpeed[client] = speed;
		SetPlayerSpeed(client, speed);
	}
}

public int Native_GetStun(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsPlayerAlive(client))
		return 0;
	
	return g_iPlayerStunTimer[client] > 0 ? 1 : 0;
}

public int Native_SetGodMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return;
		
	int ent = EntRefToEntIndex(g_iGlowEntities[client]);
	if(ent != INVALID_ENT_REFERENCE)
		AcceptEntityInput(ent, "Kill");
	g_iGlowEntities[client] = INVALID_ENT_REFERENCE;

	if (!IsPlayerAlive(client))
		return;
	
	float duration = GetNativeCell(2);
	
	if(duration > g_iPlayerGodTimer[client])
	{
		g_iPlayerGodTimer[client] = RoundToNearest(duration);
		g_iGlowEntities[client] = EntIndexToEntRef(CreateGlowEntity(client));
	}
}

public int Native_IsGodMode(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerAlive(client))
		return false;
		
	return (g_iPlayerGodTimer[client] > 0);
}

public int Native_ResetMaxSpeed(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsPlayerAlive(client))
		return;
	
	SetSpeedPowers(client);
}

public int Native_ResetGravity(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsPlayerAlive(client))
		return;
	
	SetGravityPowers(client);
}

public int Native_SetPlayerHeroCooldown(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int heroIndex = GetNativeCell(2);
	float cooldown = GetNativeCell(3);
	
	if(g_hCoolDownTimers[client][heroIndex] != INVALID_HANDLE)
		KillTimer(g_hCoolDownTimers[client][heroIndex]);
	g_hCoolDownTimers[client][heroIndex] = INVALID_HANDLE;
	
	if(!IsValidClient(client))
		return;
		
	g_bPlayerInCooldown[client][heroIndex] = true;
	DataPack pack = CreateDataPack();
	g_hCoolDownTimers[client][heroIndex] = CreateDataTimer(cooldown, Timer_Cooldown, pack);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(heroIndex);
}

public int Native_EndPlayerHeroCooldown(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int heroIndex = GetNativeCell(2);
	EndPlayerHeroCooldown(client, heroIndex);
}

public int Native_IsPlayerHeroInCooldown(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int heroIndex = GetNativeCell(2);
	return g_bPlayerInCooldown[client][heroIndex];
}

public int Native_ForceSetPlayerHeroCooldown(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int heroIndex = GetNativeCell(2);
	g_bPlayerInCooldown[client][heroIndex] = GetNativeCell(3);
	EndPlayerHeroCooldown(client, heroIndex);
}

public int Native_AddHealth(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return -1;
	
	int health = GetNativeCell(2);
	int maxHealth = GetMaxHealth(client);
	if (health == 0) 
		return 0;

	int currentHealth = GetPlayerHealth(client);

	if ( currentHealth < maxHealth ) 
	{
		int newHealth = min((currentHealth + health), maxHealth);
		SetPlayerHealth(client, newHealth);
		return newHealth - currentHealth;
	}

	return 0;
}

public int Native_AddArmor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return -1;
	
	int armor = GetNativeCell(2);
	int maxArmor = GetMaxArmor(client);
	if (armor == 0) 
		return 0;

	int currentArmor = GetPlayerArmor(client);

	if ( currentArmor < maxArmor ) 
	{
		int newArmor = min((currentArmor + armor), maxArmor);
		SetPlayerArmor(client, newArmor);
		return newArmor - currentArmor;
	}

	return 0;
}

public int Native_PlayDenySound(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
		EmitSoundToClientAny(client, DENY_SOUND);
}

public int Native_SetChangeWeaponSpeedBool(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	g_bWeaponSwitchSpeedChange[client] = GetNativeCell(2);
}

public int Native_SetHeroPrimaryWeapon(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	CSGOWeaponID weaponid = view_as<CSGOWeaponID>(GetNativeCell(2));
	g_HeroPrimaryWeapon[heroIndex] = weaponid;
}

public int Native_SetHeroSecondaryWeapon(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	CSGOWeaponID weaponid = view_as<CSGOWeaponID>(GetNativeCell(2));
	g_HeroSecondaryWeapon[heroIndex] = weaponid;
}

public int Native_GetHighestPrimaryWeaponLevel(Handle plugin, int numParams)
{
	int weaponid = 0;
	
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return view_as<int>(weaponid);
		
	int heroIndex;
	int maxLevel = 0;
	int heroLevel = 0;
	
	ArrayList weapons = new ArrayList();
	ArrayList heroes = new ArrayList();
	
	for(int i = 0; i < g_iHeroCount; i++)  
	{
		heroIndex = i;
		if(!PlayerHasPower(client, heroIndex))
			continue;
		
		if(g_HeroPrimaryWeapon[heroIndex] == CSGOWeaponID_NONE)
			continue;

		weapons.Push(view_as<int>(g_HeroPrimaryWeapon[heroIndex]));
		heroes.Push(heroIndex);
	}
	
	for (int i = 0; i < heroes.Length; i++)
	{
		heroIndex = heroes.Get(i);
		heroLevel = GetHeroLevel(heroIndex);
		
		if(heroLevel > maxLevel)
			weaponid = weapons.Get(i);
		maxLevel = max(maxLevel, heroLevel);
	}
	
	delete weapons;
	delete heroes;
	
	return weaponid;
}

public int Native_GetHighestSecondaryWeaponLevel(Handle plugin, int numParams)
{
	int weaponid = 0;
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return view_as<int>(weaponid);
		
	int heroIndex;
	int maxLevel = 0;
	int heroLevel = 0;
	
	ArrayList weapons = new ArrayList();
	ArrayList heroes = new ArrayList();
	
	for(int i = 0; i < g_iHeroCount; i++)  
	{
		heroIndex = i;
		if(!PlayerHasPower(client, heroIndex))
			continue;
		
		if(g_HeroSecondaryWeapon[heroIndex] == CSGOWeaponID_NONE)
			continue;

		weapons.Push(view_as<int>(g_HeroSecondaryWeapon[heroIndex]));
		heroes.Push(heroIndex);
	}
	
	for (int i = 0; i < heroes.Length; i++)
	{
		heroIndex = heroes.Get(i);
		heroLevel = GetHeroLevel(heroIndex);
		
		if(heroLevel > maxLevel)
			weaponid = weapons.Get(i);
		maxLevel = max(maxLevel, heroLevel);
	}
	
	delete weapons;
	delete heroes;
	
	return weaponid;
}

public int Native_GetHighestLevelHero(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return -1;
		
	int heroIndex;
	int heroLevel = 0;

	for(int i = 0; i < g_iHeroCount; i++)  
	{
		heroIndex = i;
		if(!PlayerHasPower(client, heroIndex))
			continue;

		heroLevel = max(heroLevel, GetHeroLevel(heroIndex));
	}
	
	return heroLevel;
}

public int Native_SetHeroPlayerModel(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	char szModel[PLATFORM_MAX_PATH];
	GetNativeString(2, szModel, sizeof(szModel));
	Format(g_szHeroModel[heroIndex], sizeof(g_szHeroModel[]), szModel);
}

public int Native_GetHeroPlayerModel(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	int size = GetNativeCell(3);
	SetNativeString(2, g_szHeroModel[heroIndex], size);
}

public int Native_HeroHasPlayerModel(Handle plugin, int numParams)
{
	int heroIndex = GetNativeCell(1);
	if(StrEqual(g_szHeroModel[heroIndex], "", false))
		return false;
	return true;
}

public int Native_GetHighestPlayerModelLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char szBuffer[PLATFORM_MAX_PATH];
	int heroindex = GetHighestPlayerModelLevel(client, szBuffer, sizeof(szBuffer));

	int maxlen = GetNativeCell(3);
	SetNativeString(2, szBuffer, maxlen);
	return heroindex;
}

//////////////
//	EVENTS  //
//////////////
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetEntProp(client, Prop_Data, "m_ArmorValue", g_iPlayerArmor[client]);
	//if(!g_LongTermExperience.BoolValue)
	//	g_bReadExperienceNextRound[client] = false;
		
	g_iPlayerStunTimer[client] = -1;
	g_iPlayerGodTimer[client] = -1;
	
	GetMaxHealth(client);
	GetMaxArmor(client);
	
	if(!g_bNewRoundSpawn[client])
	{
		DisplayPowers(client, true);
		
		//Set highest level hero model
		char szModel[PLATFORM_MAX_PATH];
		GetHighestPlayerModelLevel(client, szModel, sizeof(szModel));
		if(!StrEqual(szModel, "", false))
			SetEntityModel(client, szModel);
		
		Call_StartForward(g_hOnPlayerSpawned);
		Call_PushCell(client);
		Call_PushCell(false);
		Call_Finish();
		return Plugin_Continue;
	}
	
	//if(g_bReadExperienceNextRound[client])
	ReadExperience(client);
	
	DisplayPowers(client, true);
	
	//Set highest level hero model
	char szModel[PLATFORM_MAX_PATH];
	GetHighestPlayerModelLevel(client, szModel, sizeof(szModel));
	if(!StrEqual(szModel, "", false))
		SetEntityModel(client, szModel);
	
	g_bNewRoundSpawn[client] = false;
	
	Call_StartForward(g_hOnPlayerSpawned);
	Call_PushCell(client);
	Call_PushCell(true);
	Call_Finish();
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool headshot = event.GetBool("headshot");
	
	int ent = EntRefToEntIndex(g_iGlowEntities[victim]);
	if(ent != INVALID_ENT_REFERENCE)
		AcceptEntityInput(ent, "Kill");
	g_iGlowEntities[victim] = INVALID_ENT_REFERENCE;
	
	Call_StartForward(g_hOnPlayerDeath);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(headshot);
	Call_Finish();
	
	if(!IsGameLive())
		return Plugin_Continue;
	
	if(IsValidClient(attacker) && IsValidClient(victim) && attacker != victim)
	{
		if(GetClientTeam(attacker) == GetClientTeam(victim))
		{
			LocalAddExperience(attacker, -g_iGivenExperience[g_iPlayerLevel[victim]]);
		}
		else
		{
			if(headshot)
				LocalAddExperience(attacker, RoundToNearest(g_HeadshotMultiplier.FloatValue * float(g_iGivenExperience[g_iPlayerLevel[victim]])));
			else
				LocalAddExperience(attacker, g_iGivenExperience[g_iPlayerLevel[victim]]);
		}
		DisplayPowers(attacker, false);
	}
	DisplayPowers(victim, false);
	
	return Plugin_Continue;
}

public Action Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MAXPLAYERS; i++)
		g_bNewRoundSpawn[i] = true;
}

public Action Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MAXPLAYERS; i++)
		if(IsValidClient(i) && !IsFakeClient(i))
			DisplayPowers(i, true);
}

////////////////
//	COMMANDS  //
////////////////

public Action PowerKeyDown(int client, int args)
{
	char arg[65];
	GetCmdArg(0, arg, sizeof(arg));
	int key = StringToInt(arg[6]);

	if (key > SH_MAXBINDPOWERS || key <= 0 ) 
		return Plugin_Handled;

	// Make sure player isn't stunned
	if (g_iPlayerStunTimer[client] > 0) 
	{
		EmitSoundToClientAny(client, DENY_SOUND);
		return Plugin_Handled;
	}

	// Make sure there is a power bound to this key!
	if ( key > g_iPlayerBinds[client][0] ) 
	{
		EmitSoundToClientAny(client, DENY_SOUND);
		return Plugin_Handled;
	}

	int heroIndex = g_iPlayerBinds[client][key];
	if (heroIndex < 0 || heroIndex >= g_iHeroCount)
		return Plugin_Handled;

	//Make sure they are not already using this keydown
	if (g_bPowerDown[client][key]) 
		return Plugin_Handled;
		
	g_bPowerDown[client][key] = true;

	if(PlayerHasPower(client, heroIndex))
	{
		Call_StartForward(g_hOnHeroBind);
		Call_PushCell(client);
		Call_PushCell(heroIndex);
		Call_PushCell(SH_KEYDOWN);
		Call_Finish();
	}

	return Plugin_Handled;
}

public Action PowerKeyUp(int client, int args)
{
	char arg[65];
	GetCmdArg(0, arg, sizeof(arg));
	int key = StringToInt(arg[6]);

	if (key > SH_MAXBINDPOWERS || key <= 0 ) 
		return Plugin_Handled;

	// Make sure player isn't stunned (unless they were in keydown when stunned)
	if (g_iPlayerStunTimer[client] > 0 && !g_bPowerDown[client][key]) 
		return Plugin_Handled;

	//Set this key as NOT in use anymore
	g_bPowerDown[client][key] = false;
	
	// Make sure there is a power bound to this key!
	if ( key > g_iPlayerBinds[client][0] ) 
		return Plugin_Handled;

	int heroIndex = g_iPlayerBinds[client][key];
	if (heroIndex < 0 || heroIndex >= g_iHeroCount)
		return Plugin_Handled;

	if(PlayerHasPower(client, heroIndex))
	{
		Call_StartForward(g_hOnHeroBind);
		Call_PushCell(client);
		Call_PushCell(heroIndex);
		Call_PushCell(SH_KEYUP);
		Call_Finish();
	}

	return Plugin_Handled;
}

public Action Command_HeroList(int client, int args)
{
	char szBuffer[64];
	
	Menu menu = new Menu(NullMenuHandler);
	menu.SetTitle("Hero List");
	for (int i = 0; i < g_iHeroCount; i++)
	{
		Format(szBuffer, sizeof(szBuffer), "%s (%d%s) - %s", g_hHeroes[i][szHero], g_hHeroes[i][availableLevel], (g_hHeroes[i][requiresBind] ? " +Bind" : ""), g_hHeroes[i][szSuperPower]);
		menu.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_Heroes(int client, int args)
{
	int playerPowerCount = GetPowerCount(client);
	int playerLevel = g_iPlayerLevel[client];
	
	// Don't show menu if they already have enough powers
	if (playerPowerCount >= playerLevel || playerPowerCount >= g_MaxPowers.IntValue)
	{
		ReplyToCommand(client, "%t", "Too Many Powers", SH_PREFIX);
		return Plugin_Handled;
	}
	
	// Figure out how many powers a person should be able to have
	// Example: At level 10 a person can pick a max of 1 lvl 10 hero
	//		and a max of 2 lvl 9 heroes, and a max of 3 lvl 8 heroes, etc... //CSGO EDIT: this system doesnt even work for some reason...
	int lvllimit = g_Levels.IntValue;
	if (lvllimit == 0 )
		lvllimit = SH_MAXLEVELS;

	/*for(int i = 0; i <= lvllimit; i++) 
	{
		if(playerLevel >= i)
			g_iPlayerPowersLeft[client][i] = playerLevel - i + lvllimit;
		else 
			g_iPlayerPowersLeft[client][i] = 0;
	}*/
	
	// Now decrement the level powers that they've picked
	int heroIndex, heroLevel;
	/*
	for (int i = 1; i <= playerPowerCount && i <= SH_MAXLEVELS; i++) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if (heroIndex < 0 || heroIndex >= g_iHeroCount) 
			continue;
			
		heroLevel = GetHeroLevel(heroIndex);
		
		// Decrement all g_iPlayerPowersLeft by 1 for the level hero they have and below
		for (int j = heroLevel; j >= 0; j--) 
		{
			if (--g_iPlayerPowersLeft[client][j] < 0) 
				g_iPlayerPowersLeft[client][j] = 0;
				
			//If none left on this level, there should be none left on any higher levels
			if(g_iPlayerPowersLeft[client][j] <= 0 && j < SH_MAXLEVELS) 
			{
				if(g_iPlayerPowersLeft[client][j+1] != 0) 
				{
					for (int z = j; z <= g_Levels.IntValue; z++) 
					{
						g_iPlayerPowersLeft[client][z] = 0;
					}
				}
			}
		}
	}*/
	
	// OK BUILD A LIST OF HEROES THIS PERSON CAN PICK FROM
	g_iPlayerMenuChoices[client][0] = 0; // <- 0 choices so far
	int count = 0; 
	bool thisEnabled;

	for(int i = 0; i < g_iHeroCount; i++)  
	{
		heroIndex = i;
		heroLevel = GetHeroLevel(heroIndex);
		thisEnabled = false;
		if(playerLevel >= heroLevel) 
		{
			if (/*g_iPlayerPowersLeft[client][heroLevel] > 0 && */!(g_iPlayerBinds[client][0] >= g_MaxBinds.IntValue && g_hHeroes[heroIndex][requiresBind]))
				thisEnabled = true;
				
			// Don't want to present this power if the player already has it!
			if (!PlayerHasPower(client, heroIndex) && thisEnabled) 
			{
				g_iPlayerMenuChoices[client][0] = ++count;
				g_iPlayerMenuChoices[client][count] = heroIndex;
			}
		}
	}
	
	
	// show menu super power
	char menuItem[256], title[64], temp[SH_HERO_NAME_SIZE];

	int total = min(g_MaxPowers.IntValue, playerLevel);
	Format(title, 64, "%t", "Select Super Power", playerPowerCount, total);

	// OK Display the Menu
	Menu menu = new Menu(HeroMenuHandler);
	menu.SetTitle(title);
	for (int i = 0; i < g_iHeroCount; i++ ) 
	{
		// Only allow a selection from powers the player doesn't have
		if (i >= g_iPlayerMenuChoices[client][0]) 
			continue;
			
		heroIndex = g_iPlayerMenuChoices[client][i+1];
		heroLevel = GetHeroLevel(heroIndex);
		IntToString(heroIndex, temp, sizeof(temp));
		Format(menuItem, sizeof(menuItem), "%s (%d%s) - %s", g_hHeroes[heroIndex][szHero], heroLevel, (g_hHeroes[heroIndex][requiresBind] ? " +Bind" : ""), g_hHeroes[heroIndex][szSuperPower]);
		
		menu.AddItem(temp, menuItem);
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_Help(int client, int args)
{
	for (int i = 0; i < SH_MAXLEVELS; i++)
		PrintToServer("%d", g_iLevelExperience[i]);
}

public Action Command_SetLevel(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "%s %t: \x04sm_shsetlevel <name> <level>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char arg[65], arg2[16];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int setlevel = StringToInt(arg2);
	
	if(setlevel == 0 && arg2[0] != '0')
	{
		ReplyToCommand(client, "%s %t: \x04sm_shsetlevel <name> <level>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1];
	int target_count;
	
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS + 1,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if (setlevel < 0 || setlevel > g_Levels.IntValue) 
	{
		ReplyToCommand(client, "%t", "Max Level", SH_PREFIX, g_Levels.IntValue);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		g_iPlayerExperience[target_list[i]] = g_iLevelExperience[setlevel];
		DisplayPowers(target_list[i], true);
		ReplyToCommand(client, "%t", "Set Level", SH_PREFIX, target_list[i], setlevel);
	}
	return Plugin_Handled;
}

public Action Command_SetExperience(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "%s %t: \x04sm_shsetxp <name> <experience>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char arg[65], arg2[16];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int setExperience = StringToInt(arg2);
	
	if(setExperience == 0 && arg2[0] != '0')
	{
		ReplyToCommand(client, "%s %t: \x04sm_shsetxp <name> <experience>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1];
	int target_count;
	
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS + 1,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		g_iPlayerExperience[target_list[i]] = setExperience;
		DisplayPowers(target_list[i], false);
		ReplyToCommand(client, "%t", "Set Experience", SH_PREFIX, target_list[i], setExperience);
	}
	return Plugin_Handled;
}

public Action Command_AddExperience(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "%s %t: \x04sm_shaddxp <name> <experience>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char arg[65], arg2[16];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int setExperience = StringToInt(arg2);
	
	if(setExperience == 0 && arg2[0] != '0')
	{
		ReplyToCommand(client, "%s %t: \x04sm_shaddxp <name> <experience>", SH_PREFIX, "Usage");
		return Plugin_Handled;
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS + 1];
	int target_count;
	
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS + 1,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		g_iPlayerExperience[target_list[i]] += setExperience;
		DisplayPowers(target_list[i], false);
		ReplyToCommand(client, "%t", "Set Experience", SH_PREFIX, target_list[i], g_iPlayerExperience[target_list[i]]);
	}
	return Plugin_Handled;
}

public Action Command_Drop(int client, int args)
{
	char arg[65];
	GetCmdArgString(arg, sizeof(arg));
	DropPower(client, arg);
	return Plugin_Handled;
}

public Action Command_PlayerInfo(int client, int args)
{
	Menu menu = new Menu(PlayerSkillsMenuHandler);
	menu.SetTitle("Players");
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			char szName[MAX_NAME_LENGTH + 16], szClientID[5];
			int level = GetPlayerLevel(i);
			Format(szName, sizeof(szName), "%N (Level: %d)", i, level);
			Format(szClientID, sizeof(szClientID), "%d", i);
			menu.AddItem(szClientID, szName);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_MyHeroes(int client, int args)
{
	char szBuffer[32];
	int level = GetPlayerLevel(client);
	int heroIndex, playerPowerCount;
	playerPowerCount = GetPowerCount(client);
	
	char menuItem[64];
	Menu menu = new Menu(NullMenuHandler);
	Format(szBuffer, sizeof(szBuffer), "%t (%t: %d)", "My Heroes", "Level", level);
	menu.SetTitle(szBuffer);
	for (int i = 1; i <= playerPowerCount; i++)
	{
		heroIndex = g_iPlayerPowers[client][i];
		Format(menuItem, sizeof(menuItem), "%s (%d%s) - %s", g_hHeroes[heroIndex][szHero], g_hHeroes[heroIndex][availableLevel], (g_hHeroes[heroIndex][requiresBind] ? " +Bind" : ""), g_hHeroes[heroIndex][szSuperPower]);
		menu.AddItem("", menuItem, ITEMDRAW_DISABLED);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_WhoHas(int client, int args)
{
	char arg[65];
	GetCmdArgString(arg, sizeof(arg));
	int heroIndex = GetHeroIndex(arg);
	
	if(heroIndex == -1)
	{
		ReplyToCommand(client, "%t", "Invalid Hero", SH_PREFIX, arg);
		return Plugin_Handled;
	}
	
	char menuItem[64], title[16 + SH_HERO_NAME_SIZE];
	Format(title, sizeof(title), "%t", "Who Has", arg);
	Menu menu = new Menu(NullMenuHandler);

	menu.SetTitle(title);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(PlayerHasPower(i, heroIndex))
			{
				int level = GetPlayerLevel(i);
				Format(menuItem, sizeof(menuItem), "%N (%t: %d)", i, "Level", level);
				menu.AddItem("", menuItem, ITEMDRAW_DISABLED);
			}
		}
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_ClearHeroes(int client, int args)
{
	if(GetPlayerLevel(client) == 0)
		return Plugin_Handled;
		
	if (!g_DropAlive.BoolValue && IsPlayerAlive(client)) 
	{
		PrintToChat(client, "%t", "Not Allowed Drop", SH_PREFIX);
		return Plugin_Handled;
	}
	
	// OK to fire if mod is off since we want heroes to clean themselves up
	g_iPlayerPowers[client][0] = 0;
	g_iPlayerBinds[client][0] = 0;

	int heroIndex;

	// Clear the power before sending the drop init
	for (int i = 1; i <= g_Levels.IntValue && i <= SH_MAXLEVELS; i++ ) 
	{
		// Save heroid for init forward
		heroIndex = g_iPlayerPowers[client][i];

		// Clear All Power slots for player
		g_iPlayerPowers[client][i] = -1;

		// Only send drop on heroes user has
		if ( heroIndex != -1) 
			InitializeHero(client, heroIndex, SH_HERO_DROP); // Disable this power
	}

	DisplayPowers(client, true);
	Command_Heroes(client, 0);
	
	PrintToChat(client, "%t", "Powers Cleared", SH_PREFIX);
	return Plugin_Handled;
}

/////////////////////
//	MENU HANDLERS  //
/////////////////////
public int NullMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

public int PlayerSkillsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szInfo[5], szName[MAX_NAME_LENGTH + 32];
			GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
			int client = StringToInt(szInfo);
			int level = GetPlayerLevel(client);
			int heroIndex, playerPowerCount;
			playerPowerCount = GetPowerCount(client);
			
			char menuItem[64];
			Menu menu2 = new Menu(NullMenuHandler);
			Format(szName, sizeof(szName), "%N' Heroes (Level: %d)", client, level);
			menu2.SetTitle(szName);
			for (int i = 1; i <= playerPowerCount; i++)
			{
				heroIndex = g_iPlayerPowers[client][i];
				Format(menuItem, sizeof(menuItem), "%s (%d%s) - %s", g_hHeroes[heroIndex][szHero], g_hHeroes[heroIndex][availableLevel], (g_hHeroes[heroIndex][requiresBind] ? " +Bind" : ""), g_hHeroes[heroIndex][szSuperPower]);
				menu2.AddItem("", menuItem, ITEMDRAW_DISABLED);
			}
			menu2.ExitButton = true;
			menu2.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

public int HeroMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szInfo[SH_HERO_NAME_SIZE];
			GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
			
			int heroIndex = StringToInt(szInfo);
			
			// Hero was Picked!
			int playerPowerCount = GetPowerCount(param1);
			if (playerPowerCount >= g_Levels.IntValue || playerPowerCount >= g_MaxPowers.IntValue) 
				return 0;
			
			//Crash check
			if(heroIndex < 0 || heroIndex >= g_iHeroCount)
				return 0;
			
			//int heroLevel = GetHeroLevel(heroIndex);
			if ((g_iPlayerBinds[param1][0] >= g_MaxBinds.IntValue && g_hHeroes[heroIndex][requiresBind])) 
			{
				PrintToChat(param1, "%t", "Too Many Bind Heroes", SH_PREFIX, g_MaxBinds.IntValue);
				Command_Heroes(param1, 0);
				return 0;
			}
			/*else if (g_iPlayerPowersLeft[param1][heroLevel] <= 0) 
			{
				PrintToChat(param1, "%t", "Too Many High Level Heroes", SH_PREFIX);
				Command_Heroes(param1, 0);
				return 0;
			}
			*/
		
			char message[256];
			if (!g_hHeroes[heroIndex][requiresBind]) 
				Format(message, sizeof(message), "AUTOMATIC POWER: %s\n%s", g_hHeroes[heroIndex][szSuperPower], g_hHeroes[heroIndex][szHelp]);
			else
				Format(message, sizeof(message), "BIND KEY TO '+POWER%d': %s\n%s", g_iPlayerBinds[param1][0] + 1, g_hHeroes[heroIndex][szSuperPower], g_hHeroes[heroIndex][szHelp]);
		
			// Show the Hero Picked
			SetHudTextParams(0.35, 0.15, 8.0, 255, 255, 0, 255);
			ShowSyncHudText(param1, g_hHeroHudSync, "%s", message);
		
			// Bind Keys / Set Powers
			g_iPlayerPowers[param1][0] = playerPowerCount + 1;
			g_iPlayerPowers[param1][playerPowerCount + 1] = heroIndex;
		
			//Init This Hero!
			InitializeHero(param1, heroIndex, SH_HERO_ADD);
			DisplayPowers(param1, true);
		
			// Show the Menu Again if they don't have enough skills yet!
			int playerLevel = g_iPlayerLevel[param1];
			
			if (playerPowerCount < playerLevel || playerPowerCount < g_MaxPowers.IntValue)
				Command_Heroes(param1, 0);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

//////////////
// FORWARDS //
//////////////
public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	InitializePlayer(client);
	return true;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnPlayerSwitchWeapon);
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
		LoadData(client);
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client))
		WriteData(client);
		
	int ent = EntRefToEntIndex(g_iGlowEntities[client]);
	if(ent != INVALID_ENT_REFERENCE)
		AcceptEntityInput(ent, "Kill");
	g_iGlowEntities[client] = INVALID_ENT_REFERENCE;
}

public void OnMapStart()
{
	CreateTables();
	
	AddFileToDownloadsTable("sound/superheromod/deny.mp3");
	AddFileToDownloadsTable("sound/superheromod/level.mp3");
	PrecacheSoundAny(DENY_SOUND, true);
	PrecacheSoundAny(LEVEL_SOUND, true);
	
	PrecacheModel(SH_DEFAULT_MODEL_CT, true);
	PrecacheModel(SH_DEFAULT_MODEL_T, true);
}

//////////////
//	TIMERS  //
//////////////

public Action Timer_All(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++ ) 
	{
		if (IsValidClient(i) && IsPlayerAlive(i)) 
		{
			// Switches are faster but we don't want to do anything with -1
			switch(g_iPlayerStunTimer[i]) 
			{
				case -1: 
				{
					/*Do nothing*/
				}
				case 0: 
				{
					g_iPlayerStunTimer[i] = -1;
					SetSpeedPowers(i);
				}
				default: 
				{
					g_iPlayerStunTimer[i]--;
					//g_fPlayerStunSpeed[i] = GetMaxSpeed(i); //is this really needed?
				}
			}

			switch(g_iPlayerGodTimer[i]) 
			{
				case -1: 
				{
					/*Do nothing*/
				}
				case 0: 
				{
					g_iPlayerGodTimer[i] = -1;
					int ent = EntRefToEntIndex(g_iGlowEntities[i]);
					if(ent != INVALID_ENT_REFERENCE)
						AcceptEntityInput(ent, "Kill");
					g_iGlowEntities[i] = INVALID_ENT_REFERENCE;
				}
				default: 
				{
					g_iPlayerGodTimer[i]--;
				}
			}
		}
		else 
		{
			g_iPlayerStunTimer[i] = -1;
			g_iPlayerGodTimer[i] = -1;
		}
	}
}

public Action Timer_Cooldown(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int heroIndex = pack.ReadCell();

	g_bPlayerInCooldown[client][heroIndex] = false;
	g_hCoolDownTimers[client][heroIndex] = INVALID_HANDLE;
	return Plugin_Stop;
}

///////////
// HOOKS //
///////////
public Action OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(g_iPlayerGodTimer[victim] > 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if(!IsValidClient(attacker))
		return Plugin_Continue;
		
	char classname[32];
	if(weapon > 1)
		GetEntityClassname(weapon, classname, sizeof(classname));
	else
	{
		if(damagetype & DMG_BLAST || damagetype & DMG_BLAST_SURFACE)
			Format(classname, sizeof(classname), "weapon_hegrenade");
		else if(damagetype & DMG_BURN)
		{
			if(GetClientTeam(attacker) == CS_TEAM_T)
				Format(classname, sizeof(classname), "weapon_molotov");
			else if(GetClientTeam(attacker) == CS_TEAM_CT)
				Format(classname, sizeof(classname), "weapon_incgrenade");
			else
				Format(classname, sizeof(classname), "weapon_molotov");
		}
	}
	
	DataPack pack = CreateDataPack();
	RequestFrame(OnPlayerTakeDamagePost, pack);
	pack.WriteCell(GetClientUserId(victim));
	pack.WriteCell(GetClientUserId(attacker));
	pack.WriteCell(damagetype);
	pack.WriteCell(((weapon < 1) ? -1 : EntIndexToEntRef(weapon)));
	pack.WriteCell(GetEntProp(victim, Prop_Data, "m_iHealth"));
	pack.WriteCell(GetEntProp(victim, Prop_Data, "m_ArmorValue"));
	
	int weaponid = view_as<int>(WeaponClassNameToCSWeaponID(classname));
	
	if(!weaponid)
		return Plugin_Continue;
	
	float dmgmult = GetMaxDamageMultiplier(attacker, weaponid);
	damage *= dmgmult;
	
	Call_StartForward(g_hOnPlayerTakeDamage);
	Call_PushCell(victim);
	Call_PushCellRef(attacker);
	Call_PushCellRef(inflictor);
	Call_PushCellRef(damage);
	Call_PushCellRef(damagetype);
	Call_PushCellRef(weapon);
	Call_PushArray(damageForce, sizeof(damageForce));
	Call_PushArray(damagePosition, sizeof(damagePosition));
	Call_Finish();
	
	return Plugin_Changed;
}

public void OnPlayerTakeDamagePost(DataPack pack)
{
	pack.Reset();
	int victim = GetClientOfUserId(pack.ReadCell());
	int attacker = GetClientOfUserId(pack.ReadCell());
	if(!IsValidClient(victim))
		return;
		
	int damagetype = pack.ReadCell();
	int ent = pack.ReadCell();
	int weapon = INVALID_ENT_REFERENCE;
	if(ent > 0)
		weapon = EntRefToEntIndex(weapon);
		
	int oldHealth = pack.ReadCell();
	int oldArmor = pack.ReadCell();
	
	int newHealth = GetEntProp(victim, Prop_Data, "m_iHealth");
	int newArmor = GetEntProp(victim, Prop_Data, "m_ArmorValue");
	
	int healthtaken = oldHealth - newHealth;
	int armortaken = oldArmor - newArmor;
	
	g_iPlayerArmor[victim] = g_iPlayerArmor[victim] - armortaken;
	int iarmor = g_iPlayerArmor[victim];
	clamp(iarmor, 0, 100);
	if(g_iPlayerArmor[victim] > 100)
		SetEntProp(victim, Prop_Data, "m_ArmorValue", 100);
	else
		SetEntProp(victim, Prop_Data, "m_ArmorValue", g_iPlayerArmor[victim]);
		
	Call_StartForward(g_hOnPlayerTakeDamagePost);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushCell(damagetype);
	Call_PushCell(weapon);
	Call_PushCell(healthtaken);
	Call_PushCell(armortaken);
	Call_Finish();
}

public Action OnPlayerSwitchWeapon(int client, int weapon)
{
	if(IsPlayerAlive(client) && g_bWeaponSwitchSpeedChange[client])
		SetSpeedPowers(client);
}

public Action SetTransmit(int entity, int client)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(owner == client)
		return Plugin_Handled;
	return Plugin_Continue;
}
/////////////////
// HERO STOCKS //
/////////////////
stock int GetHeroIndex(const char[] heroName)
{
	for (int i = 0; i < g_iHeroCount; i++)
	{
		if(StrEqual(heroName, g_hHeroes[i][szHero], false))
			return i;
	}
	return -1;
}

stock bool PlayerHasPower(int client, int heroIndex)
{
	int playerPowerCount = GetPowerCount(client);
	for (int i = 1; i <= playerPowerCount && i <= SH_MAXLEVELS; i++)
		if(g_iPlayerPowers[client][i] == heroIndex)
			return true;
	return false;
}

stock void EndPlayerHeroCooldown(int client, int heroIndex)
{
	if(g_hCoolDownTimers[client][heroIndex] != INVALID_HANDLE)
		KillTimer(g_hCoolDownTimers[client][heroIndex]);
	g_hCoolDownTimers[client][heroIndex] = INVALID_HANDLE;
	g_bPlayerInCooldown[client][heroIndex] = false;
}

stock int GetHeroLevel(int heroIndex)
{
	return g_hHeroes[heroIndex][availableLevel];
}

stock int GetPowerCount(int client)
{
	return max(g_iPlayerPowers[client][0], 0);
}

public int GetHighestPlayerModelLevel(int client, char[] szbuffer, int maxlen)
{
	if(!IsValidClient(client))
		return -1;
		
	int heroIndex = 0; 
	int finalHeroIndex = -1;

	for(int i = 0; i < g_iHeroCount; i++)  
	{
		heroIndex = i;
		if(!PlayerHasPower(client, heroIndex))
			continue;
		
		if(StrEqual(g_szHeroModel[heroIndex], "", false))
			continue;
		
		if(finalHeroIndex == -1)
			finalHeroIndex = heroIndex;
			
		if(GetHeroLevel(heroIndex) > GetHeroLevel(finalHeroIndex))
			finalHeroIndex = heroIndex;
	}
	
	if(finalHeroIndex >= 0)
		Format(szbuffer, maxlen, g_szHeroModel[finalHeroIndex]);
	return finalHeroIndex;
}

stock void InitializePlayer(int client)
{
	if(!IsValidClient(client))
		return;
		
	g_iPlayerExperience[client] = 0;
	g_iPlayerPowers[client][0] = 0;
	g_iPlayerBinds[client][0] = 0;
	g_iPlayerStunTimer[client] = -1;
	g_iPlayerGodTimer[client] = -1;
	SetLevel(client, 0);
	g_iPlayerFlags[client] = 0;
	g_bNewRoundSpawn[client] = true;
	//g_bReadExperienceNextRound[client] = g_LongTermExperience.BoolValue;
	g_bChangedHeroes[client] = false;
	g_bWeaponSwitchSpeedChange[client] = true;
	g_iPlayerMaxHealth[client] = 100;
	g_iPlayerMaxArmor[client] = 0;
	g_iPlayerArmor[client] = 0;
	g_fPlayerStunSpeed[client] = 1.0;
	for (int i = 0; i <= SH_MAXBINDPOWERS; i++)
		g_bPowerDown[client][i] = false;
		
	for (int i = 0; i <= SH_MAXHEROES; i++)
		g_bPlayerInCooldown[client][i] = false;
	
	int heroIndex;

	// Clear the power before sending the drop init
	for (int i = 1; i <= g_Levels.IntValue && i <= SH_MAXLEVELS; i++ ) 
	{
		// Save heroid for init forward
		heroIndex = g_iPlayerPowers[client][i];

		// Clear All Power slots for player
		g_iPlayerPowers[client][i] = -1;

		// Only send drop on heroes user has
		if ( heroIndex != -1) 
			InitializeHero(client, heroIndex, SH_HERO_DROP); // Disable this power
	}
}

stock void InitializeHero(int client, int heroIndex, int mode)
{
	if(!IsValidClient(client))
		return;
	// OK to pass this through when mod off... Let's heroes cleanup after themselves
	// init event is used to let hero know when a player has selected OR deselected a hero's power

	// Reset Hero hp/ap/speed/grav if needed
	if (mode == SH_HERO_DROP && IsPlayerAlive(client)) 
	{
		//reset all values
		if (g_iHeroMaxHealth[heroIndex] != 0 ) 
		{
			int newHealth = GetMaxHealth(client);

			if (GetPlayerHealth(client) > newHealth ) 
			{
				// Assume some damage for doing this?
				// Don't want players picking Superman let's say then removing his power - and trying to keep the HPs
				// If they do that - feel free to lose some hps
				// Also - Superman starts with around 150 Person could take some damage (i.e. reduced to 110 )
				// but then clear powers and start at 100 - like 40 free hps for doing that, trying to avoid exploits
				SetPlayerHealth(client, newHealth - (newHealth / 4));
			}
		}

		if (g_iHeroMaxArmor[heroIndex] != 0) 
		{
			int newArmor = GetMaxArmor(client);
			if (GetPlayerArmor(client) > newArmor) 
			{
				// Remove Armor for doing this
				SetPlayerArmor(client, newArmor);
			}
		}

		if (g_fHeroMaxSpeed[heroIndex] != 0)
			SetSpeedPowers(client);

		if (g_fHeroGravity[heroIndex] != 0 )
			SetGravityPowers(client);
		
		char szModel[PLATFORM_MAX_PATH];
		int playerModelHeroIndex = GetHighestPlayerModelLevel(client, szModel, sizeof(szModel));
		if(playerModelHeroIndex >= 0)
		{
			if(!StrEqual(szModel, "", false))
				SetEntityModel(client, szModel);
		}
		else
		{
			int team = GetClientTeam(client);
			if(team == CS_TEAM_T)
				SetEntityModel(client, SH_DEFAULT_MODEL_T);
			else if(team == CS_TEAM_CT)
				SetEntityModel(client, SH_DEFAULT_MODEL_CT);
		}
	}
		
	//If the player equips a hero that has a player model while he already has a custom player model, equip the hero model that is the highest level
	char szModel[PLATFORM_MAX_PATH];
	int playerModelHeroIndex = GetHighestPlayerModelLevel(client, szModel, sizeof(szModel));
	if(playerModelHeroIndex >= 0)
	{
		if(!StrEqual(szModel, "", false))
			SetEntityModel(client, szModel);
	}

	Call_StartForward(g_hOnHeroInitialized);
	Call_PushCell(client);
	Call_PushCell(heroIndex);
	Call_PushCell(mode);
	Call_Finish();

	g_bChangedHeroes[client] = true;
}

stock void DisplayPowers(int client, bool setThePowers)
{
	if(!IsValidClient(client))
		return;

	//if (g_bReadExperienceNextRound[client]) 
	//{
	//	PrintToChat(client, "%t", "Experience Load Next Round", SH_PREFIX);
	//	return;
	//}

	// OK Test What Level this Fool is
	TestLevel(client);

	char message[128];
	int heroIndex, count, playerLevel, playerPowerCount;

	count = 0;
	playerLevel = g_iPlayerLevel[client];

	if (playerLevel < g_Levels.IntValue)
		Format(message, sizeof(message), "%s LVL: %d/%d XP: (%d/%d)", SH_PREFIX, playerLevel, g_Levels.IntValue, g_iPlayerExperience[client], g_iLevelExperience[playerLevel + 1]);
	else
		Format(message, sizeof(message), "%s LVL: %d/%d XP: (%d)", SH_PREFIX, playerLevel, g_Levels.IntValue, g_iPlayerExperience[client]);

	//Resets All Bind assignments
	for (int i = 1; i <= g_MaxBinds.IntValue; i++) 
		g_iPlayerBinds[client][i] = -1;

	playerPowerCount = GetPowerCount(client);

	for (int i = 1; i <= g_Levels.IntValue && i <= playerPowerCount; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if ( -1 < heroIndex < g_iHeroCount ) 
		{
			// 2 types of heroes - auto heroes and bound heroes...
			// Bound Heroes require special work...
			if (g_hHeroes[heroIndex][requiresBind]) 
			{
				count++;
				if (count <= 3) 
				{
					if (message[0] != '\0')
						Format(message, sizeof(message), "%s ", message);
						
					Format(message, sizeof(message), "%s %d=%s", message, count, g_hHeroes[heroIndex]);
				}
				// Make sure this players keys are bound correctly
				if (count <= g_MaxBinds.IntValue && count <= SH_MAXBINDPOWERS) 
				{
					g_iPlayerBinds[client][count] = heroIndex;
					g_iPlayerBinds[client][0] = count;
				}
				else 
				{
					ClearPower(client, i);
				}
			}
		}
	}

	if (IsPlayerAlive(client)) 
	{
		PrintToChat(client, message);
		if (setThePowers)
			SetPowers(client);
	}
}

stock void SetPowers(int client)
{
	if (!IsPlayerAlive(client)) 
		return;

	SetSpeedPowers(client);
	SetArmorPowers(client);
	SetGravityPowers(client);
	SetHealthPowers(client);
}

stock void SetSpeedPowers(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)/* || g_bReadExperienceNextRound[client]*/)
		return;

	if (g_iPlayerStunTimer[client] > 0 ) 
	{
		float stunSpeed = g_fPlayerStunSpeed[client];
		SetPlayerSpeed(client, stunSpeed);
		return;
	}

	//float oldSpeed = GetPlayerSpeed(client);
	
	char classname[32];
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon > 0)
		GetEntityClassname(weapon, classname, sizeof(classname));
	int weaponid = view_as<int>(WeaponClassNameToCSWeaponID(classname));
	
	float newSpeed = GetMaxSpeed(client, weaponid);
	
	// OK SET THE SPEED
	//if (newSpeed != oldSpeed) 
	SetPlayerSpeed(client, newSpeed);
}

stock void SetGravityPowers(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)/* || g_bReadExperienceNextRound[client]*/)
		return;

	float newGravity = GetGravity(client);
	SetPlayerGravity(client, newGravity);
}

stock void SetHealthPowers(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)/* || g_bReadExperienceNextRound[client]*/)
		return;

	int oldHealth = GetPlayerHealth(client);
	int newHealth = GetMaxHealth(client);

	// Can't get health in the middle of a round UNLESS you didn't get shot...
	if ( oldHealth < newHealth && oldHealth >= 100 )
		SetPlayerHealth(client, newHealth);
}

stock void SetArmorPowers(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)/* || g_bReadExperienceNextRound[client]*/)
		return;

	int oldArmor = GetPlayerArmor(client);
	int newArmor = GetMaxArmor(client);

	// Little check for armor system
	if ( oldArmor != 0 || oldArmor >= newArmor ) 
		return;

	// Set the armor to the correct value
	SetPlayerArmor(client, newArmor);
}

stock int GetMaxHealth(int client)
{
	static int returnHealth, i;
	returnHealth = 100;

	static int heroIndex, playerPowerCount;
	playerPowerCount = GetPowerCount(client);
	
	for (i = 1; i <= playerPowerCount; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		// Test crash gaurd
		if ( -1 < heroIndex < g_iHeroCount ) 
			returnHealth = max(returnHealth, g_iHeroMaxHealth[heroIndex]);
	}

	// Other plugins might use this, even maps
	SetEntProp(client, Prop_Data, "m_iMaxHealth", returnHealth);
	return g_iPlayerMaxHealth[client] = returnHealth;
}

stock int GetMaxArmor(int client)
{
	static int heroIndex, returnArmor, i, playerPowerCount;
	returnArmor = 0;
	playerPowerCount = GetPowerCount(client);

	for ( i = 1; i <= playerPowerCount; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if ( -1 < heroIndex < g_iHeroCount )
			returnArmor = max(returnArmor, g_iHeroMaxArmor[heroIndex]);
	}

	return g_iPlayerMaxArmor[client] = returnArmor;
}

stock float GetMaxSpeed(int client, int weaponid)
{
	static float returnSpeed, heroSpeed;
	static int playerPowerCount, heroIndex, i;
	returnSpeed = 1.0;
	playerPowerCount = GetPowerCount(client);

	for ( i = 1; i <= playerPowerCount; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if ( -1 < heroIndex < g_iHeroCount) 
		{
			heroSpeed = g_fHeroMaxSpeed[heroIndex];
			if ( heroSpeed > 0.0 ) 
			{
				if(g_bHeroSpeedWeapons[heroIndex][0])
				{
					for (int j = 0; j <= view_as<int>(CSGOWeaponID_INCGRENADE); j++)
					{
						if(weaponid == j && g_bHeroSpeedWeapons[heroIndex][j])
						{
							returnSpeed = floatmax(returnSpeed, heroSpeed);
						}
					}
				}
				else
				{
					returnSpeed = floatmax(returnSpeed, heroSpeed);
				}
			}
		}
	}

	return returnSpeed;
}

stock float GetGravity(int client)
{
	static float returnGravity, heroGravity;
	static int i, heroIndex, playerPowerCount;
	returnGravity = 1.0;
	playerPowerCount = GetPowerCount(client);

	for (i = 1; i <= playerPowerCount; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if (-1 < heroIndex < g_iHeroCount) 
		{
			heroGravity = g_fHeroGravity[heroIndex];
			if (heroGravity > 0.0)
				returnGravity = floatmin(returnGravity, heroGravity);
		}
	}

	return returnGravity;
}

stock float GetMaxDamageMultiplier(int client, int weaponid)
{
	int playerPowerCount, heroIndex;
	playerPowerCount = GetPowerCount(client);
	
	float returnDamage = 1.0;
	
	for (int i = 1; i <= playerPowerCount; i++)
	{
		heroIndex = g_iPlayerPowers[client][i];
		if(-1 < heroIndex < g_iHeroCount)
			returnDamage = floatmax(returnDamage, g_fHeroMaxDamageMultiplier[heroIndex][weaponid]);
	}
	
	return returnDamage;
}

stock CSGOWeaponID GetHighestLevelPrimaryWeapon(int client)
{
	CSGOWeaponID g_PrimaryWeapon[MAXPLAYERS + 1][SH_MAXHEROES + 1];	
CSGOWeaponID g_SecondaryWeapon[MAXPLAYERS + 1][SH_MAXHEROES + 1];	


	

}

stock int GetPlayerLevel(int client)
{
	int newLevel = 0;

	for (int i = g_Levels.IntValue; i >= 0 ;i--) 
	{
		if (g_iLevelExperience[i] <= g_iPlayerExperience[client]) 
		{
			newLevel = i;
			break;
		}
	}

	// Now make sure this level is between the ranges
	int minLevel = 0; //MIN LEVLE ??????????????????????????????

	if ( newLevel < minLevel/* && !g_bReadExperienceNextRound[client]*/) 
	{
		newLevel = minLevel;
		g_iPlayerExperience[client] = g_iLevelExperience[newLevel];
	}

	if (newLevel > g_Levels.IntValue) 
		newLevel = g_Levels.IntValue;

	return newLevel;
}

stock void ReadExperience(int client)
{
	if (g_LongTermExperience.BoolValue) 
		return;

	// Players XP already loaded, no need to do this again
	//if (!g_bReadExperienceNextRound[client]) 
	//	return;

	static char savekey[32];

	// Get Key
	if (!GetSaveKey(client, savekey))
		return;

	// Check Memory Table First
	if (MemoryTableRead(client, savekey)) 
	{
		//debugMsg(id, 8, "XP Data loaded from memory table")
	}
	//else if ( LoadExperience(client, savekey) )  //MYSQL CODE
	//{
		//debugMsg(id, 8, "XP Data loaded from Vault, nVault, or MySQL save")
	//}
	else 
	{
		// XP Not able to load, will try again next round
		return;
	}

	//g_bReadExperienceNextRound[client] = false;
	MemoryTableUpdate(client);
	DisplayPowers(client, false);
}

stock void SetLevel(int client, int newLevel)
{
	// MAKE SURE THE VAR IS SET CORRECTLY...
	g_iPlayerLevel[client] = newLevel;
}

stock void TestLevel(int client)
{
	int newLevel, oldLevel, playerPowerCount;
	oldLevel = g_iPlayerLevel[client];
	newLevel = GetPlayerLevel(client);

	// Play a Sound on Level Change!
	if ( oldLevel != newLevel ) 
	{
		SetLevel(client, newLevel);
		if (newLevel != 0)
			EmitSoundToClientAny(client, LEVEL_SOUND);
			
	}

	// Make sure player is allowed to have the heroes in their list
	if ( newLevel < oldLevel ) 
	{
		int heroIndex;
		playerPowerCount = GetPowerCount(client);
		for ( int i = 1; i <= g_Levels.IntValue && i <= playerPowerCount; i++ ) 
		{
			heroIndex = g_iPlayerPowers[client][i];
			if (-1 < heroIndex < g_iHeroCount) 
			{
				if (GetHeroLevel(heroIndex) > g_iPlayerLevel[client]) 
				{
					ClearPower(client, i);
					i--;
				}
			}
		}
	}

	// Uh oh - Rip away a level from powers if they loose a level
	playerPowerCount = GetPowerCount(client);
	if ( playerPowerCount > newLevel ) 
	{
		for (int i = newLevel + 1; i <= playerPowerCount && i <= SH_MAXLEVELS; i++) 
			ClearPower(client, i); // Keep clearing level above cuz levels shift!
			
		g_iPlayerPowers[client][0] = newLevel;
	}

	// Go ahead and write this so it's not lost - hopefully no server crash!
	MemoryTableUpdate(client);
}

stock void ClearPower(int client, int level)
{
	int heroIndex = g_iPlayerPowers[client][level];

	if (heroIndex < 0 || heroIndex >= g_iHeroCount)
		return;

	// Ok shift over any levels higher
	int playerPowerCount = GetPowerCount(client);
	for (int i = level; i <= playerPowerCount && i <= SH_MAXLEVELS; i++ ) 
	{
		if (i != SH_MAXLEVELS) 
			g_iPlayerPowers[client][i] = g_iPlayerPowers[client][i + 1];
	}

	int powers = g_iPlayerPowers[client][0]--;
	
	if (powers < 0)
		g_iPlayerPowers[client][0] = 0;

	//Clear out powers higher than powercount
	for ( int i = powers + 1; i <= g_Levels.IntValue && i <= SH_MAXLEVELS; i++ )
		g_iPlayerPowers[client][i] = -1;

	// Disable this power
	InitializeHero(client, heroIndex, SH_HERO_DROP);

	// Display Levels will have to rebind this heroes powers...
	g_iPlayerBinds[client][0] = 0;
}

stock void MemoryTableUpdate(int client)
{
	if (!g_LongTermExperience.IntValue) 
		return;
	//if (g_bReadExperienceNextRound[client]) 
	//	return;

	// Update this XP line in Memory Table
	char steamid[32];
	static int i, powerCount;

	if (!GetSaveKey(client, steamid)) 
		return;

	// Check to see if there's already another id in that slot... (disconnected etc.)
	if (g_szMemoryTableKeys[client][0] != '\0' && !StrEqual(g_szMemoryTableKeys[client], steamid, false)) 
	{
		if (g_iMemoryTableCount < SH_MEMORY_TABLE_SIZE) 
		{
			strcopy(g_szMemoryTableKeys[g_iMemoryTableCount], sizeof(g_szMemoryTableKeys[]), g_szMemoryTableKeys[client]);
			strcopy(g_szMemoryTableNames[g_iMemoryTableCount], sizeof(g_szMemoryTableNames[]), g_szMemoryTableNames[client]);
			g_iMemoryTableExperience[g_iMemoryTableCount] = g_iMemoryTableExperience[client];
			g_iMemoryTableFlags[g_iMemoryTableCount] = g_iMemoryTableFlags[client];
			powerCount = g_iMemoryTablePowers[client][0];
			for (i = 0; i <= powerCount && i <= SH_MAXLEVELS; i++) 
			{
				g_iMemoryTablePowers[g_iMemoryTableCount][i] = g_iMemoryTablePowers[client][i];
			}
			g_iMemoryTableCount++; // started with position 33
		}
	}

	// OK copy to table now - might have had to write 1 record...
	strcopy(g_szMemoryTableKeys[client], sizeof(g_szMemoryTableKeys[]), steamid);
	GetClientName(client, g_szMemoryTableNames[client], sizeof(g_szMemoryTableNames[]));
	g_iMemoryTableExperience[client] = g_iPlayerExperience[client];
	g_iMemoryTableFlags[client] = g_iPlayerFlags[client];

	powerCount = GetPowerCount(client);
	for (i = 0; i <= powerCount && i <= SH_MAXLEVELS; i++)
		g_iMemoryTablePowers[client][i] = g_iPlayerPowers[client][i];
}

stock bool MemoryTableRead(int client, const char[] savekey)
{
	static int i, j, clientLevel, powerCount, heroIndex;

	for (i = 1; i < g_iMemoryTableCount; i++) 
	{
		if (g_szMemoryTableKeys[i][0] != '\0' && StrEqual(g_szMemoryTableKeys[i], savekey, false)) 
		{
			g_iPlayerExperience[client] = g_iMemoryTableExperience[i];
			clientLevel = g_iPlayerLevel[client] = GetPlayerLevel(client);
			SetLevel(client, clientLevel);
			g_iPlayerFlags[client] = g_iMemoryTableFlags[client];

			// Load the Powers
			g_iPlayerPowers[client][0] = 0;
			powerCount = g_iPlayerPowers[client][0] = g_iMemoryTablePowers[i][0];
			for (j = 1; j <= clientLevel && j <= powerCount; j++) 
			{
				heroIndex = g_iPlayerPowers[client][j] = g_iMemoryTablePowers[i][j];
				InitializeHero(client, heroIndex, SH_HERO_ADD);
			}

			// Null this out so if the client changed - there won't be multiple copies of this guy in memory
			if (client != i) 
			{
				g_szMemoryTableKeys[i][0] = '\0';
				MemoryTableUpdate(client);
			}

			// Notify that this was found in memory...
			return true;
		}
	}
	return false; // If not found in memory table...
}

stock bool GetSaveKey(int client, char steamid[32])
{
	if (IsValidClient(client) && !IsFakeClient(client)) 
	{
		//Save XP by SteamID
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid)); // by steamid

		if (StrEqual(steamid[9], "PENDING")) 
		{
			// steamid not loaded yet, try again
			return false;
		}
	}

	// Check to make sure we got something useable
	if (steamid[0] == '\0') 
		return false;

	return true;
}

stock void LocalAddExperience(int client, int experience)
{
	int playerExperience = g_iPlayerExperience[client];
	int newTotal = playerExperience + experience;

	if ( experience > 0 && newTotal < playerExperience ) 
	{
		// Max possible signed 32bit int
		g_iPlayerExperience[client] = 2147483647;
	}
	else
		g_iPlayerExperience[client] = newTotal;
}

stock void DropPower(int client, const char[] hero)
{
	if (!g_DropAlive.BoolValue && IsPlayerAlive(client)) 
	{
		PrintToChat(client, "%t", "Not Allowed Drop", SH_PREFIX);
		return;
	}

	int heroIndex;
	bool found = false;
	
	int playerPowerCount = GetPowerCount(client);
	for (int i = 1; i <= playerPowerCount && i <= SH_MAXLEVELS; i++ ) 
	{
		heroIndex = g_iPlayerPowers[client][i];
		if (-1 < heroIndex < g_iHeroCount) 
		{
			if (StrContains(hero, g_hHeroes[heroIndex][szHero], false) != -1) 
			{
				ClearPower(client, i);
				PrintToChat(client, "%t", "Dropped Hero", SH_PREFIX, g_hHeroes[heroIndex][szHero]);
				found = true;
				break;
			}
		}
	}

	// Show the menu and the loss of power... or a message...
	if (found) 
	{
		DisplayPowers(client, true);
		Command_Heroes(client, 0);
	}
	else 
	{
		PrintToChat(client, "%t", "Could Not Find Power", SH_PREFIX, hero);
	}
}

////////////
// STOCKS //
////////////
stock int GetPlayerHealth(int client)
{
	return GetEntProp(client, Prop_Data, "m_iHealth");
}

stock void SetPlayerHealth(int client, int value)
{
	SetEntProp(client, Prop_Data, "m_iHealth", value);
}

stock int GetPlayerArmor(int client)
{
	return g_iPlayerArmor[client];
}

stock int SetPlayerArmor(int client, int value)
{
	g_iPlayerArmor[client] = value;
	
	if(g_iPlayerArmor[client] > 100)
		SetEntProp(client, Prop_Data, "m_ArmorValue", 100);
	else
		SetEntProp(client, Prop_Data, "m_ArmorValue", value);
}

stock float GetPlayerSpeed(int client)
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

stock void SetPlayerSpeed(int client, float value)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value);
	
	//Have no other way of trying to maintain a good jumping velocity than setting gravity
	//Tried dhooks return 0 on GetPlayerMax speed but things were buggy and bad
	
	//Maintain a balanced jump velocity by setting gravity
	SetGravityPowers(client);
}

stock float GetPlayerGravity(int client)
{
	float gravity = GetEntPropFloat(client, Prop_Data, "m_flGravity");
	float speed;
	if((speed = GetPlayerSpeed(client)) != 1.0)
	{
		//Get the normal gravity for the lagged movement speed
		float normalGrav = SH_DEFAULT_GRAVITY / speed;
		return normalGrav;
	}
	return gravity;
}

stock void SetPlayerGravity(int client, float value)
{
	float speed;
	if((speed = GetPlayerSpeed(client)) != 1.0)
	{
		//Get the normal gravity for the lagged movement speed
		float normalGrav = SH_DEFAULT_GRAVITY / speed;
		SetEntPropFloat(client, Prop_Data, "m_flGravity", (value*normalGrav));
		return;
	}
	
	SetEntPropFloat(client, Prop_Data, "m_flGravity", value);
	return;
}

stock void CvarCheck()
{
	
}

stock void ReadINI()
{
	char levelINIFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, levelINIFile, sizeof(levelINIFile), "configs/superhero.ini");

	if(!FileExists(levelINIFile))
		SetFailState("[superheromod.smx] Could not load %s", levelINIFile);

	File levelsFile = OpenFile(levelINIFile, "rt");

	if(!levelsFile)
		SetFailState("[superheromod.smx] Could not load %s", levelINIFile);

	// Only called once no need for static
	char data[1501];
	char numLevels[32];
	char XP[1501], XPG[1501];
	char LeftXP[32], LeftXPG[32];
	int loadCount = -1;
	
	while (!IsEndOfFile(levelsFile)) 
	{
		ReadFileLine(levelsFile, data, sizeof(data));
		TrimString(data);
		
		if( data[0] == '\0' || strncmp(data, "##", 2, false) == 0) 
			continue;
		
		if(strncmp(data, "NUMLEVELS", 9, true) == 0)
			strcopy(numLevels, sizeof(numLevels), data);
		else if((strncmp(data, "XPLEVELS", 8, true) == 0 && !g_LongTermExperience.BoolValue) || (strncmp(data, "LTXPLEVELS", 10, true) == 0 && g_LongTermExperience.BoolValue))
			strcopy(XP, sizeof(XP), data);
		else if((strncmp(data, "XPGIVEN", 7, true) == 0 && !g_LongTermExperience.BoolValue) || (strncmp(data, "LTXPGIVEN", 9, true) == 0 && g_LongTermExperience.BoolValue))
			strcopy(XPG, sizeof(XPG), data);
	}
	delete levelsFile;

	if(numLevels[0] == '\0') 
	{
		SetFailState("[superheromod.smx] No NUMLEVELS Data was found, aborting INI Loading");
		return;
	}
	else if(XP[0] == '\0')
	{
		SetFailState("[superheromod.smx] No XP LEVELS Data was found, aborting INI Loading");
		return;
	}
	else if(XPG[0] == '\0') 
	{
		SetFailState("[superheromod.smx] No XP GIVEN Data was found, aborting INI Loading");
		return;
	}

	PrintToServer("Loading %s XP Levels", g_LongTermExperience.BoolValue ? "Long Term" : "Short Term");
	ReplaceString(numLevels, sizeof(numLevels), "NUMLEVELS ", "", true);
	
	g_Levels = CreateConVar("superheromod_levels", numLevels, "Amount of levels a player can have");

	//This prevents variables from getting overflown
	if (g_Levels.IntValue > SH_MAXLEVELS) {
		PrintToServer("NUMLEVELS in superhero.ini is defined higher than MAXLEVELS in the include file. Adjusting NUMLEVELS to %d", SH_MAXLEVELS);
		g_Levels.IntValue = SH_MAXLEVELS;
	}

	BreakString(XP, LeftXP, sizeof(LeftXP));
	BreakString(XPG, LeftXPG, sizeof(LeftXPG));
	
	//Get the data tag out of the way
	if(!g_LongTermExperience.BoolValue)
	{
		ReplaceString(XP, sizeof(XP), "XPLEVELS ", "", true);
		ReplaceString(XPG, sizeof(XPG), "XPGIVEN ", "", true);
	}
	else
	{
		ReplaceString(XP, sizeof(XP), "LTXPLEVELS ", "", true);
		ReplaceString(XPG, sizeof(XPG), "LTXPGIVEN ", "", true);
	}
	char temp[32];
	while ( XP[0] != '\0' && XPG[0] != '\0' && loadCount < g_Levels.IntValue) 
	{
		loadCount++;
		
		BreakString(XP, LeftXP, sizeof(LeftXP));
		BreakString(XPG, LeftXPG, sizeof(LeftXPG));
		
		Format(temp, sizeof(temp), "%s ", LeftXP);
		ReplaceStringEx(XP, sizeof(XP), temp, "", -1, -1, true);
		Format(temp, sizeof(temp), "%s ", LeftXPG);
		ReplaceStringEx(XPG, sizeof(XPG), temp, "", -1, -1, true);
		g_iLevelExperience[loadCount] = StringToInt(LeftXP);
		g_iGivenExperience[loadCount] = StringToInt(LeftXPG);

		switch(loadCount) 
		{
			case 0: 
			{
				if(g_iLevelExperience[loadCount] != 0) 
				{
					PrintToServer("Level 0 must have an XP setting of 0, adjusting automatically");
					g_iLevelExperience[loadCount] = 0;
				}
			}
			default: 
			{
				if(g_iLevelExperience[loadCount] < g_iLevelExperience[loadCount - 1]) 
				{
					PrintToServer("Level %d is less XP than the level before it (%d < %d), adjusting NUMLEVELS to %d", loadCount, g_iLevelExperience[loadCount], g_iLevelExperience[loadCount - 1], loadCount - 1);
					g_Levels.IntValue = loadCount - 1;
					break;
				}
			}
		}

		PrintToServer("XP Loaded - Level: %d  -  XP Required: %d  -  XP Given: %d", loadCount, g_iLevelExperience[loadCount], g_iGivenExperience[loadCount]);
	}

	if(loadCount < g_Levels.IntValue) 
	{
		PrintToServer("Ran out of levels to load, check your superhero.ini for errors. Adjusting NUMLEVELS to %d", loadCount);
		g_Levels.IntValue = loadCount;
	}
}

stock int CreateGlowEntity(int client)
{
	char color[16];
	
	if(GetClientTeam(client) == CS_TEAM_T)
		Format(color, sizeof(color), "255 0 0 255");
	else
		Format(color, sizeof(color), "0 0 255 255");

	int glow = CreateEntityByName("prop_dynamic_override");

	char szModel[PLATFORM_MAX_PATH];
	GetClientModel(client, szModel, sizeof(szModel));
	DispatchKeyValue(glow, "model", szModel);
	DispatchKeyValue(glow, "disablereceiveshadows", "1");
	DispatchKeyValue(glow, "disableshadows", "1");
	DispatchKeyValue(glow, "solid", "0");
	DispatchKeyValue(glow, "spawnflags", "256");
	SetEntProp(glow, Prop_Data, "m_CollisionGroup", 11);
	DispatchSpawn(glow);
	
	SetEntProp(glow, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(glow, Prop_Send, "m_nGlowStyle", 1);
	SetEntPropFloat(glow, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	SetEntPropEnt(glow, Prop_Data, "m_hOwnerEntity", client);
	int iFlags = GetEntProp(glow, Prop_Send, "m_fEffects");
	SetEntProp(glow, Prop_Send, "m_fEffects", iFlags | (1 << 0) | (1 << 4) | (1 << 6) | (1 << 9));
	SetGlowColor(glow, color);
	SetVariantString("!activator");
	AcceptEntityInput(glow, "SetParent", client, glow);
	SetVariantString("primary");
	AcceptEntityInput(glow, "SetParentAttachment", glow, glow, 0);
	SDKHook(glow, SDKHook_SetTransmit, SetTransmit);
	return glow;
}

stock void SetGlowColor(int entity, const char[] color)
{
    char colorbuffers[3][4];
    ExplodeString(color, " ", colorbuffers, sizeof(colorbuffers), sizeof(colorbuffers[]));
    int colors[4];
    for (int i = 0; i < 3; i++)
        colors[i] = StringToInt(colorbuffers[i]);
    colors[3] = 255; // Set alpha
    SetVariantColor(colors);
    AcceptEntityInput(entity, "SetGlowColor");
}
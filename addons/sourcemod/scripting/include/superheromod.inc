#if defined _superheromod_included
 #endinput
#endif
#define _superheromod_included

#include <sdkhooks>

#define SH_PREFIX " \x09[\x04SuperHero\x09]"

// Max levels that can be loaded from the superhero.ini
#define SH_MAXLEVELS 100

// Max Amount of heroes that can be loaded
#define SH_MAXHEROES 100

// Potential of power1-power9 but limited by sh_maxbinds (3 default)
#define SH_MAXBINDPOWERS 9

// The max length of a hero name
#define SH_HERO_NAME_SIZE 32

// The max string length of a hero power description
#define SH_SUPERPOWER_SIZE 32

// The max string length of a hero help dscription
#define SH_HELP_SIZE 128

// InitializeHero(id, heroID, mode) modes
#define SH_HERO_DROP 0	//Hero is dropped
#define SH_HERO_ADD	1	//Hero is added

#define SH_DEFAULT_SPEED 1.0
#define SH_DEFAULT_GRAVITY 1.0

#define SH_MEMORY_TABLE_SIZE 64

#define SH_UBYTE_MAX 255

#define SH_KEYDOWN 1
#define SH_KEYUP 0

#define SH_DEFAULT_MODEL_T "models/player/custom_player/legacy/tm_phoenix.mdl"
#define SH_DEFAULT_MODEL_CT "models/player/custom_player/legacy/ctm_st6.mdl"

enum CSGOWeaponID
{
	CSGOWeaponID_NONE = 0,
	CSGOWeaponID_DEAGLE,
	CSGOWeaponID_REVOLVER,
	CSGOWeaponID_ELITE,
	CSGOWeaponID_FIVESEVEN,
	CSGOWeaponID_GLOCK,
	CSGOWeaponID_AK47,
	CSGOWeaponID_AUG,
	CSGOWeaponID_AWP,
	CSGOWeaponID_FAMAS,
	CSGOWeaponID_G3SG1,
	CSGOWeaponID_GALILAR,
	CSGOWeaponID_M249,
	CSGOWeaponID_M4A1,
	CSGOWeaponID_M4A1SILENCER,
	CSGOWeaponID_MAC10,
	CSGOWeaponID_P90,
	CSGOWeaponID_UMP45,
	CSGOWeaponID_XM1014,
	CSGOWeaponID_BIZON,
	CSGOWeaponID_MAG7,
	CSGOWeaponID_NEGEV,
	CSGOWeaponID_SAWEDOFF,
	CSGOWeaponID_TEC9,
	CSGOWeaponID_TASER,
	CSGOWeaponID_HKP2000,
	CSGOWeaponID_USPSILENCER,
	CSGOWeaponID_MP7,
	CSGOWeaponID_MP9,
	CSGOWeaponID_NOVA,
	CSGOWeaponID_P250,
	CSGOWeaponID_CZ75A,
	CSGOWeaponID_SCAR20,
	CSGOWeaponID_SG556,
	CSGOWeaponID_SSG08,
	CSGOWeaponID_KNIFE,
	CSGOWeaponID_FLASHBANG,
	CSGOWeaponID_SMOKEGRENADE,
	CSGOWeaponID_HEGRENADE,
	CSGOWeaponID_MOLOTOV,
	CSGOWeaponID_DECOY,
	CSGOWeaponID_INCGRENADE,
	CSGOWeaponID_C4,
	CSGOWeaponID_HEALTHSHOT,
}

enum HeroEnum
{
	String:szHero[SH_HERO_NAME_SIZE],
	String:szSuperPower[SH_SUPERPOWER_SIZE],
	String:szHelp[SH_HELP_SIZE],
	bool:requiresBind,
	availableLevel,
}

enum //PlayerData
{
	SH_DATA_PLAYER = 0,
	SH_DATA_HEROES,
	
	SH_DATA_MAX,
}

//NATIVES

// REQUIRED
// Creates your hero
// Call this on pluginstart
// param1: the name of your hero
// param2: the level you want your hero to be
// return: heroIndex
native int SuperHero_CreateHero(char[] hero, int minlevel);

// REQUIRED
// Set some required info of your hero
// Call this on plugin start
// param1: the heroindex you wanna set info on
// param2: very short power description
// param3: longer power description
native void SuperHero_SetHeroInfo(int heroIndex, char[] superpower, char[] help);

// REQUIRED If you wanna give your hero a primary weapon and have multiple heroes that gives primary weapons, just use it for safety
// Sets the heros primary weapon in a variable to determine what primary weapon to give the player if he has multiple heroes that gives primary weapons
// param1: heroindex that spawns a weapon
// param2: weaponid (CTRL + F: CSGOWeaponID in superheromod.inc (this file)). You can pass the enum into the parameter by using e.g: view_as<int>(CSGOWeaponID_AK47)
native void SuperHero_SetHeroPrimaryWeapon(int heroIndex, int weaponid);

// REQUIRED If you wanna give your hero a secondary weapon and have multiple heroes that gives secondary weapons, just use it for safety
// Sets the heros secondary weapon in a variable to determine what secondary weapon to give the player if he has multiple heroes that gives secondary weapons
// param1: heroindex that spawns a weapon
// param2: weaponid (CTRL + F: CSGOWeaponID in superheromod.inc (this file)). You can pass the enum into the parameter by using e.g: view_as<int>(CSGOWeaponID_AK47)
native void SuperHero_SetHeroSecondaryWeapon(int heroIndex, int weaponid);

// REQUIRED If your hero has a player model
// Sets the heros player model
// param1: heroindex to set player model
// param2: model path
// Extra: THIS FUNCTION DOES NOT PRECACHE/ADDFILETODOWNLOADSTABLE
native void SuperHero_SetHeroPlayerModel(int heroindex, const char[] model);

// Adds a bind to your hero (+POWER[heroindex])
// param1: the hero you want to have a bind
native void SuperHero_SetHeroBind(int heroIndex);

// Sets your heros max health
// param1: the heroindex you wanna set max health on
// param2: amount of health
native void SuperHero_SetHeroHealth(int heroIndex, int health);

// Sets your heros max armor
// param1: the heroindex you wanna set max armor on
// param2: amount of armor
native void SuperHero_SetHeroArmor(int heroIndex, int armor);

// Sets your heros max speed
// param1: the heroindex you wanna set max speed on
// param2: amount of speed
// param3: the weapons you want to set speed on (leave empty if you want the speed affect all weapons)
// param4: the number of weapons you're setting speed on
native void SuperHero_SetHeroSpeed(int heroIndex, float speed, int weapons[42] = {0}, int numberofweapons = 0);

// Sets your heros gravity
// param1: the hero index you wanna set gravity on
// param2: amount of gravity (1.0 is default, 0.0 is never fall down)
native void SuperHero_SetHeroGravity(int heroIndex, float gravity);

// Sets a damage multiplier on a hero wepaon
// param1: the hero index you wanna set damage multiplier on
// param2: amount of multiplied damage (2.0 is double the damage)
// param3: weaponid (CTRL + F: CSGOWeaponID in superheromod.inc (this file)). You can pass the enum into the parameter by using e.g: view_as<int>(CSGOWeaponID_AK47)
native void SuperHero_SetHeroDamageMultiplier(int heroIndex, float dmgmult, int weaponid);

// Gets the players max health (from all of his heroes together)
// param1: player you wanna get max health from
// return: player max health
native int SuperHero_GetMaxHealth(int client);

// Gets the players max armor (from all of his heroes together)
// param1: player you wanna get max armor from
// return: player max armor
native int SuperHero_GetMaxArmor(int client);

// Gets the players max speed (from all of his heroes together, or max speed for a weapon if weaponid > CSGOWeaponID_NONE)
// param1: player you wanna get speed from
// param2: what weapon id you wanna get max speed from (CSGOWeaponID_NONE for no specific weapon)
// param3: float buffer to store the result speed
native void SuperHero_GetMaxSpeed(int client, int weaponid, float& resultspeed);

// Gets the players lowest gravity (from all of his heroes together)
// param1: player you wanna get lowest gravity from
// param2: float buffer to store the result gravity
native void SuperHero_GetGravity(int client, float& resultgravity);

// Gets the amount of levels that are loaded by configs/superhero.ini
// return: max levels
native int SuperHero_GetLevelCount();

// Gets the amount of experience the level requires from previous level
// param1: the level you want to get experience from
// return: amount of experience
native int SuperHero_GetLevelExperience(int level);

// Gets the players level
// param1: player you wanna get level from
// return: player level
native int SuperHero_GetPlayerLevel(int client);

// Sets the players level
// param1: player you wanna set level on
// param2: level you wanna set the client
// return: the level set (-1 if fail)
native int SuperHero_SetPlayerLevel(int client, int setlevel);

// Gets the players experience
// param1: player you wanna get experience from
// return: amount of experience
native int SuperHero_GetPlayerExperience(int client);

// Sets the players experience
// param1: player you wanna set experience on
// param2: amount of experience
// return: the experience set (-1 if fail)
native int SuperHero_SetPlayerExperience(int client, int setexperience);

// Adds experience to client (xp is based on victims level)
// param1: player you wanna add xp to
// param2: player you want players xp to base off
native void SuperHero_AddKillExperience(int client, int victim);

// Gets the hero index of a hero name
// param1: named hero to get hero index of
// return: hero index
native int SuperHero_GetHeroIndex(const char[] hero);

// Does the player have this hero?
// param1: player to check
// param2: heroindex to check
// return: true if player has hero, false if not
native bool SuperHero_PlayerHasHero(int client, int heroIndex);

// Set player stun (Make him walk slower and not be able to use power binds)
// param1: player to stun
// param2: duration of the stun
// param3: the amount of speed the player should get when stunned
native void SuperHero_SetStun(int client, float duration, float speed);

// Get the amount of stun time left
// param1: player to get stun time off
// return: time in seconds left of stun
native int SuperHero_GetStun(int client);

// Set godmode on player
// param1: player to set godmode on
// param2: duration of the godmode
native void SuperHero_SetGodMode(int client, float duration);

// Does player have godmode?
// param1: player to check
// return: true if player has godmode, false if not
native bool SuperHero_IsGodMode(int client);

// Reset the players speed to his max hero speed
// param1: player to reset speed on
native void SuperHero_ResetMaxSpeed(int client);

// Reset the players gravity to his min hero gravity
// param1: player to reset gravity on
native void SuperHero_ResetGravity(int client);

// Set the cooldown of a hero (power or anything really)
// param1: player to set cooldown on
// param2: hero to set cooldown on
// param3: duration of the cooldown
native void SuperHero_SetPlayerHeroCooldown(int client, int heroIndex, float time);

// End the cooldown of a hero
// param1: player to end cooldown on
// param2: heroindex to end cooldown on
native void SuperHero_EndPlayerHeroCooldown(int client, int heroIndex);

// Is the players hero in cooldown?
// param1: player to check
// param2: heroindex to check
// return: returns true if players hero is in cooldown, false if not
native bool SuperHero_IsPlayerHeroInCooldown(int client, int heroIndex);

// Force set the players hero cooldown
// param1: player to force cooldown on
// param2: heroindex to force cooldown on
// param3: value (true or false)
native void SuperHero_ForceSetPlayerHeroCooldown(int client, int heroIndex, bool value);

// Add health to player (This function already checks if health exceeds max health) 
// param1: player to add health to
// param2: amount of health
// return: the amount of real health added (0 if health was not changed, -1 if invalid client)
native int SuperHero_AddHealth(int client, int health);

// Add armor to player (This function already checks if armor exceeds max armor)
// param1: player to add armor to
// param2: amount of armor
// return: the amount of real armor added (0 if armor was not changed, -1 if invalid client)
native int SuperHero_AddArmor(int client, int armor);

// Play deny sound to player (Used for power cooldowns and stuns)
// param1: player to play deny sound to
native void SuperHero_PlayDenySound(int client);

// Set the bool that checks if players speed should be changed on weapon speed (Had to be made for shadowcat superhero)
// param1: player to set bool
// param2: value to set
native void SuperHero_SetChangeWeaponSpeedBool(int client, bool value);

// Gets the weaponid of the players highest leveled hero that gives a primary weapon
// param1: player to get highest primary weapon level
// return: casted CSGOWeaponID weapon id
native int SuperHero_GetHighestPrimaryWeaponLevel(int client);

// Gets the weaponid of the players highest leveled hero that gives a secondary weapon
// param1: player to get highest primary weapon level
// return: casted CSGOWeaponID weapon id
native int SuperHero_GetHighestSecondaryWeaponLevel(int client);

// Gets the players highest level hero
// param1: player to get highest level hero
// return: highest level
native int SuperHero_GetHighestLevelHero(int client);

// Gets the heros player model
// param1: heroindex to get player model from
// param2: buffer to store the player model
// param3: size of the buffer
native void SuperHero_GetHeroPlayerModel(int heroindex, char[] szbuffer, int maxlen);

// Does the hero have a player model?
// param1: heroindex to check
// return: true if hero has a player model, false if not
native bool SuperHero_HeroHasPlayerModel(int heroindex);

// Gets the players final player model if he has multiple heroes that changes his player model (Model picked is determined by highest level)
// param1: player to get highest level model
// param2: buffer to store the model path
// param3: size of the buffer
// return: heroindex (-1 on failure)
// Extra info: Model is automatically set from superheromod.sp on Event_PlayerSpawn aslong as SuperHero_SetHeroPlayerModel is called on your superhero
native int SuperHero_GetHighestPlayerModelLevel(int client, char[] szbuffer, int maxlen);

// Sets the heros available level (Use this in OnConfigsExecuted forward since AutoExecConfig requires more than 1 frame to execute)
// param1: heroindex to set level on
// param2: the level to set
native void SuperHero_SetHeroAvailableLevel(int heroIndex, int level);

//FORWARDS

// This is called when a players hero is initialized (e.g playerspawn or when player picks a new hero). Its used to set info like if the player has this hero and what not
// param1: player that initializes a hero
// param2: heroindex that was initialized
// param3: 1 (SH_HERO_ADD) if hero was added, 0 (SH_HERO_DROP) if hero was dropped/removed
forward void SuperHero_OnHeroInitialized(int client, int heroIndex, int mode);

// This is called on player_spawn event
// param1: player that spawned
// param2: was it a new round spawn or mid round spawn?
forward void SuperHero_OnPlayerSpawned(int client, bool newroundspawn);

// This is called when player dies
// param1: player that died
// param2: player that killed
// param3: was it a headshot?
forward void SuperHero_OnPlayerDeath(int victim, int attacker, bool headshot);

// This is called when a player presses a power key
// param1: player that pressed power key
// param2: heroindex that pressed power key
// param3: 1 (SH_KEYDOWN) if pressed, 0 (SH_KEYUP) if released
forward void SuperHero_OnHeroBind(int client, int heroIndex, int key);

// This is called when a player takes damage
// param1: player that takes damage
// param2: player that attacks
// param3: entity that inflicted the damage (I have no idea tbh, see more in some sdkhooks docs)
// param4: amount of damage the attacker did
// param5: what damagetype (e.g DMG_BLAST for grenade)
// param6: weapon entity index that did damage
// param7: damage force vector
// param8: damage position vector
// Extra: this forward is called on SDKHook_OnTakeDamage in superheromod.sp and if this is called, it will always return plugin_changed
forward void SuperHero_OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]);

// This is called after a player took damage
// param1: player that takes damage
// param2: player that attacks
// param3: damage type
// param4: weapon entity index that damaged player
// param5: amount of damage taken
// param6: amount of armor taken
// Extra: this forward is created for the sole purpose of getting proper health/armor damage taken (Useful for superhero anubis or dracula)
forward void SuperHero_OnPlayerTakeDamagePost(int victim, int attacker, int damagetype, int weapon, int damagetaken, int armortaken);


//Converts a weapon class named to CSGOWeaponID enum
stock CSGOWeaponID WeaponClassNameToCSWeaponID(char[] classname)
{
	if(StrEqual(classname, "weapon_deagle")) return CSGOWeaponID_DEAGLE;
	else if(StrEqual(classname, "weapon_revolver")) return CSGOWeaponID_REVOLVER;
	else if(StrEqual(classname, "weapon_elite")) return CSGOWeaponID_ELITE;
	else if(StrEqual(classname, "weapon_fiveseven")) return CSGOWeaponID_FIVESEVEN;
	else if(StrEqual(classname, "weapon_glock")) return CSGOWeaponID_GLOCK;
	else if(StrEqual(classname, "weapon_ak47")) return CSGOWeaponID_AK47;
	else if(StrEqual(classname, "weapon_aug")) return CSGOWeaponID_AUG;
	else if(StrEqual(classname, "weapon_awp")) return CSGOWeaponID_AWP;
	else if(StrEqual(classname, "weapon_famas")) return CSGOWeaponID_FAMAS;
	else if(StrEqual(classname, "weapon_g3sg1")) return CSGOWeaponID_G3SG1;
	else if(StrEqual(classname, "weapon_galilar")) return CSGOWeaponID_GALILAR;
	else if(StrEqual(classname, "weapon_m249")) return CSGOWeaponID_M249;
	else if(StrEqual(classname, "weapon_m4a1")) return CSGOWeaponID_M4A1;
	else if(StrEqual(classname, "weapon_mac10")) return CSGOWeaponID_MAC10;
	else if(StrEqual(classname, "weapon_p90")) return CSGOWeaponID_P90;
	else if(StrEqual(classname, "weapon_ump45")) return CSGOWeaponID_UMP45;
	else if(StrEqual(classname, "weapon_xm1014")) return CSGOWeaponID_XM1014;
	else if(StrEqual(classname, "weapon_bizon")) return CSGOWeaponID_BIZON;
	else if(StrEqual(classname, "weapon_mag7")) return CSGOWeaponID_MAG7;
	else if(StrEqual(classname, "weapon_negev")) return CSGOWeaponID_NEGEV;
	else if(StrEqual(classname, "weapon_sawedoff")) return CSGOWeaponID_SAWEDOFF;
	else if(StrEqual(classname, "weapon_tec9")) return CSGOWeaponID_TEC9;
	else if(StrEqual(classname, "weapon_taser")) return CSGOWeaponID_TASER;
	else if(StrEqual(classname, "weapon_hkp2000")) return CSGOWeaponID_HKP2000;
	else if(StrEqual(classname, "weapon_mp7")) return CSGOWeaponID_MP7;
	else if(StrEqual(classname, "weapon_mp9")) return CSGOWeaponID_MP9;
	else if(StrEqual(classname, "weapon_nova")) return CSGOWeaponID_NOVA;
	else if(StrEqual(classname, "weapon_p250")) return CSGOWeaponID_P250;
	else if(StrEqual(classname, "weapon_scar20")) return CSGOWeaponID_SCAR20;
	else if(StrEqual(classname, "weapon_sg556")) return CSGOWeaponID_SG556;
	else if(StrEqual(classname, "weapon_ssg08")) return CSGOWeaponID_SSG08;
	else if(StrContains(classname, "knife") != -1 || StrContains(classname, "bayonet") != -1) return CSGOWeaponID_KNIFE; //NO:GO
	else if(StrEqual(classname, "weapon_flashbang")) return CSGOWeaponID_FLASHBANG;
	else if(StrEqual(classname, "weapon_smokegrenade")) return CSGOWeaponID_SMOKEGRENADE;
	else if(StrEqual(classname, "weapon_hegrenade")) return CSGOWeaponID_HEGRENADE;
	else if(StrEqual(classname, "weapon_molotov")) return CSGOWeaponID_MOLOTOV;
	else if(StrEqual(classname, "weapon_decoy")) return CSGOWeaponID_DECOY;
	else if(StrEqual(classname, "weapon_incgrenade")) return CSGOWeaponID_INCGRENADE;
	else if(StrEqual(classname, "weapon_c4")) return CSGOWeaponID_C4;
	else if(StrEqual(classname, "weapon_m4a1_silencer")) return CSGOWeaponID_M4A1SILENCER;
	else if(StrEqual(classname, "weapon_usp_silencer")) return CSGOWeaponID_USPSILENCER;
	else if(StrEqual(classname, "weapon_cz75a")) return CSGOWeaponID_CZ75A;
	else if(StrEqual(classname, "weapon_revolver")) return CSGOWeaponID_REVOLVER;
	else if(StrEqual(classname, "weapon_healthshot")) return CSGOWeaponID_HEALTHSHOT;
	else return CSGOWeaponID_NONE;
}

stock bool IsGameLive()
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 0 && GameRules_GetProp("m_bFreezePeriod") == 0)
		return true;
	return false;
}

stock bool IsFreezeTime()
{
	if(GameRules_GetProp("m_bFreezePeriod"))
		return true;
	return false;
}

stock int clamp(int value, int min, int max)
{
	if(value > max)
		return max;
	if(value < min)
		return min;
		
	return value;
}

stock float floatclamp(float value, float minf, float maxf)
{
	if(value > maxf)
		return maxf;
	if(value < minf)
		return minf;
	
	return value;
}

stock int max(int x, int y)
{
	return x >= y ? x : y;
}

stock int min(int x, int y)
{
	return x <= y ? x : y;
}

stock float floatmax(float x, float y)
{
	return x >= y ? x : y;
}

stock float floatmin(float x, float y)
{
	return x <= y ? x : y;
}

// strip all weapons
stock void StripWeapons(int client, bool knife = true)
{
	int weapon; 
	for(int i = 0; i < 5; i++) 
	{ 
	    if((weapon = GetPlayerWeaponSlot(client, i)) != -1) 
	    { 
	        SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR); 
	        AcceptEntityInput(weapon, "Kill"); 
	    } 
	}
	if(!knife)
		GivePlayerItem(client, "weapon_knife");
}

// Is the player in game?
stock bool IsValidClient(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

// Strip players primary weapon
stock void StripPrimary(int client)
{
	int weapon; 
	if((weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != -1) 
	{ 
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR); 
		AcceptEntityInput(weapon, "Kill"); 
	} 
}

// Strip players secondary weapon
stock void StripSecondary(int client)
{
	int weapon; 
	if((weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1) 
	{ 
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR); 
		AcceptEntityInput(weapon, "Kill"); 
	} 
}
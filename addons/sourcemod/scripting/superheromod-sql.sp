//Plugin will auto create the tables if they do not exist

//If shmod's mysql cvars not set plugin will try to setup
//database in amxmodx's database if one exists

//Use these to create the tables manually if necessary
/*
CREATE TABLE `sh_savexp` (
	`SH_KEY` varchar(32) binary NOT NULL default '',
	`PLAYER_NAME` varchar(32) binary NOT NULL default '',
	`LAST_PLAY_DATE` timestamp(14) NOT NULL,
	`XP` int(10) NOT NULL default '0',
	`HUDHELP` tinyint(3) unsigned NOT NULL default '1',
	`SKILL_COUNT` tinyint(3) unsigned NOT NULL default '0',
	PRIMARY KEY  (`SH_KEY`)
) TYPE=MyISAM COMMENT='SUPERHERO XP Saving Table';

CREATE TABLE `sh_saveskills` (
	`SH_KEY` varchar(32) binary NOT NULL default '',
	`SKILL_NUMBER` tinyint(3) unsigned NOT NULL default '0',
	`HERO_NAME` varchar(25) NOT NULL default '',
	PRIMARY KEY  (`SH_KEY`,`SKILL_NUMBER`)
) TYPE=MyISAM COMMENT='SUPERHERO Skill Saving Table';

//Upgrade from prior to 1.17.5
ALTER TABLE `sh_savexp` ADD `HUDHELP` TINYINT( 3 ) UNSIGNED DEFAULT '1' NOT NULL AFTER `XP`;

//Upgraded from prior to 1.20 (XP from unsigned to signed and usage of tinyint over int)
ALTER TABLE `sh_savexp` CHANGE `XP` `XP` INT( 10 ) SIGNED NOT NULL DEFAULT '0';
ALTER TABLE `sh_savexp` CHANGE `HUDHELP` `HUDHELP` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '1';
ALTER TABLE `sh_savexp` CHANGE `SKILL_COUNT` `SKILL_COUNT` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `sh_saveskills` CHANGE `SKILL_NUMBER` `SKILL_NUMBER` TINYINT( 3 ) UNSIGNED NOT NULL DEFAULT '0';

*/

public void SQLConnection_Callback(Database db, const char[] error, any data)
{
	if (db == null)
		SetFailState("Could not connect to superheromod database");
	else
	{
		g_hPlayerData = db;
		g_hPlayerData.SetCharset("utf8");
		CreateTables();
	}
}

stock void CreateTables()
{
	char szQuery[4096];
	Transaction t = SQL_CreateTransaction();
	//Stats per round
	Format(szQuery, sizeof(szQuery),"CREATE TABLE IF NOT EXISTS `sh_savexp` ( \
									`SH_KEY` varchar(32) NOT NULL default '', \
									`PLAYER_NAME` varchar(32) NOT NULL default '', \
									`LAST_PLAY_DATE` timestamp(14) NOT NULL, \
									`XP` int(10) NOT NULL default '0', \
									`HUDHELP` tinyint(3) NOT NULL default '1', \
									`SKILL_COUNT` tinyint(3) NOT NULL default '0', \
									PRIMARY KEY  (`SH_KEY`) \
									); ");
						
	t.AddQuery(szQuery);
	
	
	Format(szQuery, sizeof(szQuery),"CREATE TABLE IF NOT EXISTS `sh_saveskills` ( \
									`SH_KEY` varchar(32) NOT NULL default '', \
									`SKILL_NUMBER` tinyint(3) NOT NULL default '0', \
									`HERO_NAME` varchar(25) NOT NULL default '', \
									PRIMARY KEY  (`SH_KEY`,`SKILL_NUMBER`) \
									); ");
	t.AddQuery(szQuery);
	g_hPlayerData.Execute(t,_,TableCreationFailure);
}

public void TableCreationFailure(Database database, any data, int numQueries, const char[] error, int failIndex, any[] queryData) 
{
	LogError("Failed table creation query, error = %s", error);
}

// Flushes data in memory table position x to database...
public void WriteData(int client)
{
	if(g_hPlayerData == INVALID_HANDLE)
		return;

	//DEBUG
	//PrintToServer("WRITING %N' PLAYER DATA!", client);

	char szQuery[4096], name[MAX_NAME_LENGTH], steamid[32];									 
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	if(StrEqual(steamid, "STEAM_ID_STOP_IGNORING_RETVALS", false))
		return;
		
	SQL_EscapeString(g_hPlayerData, name, name, sizeof(name));
	Transaction t = SQL_CreateTransaction();												 
	Format(szQuery, sizeof(szQuery),"INSERT OR IGNORE INTO `sh_savexp` \
									(`SH_KEY`, `PLAYER_NAME`, `LAST_PLAY_DATE`, `XP`, `HUDHELP`, `SKILL_COUNT`) \
									VALUES ('%s', '%s', date(), '%d', '%d', '%d')", 
									steamid, name, g_iMemoryTableExperience[client], g_iMemoryTableFlags[client], g_iMemoryTablePowers[client][0]);
	
	t.AddQuery(szQuery);
	

	Format(szQuery, sizeof(szQuery),"UPDATE `sh_savexp` \
									SET `PLAYER_NAME`='%s', `LAST_PLAY_DATE`=date(), `XP`='%d', `HUDHELP`='%d', `SKILL_COUNT`='%d' \
									WHERE`SH_KEY` = '%s'", name, g_iMemoryTableExperience[client], g_iMemoryTableFlags[client], g_iMemoryTablePowers[client][0], steamid);
	t.AddQuery(szQuery);


	if (!IsClientConnected(client) || g_bChangedHeroes[client]) 
	{
		// Remove all saved powers for this user
		Format(szQuery, sizeof(szQuery), "DELETE FROM `sh_saveskills` WHERE `SH_KEY`='%s'", steamid);
		t.AddQuery(szQuery);
		

		// Saving by SuperHeroName since the hero order in the plugin.ini can change...
		int numHeroes;
		numHeroes = g_iMemoryTablePowers[client][0];

		for (int i = 1; i <= numHeroes; i++) 
		{
			Format(szQuery, sizeof(szQuery), "INSERT INTO `sh_saveskills` VALUES ");

			// (savekey, user's hero number, hero name)
			Format(szQuery, sizeof(szQuery), "%s('%s','%d','%s')", szQuery, steamid, i, g_hHeroes[g_iMemoryTablePowers[client][i]][szHero]);
			t.AddQuery(szQuery);
		}

		// x can be higher than max slots, however sizeof g_bChangedHeroes can not be
		if ( 0 < client <= MAXPLAYERS)
			g_bChangedHeroes[client] = false;
	}
	g_hPlayerData.Execute(t,_,WritingDataFailure);
}

public void LoadData(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	if(g_hPlayerData == INVALID_HANDLE)
		return;
	
	//DEBUG
	//PrintToServer("LOADING %N' PLAYER DATA!", client);
	char szQuery[4096];
	Format(szQuery, sizeof(szQuery), "SELECT `XP`, `HUDHELP`, `SKILL_COUNT` FROM `sh_savexp` WHERE `SH_KEY` = '%s'", steamid);
	g_hPlayerData.Query(SQLQuery_LoadPlayerData, szQuery, GetClientUserId(client));
}

public void SQLQuery_LoadPlayerData(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Error (%i): %s", data, error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if(client > 0 && client <= MaxClients)
	{

		if (results.RowCount == 0)
		{
			PrintToServer("No Saved XP to Load for %N", client);
			return;
		}
		
		int skillCount = 0;
		char steamid[32];
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
		results.FetchRow();
		g_iPlayerExperience[client] = results.FetchInt(0);
		g_iPlayerLevel[client] = GetPlayerLevel(client);
		SetLevel(client, g_iPlayerLevel[client]);
	
		g_iPlayerFlags[client] = results.FetchInt(1);
		skillCount = results.FetchInt(2);
		char szQuery[4096];
		Format(szQuery, sizeof(szQuery), "SELECT `HERO_NAME` FROM `sh_saveskills` WHERE `SH_KEY` = '%s' AND `SKILL_NUMBER` <= '%s' ORDER BY `SKILL_NUMBER` ASC", steamid, skillCount);
		g_hPlayerData.Query(SQLQuery_LoadPlayerPowers, szQuery, data);
	}
}

public void SQLQuery_LoadPlayerPowers(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Error (%i): %s", data, error);
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if(client > 0 && client <= MaxClients)
	{
		if (results.RowCount == 0)
		{
			PrintToServer("No heroes to Load for %N", client);
			return;
		}

		char heroName[SH_HERO_NAME_SIZE];
		int heroIndex = 0;
		int powerCount = 0;
		g_iPlayerPowers[client][0] = 0;
		
		while (results.FetchRow())
		{
			results.FetchString(0, heroName, sizeof(heroName));
			heroIndex = GetHeroIndex(heroName);
			if (-1 < heroIndex < g_iHeroCount && (GetHeroLevel(heroIndex) <= g_iPlayerLevel[client]))
			{
				g_iPlayerPowers[client][0] = ++powerCount;
				g_iPlayerPowers[client][powerCount] = heroIndex;
				InitializeHero(client, heroIndex, SH_HERO_ADD);
			}
		}
		MemoryTableUpdate(client);
	}
}
public void SQLQuery_Void(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null)
		LogError("Error (%i): %s", data, error);
}


public void WritingDataFailure(Database database, any data, int numQueries, const char[] error, int failIndex, any[] queryData) 
{
	LogError("Failed storing stats query, error = %s", error);
}
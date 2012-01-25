#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <ApolloRP>
#include <sqlx>

#define MENU_OPTIONS 3
#define DB_MENU_OPTIONS 4

new g_MenuOptions[MENU_OPTIONS][] =
{
	"Add First ARP Admin",
	"Change Database Connection",
	"Load Map SQL Data"
}

// for some reason, these align perfectly. it's great for me ;]
new g_DbMenuOptions[DB_MENU_OPTIONS][] =
{
	"Host",
	"User",
	"Pass",
	"DB"
}

enum
{
	HOSTNAME = 1,
	USERNAME,
	PASSWORD,
	DATABASE
}

new g_LocalSqlFile[64] = "arp.ini"

new g_DbMenu[] = "mDatabaseMenu"
new g_MainMenu[] = "mConfigMenu"
new const g_Keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

//new bool:g_FirstSet

new g_ModMode[33]
new g_Checker[33]

new g_Offline

new g_Queries
new g_Completed
new g_Errors

new g_Query[4096]

new Handle:g_SqlHandle

// the name of the users table
new g_DefaultUserTable[64] = "arp_users"
new g_UserTable[64] = "arp_users"
// the name of the jobs table
new g_DefaultJobsTable[64] = "arp_jobs"
new g_JobsTable[64] = "arp_jobs"
// the name of the property table
new g_DefaultPropertyTable[64] = "arp_property"
new g_PropertyTable[64] = "arp_property"
// name of the doors table
new g_DefaultDoorsTable[64] = "arp_doors"
new g_DoorsTable[64] = "arp_doors"
// door keys
new g_DefaultKeysTable[64] = "arp_keys"
new g_KeysTable[64] = "arp_keys"
// name of the items table
new g_DefaultItemsTable[64] = "arp_items"
new g_ItemsTable[64] = "arp_items"
// name of the orgs table
//new g_OrgsTable[] = "arp_orgs"
// name of the data table
new g_DefaultDataTable[64] = "arp_data"
new g_DataTable[64] = "arp_data"

new p_BackupDatabase

new g_BackupName[33]
new g_BackupQueries
new g_TotalBackupQueries

public plugin_init()
{	
	register_clcmd("arp_config","CmdConfig")
	register_srvcmd("arp_delete","CmdDelete")
	register_srvcmd("arp_query","CmdQuery")
	register_srvcmd("arp_backup","CmdBackup")
	register_srvcmd("arp_restore","CmdRestore")
	
	register_clcmd("say","CmdSay")
	register_clcmd("say_team","CmdSay")
	
	ARP_RegisterCmd("arp_getinfo","CmdGetInfo","<ADMIN> - gets all current info")
	
	register_menucmd(register_menuid(g_MainMenu),g_Keys,"HandleCmdConfig")
	register_menucmd(register_menuid(g_DbMenu),g_Keys,"HandleDbMenu")
	
	new ConfigsDir[64]
	get_configsdir(ConfigsDir,63)
	
	p_BackupDatabase = register_cvar("arp_sql_backup_db","backup")

	format(g_LocalSqlFile,63,"%s/%s",ConfigsDir,g_LocalSqlFile)
}

public CmdGetInfo(id)
{
	if(!ARP_AdminAccess(id))
		return PLUGIN_HANDLED
	
	new Float:fOrigin[3], Float:fAngles[3],iOrigin[3]
	entity_get_vector(id,EV_VEC_origin,fOrigin)
	entity_get_vector(id,EV_VEC_angles,fAngles)
	FVecIVec(fOrigin,iOrigin)
	
	new Access[27],JobRights[27]
	ARP_IntToAccess(ARP_GetUserAccess(id),Access,charsmax(Access))
	ARP_IntToAccess(ARP_GetUserJobRight(id),JobRights,charsmax(JobRights))
	
	console_print(id,"Origin: %d %d %d",iOrigin[0],iOrigin[1],iOrigin[2])
	console_print(id,"Angles: %d %d %d (%0.1f %0.1f %0.1f)",floatround(fAngles[0] / 45.0) * 45,floatround(fAngles[1] / 45.0) * 45,floatround(fAngles[2] / 45.0) * 45,fAngles[0],fAngles[1],fAngles[2])
	entity_get_vector(id,EV_VEC_v_angle,fAngles)
	console_print(id,"View Angles: %d %d %d (%0.1f %0.1f %0.1f)",floatround(fAngles[0] / 45.0) * 45,floatround(fAngles[1] / 45.0) * 45,floatround(fAngles[2] / 45.0) * 45,fAngles[0],fAngles[1],fAngles[2])
	console_print(id,"Access flags: %s",Access)
	console_print(id,"Job rights: %s",JobRights)
	
	return PLUGIN_HANDLED
}

public ARP_Init()
{
	g_Offline ? register_plugin("ARP - Config",ARP_VERSION,"The Apollo RP Team") : ARP_RegisterPlugin("Config",ARP_VERSION,"The Apollo RP Team","Helps admins with setting up the server")
	
	g_SqlHandle = ARP_SqlHandle()
	
	ARP_GetTable(USERS,g_UserTable,63)
	ARP_GetTable(JOBS,g_JobsTable,63)
	ARP_GetTable(PROPERTIES,g_PropertyTable,63)
	ARP_GetTable(DOORS,g_DoorsTable,63)
	ARP_GetTable(KEYS,g_KeysTable,63)
	ARP_GetTable(ITEMS,g_ItemsTable,63)
	ARP_GetTable(DATA,g_DataTable,63)
}	

public ARP_Error(const Reason[])
	g_Offline = 1

//public ARP_Init()
	//fnFirstSet()

public CmdRestore()
{
	if(IsOffline())
	{
		server_print("The SQL database is currently disconnected.")
		return
	}
	
	if(g_BackupQueries)
	{
		server_print("There is already a restore in progress.")
		return
	}
	
	server_print("** NOTE ** YOU MUST RUN arp_delete BEFORE USING THIS COMMAND ** NOTE **")
	
	read_args(g_BackupName,32)
	trim(g_BackupName)
	remove_quotes(g_BackupName)
	
	if(!strlen(g_BackupName))
	{
		server_print("You must input a backup name")
		return
	}
	
	if(containi(g_BackupName,"_") != -1)
	{
		server_print("Your backup name cannot contain underscores (_).")
		return
	}
	
	switch(ARP_SqlMode())
	{
		case MYSQL:
		{
			new Database[64]
			get_pcvar_string(p_BackupDatabase,Database,63)
			
			format(g_Query,4095,"SHOW TABLES IN %s",Database)
		}
		case SQLITE:
		{
			server_print("This option is not available on SQLite servers. The database file is located in ./amxmodx/data/sqlite3/ and can be copied for backup purposes.")
			return
		}
	}

	ARP_CleverQuery(g_SqlHandle,"RestoreQueryHandle",g_Query)
}

public RestoreQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	new Table[64],Database[64],BackupName[64],Len
	copy(BackupName,63,g_BackupName)
	add(BackupName,63,"_")
	
	get_pcvar_string(p_BackupDatabase,Database,63)
	
	while(SQL_MoreResults(Query))
	{		
		SQL_ReadResult(Query,0,Table,63)
		SQL_NextRow(Query)
		
		Len = strlen(Table)
		if(Table[Len - 1] == '_')
			Table[Len - 1] = '^0'
		
		replace(Table,63,BackupName,"")
		
		format(g_Query,4095,"CREATE TABLE %s AS SELECT * FROM %s.%s_%s",Table,Database,g_BackupName,Table)
		
		server_print("Restoring table %s from %s_%s",Table,g_BackupName,Table)
		
		SQL_ThreadQuery(g_SqlHandle,"RestoreTableQueryHandle",g_Query)
		
		g_BackupQueries++
	}
	
	g_TotalBackupQueries = g_BackupQueries
	server_print("%d restore queries queued",g_BackupQueries)
	
	return PLUGIN_CONTINUE
}

public RestoreTableQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	server_print("%d/%d tables restored",g_TotalBackupQueries - --g_BackupQueries,g_TotalBackupQueries)
	
	if(!g_BackupQueries)
		server_print("Restore ^"%s^" complete",g_BackupName)
	
	return PLUGIN_CONTINUE
}

public CmdBackup()
{
	if(IsOffline())
	{
		server_print("The SQL database is currently disconnected.")
		return
	}
	
	if(g_BackupQueries)
	{
		server_print("There is already a backup in progress.")
		return
	}
	
	read_args(g_BackupName,32)
	trim(g_BackupName)
	remove_quotes(g_BackupName)
	
	if(!strlen(g_BackupName))
	{
		server_print("You must input a backup name")
		return
	}
	
	if(containi(g_BackupName,"_") != -1)
	{
		server_print("Your backup name cannot contain underscores (_).")
		return
	}
	
	switch(ARP_SqlMode())
	{
		case MYSQL:
			format(g_Query,4095,"SHOW TABLES")
		case SQLITE:
		{
			server_print("This option is not available on SQLite servers. The database file is located in ./amxmodx/data/sqlite3/ and can be copied for backup purposes.")
			return
		}
	}

	ARP_CleverQuery(g_SqlHandle,"BackupQueryHandle",g_Query)
}

public BackupQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	new Table[64],Database[64]
	get_pcvar_string(p_BackupDatabase,Database,63)
	while(SQL_MoreResults(Query))
	{		
		SQL_ReadResult(Query,0,Table,63)
		SQL_NextRow(Query)
		
		format(g_Query,4095,"CREATE TABLE %s.%s_%s AS SELECT * FROM %s",Database,g_BackupName,Table,Table)
		
		server_print("Backing up table %s to %s_%s",Table,g_BackupName,Table)
		
		SQL_ThreadQuery(g_SqlHandle,"BackupTableQueryHandle",g_Query)
		
		g_BackupQueries++
	}
	
	g_TotalBackupQueries = g_BackupQueries
	server_print("%d backup queries queued",g_BackupQueries)
	
	return PLUGIN_CONTINUE
}

public BackupTableQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	server_print("%d/%d tables backed up",g_TotalBackupQueries - --g_BackupQueries,g_TotalBackupQueries)
	
	if(!g_BackupQueries)
		server_print("Backup ^"%s^" complete",g_BackupName)
	
	return PLUGIN_CONTINUE
}
	
public CmdDelete()
{
	if(IsOffline())
	{
		server_print("The SQL database is currently disconnected.")
		return
	}
	
	read_args(g_BackupName,32)
	trim(g_BackupName)
	remove_quotes(g_BackupName)
	
	switch(ARP_SqlMode())
	{
		case MYSQL:
		{
			if(strlen(g_BackupName))
			{
				new Database[63]
				get_pcvar_string(p_BackupDatabase,Database,63)
				
				format(g_Query,4095,"SHOW TABLES IN %s",Database)
			}
			else	
				format(g_Query,4095,"SHOW TABLES")
		}
		case SQLITE:
			format(g_Query,4095,"SELECT * FROM sqlite_master WHERE type='table'")
	}
	ARP_CleverQuery(g_SqlHandle,"DeleteQueryHandle",g_Query)
}

public CmdQuery()
{
	if(IsOffline())
	{
		server_print("The SQL database is currently disconnected.")
		return
	}
	
	read_args(g_Query,4095)
	ARP_CleverQuery(g_SqlHandle,"UserQueryHandle",g_Query)
}

public UserQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	server_print("Query results...")
	
	new Buffer[256],i,NumColumns = SQL_NumColumns(Query),Column[33]
	for(i = 0;i < NumColumns;i++)
	{
		SQL_FieldNumToName(Query,i,Column,32)
		add(Buffer,255,Column)
		add(Buffer,255," ")
	}
	
	server_print("%s",Buffer)
	
	new Results = SQL_NumResults(Query)
	while(Results && SQL_MoreResults(Query))
	{
		Buffer[0] = '^0'
		
		for(i = 0;i < NumColumns;i++)
		{
			SQL_ReadResult(Query,i,Column,32)
			add(Buffer,255,Column)
			add(Buffer,255," ")
		}
		
		server_print("%s",Buffer)
		
		SQL_NextRow(Query)
	}
	
	server_print("Results: %d - Affected rows: %d",Results,SQL_AffectedRows(Query))
	
	return PLUGIN_CONTINUE
}

public DeleteQueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
		log_amx("Error on query: %s",Error)
	
	new Table[64],Column = ARP_SqlMode() == SQLITE ? 1 : 0,Database[64],Len = strlen(g_BackupName),Flag
	get_pcvar_string(p_BackupDatabase,Database,63)
	
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,Column,Table,63)
		SQL_NextRow(Query)
		
		if(Len)
		{
			if(!equali(Table,g_BackupName,Len))
				continue
			
			format(g_Query,4095,"DROP TABLE %s.%s;",Database,Table)
		}
		else
			format(g_Query,4095,"DROP TABLE %s;",Table)
		
		Flag = 1
		server_print("Dropping table %s",Table)
		
		ARP_CleverQuery(g_SqlHandle,"IgnoreHandle",g_Query)
	}
	
	server_print("Done data deletion")
	if(!Flag)
		server_print("No tables matching backup name ^"%s^"",g_BackupName)
	
	return PLUGIN_CONTINUE
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer. Error: %s",Error)
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	return PLUGIN_CONTINUE
}

public CmdConfig(id)
{	
	if(!IsOffline() && !ARP_AdminAccess(id) && !(get_user_flags(id) & ADMIN_BAN))
		return client_print(id,print_console,"You have no access to this command.")
		
	static Menu[MENU_OPTIONS * 64]
	new Pos
	
	Pos += format(Menu,MENU_OPTIONS * 64 - 1,"ARP Config Menu^n^n")
	for(new Count;Count < MENU_OPTIONS;Count++)
		Pos += format(Menu[Pos],MENU_OPTIONS * 64 - Pos - 1,"%i. %s^n",Count + 1,g_MenuOptions[Count])
	Pos += format(Menu[Pos],MENU_OPTIONS * 64 - Pos - 1,"^n0. Exit")
	
	show_menu(id,g_Keys,Menu,-1,g_MainMenu)
	
	return PLUGIN_HANDLED
}
		
public HandleCmdConfig(id,Key)
	switch(Key)
	{
		case 0 :
			FirstMember(id)
		case 1 :
			ChangeDatabase(id)
		case 2 :
			LoadSQLFile(id)
		default :
			if(Key != 9)
				CmdConfig(id)
	}
	
/*FirstSet()
{
	static Query[512],MemberTable[64]
	clan_get_membertable(MemberTable,63)
	
	format(Query,511,"SELECT * FROM %s",MemberTable)
	
	clan_sql_threaded_query(Query,"HandleFirstSet")
}

public HandleFirstSet(Handle:hQuery)
{
	if(!_:hQuery)
		return PLUGIN_CONTINUE
	
	new iNumRows = SQL_NumResults(hQuery)
	
	if(!iNumRows)
		g_bFirstSet = false
	else
		g_bFirstSet = true
		
	return PLUGIN_CONTINUE
}*/

FirstMember(id)
{			
	if(IsOffline())
	{
		client_print(id,print_chat,"[ARP] SQL connection is down - admin additions cannot be made.")
		
		return PLUGIN_CONTINUE
	}
	
	set_task(0.1,"FailedMessage",id)
	
	ARP_SetUserAccess(id,ARP_GetUserAccess(id) | ARP_AccessToInt("z"))
	
	g_Checker[id] = 1
	
	client_print(id,print_chat,"[ARP] You have been added as an admin.")
	
	return PLUGIN_CONTINUE
}

public FailedMessage(id)
	g_Checker[id] ? (g_Checker[id] = 0) : client_print(id,print_chat,"[ARP] Adding you as an admin has failed. Please check connection information.")

ChangeDatabase(id)
{
	new Offline = IsOffline()
	if(!Offline && !ARP_AdminAccess(id))
		return client_print(id,print_chat,"[ARP] You do not have access to this command.")
	
	if(Offline)
		client_print(id,print_chat,"[ARP] SQL connection failed - please change settings.")
	
	static Menu[DB_MENU_OPTIONS * 64],Setting[33]
	new Pos
	
	Pos += format(Menu,DB_MENU_OPTIONS * 64 - 1,"ARP Database Modification Menu^n^n")
	for(new Count;Count < DB_MENU_OPTIONS;Count++)
	{
		GetSetting(Count + 1,Setting,32)
		Pos += format(Menu[Pos],DB_MENU_OPTIONS * 64 - Pos - 1,"%i. %s: %s^n",Count + 1,g_DbMenuOptions[Count],Setting)
	}
	Pos += format(Menu[Pos],MENU_OPTIONS * 64 - Pos - 1,"^n0. Exit")
	
	show_menu(id,g_Keys,Menu,-1,g_DbMenu)
	
	return PLUGIN_CONTINUE
}

GetSetting(Setting,Format[],Len)
{
	if(!file_exists(g_LocalSqlFile))
		return
		
	new Line,Buffer[64],ByrefLen,Left[33],Right[33],Search[33]
	
	format(Search,32,"arp_sql_%s",g_DbMenuOptions[Setting - 1])
	while(read_file(g_LocalSqlFile,Line++,Buffer,63,ByrefLen))
	{
		if(containi(Buffer,Search) == -1)
			continue
		
		parse(Buffer,Left,32,Right,32)
		
		remove_quotes(Right)
		trim(Right)
		
		copy(Format,Len,Right)
		
		break
	}
}	

SetSetting(Setting,Format[])
{
	if(!file_exists(g_LocalSqlFile))
		return
		
	new Line,Buffer[64],ByrefLen,Left[33],Right[33],Search[33]
	
	format(Search,32,"arp_sql_%s",g_DbMenuOptions[Setting - 1])
	
	while(read_file(g_LocalSqlFile,Line++,Buffer,63,ByrefLen))
	{
		if(containi(Buffer,Search) == -1)
			continue
		
		parse(Buffer,Left,32,Right,32)
		
		format(Buffer,63,"%s ^"%s^"",Left,Format)
		
		write_file(g_LocalSqlFile,Buffer,Line - 1)
		
		break
	}
}
	
public HandleDbMenu(id,Key)
	if(Key < DB_MENU_OPTIONS && Key >= 0)
	{
		g_ModMode[id] = Key + 1
		client_print(id,print_chat,"[ARP] Please say (i.e. press y and type) what you would like to change this to, or say ^"cancel^" to stop.")
	}
	else if(Key == 9)
		return
	else
		ChangeDatabase(id)
			
LoadSQLFile(id)
{
	if(IsOffline())
	{
		client_print(id,print_chat,"[ARP] SQL connection failed - please check settings.")
		
		return
	}
	
	if(!ARP_AdminAccess(id))
	{
		client_print(id,print_chat,"[ARP] You do not have access to this command.")
		
		return
	}
	
	client_print(id,print_chat,"[ARP] Beginning SQL loading process.")
	
	new Line,ByrefLen,File[128],Mapname[33],Params[1]
	ARP_GetConfigsdir(File,127)
	get_mapname(Mapname,32)
	
	add(File,127,"/")
	add(File,127,Mapname)
	add(File,127,".sql")
	
	Params[0] = id
	
	g_Errors = 0
	g_Queries = 0
	g_Completed = 0
	
	if(!file_exists(File))
	{
		client_print(id,print_chat,"[ARP] No map configuration file found for this map.")
		
		return
	}
	
	while(read_file(File,Line++,g_Query,4095,ByrefLen))
	{
		if(g_Query[0] == ';' || g_Query[0] == '#' || g_Query[0] == '-' || strlen(g_Query) < 3)
			continue
		
		g_Queries++
		
		replace_all(g_Query,4095,g_DefaultUserTable,g_UserTable)
		replace_all(g_Query,4095,g_DefaultJobsTable,g_JobsTable)
		replace_all(g_Query,4095,g_DefaultPropertyTable,g_PropertyTable)
		replace_all(g_Query,4095,g_DefaultDoorsTable,g_DoorsTable)
		replace_all(g_Query,4095,g_DefaultKeysTable,g_KeysTable)
		replace_all(g_Query,4095,g_DefaultItemsTable,g_ItemsTable)
		replace_all(g_Query,4095,g_DefaultDataTable,g_DataTable)
		
		SQL_ThreadQuery(g_SqlHandle,"LoadHandle",g_Query,Params,1)
	}
}

public LoadHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
	{		
		SQL_QueryError(Query,g_Query,4095)
		
		server_print("Error: %s",g_Query)
	}	
	if(Errcode)
	{
		g_Errors++
		
		log_amx("Error on query: %s",Error)
	}
	
	// some bizarre error forces me to separate this
	g_Completed++
	
	client_print(Data[0],print_center,"%d/%d Completed - %d Errors",g_Completed,g_Queries,g_Errors)
	
	if(g_Completed == g_Queries)
	{
		client_print(Data[0],print_center,"Map SQL: Done!")
		client_print(Data[0],print_chat,"[ARP] Map SQL loading is complete. Please reload the map for settings to take effect.")
	}
	
	return PLUGIN_CONTINUE
}
	
public CmdSay(id)
{
	if(!g_ModMode[id])
		return PLUGIN_CONTINUE
		
	static Args[128]
	read_args(Args,127)
	
	remove_quotes(Args)
	trim(Args)
	
	if(equali(Args,"cancel"))
	{
		client_print(id,print_chat,"[ARP] %s modification cancelled.",g_DbMenuOptions[g_ModMode[id] - 1])
		
		g_ModMode[id] = 0
		
		return PLUGIN_HANDLED
	}
	
	replace_all(Args,127,"'","\'")
	
	SetSetting(g_ModMode[id],Args)
	
	client_print(id,print_chat,"[ARP] %s set, changes will take effect after map change.",g_DbMenuOptions[g_ModMode[id] - 1])
	
	g_ModMode[id] = 0
	
	return PLUGIN_HANDLED
}

IsOffline()
	return ARP_SqlHandle() == Empty_Handle || g_Offline
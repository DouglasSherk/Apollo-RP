// Whether or not to use ArrayX (doesn't work on Linux)
// #define ARRAYX

// Whether or not to enable debug mode (tracks amount of queries out, more or less useless)
// #define DEBUG

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <sqlx>
#include <hamsandwich>
//#include <tsx>
//#include <tfcx>
#include <ApolloRP>
#include <xs>
#include <tsfun>
#if defined ARRAYX
#include <arrayx_array>
#else
#include <arrayx_travtrie>
#endif

// CAPTAIN! WE NEED MORE DILITHIUM CRYSTALS!
#pragma dynamic 32768

#define STD_USER_QUERIES 3

#define USER_ITEM_SCAN new Success,Next = array_first(g_UserItemArray[id],0,Success); if(Success) for(;Success;Next = array_next(g_UserItemArray[id],Next,Success))

// the handle of the connection tuple
new Handle:g_SqlHandle
new SQLMODE:g_SqlMode

// the name of the users table
new g_UserTable[64] = "arp_users"
// the name of the jobs table
new g_JobsTable[64] = "arp_jobs"
// the name of the property table
new g_PropertyTable[64] = "arp_property"
// name of the doors table
new g_DoorsTable[64] = "arp_doors"
// door keys
new g_KeysTable[64] = "arp_keys"
// name of the items table
new g_ItemsTable[64] = "arp_items"
// name of the orgs table
//new g_OrgsTable[] = "arp_orgs"
// name of the data table
new g_DataTable[64] = "arp_data"

// SQL cvars, serve no purpose other than for other plugins
// in case they want to make their own tuple or something
new const g_HostCvar[] = "arp_sql_host"
new const g_UserCvar[] = "arp_sql_user"
new const g_PassCvar[] = "arp_sql_pass"
new const g_DbCvar[] = "arp_sql_db"
new const g_TypeCvar[] = "arp_sql_type"

new g_Host[64] = "localhost"
new g_User[64] = "root"
new g_Pass[64] = ""
new g_Db[64] = "arp"
new g_Type[64] = "sqlite"

new g_Authid[33][36]

new g_PluginEnd

// amount of jobs currently loaded
new g_JobsNum
// array for jobs
new g_JobsArray
// what the id of each job is
/*new g_JobIds[MAX_JOBS]
// where the jobs names are stored
new g_JobNames[MAX_JOBS][33]
// access of the jobs
new g_JobAccess[MAX_JOBS]
// salary of jobs
new g_JobSalaries[MAX_JOBS]*/

//new g_OrgsNum
//new g_OrgsArray

// rather than making "new Query" every time we use it,
// we'll instead just have one global variable to make
// it a lot faster and less resource consuming.
// this will also act as cache to speed other stuff up
new g_Query[4096]
new g_Cache[4096]

new g_BankMoney[33]
new g_Money[33]
new g_Salary[33]
new g_UserItemArray[33]
new g_UserItemNum[33]
new g_ItemUse[33]
new g_JobId[33]
new g_Hunger[33]
new g_Access[33]
new g_AccessCache[33]
new g_JobRight[33]
new g_BadJob[33]
new g_Falling[33]

#if defined DEBUG
new g_TotalQueries
#endif

new g_Plugin

new p_AuxType
/*new p_AuxX
new p_AuxY
new p_AuxR
new p_AuxG
new p_AuxB*/
new p_StartMoney
new p_ItemsPerPage
new p_SaveTime
new p_Lights
new p_WalletDeath
new p_GodDoors
new p_GodWindows
new p_FallDamage
new p_Performance
new p_Log
new p_GameName
new p_Welcome[3]
new p_HoverMessage
//new p_CharacterSheet

enum _:HUD_CVARS
{
	X = 0,
	Y,
	R,
	G,
	B
}

new p_Hud[HUD_NUM][HUD_CVARS]
new g_HudObjects[HUD_NUM]
new TravTrie:g_HudArray[33][HUD_NUM]
new g_HudPending

new g_Time

new g_ItemsArray
new g_ItemsNum

new TravTrie:g_EventTrie

new g_Display[33] = {1,...}

new g_GotInfo[33]
new g_Saving[33]
/*
new g_ItemsNames[MAX_ITEMS][33]
new g_ItemsIds[MAX_ITEMS]
new g_ItemsPlugin[MAX_ITEMS]
new g_ItemsHandler[MAX_ITEMS][33]
new g_ItemsDisposable[MAX_ITEMS]
new g_ItemsDescription[MAX_ITEMS][64]
*/

new g_NpcClassname[] = "arp_npc"
new g_NpcZoneClassname[] = "arp_zone"

new g_CommandNum
new g_CommandArray
//new g_CommandNames[MAX_COMMANDS][33]
//new g_CommandDescriptions[MAX_COMMANDS][64]

new g_RegisterItem

new g_MenuPage[33]
new g_CurItem[33]
new g_Keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9
new g_ItemsMenu[] = "ARP_ItemsMenu"
new g_ItemsDrop[] = "ARP_ItemsDrop"
new g_ItemsGive[] = "ARP_ItemsGive"
new g_ItemsOptions[] = "ARP_ItemsOptions"

new g_ItemClassname[] = "arp_item"
new g_ItemModel[] = "models/arp/w_backpack.mdl"

new TravTrie:g_ClassArray

new g_PropertyArray
new g_PropertyNum

new TravTrie:g_MenuArray[33]
new g_MenuAccepting[33]

//new TravTrie:g_Characters[33]

new g_DoorArray
new g_DoorNum

new g_Joined[33]

new Float:g_MaxSpeed[33]

new g_ConfigsDir[128]

new g_Version[] = ARP_VERSION

new TravTrie:g_PluginTrie

new TravTrie:g_SpeedTrie[33]
new Float:g_SpeedOverride[33]
new g_SpeedOverridePlugin[33]

enum MODS
{
	HL = 0,
	TS,
	TFC,
	CS
}

new MODS:g_Mod

public plugin_init()
{			
	register_cvar("arp_version",g_Version,FCVAR_SERVER)
	
	register_menucmd(register_menuid(g_ItemsMenu),g_Keys,"ItemsHandle")
	register_menucmd(register_menuid(g_ItemsOptions),g_Keys,"ItemsOptions")
	register_menucmd(register_menuid(g_ItemsDrop),g_Keys,"ItemsDrop")
	register_menucmd(register_menuid(g_ItemsGive),g_Keys,"ItemsGive")
	
	new ConfigsDir[128]
	get_configsdir(ConfigsDir,127)
	server_cmd("exec %s/arp/arp.cfg",ConfigsDir)
	
	// I don't like doing this, but since TSRP generally
	// has too many ents, I'm going to avoid spawning an
	// ent and making it think every second.
	// This will also calculate time.
	set_task(1.0,"ShowHud")
	set_task(get_pcvar_float(p_SaveTime),"SaveData")
	
	register_event("DeathMsg","EventDeathMsg","a")
	register_event("ResetHUD","EventResetHUD","b")
	
	register_forward(FM_Sys_Error,"plugin_end")
	//register_forward(FM_GetGameDescription,"ForwardGetGameDescription")
	register_forward(FM_SetClientMaxspeed,"ForwardSetClientMaxspeed")
	
	ARP_RegisterCmd("say /buy","CmdBuy","Allows you to buy properties you're looking at")
	ARP_RegisterCmd("say /items","CmdItems","Shows your items and allows you to control them")
	ARP_RegisterCmd("say /inventory","CmdItems","Shows your items and allows you to control them")
	ARP_RegisterCmd("arp_joblist","CmdJobList","Shows jobs list")
	ARP_RegisterCmd("arp_itemlist","CmdItemList","Shows item list")
	ARP_RegisterCmd("arp_help","CmdHelp","Shows command list")
	ARP_RegisterCmd("arp_menu","CmdMenu","Shows client menu")
	ARP_RegisterCmd("say /menu","CmdMenu","Shows client menu")
	ARP_RegisterCmd("arp_plugins","CmdPlugins","Shows current plugins running")
	ARP_RegisterCmd("arp_query","CmdQuery","(ADMIN) Executes an SQL query")
	
	register_touch("player","func_door","PlayerTouch")
	register_touch("func_door","player","PlayerTouch")
	register_touch("player","func_door_rotating","PlayerTouch")
	register_touch("func_door_rotating","player","PlayerTouch")
	
	for(new Count;Count < HUD_NUM;Count++)
		g_HudObjects[Count] = CreateHudSyncObj()
	
	//register_clcmd("amx_employ","CmdEmploy")
	//register_clcmd("amx_setwallet","CmdSetWallet")
	//register_clcmd("amx_setbank","CmdSetBank")
	//register_clcmd("amx_setjob","CmdSetJob")
	
	//register_touch(g_ItemClassname,"player","TouchItem")
	//register_touch("player",g_ItemClassname,"TouchItem2")
	
	#if defined DEBUG
	register_clcmd("arp_queries","CmdQueries")
	#endif
	
	set_task(1.0,"GodEnts")
	
	if(module_exists("tsfun") || module_exists("tsx")) g_Mod = TS
	else if(module_exists("tfcx")) g_Mod = TFC
	else if(module_exists("csx") || module_exists("cstrike")) g_Mod = CS
	// No such module
	else /*if(module_exists("svencoop")*/ g_Mod = HL
	
	if(g_Mod != TS && g_Mod != CS) 
	{
		new Mod[12]
		get_modname(Mod,11)
		
		server_print("Apollo RP is optimized for The Specialists and Counter-Strike. Some functionality will be disabled to allow operation on ^"%s^".",Mod)
	}
	
	//register_concmd("getclasses","CmdGetClasses")
}

#if 0
public CmdGetClasses(id)
{
	new travTrieIter:Iter = GetTravTrieIterator(g_ClassArray),Cell,ClassHeader[64],Loaded,TravTrie:CurTrie,TravTrie:PluginTrie,Flag,ReadTable[64],Garbage[1]
	while(MoreTravTrie(Iter))
	{		
		ReadTravTrieKey(Iter,ClassHeader,63)
		ReadTravTrieCell(Iter,Cell)
		
		client_print(id,print_console,"ClassHeader:%s",ClassHeader)
		server_print("ClassHeader:%s",ClassHeader)
	}
	DestroyTravTrieIterator(Iter)
}
#endif

public ModuleFilter(const Module[])
{
    if(equali(Module,"tsfun") || equali(Module,"tsx") || equali(Module,"xstats") || equali(Module,"tfcx") || equali(Module,"cstrike") || equali(Module,"csx"))
        return PLUGIN_HANDLED
	
    return PLUGIN_CONTINUE
}

public NativeFilter(const Name[],Index,Trap)
{
    if(!Trap)
        return PLUGIN_HANDLED
        
    return PLUGIN_CONTINUE
}

public GodEnts()
{	
	if(get_pcvar_num(p_GodDoors))
	{
		new Ent
		while((Ent = find_ent_by_class(Ent,"func_door")) != 0)
			entity_set_float(Ent,EV_FL_takedamage,0.0)
		
		Ent = 0
		while((Ent = find_ent_by_class(Ent,"func_door_rotating")) != 0)
			entity_set_float(Ent,EV_FL_takedamage,0.0)
	}
	
	if(get_pcvar_num(p_GodWindows))
	{
		new Ent
		while((Ent = find_ent_by_class(Ent,"func_breakable")) != 0)
			entity_set_float(Ent,EV_FL_takedamage,0.0)
	}
}

public ForwardGetGameDescription()
{
	static GameName[33]
	get_pcvar_string(p_GameName,GameName,32)
	
	if(GameName[0])
	{
		forward_return(FMV_STRING,GameName)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

#if defined DEBUG
public CmdQueries(id,cid)
{
	if(ARP_CmdAccess(id,cid,1))
		client_print(id,print_chat,"Total queries out: %d",g_TotalQueries)
	
	return PLUGIN_HANDLED
}
#endif

public CmdQuery(id,cid)
{
	if(!ARP_CmdAccess(id,cid,2))
		return PLUGIN_HANDLED
	
	new Args[512]
	read_args(Args,511)
	
	remove_quotes(Args)
	trim(Args)
	
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",Args)
	
	console_print(id,"Query executed.")
	
	return PLUGIN_HANDLED
}

public CmdPlugins(id)
{
	new travTrieIter:Iter = GetTravTrieIterator(g_PluginTrie),Plugin,Name[33],Version[10],Author[33],Status[24],Description[128],Garbage[1],Count,Num
	console_print(id,"Apollo RP %s Addons Loaded^nNAME       VERSION   AUTHOR          DESCRIPTION",ARP_VERSION)
	
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKeyEx(Iter,Plugin)
		ReadTravTrieString(Iter,Description,127)
		
		arrayset(Name,0,33)
		arrayset(Version,0,10)
		arrayset(Author,0,33)
		
		get_plugin(Plugin,Garbage,0,Name,32,Version,9,Author,32,Status,23)
		
		if(!equali(Status,"running"))
			continue
		
		for(Count = strlen(Name);Count < 16;Count++)
			Name[Count] = ' '
		
		for(Count = strlen(Version);Count < 9;Count++)
			Version[Count] = ' '
		
		for(Count = strlen(Author);Count < 20;Count++)
			Author[Count] = ' '	
		
		replace(Name,32,"ARP - ","")
		
		console_print(id,"%s %s %s %s",Name,Version,Author,Description)
		Num++
	}
	DestroyTravTrieIterator(Iter)
	
	console_print(id,"%d addons loaded",Num)
	
	return PLUGIN_HANDLED
}

public CmdMenu(id)
{
	TravTrieClear(g_MenuArray[id])
	
	g_MenuAccepting[id] = 1
	
	new Data[1]
	Data[0] = id
	if(_CallEvent("Menu_Display",Data,1))
		return PLUGIN_HANDLED
	
	g_MenuAccepting[id] = 0
	
	new Size = TravTrieSize(g_MenuArray[id])
	if(!Size)
	{
		client_print(id,print_chat,"[ARP] There are no items in the menu.")
		return PLUGIN_HANDLED
	}
	
	new travTrieIter:Iter = GetTravTrieIterator(g_MenuArray[id]),Key[64],Menu = menu_create("ARP Client Menu","ClientMenuHandle"),Info[128]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,63)
		ReadTravTrieString(Iter,Info,127)
		
		menu_additem(Menu,Key,Info)
	}
	DestroyTravTrieIterator(Iter)
	
	menu_display(id,Menu,0)
	
	return PLUGIN_HANDLED
}

public ClientMenuHandle(id,Menu,Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Info[128],Name[2],Access,Callback
	menu_item_getinfo(Menu,Item,Access,Info,127,Name,1,Callback)
	
	new Forward = CreateOneForward(Info[0],Info[1],FP_CELL),Return
	if(!Forward || !ExecuteForward(Forward,Return,id))
	{
		menu_destroy(Menu)
		format(g_Query,sizeof g_Query - 1,"Function does not exist in plugin %d: %s",Info[0],Info[1])
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	DestroyForward(Forward)
	
	menu_destroy(Menu)
	
	return PLUGIN_HANDLED
}

public client_kill(id)
{
	client_print(id,print_console,"You cannot commit suicide in this server.")
	return PLUGIN_HANDLED
}

public SaveData()
{
	new Data[1]
	if(_CallEvent("Core_Save",Data,0))
	{
		new Float:Performance = get_pcvar_float(p_Performance)
	
		// epsilon format for IEEE precision (if it's 0)
		if(Performance > 0.1)
			set_task(get_pcvar_float(p_SaveTime) * Performance / 100.0,"SaveData")
		
		return
	}
	
	new Players[32],Playersnum
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
		if(g_GotInfo[Players[Count]] >= STD_USER_QUERIES)
			SaveUserData(Players[Count],0)
	
	new InternalName[64],ExternalName[64],OwnerName[33],OwnerAuthid[36],Price,Locked,AccessStr[JOB_ACCESSES + 1],Access,Profit,CurArray,MapName[33],Targetname[33],EntID,Changed
	get_mapname(MapName,32)
	
	for(new Count;Count < g_PropertyNum;Count++)
	{		
		CurArray = array_get_int(g_PropertyArray,Count)
		
		Changed = array_get_int(CurArray,9)
		if(!Changed)
			continue
		
		array_get_string(CurArray,0,InternalName,63)
		array_get_string(CurArray,1,ExternalName,63)
		array_get_string(CurArray,2,OwnerName,32)
		array_get_string(CurArray,3,OwnerAuthid,32)
		Price = array_get_int(CurArray,4)
		Locked = array_get_int(CurArray,5)
		Access = array_get_int(CurArray,6)
		Profit = array_get_int(CurArray,7)	
		
		ARP_SqlEscape(InternalName,63)
		ARP_SqlEscape(ExternalName,63)
		ARP_SqlEscape(OwnerName,32)
		//replace_all(ExternalName,32,"'","\'")
		//replace_all(OwnerName,32,"'","\'")
		
		ARP_IntToAccess(Access,AccessStr,JOB_ACCESSES)
		
		#if defined DEBUG
		g_TotalQueries++
		#endif
		
		switch(g_SqlMode)
		{
			case MYSQL:
				format(g_Query,4095,"INSERT INTO %s VALUES ('%s','%s','%s','%s','%d','%d','%s','%d') ON DUPLICATE KEY UPDATE externalname='%s',ownername='%s',ownerauth='%s',price='%d',locked='%d',access='%s',profit='%d'",g_PropertyTable,InternalName,ExternalName,OwnerName,OwnerAuthid,Price,Locked,AccessStr,Profit,ExternalName,OwnerName,OwnerAuthid,Price,Locked,AccessStr,Profit)
			case SQLITE:
				format(g_Query,4095,"INSERT OR REPLACE INTO %s VALUES ('%s','%s','%s','%s','%d','%d','%s','%d')",g_PropertyTable,InternalName,ExternalName,OwnerName,OwnerAuthid,Price,Locked,AccessStr,Profit)
		}
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	}
	
	for(new Count;Count < g_DoorNum;Count++)
	{
		CurArray = array_get_int(g_DoorArray,Count)
		
		Changed = array_get_int(CurArray,3)
		if(!Changed)
			continue
		
		array_get_string(CurArray,0,Targetname,32)
		EntID = array_get_int(CurArray,1)
		array_get_string(CurArray,2,InternalName,32)
		
		EntID ? format(Targetname,32,"e|%d",EntID) : format(Targetname,32,"t|%s",Targetname)
		
		#if defined DEBUG
		g_TotalQueries++
		#endif
		
		ARP_SqlEscape(InternalName,charsmax(InternalName))
		
		switch(g_SqlMode)
		{
			case MYSQL:
				format(g_Query,4095,"INSERT INTO %s VALUES ('%s','%s') ON DUPLICATE KEY UPDATE internalname='%s'",g_DoorsTable,Targetname,InternalName,InternalName)
			case SQLITE:
				format(g_Query,4095,"INSERT OR REPLACE INTO %s VALUES ('%s','%s')",g_DoorsTable,Targetname,InternalName)
		}
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	}
		
	new Float:Performance = get_pcvar_float(p_Performance)
	
	// epsilon format for IEEE precision (if it's 0)
	if(Performance > 0.1)
		set_task(get_pcvar_float(p_SaveTime) * Performance / 100.0,"SaveData")
}

SaveUserItems(id)
{
	new Authid[36],ItemId,ItemName[33],Size = array_size(g_UserItemArray[id]) + 1
	
	if(Size < 2)
		return
	
	get_user_authid(id,Authid,35)
	
	for(new Count = 1,Success = 1;Count < Size && Success;Count++)
	{
		ItemId = array_get_nth(g_UserItemArray[id],Count,_,Success)
		if(ItemId < 1 || !Success)
			continue
		
		UTIL_ARP_GetItemName(ItemId,ItemName,32)
		
		new Num = array_get_int(g_UserItemArray[id],ItemId)
		if(Num < 1)
			continue
		
		#if defined DEBUG
		g_TotalQueries++
		#endif
		
		ARP_SqlEscape(ItemName,32)
		//replace_all(ItemName,32,"'","\'")
		
		//format(g_Query,511,"IF EXISTS (SELECT * FROM %s WHERE authid='%s' AND itemid='%d')^nUPDATE %s SET num='%d' WHERE authid='%s' AND itemid='%d'^nELSE^nINSERT INTO %s VALUES('%s','%d','%d')",g_ItemsTable,Authid,ItemId,g_ItemsTable,Num,Authid,ItemId,g_ItemsTable,Authid,ItemId,Num)
		switch(g_SqlMode)
		{
			case MYSQL:
				format(g_Query,4095,"INSERT INTO %s VALUES('%s|%s','%d') ON DUPLICATE KEY UPDATE num='%d'",g_ItemsTable,Authid,ItemName,abs(Num),abs(Num))
			case SQLITE:
				format(g_Query,4095,"INSERT OR REPLACE INTO %s VALUES('%s|%s','%d')",g_ItemsTable,Authid,ItemName,abs(Num))
		}
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
		
		Num = -abs(Num)
		
		//format(g_Query,511,"SELECT * FROM %s WHERE authid='%s' AND itemid='%d'",g_ItemsTable,Authid,ItemId)
		//UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"SaveClientItems",g_Query,Data,3)
		//Id = array_get_int(array_get_int(g_UserItemArray[id],Count + 1),1)
		//Num = array_get_int(array_get_int(g_UserItemArray[id],Count + 1),2)
		
		//if(Id && Num)
		//	Pos += format(Items[Pos],511,"%d|%d ",Id,Num)
	}
	
	//if(g_PluginEnd)
	//	array_destroy(g_UserItemArray[id])
}

public PlayerTouch(Touched,Toucher)
{
	if(get_pcvar_num(p_Performance) < 70)
		return PLUGIN_CONTINUE		
	
	new Result = CheckTouched(Touched)
	if(Result)
		return RunResult(Result,Touched,Toucher)
	
	Result = CheckTouched(Toucher)
	if(Result)
		return RunResult(Result,Touched,Toucher)
	
	return PLUGIN_CONTINUE
}

RunResult(Result,Touched,Toucher)
{
	switch(Result)
	{
		case 1 :
		{
			if(is_user_alive(Touched))
			{
				force_use(Touched,Toucher)
				fake_touch(Toucher,Touched)
			}
			else if(is_user_alive(Toucher))
			{
				force_use(Toucher,Touched)
				fake_touch(Touched,Toucher)
			}
		}
		case 2 :
			return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

CheckTouched(Index)
{
	new Classname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	if(equali(Classname,"func_door") || equali(Classname,"func_door_rotating"))
	{
		static Targetname[33],CurTargetname[33]
		entity_get_string(Index,EV_SZ_targetname,CurTargetname,32)
		
		for(new Count,Property;Count < g_DoorNum;Count++)
		{			
			array_get_string(array_get_int(g_DoorArray,Count),0,Targetname,32)
			if((CurTargetname[0] && Targetname[0] && equali(Targetname,CurTargetname)) || (array_isfilled(array_get_int(g_DoorArray,Count),1) && Index == array_get_int(array_get_int(g_DoorArray,Count),1) && is_valid_ent(Index)))
			{				
				Property = UTIL_ARP_GetProperty(Targetname,Index)
				if(Property == -1)
					return PLUGIN_CONTINUE
				
				return array_get_int(array_get_int(g_PropertyArray,Property),5) + 1
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public plugin_precache()
{	
	g_Plugin = register_plugin("ARP - Core",g_Version,"The Apollo RP Team")
	
	p_StartMoney = register_cvar("arp_startmoney","500")
	p_ItemsPerPage = register_cvar("arp_items_per_page","30")
	p_SaveTime = register_cvar("arp_save_interval","30")
	p_Lights = register_cvar("arp_lights","q")
	p_GodDoors = register_cvar("arp_goddoors","1")
	p_GodWindows = register_cvar("arp_godwindows","1")
	p_FallDamage = register_cvar("arp_falldamage","1")
	p_AuxType = register_cvar("arp_hud4_type","1")
	p_Performance = register_cvar("arp_performance","100")
	p_Log = register_cvar("arp_log","1")
	p_GameName = register_cvar("arp_gamename","")
	p_HoverMessage = register_cvar("arp_hover_message","1")
	//p_CharacterSheet = register_cvar("arp_character_sheet","1")
	
	p_Welcome[0] = register_cvar("arp_welcome_msg1","This server is running Apollo RP (http://ApolloRP.org).")
	p_Welcome[1] = register_cvar("arp_welcome_msg2","Type ^"arp_help^" in your console to get started.")
	p_Welcome[2] = register_cvar("arp_welcome_msg3","")
	
	for(new Count,Cvar[33];Count < HUD_NUM;Count++)
	{
		format(Cvar,32,"arp_hud%d_x",Count + 1)
		p_Hud[Count][X] = register_cvar(Cvar,"")
		
		format(Cvar,32,"arp_hud%d_y",Count + 1)
		p_Hud[Count][Y] = register_cvar(Cvar,"")
		
		format(Cvar,32,"arp_hud%d_r",Count + 1)
		p_Hud[Count][R] = register_cvar(Cvar,"")
		
		format(Cvar,32,"arp_hud%d_g",Count + 1)
		p_Hud[Count][G] = register_cvar(Cvar,"")
		
		format(Cvar,32,"arp_hud%d_b",Count + 1)
		p_Hud[Count][B] = register_cvar(Cvar,"")
	}
	
	p_WalletDeath = register_cvar("arp_wallet_death","1")
	/*p_AuxType = register_cvar("arp_auxhud_type","2")
	p_AuxX = register_cvar("arp_auxhud_x","0.4")
	p_AuxY = register_cvar("arp_auxhud_y","0.7")
	p_AuxR = register_cvar("arp_auxhud_r","255")
	p_AuxG = register_cvar("arp_auxhud_g","0")
	p_AuxB = register_cvar("arp_auxhud_b","0")*/
	
	register_cvar(g_HostCvar,"")
	register_cvar(g_UserCvar,"")
	register_cvar(g_PassCvar,"")
	register_cvar(g_DbCvar,"")
	register_cvar(g_TypeCvar,"")
	
	register_cvar(g_PoliceAccessCvar,"a")
	register_cvar(g_MedicalAccessCvar,"b")
	register_cvar(g_AdminAccessCvar,"z")
	
	new MapName[33],ConfigFile[128]
	
	get_configsdir(ConfigFile,127)
	add(ConfigFile,127,"/arp/arp.ini")
	
	get_mapname(MapName,sizeof MapName - 1)
	get_configsdir(g_Query,sizeof g_Query - 1)
	format(g_ConfigsDir,sizeof g_ConfigsDir - 1,"%s/arp/maps/%s",g_Query,MapName)
	
	if(!dir_exists(g_ConfigsDir))
	{
		format(g_Query,sizeof g_Query - 1,"Configuration directory missing: %s",g_ConfigsDir)
		UTIL_ARP_ThrowError(0,0,g_Query,0)
	}

	new File = fopen(ConfigFile,"r")
	if(!File)
	{
		format(g_Query,4095,"Could not open core config file (%s).",ConfigFile)
		UTIL_ARP_ThrowError(0,0,g_Query,0)
	}

	LoadConfigFile(File)

	format(ConfigFile,127,"%s/arp.ini",g_ConfigsDir)
	if(file_exists(ConfigFile))
	{
		File = fopen(ConfigFile,"r")
		if(File)
			LoadConfigFile(File)
	}

	if(file_exists(g_ItemModel))
		precache_model(g_ItemModel)
	else
	{
		format(g_Query,sizeof g_Query - 1,"Item model missing: %s",g_ItemModel)
		UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	g_ItemsArray = array_create()
	
	for(new Count;Count < 33;Count++)
	{
		g_MenuArray[Count] = TravTrieCreate()
		//g_Characters[Count] = TravTrieCreate()
		g_UserItemArray[Count] = array_create()
		for(new Count2;Count2 < HUD_NUM;Count2++)
			g_HudArray[Count][Count2] = TravTrieCreate(256,_)
		//g_HudArray[Count] = TravTrieCreate()
		
		g_SpeedTrie[Count] = TravTrieCreate()
	}
	
	g_JobsArray = array_create()
	g_CommandArray = array_create()
	g_PropertyArray = array_create()
	g_DoorArray = array_create()
	g_ClassArray = TravTrieCreate()
	g_EventTrie = TravTrieCreate()
	g_PluginTrie = TravTrieCreate()
	
	g_RegisterItem = 1
	
	new Forward = CreateMultiForward("ARP_RegisterItems",ET_IGNORE),Return
	if(!Forward || !ExecuteForward(Forward,Return))
		UTIL_ARP_ThrowError(0,0,"Could not execute ^"ARP_RegisterItems^" forward.",0)
	DestroyForward(Forward)
		
	g_RegisterItem = 0
	
	SqlInit()
}

LoadConfigFile(File)
{
	new ConfigFile[128],Left[128],Right[128]
	
	while(!feof(File))
	{
		// bad naming application, but whatever
		fgets(File,ConfigFile,sizeof ConfigFile - 1)
		trim(ConfigFile)
		
		if(ConfigFile[0] == ';')
			continue
		
		parse(ConfigFile,Left,sizeof Left - 1,Right,sizeof Right - 1)
		remove_quotes(Left)
		trim(Left)
		remove_quotes(Right)
		trim(Right)
		
		if(Left[0] && Right[0])
		{
			if(equali(Left,g_HostCvar))
			{
				set_cvar_string(g_HostCvar,Right)
				copy(g_Host,sizeof g_Host - 1,Right)
			}
			else if(equali(Left,g_UserCvar))
			{
				set_cvar_string(g_UserCvar,Right)
				copy(g_User,sizeof g_User - 1,Right)
			}
			else if(equali(Left,g_PassCvar))
			{
				set_cvar_string(g_PassCvar,Right)
				copy(g_Pass,sizeof g_Pass - 1,Right)
			}
			else if(equali(Left,g_DbCvar))
			{
				set_cvar_string(g_DbCvar,Right)
				copy(g_Db,sizeof g_Db - 1,Right)
			}
			else if(equali(Left,g_TypeCvar))
			{
				set_cvar_string(g_TypeCvar,Right)
				copy(g_Type,sizeof g_Type - 1,Right)
			}
			else if(equali(Left,"arp_table_users"))
				copy(g_UserTable,sizeof g_UserTable - 1,Right)
			else if(equali(Left,"arp_table_jobs"))
				copy(g_JobsTable,sizeof g_JobsTable - 1,Right)
			else if(equali(Left,"arp_table_property"))
				copy(g_PropertyTable,sizeof g_PropertyTable - 1,Right)
			else if(equali(Left,"arp_table_doors"))
				copy(g_DoorsTable,sizeof g_DoorsTable - 1,Right)
			else if(equali(Left,"arp_table_keys"))
				copy(g_KeysTable,sizeof g_KeysTable - 1,Right)
			else if(equali(Left,"arp_table_items"))
				copy(g_ItemsTable,sizeof g_ItemsTable - 1,Right)
		}
	}
	
	fclose(File)
}

public SqlInit()
{
	new Type[64]
	SQL_GetAffinity(Type,sizeof Type - 1)
	
	if(!equali(Type,g_Type) && !SQL_SetAffinity(g_Type))
	{
		format(g_Query,sizeof g_Query - 1,"Failed to set SQL affinity from %s to %s.",Type,g_Type)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(equali(g_Type,"mysql")) g_SqlMode = MYSQL
	else if(equali(g_Type,"sqlite")) g_SqlMode = SQLITE
	
	g_SqlHandle = SQL_MakeDbTuple(g_Host,g_User,g_Pass,g_Db)
	if(g_SqlHandle == Empty_Handle)
	{
		format(g_Query,4095,"Failed to create SQL tuple.")
		UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlHandle,ErrorCode,g_Query,4095)
	if(ErrorCode)
	{
		g_SqlHandle = Empty_Handle
		format(g_Query,4095,"Could not connect to SQL database: %s", g_Query)
		UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	SQL_FreeHandle(SqlConnection)
	
	// one of the problems with the original harbu was authid not
	// being 36 max chars. the max is really 36, not 32.
	
	#if defined DEBUG
	g_TotalQueries += 7
	#endif
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR(36),bankmoney INT(11),wallet INT(11),jobname VARCHAR(36),hunger INT(11),access VARCHAR(27),jobright VARCHAR(27),UNIQUE KEY (authid))",g_UserTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR(36),bankmoney INT(11),wallet INT(11),jobname VARCHAR(36),hunger INT(11),access VARCHAR(27),jobright VARCHAR(27),UNIQUE (authid))",g_UserTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (name VARCHAR(32),salary INT(11),access VARCHAR(27),UNIQUE KEY (name))",g_JobsTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (name VARCHAR(32),salary INT(11),access VARCHAR(27),UNIQUE (name))",g_JobsTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (internalname VARCHAR(66),externalname VARCHAR(66),ownername VARCHAR(40),ownerauth VARCHAR(36),price INT(11),locked INT(11),access VARCHAR(27),profit INT(11),UNIQUE KEY (internalname))",g_PropertyTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (internalname VARCHAR(66),externalname VARCHAR(66),ownername VARCHAR(40),ownerauth VARCHAR(36),price INT(11),locked INT(11),access VARCHAR(27),profit INT(11),UNIQUE (internalname))",g_PropertyTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (targetname VARCHAR(36),internalname VARCHAR(66),UNIQUE KEY (targetname))",g_DoorsTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (targetname VARCHAR(36),internalname VARCHAR(66),UNIQUE (targetname))",g_DoorsTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authidkey VARCHAR(64),UNIQUE KEY (authidkey))",g_KeysTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authidkey VARCHAR(64),UNIQUE (authidkey))",g_KeysTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authidname VARCHAR(64),num INT(11),UNIQUE KEY (authidname))",g_ItemsTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (authidname VARCHAR(64),num INT(11),UNIQUE (authidname))",g_ItemsTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	switch(g_SqlMode)
	{
		case MYSQL:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (classkey VARCHAR(64),value TEXT,UNIQUE KEY (classkey))",g_DataTable)
		case SQLITE:
			format(g_Query,4095,"CREATE TABLE IF NOT EXISTS %s (classkey VARCHAR(64),value TEXT,UNIQUE (classkey))",g_DataTable)
	}
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	format(g_Query,4095,"SELECT * FROM %s",g_JobsTable)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchJobs",g_Query)
	
	format(g_Query,4095,"SELECT * FROM %s",g_PropertyTable)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchProperties",g_Query)
	
	format(g_Query,4095,"SELECT * FROM %s",g_DoorsTable)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchDoors",g_Query)
	
	new Forward = CreateMultiForward("ARP_Init",ET_IGNORE),Return
	if(Forward <= 0 || !ExecuteForward(Forward,Return))
	{
		format(g_Query,4095,"Could not create ARP_Init forward.")
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	return DestroyForward(Forward)
}

public FetchProperties(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new InternalName[64],ExternalName[64],OwnerName[33],OwnerAuthid[36],Price,Locked,AccessStr[JOB_ACCESSES + 1],Access,Profit
	if(!SQL_NumResults(Query))
		return PLUGIN_CONTINUE
	
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,0,InternalName,63)
		SQL_ReadResult(Query,1,ExternalName,63)
		SQL_ReadResult(Query,2,OwnerName,32)
		SQL_ReadResult(Query,3,OwnerAuthid,35)
		Price = SQL_ReadResult(Query,4)
		Locked = SQL_ReadResult(Query,5)
		SQL_ReadResult(Query,6,AccessStr,JOB_ACCESSES)
		Access = ARP_AccessToInt(AccessStr)
		Profit = SQL_ReadResult(Query,7)
		
		new CurArray = array_create()
		array_set_int(g_PropertyArray,g_PropertyNum++,CurArray)
		
		array_set_string(CurArray,0,InternalName)
		array_set_string(CurArray,1,ExternalName)
		array_set_string(CurArray,2,OwnerName)
		array_set_string(CurArray,3,OwnerAuthid)
		array_set_int(CurArray,4,Price)
		array_set_int(CurArray,5,Locked)
		array_set_int(CurArray,6,Access)
		array_set_int(CurArray,7,Profit)	
		array_set_int(CurArray,8,0)
		array_set_int(CurArray,9,0)
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}

public FetchDoors(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new Targetname[64],InternalName[64]
	while(SQL_MoreResults(Query))
	{		
		SQL_ReadResult(Query,0,Targetname,63)
		SQL_ReadResult(Query,1,InternalName,63)
		
		new CurArray = array_create()
		array_set_int(g_DoorArray,g_DoorNum,CurArray)
		g_DoorNum++
		
		if(equali(Targetname,"e|",2))
		{
			replace(Targetname,63,"e|","")
			array_set_string(CurArray,0,"")
			array_set_int(CurArray,1,str_to_num(Targetname))	
		}
		else if(equali(Targetname,"t|",2))
		{
			replace(Targetname,63,"t|","")
			array_set_string(CurArray,0,Targetname)
			array_set_int(CurArray,1,0)	
		}
		
		array_set_string(CurArray,2,InternalName)
		array_set_int(CurArray,3,0)
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}

public FetchJobs(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
		
	new Temp[JOB_ACCESSES + 1],CurArray
	while(SQL_MoreResults(Query))
	{
		CurArray = array_create()
		array_set_int(g_JobsArray,g_JobsNum++,CurArray)
		
		SQL_ReadResult(Query,0,g_Query,4095)
		array_set_string(CurArray,1,g_Query)
		
		array_set_int(CurArray,2,SQL_ReadResult(Query,1))
		
		SQL_ReadResult(Query,2,Temp,JOB_ACCESSES)
		array_set_int(CurArray,3,ARP_AccessToInt(Temp))
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}

public plugin_end()
{	
	server_cmd("totaltravtries")
	
	g_PluginEnd = 1
	
	SaveData()
	
	new Players[32],Playersnum
	get_players(Players,Playersnum)
	
	/*
	for(new Count,Count2,Count3,CurArray;Count < Playersnum;Count++)
	{
		id = Players[Count]
		for(Count2 = 0;Count2 < HUD_NUM;Count2++)
		{
			ClearHud(id,Count2)
			for(Count3 = 0;Count3 < g_HudNum[id][Count2];Count3++)
			{
				CurArray = array_get_int(g_HudArray[id][Count2],Count3)
				array_destroy(CurArray)
			}
		}
	}
	*/
	
	for(new Count,Count2;Count < 33;Count++)	
	{
		array_destroy(g_UserItemArray[Count])
		TravTrieDestroy(g_MenuArray[Count])
		//TravTrieDestroy(g_HudArray[Count])
		for(Count2 = 0;Count2 < HUD_NUM;Count2++)
			TravTrieDestroy(g_HudArray[Count][Count2])
	}
	
	new Num
	
	for(new Count;Count < g_CommandNum;Count++)
	{
		Num = array_get_int(g_CommandArray,Count + 1)
		array_destroy(Num)
	}
	
	for(new Count;Count < g_JobsNum;Count++)
	{
		Num = array_get_int(g_JobsArray,Count)
		array_destroy(Num)
	}
	
	for(new Count;Count < g_PropertyNum;Count++)
	{
		Num = array_get_int(g_PropertyArray,Count)
		array_destroy(Num)
	}
	
	for(new Count;Count < g_DoorNum;Count++)
	{
		Num = array_get_int(g_DoorArray,Count)
		array_destroy(Num)
	}
	
	array_destroy(g_JobsArray)
	array_destroy(g_PropertyArray)
	array_destroy(g_CommandArray)
	array_destroy(g_DoorArray)
	//TravTrieDestroy(g_ClassArray)
	array_destroy(g_ItemsArray)
	TravTrieDestroy(g_EventTrie)
	TravTrieDestroy(g_PluginTrie)
		
	SQL_FreeHandle(g_SqlHandle)
}
		
public client_disconnect(id)	
{
	if(g_GotInfo[id] >= STD_USER_QUERIES && !g_PluginEnd)
	{
		SaveUserData(id,1)
		g_GotInfo[id] = 0
	}
	
	g_SpeedOverride[id] = 0.0
	g_SpeedOverridePlugin[id] = 0
	
	TravTrieClear(g_SpeedTrie[id])
	
	//g_DisplayCharacterMenu[id] = 0
}

public SaveUserData(id,Disconnected)
{
	new Data[2]
	Data[0] = id
	Data[1] = Disconnected
	_CallEvent("Player_Save",Data,2)
	
	SaveUserItems(id)
	
	new Access[27],JobRight[27],JobName[33]
	ARP_IntToAccess(g_AccessCache[id],Access,26)
	ARP_IntToAccess(g_JobRight[id],JobRight,26)
	array_get_string(array_get_int(g_JobsArray,g_JobId[id]),1,JobName,32)
	
	get_user_authid(id,g_Authid[id],35)
	if(containi(g_Authid[id],"PENDING") != -1 || containi(g_Authid[id],"LAN") != -1 || equali(g_Authid[id],"STEAM_0:0") || containi(g_Authid[id],"UNKNOWN") != -1)
		return
	
	ARP_SqlEscape(JobName,32)
	
	format(g_Query,4095,"UPDATE %s SET bankmoney='%d',wallet='%d',jobname='%s',hunger='%d',access='%s',jobright='%s' WHERE authid='%s'",g_UserTable,g_BankMoney[id],g_Money[id],JobName,g_Hunger[id],Access,JobRight,g_Authid[id])
	
	g_Saving[id] = 1
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"SaveUserDataHandle",g_Query,Data,2)
}

public SaveUserDataHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new id = Data[0],Authid[36]
	
	g_Saving[id] = 0
	
	if(g_PluginEnd)
		return PLUGIN_CONTINUE
	
	get_user_authid(id,Authid,35)
	
	if(!is_user_connected(id) || !equali(g_Authid[id],Authid) || Data[1])
		return ClearSettings(id)
	
	return PLUGIN_CONTINUE
}

ClearSettings(id)
{
	for(new Count,CurArray;Count < g_PropertyNum;Count++)
	{
		CurArray = array_get_int(g_PropertyArray,Count)
		array_set_int(CurArray,8,array_get_int(CurArray,8) & ~(1<<(id - 1)))
	}
	
	g_UserItemNum[id] = 0
	
	g_Saving[id] = 0
	
	g_Access[id] = 0
	g_AccessCache[id] = 0
	
	g_Authid[id][0] = 0
	
	g_BadJob[id] = 0
	
	g_Display[id] = 1
	
	array_clear(g_UserItemArray[id])
	
	for(new Count;Count < HUD_NUM;Count++)
		//ClearHud(id,Count)
		TravTrieClear(g_HudArray[id][Count])
	
	return PLUGIN_CONTINUE
}

public CmdHelp(id)
{
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Start = str_to_num(Arg),Items = get_pcvar_num(p_ItemsPerPage)
	
	if(Start >= g_CommandNum || Start < 0)
	{
		client_print(id,print_console,"No help items to display at this area.")
		return PLUGIN_HANDLED
	}
	
	new Data[2]
	Data[0] = id
	Data[1] = Start
	if(_CallEvent("Player_HelpMenu",Data,2))
		return PLUGIN_HANDLED
	
	client_print(id,print_console,"ARP Help List (Starting at #%d)",Start)
	client_print(id,print_console,"NUMBER   COMMAND   DESCRIPTION")
	
	for(new Count = Start;Count < Start + Items;Count++)
	{
		if(Count >= g_CommandNum)
			break
		
		array_get_string(array_get_int(g_CommandArray,Count + 1),1,Arg,32)
		array_get_string(array_get_int(g_CommandArray,Count + 1),2,g_Query,4095)
		
		client_print(id,print_console,"#%d   %s   %s",Count + 1,Arg,g_Query)
	}
	
	if(Start + Items < g_CommandNum)
		client_print(id,print_console,"Type ^"arp_help %d^" to view next items.",Start + Items)
	
	return PLUGIN_HANDLED
}

public CmdBuy(id)
{
	new Index,Body
	get_user_aiming(id,Index,Body,100)
	
	if(Index)
	{
		new Targetname[33],Return
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		
		new Classname[33]
		entity_get_string(Index,EV_SZ_classname,Classname,32)
		
		new Property = UTIL_ARP_GetProperty(Targetname,Index)
		if(Property == -1)
			return PLUGIN_HANDLED
		
		//if((equal(Classname,"func_door") || equal(Classname,"func_door_rotating")) && entity_get_int(Index,EV_INT_bInDuck))
		//	ARP_RealProperty(Index,Targetname,Targetname,32)
		//else
		//	return PLUGIN_HANDLED
		
		new CurArray = array_get_int(g_PropertyArray,Property),Price = array_get_int(CurArray,4),Authid[36],EntAuthid[36]
		
		get_user_authid(id,Authid,35)
		array_get_string(CurArray,3,EntAuthid,35)
		
		if(equali(Authid,EntAuthid))
		{
			client_print(id,print_chat,"[ARP] You already own this place.")
			return PLUGIN_HANDLED
		}
		
		if(Price && g_BankMoney[id] >= Price)
		{
			new Data[2]
			Data[0] = id
			Data[1] = Property + 1
			if(_CallEvent("Property_Buy",Data,2))
				return PLUGIN_HANDLED
			
			if(!Return)
			{
				new Players[32],Playersnum,Player,PlayerAuthid[36],Flag
				get_players(Players,Playersnum)
				
				for(new Count;Count < Playersnum;Count++)
				{
					Player = Players[Count]
					
					get_user_authid(Player,PlayerAuthid,35)
					
					if(equali(PlayerAuthid,EntAuthid))
					{
						g_BankMoney[Player] += Price
						
						new ExternalName[33],Name[33]
						get_user_name(id,Name,32)
						array_get_string(array_get_int(g_PropertyArray,Property),1,ExternalName,32)
						
						client_print(Player,print_chat,"[ARP] Your property, ^"%s^", has been bought by %s for $%d.",ExternalName,Name,Price)
						
						Flag = 1
						
						break
					}
				}
				
				if(!Flag)
				{
					format(g_Query,4095,"UPDATE %s SET bankmoney = bankmoney + %d WHERE authid='%s'",g_UserTable,Price,EntAuthid)
					UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
				}
				
				g_BankMoney[id] -= Price
				
				new Name[33]
				get_user_name(id,Name,32)
				
				array_set_string(CurArray,2,Name)
				array_set_string(CurArray,3,Authid)
				array_set_int(CurArray,4,0) 
				array_set_int(CurArray,8,0)
				array_set_int(CurArray,9,1)
				
				new InternalName[64]
				array_get_string(CurArray,0,InternalName,63)
				
				#if defined DEBUG
				g_TotalQueries++
				#endif
				
				format(g_Query,4095,"DELETE FROM %s WHERE authidkey LIKE '%%|%s'",g_KeysTable,InternalName)
				UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
			}
		}
		else
			client_print(id,print_chat,"[ARP] You do not have enough money in your bank account for this property.")
	}
		
	return PLUGIN_HANDLED
}

public CmdItems(id)
{
	g_MenuPage[id] = 0
	ShowItems(id)
	
	return PLUGIN_HANDLED
}

ShowItems(id)
{	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	new Data[2]
	Data[0] = id
	if(_CallEvent("Item_Inventory",Data,1))
		return PLUGIN_HANDLED
	
	new Success,Num,ItemId,Size = array_size(g_UserItemArray[id])
	if(Size < 1)
	{
		client_print(id,print_chat,"[ARP] You have no items in your inventory.")
		return PLUGIN_HANDLED
	}
	
	new Menu = menu_create("ARP Items","ItemsHandle"),ItemName[33],Msg[128]
	
	while(Num < Size && (ItemId = array_get_nth(g_UserItemArray[id],++Num,_,Success)) != 0 && Success)
	{				
		//if(!array_isfilled(g_UserItemArray[id],ItemId))
		//	break
		
		Data[1] = ItemId
		if(_CallEvent("Item_AddItem",Data,2))
			return PLUGIN_HANDLED
		
		UTIL_ARP_ValidItemId(ItemId) ? UTIL_ARP_GetItemName(ItemId,ItemName,32) : copy(ItemName,32,"BAD ITEMID: Contact admin")
		format(Msg,127,"%s x %d",ItemName,UTIL_ARP_GetUserItemNum(id,ItemId))
		menu_additem(Menu,Msg,"")
		
		//if(ItemId == Last)
		//	break
	}
	
	menu_display(id,Menu)
	
	return PLUGIN_HANDLED
}	

public ItemsHandle(id,Menu,Item)
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT) return
	
	new Success
	
	/*USER_ITEM_SCAN
		if(ItemNum++ >= Item)
		{
			ItemNum = Next
			break
		}*/
	
	new ItemId = array_get_nth(g_UserItemArray[id],Item + 1,_,Success),Data[2]
	Data[0] = id
	Data[1] = ItemId
	if(_CallEvent("Item_Menu",Data,2))
		return
	
	g_CurItem[id] = ItemId
	
	if(UTIL_ARP_GetUserItemNum(id,ItemId) <= 0)
		client_print(id,print_chat,"[ARP] You do not have any of this item.")
	else if(UTIL_ARP_ValidItemId(ItemId))
	{
		format(g_Query,4095,"ARP Item Options^n^n1. Use^n2. Give^n3. Examine^n4. Show^n5. Drop^n^n0. Exit")
		show_menu(id,g_Keys,g_Query,-1,g_ItemsOptions)
	}
	else
		client_print(id,print_chat,"[ARP] This item is invalid. Please contact the administrator.")
		
	return
}

public ItemsOptions(id,Key)
	switch(Key)
	{
		case 0 :
		{
			if(g_ItemUse[id])
			{
				client_print(id,print_chat,"[ARP] You are already using another item.")
				return
			}
			
			new Name[33]
			UTIL_ARP_GetItemName(g_CurItem[id],Name,32)
			
			new Data[2]
			Data[0] = id
			Data[1] = g_CurItem[id]
			
			if(_CallEvent("Item_Use",Data,2))
				return
			
			ItemUse(id,g_CurItem[id],1)
		}
		
		case 1 :
		{
			format(g_Query,4095,"ARP Give Items^n^n1. Give 1^n2. Give 5^n3. Give 20^n4. Give 50^n5. Give 100^n6. Give All^n^n0. Exit")
			show_menu(id,g_Keys,g_Query,-1,g_ItemsGive)
		}
		
		case 2 :
		{
			new ItemId = g_CurItem[id]
			if(!UTIL_ARP_ValidItemId(ItemId))
			{
				client_print(id,print_chat,"[ARP] This item is invalid. Please contact an administrator.")
				return
			}
			
			new Data[2]
			Data[0] = id
			Data[1] = ItemId
			
			if(_CallEvent("Item_Description",Data,2))
				return
				
			array_get_string(array_get_int(g_ItemsArray,ItemId),4,g_Query,63)
			
			client_print(id,print_chat,"[ARP] %s",g_Query)
		}
		
		case 3 :
		{
			new Index,Body
			get_user_aiming(id,Index,Body,100)
			
			if(!Index || !is_user_alive(Index))
				return
			
			new Data[3]
			Data[0] = id
			Data[1] = Index
			Data[2] = g_CurItem[id]
			if(_CallEvent("Item_Show",Data,3))
				return
	
			new Names[2][33],ItemId = g_CurItem[id],ItemName[33]//_ARP_GetItemIdCell(0,g_UserItemIds[id][g_CurItem[id]])
			get_user_name(id,Names[0],32)
			get_user_name(Index,Names[1],32)
			
			UTIL_ARP_GetItemName(ItemId,ItemName,32)
			
			client_print(id,print_chat,"[ARP] You show %s your %s.",Names[1],ItemName)
			client_print(Index,print_chat,"[ARP] %s shows you his %s.",Names[0],ItemName)
		}
		
		case 4 :
		{
			format(g_Query,4095,"ARP Drop Items^n^n1. Drop 1^n2. Drop 5^n3. Drop 20^n4. Drop 50^n5. Drop 100^n6. Drop All^n^n0. Exit")
			show_menu(id,g_Keys,g_Query,-1,g_ItemsDrop)
		}
	}

public ItemsGive(id,Key)
{
	new Index,Body,Num
	get_user_aiming(id,Index,Body,200)
	
	if(!Index || !is_user_alive(Index))
	{
		client_print(id,print_chat,"[ARP] You are not looking at a user.")
		return
	}
	
	new ItemId = g_CurItem[id]
	
	switch(Key)
	{
		case 0 :
			Num = 1
		case 1 :
			Num = 5
		case 2 :
			Num = 20
		case 3 :
			Num = 50
		case 4 :
			Num = 100
		case 5 :
			Num = abs(array_get_int(g_UserItemArray[id],g_CurItem[id]))
	}
	
	if(ARP_GetUserItemNum(id,ItemId) < Num)
	{
		client_print(id,print_chat,"[ARP] You do not have enough of this item.")		
		return
	}
	
	new Data[4]
	Data[0] = id
	Data[1] = Index
	Data[2] = ItemId
	Data[3] = Num
	
	if(_CallEvent("Item_Give",Data,4))
		return
	
	if(!UTIL_ARP_SetUserItemNum(Index,ItemId,UTIL_ARP_GetUserItemNum(Index,ItemId) + Num))
	{
		client_print(id,print_chat,"[ARP] Sorry, that user cannot accept items right now.")
		return
	}
		
	UTIL_ARP_SetUserItemNum(id,ItemId,UTIL_ARP_GetUserItemNum(id,ItemId) - Num)
			
	new Names[2][33],ItemName[33]//= _ARP_GetItemIdCell(0,g_UserItemIds[id][g_CurItem[id]])
	get_user_name(id,Names[0],32)
	get_user_name(Index,Names[1],32)
	
	UTIL_ARP_GetItemName(ItemId,ItemName,32)
	
	client_print(id,print_chat,"[ARP] You have given %s %d %s%s.",Names[1],Num,ItemName,Num == 1 ? "" : "s")
	client_print(Index,print_chat,"[ARP] %s has given you %d %s%s.",Names[0],Num,ItemName,Num == 1 ? "" : "s")
}	

public ItemsDrop(id,Key)
{
	if(Key == 9) return
	
	new Num,ItemNum = abs(array_get_int(g_UserItemArray[id],g_CurItem[id])),ItemId = g_CurItem[id]
	
	switch(Key)
	{
		case 0 :
			Num = 1
		case 1 :
			Num = 5
		case 2 :
			Num = 20
		case 3 :
			Num = 50
		case 4 :
			Num = 100
		case 5 :
			Num = ItemNum
	}
	
	if(ItemNum < Num)
	{
		client_print(id,print_chat,"[ARP] You do not have enough of this item.")		
		return
	}
	
	new Data[3]
	Data[0] = id
	Data[1] = ItemId
	Data[2] = Num
	
	if(_CallEvent("Item_Drop",Data,3))
		return
	
	UTIL_ARP_SetUserItemNum(id,ItemId,UTIL_ARP_GetUserItemNum(id,ItemId) - Num)
	
	new Name[33]
	UTIL_ARP_GetItemName(ItemId,Name,32)
	
	if(get_pcvar_num(p_Performance) > 10)
	{
		new Ent = create_entity("info_target"),Float:Origin[3]
		if(!Ent)
			return
		
		// Hawk552: Starting with v1.2, you can make premade items on your maps
		//	using this because it stores the info using names rather than ids
		entity_get_vector(id,EV_VEC_origin,Origin)
		entity_set_string(Ent,EV_SZ_classname,g_ItemClassname)
		entity_set_model(Ent,g_ItemModel)
		entity_set_origin(Ent,Origin)
		entity_set_string(Ent,EV_SZ_noise,Name)
		//entity_set_int(Ent,EV_INT_iuser1,ItemId)
		entity_set_int(Ent,EV_INT_iuser2,Num)
		entity_set_size(Ent,Float:{-2.5,-2.5,-2.5},Float:{2.5,2.5,2.5})

		entity_set_origin(id,Float:{0.0,0.0,0.0})
		drop_to_floor(Ent)
		entity_set_origin(id,Origin)
	}
}

public client_PostThink(id)
	if(is_user_alive(id) && !get_pcvar_num(p_FallDamage))
		entity_set_int(id,EV_INT_watertype,-3)
	
public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
	
	if(g_SpeedOverridePlugin[id])
		set_user_maxspeed(id,g_SpeedOverride[id])
	else
	{
		new Float:NewSpeed = g_MaxSpeed[id],travTrieIter:Iter = GetTravTrieIterator(g_SpeedTrie[id]),Float:Mul,Flag
		while(MoreTravTrie(Iter))
		{
			ReadTravTrieCell(Iter,Mul)
			NewSpeed *= Mul
			
			Flag = 1
		}
		DestroyTravTrieIterator(Iter)
		
		if(Flag)
			set_user_maxspeed(id,NewSpeed)
	}
	
	g_Falling[id] = entity_get_float(id,EV_FL_flFallVelocity) > 350.0
	
	new Index,Body,EntList[50]
	get_user_aiming(id,Index,Body,100)
	
	static Classname[33],Data[3]
	
	if(entity_get_int(id,EV_INT_button) & IN_USE && !(entity_get_int(id,EV_INT_oldbuttons) & IN_USE))
	{
		if(Index && is_valid_ent(Index))
		{
			entity_get_string(Index,EV_SZ_classname,Classname,32)
			if(equali(Classname,"func_door") || equali(Classname,"func_door_rotating"))
			{
				// is really targetname now, but we should reuse variables
				entity_get_string(Index,EV_SZ_targetname,Classname,32)
				new Property = UTIL_ARP_GetProperty(Classname,Index)
				if(Property == -1)
					return
				
				new CurArray = array_get_int(g_PropertyArray,Property)
				
				static Authid[36],EntAuthid[36]
				get_user_authid(id,Authid,35)
				array_get_string(CurArray,3,EntAuthid,35)
				
				if(!array_get_int(CurArray,5) || array_get_int(CurArray,8) & (1<<(id - 1)) || equali(Authid,EntAuthid) || array_get_int(CurArray,6) & g_Access[id])
				{
					Data[0] = id
					Data[1] = Index
					Data[2] = Property
					
					if(_CallEvent("Property_Use",Data,3))
						return
					
					client_print(id,print_chat,"[ARP] You used the door.")
					force_use(id,Index)
					fake_touch(Index,id)
				}
				else
					client_print(id,print_chat,"[ARP] This door is locked.")
				
				return
			}
		}
		
		if(find_sphere_class(id,g_ItemClassname,50.0,EntList,1))
		{
			new Ent = EntList[0]
			
			new Quantity = entity_get_int(Ent,EV_INT_iuser2),ItemName[33]//,Cell = _ARP_GetItemIdCell(0,ItemId)
			entity_get_string(Ent,EV_SZ_noise,ItemName,32)
			
			new ItemId = UTIL_ARP_FindItemId(ItemName)
	
			Data[0] = id
			Data[1] = ItemId
			Data[2] = Quantity
			
			if(_CallEvent("Item_Pickup",Data,3))
				return
			
			UTIL_ARP_SetUserItemNum(id,ItemId,UTIL_ARP_GetUserItemNum(id,ItemId) + Quantity)
			UTIL_ARP_GetItemName(ItemId,ItemName,32)
	
			client_print(id,print_chat,"[ARP] You have picked up %d %s%s.",Quantity,ItemName,Quantity == 1 ? "" : "s")
			
			remove_entity(Ent)
			
			return
		}
		
		if(Index && is_valid_ent(Index))
		{
			entity_get_string(Index,EV_SZ_classname,Classname,32)
			if(equal(Classname,g_NpcClassname))
			{
				new Plugin = entity_get_int(Index,EV_INT_iuser3),Handler[32]
				entity_get_string(Index,EV_SZ_noise,Handler,31)
				
				Data[0] = id
				Data[1] = Index
				
				if(_CallEvent("NPC_Use",Data,2))
					return
				
				NpcUse(Handler,Plugin,id,Index)
			}	
		}
		
		Index = 0
		while((Index = find_ent_by_class(Index,g_NpcZoneClassname)))
		{
			if(get_entity_distance(id,Index) > 100 || !fm_is_ent_visible(id,Index))
				continue
			
			new Plugin = entity_get_int(Index,EV_INT_iuser3),Handler[32]
			entity_get_string(Index,EV_SZ_noise,Handler,31)
			
			Data[0] = id
			Data[1] = Index
				
			if(_CallEvent("NPC_Use",Data,2))
				return
				
			NpcUse(Handler,Plugin,id,Index)
		}
	}	
	
	if(g_Display[id])
		GetMsg(id,Index)
}

GetMsg(id,Index)
{
	if(!is_valid_ent(Index))
		return
	
	//if(g_HudPending)
	//	client_print(id,print_chat,"Hud Pending")
	
	static Name[33],Message[128],Classname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	new Ent
	while((Ent = find_ent_by_class(Ent,g_NpcZoneClassname)))
	{
		if(!get_entity_distance(id,Ent) || !fm_is_ent_visible(id,Ent))
			continue
		
		entity_get_string(Ent,EV_SZ_noise1,Name,32)
		
		format(Message,127,"%s^nPress use (default e) to use",Name)
		
		UTIL_ARP_ClientPrint(id,"%s",Message)
		
		break
	}
	
	if(!Index)
		return
	
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	if(equal(Classname,g_NpcClassname))
	{
		entity_get_string(Index,EV_SZ_noise1,Name,32)
		
		format(Message,127,"%s^nPress use (default e) to use",Name)
		
		UTIL_ARP_ClientPrint(id,"%s",Message)
	}
	else if(equali(Classname,"func_door") || equali(Classname,"func_door_rotating"))
	{
		static Targetname[33],CurTargetname[33]
		entity_get_string(Index,EV_SZ_targetname,CurTargetname,32)
		
		for(new Count;Count < g_DoorNum;Count++)
		{			
			array_get_string(array_get_int(g_DoorArray,Count),0,Targetname,32)
			if((CurTargetname[0] && Targetname[0] && equali(Targetname,CurTargetname)) || (Index == array_get_int(array_get_int(g_DoorArray,Count),1) && is_valid_ent(Index)))
			{
				static Ownername[33],Purchase[64]
				
				new Property = UTIL_ARP_GetProperty(Targetname,Index)
				if(Property == -1)
					return
				
				new CurArray = array_get_int(g_PropertyArray,Property)
				array_get_string(CurArray,1,Name,32)
				array_get_string(CurArray,2,Ownername,32)
				new Price = array_get_int(CurArray,4)
				
				format(Message,127,"^nOwner: %s",Ownername)
				format(Purchase,63,"^nPrice: $%d. Say /buy to purchase.",Price)
				
				UTIL_ARP_ClientPrint(id,"%s%s%s^nStatus: %s",Name[0] ? Name : "",Ownername[0] ? Message : "", Price ? Purchase : "",array_get_int(CurArray,5) ? "Locked" : "Unlocked")
			}
		}
	}
	else if(get_pcvar_num(p_HoverMessage) && equali(Classname,"player"))
	{
		static JobName[33],Name[33]
		get_user_name(Index,Name,32)
		array_get_string(array_get_int(g_JobsArray,g_JobId[Index]),1,JobName,32)
		
		UTIL_ARP_ClientPrint(id,"Name: %s^nJob: %s",Name,JobName)
		
		//if(g_HudPending)
		//	client_print(id,print_chat,"Hud Added")
	}
	
	if(!g_HudPending)
	{
		g_Display[id] = 0
		set_task(0.1,"ResetDisplay",id)
	}
}

public ResetDisplay(id)
	g_Display[id] = 1

NpcUse(Handler[],Plugin,id,Index)
{
	new Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_CELL),Return
	// duplicate code, but whatever
	if(Forward < 0)
	{
		format(g_Query,4095,"Function does not exist: %s",Handler)
		return UTIL_ARP_ThrowError(0,0,g_Query,Plugin)
	}
	
	if(!ExecuteForward(Forward,Return,id,Index))
	{
		format(g_Query,4095,"Function does not exist: %s",Handler)
		return UTIL_ARP_ThrowError(0,0,g_Query,Plugin)
	}
	
	DestroyForward(Forward)
	
	return SUCCEEDED
}

public plugin_natives()
{
	register_library("arp")
	
	set_module_filter("ModuleFilter")
	set_native_filter("NativeFilter")
	
	register_native("ARP_Version","_ARP_Version")
	
	register_native("ARP_Log","_ARP_Log")
	
	register_native("ARP_RegisterAddon","_ARP_RegisterAddon")
	register_native("ARP_AddonTrie","_ARP_AddonTrie")
	register_native("ARP_AddonLoaded","_ARP_AddonLoaded")
	
	register_native("ARP_FileOpen","_ARP_FileOpen")
	
	register_native("ARP_SqlMode","_ARP_SqlMode")
	register_native("ARP_SqlHandle","_ARP_SqlHandle")
	register_native("ARP_GetTable","_ARP_GetTable")
	register_native("ARP_CleverQueryBackend","_ARP_CleverQueryBackend")
	
	register_native("ARP_GetConfigsdir","_ARP_GetConfigsdir")
	
	register_native("ARP_GetNpcClassname","_ARP_GetNpcClassname")
	register_native("ARP_RegisterNpc","_ARP_RegisterNpc")
	register_native("ARP_IsNpc","_ARP_IsNpc")
	
	register_native("ARP_PlayerReady","_ARP_PlayerReady")
	
	register_native("ARP_GetUserWallet","_ARP_GetUserWallet")
	register_native("ARP_SetUserWallet","_ARP_SetUserWallet")
	register_native("ARP_GetUserBank","_ARP_GetUserBank")
	register_native("ARP_SetUserBank","_ARP_SetUserBank")
	register_native("ARP_GetUserHunger","_ARP_GetUserHunger")
	register_native("ARP_SetUserHunger","_ARP_SetUserHunger")
	register_native("ARP_GetUserAccess","_ARP_GetUserAccess")
	register_native("ARP_SetUserAccess","_ARP_SetUserAccess")
	
	register_native("ARP_GetJobsNum","_ARP_GetJobsNum")
	register_native("ARP_GetJobName","_ARP_GetJobName")
	register_native("ARP_GetJobSalary","_ARP_GetJobSalary")
	register_native("ARP_GetJobAccess","_ARP_GetJobAccess")
	register_native("ARP_GetUserJobId","_ARP_GetUserJobId")
	register_native("ARP_SetUserJobId","_ARP_SetUserJobId")
	register_native("ARP_SetUserJobRight","_ARP_SetUserJobRight")
	register_native("ARP_GetUserJobRight","_ARP_GetUserJobRight")
	register_native("ARP_ValidJobId","_ARP_ValidJobId")
	register_native("ARP_FindJobId","_ARP_FindJobId")
	register_native("ARP_AddJob","_ARP_AddJob")
	register_native("ARP_DeleteJob","_ARP_DeleteJob")
	
	register_native("ARP_RegisterItem","_ARP_RegisterItem")
	register_native("ARP_ValidItemId","_ARP_ValidItemId")
	register_native("ARP_FindItemId","_ARP_FindItemId")
	register_native("ARP_GetItemName","_ARP_GetItemName")
	//register_native("ARP_GetUserItemId","_ARP_GetUserItemId")
	register_native("ARP_GetUserItemNum","_ARP_GetUserItemNum")
	register_native("ARP_GetUserItems","_ARP_GetUserItems")
	register_native("ARP_SetUserItemNum","_ARP_SetUserItemNum")
	register_native("ARP_ForceUseItem","_ARP_ForceUseItem")
	register_native("ARP_ItemSet","_ARP_ItemSet")
	register_native("ARP_ItemDone","_ARP_ItemDone")
	
	register_native("ARP_AddCommand","_ARP_AddCommand")
	
	register_native("ARP_AddHudItem","_ARP_AddHudItem")
	
	register_native("ARP_GetPayday","_ARP_GetPayday")
	
	register_native("ARP_ValidProperty","_ARP_ValidProperty")
	register_native("ARP_ValidPropertyName","_ARP_ValidPropertyName")
	register_native("ARP_ValidDoor","_ARP_ValidDoor")
	register_native("ARP_ValidDoorName","_ARP_ValidDoorName")
	register_native("ARP_AddProperty","_ARP_AddProperty")
	register_native("ARP_DeleteProperty","_ARP_DeleteProperty")
	register_native("ARP_AddDoor","_ARP_AddDoor")
	register_native("ARP_DeleteDoor","_ARP_DeleteDoor")
	register_native("ARP_PropertyNum","_ARP_PropertyNum")
	register_native("ARP_DoorNum","_ARP_DoorNum")
	register_native("ARP_DoorMatch","_ARP_DoorMatch")
	register_native("ARP_PropertyMatch","_ARP_PropertyMatch")
	register_native("ARP_PropertyGetInternalName","_ARP_PropertyGetInternalName")
	register_native("ARP_PropertyGetExternalName","_ARP_PropertyGetExternalName")
	register_native("ARP_PropertySetExternalName","_ARP_PropertySetExternalName")
	register_native("ARP_PropertyGetOwnerName","_ARP_PropertyGetOwnerName")
	register_native("ARP_PropertySetOwnerName","_ARP_PropertySetOwnerName")
	register_native("ARP_PropertyGetOwnerAuth","_ARP_PropertyGetOwnerAuth")
	register_native("ARP_PropertySetOwnerAuth","_ARP_PropertySetOwnerAuth")
	register_native("ARP_PropertyGetPrice","_ARP_PropertyGetPrice")
	register_native("ARP_PropertySetPrice","_ARP_PropertySetPrice")
	register_native("ARP_PropertyGetLocked","_ARP_PropertyGetLocked")
	register_native("ARP_PropertySetLocked","_ARP_PropertySetLocked")
	register_native("ARP_PropertyGetAccess","_ARP_PropertyGetAccess")
	register_native("ARP_PropertySetAccess","_ARP_PropertySetAccess")
	register_native("ARP_PropertyGetProfit","_ARP_PropertyGetProfit")
	register_native("ARP_PropertySetProfit","_ARP_PropertySetProfit")
	register_native("ARP_PropertyAddAccess","_ARP_PropertyAddAccess")
	register_native("ARP_PropertyRemoveAccess","_ARP_PropertyRemoveAccess")
	register_native("ARP_PropertyClearAccess","_ARP_PropertyClearAccess")
	
	//register_native("ARP_RegisterRob","_ARP_RegisterRob")
	//register_native("ARP_Rob","_ARP_Rob")
	
	register_native("ARP_ThrowError","_ARP_ThrowError")
	register_native("ARP_ClientPrint","_ARP_ClientPrint")
	
	register_native("ARP_CallEvent","_ARP_CallEvent")
	register_native("ARP_RegisterEvent","_ARP_RegisterEvent")
	
	register_native("ARP_ClassLoad","_ARP_ClassLoad")
	register_native("ARP_ClassSave","_ARP_ClassSave")
	register_native("ARP_ClassSaveHook","_ARP_ClassSaveHook")
	register_native("ARP_ClassDeleteKey","_ARP_ClassDeleteKey")
	register_native("ARP_ClassDestroy","_ARP_ClassDestroy")
	
	register_native("ARP_SetUserSpeed","_ARP_SetUserSpeed")
	//register_native("ARP_GetUserSpeed","_ARP_GetUserSpeed")
	
	register_native("ARP_AddMenuItem","_ARP_AddMenuItem")
}

public _ARP_SetUserSpeed(Plugin,Params)
{
	if(Params != 3)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 3",Params)
		return PLUGIN_CONTINUE
	}
	
	new id = get_param(1),Float:Value = get_param_f(3)
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"Player not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	switch(Speed:get_param(2))
	{
		case Speed_None:
		{
			TravTrieDeleteKeyEx(g_SpeedTrie[id],Plugin)
			
			if(g_SpeedOverridePlugin[id] == Plugin)
			{
				g_SpeedOverride[id] = 0.0
				g_SpeedOverridePlugin[id] = 0
			}
		}
		case Speed_Override:
		{
			if(g_SpeedOverridePlugin[id] && g_SpeedOverridePlugin[id] != Plugin)
				return FAILED
			
			g_SpeedOverride[id] = Value
			g_SpeedOverridePlugin[id] = Plugin
		}
		case Speed_Mul:
		{
			if(Value < 0.001)
				Value = 0.001
			
			new Float:PrevSpeed
			if(TravTrieGetCellEx(g_SpeedTrie[id],Plugin,PrevSpeed) && PrevSpeed)
				// Compound it with whatever was set before.
				Value *= PrevSpeed
			
			if(Value < 1.001 && Value > 0.999 )
				TravTrieDeleteKeyEx(g_SpeedTrie[id],Plugin)
			else
				TravTrieSetCellEx(g_SpeedTrie[id],Plugin,Value)
		}
	}
	
	// Fake a reset in case client_PreThink() skips.
	set_user_maxspeed(id,g_MaxSpeed[id])
	
	return SUCCEEDED
}

public _ARP_SqlMode(Plugin,Params)
{
	if(Params)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 0",Params)
		return PLUGIN_CONTINUE
	}
	
	return _:g_SqlMode
}

public _ARP_PlayerReady(Plugin,Params)
{
	if(Params < 1)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 1",Params)
		return PLUGIN_CONTINUE
	}
	
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"Player not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return g_GotInfo[id] >= STD_USER_QUERIES
}

public _ARP_Log(Plugin,Params)
{
	if(Params < 1)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 1",Params)
		return PLUGIN_CONTINUE
	}
	
	vdformat(g_Query,4095,1,2)
	
	return UTIL_ARP_Log(Plugin,g_Query)
}

UTIL_ARP_Log(Plugin,Message[])
{
	new PluginName[64],Garbage[1]
	get_plugin(Plugin,Garbage,0,PluginName,63,Garbage,0,Garbage,0,Garbage,0)
	
	replace(PluginName,63,"ARP - ","")
	
	switch(get_pcvar_num(p_Log))
	{
		case 1 : log_amx("[ARP - %s] %s",PluginName,g_Query)
		case 2 : 
		{
			new Time[128],LogsDir[64],File[128]
			get_localinfo("amxx_logs",LogsDir,63)
			
			get_time("%m-%d-%Y",Time,127)
			format(File,127,"%s/arp/%s.log",LogsDir,Time)
			
			log_to_file(File,"[ARP - %s] %s",PluginName,Message)
		}
		case 3 : 
		{
			new File[128],LogsDir[64]
			get_localinfo("amxx_logs",LogsDir,63)
			
			replace_all(PluginName,63," ","")
			strtolower(PluginName)
			format(File,127,"%s/arp/%s.log",LogsDir,Message)
			
			log_to_file(File,g_Query)
		}
		default : return FAILED
	}
	
	return SUCCEEDED
}

public _ARP_FileOpen(Plugin,Params)
{
	if(Params != 2)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 2",Params)
		return PLUGIN_CONTINUE
	}
	
	new FileName[128],Mode[24]
	get_string(1,FileName,127)
	get_string(2,Mode,23)
	
	return UTIL_ARP_FileOpen(FileName,Mode)
}

UTIL_ARP_FileOpen(FileName[],Mode[])
{
	new FilePath[256]
	get_configsdir(FilePath,255)
	add(FilePath,255,"/arp/")
	new OrigLen = strlen(FilePath)
	
	new MapName[33]
	get_mapname(MapName,32)
	
	add(FilePath,255,"maps/")
	add(FilePath,255,MapName)
	add(FilePath,255,"/")
	add(FilePath,255,FileName)
	
	new File
	if(file_exists(FilePath) && (File = fopen(FilePath,Mode)))
		return File
	
	FilePath[OrigLen] = 0
	
	add(FilePath,255,FileName)
	
	if(file_exists(FilePath))
		return fopen(FilePath,Mode)
	
	return FAILED
}

public _ARP_RegisterAddon(Plugin,Params)
{
	if(Params != 1)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 1",Params)
		return PLUGIN_CONTINUE
	}
	
	new Description[128]
	get_string(1,Description,127)
	TravTrieSetStringEx(g_PluginTrie,Plugin,Description)
	
	return SUCCEEDED
}

public _ARP_AddonTrie(Plugin,Params)
{
	if(Params != 0)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 0",Params)
		return PLUGIN_CONTINUE
	}
	
	return _:g_PluginTrie
}

public _ARP_AddonLoaded(Plugin,Params)
{
	if(Params != 1)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 1",Params)
		return PLUGIN_CONTINUE
	}
	
	new Addon[64]
	get_string(1,Addon,63)
	
	new Name[64],Garbage[1],travTrieIter:Iter = GetTravTrieIterator(g_PluginTrie),Plugin,Return
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKeyEx(Iter,Plugin)
		// just to advance the iterator
		ReadTravTrieString(Iter,Garbage,0)
		
		get_plugin(Plugin,Garbage,0,Name,63,Garbage,0,Garbage,0,Garbage,0)
		replace(Name,63,"ARP - ","")
		
		if(equali(Addon,Name))
		{
			Return = Plugin
			break
		}
	}
	DestroyTravTrieIterator(Iter)
	
	return Return
}

public _ARP_CleverQueryBackend(Plugin,Params)
{
	if(Params != 5)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 5",Params)
		return PLUGIN_CONTINUE
	}
	
	new Handle:Tuple = Handle:get_param(1),Handler[128],Data[1024],Len = min(1023,get_param(5))
	get_string(2,Handler,127)
	get_string(3,g_Query,4095)
	get_array(4,Data,Len)
	
	return _ARP_CleverQuery(Plugin,Tuple,Handler,g_Query,Data,Len)
}

public ClearHandle(Handle:Query)
	SQL_FreeHandle(Query)

CleverQueryFunction(PluginGiven,HandlerS[],FailState,Handle:Query,Error[],Errcode,PassData[],Len,Float:HangTime)
{
	new Forward = CreateOneForward(PluginGiven,HandlerS,FP_CELL,FP_CELL,FP_STRING,FP_CELL,FP_ARRAY,FP_CELL,FP_CELL),CurArray = Len ? PrepareArray(PassData,Len) : 0,Return
	if(!Forward || !ExecuteForward(Forward,Return,FailState,Query,Error,Errcode,CurArray,Len,HangTime))
	{
		log_error(AMX_ERR_NATIVE,"Could not execute forward to %d: %s (%d)",PluginGiven,HandlerS,Forward)
		return
	}
	DestroyForward(Forward)
}

UTIL_ARP_CleverQuery(PluginGiven,Handle:Tuple,Handler[],QueryS[],Data[] = "",Len = 0)
{
	if(g_SqlHandle == Empty_Handle) return FAILED
	return _ARP_CleverQuery(PluginGiven,Tuple,Handler,QueryS,Data,Len) ? SQL_ThreadQuery(Tuple,Handler,QueryS,Data,Len) : PLUGIN_HANDLED
}

_ARP_CleverQuery(Plugin,Handle:Tuple,Handler[],QueryS[],Data[] = "",Len = 0)
{
	if(!get_playersnum() || g_PluginEnd /*|| g_SqlMode == SQLITE*/)
	{
		new Error[512],ErrorCode,Handle:SqlConnection = SQL_Connect(Tuple,ErrorCode,Error,511)
		if(SqlConnection == Empty_Handle)
		{
			CleverQueryFunction(Plugin,Handler,TQUERY_CONNECT_FAILED,Empty_Handle,Error,ErrorCode,Data,Len,0.0)
			return PLUGIN_CONTINUE
		}
		
		new Handle:Query = SQL_PrepareQuery(SqlConnection,"%s",QueryS)
		if(!SQL_Execute(Query))
		{
			ErrorCode = SQL_QueryError(Query,Error,511)
			CleverQueryFunction(Plugin,Handler,TQUERY_QUERY_FAILED,Query,Error,ErrorCode,Data,Len,0.0)
			return PLUGIN_CONTINUE
		}
		
		CleverQueryFunction(Plugin,Handler,TQUERY_SUCCESS,Query,"",0,Data,Len,0.0)
		
		SQL_FreeHandle(Query)
		SQL_FreeHandle(SqlConnection)
		
		//set_task(0.1,"ClearHandle",_:Query)
		//set_task(0.1,"ClearHandle",_:SqlConnection)
		
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}

public _ARP_ClassLoad(Plugin,Params)
{
	if(Params != 4)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Param[64],Handler[64],Temp[128],Table[64],ClassName[128]//,Len = min(4095,get_param(4))
	get_string(1,Param,63)
	get_string(2,Handler,63)
	get_string(3,g_Query,4095)
	get_string(4,Table,63)
	
	if(!Table[0])
		copy(Table,63,g_DataTable)
	
	format(ClassName,127,"%s|%s",Table,Param)
	
	//g_Query[0] = Len
	
	format(Temp,127,"%d|%s",Plugin,Handler)
	
	new travTrieIter:Iter = GetTravTrieIterator(g_ClassArray),Cell,ClassHeader[64],Loaded,TravTrie:CurTrie,TravTrie:PluginTrie,Flag,ReadTable[64],Garbage[1]
	while(MoreTravTrie(Iter))
	{		
		ReadTravTrieKey(Iter,ClassHeader,63)
		ReadTravTrieCell(Iter,Cell)
		
		strtok(ClassHeader,ReadTable,63,Garbage,0,'|')
		if(Table[0] && equali(ReadTable,Table))
			Flag = 1
		
		if(equali(ClassName,ClassHeader))
		{			
			TravTrieGetCell(g_ClassArray,ClassHeader,CurTrie)
			
			TravTrieGetHCell(CurTrie,"/plugins",PluginTrie)
			TravTrieSetCellEx(PluginTrie,Plugin,1)
			
			TravTrieGetHCell(CurTrie,"/loaded",Loaded)
			if(!Loaded)
			{				
				new TravTrie:CallsTrie
				TravTrieGetHCell(CurTrie,"/calls",CallsTrie)
				
				TravTrieSetString(CallsTrie,Temp,g_Query)
				
				return -1
			}
				
			/*new Forward = CreateOneForward(Plugin,"ARP_ClassLoaded",FP_CELL,FP_STRING),Return
			if(!Forward || !ExecuteForward(Forward,Return,_:CurTrie,Class))
			{
				format(g_Query,4095,"Could not execute ARP_ClassLoaded forward")
				return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
			}
			DestroyForward(Forward)*/
			
			new Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_STRING,FP_STRING),Return
			//new CurArray = PrepareArray(g_Query[1],Len)
			if(!Forward || !ExecuteForward(Forward,Return,_:CurTrie,ClassHeader,g_Query))
			{
				format(g_Query,4095,"Could not execute %s forward to %d",Handler,Plugin)
				return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
			}				
			DestroyForward(Forward)
			
			return PLUGIN_HANDLED
		}
	}
	DestroyTravTrieIterator(Iter)
	
	if(!Flag && !equali(g_DataTable,Table))
	{		
		static Query[512]
		switch(g_SqlMode)
		{
			case MYSQL:
				format(Query,511,"CREATE TABLE IF NOT EXISTS %s (classkey VARCHAR(64),value TEXT,UNIQUE KEY (classkey))",Table)
			case SQLITE:
				format(Query,511,"CREATE TABLE IF NOT EXISTS %s (classkey VARCHAR(64),value TEXT,UNIQUE (classkey))",Table)
		}
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",Query)
	}
	
	new Buffer[128] //,TravTrie:CallTrie = TravTrieCreate()
	//SQL_QuoteString(g_SqlHandle,Buffer,127,Param)
	copy(Buffer,126,Param)
	
	//server_print("Setting array: %d | %s | %s | %d",CallTrie,Handler,g_Query,Len)
	new TravTrie:CallTrie = TravTrieCreate()
	PluginTrie = TravTrieCreate()
	TravTrieSetCellEx(PluginTrie,Plugin,1)
	TravTrieSetString(CallTrie,Temp,g_Query)
	
	CurTrie = TravTrieCreate()
	TravTrieSetCell(g_ClassArray,ClassName,CurTrie)
	TravTrieSetHCell(CurTrie,"/loaded",0)
	TravTrieSetHCell(CurTrie,"/saving",0)
	TravTrieSetHCell(CurTrie,"/lastquery",0)
	TravTrieSetHCell(CurTrie,"/plugins",PluginTrie)
	TravTrieSetHCell(CurTrie,"/changed",TravTrieCreate())
	TravTrieSetHCell(CurTrie,"/calls",CallTrie)
	TravTrieSetHCell(CurTrie,"/savetrie",TravTrieCreate())
	TravTrieSetString(CurTrie,"/table",Table)
	//TravTrieSetString(CurTrie,"/table",Table)
	
	Buffer[127] = _:CurTrie
	
	new OldBuffer[128]
	for(new i;i < 128;i++)
		OldBuffer[i] = Buffer[i]
	ARP_SqlEscape(Buffer,charsmax(Buffer))
	format(g_Query,4095,"SELECT * FROM %s WHERE classkey LIKE '%s|%%'",Table,Buffer)
	//UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"ClassLoadHandle",g_Query,Buffer,128)
	SQL_ThreadQuery(g_SqlHandle,"ClassLoadHandle",g_Query,OldBuffer,128)
	
	return PLUGIN_CONTINUE
}

public ClassLoadHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{	
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new ClassKey[128],Key[64],Value[128],Garbage[2],TravTrie:CurTrie = TravTrie:Data[127],TravTrie:CallsTrie
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,0,ClassKey,127)
		strtok(ClassKey,Garbage,1,Key,63,'|')
		SQL_ReadResult(Query,1,Value,127)
		
		TravTrieSetString(CurTrie,Key,Value)
		
		SQL_NextRow(Query)
	}
	
	TravTrieSetHCell(CurTrie,"/loaded",1)
	
	TravTrieGetHCell(CurTrie,"/calls",CallsTrie)
	new travTrieIter:Iter = GetTravTrieIterator(CallsTrie),Handler[64],Forward,Return,Temp[64],PluginStr[10],Plugin
	while(MoreTravTrie(Iter))
	{		
		ReadTravTrieKey(Iter,Temp,63)
		strtok(Temp,PluginStr,9,Handler,63,'|')
		Plugin = str_to_num(PluginStr)
		ReadTravTrieString(Iter,g_Query,4095)
		
		Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_STRING,FP_STRING)
		//CurArray = PrepareArray(g_Query[1],g_Query[0])
		if(!Forward || !ExecuteForward(Forward,Return,_:CurTrie,Data,g_Query))
		{
			format(g_Query,4095,"Could not execute %s forward to %d",Handler,Plugin)
			return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
		}
		DestroyForward(Forward)
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieDestroy(CallsTrie)
	
	Forward = CreateMultiForward("ARP_ClassLoaded",ET_IGNORE,FP_CELL,FP_STRING)
	if(!Forward || !ExecuteForward(Forward,Return,_:CurTrie,Data))
	{
		format(g_Query,4095,"Could not execute ARP_ClassLoaded forward")
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
	}
	DestroyForward(Forward)
	
	return PLUGIN_CONTINUE
}

public _ARP_ClassSave(ThisPlugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,ThisPlugin)
	}
	
	new TravTrie:ClassNum = TravTrie:get_param_byref(1),ProcClass[128],Close = get_param(2),travTrieIter:Iter = GetTravTrieIterator(g_ClassArray),TrieClass[64],TravTrie:CurTrie,TravTrie:PluginTrie,ClassName[64]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,TrieClass,63)
		ReadTravTrieCell(Iter,CurTrie)
		
		copy(ClassName,63,TrieClass[containi(TrieClass,"|") + 1])
		
		if(CurTrie == ClassNum && !task_exists(_:CurTrie))
		{
			//SQL_QuoteString(g_SqlHandle,ProcClass,127,Class)
			copy(ProcClass[1],126,TrieClass)
			
			//format(g_Query,4095,"DELETE FROM %s WHERE classkey LIKE '%s|%%'",g_DataTable,ProcClass)
			//UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
			
			ProcClass[0] = _:CurTrie
			
			new TravTrie:SaveTrie
			TravTrieGetHCell(CurTrie,"/savetrie",SaveTrie)
			
			new travTrieIter:saveIter = GetTravTrieIterator(SaveTrie),Handler[64],Temp[128],PluginStr[10],Plugin,Forward,Return
			//server_print("ITERATOR: %d, SAVETRIE: %d",Iter,SaveTrie)
			while(MoreTravTrie(saveIter))
			{
				ReadTravTrieKey(saveIter,Temp,127)
				ReadTravTrieString(saveIter,g_Query,4095)
				
				strtok(Temp,PluginStr,9,Handler,63,'|')
				Plugin = str_to_num(PluginStr)
				
				//server_print("Calling forward to: %d , %s",Plugin,Handler)
				
				Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_STRING,FP_STRING)
				if(!Forward || !ExecuteForward(Forward,Return,CurTrie,ClassName,g_Query))
				{
					format(g_Query,4095,"Could not register forward")
					return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,g_Plugin)
				}
				DestroyForward(Forward)
			}
			DestroyTravTrieIterator(saveIter)
			
			//if(_CallEvent("Class_Save",ClassName,128))
			//	return FAILED
			
			if(Close)
			{					
				//server_print("marking as closed: %s / %d",TrieClass,ThisPlugin)
				
				TravTrieGetHCell(CurTrie,"/plugins",PluginTrie)
				TravTrieDeleteKeyEx(PluginTrie,ThisPlugin)
				
				set_param_byref(1,_:Invalid_TravTrie)
			}
			
			SaveClass(CurTrie,ProcClass[1])
			
			return SUCCEEDED
		}
	}
	DestroyTravTrieIterator(Iter)
	
	return SUCCEEDED
}

public SaveClass(TravTrie:CurTrie,ProcClass[])
{	
	new Saving
	TravTrieGetHCell(CurTrie,"/saving",Saving)
	if(Saving)
		return SUCCEEDED
	
	new TravTrie:ChangedTrie,Table[64],ClassName[64]//,Garbage[1]
	TravTrieGetHCell(CurTrie,"/changed",ChangedTrie)
	//TravTrieGetString(CurTrie,"/table",Table,63)
	//TravTrieGetHCell(CurTrie,"/table",TableTrie)
	//TravTrieGetStringEx(TableTrie,0,Table,63)
	
	strtok(ProcClass,Table,63,ClassName,63,'|')
	
	TravTrieSetHCell(CurTrie,"/saving",1)
	
	new Key[128],Data[64],TrieClass[64]
	Data[1] = _:CurTrie
	
	copy(Data[2],60,ProcClass)
	
	//format(g_Query,4095,"DELETE FROM %s WHERE classkey LIKE '%s|%%'",g_DataTable,ProcClass)
	//UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	new travTrieIter:Iter = GetTravTrieIterator(CurTrie),Changed,ChangedNum
	
	// Run through it once to get the number
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,TrieClass,63)
		ReadTravTrieString(Iter,g_Query,4095)
		
		TravTrieGetCell(ChangedTrie,TrieClass,Changed)
		
		if(TrieClass[0] != '^n' && TrieClass[0] != '/' && Changed) ChangedNum++
		
		Changed = 0
	}
	
	TravTrieSetHCell(CurTrie,"/lastquery",ChangedNum)
	DestroyTravTrieIterator(Iter)
	
	Iter = GetTravTrieIterator(CurTrie)
	while(MoreTravTrie(Iter))
	{				
		ReadTravTrieKey(Iter,TrieClass,63)
		ReadTravTrieString(Iter,g_Query,4095)
		TravTrieGetCell(ChangedTrie,TrieClass,Changed)
		
		if(TrieClass[0] == '^0' || TrieClass[0] == '/' || !Changed) continue
		
		TravTrieSetCell(ChangedTrie,TrieClass,0)
		
		Changed = 0
		
		//SQL_QuoteString(g_SqlHandle,Key,127,TrieClass)
		copy(Key,127,TrieClass)
		//SQL_QuoteString(g_SqlHandle,g_Cache,4095,g_Query)
		copy(g_Cache,4095,g_Query)
		
		Data[0]++
		
		ARP_SqlEscape(ClassName,127)
		ARP_SqlEscape(Key,127)
		ARP_SqlEscape(g_Cache,4095)
		//replace_all(ClassName,127,"'","\'")
		//replace_all(Key,127,"'","\'")
		//replace_all(g_Cache,4095,"'","\'")
		
		switch(g_SqlMode)
		{
			case MYSQL: 
				format(g_Query,4095,"INSERT INTO %s VALUES ('%s|%s','%s') ON DUPLICATE KEY UPDATE value='%s'",Table,ClassName,Key,g_Cache,g_Cache)
			case SQLITE:
				format(g_Query,4095,"REPLACE INTO %s VALUES ('%s|%s','%s')",Table,ClassName,Key,g_Cache)
		}
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"ClassSaveHandle",g_Query,Data,64)
	}
	DestroyTravTrieIterator(Iter)
	
	new TravTrie:PluginTrie,TravTrie:SaveTrie
	TravTrieGetHCell(CurTrie,"/plugins",PluginTrie)
	TravTrieGetHCell(CurTrie,"/savetrie",SaveTrie)
	
// Hawk552: Do this later no matter what driver we're running.
#if 000
	if(!ChangedNum && !TravTrieSize(PluginTrie) && g_SqlMode == SQLITE)
	{				
		TravTrieDestroy(PluginTrie)
		TravTrieDestroy(CurTrie)
		TravTrieDestroy(ChangedTrie)
		TravTrieDestroy(SaveTrie)
			
		TravTrieDeleteKey(g_ClassArray,ProcClass)
	}
#endif
	
	if(!ChangedNum)
		ClassSaveHandle(0,Empty_Handle,"",0,Data,64)
	
	return SUCCEEDED
}

public ClassSaveHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		SQL_GetQueryString(Query,g_Query,4095)		
		format(g_Query,4095,"Internal error: %s^nQuery: %s",Error,g_Query)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	new LastQuery,TravTrie:CurTrie = TravTrie:Data[1]
	TravTrieGetHCell(CurTrie,"/lastquery",LastQuery)
	
	if(Data[0] == LastQuery /*&& g_SqlMode != SQLITE*/)
	{
		TravTrieSetHCell(CurTrie,"/saving",0)
	
		new TravTrie:PluginTrie,TravTrie:ChangedTrie,TravTrie:SaveTrie
		TravTrieGetHCell(CurTrie,"/plugins",PluginTrie)
		TravTrieGetHCell(CurTrie,"/changed",ChangedTrie)
		TravTrieGetHCell(CurTrie,"/savetrie",SaveTrie)

		//server_print("trie size: %d [%s]", TravTrieSize(PluginTrie),Data[2])
		if(!TravTrieSize(PluginTrie) && !g_PluginEnd)
		{
			//server_print("destroying %s",Data[2])
			
			TravTrieDestroy(PluginTrie)
			TravTrieDestroy(CurTrie)
			TravTrieDestroy(ChangedTrie)
			TravTrieDestroy(SaveTrie)
			
			TravTrieDeleteKey(g_ClassArray,Data[2])
		}
		
		//if(g_PluginEnd && g_LastOverallQuery == Data[2]) TravTrieDestroy(g_ClassArray)
	}
	
	return PLUGIN_CONTINUE
}

public _ARP_ClassSaveHook(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new TravTrie:CurTrie = TravTrie:get_param(1),Handler[64],Temp[128],TravTrie:SaveTrie
	get_string(2,Handler,63)
	get_string(3,g_Query,4095)
	
	format(Temp,127,"%d|%s",Plugin,Handler)
	
	TravTrieGetHCell(CurTrie,"/savetrie",SaveTrie)
	TravTrieSetString(SaveTrie,Temp,g_Query)
	
	return SUCCEEDED
}

public _ARP_ClassDeleteKey(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new TravTrie:ClassNum = TravTrie:get_param(1),Key[64]
	get_string(2,Key,63)
	
	if(Key[0] == '/' || Key[0] == '^n' || !ClassNum) 
		return FAILED
	
	new travTrieIter:Iter = GetTravTrieIterator(g_ClassArray),Cell,Name[64],Table[64]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Name,63)
		ReadTravTrieCell(Iter,Cell)
		if(Cell == _:ClassNum)		
		{
			strtok(Name,"",0,Name,63,'|')
			break
		}
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieGetString(ClassNum,"/table",Table,63)
	
	//if(!Name[0])
	//	return FAILED
	
	new KeyDeleted = TravTrieDeleteKey(ClassNum,Key)
	
	ARP_SqlEscape(Name,63)
	ARP_SqlEscape(Key,63)
	
	format(g_Query,4095,"DELETE FROM %s WHERE classkey='%s|%s'",Table,Name,Key)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	return KeyDeleted
}

public _ARP_ClassDestroy(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new TravTrie:CurTrie = TravTrie:get_param(1)
	
	new travTrieIter:Iter = GetTravTrieIterator(g_ClassArray),Cell,Name[64],Table[64]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Name,63)
		ReadTravTrieCell(Iter,Cell)
		if(Cell == _:CurTrie)			
			break
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieGetString(CurTrie,"/table",Table,63)
	
	format(g_Query,4095,"DELETE FROM %s WHERE classkey LIKE '%s|%%'",Table,Name)
	
	new TravTrie:PluginTrie,TravTrie:ChangedTrie,TravTrie:SaveTrie
	TravTrieGetHCell(CurTrie,"/plugins",PluginTrie)
	TravTrieGetHCell(CurTrie,"/changed",ChangedTrie)
	TravTrieGetHCell(CurTrie,"/savetrie",SaveTrie)
		
	TravTrieDestroy(PluginTrie)
	TravTrieDestroy(CurTrie)
	TravTrieDestroy(ChangedTrie)
	TravTrieDestroy(SaveTrie)
	
	TravTrieDeleteKey(g_ClassArray,Name)
	
	return SUCCEEDED
}

public _ARP_AddMenuItem(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(!g_MenuAccepting[id])
	{
		format(g_Query,4095,"The menu only accepts items during the 'clientmenu' event.")
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Name[33],Handler[64],Data[64]
	get_string(2,Name,32)
	get_string(3,Handler[1],62)
	Handler[0] = Plugin
	
	Data[0] = Plugin
	copy(Data[1],62,Name)
	
	return _CallEvent("Menu_AddItem",Data,63) ? PLUGIN_CONTINUE : _:TravTrieSetString(g_MenuArray[id],Name,Handler)
}

public _ARP_CallEvent(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Len = min(4095,get_param(3)),Name[33]
	get_array(2,g_Query,Len)
	get_string(1,Name,32)

	return _CallEvent(Name,g_Query,Len)
}

_CallEvent(Name[],Data[],Length)
{
	new travTrieIter:Iter = GetTravTrieIterator(g_EventTrie),Event[128],Key[128],Plugin,PluginStr[12],Handler[128],Forward,Return
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,127)
		ReadTravTrieString(Iter,Event,127)
		
		if(!equal(Event,Name))
			continue
		
		strtok(Key,PluginStr,11,Handler,127,'|')
		Plugin = str_to_num(PluginStr)
		
		Forward = CreateOneForward(Plugin,Handler,FP_STRING,FP_ARRAY,FP_CELL)
		if(!Forward)
		{
			format(g_Query,4095,"Could not register forward")
			return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,g_Plugin)
		}
		
		new CurArray = PrepareArray(Data,Length)
	
		if(!ExecuteForward(Forward,Return,Event,CurArray,Length))
		{
			format(g_Query,4095,"Could not execute forward: %s in %d",Handler,Plugin)
			return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,g_Plugin)
		}
		
		DestroyForward(Forward)
		
		if(Return)
			return Return
	}
	DestroyTravTrieIterator(Iter)
	
	Forward = CreateMultiForward("ARP_Event",ET_STOP2,FP_STRING,FP_ARRAY,FP_CELL)
	if(!Forward)
	{
		format(g_Query,4095,"Could not register forward")
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,g_Plugin)
	}
	
	new CurArray = PrepareArray(Data,Length)
	
	if(!ExecuteForward(Forward,Return,Name,CurArray,Length))
	{
		format(g_Query,4095,"Could not execute forward")
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,g_Plugin)
	}
	
	DestroyForward(Forward)
	
	return Return
}

public _ARP_RegisterEvent(Plugin,Params)
{
	if(Params < 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new travTrieIter:Iter = GetTravTrieIterator(g_EventTrie),Event[128],Handler[128],Key[128],Dummy[2]
	get_string(1,Event,127)
	get_string(2,Handler,127)
	
	format(Handler,127,"%d|%s",Plugin,Handler)
	
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,127)
		ReadTravTrieString(Iter,Dummy,1)
		
		// It's okay if the event repeats as multiple plugins can register it
		if(equali(Handler,Key))
			return FAILED
	}
	
	DestroyTravTrieIterator(Iter)
	
	TravTrieSetString(g_EventTrie,Handler,Event)
	
	return SUCCEEDED
}

public _ARP_GetTable(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	switch(get_param(1))
	{
		case 0 :
			set_string(2,g_UserTable,get_param(3))
		case 1 :
			set_string(2,g_JobsTable,get_param(3))
		case 2 :
			set_string(2,g_PropertyTable,get_param(3))
		case 3 :
			set_string(2,g_DoorsTable,get_param(3))
		case 4 :
			set_string(2,g_KeysTable,get_param(3))
		case 5 :
			set_string(2,g_ItemsTable,get_param(3))
		case 6 :
			set_string(2,g_DataTable,get_param(3))
	}

	return SUCCEEDED
}

public _ARP_GetPayday(Plugin,Params)
	return g_Time / 10

public _ARP_Version(Plugin,Params)
{
	if(Params == 2)
		set_string(1,g_Version,get_param(2))
	else
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2 or more, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return SUCCEEDED
}

public _ARP_ClientPrint(Plugin,Params)
{
	if(Params < 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2 or more, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	get_string(2,g_Query,4095)
	
	if(!is_user_connected(id) && id)
	{
		format(g_Query,4095,"User is not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	vformat(g_Query,4095,g_Query,3)
	
	UTIL_ARP_ClientPrint(id,g_Query)
	
	return SUCCEEDED
}

public _ARP_GetConfigsdir(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	set_string(1,g_ConfigsDir,get_param(2))
	
	return SUCCEEDED
}

public _ARP_GetUserJobRight(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(is_user_connected(id))
		return g_JobRight[id]
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserJobRight(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1),Rights = get_param(2),Set
	for(new Count;Count < JOB_ACCESSES;Count++)
		if(Rights & (1<<Count))
			Set |= (1<<Count)
	
	if(is_user_connected(id))
		return g_JobRight[id] = Set
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	return FAILED
}

public _ARP_ItemSet(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(is_user_connected(id))
		return g_ItemUse[id] ? FAILED : (g_ItemUse[id] = Plugin)
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_ValidItemId(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_ValidItemId(get_param(1))
}

public _ARP_ForceUseItem(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1),ItemId = get_param(2),UseUp = get_param(3)
	
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(UseUp && !UTIL_ARP_GetUserItemNum(id,ItemId))
	{
		format(g_Query,4095,"User %d has none of item: %d",id,ItemId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(g_ItemUse[id] && UseUp)
		return FAILED
	
	if(UTIL_ARP_ValidItemId(ItemId))
		return ItemUse(id,ItemId,UseUp ? 1 : 0)
	
	format(g_Query,4095,"Invalid item id: %d",ItemId)
	return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
}

public _ARP_AddJob(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Name[33],Salary,IntAccess
	
	get_string(1,Name,32)
	Salary = get_param(2)
	IntAccess = get_param(3)
	
	new Results[1]
	ARP_FindJobId(Name,Results,1)
	
	if(Results[0])
	{
		Results[0] -= 1
		
		new TempName[33]
		array_get_string(array_get_int(g_JobsArray,Results[0]),1,TempName,32)
		
		format(g_Query,4095,"A job with a similar name already exists. User input: %s - Existing job: %s",Name,TempName)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_AddJob(Name,Salary,IntAccess) + 1
}

UTIL_ARP_AddJob(Name[],Salary,IntAccess)
{
	new Access[JOB_ACCESSES + 1]
	ARP_IntToAccess(IntAccess,Access,JOB_ACCESSES)
	
	#if defined DEBUG
	g_TotalQueries++
	#endif
	
	new FmtName[64]
	copy(FmtName,63,Name)
	ARP_SqlEscape(FmtName,63)
	
	format(g_Query,4095,"INSERT INTO %s VALUES ('%s','%d','%s')",g_JobsTable,Name,Salary,Access)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	new CurArray = array_create()
	array_set_int(g_JobsArray,g_JobsNum++,CurArray)
	
	array_set_string(CurArray,1,Name)
	array_set_int(CurArray,2,Salary)
	array_set_int(CurArray,3,IntAccess)
	
	return g_JobsNum - 1
}

public _ARP_DeleteJob(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(1) - 1
	
	if(!UTIL_ARP_ValidJobId(JobId))
	{
		format(g_Query,4095,"Invalid job id: %d",JobId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_DeleteJob(JobId)
}

UTIL_ARP_DeleteJob(JobId)
{
	new Players[32],Playersnum,Player,Jobs[1]
	get_players(Players,Playersnum)
	
	if(!ARP_FindJobId("Unemployed",Jobs,1))
	{
		format(g_Query,4095,"Error finding ^"Unemployed^" job.")
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
	}
	
	new Unemployed = Jobs[0] - 1
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		if(g_JobId[Player] == JobId)
			g_JobId[Player] = Unemployed
	}
	
	new Name[33]
	array_get_string(array_get_int(g_JobsArray,JobId),1,Name,32)
	
	format(g_Query,4095,"DELETE FROM %s WHERE name='%s'",g_JobsTable,Name)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	new JobArray = array_get_int(g_JobsArray,JobId)
	array_destroy(JobArray)
	array_set_int(g_JobsArray,JobId,-1)
	
	return SUCCEEDED
}

public _ARP_AddProperty(Plugin,Params)
{
	if(Params != 8)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 5, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new InternalName[64],ExternalName[64],OwnerName[33],OwnerAuth[36],Price,Locked,Access,Profit
	get_string(1,InternalName,63)
	get_string(2,ExternalName,63)
	get_string(3,OwnerName,32)
	get_string(4,OwnerAuth,35)
	Price = get_param(5)
	Locked = get_param(6)
	Access = get_param(7)
	Profit = get_param(8)
	
	if(UTIL_ARP_MatchProperty(InternalName) != -1)
	{
		format(g_Query,4095,"Property already exists: %s",InternalName)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new CurArray = array_create()
	array_set_int(g_PropertyArray,g_PropertyNum++,CurArray)
	
	array_set_string(CurArray,0,InternalName)
	array_set_string(CurArray,1,ExternalName)
	array_set_string(CurArray,2,OwnerName)
	array_set_string(CurArray,3,OwnerAuth)
	array_set_int(CurArray,4,Price)
	array_set_int(CurArray,5,Locked)
	array_set_int(CurArray,6,Access)
	array_set_int(CurArray,7,Profit)
	array_set_int(CurArray,8,0)
	array_set_int(CurArray,9,1)
	
	//format(g_Query,4095,"INSERT INTO %s VALUES ('%s','%s','','','%d','0','','0','','%s')",g_PropertyTable,Targetname,Name,Price,FakeMsg)
	//UTIL_ARP_CleverQuery(g_Plugin(g_SqlHandle,"IgnoreHandle",g_Query)
	
	return g_PropertyNum
}

public _ARP_DeleteProperty(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
		return FAILED
	
	new InternalName[33],FetchInternalName[33],CurArray,NextArray,PropArray = array_get_int(g_PropertyArray,Property)
	array_get_string(PropArray,0,InternalName,32)
	
	new NextInternalName[64],ExternalName[64],OwnerName[33],OwnerAuth[36]
	for(new Count = Property;Count < g_PropertyNum - 1;Count++)
	{
		NextArray = array_get_int(g_PropertyArray,Count + 1)
		array_get_string(NextArray,0,NextInternalName,63)
		array_get_string(NextArray,1,ExternalName,63)
		array_get_string(NextArray,2,OwnerName,32)
		array_get_string(NextArray,3,OwnerAuth,35)
		CurArray = array_get_int(g_PropertyArray,Count)
		array_set_string(CurArray,0,NextInternalName)
		array_set_string(CurArray,1,ExternalName)
		array_set_string(CurArray,2,OwnerName)
		array_set_string(CurArray,3,OwnerAuth)
		array_set_int(CurArray,4,array_get_int(NextArray,4))
		array_set_int(CurArray,5,array_get_int(NextArray,5))
		array_set_int(CurArray,6,array_get_int(NextArray,6))
		array_set_int(CurArray,7,array_get_int(NextArray,7))
		array_set_int(CurArray,8,array_get_int(NextArray,8))
		array_set_int(CurArray,9,array_get_int(NextArray,9))
		
		array_set_int(g_PropertyArray,Count,NextArray)
	}
	
	array_destroy(PropArray)
	array_delete(g_PropertyArray,--g_PropertyNum)
	
	format(g_Query,4095,"DELETE FROM %s WHERE internalname='%s'",g_PropertyTable,InternalName)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	for(new Count;Count < g_DoorNum;Count++)
	{
		CurArray = array_get_int(g_DoorArray,Count)
		array_get_string(g_DoorArray,2,FetchInternalName,32)
		
		if(equali(InternalName,FetchInternalName))
			UTIL_ARP_DeleteDoor(Count)
	}
	
	return SUCCEEDED
}

public _ARP_AddDoor(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,511,"Parameters do not match. Expected: 5, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Targetname[33],EntID,InternalName[64]
	get_string(1,Targetname,32)
	EntID = get_param(2)
	get_string(3,InternalName,63)
	
	if(UTIL_ARP_GetProperty(Targetname,EntID) != -1)
	{
		format(g_Query,4095,"Door already exists: %s/%d",Targetname,EntID)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(UTIL_ARP_MatchProperty(InternalName) == -1)
	{
		format(g_Query,4095,"Property does not exist: %s",InternalName)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new CurArray = array_create()
	array_set_int(g_DoorArray,g_DoorNum++,CurArray)
	
	array_set_string(CurArray,0,Targetname)
	array_set_int(CurArray,1,EntID)
	array_set_string(CurArray,2,InternalName)
	array_set_int(CurArray,3,1)
	
	return g_DoorNum
}

public _ARP_DeleteDoor(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Door = get_param(1) - 1
	if(UTIL_ARP_ValidDoor(Door))
		return UTIL_ARP_DeleteDoor(Door)
	
	return FAILED
}

UTIL_ARP_DeleteDoor(Door)
{
	new Targetname[33],InternalName[64],CurArray,NextArray,DoorArray = array_get_int(g_DoorArray,Door)
	for(new Count = Door;Count < g_DoorNum - 1;Count++)
	{
		NextArray = array_get_int(g_DoorArray,Count + 1)
		array_get_string(NextArray,0,Targetname,32)
		array_get_string(NextArray,2,InternalName,63)
		CurArray = array_get_int(g_DoorArray,Count)
		array_set_string(CurArray,0,Targetname)
		array_set_int(CurArray,1,array_get_int(NextArray,1))
		array_set_string(CurArray,2,InternalName)
		array_set_int(CurArray,3,array_get_int(NextArray,3))
		
		array_set_int(g_DoorArray,Count,NextArray)
	}
	
	array_destroy(DoorArray)
	array_delete(g_DoorArray,--g_DoorNum)
	
	format(g_Query,4095,"DELETE FROM %s WHERE internalname='%s'",g_DoorsTable,InternalName)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	return SUCCEEDED
}

public _ARP_ValidProperty(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_ValidProperty(get_param(1) - 1)
}

public _ARP_ValidDoor(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_ValidDoor(get_param(1) - 1)
}

public _ARP_ValidPropertyName(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new InternalName[64]
	get_string(1,InternalName,63)
	
	if(UTIL_ARP_MatchProperty(InternalName) > -1)
		return SUCCEEDED
	
	return FAILED
}
	
public _ARP_ValidDoorName(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	new Ent = get_param(2),Targetname[33]
	get_string(1,Targetname,32)
	
	if(UTIL_ARP_GetProperty(Targetname,Ent) > -1)
		return SUCCEEDED
	
	return FAILED
}

public _ARP_PropertyNum()
	return g_PropertyNum

public _ARP_DoorNum()
	return g_DoorNum

public _ARP_PropertyMatch(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Targetname[33],EntID = get_param(2),InternalName[64]
	get_string(1,Targetname,32)
	get_string(3,InternalName,63)
	
	if(Targetname[0] || EntID)
		return UTIL_ARP_GetProperty(Targetname,EntID) + 1
		
	return UTIL_ARP_MatchProperty(InternalName) + 1
}

public _ARP_DoorMatch(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Targetname[33],EntID = get_param(2)
	get_string(1,Targetname,32)
	
	if(Targetname[0] || EntID)
		return UTIL_ARP_GetDoor(Targetname,EntID) + 1
		
	return FAILED
}

public _ARP_PropertySetExternalName(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,ExternalName[64]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	get_string(2,ExternalName,63)
	array_set_string(array_get_int(g_PropertyArray,Property),1,ExternalName)
	
	UTIL_ARP_PropertyChanged(Property)
	
	return SUCCEEDED
}

public _ARP_PropertyGetExternalName(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,ExternalName[64]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_get_string(array_get_int(g_PropertyArray,Property),1,ExternalName,63)
	set_string(2,ExternalName,get_param(3))
	
	return SUCCEEDED
}

public _ARP_PropertyGetInternalName(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,InternalName[64]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_get_string(array_get_int(g_PropertyArray,Property),0,InternalName,63)
	set_string(2,InternalName,get_param(3))
	
	return SUCCEEDED
}

public _ARP_PropertySetOwnerName(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,OwnerName[33]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	get_string(2,OwnerName,32)
	array_set_string(array_get_int(g_PropertyArray,Property),2,OwnerName)
	
	return SUCCEEDED
}

public _ARP_PropertyGetOwnerName(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,OwnerName[33]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_get_string(array_get_int(g_PropertyArray,Property),2,OwnerName,33)
	set_string(2,OwnerName,get_param(3))
	
	return SUCCEEDED
}

public _ARP_PropertySetOwnerAuth(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,OwnerAuth[33]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	get_string(2,OwnerAuth,32)
	array_set_string(array_get_int(g_PropertyArray,Property),3,OwnerAuth)
	
	return SUCCEEDED
}

public _ARP_PropertyGetOwnerAuth(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,OwnerAuth[33]
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_get_string(array_get_int(g_PropertyArray,Property),3,OwnerAuth,33)
	set_string(2,OwnerAuth,get_param(3))
	
	return SUCCEEDED
}

public _ARP_PropertySetPrice(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_set_int(array_get_int(g_PropertyArray,Property),4,max(0,get_param(2)))
	
	return SUCCEEDED
}

public _ARP_PropertyGetPrice(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_PropertyArray,Property),4)
}

public _ARP_PropertySetLocked(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	array_set_int(array_get_int(g_PropertyArray,Property),5,get_param(2) ? 1 : 0)
	
	return SUCCEEDED
}

public _ARP_PropertyGetLocked(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_PropertyArray,Property),5)
}

public _ARP_PropertySetAccess(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	array_set_int(array_get_int(g_PropertyArray,Property),6,get_param(2))
	
	return SUCCEEDED
}

public _ARP_PropertyGetAccess(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_PropertyArray,Property),6)
}

public _ARP_PropertySetProfit(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	array_set_int(array_get_int(g_PropertyArray,Property),7,max(0,get_param(2)))
	
	return SUCCEEDED
}

public _ARP_PropertyGetProfit(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_PropertyArray,Property),7)
}

public _ARP_PropertyAddAccess(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,Authid[36],InternalName[64]
	get_string(2,Authid,35)
	
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	new CurArray = array_get_int(g_PropertyArray,Property)
	array_get_string(CurArray,0,InternalName,63)
	
	#if defined DEBUG
	g_TotalQueries++
	#endif
	
	ARP_SqlEscape(InternalName,63)
	
	format(g_Query,4095,"INSERT INTO %s VALUES('%s|%s')",g_KeysTable,Authid,InternalName)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	new PlayerAuthid[36],Players[32],Playersnum,Player
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		get_user_authid(Player,PlayerAuthid,35)
		
		if(equali(Authid,PlayerAuthid))
		{
			array_set_int(CurArray,8,array_get_int(CurArray,8)|(1<<(Player - 1)))
			break
		}
	}
	
	return SUCCEEDED
}

public _ARP_PropertyRemoveAccess(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1,Authid[36],InternalName[64]
	get_string(2,Authid,35)
	
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	new CurArray = array_get_int(g_PropertyArray,Property)
	array_get_string(CurArray,0,InternalName,63)
	
	#if defined DEBUG
	g_TotalQueries++
	#endif
	
	ARP_SqlEscape(InternalName,63)
	
	format(g_Query,4095,"DELETE FROM %s WHERE authidkey='%s|%s'",g_KeysTable,Authid,InternalName)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	
	new PlayerAuthid[36],Players[32],Playersnum,Player
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		get_user_authid(Player,PlayerAuthid,35)
		
		if(equali(Authid,PlayerAuthid))
		{
			array_set_int(CurArray,8,array_get_int(CurArray,8) & ~(1<<(Player - 1)))
			break
		}
	}
	
	return SUCCEEDED
}

public _ARP_PropertyClearAccess(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Property = get_param(1) - 1
	
	if(!UTIL_ARP_ValidProperty(Property))
	{
		format(g_Query,4095,"Property does not exist: %d",Property)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	UTIL_ARP_PropertyChanged(Property)
	
	return UTIL_ARP_PropertyClearAccess(Property)
}

UTIL_ARP_PropertyClearAccess(Property)
{
	new CurArray = array_get_int(g_PropertyArray,Property),InternalName[64]
	array_get_string(CurArray,0,InternalName,63)
	
	#if defined DEBUG
	g_TotalQueries++
	#endif
	
	ARP_SqlEscape(InternalName,63)
	
	if(array_get_int(CurArray,8))
	{
		format(g_Query,4095,"DELETE FROM %s WHERE authidkey LIKE '%%|%s'",g_KeysTable,InternalName)
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
		
		array_set_int(CurArray,8,0)
	}
	
	return SUCCEEDED
}

public _ARP_AddHudItem(Plugin,Params)
{
	if(Params < 4)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 4, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1),Channel = get_param(2),Refresh = get_param(3)
	if(!is_user_connected(id) && id != -1)
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(Channel < 0 || Channel > HUD_NUM)
	{
		format(g_Query,4095,"Invalid channel: %d",Channel)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}

	vdformat(g_Query,4095,4,5)
	//while(replace(g_Query,4095,"^n","")) { }
	//add(g_Query,4095,"^n")

	if(g_HudPending)
		Refresh = 0
	
	UTIL_ARP_AddHudItem(id,Channel,g_Query,Refresh)
	
	return SUCCEEDED
}

public _ARP_SqlHandle(Plugin,Params)
	return _:g_SqlHandle

public _ARP_GetNpcClassname(Plugin,Params)
{
	if(Params != 2)	
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	set_string(1,g_NpcClassname,get_param(2))
	
	return SUCCEEDED
}

public _ARP_GetUserWallet(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))
		return g_Money[id]
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserWallet(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))
		return g_Money[id] = get_param(2)
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	return FAILED
}

public _ARP_GetUserBank(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))	
		return g_BankMoney[id]
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserBank(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))
		return g_BankMoney[id] = get_param(2)
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_GetUserHunger(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)

	if(is_user_connected(id))	
		return g_Hunger[id] / 10
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	return FAILED
}

public _ARP_SetUserHunger(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))
		return g_Hunger[id] = clamp(get_param(2),0,100) * 10
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_GetUserAccess(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(is_user_connected(id))
		return g_Access[id]
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserAccess(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1),Access = get_param(2)
	if(is_user_connected(id))
	{
		g_Access[id] = Access
		g_Access[id] |= array_get_int(array_get_int(g_JobsArray,g_JobId[id]),3)
					
		g_AccessCache[id] = Access
	}
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return SUCCEEDED
}

public _ARP_GetJobsNum(Plugin,Params)
{
	// if it is anything other than 0
	if(Params)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 0, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return g_JobsNum
}

public _ARP_GetJobName(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(1) - 1,Name[33]
	
	if(!UTIL_ARP_ValidJobId(JobId))
	{
		format(g_Query,4095,"Invalid job id: %d",JobId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	array_get_string(array_get_int(g_JobsArray,JobId),1,Name,32)
			
	set_string(2,Name,get_param(3))
	
	return SUCCEEDED
}

public _ARP_GetJobSalary(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(1) - 1
	
	if(!UTIL_ARP_ValidJobId(JobId))
	{
		format(g_Query,4095,"Invalid job id: %d",JobId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_JobsArray,JobId),2)
}

public _ARP_GetJobAccess(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(1) - 1
	
	if(!UTIL_ARP_ValidJobId(JobId))
	{
		format(g_Query,4095,"Invalid job id: %d",JobId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return array_get_int(array_get_int(g_JobsArray,JobId),3)
}
	
public _ARP_GetUserJobId(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	
	if(is_user_connected(id))
		return UTIL_ARP_ValidJobId(g_JobId[id]) ? g_JobId[id] + 1 : FAILED
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserJobId(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(2) - 1,id = get_param(1)
	
	if(!UTIL_ARP_ValidJobId(JobId))
	{
		format(g_Query,4095,"Invalid job id: %d",JobId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"User not connected: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}

	g_JobId[id] = JobId
	g_Access[id] = g_AccessCache[id]
	
	g_Salary[id] = array_get_int(array_get_int(g_JobsArray,JobId),2)
	//g_Access[id] |= g_JobAccess[g_JobId[id]]
	g_Access[id] |= array_get_int(array_get_int(g_JobsArray,JobId),3)
	
	return SUCCEEDED
}

public _ARP_ValidJobId(Plugin,Params)
{
	if(Params != 1 && Plugin)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new JobId = get_param(1) - 1
	
	return UTIL_ARP_ValidJobId(JobId)
}

public _ARP_FindJobId(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	new SearchString[64],MaxResults = get_param(3),Num,Name[33]
	static Results[512],Temp[512],Length[512]
	get_string(1,SearchString,63)
	
	for(new Count;Count < g_JobsNum;Count++)
	{		
		if(!UTIL_ARP_ValidJobId(Count)) continue
		
		array_get_string(array_get_int(g_JobsArray,Count),1,Name,32)
		if(containi(Name,SearchString) != -1)
		{
			Temp[Num] = Count + 1
			Length[Num] = strlen(Name)
			
			Num++
		}
	}
	
	new CurStep,Cell = -1
	for(new Count,LowLength,Count2;Count < Num && Count < MaxResults;Count++)
	{
		LowLength = 9999999
		for(Count2 = 0;Count2 < Num;Count2++)
		{
			if(Length[Count2] < LowLength && Length[Count2] >= CurStep && Cell != Count2)
			{
				LowLength = Length[Count2]
				Cell = Count2
			}
		}
		
		CurStep = LowLength
		Results[Count] = Temp[Cell]
	}
	
	set_array(2,Results,Num)
	
	return Num
}	

public _ARP_RegisterItem(Plugin,Params)
{
	if(Params != 4)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 4, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	// Hawk552: Disabled this for now, let's see how it goes.
	//if(!g_RegisterItem)
	//	return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,"ARP_RegisterItem can only be run in the ^"ARP_RegisterItems^" forward.",Plugin)
		
	new Name[33],Handler[33],Description[64]//,ItemId = get_param(2)
	get_string(1,Name,32)
	get_string(2,Handler,32)
	get_string(3,Description,63)
	
	//for(new Count;Count < MAX_ITEMS;Count++)
	//	if(equali(Name,g_ItemsNames[Count]) || ItemId == g_ItemsIds[Count])
	//		return FAILED
	
	new Len = strlen(Name)
	if(!Len)
	{
		format(g_Query,4095,"Name must have a length.",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new CheckName[33]
	for(new Count = 1;Count <= g_ItemsNum;Count++)
	{
		array_get_string(array_get_int(g_ItemsArray,Count),1,CheckName,32)
		if(equali(Name,CheckName))
		{
			format(g_Query,4095,"Item collision detected, name: %s",Name)
			return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
		}
	}
			
	new CurArray = array_create()
	
	array_set_int(g_ItemsArray,++g_ItemsNum,CurArray)
	array_set_string(CurArray,1,Name)
	array_set_int(CurArray,2,Plugin)
	array_set_string(CurArray,3,Handler)
	array_set_string(CurArray,4,Description)
	array_set_int(CurArray,5,get_param(4) ? 1 : 0)
	
	// this will start it at 1 externally, but 0 internally
	return g_ItemsNum
}

public _ARP_FindItemId(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	new Item[33],MaxResults = get_param(3),Num,Name[33]
	static Temp[512],Results[512],Length[512]
	get_string(1,Item,32)
	
	for(new Count = 1;Count <= g_ItemsNum && Num < 512;Count++)
	{
		array_get_string(array_get_int(g_ItemsArray,Count),1,Name,32)
		
		if(containi(Name,Item) != -1)
		{
			Temp[Num] = Count
			Length[Num] = strlen(Name)
			
			Num++
		}
	}
	
	new CurStep,Cell = -1
	for(new Count,LowLength,Count2;Count < Num && Count < MaxResults;Count++)
	{
		LowLength = 9999999
		for(Count2 = 0;Count2 < Num;Count2++)
		{
			if(Length[Count2] < LowLength && Length[Count2] >= CurStep && Cell != Count2)
			{
				LowLength = Length[Count2]
				Cell = Count2
			}
		}
		
		CurStep = LowLength
		Results[Count] = Temp[Cell]
	}
	
	if(Num) set_array(2,Results,min(MaxResults,Num))
	
	return Num
}

public _ARP_GetItemName(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	new ItemId = get_param(1),Name[33]
	/*for(new Count;Count < g_ItemsNum;Count++)
		if(g_ItemsIds[Count] == ItemId)
			return SUCCEEDED + set_string(2,g_ItemsNames[Count],get_param(3))*/
		
	UTIL_ARP_GetItemName(ItemId,Name,32)
	
	if(!Name[0])
	{
		format(g_Query,4095,"Invalid item id: %d",ItemId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	set_string(2,Name,get_param(3))
	
	return SUCCEEDED
}

public _ARP_RegisterNpc(Plugin,Params)
{
	if(Params != 7)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 7, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Float:Origin[3],Float:Angles[3],Model[64],Name[33],Handler[32],Zone,Property[64]
	
	get_string(1,Name,32)
	get_array_f(2,Origin,3)
	Angles[1] = get_param_f(3) - 180
	get_string(4,Model,63)
	get_string(5,Handler,31)
	Zone = get_param(6)
	get_string(7,Property,63)
	
	if(Zone)
	{
		new Ent = create_entity("info_target")
		if(!Ent)
		{
			format(g_Query,4095,"Unable to spawn NPC.",Params)
			return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
		}
		
		entity_set_string(Ent,EV_SZ_classname,g_NpcZoneClassname)
		entity_set_origin(Ent,Origin)
		entity_set_int(Ent,EV_INT_iuser3,Plugin)
		entity_set_string(Ent,EV_SZ_noise,Handler)
		entity_set_string(Ent,EV_SZ_noise1,Name)
		entity_set_string(Ent,EV_SZ_noise2,Property)
		
		return Ent
	}
	
	Origin[2] += 2.1
	
	if(PointContents(Origin) != CONTENTS_EMPTY)
		Origin[2] -= 2.1
	
	new Ent = create_entity("info_target")
	if(!is_valid_ent(Ent))
	{
		format(g_Query,4095,"Unable to spawn NPC.",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
	}
	
	entity_set_string(Ent,EV_SZ_classname,g_NpcClassname)
	//entity_set_model(Ent,Model)
	entity_set_model(Ent,Model)
	entity_set_origin(Ent,Origin)
	entity_set_size(Ent,Float:{-16.0,-16.0,-36.0},Float:{16.0,16.0,36.0})
	entity_set_int(Ent,EV_INT_solid,SOLID_BBOX)
	entity_set_byte(Ent,EV_BYTE_controller1,125)
	entity_set_byte(Ent,EV_BYTE_controller2,125)
	entity_set_byte(Ent,EV_BYTE_controller3,125)
	entity_set_byte(Ent,EV_BYTE_controller4,125)
	entity_set_int(Ent,EV_INT_sequence,1)
	entity_set_float(Ent,EV_FL_framerate,1.0)
	entity_set_vector(Ent,EV_VEC_angles,Angles)
	entity_set_int(Ent,EV_INT_iuser3,Plugin)
	entity_set_string(Ent,EV_SZ_noise,Handler)
	entity_set_string(Ent,EV_SZ_noise1,Name)
	entity_set_string(Ent,EV_SZ_noise2,Property)
	
	drop_to_floor(Ent)
	
	return Ent
}

public _ARP_IsNpc(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new Classname[33],Ent = get_param(1)
	if(!is_valid_ent(Ent))
	{
		format(g_Query,4095,"Invalid entity: %d",Ent)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	entity_get_string(Ent,EV_SZ_classname,Classname,32)
	
	if(equal(Classname,g_NpcClassname) || equal(Classname,g_NpcZoneClassname))
		return SUCCEEDED
	
	return FAILED
}

public _ARP_AddCommand(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new CurArray = array_create()
	
	array_set_int(g_CommandArray,++g_CommandNum,CurArray)
	
	get_string(1,g_Query,4095)
	array_set_string(CurArray,1,g_Query)
		
	get_string(2,g_Query,4095)
	array_set_string(CurArray,2,g_Query)
	
	return SUCCEEDED
}

/*public _ARP_GetUserItemId(Plugin,Params)
{
	if(Params != 2)
		return FAILED
		
	new id = get_param(1),Column = get_param(2)
	
	if(Column > g_UserItemNum[id] || !is_user_connected(id))
		return FAILED
		
	new Array =
	
	return array_isfilled(array_get_int(g_UserItemArray[id],Column),) 
}*/

public _ARP_GetUserItemNum(Plugin,Params)
{
	if(Params != 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
		
	new id = get_param(1),ItemId = get_param(2)
	
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(!UTIL_ARP_ValidItemId(ItemId))
	{
		format(g_Query,4095,"Invalid item id: %d",ItemId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_GetUserItemNum(id,ItemId)
}

public _ARP_GetUserItems(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(is_user_connected(id))
		return g_UserItemNum[id]
	else
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return FAILED
}

public _ARP_SetUserItemNum(Plugin,Params)
{
	if(Params != 3)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 3, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1),ItemId = get_param(2),ItemNum = get_param(3)/*,Cell = -1,Cache[2][MAX_USER_ITEMS]*/
	
	if(ItemNum < 0)
	{
		format(g_Query,4095,"Invalid item number, must be more than 0. Num: %d",ItemNum)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(!UTIL_ARP_ValidItemId(ItemId))
	{
		format(g_Query,4095,"Invalid item id: %d",ItemId)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	return UTIL_ARP_SetUserItemNum(id,ItemId,ItemNum)
	
	/*for(new Count;Count < MAX_USER_ITEMS;Count++)
		if(g_UserItemIds[id][Count] == ItemId)
		{
			Cell = Count
			break
		}
	
	if(Cell < 0)
		for(new Count;Count < MAX_USER_ITEMS;Count++)
			if(!g_UserItemIds[id][Count] || !g_UserItems[id][Count])
			{
				Cell = Count
				break
			}
	
	// if it's STILL less than 0
	if(Cell < 0)
	{
		log_amx("ERROR: User has max items!")
		return FAILED
	}
	
	g_UserItems[id][Cell] = Num
	g_UserItemIds[id][Cell] = ItemId
	
	Num = 0
	for(new Count;Count < MAX_USER_ITEMS;Count++)
		if(g_UserItems[id][Count] && g_UserItemIds[id][Count])
		{
			Cache[0][Num] = g_UserItems[id][Count]
			Cache[1][Num++] = g_UserItemIds[id][Count]
		}
	
	for(new Count;Count < MAX_USER_ITEMS;Count++)
		if(Count < Num)
		{
			g_UserItems[id][Count] = Cache[0][Count]
			g_UserItemIds[id][Count] = Cache[1][Count]
		}
		else
		{
			g_UserItems[id][Count] = 0
			g_UserItemIds[id][Count] = 0
		}
	
	return SUCCEEDED*/
}

public _ARP_ItemDone(Plugin,Params)
{
	if(Params != 1)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 1, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	new id = get_param(1)
	if(!is_user_connected(id))
	{
		format(g_Query,4095,"User not connected: %d",id)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,Plugin)
	}
	
	if(g_ItemUse[id] == Plugin)
		g_ItemUse[id] = 0
		
	return SUCCEEDED
}

public _ARP_ThrowError(Plugin,Params)
{
	if(Params < 2)
	{
		format(g_Query,4095,"Parameters do not match. Expected: 2 or more, Found: %d",Params)
		return UTIL_ARP_ThrowError(AMX_ERR_PARAMS,0,g_Query,Plugin)
	}
	
	get_string(2,g_Query,4095)
	new Mode = get_param(1)
	
	vformat(g_Query,4095,g_Query,3)
	
	UTIL_ARP_ThrowError(0,Mode,g_Query,Plugin)
	
	return SUCCEEDED
}
	
public client_putinserver(id)
{
	if(id > 32)
	{
		id -= 32
		if(g_Saving[id])
			set_task(0.5,"client_putinserver",id + 32)
		
		return
	}
	
	if(g_Saving[id])
	{
		set_task(0.5,"client_putinserver",id + 32)
		return
	}
	
	g_Joined[id] = false
	g_GotInfo[id] = 0
	
	//g_Money[id] = 0
	//g_BankMoney[id] = 0
	
	g_ItemUse[id] = 0
	
	new Authid[36],Data[1],Results[1]
	if(ARP_FindJobId("Unemployed",Results,1)) g_JobId[id] = Results[0]
	
	get_user_authid(id,Authid,35)
	Data[0] = id
	
	format(g_Query,4095,"SELECT * FROM %s WHERE authid='%s'",g_UserTable,Authid)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchClientData",g_Query,Data,1)
	
	format(g_Query,4095,"SELECT * FROM %s WHERE authidname LIKE '%s|%%'",g_ItemsTable,Authid)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchClientItems",g_Query,Data,1)
	
	format(g_Query,4095,"SELECT * FROM %s WHERE authidkey LIKE '%s|%%'",g_KeysTable,Authid)
	UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"FetchClientKeys",g_Query,Data,1)
}

public FetchClientData(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to SQL database.")
		return UTIL_ARP_ThrowError(0,1,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: consult developer.")
		return UTIL_ARP_ThrowError(0,1,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,1,g_Query,0)
	}
		
	new id = Data[0]
	
	g_GotInfo[id]++
	
	if(SQL_NumResults(Query) < 1)
	{
		//g_FirstJoin[id] = 1

		new Authid[36],StartMoney = get_pcvar_num(p_StartMoney)
		get_user_authid(id,Authid,35)
		
		#if defined DEBUG
		g_TotalQueries++
		#endif
		
		format(g_Query,4095,"INSERT INTO %s VALUES('%s','%d','0','Unemployed','0','','')",g_UserTable,Authid,StartMoney)
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
		
		new Results[1]
		ARP_FindJobId("Unemployed",Results,1)
		
		Results[0] -= 1
		
		//if(!UTIL_ARP_ValidJobId(Results[0]))
		//	Results[0] = ARP_AddJob("Unemployed",5,0) - 1
		
		g_Money[id] = StartMoney
		g_Hunger[id] = 0
		g_BankMoney[id] = 0
		g_JobId[id] = Results[0]
		g_Access[id] = array_get_int(array_get_int(g_JobsArray,Results[0]),3)
		g_AccessCache[id] = 0
		g_JobRight[id] = 0
		g_Salary[id] = array_get_int(array_get_int(g_JobsArray,Results[0]),2)
		
		array_clear(g_UserItemArray[id])
		
		return PLUGIN_CONTINUE
	}
	
	// terrible way of doing it (like 2000 cells in total) but whatever
	new Temp[512]//,Exploded[MAX_USER_ITEMS][10],Left[5],Right[5]
	//SQL_ReadResult(Query,3,Temp,4095)
	
	g_BankMoney[id] = SQL_ReadResult(Query,1)
	g_Money[id] = SQL_ReadResult(Query,2)
	
	/*new Num = ExplodeString(Exploded,MAX_USER_ITEMS,Temp,9,' '),Array
	
	for(new Count;Count <= Num;Count++)
	{
		strtok(Exploded[Count],Left,4,Right,4,'|',1)
		
		Array = array_create()
		array_set_int(g_UserItemArray[id],++g_UserItemNum[id],Array)
		array_set_int(Array,1,str_to_num(Left))
		array_set_int(Array,2,str_to_num(Right))
	}*/
	
	new Results[2]
	SQL_ReadResult(Query,3,Temp,4095)
	ARP_FindJobId(Temp,Results,2)
	
	g_JobId[id] = Results[0] - 1
	
	if(!Results[0])
	{
		g_BadJob[id] = 1
		
		ARP_FindJobId("Unemployed",Results,1)
		if(!UTIL_ARP_ValidJobId(Results[0] - 1))
			Results[0] = UTIL_ARP_AddJob("Unemployed",5,0)
			
		g_JobId[id] = Results[0] - 1
		g_Salary[id] = 5
	}
	else if(UTIL_ARP_ValidJobId(g_JobId[id]))
		g_BadJob[id] = 0
	else
	{
		g_BadJob[id] = 1
		
		ARP_FindJobId("Unemployed",Results,1)
		if(!UTIL_ARP_ValidJobId(Results[0] - 1))
			Results[0] = UTIL_ARP_AddJob("Unemployed",5,0)
			
		g_JobId[id] = Results[0] - 1
		g_Salary[id] = 5
	}
	
	g_Hunger[id] = SQL_ReadResult(Query,4)	
	SQL_ReadResult(Query,5,Temp,4095)
	g_Access[id] = ARP_AccessToInt(Temp)
	g_AccessCache[id] = g_Access[id]

	g_Salary[id] = array_get_int(array_get_int(g_JobsArray,g_JobId[id]),2)
	g_Access[id] |= array_get_int(array_get_int(g_JobsArray,g_JobId[id]),3)
		
	SQL_ReadResult(Query,6,Temp,4095)
	g_JobRight[id] = ARP_AccessToInt(Temp)
	
	CheckReady(id)
	
	return PLUGIN_CONTINUE
}

public FetchClientItems(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
		
	new id = Data[0],Temp[2][36],ItemId
	
	g_GotInfo[id]++
	
	array_clear(g_UserItemArray[id])
	
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,0,g_Query,4095)
		strtok(g_Query,Temp[0],35,Temp[1],35,'|',1)
		
		ItemId = UTIL_ARP_FindItemId(Temp[1])
		
		if(!UTIL_ARP_ValidItemId(ItemId))
		{			
			SQL_NextRow(Query)
			continue
		}
		
		array_set_int(g_UserItemArray[id],ItemId,-SQL_ReadResult(Query,1))
		
		SQL_NextRow(Query)
	}
	
	CheckReady(id)
	
	return PLUGIN_CONTINUE
}

public FetchClientKeys(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
		
	new id = Data[0],InternalName[33],Property,AuthidKey[64],Garbage[1]
	
	g_GotInfo[id]++
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,0,AuthidKey,63)
		strtok(AuthidKey,Garbage,0,InternalName,32,'|')
		
		Property = UTIL_ARP_MatchProperty(InternalName)
		if(Property != -1)		
			array_set_int(array_get_int(g_PropertyArray,Property),8,array_get_int(array_get_int(g_PropertyArray,Property),8)|(1<<(id - 1)))
		
		SQL_NextRow(Query)
	}
	
	CheckReady(id)
	
	return PLUGIN_CONTINUE
}

CheckReady(id)
	if(g_GotInfo[id] >= STD_USER_QUERIES)
	{
		new Data[1]
		Data[0] = id
		_CallEvent("Player_Ready",Data,1)
	}

/*
Handle:SqlConnect()
{
	static Errcode,Error[256]
	new Handle:SqlConnection = SQL_Connect(g_SqlHandle,Errcode,Error,255)
	
	if(SqlConnection == Empty_Handle)
	{
		log_amx(Error)
		g_SqlOk = false		
		
		return Handle:0
	}
	
	return SqlConnection
}
*/

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		format(g_Query,4095,"Could not connect to database: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		format(g_Query,4095,"Internal error: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	if(Errcode)
	{
		format(g_Query,4095,"Error on query: %s",Error)
		return UTIL_ARP_ThrowError(0,0,g_Query,0)
	}
	
	#if defined DEBUG
	g_TotalQueries--
	#endif
	
	return PLUGIN_CONTINUE
}

public ShowHud()
{		
	new StartTime = 600
		
	g_Time -= 10
	
	// Time is actually in like hundreds
	if(g_Time <= 0)
		g_Time = StartTime
	
	new Players[32],Playersnum,Player/*,Pos*/,Retn,Fwd
		
	get_players(Players,Playersnum)
	
	for(new Count,Count2;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		client_PreThink(Player)
		
		//for(Count2 = 0;Count2 < HUD_NUM;Count2++)
		//	ClearHud(Player,Count2)
		
		if(!is_user_connected(Player))
			continue
		
		if(g_Time == StartTime)
		{
			Fwd = CreateMultiForward("ARP_Salary",ET_STOP2,FP_CELL)
			if(Fwd < 0 || !ExecuteForward(Fwd,Retn,Player))
				continue
			
			if(!Retn)
				g_BankMoney[Player] += g_Salary[Player]
			
			DestroyForward(Fwd)
		}
		
		for(Count2 = 0;Count2 < HUD_NUM;Count2++)
			RenderHud(Player,Count2)
	}
	
	//DestroyForward(Forward)
	
	get_pcvar_string(p_Lights,g_Query,4095)
	set_lights(g_Query)
	
	set_task(2.0 - get_pcvar_float(p_Performance)/100.0,"ShowHud")
}

RenderHud(id,Hud)
{	
	g_HudPending = true
	
	static Temp[256]
	
	new Index,Body
	get_user_aiming(id,Index,Body,100)
	if(Hud != HUD_QUAT) 
		TravTrieClear(g_HudArray[id][Hud])
	
	new Data[2]
	Data[0] = id
	Data[1] = Hud
	if(_CallEvent("HUD_Render",Data,2))
		return
	
	g_Query[0] = 0
	
	new travTrieIter:Iter = GetTravTrieIterator(g_HudArray[id][Hud]),Priority,Ticker
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Temp,255)
		ReadTravTrieCell(Iter,Priority)
		
		float(Priority)
		
		Ticker += format(g_Query[Ticker],4095 - Ticker,"%s^n",Temp)
	}
	DestroyTravTrieIterator(Iter)
	
	if(Hud == HUD_QUAT)
		TravTrieClear(g_HudArray[id][Hud])
			
	g_HudPending = false
	
	/*for(new Count,CurArray,Ticker;Count < g_HudNum[id][Hud];Count++)
	{
		CurArray = array_get_int(g_HudArray[id][Hud],Count)
		
		array_get_string(CurArray,0,Temp,255)
		Ticker += format(g_Query[Ticker],4095 - Ticker,Temp)
	}*/
	
	/*if(Hud == HUD_QUAT)
	{		
		TravTrieClear(g_HudArray[id][Hud])
		
		client_print(id,print_console,"g_LastMsg[id]: %s | g_Query: %s",g_LastMsg[id],g_Query)
		
		if(equali(g_LastMsg[id],g_Query))
			return
		
		client_print(id,print_console,"Passed.")
		
		set_hudmessage(get_pcvar_num(p_Hud[Hud][R]),get_pcvar_num(p_Hud[Hud][G]),get_pcvar_num(p_Hud[Hud][B]),get_pcvar_float(p_Hud[Hud][X]),get_pcvar_float(p_Hud[Hud][Y]),0,0.0,g_Query[0] ? 999999.9 : 1.0,g_Query[0] ? 0.3 : 0.0,g_Query[0] ? 0.0 : 0.3,-1)
		ShowSyncHudMsg(id,g_HudObjects[Hud],"%s",g_Query[0] ? g_Query : g_LastMsg[id])
	
		copy(g_LastMsg[id],127,g_Query)
	}
	else
	{
		set_hudmessage(get_pcvar_num(p_Hud[Hud][R]),get_pcvar_num(p_Hud[Hud][G]),get_pcvar_num(p_Hud[Hud][B]),get_pcvar_float(p_Hud[Hud][X]),get_pcvar_float(p_Hud[Hud][Y]),0,0.0,999999.9,0.0,0.0,-1)
		ShowSyncHudMsg(id,g_HudObjects[Hud],"%s",g_Query)
	}*/
	
	set_hudmessage(get_pcvar_num(p_Hud[Hud][R]),get_pcvar_num(p_Hud[Hud][G]),get_pcvar_num(p_Hud[Hud][B]),get_pcvar_float(p_Hud[Hud][X]),get_pcvar_float(p_Hud[Hud][Y]),0,0.0,999999.9,0.0,0.0,-1)
	ShowSyncHudMsg(id,g_HudObjects[Hud],"%s",g_Query)
}

/*ClearHud(id,Hud)
{
	for(new Count,CurArray;Count < g_HudNum[id][Hud];Count++)
	{
		CurArray = array_get_int(g_HudArray[id][Hud],Count)
		array_destroy(CurArray)
	}
	
	g_HudNum[id][Hud] = 0
	
	TravTrieClear(g_HudArray[id][Hud])
	
	new travTrieIter:Iter = GetTravTrieIterator(g_HudArray[id]),Channel = -1
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,g_Query,4095)
		ReadTravTrieCell(Iter,Channel)
		
		if(Channel == Hud)
			TravTrieDeleteKey(g_HudArray[id],g_Query)
		
		Channel = -1
	}
	DestroyTravTrieIterator(Iter)
}*/

public ForwardSetClientMaxspeed(id,Float:NewSpeed)
{
	g_MaxSpeed[id] = NewSpeed
	return FMRES_IGNORED
}

public EventDeathMsg()
{
	new id = read_data(2)
	if(get_pcvar_num(p_WalletDeath))
		g_Money[id] = 0
	
	g_Hunger[id] = 0
}

public EventResetHUD(id)
	set_task(1.0,"Welcome",id)

public Welcome(id)
	if(is_user_alive(id))
	{		
		if(!g_Joined[id])
		{
			for(new Count;Count < 3;Count++)
			{
				get_pcvar_string(p_Welcome[Count],g_Query,4095)
				if(g_Query[0])
					client_print(id,print_chat,"[ARP] %s",g_Query)
			}
			
			new Authid[36]
			get_user_authid(id,Authid,35)
			if(containi(Authid,"PENDING") != -1 || containi(Authid,"LAN") != -1 || equali(Authid,"STEAM_0:0"))
				client_print(id,print_chat,"[ARP] Your Steam identification has failed to load. Your user data will not be saved.")
			
			g_Joined[id] = true
		}
		
		if(g_BadJob[id])
		{
			client_print(id,print_chat,"[ARP] Notice: Your job no longer exists. Please contact an administrator.")
			client_print(id,print_chat,"[ARP] You have been temporarily set back to Unemployed.")
			
			g_BadJob[id] = 0
		}
		
		if(g_SqlHandle == Empty_Handle)
		{
			client_print(id,print_chat,"[ARP] The server is currently malfunctioning and will not save any data.")
			client_print(id,print_chat,"[ARP] Please inform the administration of this problem and be patient while they solve it.")
		}
	}
	
public CmdJobList(id)
{
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Start = str_to_num(Arg),Items = get_pcvar_num(p_ItemsPerPage),Num,Access[JOB_ACCESSES + 1],Name[33],Data[2]
	Data[0] = id
	Data[1] = Start
	
	if(_CallEvent("Job_List",Data,2))
		return PLUGIN_HANDLED
	
	if(Start >= g_JobsNum || Start < 0)
	{
		client_print(id,print_console,"No jobs to display at this area.")
		return PLUGIN_HANDLED
	}
	
	client_print(id,print_console,"ARP Jobs List (Starting at #%d)",Start)
	client_print(id,print_console,"NUMBER   JOBID   NAME   SALARY   ACCESS")
	
	for(new Count = Start;Count < Start + Items;Count++)
	{
		if(Count >= g_JobsNum)
			break
		
		if(!UTIL_ARP_ValidJobId(Count))
			continue
		
		ARP_IntToAccess(array_get_int(array_get_int(g_JobsArray,Count),3),Access,JOB_ACCESSES)
		array_get_string(array_get_int(g_JobsArray,Count),1,Name,32)
		
		client_print(id,print_console,"#%d   %d   %s   $%d   %s",++Num,Count + 1,Name,array_get_int(array_get_int(g_JobsArray,Count),2),Access)
	}
	
	if(Start + Items < g_JobsNum)
		client_print(id,print_console,"Type ^"arp_joblist %d^" to view next jobs.",Start + Items)
	
	return PLUGIN_HANDLED
}

public CmdItemList(id)
{
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Start = str_to_num(Arg) + 1,Items = get_pcvar_num(p_ItemsPerPage),Data[2]
	Data[0] = id
	Data[1] = Start
	
	if(_CallEvent("Item_List",Data,2))
		return PLUGIN_HANDLED
	
	if(Start > g_ItemsNum || Start < 1)
	{
		client_print(id,print_console,"No jobs to display at this area.")
		return PLUGIN_HANDLED
	}
	
	client_print(id,print_console,"ARP Items List (Starting at #%d)",Start)
	client_print(id,print_console,"NUMBER   ITEMID   NAME   DISPOSABLE   DESCRIPTION")
	
	new Name[33],Description[64],CurArray
	
	for(new Count = Start;Count < Start + Items;Count++)
	{
		if(Count > g_ItemsNum)
			break
		
		CurArray = array_get_int(g_ItemsArray,Count)
		
		array_get_string(CurArray,1,Name,32)
		array_get_string(CurArray,4,Description,63)
		
		client_print(id,print_console,"#%d   %s   %s   %s",Count,Name,array_get_int(CurArray,5) ? "Yes" : "No",Description)
	}
	
	if(Start + Items <= g_ItemsNum)
		client_print(id,print_console,"Type ^"arp_itemlist %d^" to view next items.",Start + Items - 1)
	
	return PLUGIN_HANDLED
}

ItemUse(id,ItemId,UseUp)
{
	new Handler[33],Plugin = array_get_int(array_get_int(g_ItemsArray,ItemId),2)
	array_get_string(array_get_int(g_ItemsArray,ItemId),3,Handler,32)
	
	new Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_CELL),Return
	if(Forward < 0)
	{
		format(g_Query,4095,"Function ^"%s^" does not exist in plugin %d.",Handler,Plugin)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
	}
	
	if(!ExecuteForward(Forward,Return,id,ItemId))
	{
		format(g_Query,4095,"Function ^"%s^" does not exist in plugin %d.",Handler,Plugin)
		return UTIL_ARP_ThrowError(AMX_ERR_NATIVE,0,g_Query,0)
	}
	
	// if disposable
	if(UseUp && array_get_int(array_get_int(g_ItemsArray,ItemId),5))
		UTIL_ARP_SetUserItemNum(id,ItemId,UTIL_ARP_GetUserItemNum(id,ItemId) - 1)
	
	DestroyForward(Forward)
	
	return SUCCEEDED
}

UTIL_ARP_PropertyChanged(Property)
	array_set_int(array_get_int(g_PropertyArray,Property),9,1)

UTIL_ARP_ValidProperty(Property)
{
	if(Property >= 0 && Property < g_PropertyNum)
		return SUCCEEDED
	
	return FAILED
}

UTIL_ARP_ValidDoor(Door)
{
	if(Door >= 0 && Door < g_DoorNum)
		return SUCCEEDED
	
	return FAILED
}

UTIL_ARP_GetProperty(Targetname[] = "",EntID = 0)
{
	static PropertyTargetname[33],InternalName[64]
	
	for(new Count;Count < g_DoorNum;Count++)
	{
		array_get_string(array_get_int(g_DoorArray,Count),0,PropertyTargetname,32)
		
		if((equali(PropertyTargetname,Targetname) && Targetname[0]) || (EntID && EntID == array_get_int(array_get_int(g_DoorArray,Count),1)))
		{
			array_get_string(array_get_int(g_DoorArray,Count),2,InternalName,63)
			return UTIL_ARP_MatchProperty(InternalName)
		}
	}
	
	return -1
}

UTIL_ARP_GetDoor(Targetname[] = "",EntID = 0)
{
	static PropertyTargetname[33]
	
	for(new Count;Count < g_DoorNum;Count++)
	{
		array_get_string(array_get_int(g_DoorArray,Count),0,PropertyTargetname,32)
		
		if((equali(PropertyTargetname,Targetname) && Targetname[0]) || (EntID && EntID == array_get_int(array_get_int(g_DoorArray,Count),1)))
			return Count
	}
	
	return FAILED
}

UTIL_ARP_MatchProperty(InternalName[])
{
	static CurName[64]
	
	for(new Count;Count < g_PropertyNum;Count++)
	{
		array_get_string(array_get_int(g_PropertyArray,Count),0,CurName,63)
		if(equali(CurName,InternalName))
			return Count
	}
	
	return -1
}

UTIL_ARP_FindItemId(ItemName[])
{
	new Name[33]
	for(new Count = 1;Count <= g_ItemsNum;Count++)
	{
		array_get_string(array_get_int(g_ItemsArray,Count),1,Name,32)
		
		if(equali(Name,ItemName))
			return Count
	}
	
	return -1
}

UTIL_ARP_SetUserItemNum(id,ItemId,Num)
{
	if(UTIL_ARP_ValidItemId(ItemId))
		Num ? array_set_int(g_UserItemArray[id],ItemId,Num) : array_delete(g_UserItemArray[id],ItemId)
	
	if(!Num)
	{		
		new Name[33],Authid[36]
		UTIL_ARP_GetItemName(ItemId,Name,32)
		
		get_user_authid(id,Authid,35)
		
		#if defined DEBUG
		g_TotalQueries++
		#endif
		
		format(g_Query,4095,"DELETE FROM %s WHERE authidname='%s|%s'",g_ItemsTable,Authid,Name)
		UTIL_ARP_CleverQuery(g_Plugin,g_SqlHandle,"IgnoreHandle",g_Query)
	}
	
	return 1
}

UTIL_ARP_GetUserItemNum(id,ItemId)
	return array_isfilled(g_UserItemArray[id],ItemId) ? abs(array_get_int(g_UserItemArray[id],ItemId)) : 0
		

UTIL_ARP_GetItemName(ItemId,ItemName[],Len)
{
	if(!UTIL_ARP_ValidItemId(ItemId))
		return FAILED
	
	array_get_string(array_get_int(g_ItemsArray,ItemId),1,ItemName,Len)
	
	/*new Array
	for(new Count;Count < g_ItemsNum;Count++)
	{
		Array = array_get_int(g_ItemsArray,Count + 1)
		
		if(ItemId == array_get_int(Array,2))
		{
			array_get_string(Array,1,ItemName,Len)
			return SUCCEEDED
		}
	}*/
	
	//return FAILED
	
	return SUCCEEDED
}

UTIL_ARP_ValidItemId(ItemId)
{
	if(ItemId <= g_ItemsNum && ItemId > 0)
		return SUCCEEDED
	
	return FAILED
}

UTIL_ARP_ValidJobId(JobId)
{
	if(JobId < g_JobsNum && JobId >= 0 && array_get_int(g_JobsArray,JobId) != -1)
		return SUCCEEDED
	
	return FAILED
}

UTIL_ARP_ThrowError(Error,Fatal,Message[],Plugin)
{	
	if(Plugin)
	{
		new Name[64],Filename[64],Temp[2]
	
		get_plugin(Plugin,Filename,63,Name,63,Temp,1,Temp,1,Temp,1)
		
		if(Error)
			log_error(Error,"[ARP] [PLUGIN: %s - %s] %s",Name,Filename,Message)
		else
			log_amx("[ARP] [PLUGIN: %s - %s] %s",Name,Filename,Message)
	}
	else
		if(Error)
			log_error(Error,"[ARP] [PLUGIN: CORE] %s",Message)
		else
			log_amx("[ARP] [PLUGIN: CORE] %s",Message)
		
	if(Fatal)
	{
		new Forward = CreateMultiForward("ARP_Error",ET_IGNORE,FP_STRING),Return
		if(Forward < 0 || !ExecuteForward(Forward,Return,Message))
			return SUCCEEDED
		
		DestroyForward(Forward)
		
		pause("d")
	}
	
	return FAILED
}

UTIL_ARP_ClientPrint(id,Message[],{Float,Sql,Result,_}:...)
{
	vformat(g_Query,4095,Message,3)
	
	//if(equali(g_Query,g_LastMsg[id]))
	//	return
	
	new Copy[128]
	copy(Copy[2],125,Message)
	Copy[0] = id
	Copy[1] = HUD_QUAT
	
	switch(get_pcvar_num(p_AuxType))
	{
		case 1 :	
		{
			if(_CallEvent("HUD_AddItem",Copy,128)) return
			client_print(id,print_center,"%s",g_Query)
		}
		case 2 :
		{
			//ClearHud(id,HUD_QUAT)
			TravTrieClear(TravTrie:g_HudArray[id][HUD_QUAT])
			UTIL_ARP_AddHudItem(id,HUD_QUAT,g_Query,!g_HudPending)
		}
	}
}

UTIL_ARP_AddHudItem(id,Channel,Message[],Refresh)
{
	new Copy[128]
	copy(Copy[2],125,Message)
	Copy[0] = id
	Copy[1] = Channel
	
	if(_CallEvent("HUD_AddItem",Copy,128)) return
	
	if(id == -1)
	{
		new Players[32],Playersnum
		get_players(Players,Playersnum)
		for(new Count;Count < Playersnum;Count++)
			AddItem(Players[Count],Channel,Message,Refresh)
	}
	else
		AddItem(id,Channel,Message,Refresh)	
}

AddItem(id,Channel,Message[],Refresh)
{
	//new CurArray = array_create()
	//array_set_int(g_HudArray[id][Channel],g_HudNum[id][Channel]++,CurArray)
	
	//array_set_string(CurArray,0,Message)
	
	TravTrieSetCell(g_HudArray[id][Channel],Message,Channel)
	
	if(Refresh)
		RenderHud(id,Channel)
}

stock bool:fm_is_ent_visible(index, entity) 
{
    new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
    pev(index, pev_origin, origin)
    pev(index, pev_view_ofs, view_ofs)
    xs_vec_add(origin, view_ofs, eyespos)

    new Float:entpos[3]
    pev(entity, pev_origin, entpos)
    engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

    switch (pev(entity, pev_solid)) {
        case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
    }
    
    new Float:fraction
    global_get(glb_trace_fraction, fraction)
    if (fraction == 1.0)
        return true

    return false
}
#include <amxmodx>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <sqlx>

new p_Interval

new Handle:g_Sql

new g_Apply[33]
new g_JobId[33]

new g_Menu[512]

new g_Table[] = "arp_jobapps"

new g_ReviewMenu[] = "ARP_ReviewMenu"
new g_AcceptMenu[] = "ARP_AcceptMenu"

new g_MenuPage[33]

new g_Results

new g_Authid[33][36]

new g_AppModes[][] = 
{
	"PENDING",
	"ACCEPTED",
	"DENIED"
}

public plugin_init()
{	
	p_Interval = register_cvar("arp_application_interval","180")
	
	//ARP_RegisterEvent("Player_Say","CmdSay")
	ARP_AddChat(_,"CmdSay")
	ARP_RegisterChat("/apply","CmdSayApply","- starts application process")
	ARP_RegisterCmd("arp_applications","CmdApplications","(ADMIN) - brings up menu that displays user job apps")
	
	set_task(get_pcvar_float(p_Interval),"Advertise")
	
	register_menucmd(register_menuid(g_ReviewMenu),1023,"ReviewMenuHandle")
	register_menucmd(register_menuid(g_AcceptMenu),1023,"AcceptMenuHandle")
	
	register_event("ResetHUD","EventResetHUD","be")
}

public ARP_Error(const Reason[])
	pause("d")

public client_disconnect(id)
	g_Apply[id] = 0

public ARP_Init()
{
	ARP_RegisterPlugin("In-Game Applications","1.0","Hawk552","Allows users to apply for jobs in-game")
	
	g_Sql = ARP_SqlHandle()
	
	format(g_Menu,511,"CREATE TABLE IF NOT EXISTS %s (authid VARCHAR(36),name VARCHAR(33),jobid INT(11),description TEXT,accepted INT(11))",g_Table)
	SQL_ThreadQuery(g_Sql,"IgnoreHandle",g_Menu)
}

public CmdApplications(id)
{
	g_MenuPage[id] = 0
	Review(id)
}

public Review(id)
{	
	if(!(ARP_GetUserAccess(id) & ACCESS_Z))
	{
		client_print(id,print_console,"You have no access to this command.")
		return PLUGIN_HANDLED
	}
	
	new Data[1]
	Data[0] = id
	
	format(g_Menu,511,"SELECT * FROM %s",g_Table)
	SQL_ThreadQuery(g_Sql,"ReviewHandle",g_Menu,Data,1)
	
	return PLUGIN_HANDLED
}

public ReviewHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)	
	
	g_Results = SQL_NumResults(Query)
	new Num = g_MenuPage[Data[0]] * 7,Name[33],Pos,ItemNum,Keys = (1<<7|1<<8|1<<9)
	
	Pos += format(g_Menu,511,"ARP Application Admin^n^n")
	for(new Count;Count < Num + 7 && SQL_MoreResults(Query);Count++)
	{
		if(Count < Num)
		{
			SQL_NextRow(Query)
			continue
		}
		
		SQL_ReadResult(Query,1,Name,32)
				
		Keys |= (1<<ItemNum)
		
		Pos += format(g_Menu[Pos],511 - Pos,"%d. [%s] %s^n",++ItemNum,g_AppModes[clamp(SQL_ReadResult(Query,4) + 1,0,2)],Name)
		
		SQL_NextRow(Query)
	}
	format(g_Menu[Pos],511 - Pos,"^n8. Last Page^n9. Next Page^n^n0. Exit")
	
	show_menu(Data[0],Keys,g_Menu,-1,g_ReviewMenu)
	
	return PLUGIN_HANDLED
}

public ReviewMenuHandle(id,Key)
{
	if(Key == 9)
		return
	
	if(Key == 8)
	{
		if(g_MenuPage[id] * 7 + 7 < g_Results)
			g_MenuPage[id]++
		
		Review(id)
		
		return
	}
	
	if(Key == 7)
	{
		if(g_MenuPage[id])
			g_MenuPage[id]--
		
		Review(id)
		
		return
	}
	
	new Item = g_MenuPage[id] * 7 + Key,Data[2]
	Data[0] = id
	Data[1] = Item
	
	format(g_Menu,511,"SELECT * FROM %s",g_Table)
	SQL_ThreadQuery(g_Sql,"ReviewMenuHandleAccept",g_Menu,Data,2)
}

public ReviewMenuHandleAccept(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new Item = Data[1],Name[33],JobName[33]
	
	for(new Count,id = Data[0];Count <= Item && SQL_MoreResults(Query);Count++)
		if(Count < Item)
		{
			SQL_NextRow(Query)
			continue
		}
		else
		{
			SQL_ReadResult(Query,0,g_Authid[id],35)
			SQL_ReadResult(Query,1,Name,32)
			ARP_GetJobName(SQL_ReadResult(Query,2),JobName,32)
			SQL_ReadResult(Query,3,g_Menu,511)
			
			client_print(id,print_chat,"[ARP] Description given: %s",g_Menu)
			
			format(g_Menu,511,"ARP Application Admin^n^nName: %s^nJob: %s^n^n1. Accept^n2. Deny^n^n0. Exit",Name,JobName)
			show_menu(id,MENU_KEY_1|MENU_KEY_2|MENU_KEY_0,g_Menu,-1,g_AcceptMenu)
			
			break
		}
	
	return PLUGIN_HANDLED
}

public AcceptMenuHandle(id,Key)
{
	if(Key == 9)
		return
		
	client_print(id,print_chat,"[ARP] Application %s.",Key ? "denied" : "accepted")
	
	format(g_Menu,511,"UPDATE %s SET accepted='%d' WHERE authid='%s'",g_Table,Key,g_Authid[id])
	SQL_ThreadQuery(g_Sql,"IgnoreHandle",g_Menu)
}

public CmdSayApply(id)
{
	new Authid[36],Data[1]
	get_user_authid(id,Authid,35)
	Data[0] = id
	
	format(g_Menu,511,"SELECT * FROM %s WHERE authid='%s'",g_Table,Authid)
	SQL_ThreadQuery(g_Sql,"ApplyHandle",g_Menu,Data,1)
	
	return PLUGIN_HANDLED
}

public ApplyHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new id = Data[0]
		
	if(SQL_NumResults(Query))
	{
		client_print(id,print_chat,"[ARP] You have already submitted an application.")
		return PLUGIN_HANDLED
	}
		
	if(g_Apply[id])
	{
		client_print(id,print_chat,"[ARP] You are already in the application process. If you are trying to cancel it, say ^"cancel^".")
		return PLUGIN_HANDLED
	}
	
	client_print(id,print_chat,"[ARP] You have entered the job application process. Say ^"cancel^" at any time to cancel it.")
	client_print(id,print_chat,"[ARP] Please say (press y and type in, then press enter) what the name of the job you are applying for is.")
	
	g_Apply[id] = 1
	
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

public CmdSay(id,Mode,Arg[])
{
	if(g_Apply[id] == 1)
	{
		new Results[2]
		
		if(equali(Arg,"cancel",6))
		{
			client_print(id,print_chat,"[ARP] Job application cancelled.")
			g_Apply[id] = 0
			return PLUGIN_HANDLED
		}
		
		if(strlen(Arg) < 2)
			return PLUGIN_HANDLED
		
		new Num = ARP_FindJobId(Arg,Results,2)
		
		if(!Num)
		{
			client_print(id,print_chat,"[ARP] Could not find any jobs matching your input.")
			return PLUGIN_HANDLED
		}
		if(Num > 1)
		{
			client_print(id,print_chat,"[ARP] Found more than one result for the job you inputted; please be more specific.")
			return PLUGIN_HANDLED
		}
		
		new Name[33]
		ARP_GetJobName(Results[0],Name,32)
		
		g_JobId[id] = Results[0]
		
		client_print(id,print_chat,"[ARP] You are now applying for a job as a %s.",Name)
		client_print(id,print_chat,"[ARP] Please say why you should have this job, and describe why you would be good at it.")
		
		g_Apply[id] = 2
		
		return PLUGIN_HANDLED
	}
	else if(g_Apply[id] == 2)
	{
		new Args[256]
		read_args(Args,255)
		
		if(strlen(Args) < 2)
			return PLUGIN_HANDLED
			
		remove_quotes(Args)
		trim(Args)
		
		if(equali(Args,"cancel",6))
		{
			client_print(id,print_chat,"[ARP] Job application cancelled.")
			g_Apply[id] = 0
			return PLUGIN_HANDLED
		}
		
		replace_all(Args,255,"^n","")
		replace_all(Args,255,"'","^"")
		
		new Query[512],Authid[36],Name[33]
		get_user_authid(id,Authid,35)
		get_user_name(id,Name,32)
		replace_all(Name,32,"'","\'")
		format(Query,511,"INSERT INTO %s VALUES ('%s','%s','%d','%s','-1')",g_Table,Authid,Name,g_JobId[id],Args)
		
		client_print(id,print_chat,"[ARP] Your application has been submitted. Expect an administrator to review it shortly.")
		
		SQL_ThreadQuery(g_Sql,"IgnoreHandle",Query)
		
		g_Apply[id] = 0
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public Advertise()
{
	new Players[32],Playersnum,Player
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		
		if(!ARP_GetUserJobId(Player))
			client_print(Player,print_chat,"[ARP] Need a job? Say /apply to apply for a job.")
	}
	
	set_task(get_pcvar_float(p_Interval),"Advertise")
}

public EventResetHUD(id)
{
	new Authid[36],Data[1]
	get_user_authid(id,Authid,35)
	Data[0] = id
	
	format(g_Menu,511,"SELECT * FROM %s WHERE authid='%s' AND accepted<>'-1'",g_Table,Authid)
	SQL_ThreadQuery(g_Sql,"FindAppsHandle",g_Menu,Data,1)
}

public FindAppsHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new id = Data[0]
	
	if(!SQL_NumResults(Query))
		return PLUGIN_CONTINUE
	
	new Accepted = SQL_ReadResult(Query,4),JobName[33],JobId = SQL_ReadResult(Query,2)
	ARP_GetJobName(JobId,JobName,32)
	
	// it's reversed, since deny was key 2
	if(Accepted)
		client_print(id,print_chat,"[ARP] Your application to be a %s has been denied.",JobName)
	else
	{
		client_print(id,print_chat,"[ARP] Your application to be a %s has been accepted.",JobName)
		ARP_SetUserJobId(id,JobId)
	}
	
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	format(g_Menu,511,"DELETE FROM %s WHERE authid='%s'",g_Table,Authid)
	
	SQL_ThreadQuery(g_Sql,"IgnoreHandle",g_Menu)
	
	return PLUGIN_CONTINUE
}

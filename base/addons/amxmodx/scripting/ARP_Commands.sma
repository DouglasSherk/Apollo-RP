#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

new g_EmployMenu[] = "ARP_EmployMenu"
new g_FineMenu[] = "ARP_FineMenu"

new g_Finer[33]
new g_Employer[33]
new g_JobID[33]
new g_Amount[33]

public plugin_init()
{	
	//register_clcmd("say","CmdSay")
	//ARP_RegisterEvent("Player_Say","CmdSay")
	ARP_AddChat(_,"CmdSay")
	
	ARP_AddCommand("say /sell","<price> - puts property for sale for price")
	ARP_AddCommand("say /addaccess","<user> - gives user access to the door you're looking at")
	ARP_AddCommand("say /delaccess","<user> - removes user's access from the door you're looking at")
	ARP_AddCommand("say /changename","<name> - changes the name of the property you're looking at")
	ARP_AddCommand("say /givemoney","<amount> - gives money to a user from wallet")
	ARP_AddCommand("say /profit","- takes profit from property")
	
	ARP_RegisterCmd("arp_createmoney","CmdChangeMoney","(ADMIN) <user> <money> - adds money to user's wallet")
	ARP_RegisterCmd("arp_removemoney","CmdChangeMoney","(ADMIN) <user> <money> - removes money from user's wallet")
	ARP_RegisterCmd("arp_setmoney","CmdChangeMoney","(ADMIN) <user> <money> - sets user's wallet money")
	ARP_RegisterCmd("arp_createbank","CmdChangeBank","(ADMIN) <user> <money> - adds money to user's bank")
	ARP_RegisterCmd("arp_removebank","CmdChangeBank","(ADMIN) <user> <money> - removes money from user's bank")
	ARP_RegisterCmd("arp_setbank","CmdChangeBank","(ADMIN) <user> <money> - sets user's bank money")
	ARP_RegisterCmd("arp_createitems","CmdChangeItems","(ADMIN) <user> <item> <amount> - gives items to user")
	ARP_RegisterCmd("arp_removeitems","CmdChangeItems","(ADMIN) <user> <item> <amount> - takes items from user")
	ARP_RegisterCmd("arp_setitems","CmdChangeItems","(ADMIN) <user> <item> <amount> - sets user items")
	ARP_RegisterCmd("arp_setjob","CmdSetJob","(ADMIN) <user> <jobid/jobname> - sets user's job id")
	ARP_RegisterCmd("arp_employ","CmdEmploy","(ADMIN) <user> <jobid/jobname> - offers job to user")
	ARP_RegisterCmd("arp_fire","CmdFire","(ADMIN) <user> - fires user")
	ARP_RegisterCmd("arp_addproperty","CmdAddProperty","(ADMIN) <internalname> <externalname> <owner> <authid> <price> <lock> <access> <profit>")
	ARP_RegisterCmd("arp_setproperty","CmdSetProperty","(ADMIN) <internalname> <externalname> <owner> <authid> <price> <lock> <access> <profit> (use ! to not change)")
	ARP_RegisterCmd("arp_deleteproperty","CmdDeleteProperty","(ADMIN) - deletes property being looked at")
	ARP_RegisterCmd("arp_adddoor","CmdAddDoor","(ADMIN) <internalname> - hooks a door to a property")
	ARP_RegisterCmd("arp_deletedoor","CmdDeleteDoor","(ADMIN) - deletes door being looked at")
	ARP_RegisterCmd("arp_propertyaccess","CmdPropertyAccess","(ADMIN) <access> - sets access level for a property")
	ARP_RegisterCmd("arp_setaccess","CmdSetAccess","(ADMIN) <user> <access> - sets user's access")
	ARP_RegisterCmd("arp_addjob","CmdAddJob","(ADMIN) <name> <salary> <access> - adds job")
	ARP_RegisterCmd("arp_deletejob","CmdDeleteJob","(ADMIN) <name> - deletes a job")
	ARP_RegisterCmd("arp_setjobright","CmdSetJobRight","(ADMIN) <name> <rights> - sets user's job rights")
	
	register_menucmd(register_menuid(g_EmployMenu),MENU_KEY_1|MENU_KEY_2,"EmployHandle")
	register_menucmd(register_menuid(g_FineMenu),MENU_KEY_1|MENU_KEY_2,"FineHandle")
}

public ARP_Init()
	ARP_RegisterPlugin("Commands",ARP_VERSION,"The Apollo RP Team","Helps admins with maintaining the server")

public ARP_Error(const Reason[])
	pause("d")

public CmdFire(id,level,cid)
{
	if(read_argc() != 2)
		return ARP_CmdAccess(id,cid,9999) + 1
	
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Target = cmd_target(id,Arg,1|2),JobIDs[1]
	if(!Target)
		return PLUGIN_HANDLED
	
	new JobID = ARP_GetUserJobId(Target)
	
	if(!ARP_JobAccess(id,JobID) && !ARP_IsJobAdmin(id) && !ARP_IsAdmin(id))
	{
		client_print(id,print_chat,"You have no access to this command.")
		return PLUGIN_HANDLED
	}
	
	if(!ARP_FindJobId("Unemployed",JobIDs,1))
	{
		console_print(id,"Error finding the ^"Unemployed^" job.")
		return PLUGIN_HANDLED
	}
	
	ARP_SetUserJobId(Target,JobIDs[0])
	
	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	show_activity(id,AdminName,"Fire %s",Name)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" fire player ^"%s<%d><%s><>^"",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid)
	
	client_print(id,print_console,"You have fired player %s",Name,Arg)
	
	return PLUGIN_HANDLED
}
	
public CmdSetJobRight(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,3))
		return PLUGIN_HANDLED
	
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Target = cmd_target(id,Arg,1|2)
	if(!Target)
		return PLUGIN_HANDLED
	
	read_argv(2,Arg,32)
	new Access = ARP_AccessToInt(Arg)
	
	ARP_SetUserJobRight(Target,Access)
	
	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	show_activity(id,AdminName,"Set %s's job rights to %s",Name,Arg)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" set player ^"%s<%d><%s><>^" (jobright ^"%s^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Arg)
	
	client_print(id,print_console,"You have set %s's job rights to %s",Name,Arg)
	
	return PLUGIN_HANDLED
}

public CmdAddJob(id,level,cid)
{
	if(!cmd_access(id,level,cid,4))
		return PLUGIN_HANDLED
	
	if(!ARP_IsAdmin(id) && !ARP_IsJobAdmin(id))
	{
		console_print(id,"You do not have access to this command")
		return PLUGIN_HANDLED
	}
	
	new Arg[33],AccessStr[JOB_ACCESSES + 1],Results[1]
	
	read_argv(2,Arg,32)
	new Salary = str_to_num(Arg)
	
	read_argv(3,AccessStr,JOB_ACCESSES)
	new Access = ARP_AccessToInt(AccessStr)
	
	read_argv(1,Arg,32)
	remove_quotes(Arg)
	trim(Arg)
	
	ARP_FindJobId(Arg,Results,1)
	
	if(Results[0])
	{
		new TempName[33]
		ARP_GetJobName(Results[0],TempName,32)
		
		client_print(id,print_console,"A similar job is already taken. You entered: %s - Existing job: %s",Arg,TempName)
		return PLUGIN_HANDLED
	}
	
	if(ARP_AddJob(Arg,Salary,Access))
	{
		client_print(id,print_console,"Job %s added to database with salary $%d/hr and access %s.",Arg,Salary,AccessStr)
		
		new Name[33],Authid[36]
		get_user_name(id,Name,32)
		get_user_authid(id,Authid,35)
		
		show_activity(id,Name,"Add job ^"%s^"",Arg)
		
		ARP_Log("Cmd: ^"%s<%d><%s> add job ^"%s^" (salary ^"$%d/hr^") (access ^"%s^")",Name,get_user_userid(id),Authid,Arg,Salary,AccessStr)
	}
	
	return PLUGIN_HANDLED
}

public CmdDeleteJob(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED
	
	if(!ARP_IsAdmin(id) && !ARP_IsJobAdmin(id))
	{
		console_print(id,"You do not have access to this command")
		return PLUGIN_HANDLED
	}
	
	new Arg[33],Results[1]
	
	read_argv(1,Arg,32)
	remove_quotes(Arg)
	trim(Arg)
	
	ARP_FindJobId(Arg,Results,1)
	if(!Results[0])
	{
		console_print(id,"No job matching your input was found")
		return PLUGIN_HANDLED
	}
	
	new JobName[33],JobId = Results[0]
	ARP_GetJobName(JobId,JobName,32)
	
	new Players[32],Playersnum,Player
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		
		if(ARP_GetUserJobId(Player) == JobId) client_print(Player,print_chat,"[ARP] Your job has been deleted and you have been set back to Unemployed.")
	}
	
	ARP_DeleteJob(JobId)
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	ARP_Log("Cmd: ^"%s<%d><%s> delete job ^"%s^"",Name,get_user_userid(id),Authid,JobName)
	
	show_activity(id,Name,"Delete job ^"%s^"",JobName)
	
	return PLUGIN_HANDLED
}

public CmdSetAccess(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,3))
		return PLUGIN_HANDLED
	
	new Arg[33]
	read_argv(1,Arg,32)
	
	new Target = cmd_target(id,Arg,1|2)
	if(!Target)
		return PLUGIN_HANDLED
	
	read_argv(2,Arg,32)
	new Access = ARP_AccessToInt(Arg)
	
	ARP_SetUserAccess(Target,Access)
	
	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	show_activity(id,AdminName,"Set %s's access to %s",Name,Arg)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" set player ^"%s<%d><%s><>^" (access ^"%s^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Arg)
	
	client_print(id,print_console,"You have set %s's access to %s",Name,Arg)
	
	return PLUGIN_HANDLED
}

public CmdPropertyAccess(id,level,cid)
{
	new Index,Body
	get_user_aiming(id,Index,Body,200)
	
	if(!Index || !is_valid_ent(Index))
	{
		client_print(id,print_chat,"[ARP] You are not looking at a valid door.")
		return PLUGIN_HANDLED
	}
	
	new Classname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	if(containi(Classname,"door") == -1)
	{
		client_print(id,print_chat,"[ARP] You are not looking at a valid door.")
		return PLUGIN_HANDLED
	}
	
	if(read_argc() != 2)
	{
		new Access[JOB_ACCESSES + 1],Targetname[33]
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		ARP_IntToAccess(ARP_PropertyGetAccess(Property),Access,JOB_ACCESSES)
		
		client_print(id,print_console,"This property's access flags are ^"%s^".",Access)
		
		return PLUGIN_HANDLED
	}		
	
	if(!ARP_CmdAccess(id,cid,2))
		return PLUGIN_HANDLED
	
	new Arg[JOB_ACCESSES + 1],Targetname[33]
	read_argv(1,Arg,JOB_ACCESSES)
	
	entity_get_string(Index,EV_SZ_targetname,Targetname,32)
	new Property = ARP_PropertyMatch(Targetname,Index)
	if(!Property)
		return PLUGIN_HANDLED
	
	new Access = ARP_AccessToInt(Arg)
	
	ARP_PropertySetAccess(Property,Access)
	
	//ARP_AddProperty
	
	client_print(id,print_console,"You have set this property's access to ^"%s^".",Arg)
	
	new Name[33],Authid[36],PropertyName[33]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	ARP_PropertyGetExternalName(Property,PropertyName,32)
	
	show_activity(id,Name,"Set property ^"%s^" access to ^"%s^"",PropertyName,Arg)
	
	ARP_Log("Cmd: ^"%s<%d><%s> set property ^"%s^" (access ^"%s^")",Name,get_user_userid(id),Authid,PropertyName,Arg)
	
	return PLUGIN_HANDLED
}

public CmdAddProperty(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,9))
		return PLUGIN_HANDLED
	
	new InternalName[64],ExternalName[64],OwnerName[33],OwnerAuth[36],Price,Locked,AccessStr[JOB_ACCESSES + 1],Access,Profit,Temp[33]
	read_argv(1,InternalName,63)
	if(ARP_ValidPropertyName(InternalName))
	{
		client_print(id,print_console,"Property %s already exists.",InternalName)
		return PLUGIN_HANDLED
	}
	
	read_argv(2,ExternalName,63)
	read_argv(3,OwnerName,32)
	read_argv(4,OwnerAuth,35)
	read_argv(5,Temp,32)
	Price = str_to_num(Temp)
	read_argv(6,Temp,32)
	Locked = str_to_num(Temp)
	read_argv(7,AccessStr,JOB_ACCESSES)
	Access = ARP_AccessToInt(AccessStr)
	read_argv(8,Temp,32)
	Profit = str_to_num(Temp)
	
	remove_quotes(InternalName)
	remove_quotes(ExternalName)
	remove_quotes(OwnerName)
	remove_quotes(OwnerAuth)
	trim(InternalName)
	trim(ExternalName)
	trim(OwnerName)
	trim(OwnerAuth)
	
	ARP_AddProperty(InternalName,ExternalName,OwnerName,OwnerAuth,Price,Locked,Access,Profit)
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	show_activity(id,Name,"Add property ^"%s^"",ExternalName)
	
	ARP_Log("Cmd: ^"%s<%d><%s> add property ^"%s^" (externalname ^"%s^") (ownername ^"%s^") (ownerauth ^"%s^") (price ^"%d^") (locked ^"%s^") (access ^"%s^") (profit ^"$%d^")",Name,get_user_userid(id),Authid,InternalName,ExternalName,OwnerName,OwnerAuth,Price,Locked ? "yes" : "no:",AccessStr,Profit)
	
	return PLUGIN_HANDLED
}

public CmdDeleteProperty(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,1))
		return PLUGIN_HANDLED
	
	new Index,Body
	get_user_aiming(id,Index,Body)
	
	if(!is_valid_ent(Index))
	{
		client_print(id,print_console,"You are not looking at a valid door")
		return PLUGIN_HANDLED
	}
	
	new Classname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	if(!equali(Classname,"func_door") && !equali(Classname,"func_door_rotating"))
	{
		client_print(id,print_console,"You are not looking at a valid door")
		return PLUGIN_HANDLED
	}
	
	new Targetname[33]
	entity_get_string(Index,EV_SZ_targetname,Targetname,32)
	new Property = ARP_PropertyMatch(Targetname,Index)
	if(!ARP_ValidProperty(Property))
	{
		client_print(id,print_console,"You are not looking at a registered property")
		return PLUGIN_HANDLED
	}		
	
	new ExternalName[33]
	ARP_PropertyGetExternalName(Property,ExternalName,32)
	
	ARP_DeleteProperty(Property)
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	show_activity(id,Name,"Delete property ^"%s^"",ExternalName)
	
	ARP_Log("Cmd: ^"%s<%d><%s> delete property ^"%s^" (entid ^"%d^") (targetname ^"%s^")",Name,get_user_userid(id),Authid,ExternalName,Index,Targetname)
	
	return PLUGIN_HANDLED
}

public CmdSetProperty(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,9))
		return PLUGIN_HANDLED
	
	new InternalName[64],ExternalName[64],OwnerName[33],OwnerAuth[36],Price,Locked,AccessStr[JOB_ACCESSES + 1],Access,Profit,Temp[33]
	read_argv(1,InternalName,63)
	if(!ARP_ValidPropertyName(InternalName))
	{
		client_print(id,print_console,"Property ^"%s^" doesn't exist.",InternalName)
		return PLUGIN_HANDLED
	}
	
	new FirstChar[4]
	
	read_argv(2,ExternalName,63)
	read_argv(3,OwnerName,32)
	read_argv(4,OwnerAuth,35)
	read_argv(5,Temp,32)
	FirstChar[0] = Temp[0]
	Price = str_to_num(Temp)
	read_argv(6,Temp,32)
	FirstChar[1] = Temp[0]
	Locked = str_to_num(Temp)
	read_argv(7,AccessStr,JOB_ACCESSES)
	FirstChar[2] = Temp[0]
	Access = ARP_AccessToInt(AccessStr)
	read_argv(8,Temp,32)
	FirstChar[3] = Temp[0]
	Profit = str_to_num(Temp)
	
	remove_quotes(InternalName)
	remove_quotes(ExternalName)
	remove_quotes(OwnerName)
	remove_quotes(OwnerAuth)
	trim(InternalName)
	trim(ExternalName)
	trim(OwnerName)
	trim(OwnerAuth)
	
	new Property = ARP_PropertyMatch(_,_,InternalName)
	if(!ARP_ValidProperty(Property))
		return PLUGIN_HANDLED
	
	new Msg[512],Len,Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	Len = format(Msg,sizeof Msg - 1,"Cmd: ^"%s<%d><%s> set property ^"%s^"",Name,get_user_userid(id),Authid,InternalName)
	
	if(ExternalName[0] != '!')
	{
		ARP_PropertySetExternalName(Property,ExternalName)
		Len += format(Msg,sizeof Msg - Len - 1," (externalname ^"%s^")",ExternalName)
	}
	if(OwnerName[0] != '!')
	{
		ARP_PropertySetOwnerName(Property,OwnerName)
		Len += format(Msg,sizeof Msg - Len - 1," (ownername ^"%s^")",OwnerName)
	}
	if(OwnerAuth[0] != '!')
	{
		ARP_PropertySetOwnerAuth(Property,OwnerAuth)
		Len += format(Msg,sizeof Msg - Len - 1," (ownerauth ^"%s^")",OwnerAuth)
	}
	if(Price >= 0 && FirstChar[0] != '!')
	{
		ARP_PropertySetPrice(Property,Price)
		Len += format(Msg,sizeof Msg - Len - 1," (price ^"$%d^")",Price)
	}
	if(Locked >= 0 || FirstChar[1] != '!')
	{
		ARP_PropertySetLocked(Property,Locked ? 1 : 0)
		Len += format(Msg,sizeof Msg - Len - 1," (locked ^"%s^")",Locked ? "yes" : "no")
	}
	if(Access >= 0 || FirstChar[2] != '!')
	{
		ARP_PropertySetAccess(Property,Access)
		Len += format(Msg,sizeof Msg - Len - 1," (access ^"%s^")",AccessStr)
	}
	if(Profit >= 0 || FirstChar[3] != '!')
	{
		ARP_PropertySetProfit(Property,Profit)
		Len += format(Msg,sizeof Msg - Len - 1," (profit ^"$%d^")",Profit)
	}
	
	show_activity(id,Name,"Set property ^"%s^"",ExternalName)
	ARP_Log("%s",Msg)
	
	return PLUGIN_HANDLED
}

public CmdAddDoor(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,2))
		return PLUGIN_HANDLED
	
	new Index,Body
	get_user_aiming(id,Index,Body,200)
	
	if(!Index || !is_valid_ent(Index))
	{
		client_print(id,print_chat,"[ARP] You are not looking at a valid door.")
		return PLUGIN_HANDLED
	}
	
	new Classname[33],Targetname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	entity_get_string(Index,EV_SZ_targetname,Targetname,32)
	
	if(containi(Classname,"door") == -1)
	{
		client_print(id,print_chat,"[ARP] You are not looking at a valid door.")
		return PLUGIN_HANDLED
	}
	
	if(ARP_ValidDoorName(Targetname,Index))
	{
		client_print(id,print_chat,"[ARP] This property is already in the database.")
		return PLUGIN_HANDLED
	}
	
	new Arg[33]
	read_argv(1,Arg,32)
	
	if(!ARP_ValidPropertyName(Arg))
	{
		client_print(id,print_chat,"Property ^"%s^" does not exist.",Arg)
		return PLUGIN_HANDLED
	}
	
	new Property = ARP_PropertyMatch(_,_,Arg)
	
	ARP_AddDoor(Targetname[1] ? Targetname : "",Targetname[1] ? 0 : Index,Arg)
	
	client_print(id,print_console,"You have added %s to the list of doors.",Targetname)
	
	new Name[33],Authid[36],ExternalName[33]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	ARP_PropertyGetExternalName(Property,ExternalName,32)
	
	show_activity(id,Name,"Add door to property ^"%s^"",ExternalName)
	ARP_Log("Cmd: ^"%s<%d><%s> add door (targetname ^"%s^") (entid ^"%d^") (externalname ^"%s^") (internalname ^"%s^")",Name,get_user_userid(id),Authid,Targetname,Index,ExternalName,Arg)
	
	return PLUGIN_HANDLED
}

public CmdDeleteDoor(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,1))
		return PLUGIN_HANDLED
	
	new Index,Body
	get_user_aiming(id,Index,Body)
	
	if(!is_valid_ent(Index))
	{
		client_print(id,print_console,"You are not looking at a valid door")
		return PLUGIN_HANDLED
	}
	
	new Classname[33]
	entity_get_string(Index,EV_SZ_classname,Classname,32)
	
	if(!equali(Classname,"func_door") && !equali(Classname,"func_door_rotating"))
	{
		client_print(id,print_console,"You are not looking at a valid door")
		return PLUGIN_HANDLED
	}
	
	new Targetname[33]
	entity_get_string(Index,EV_SZ_targetname,Targetname,32)
	new Door = ARP_DoorMatch(Targetname,Index)
	if(!ARP_ValidDoor(Door))
	{
		client_print(id,print_console,"You are not looking at a registered door")
		return PLUGIN_HANDLED
	}		
	
	new ExternalName[33],Property = ARP_PropertyMatch(Targetname,Index)
	ARP_PropertyGetExternalName(Property,ExternalName,32)
	
	ARP_DeleteDoor(Door)
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	show_activity(id,Name,"Delete door attached to ^"%s^"",ExternalName)
	
	ARP_Log("Cmd: ^"%s<%d><%s> delete door attached to ^"%s^" (entid ^"%d^") (targetname ^"%s^")",Name,get_user_userid(id),Authid,ExternalName,Index,Targetname)
	
	return PLUGIN_HANDLED
}

public CmdSay(id,Mode,Args[])
{	
	if(equali(Args,"/sell",5))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new StrPrice[64],Temp[2]
		
		parse(Args,Temp,1,StrPrice,63)
		new Price = str_to_num(StrPrice)
		
		if(Price < 0)
		{
			client_print(id,print_chat,"[ARP] You cannot set a property's price to a negative value.")
			return PLUGIN_HANDLED
		}
		
		if(Price)
			client_print(id,print_chat,"[ARP] You have put this property for sale at $%d.",Price)
		else
			client_print(id,print_chat,"[ARP] You have taken this property down from sale.")
		
		ARP_PropertySetPrice(Property,Price)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/lock",5))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Num = ARP_PropertyGetLocked(Property) ? 0 : 1
		ARP_PropertySetLocked(Property,Num)
		
		client_print(id,print_chat,"[ARP] You have %locked the door.",Num ? "" : "un")
		
		return PLUGIN_HANDLED
	}		
	else if(equali(Args,"/changename",11))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Name[33],Temp[2]		
		parse(Args,Temp,1,Name,32)
		
		remove_quotes(Name)
		trim(Name)
		
		ARP_PropertySetExternalName(Property,Name)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/changeowner",12))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Name[33],Temp[2]		
		parse(Args,Temp,1,Name,32)
		
		remove_quotes(Name)
		trim(Name)
		
		ARP_PropertySetOwnerName(Property,Name)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/givemoney",10))
	{
		new Index,Body
		get_user_aiming(id,Index,Body,200)
		
		if(!Index || !is_user_alive(Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at another player.")
			return PLUGIN_HANDLED
		}
		
		new Temp[33]
		parse(Args,Args,255,Temp,32)
		
		new Amount = str_to_num(Temp)
		if(Amount <= 0)
		{
			client_print(id,print_chat,"[ARP] You did not specify a valid amount.")
			return PLUGIN_HANDLED
		}
		
		new Money = ARP_GetUserWallet(id)
		if(Amount > Money)
		{
			client_print(id,print_chat,"[ARP] You do not have enough money in your wallet.")
			return PLUGIN_HANDLED
		}
		
		ARP_SetUserWallet(id,Money - Amount)
		ARP_SetUserWallet(Index,ARP_GetUserWallet(Index) + Amount)
		
		new Name[33]
		get_user_name(id,Name,32)
		client_print(Index,print_chat,"[ARP] %s has given you $%d.",Name,Amount)
		
		get_user_name(Index,Name,32)
		client_print(id,print_chat,"[ARP] You have given %s $%d.",Name,Amount)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/addaccess",10))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a valid property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Arg[33]
		parse(Args,Args,1,Arg,32)
		
		remove_quotes(Arg)
		trim(Arg)
		
		new Target = cmd_target(id,Arg,0)
		
		if(!is_user_connected(Target))
		{
			client_print(id,print_chat,"[ARP] Could not find a user matching parameters.")
			return PLUGIN_HANDLED
		}
		
		if(Target == id)
		{
			client_print(id,print_chat,"[ARP] You cannot give yourself access to a property you already own.")
			return PLUGIN_HANDLED
		}
		
		ARP_GiveKey(Property,Target)
		
		new Name[33]
		get_user_name(Target,Name,32)
		client_print(id,print_chat,"[ARP] You have given %s access to this property.",Name)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/delaccess",10))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a valid property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Arg[33]
		parse(Args,Args,1,Arg,32)
		
		remove_quotes(Arg)
		trim(Arg)
		
		new Target = cmd_target(id,Arg,0)
		
		if(!is_user_connected(Target))
		{
			client_print(id,print_chat,"[ARP] Could not find a user matching parameters.")
			return PLUGIN_HANDLED
		}
		
		if(Target == id)
		{
			client_print(id,print_chat,"[ARP] You cannot take away access from yourself to a property you already own.")
			return PLUGIN_HANDLED
		}
		
		ARP_TakeKey(Property,Target)
		
		new Name[33]
		get_user_name(Target,Name,32)
		client_print(id,print_chat,"[ARP] You have revoked %s's access to this property.",Name)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/fine",5))
	{
		if(!ARP_IsCop(id))
		{
			client_print(id,print_chat,"[ARP] You have no access to this command.")
			return PLUGIN_HANDLED
		}
		
		new Arg[33],Amount,Index,Body
		get_user_aiming(id,Index,Body,200)
		
		if(!Index || !is_user_alive(Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a valid player.")
			return PLUGIN_HANDLED
		}
		
		parse(Args,Args,1,Arg,32)
		Amount = str_to_num(Arg)
		
		if(Amount < 1)
		{
			client_print(id,print_chat,"[ARP] You must fine a valid amount of money.")
			return PLUGIN_HANDLED
		}
		
		if(Amount > ARP_GetUserBank(Index) + ARP_GetUserWallet(Index))
		{
			client_print(id,print_chat,"[ARP] That user does not have enough money.")
			return PLUGIN_HANDLED
		}
		
		g_Finer[Index] = id
		g_Amount[Index] = Amount
		
		new Tmp[256]
		format(Tmp,255,"ARP Fine Menu^n^nAmount: $%d^n^n1. Pay^n2. Refuse",Amount)
		
		show_menu(Index,(1<<0|1<<1),Tmp,-1,g_FineMenu)
		
		client_print(id,print_chat,"[ARP] You have sent a fine order.")
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/profit",7))
	{
		new Index,Body,Targetname[33]
		get_user_aiming(id,Index,Body,200)
		
		if(!Index)
		{
			client_print(id,print_chat,"[ARP] You are not looking at a valid property.")
			return PLUGIN_HANDLED
		}
		
		entity_get_string(Index,EV_SZ_targetname,Targetname,32)
		if(!ARP_ValidDoorName(Targetname,Index))
		{
			client_print(id,print_chat,"[ARP] You are not looking at a property.")
			return PLUGIN_HANDLED
		}
		
		new Property = ARP_PropertyMatch(Targetname,Index)
		if(!Property)
			return PLUGIN_HANDLED
		
		if(ARP_PropertyGetOwner(Property) != id)
		{
			client_print(id,print_chat,"[ARP] You are not the owner of this property.")
			return PLUGIN_HANDLED
		}
		
		new Profit = ARP_PropertyGetProfit(Property)
		ARP_SetUserWallet(id,ARP_GetUserWallet(id) + Profit)
		ARP_PropertySetProfit(Property,0)
		
		client_print(id,print_chat,"[ARP] You extracted $%d from the property's profit.",Profit)
		
		return PLUGIN_HANDLED
	}
	else if(equali(Args,"/unemploy",9))
	{
		new JobIDs[1]
		if(!ARP_FindJobId("Unemployed",JobIDs,1))
		{
			client_print(id,print_chat,"[ARP] There has been an internal error. Please inform the administrator of this problem.")
			return PLUGIN_HANDLED
		}
		
		if(ARP_GetUserJobId(id) != JobIDs[0])
		{
			ARP_SetUserJobId(id,JobIDs[0])
			client_print(id,print_chat,"[ARP] You have left your job and are now unemployed.")
		}
		else client_print(id,print_chat,"[ARP] You are already unemployed.")
			
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public FineHandle(id,Key)
{
	new Name[33]
	
	if(Key)
	{
		get_user_name(id,Name,32)
		client_print(g_Finer[id],print_chat,"[ARP] %s has refused to pay the fine.",Name)
		
		client_print(id,print_chat,"[ARP] You have refused to pay the fine.")
	}
	else
	{
		new Amount = g_Amount[id],Wallet = ARP_GetUserWallet(id),CashLeft = Wallet - Amount
		if(CashLeft < 0)
		{
			ARP_SetUserWallet(id,0)
			CashLeft = abs(CashLeft)
		}
		else
		{
			ARP_SetUserWallet(id,CashLeft)
			PrintPay(id,g_Finer[id],Name)
			return
		}
		
		new Bank = ARP_GetUserBank(id)
		Bank -= CashLeft
		
		ARP_SetUserBank(id,Bank)
		
		PrintPay(id,g_Finer[id],Name)
	}
}

PrintPay(id,Finer,Name[33])
{
	get_user_name(id,Name,32)
	client_print(Finer,print_chat,"[ARP] %s has paid your fine.",Name)
	
	client_print(id,print_chat,"[ARP] You have paid the fine.")
}

public CmdChangeMoney(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,3))
		return PLUGIN_HANDLED
	
	new Arg[32],Money,Target
	
	read_argv(1,Arg,31)
	Target = cmd_target(id,Arg,3)
	if(!Target)
		return PLUGIN_HANDLED
	
	read_argv(2,Arg,31)
	Money = str_to_num(Arg)
	
	new Name[33],AdminName[33],Wallet = ARP_GetUserWallet(id)
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	read_argv(0,Arg,31)
	switch(Arg[4])
	{
		case 'r':
		{
			ARP_SetUserWallet(Target,Wallet - Money)
			client_print(id,print_console,"You have removed $%d from %s's wallet.",Money,Name)
			
			show_activity(id,AdminName,"Remove $%d from %s's wallet",Money,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" remove wallet money from player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
		
		case 'c':
		{
			ARP_SetUserWallet(Target,Wallet + Money)
			client_print(id,print_console,"You have added $%d to %s's wallet.",Money,Name)
			
			show_activity(id,AdminName,"Add $%d to %s's wallet",Money,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" add wallet money for player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
		
		default:
		{
			ARP_SetUserWallet(Target,Money)
			client_print(id,print_console,"You have set %s's wallet money to $%d.",Name,Money)
			
			show_activity(id,AdminName,"Set %s's wallet money to $%d",Name,Money)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" set wallet money for player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdChangeBank(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,3))
		return PLUGIN_HANDLED
	
	new Arg[32],Money,Target
	
	read_argv(1,Arg,31)
	Target = cmd_target(id,Arg,3)
	if(!Target)
		return PLUGIN_HANDLED
	
	read_argv(2,Arg,31)
	Money = str_to_num(Arg)
	
	new Name[33],AdminName[33],Bank = ARP_GetUserBank(id)
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	read_argv(0,Arg,31)
	switch(Arg[4])
	{
		case 'r':
		{
			ARP_SetUserBank(Target,Bank - Money)
			client_print(id,print_console,"You have removed $%d from %s's bank.",Money,Name)
			
			show_activity(id,AdminName,"Remove $%d from %s's bank account",Money,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" remove bank money from player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
		
		case 'c':
		{
			ARP_SetUserBank(Target,Bank + Money)
			client_print(id,print_console,"You have added $%d to %s's bank.",Money,Name)
			
			show_activity(id,AdminName,"Add $%d to %s's bank account",Money,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" add bank money for player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
		
		default:
		{
			ARP_SetUserBank(Target,Money)
			client_print(id,print_console,"You have set %s's bank money to $%d.",Name,Money)
			
			show_activity(id,AdminName,"Set %s's bank money to $%d",Name,Money)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" set bank money for player ^"%s<%d><%s><>^" (amount ^"$%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,Money)
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdChangeItems(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,4))
		return PLUGIN_HANDLED
	
	new Arg[32],ItemId,Amount,Results[2],Num
	read_argv(2,Arg,31)
	
	is_str_num(Arg) ? (ItemId = str_to_num(Arg)) : (Num = ARP_FindItemId(Arg,Results,2))
	if(Num > 1)
	{
		client_print(id,print_console,"Found more than one item with that name.")
		return PLUGIN_HANDLED
	}
	else if(!ItemId && !Num)
	{
		client_print(id,print_console,"No items with matching name/itemid found.")
		return PLUGIN_HANDLED
	}
	
	if(!ItemId)
		ItemId = Results[0]
	
	read_argv(3,Arg,31)
	Amount = str_to_num(Arg)
	read_argv(1,Arg,31)
	
	new Target = cmd_target(id,Arg,3)
	if(!Target || !ItemId || !ARP_ValidItemId(ItemId))
		return PLUGIN_HANDLED
	
	new Name[33],AdminName[33],OldNum = ARP_GetUserItemNum(Target,ItemId)
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	new ItemName[33]
	ARP_GetItemName(ItemId,ItemName,32)
	
	read_argv(0,Arg,32)
	switch(Arg[4])
	{
		case 'r' :
		{
			ARP_SetUserItemNum(Target,ItemId,OldNum - Amount < 0 ? 0 : OldNum - Amount)
			client_print(id,print_console,"You have removed %d of item ^"%s^" from %s's inventory.",Amount,ItemName,Name)
			
			show_activity(id,AdminName,"Remove %d ^"%s^" from %s's inventory",Amount,ItemName,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" remove inventory item from player ^"%s<%d><%s><>^" (item ^"%s^") (itemid ^"%d^") (amount ^"%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,ItemName,ItemId,Amount)
		}
		case 'c' :
		{
			ARP_SetUserItemNum(Target,ItemId,OldNum + Amount < 0 ? 0 : OldNum + Amount)
			client_print(id,print_console,"You have added %d of item ^"%s^" to %s's inventory.",Amount,ItemName,Name)
			
			show_activity(id,AdminName,"Add %d ^"%s^" to %s's inventory",Amount,ItemName,Name)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" add inventory item for player ^"%s<%d><%s><>^" (item ^"%s^") (itemid ^"%d^") (amount ^"%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,ItemName,ItemId,Amount)
		}
		default :
		{
			ARP_SetUserItemNum(Target,ItemId,Amount < 0 ? 0 : Amount)
			client_print(id,print_console,"You have set %s's inventory quantity of item ^"%s^" to %d.",Name,ItemName,Amount)
			
			show_activity(id,AdminName,"Set %s's inventory of ^"%s^" to %d",Name,ItemName,Amount)
			ARP_Log("Cmd: ^"%s<%d><%s><>^" set inventory item for player ^"%s<%d><%s><>^" (item ^"%s^") (itemid ^"%d^") (amount ^"%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,ItemName,ItemId,Amount)
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdSetJob(id,level,cid)
{	
	if(!ARP_CmdAccess(id,cid,3))
		return PLUGIN_HANDLED
	
	new Arg[33]
	read_argv(2,Arg,32)
	new JobID = str_to_num(Arg),Results[2]
	
	if(!JobID)
	{
		new Num = ARP_FindJobId(Arg,Results,2)
		if(Num > 1)
		{
			client_print(id,print_console,"Found more than one result for your input (%s).",Arg)
			return PLUGIN_HANDLED
		}
		
		JobID = Results[0]
	}
	
	if(!JobID || !ARP_ValidJobId(JobID))
	{
		client_print(id,print_console,"Could not find a job id matching what you said.")
		return PLUGIN_HANDLED
	}
	
	read_argv(1,Arg,32)
	new Target = cmd_target(id,Arg,1|2)
	if(!Target)
		return PLUGIN_HANDLED
	
	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	ARP_SetUserJobId(Target,JobID)
	
	new JobName[33]
	ARP_GetJobName(JobID,JobName,32)
	
	client_print(id,print_console,"You have set %s's job id to %d (%s).",Name,JobID,JobName)
	
	show_activity(id,AdminName,"Set %s's job to %s",Name,JobName)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" set player ^"%s<%d><%s><>^" (job ^"%s^") (jobid ^"%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,JobName,JobID)
	
	return PLUGIN_HANDLED
}	

public CmdEmploy(id,level,cid)
{
	if(read_argc() != 3)
		return ARP_CmdAccess(id,cid,9999) + 1
	
	new Arg[33]
	read_argv(2,Arg,32)
	
	new Results[2],Result
	
	if((Result = ARP_FindJobId(Arg,Results,2)) > 1)
	{
		client_print(id,print_console,"There is more than one job matching your input.")
		return PLUGIN_HANDLED
	}
	
	new JobID = Results[0]
	
	if(!Result)
		JobID = str_to_num(Arg)
	
	if(!JobID || !ARP_ValidJobId(JobID))
	{
		client_print(id,print_console,"Could not find a job id matching what you said.")
		return PLUGIN_HANDLED
	}
	
	if(!ARP_JobAccess(id,JobID) && !ARP_IsJobAdmin(id) && !ARP_IsAdmin(id))
	{
		client_print(id,print_chat,"You have no access to this command.")
		return PLUGIN_HANDLED
	}
	
	read_argv(1,Arg,32)
	new Target = cmd_target(id,Arg,2)
	if(!Target)
		return PLUGIN_HANDLED
	
	new Name[33],AdminName[33]
	get_user_name(Target,Name,32)
	get_user_name(id,AdminName,32)
	
	new Authid[36],AdminAuthid[36]
	get_user_authid(Target,Authid,35)
	get_user_authid(id,AdminAuthid,35)
	
	new Menu[256],Salary = ARP_GetJobSalary(JobID),JobName[33]
	ARP_GetJobName(JobID,JobName,32)
	
	show_activity(id,AdminName,"Offer job ^"%s^" to %s",JobName,Name)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" offer job ^"%s<%d><%s><>^" (job ^"%s^") (jobid ^"%d^")",AdminName,get_user_userid(id),AdminAuthid,Name,get_user_userid(Target),Authid,JobName,JobID)
	
	format(Menu,255,"ARP Employment Offer^n^n%s has offered you^na job:^n^nName: %s^nSalary: $%d/h^n^n1. Accept^n2. Decline",AdminName,JobName,Salary)
	
	g_JobID[Target] = JobID
	g_Employer[Target] = id
	
	show_menu(Target,MENU_KEY_1|MENU_KEY_2,Menu,-1,g_EmployMenu)
	
	return PLUGIN_HANDLED
}

public EmployHandle(id,Key)
{	
	new Name[33],Authid[36],JobName[33]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	ARP_GetJobName(g_JobID[id],JobName,32)
	
	if(!Key)
	{
		client_print(g_Employer[id],print_chat,"[ARP] %s has accepted your job offer.",Name)
		client_print(id,print_chat,"[ARP] You have accepted the job offer.")
		
		ARP_SetUserJobId(id,g_JobID[id])
		
		ARP_Log("Cmd: ^"%s<%d><%s><>^" accept job (job ^"%s^") (jobid ^"%d^")",Name,get_user_userid(id),Authid,JobName,g_JobID[id])
	}
	else
	{
		client_print(g_Employer[id],print_chat,"[ARP] %s has declined your job offer.",Name)
		client_print(id,print_chat,"[ARP] You have declined the job offer.")
		
		ARP_Log("Cmd: ^"%s<%d><%s><>^" refuse job (job ^"%s^") (jobid ^"%d^")",Name,get_user_userid(id),Authid,JobName,g_JobID[id])
	}
}
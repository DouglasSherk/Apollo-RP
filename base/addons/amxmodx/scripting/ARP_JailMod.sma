#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <tsfun>

#define MAX_JAILS 20
#define ITEMS_PER_MENU 6

// Disabled by default because no one likes it
//#define CUFF_ITEM

#define ON_CHECK(%1) if(!get_pcvar_num(p_Mode)) return %1

new Class:g_Class[33]

new p_Reconnect
new p_Death
new p_Mode
new p_Distance
new p_Table

new g_JailNames[MAX_JAILS][33]
new Float:g_JailOrigins[MAX_JAILS][3]
new g_JailCommands[MAX_JAILS][32]
new g_JailNum

new g_Menu[] = "JailModMenu"
new g_Keys

new g_MenuPage[33]

new g_Died[33]

new g_Flag

new Float:g_MaxSpeed[33]

new g_PluginEnd

#if defined CUFF_ITEM
new g_Cuffs
#endif

public plugin_init()
{
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	ARP_RegisterEvent("Player_Cuffed","EventCuffed")
	
	register_event("ResetHUD","EventResetHUD","be")
	register_event("DeathMsg","EventDeathMsg","a")
	
	p_Table = register_cvar("arp_jailmod_table","arp_jailusers")
	
	ARP_RegisterChat("/cuff","SayCuff","(COP) - cuffs the person you are looking at")
}

public ARP_Error(const Reason[])
	pause("d")

#if defined CUFF_ITEM
public ARP_RegisterItems()
	g_Cuffs = ARP_RegisterItem("Cuffs","_Cuffs","Used for cuffing players",0)
#endif

public plugin_end()
	g_PluginEnd = 1

public client_putinserver(id)
{
	// can't possibly be in jail, so just stop now if user has access
	if(!is_user_connected(id) || ARP_IsCop(id) || !get_pcvar_num(p_Reconnect))
		return
	
	ON_CHECK()
	
	new Data[10],Authid[36],Table[33]
	get_user_authid(id,Authid,35)
	
	num_to_str(id,Data,9)
	
	get_pcvar_string(p_Table,Table,32)
	
	ARP_ClassLoad(Authid,"LoadHandle",Data,Table)
}

public LoadHandle(Class:class_id,const class[],data[])
{
	new id = str_to_num(data)
	g_Class[id] = class_id
	
	ARP_ClassSaveHook(class_id,"SaveHandle",data)
	
	if(is_user_alive(id))
		EventResetHUD(id)
}

IsCuffed(id)
	return ARP_ClassGetInt(g_Class[id],"cuff")

IsJailed(id)
	return ARP_ClassGetInt(g_Class[id],"jail")
	
#if defined CUFF_ITEM
public _Cuffs(id,ItemId)
	SayCuff(id,0,"")
#endif

public SayCuff(id,Mode,Args[])
{
	if(!is_user_alive(id))
	{
		client_print(id,print_chat,"[ARP] You must be alive to cuff.")
		return PLUGIN_HANDLED
	}
	
	if(!ARP_IsCop(id))
	{
		client_print(id,print_chat,"[ARP] You are not a cop.")
		return PLUGIN_HANDLED
	}
	
	new Index,Body
	get_user_aiming(id,Index,Body,200)
	
	if(!Index || !is_user_alive(Index))
		return PLUGIN_HANDLED
	
	if(ARP_IsCop(Index))
	{
		client_print(id,print_chat,"[ARP] You cannot cuff other cops.")
		return PLUGIN_HANDLED
	}
	
	new Data[3]
	Data[0] = Index
	Data[1] = id
	Data[2] = !IsCuffed(Index)
	
	g_Flag = 1
	
	if(ARP_CallEvent("Player_Cuffed",Data,3))
		return PLUGIN_HANDLED
	
	g_Flag = 0
	
	EventCuffed("",Data,3)
	
	return PLUGIN_HANDLED
}

public EventCuffed(Name[],Data[],Len)
{
	if(g_Flag)
		return PLUGIN_CONTINUE
	
	new Index = Data[0],id = Data[1],Cuffed = Data[2]
	
	if(!Cuffed)
	{
		entity_set_float(Index,EV_FL_maxspeed,g_MaxSpeed[Index])
		g_MaxSpeed[Index] = 0.0
		
		set_rendering(Index,kRenderFxNone,255,255,255,kRenderNormal,16)
		
		ARP_ClassSetInt(g_Class[Index],"cuff",0)
		
		if(id)
		{
			new Name[33],CufferName[33]
			get_user_name(id,CufferName,32)
			client_print(Index,print_chat,"[ARP] You have been uncuffed by %s.",CufferName)
			get_user_name(Index,Name,32)
			client_print(id,print_chat,"[ARP] You have uncuffed %s.",Name)
			
			#if defined CUFF_ITEM
			ARP_SetUserItemNum(id,g_Cuffs,ARP_GetUserItemNum(id,g_Cuffs) + 1)
			#endif
			
			new Authid[36],CufferAuthid[36]
			get_user_authid(Index,Authid,35)
			get_user_authid(id,CufferAuthid,35)
			
			ARP_Log("Cuff: ^"%s<%d><%s><> uncuffed player ^"%s<%d><%s><>^"",CufferName,get_user_userid(id),CufferAuthid,Name,get_user_userid(Index),Authid)
		}
		
		ARP_ItemDone(Index)
		
		return PLUGIN_HANDLED
	}
	
	#if defined CUFF_ITEM
	if(!ARP_GetUserItemNum(id,g_Cuffs))
	{
		client_print(id,print_chat,"[ARP] You do not have any cuffs in your inventory.")
		return PLUGIN_HANDLED
	}
	#endif
	
	for(new Count = 1;Count <= 35;Count++)
		client_cmd(Index,"weapon_%d;drop",Count)
	
	ARP_ClassSetInt(g_Class[Index],"cuff",1)
	
	set_rendering(Index,kRenderFxGlowShell,255,0,0,kRenderNormal,16)
	
	g_MaxSpeed[Index] = entity_get_float(Index,EV_FL_maxspeed)
	
	if(id)
	{
		new Name[33],CufferName[33]
		get_user_name(id,CufferName,32)
		client_print(Index,print_chat,"[ARP] You have been cuffed by %s.",CufferName)
		get_user_name(Index,Name,32)
		client_print(id,print_chat,"[ARP] You have cuffed %s.",Name)
		
		#if defined CUFF_ITEM
		ARP_SetUserItemNum(id,g_Cuffs,ARP_GetUserItemNum(id,g_Cuffs) - 1)
		#endif
		
		new Authid[36],CufferAuthid[36]
		get_user_authid(Index,Authid,35)
		get_user_authid(id,CufferAuthid,35)
		
		ARP_Log("Cuff: ^"%s<%d><%s><> cuffed player ^"%s<%d><%s><>^"",CufferName,get_user_userid(id),CufferAuthid,Name,get_user_userid(Index),Authid)
	}
	
	ARP_ItemSet(Index)
	
	return PLUGIN_HANDLED
}

public EventHudRender(Name[],Data[],Len)
{	
	new id = Data[0]
	if(!is_user_alive(id) || Data[1] != HUD_PRIM)
		return
	
	new Mode = get_pcvar_num(p_Mode)
	if(g_Class[id] && (Mode == 1 && Proximity(id)) || (Mode == 2 && IsJailed(id)))
		ARP_AddHudItem(id,HUD_PRIM,0,"Jailed: No Salary")
	
	if(g_MaxSpeed[id])
		ARP_AddHudItem(id,HUD_PRIM,0,"Cuffed")
}

public ARP_Salary(id)
{
	new Mode = get_pcvar_num(p_Mode)
	if(g_Class[id] && (Mode == 1 && Proximity(id)) || (Mode == 2 && IsJailed(id)) || g_MaxSpeed[id])
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public client_PreThink(id)
	if(g_MaxSpeed[id] && is_user_alive(id))
	{
		entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id] / 2)
		
		// thanks to harbu for this part, although it's pretty easy to replicate
		new bufferstop = entity_get_int(id,EV_INT_button)

		if(bufferstop != 0)
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK & ~IN_ATTACK2 & ~IN_ALT1 & ~IN_USE)

		if((bufferstop & IN_JUMP) && (entity_get_int(id,EV_INT_flags) & ~FL_ONGROUND & ~FL_DUCKING))
			entity_set_int(id,EV_INT_button,entity_get_int(id,EV_INT_button) & ~IN_JUMP)
		
		static Temp
		if(ts_getuserwpn(id,Temp,Temp,Temp,Temp) != TSW_KUNG_FU)
			engclient_cmd(id,"drop")
	}
	
public ARP_Init()
{	
	ARP_RegisterPlugin("Jail Mod",ARP_VERSION,"The Apollo RP Team","Allows cops to jail players and provides cuffing")
	
	register_clcmd("jailmodmenu","CmdJailMod")
	register_clcmd("jail","JailCommand")
	
	p_Reconnect = register_cvar("arp_jail_reconnect","1")
	p_Death = register_cvar("arp_jail_death","1")
	p_Mode = register_cvar("arp_jail_mode","1")
	p_Distance = register_cvar("arp_jail_distance","90.0")
	
	for(new Count;Count < 10;Count++)
		g_Keys += (1<<Count)
	
	new File = ARP_FileOpen("jailmod.ini","r")
	if(!File)
		return set_fail_state("Could not open jail file")
		
	new Buffer[128],Left[33],Right[33],Origins[3][11]
	while(!feof(File) && g_JailNum < MAX_JAILS)
	{
		fgets(File,Buffer,127)		
		if(Buffer[0] == ';')
			continue
			
		if(containi(Buffer,"[") != -1 && containi(Buffer,"]") != -1)
		{
			replace(Buffer,127,"[","")
			replace(Buffer,127,"]","")
			
			remove_quotes(Buffer)
			trim(Buffer)
			
			copy(g_JailNames[++g_JailNum],32,Buffer)
		}
		else if(containi(Buffer,"origin") != -1)
		{
			parse(Buffer,Left,32,Right,32)
			remove_quotes(Right)
			trim(Right)
			
			parse(Right,Origins[0],10,Origins[1],10,Origins[2],10)
			for(new Count;Count < 3;Count++)
				g_JailOrigins[g_JailNum][Count] = str_to_float(Origins[Count])
		}
		else if(containi(Buffer,"command") != -1)
		{
			parse(Buffer,Left,32,Right,32)
			remove_quotes(Right)
			trim(Right)
			
			copy(g_JailCommands[g_JailNum],32,Right)
		}
	}	
	
	fclose(File)
	
	register_menucmd(register_menuid(g_Menu),g_Keys,"MenuHandle")
	
	return PLUGIN_CONTINUE
}

public EventDeathMsg()
{	
	ON_CHECK()
	
	new id = read_data(2)
	if(!is_user_connected(id))
		return
	
	g_Died[id] = 0
	g_MaxSpeed[id] = 0.0
	
	ARP_ClassSetInt(g_Class[id],"cuff",0)
	
	if(get_pcvar_num(p_Death))
		ARP_ClassSetInt(g_Class[id],"jail",0)
	
	if(get_pcvar_num(p_Mode) == 1)
		ARP_ClassSetInt(g_Class[id],"jail",Proximity(id))
}

public JailCommand(id)
{
	if(!ARP_IsCop(id) || !get_pcvar_num(p_Mode))
		return PLUGIN_HANDLED
		
	new Arg[33],Num,List[MAX_JAILS],Index,Body
	read_argv(1,Arg,32)
	
	get_user_aiming(id,Index,Body,200)
	if(!Index || !is_user_alive(Index))
		return PLUGIN_HANDLED
	
	for(new Count = 1;Count <= g_JailNum;Count++)
	{
		if(equali(Arg,g_JailCommands[Count]))
		{
			for(new Count2;Count2 < g_JailNum;Count2++)
				if(equali(g_JailCommands[Count],g_JailCommands[Count2]))
					List[Num++] = Count2
			
			Count = List[random_num(0,Num - 1)]
			
			PutInJail(id,Index,Count - 1)
			
			break
		}
	}
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{	
	g_MenuPage[id] = 0
	g_Died[id] = 0
	g_MaxSpeed[id] = 0.0
	
	if(!g_Class[id]) log_amx("No class found")
	ARP_ClassSave(g_Class[id],1)
}

public SaveHandle(Class:ClassId,Name[],Data[])
{
	if(g_PluginEnd)
		return
	
	new id = str_to_num(Data)
	if(is_user_alive(id) && get_pcvar_num(p_Mode) == 1)
	{
		new Prox = Proximity(id)
		//Prox ? ARP_ClassSetInt(ClassId,"jail",Prox) : ARP_ClassDeleteKey(ClassId,"jail")
		ARP_ClassSetInt(ClassId,"jail",Prox)
	}
}

public EventResetHUD(id)
{	
	if(!g_Class[id] || !is_user_alive(id) || !is_user_connected(id))
		return
	
	new Jail = IsJailed(id),Cuffed = IsCuffed(id)
	if(Jail)
	{
		// get back in jail
		entity_set_origin(id,g_JailOrigins[Jail])
		
		client_print(id,print_chat,"[ARP] You are in jail.")
	}
	if(Cuffed)
	{
		new Data[3]
		Data[0] = id
		Data[2] = 1
		EventCuffed("",Data,3)
	}
}

public CmdJailMod(id)
{
	if(!ARP_IsCop(id))
		return client_print(id,print_chat,"[ARP] You don't have access to this command.")
	
	ON_CHECK(PLUGIN_CONTINUE)
		
	static Menu[512]
	new Pos,Num,Keys = (1<<7|1<<8|1<<9),Mode = get_pcvar_num(p_Mode)
	
	Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"Jail Mod^n^n")
	for(new Count = g_MenuPage[id] * ITEMS_PER_MENU + 1;Count <= g_MenuPage[id] * ITEMS_PER_MENU + ITEMS_PER_MENU;Count++)
		if(g_JailNames[Count][0] && Count <= g_JailNum)
		{
			Keys |= (1<<Num)
			Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"%d. %s^n",++Num,g_JailNames[Count])
		}
		
	if(Mode == 2)
		Keys |= (1<<6)
		
	Pos += format(Menu[Pos],sizeof Menu - Pos - 1,"%s^n^n8. Last Page^n9. Next Page^n^n0. Exit",Mode == 2 ? "^n7. Free Target Player" : "")
	
	show_menu(id,Keys,Menu,-1,g_Menu)
	
	return PLUGIN_HANDLED
}
	
public MenuHandle(id,Key)
	switch(Key)
	{
		case 6 :
		{
			new Index,Body
			get_user_aiming(id,Index,Body,500)
			
			if(!Index || !is_user_alive(Index))
				return
			
			FreePlayer(id,Index)
		}
		case 7 :
		{
			if(g_MenuPage[id])
				g_MenuPage[id]--
			
			CmdJailMod(id)
		}
		case 8 :
		{
			if((g_MenuPage[id] + 1) * ITEMS_PER_MENU + ITEMS_PER_MENU < g_JailNum)
				g_MenuPage[id]++
			
			CmdJailMod(id)
		}
		case 9 :
			return
		default :
		{
			new RealKey = g_MenuPage[id] * ITEMS_PER_MENU + Key + 1
			
			if(RealKey > MAX_JAILS)
			{
				CmdJailMod(id)
				return 
			}
			
			new Index,Body
			get_user_aiming(id,Index,Body,500)
			
			if(!Index || !is_user_alive(Index))
				return
			
			PutInJail(id,Index,RealKey)
		}
	}

PutInJail(id,Index,Num)
{
	new Data[3]
	Data[0] = id
	Data[1] = Index
	if(ARP_CallEvent("Player_Jail",Data,2))
		return
	
	entity_set_origin(Index,g_JailOrigins[Num])

	new Name[33],JailerName[33]
	get_user_name(Index,Name,32)
	client_print(id,print_chat,"[ARP] You have sent %s to %s.",Name,g_JailNames[Num])
	get_user_name(id,JailerName,32)
	client_print(Index,print_chat,"[ARP] You have been sent to %s by %s.",g_JailNames[Num],JailerName)
	
	new Authid[36],JailerAuthid[36]
	get_user_authid(id,Authid,35)
	get_user_authid(Index,JailerAuthid,35)
		
	ARP_Log("Jail: ^"%s<%d><%s><> jailed player ^"%s<%d><%s><>^"",JailerName,get_user_userid(id),JailerAuthid,Name,get_user_userid(Index),Authid)
	
	ARP_ClassSetInt(g_Class[Index],"jail",Num)
}
			
FreePlayer(id,Index)
{
	if(!IsJailed(Index) || !get_pcvar_num(p_Reconnect))
		return PLUGIN_CONTINUE
	
	new Name[33],JailerName[33]
	get_user_name(Index,Name,32)
	client_print(id,print_chat,"[ARP] You have freed %s from jail.",Name)
	get_user_name(id,JailerName,32)
	client_print(Index,print_chat,"[ARP] You have been freed from jail by %s.",JailerName)
	
	new Authid[36],JailerAuthid[36]
	get_user_authid(id,Authid,35)
	get_user_authid(Index,JailerAuthid,35)
		
	ARP_Log("Jail: ^"%s<%d><%s><> freed player ^"%s<%d><%s><>^"",JailerName,get_user_userid(id),JailerAuthid,Name,get_user_userid(Index),Authid)
	
	ARP_ClassSetInt(g_Class[Index],"jail",0)
	
	return PLUGIN_HANDLED
}

Proximity(id)
{	
	new Float:Origin[3]
	entity_get_vector(id,EV_VEC_origin,Origin)
	
	for(new Count = 1;Count <= g_JailNum;Count++)
		if(vector_distance(Origin,g_JailOrigins[Count]) < get_pcvar_float(p_Distance))
			return Count
		
	return 0
}

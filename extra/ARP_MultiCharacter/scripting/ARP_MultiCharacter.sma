#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

new Class:g_Characters[33]

new g_CharSettings[4096]

new g_CreatingCharacter[33]

new g_Switch[33]
new g_Force[33]
new g_Character[36][33]
new g_BankMoney[33]
new g_WalletMoney[33]
new g_JobId[33]
new g_Hunger[33]
new g_Access[33]
new g_JobRight[33]

new p_EnforceName
new p_MaxCharacters

public plugin_init()
{
	ARP_RegisterCmd("say /characters","CmdCharacters"," - allows you to switch between characters")
	
	ARP_AddChat(_,"CmdSay")
	
	register_event("ResetHUD","EventResetHUD","b")
	
	p_EnforceName = register_cvar("arp_character_enforcename","0")
	p_MaxCharacters = register_cvar("arp_character_max","5")
	
	ARP_RegisterEvent("Menu_Display","EventClientMenu")
	ARP_RegisterEvent("Player_Save","EventPlayerSave")
}

public ARP_Init()
	ARP_RegisterPlugin("Multiple Characters","1.0","Hawk552","Extends users to have multiple accounts")

public client_infochanged(id)
{
	if(!is_user_alive(id) || !get_pcvar_num(p_EnforceName) || !g_Characters[id])
		return PLUGIN_CONTINUE
	
	new Name[33],CurCharacter[33]
	get_user_info(id,"name",Name,32)
	ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
	
	if(!equali(Name,CurCharacter))
	{
		client_cmd(id,"name ^"%s^"",CurCharacter)
		//set_user_info(id,"name",CurCharacter)
		client_print(id,print_chat,"[ARP] You must use the same name as your character.")
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public EventResetHUD(id)
	set_task(0.5,"SetCharacter",id)

public SetCharacter(id)
{
	if((!is_user_alive(id) || !g_Switch[id]) && !g_Force[id])
		return
	
	g_Switch[id] = 0
	
	new CurCharacter[33]
	ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
	
	new Name[33],BankMoney = ARP_GetUserBank(id),Wallet = ARP_GetUserWallet(id),Job = ARP_GetUserJobId(id),JobName[33],Hunger = ARP_GetUserHunger(id),Access = ARP_GetUserAccess(id),AccessStr[JOB_ACCESSES + 1],JobRight = ARP_GetUserJobRight(id),JobRightStr[JOB_ACCESSES + 1]
	get_user_name(id,Name,32)
	ARP_GetJobName(Job,JobName,32)
	ARP_IntToAccess(Access,AccessStr,JOB_ACCESSES)
	ARP_IntToAccess(JobRight,JobRightStr,JOB_ACCESSES)
	
	format(g_CharSettings,4095,"%d|%d|%s|%d|%s|%s",BankMoney,Wallet,JobName,Hunger,AccessStr,JobRightStr)
	
	ARP_ClassSetString(g_Characters[id],CurCharacter,g_CharSettings)
	
	ARP_SetUserBank(id,g_BankMoney[id])
	ARP_SetUserWallet(id,g_WalletMoney[id])
	ARP_SetUserJobId(id,g_JobId[id])
	ARP_SetUserHunger(id,g_Hunger[id])
	ARP_SetUserAccess(id,g_Access[id])
	ARP_SetUserJobRight(id,g_JobRight[id])
	
	ARP_ClassSetString(g_Characters[id],"current_character",g_Character[id])
	
	if(!g_Force[id])
	{
		client_print(id,print_chat,"[ARP] You are now %s.",g_Character[id])
		
		if(get_pcvar_num(p_EnforceName))
			client_cmd(id,"name ^"%s^"",g_Character[id])
	}
}

public CmdSay(id,Mode,Args[])
{
	if(!g_CreatingCharacter[id] || !strlen(Args))
		return PLUGIN_CONTINUE
	
	if(equali(Args,"cancel"))
	{
		g_CreatingCharacter[id] = 0
		client_print(id,print_chat,"[ARP] You have cancelled the character creation process.")
		
		return PLUGIN_HANDLED
	}
	
	CreateCharacter(id,Args)
	client_print(id,print_chat,"[ARP] You have created a new character named ^"%s^".",Args)
	
	CmdCharacters(id)
	
	g_CreatingCharacter[id] = 0
	
	return PLUGIN_HANDLED
}

public CmdCharacters(id)
{
	new ClassIter:Iter = ARP_ClassGetIterator(g_Characters[id]),Name[36],Menu = menu_create("Character Menu","CharacterMenuHandle"),CurCharacter[33]
	menu_additem(Menu,"Create New Character","")
	menu_addblank(Menu,0)
	
	ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
	
	while(ARP_ClassMoreData(Iter))
	{
		ARP_ClassReadKey(Iter,Name,35)
		if(equali(Name,CurCharacter))
			format(Name,35,"[*] %s",Name)
		ARP_ClassReadString(Iter,g_CharSettings,4095)
		
		if(!equali(Name,"current_character"))
			menu_additem(Menu,Name,g_CharSettings)
	}
	ARP_ClassDestroyIterator(Iter)
	
	menu_display(id,Menu,0)
	
	return PLUGIN_HANDLED
}

public CharacterMenuHandle(id,Menu,Item)
{	
	if(Item == MENU_EXIT)
		return
	
	if(Item == 0)
	{
		new CharNum = get_pcvar_num(p_MaxCharacters)
		if(ARP_ClassSize(g_Characters[id]) - 1 >= CharNum && CharNum > 0)
		{
			client_print(id,print_chat,"[ARP] The limit for characters on this server is %d.",CharNum)
			return
		}
		
		g_CreatingCharacter[id] = 1
		client_print(id,print_chat,"[ARP] Please type in chat what you want the name of your new character to be. Say ^"cancel^" to cancel this process.")
		
		return
	}
	
	new Garbage,Strings[6][33],JobIds[1]
	menu_item_getinfo(Menu,Item,Garbage,g_CharSettings,4095,g_Character[id],35,Garbage)
	replace(g_Character[id],32,"[*] ","")
	
	for(new Count;Count < 6;Count++)
		strtok(g_CharSettings,Strings[Count],32,g_CharSettings,4095,'|')
	
	g_BankMoney[id] = str_to_num(Strings[0])
	g_WalletMoney[id] = str_to_num(Strings[1])
	ARP_FindJobId(Strings[2],JobIds,1)
	g_JobId[id] = JobIds[0]
	g_Hunger[id] = str_to_num(Strings[3])
	g_Access[id] = ARP_AccessToInt(Strings[4])
	g_JobRight[id] = ARP_AccessToInt(Strings[5])
	
	menu_destroy(Menu)
	
	Menu = menu_create(g_Character[id],"CharacterManageMenuHandle")
	menu_additem(Menu,"Switch Character","")
	menu_additem(Menu,"View Character Stats","")
	menu_additem(Menu,"Delete Character","")
	menu_display(id,Menu,0)
}

public CharacterManageMenuHandle(id,Menu,Item)
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT)
		return
	
	switch(Item)
	{
		case 0 :
		{
			new CurCharacter[33]
			ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
			
			if(equali(g_Character[id],CurCharacter))
			{
				client_print(id,print_chat,"[ARP] You are already using this character.")
				return
			}
			
			g_Switch[id] = 1
			client_print(id,print_chat,"[ARP] You will become %s the next time you spawn.",g_Character[id])
		}
		case 1 :
		{
			new Menu = menu_create("Character Stats","StatsMenuHandle"),Temp[128],CurCharacter[33],IsCurChar
			ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
			
			if(equali(CurCharacter,g_Character[id]))
				IsCurChar = 1
			
			format(Temp,127,"Name: %s",g_Character[id])
			menu_additem(Menu,Temp,"")
			
			format(Temp,127,"Bank Money: $%d",IsCurChar ? ARP_GetUserBank(id) : g_BankMoney[id])
			menu_additem(Menu,Temp,"")
			
			format(Temp,127,"Wallet Money: $%d",IsCurChar ? ARP_GetUserWallet(id) : g_WalletMoney[id])
			menu_additem(Menu,Temp,"")
			
			new Job[33]
			ARP_GetJobName(IsCurChar ? ARP_GetUserJobId(id) : g_JobId[id],Job,32)
			format(Temp,127,"Job: %s",Job)
			menu_additem(Menu,Temp,"")
			
			if(get_cvar_num("arp_hunger_enabled"))
			{
				format(Temp,127,"Hunger: %d%%",IsCurChar ? ARP_GetUserHunger(id) : g_Hunger[id])
				menu_additem(Menu,Temp,"")
			}
			
			ARP_IntToAccess(IsCurChar ? ARP_GetUserAccess(id) : g_Access[id],Job,32)
			format(Temp,127,"Access: %s",Job)
			menu_additem(Menu,Temp,"")
			
			ARP_IntToAccess(IsCurChar ? ARP_GetUserJobRight(id) : g_JobRight[id],Job,32)
			format(Temp,127,"Job Rights: %s",Job)
			menu_additem(Menu,Temp,"")
			
			menu_display(id,Menu,0)
		}
		case 2 :
		{
			new Name[33]
			ARP_ClassGetString(g_Characters[id],"current_character",Name,32)
			
			if(equali(Name,g_Character[id]))
			{
				client_print(id,print_chat,"[ARP] You cannot delete a character while they are in use.")
				return
			}
			
			ARP_ClassDeleteKey(g_Characters[id],g_Character[id])
			
			client_print(id,print_chat,"[ARP] You have deleted %s.",g_Character[id])
		}
	}
}

public StatsMenuHandle(id,Menu,Item)
	if(Item == 7)
		CmdCharacters(id)

CreateCharacter(id,Name[])
{
	new Authid[36]
	get_user_authid(id,Authid,35)
		
	format(g_CharSettings,4095,"0|0|Unemployed|0||")
		
	ARP_ClassSetString(g_Characters[id],Name,g_CharSettings)
}

public EventClientMenu(Name[],Data[],Len)
	ARP_AddMenuItem(Data[0],"Manage Characters","CmdCharacters")

public client_putinserver(id)
{
	static Authid[36],Class[64],Data[10]
	get_user_authid(id,Authid,35)
	
	format(Class,63,"Characters_%s",Authid)
	
	num_to_str(id,Data,9)
	
	ARP_ClassLoad(Class,"CharacterLoad",Data)
}

public EventPlayerSave(Name[],Data[],Len)
{
	new id = Data[0]
	if(Data[1] != 1)
		return
	
	if(g_Characters[id])
		ARP_ClassSave(g_Characters[id],1)
	
	g_Characters[id] = Class:0
	g_Switch[id] = 0
}

public CharacterSave(Class:class_id,const class[],data[])
{
	new id = str_to_num(data)
	
	if(g_Switch[id])
	{
		g_Force[id] = 1
		SetCharacter(id)
	}
}

public CharacterLoad(Class:class_id,const class[],data[])
{
	new id = str_to_num(data)
	g_Characters[id] = class_id
	
	ARP_ClassSaveHook(class_id,"CharacterSave",data)
	
	if(ARP_ClassSize(class_id) < 2)
	{
		new Name[33],BankMoney = ARP_GetUserBank(id),Wallet = ARP_GetUserWallet(id),Job = ARP_GetUserJobId(id),JobName[33],Hunger = ARP_GetUserHunger(id),Access = ARP_GetUserAccess(id),AccessStr[JOB_ACCESSES + 1],JobRight = ARP_GetUserJobRight(id),JobRightStr[JOB_ACCESSES + 1]
		get_user_name(id,Name,32)
		ARP_GetJobName(Job,JobName,32)
		ARP_IntToAccess(Access,AccessStr,JOB_ACCESSES)
		ARP_IntToAccess(JobRight,JobRightStr,JOB_ACCESSES)
		
		format(g_CharSettings,4095,"%d|%d|%s|%d|%s|%s",BankMoney,Wallet,JobName,Hunger,AccessStr,JobRightStr)
		
		ARP_ClassSetString(g_Characters[id],Name,g_CharSettings)
		ARP_ClassSetString(g_Characters[id],"current_character",Name)
	}
	else if(get_pcvar_num(p_EnforceName))
	{
		new CurCharacter[33]
		ARP_ClassGetString(g_Characters[id],"current_character",CurCharacter,32)
		
		client_cmd(id,"name ^"%s^"",CurCharacter)
	}
}
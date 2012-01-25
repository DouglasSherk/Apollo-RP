#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <time>

new Class:g_Class

new g_Mode[33]

new const g_Tag[] = "details_"

new p_SaveInterval
new p_KeepTime

// Quite a bit of memory, but worth the simplification and CPU usage you get back
new g_Title[33][64]

public ARP_Init()
{
	ARP_RegisterPlugin("hawkslist","1.0","Hawk552","Allows players to trade more easily")
	
	ARP_AddChat(_,"CmdSay")
	
	ARP_RegisterChat("/hawkslist","CmdHawksList","Brings up trading menu")
	
	ARP_RegisterEvent("Menu_Display","EventMenuDisplay")
	
	register_dictionary("time.txt")
	
	// Two days by default
	p_KeepTime = register_cvar("arp_hawkslist_keep","172800")
	p_SaveInterval = register_cvar("arp_save_interval","30")
	
	set_task(get_pcvar_float(p_SaveInterval),"SaveData")
	
	set_task(0.5,"LoadData")
}

public LoadData()
	ARP_ClassLoad("listings","HawksListLoadHandle","blah","arp_hawkslist")

public EventMenuDisplay(Name[],Data[],Len)
	ARP_AddMenuItem(Data[0],"hawkslist","CmdHawksList")

public SaveData()
{	
	if(g_Class != Invalid_Class) ARP_ClassSave(g_Class,0)
	set_task(get_pcvar_float(p_SaveInterval),"SaveData")
}

//public plugin_end()
//	if(g_Class != Invalid_Class) ARP_ClassSave(g_Class,0)

public client_disconnect(id)
	g_Mode[id] = 0

public HawksListLoadHandle(Class:class_id,const class[],data[])
{	
	g_Class = class_id
	ARP_ClassSaveHook(class_id,"SaveHandle",data)
}

// Prunes old records
public SaveHandle(Class:ClassId,Name[],Data[])
{
	new ClassIter:Iter = ARP_ClassGetIterator(g_Class),Key[128],Time
	while(ARP_ClassMoreData(Iter))
	{
		ARP_ClassReadKey(Iter,Key,127)
		// Move the index forward
		ARP_ClassReadInt(Iter)
		
		if(containi(Key,g_Tag) == -1)
			continue
		
		GetDetails(Key,_,_,Time,_,_)
		
		if(get_systime() - Time > get_pcvar_num(p_KeepTime))
		{
			ARP_ClassDeleteKey(g_Class,Key)
			replace(Key,127,g_Tag,"")
			ARP_ClassDeleteKey(g_Class,Key)
		}		
	}
	ARP_ClassDestroyIterator(Iter)
}

public CmdSay(id)
{
	if(!g_Mode[id]) return PLUGIN_CONTINUE
	
	new Args[256]
	read_args(Args,255)
	
	remove_quotes(Args)
	trim(Args)
	
	if(!strlen(Args)) return PLUGIN_CONTINUE
	
	if(equali(Args,"cancel") || equali(Args,"/cancel"))
	{
		client_print(id,print_chat,"[ARP] You have cancelled the listing process.")
		g_Mode[id] = 0
		return PLUGIN_HANDLED
	}
	
	switch(g_Mode[id])
	{
		case 1 : 
		{
			copy(g_Title[id],63,Args)
			client_print(id,print_chat,"[ARP] You have entered the title for this entry. Please press 'y' and enter your listing text.")
			
			g_Mode[id] = 2
		}
		case 2 :
		{
			new Authid[36],Name[33],Entry[256]
			get_user_authid(id,Authid,35)
			get_user_name(id,Name,32)
			
			replace_all(Name,32,">","")
			
			format(Entry,255,"%s>%d>%s",Name,get_systime(),g_Title[id])
			
			ARP_ClassSetString(g_Class,Authid,Args)
			GetDetailsKey(Authid,Authid,35)
			ARP_ClassSetString(g_Class,Authid,Entry)
			
			client_print(id,print_chat,"[ARP] Thank you for your entry! It has now been posted.")
			
			ARP_ClassSave(g_Class,0)
			
			g_Mode[id] = 0
		}
	}
	
	return PLUGIN_HANDLED
}

public CmdHawksList(id)
{
	if(g_Class == Invalid_Class) return PLUGIN_HANDLED
	
	new ClassIter:Iter = ARP_ClassGetIterator(g_Class),Menu = menu_create("hawkslist^n^nThis utility is an online classifieds^nlisting, which allows you to view and^npost potential trades with other people.^n^n","MenuHawksList"),Key[128],Title[64],EntryExists,Authid[36]
	get_user_authid(id,Authid,35)
	
	while(ARP_ClassMoreData(Iter))
	{
		ARP_ClassReadKey(Iter,Key,127)
		// Move the index forward
		ARP_ClassReadInt(Iter)
		
		if(equali(Authid,Key,strlen(Authid)))
		{
			EntryExists = 1
			break
		}
	}
	ARP_ClassDestroyIterator(Iter)
	
	menu_additem(Menu,EntryExists ? "* Delete Listing" : "* Create Listing",EntryExists ? "1" : "0")
	menu_addblank(Menu,0)
	
	Iter = ARP_ClassGetIterator(g_Class)	
	while(ARP_ClassMoreData(Iter))
	{
		ARP_ClassReadKey(Iter,Key,127)
		// Move the index forward
		ARP_ClassReadInt(Iter)
		
		if(containi(Key,g_Tag) == -1)
			continue
		
		GetDetails(Key,_,_,_,Title,63)
		
		replace(Key,127,g_Tag,"")
		menu_additem(Menu,Title,Key)
	}
	ARP_ClassDestroyIterator(Iter)
	
	menu_display(id,Menu)
	
	return PLUGIN_HANDLED
}

public MenuHawksList(id,Menu,Item)
{	
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	if(!Item)
	{
		new Garbage,Mode[2]
		menu_item_getinfo(Menu,Item,Garbage,Mode,1,_,_,Garbage)
		
		if(str_to_num(Mode))
		{
			new ClassIter:Iter = ARP_ClassGetIterator(g_Class),PlayerAuthid[36],Authid[36],Key[128]
			get_user_authid(id,PlayerAuthid,35)
			
			while(ARP_ClassMoreData(Iter))
			{
				ARP_ClassReadKey(Iter,Key,127)
				// Move the index forward
				ARP_ClassReadInt(Iter)
				
				strtok(Key,Authid,35,Mode,1,'>')
				
				if(equali(Authid,PlayerAuthid))
				{
					ARP_ClassDeleteKey(g_Class,Key)
					GetDetailsKey(Key,Key,127)
					ARP_ClassDeleteKey(g_Class,Key)
					client_print(id,print_chat,"[ARP] You have deleted your listing.")
					ARP_ClassDestroyIterator(Iter)
					return
				}
			}
			ARP_ClassDestroyIterator(Iter)
			
			client_print(id,print_chat,"[ARP] There has been an error finding your listing.")
		}
		else
		{
			g_Mode[id] = 1
			client_print(id,print_chat,"[ARP] Please press 'y' and then type in the title of your listing. Say 'cancel' at any time to stop this.")
		}
		
		return
	}

	new Garbage,Key[64],Listing[256],Title[64],Authid[36],Name[33],Time,TimeLength[128]
	menu_item_getinfo(Menu,Item,Garbage,Key,63,_,_,Garbage)
	
	ARP_ClassGetString(g_Class,Key,Listing,255)
	if(!strlen(Listing))
	{
		client_print(id,print_chat,"[ARP] This listing is invalid.")
		return
	}
	
	copy(Authid,35,Key)

	GetDetailsKey(Key,Key,63)
	GetDetails(Key,Name,32,Time,Title,63)
	
	get_time_length(id,get_systime() - Time,timeunit_seconds,TimeLength,127)

	format(Listing,255,"Name: %s^nSteam ID: %s^nTime of Posting: %s ago^n^n%s",Name,Authid,TimeLength,Listing)

	show_motd(id,Listing,Title)

	client_print(id,print_chat,"[ARP] You have been shown ^"%s^".",Title)
}

GetDetailsKey(Key[],Fmt[],FmtLen)
	format(Fmt,FmtLen,"%s%s",g_Tag,Key)

GetDetails(Key[],Name[] = "",NameLen = 0,&Time = 0,Title[] = "",TitleLen = 0)
{
	new Cache[256],Right[256],TimeTemp[24]
	ARP_ClassGetString(g_Class,Key,Cache,255)
	
	strtok(Cache,Name,NameLen,Right,255,'>')
	strtok(Right,TimeTemp,23,Title,TitleLen,'>')
	
	Time = str_to_num(TimeTemp)
}
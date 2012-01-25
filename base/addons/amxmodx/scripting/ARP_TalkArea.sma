#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <fakemeta>

#define BASE_DISTANCE 300.0

#define MAX_LINES 6
//#define REFRESH_TIME 5

new g_OOCText[MAX_LINES][129]
//new g_Counter = REFRESH_TIME

#define PHONE_RING_OFFSET 1983712738

enum _:PHONE
{
	MODE = 0,
	RING,
	CALLER,
	CALLING,
	TALKING,
	RINGING
}

// flag A
#define POLICE_ACCESS ACCESS_A

#define ANSWER_ITEMS 3
#define STATUS_SETTINGS 3
#define RING_SETTINGS 3

new Float:g_LastCnn[33]
new Float:g_LastAdvert[33]

new g_Motorola
new g_Sony
new g_Nokia

new p_Ooc
new p_Cnn
new p_Advert
new p_Capscom
new p_Printconsole
new p_Printmode
new p_OocRefresh
new p_Range
new p_Lol
new p_Voice
new p_LogChat
new p_HudTitle

new g_CallMenu[] = "ARP_PhoneCallMenu"
new g_StatusMenu[] = "ARP_PhoneStatusMenu"
new g_AnswerMenu[] = "ARP_PhoneAnswerMenu"

new g_RingSound[] = "arp/ring.wav"
new g_SmsSound[] = "arp/sms.wav"
new g_911Sound[] = "arp/9.wav"
new g_911Sound2[] = "arp/1.wav"

new g_Bugged[33]

new g_StatusMenuItems[ANSWER_ITEMS][] =
{
	"Status:",
	"Ring:",
	"Place Call"
}

new g_StatusSettings[STATUS_SETTINGS][] =
{
	"On",
	"Invisible",
	"Off"
}

new g_RingSettings[RING_SETTINGS][] =
{
	"Ring",
	"Vibrate",
	"Silent"
}

new g_Phone[33][PHONE]
new g_ItemId[33]

//new g_MenuPage[33]
new g_ScanSound[] = "items/suitcharge1.wav"
new g_NotFoundSound[] = "items/suitchargeno1.wav"
new g_FoundSound[] = "items/suitchargeok1.wav"
new g_OocSound[] = "arp/ooc.wav"
new g_RadioSound[] = "hgrunt/_comma.wav"

new TravTrie:g_SayTrie
new TravTrie:g_SayTeamTrie

public plugin_init()
{	
	register_clcmd("say","CmdSay")
	register_clcmd("say_team","CmdSay")
	
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	
	ARP_AddCommand("say /shout","<message> - shouts message")
	ARP_AddCommand("say /cnn","<message> - sends news headline")
	ARP_AddCommand("say /advert","<message> - advertises message")
	ARP_AddCommand("say /ooc","<message> - sends message as OOC")
	ARP_AddCommand("say /me","<action> - performs action")
	ARP_AddCommand("say /com","(COP) <message> - sends message to all cops")
	ARP_AddCommand("say /hangup","- hangs up phone")
	ARP_AddCommand("say /911","<message> - summons police/medical")
	
	p_Ooc = register_cvar("arp_ooc","2")
	p_Cnn = register_cvar("arp_cnn","120")
	p_Advert = register_cvar("arp_advert","60")
	p_Capscom = register_cvar("arp_capscom","1")
	p_Printconsole = register_cvar("arp_printconsole","1")
	p_Printmode = register_cvar("arp_printmode","1")
	p_OocRefresh = register_cvar("arp_ooc_refresh","3.0")
	p_Range = register_cvar("arp_message_range","1.0")
	p_Lol = register_cvar("arp_message_lol","0")
	p_Voice = register_cvar("arp_voice","1")
	p_LogChat = register_cvar("arp_message_log","0")
	p_HudTitle = register_cvar("arp_ooc_hudtitle","[ARP OOC]")
	/*p_ChatColor = */
	register_cvar("arp_chat_color","0")
	
	register_forward(FM_PlayerPreThink,"ForwardPlayerThink")
	//register_forward(FM_PlayerPreThink,"ForwardPlayerThink")
	//register_forward(FM_Voice_SetClientListening,"ForwardSetClientListening")

	register_menucmd(register_menuid(g_CallMenu),1023,"CallHandle")
	register_menucmd(register_menuid(g_StatusMenu),1023,"StatusHandle")
	register_menucmd(register_menuid(g_AnswerMenu),1023,"AnswerHandle")
	
	register_event("DeathMsg","EventDeathMsg","a")
	
	set_task(get_pcvar_float(p_OocRefresh),"HudRefresh")
}

public ARP_Init()
	ARP_RegisterPlugin("Talkarea",ARP_VERSION,"The Apollo RP Team","Provides chat functionality")

public plugin_natives()
{
	g_SayTrie = TravTrieCreate()
	g_SayTeamTrie = TravTrieCreate()
	
	register_library("arp_chat")
	register_native("ARP_AddChat","_ARP_AddChat")
	register_native("ARP_AddTeamChat","_ARP_AddTeamChat")
}

public _ARP_AddChat(Plugin,Params)
{
	if(Params != 2)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 2",Params)
		return FAILED
	}
	
	static Handler[64],Temp[128],Params[512]
	get_string(1,Params,511)
	get_string(2,Handler,63)
	
	format(Temp,127,"%d|%s",Plugin,Handler)
	
	TravTrieSetString(g_SayTrie,Temp,Params)
	
	return SUCCEEDED
}

public _ARP_AddTeamChat(Plugin,Params)
{
	if(Params != 2)
	{
		log_error(AMX_ERR_NATIVE,"Invalid params passed: %d - Expected: 2",Params)
		return FAILED
	}
	
	static Handler[64],Temp[128],Params[512]
	get_string(1,Params,511)
	get_string(2,Handler,63)
	
	format(Temp,127,"%d|%s",Plugin,Handler)
	
	TravTrieSetString(g_SayTeamTrie,Temp,Params)
	
	return SUCCEEDED
}

public plugin_end()
{
	TravTrieDestroy(g_SayTrie)
	TravTrieDestroy(g_SayTeamTrie)
}

public ForwardPlayerThink(id)
{
	if(!is_user_connected(id) || !get_pcvar_num(p_Voice))
		return
	
	new Players[32],Playersnum,Player,Float:tOrigin[3],Float:pOrigin[3]
	get_players(Players,Playersnum)
	pev(id,pev_origin,pOrigin)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		if(!is_user_alive(Player))
			continue
		
		pev(Player,pev_origin,tOrigin)
		
		set_client_listen(id,Player,(get_distance_f(tOrigin,pOrigin) < BASE_DISTANCE * get_pcvar_float(p_Range) && is_user_alive(id)) ? 1 : 0)
	}
}

public HudRefresh()
{
	RefreshMessages()
	set_task(get_pcvar_float(p_OocRefresh),"HudRefresh")
}

public ARP_Error(const Reason[])
	pause("d")

public plugin_precache()
{
	precache_sound(g_RingSound)
	precache_sound(g_SmsSound)
	precache_sound(g_ScanSound)
	precache_sound(g_NotFoundSound)
	precache_sound(g_FoundSound)
	precache_sound(g_OocSound)
	precache_sound(g_911Sound)
	precache_sound(g_911Sound2)
	precache_sound(g_RadioSound)
}

public ARP_RegisterItems()
{
	g_Motorola = ARP_RegisterItem("Motorola RAZR","_Phone","One of the smallest and best phones on the market.",0)
	g_Sony = ARP_RegisterItem("Sony Ericsson","_Phone","One of the more functional phones on the market.",0)
	g_Nokia = ARP_RegisterItem("Nokia 6820","_Phone","One of the more durable phones on the market.",0)
	
	ARP_RegisterItem("Phone Subscription","_Subscription","Allows usage of a cell phone charged per minute.",0)
	ARP_RegisterItem("Phone Prepaid Card","_Subscription","Allows usage of a cell phone for a certain amount of time.",0)
	
	ARP_RegisterItem("Bug","_Bug","Used to tap into a user's communications and talking",1)
	ARP_RegisterItem("Bug Scanner","_Scanner","Used to detect bugs",0)
}

public EventDeathMsg()
{
	new id = read_data(2)
	BreakLine(id,"'s line has gone dead.")
	g_Bugged[id] = 0
}

public client_disconnect(id)
{
	BreakLine(id," has disconnected. The phone has been hung up.")
	
	g_Bugged[id] = 0
}

BreakLine(id,Msg[])
{
	if(task_exists(id + PHONE_RING_OFFSET))
		remove_task(id + PHONE_RING_OFFSET)
	
	new Call = g_Phone[id][CALLER] ? g_Phone[id][CALLER] : g_Phone[id][CALLING],Name[33]
	if(!Call)
		return
		
	get_user_name(id,Name,32)
	client_print(Call,print_chat,"[ARP] %s%s",Name,Msg)
	
	g_Phone[id][CALLER] = 0
	g_Phone[id][CALLING] = 0
	g_Phone[id][TALKING] = 0
	g_Phone[Call][CALLER] = 0
	g_Phone[Call][CALLING] = 0
	g_Phone[Call][TALKING] = 0
	
	ARP_ItemDone(id)
	ARP_ItemDone(Call)
}

public StatusHandle(id,Key)
{
	switch(Key)
	{
		case 0 :
		{
			if(g_Phone[id][MODE] == STATUS_SETTINGS - 1)
				g_Phone[id][MODE] = 0
			else
				g_Phone[id][MODE]++
				
			_Phone(id,g_ItemId[id])
		}
		case 1 :
		{
			if(g_Phone[id][RING] == RING_SETTINGS - 1)
				g_Phone[id][RING] = 0
			else
				g_Phone[id][RING]++
				
			_Phone(id,g_ItemId[id])
		}
		case 2 :
		{
			if(g_Phone[id][MODE] == 2)
			{
				client_print(id,print_chat,"[ARP] Your phone is currently off.")
				return
			}
			
			//new Menu[512],Pos,Keys = MENU_KEY_8|MENU_KEY_9|MENU_KEY_0,Players[32],Playersnum,Name[33],Num
			new Players[32],Playersnum
			
			GetPhonePlayers(Players,Playersnum,id)
			
			if(!Playersnum)
			{
				client_print(id,print_chat,"[ARP] There is no one else with a phone.")
				return
			}
			
			new Menu = menu_create("ARP Phonebook","CallHandle")
			for(new Count,Name[33],Command[3];Count < Playersnum;Count++)
			{
				get_user_name(Players[Count],Name,32)				
				num_to_str(Players[Count],Command,2)
				menu_additem(Menu,Name,Command)
			}
			
			menu_display(id,Menu)
		}
	}
}

public AnswerHandle(id,Key)
{
	if(Key)
		return
	
	if(task_exists(g_Phone[id][CALLER] + PHONE_RING_OFFSET))
		remove_task(g_Phone[id][CALLER] + PHONE_RING_OFFSET)
	
	client_print(id,print_chat,"[ARP] You have answered the phone.")
	client_print(g_Phone[id][CALLER],print_chat,"[ARP] The phone has been answered.")
	
	ARP_ItemSet(g_Phone[id][CALLER])
	ARP_ItemSet(id)
	
	g_Phone[g_Phone[id][CALLER]][TALKING] = 1
	g_Phone[id][TALKING] = 1
}

public CallHandle(id,Menu,Item)
{	
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_CONTINUE
	}
	
	new Garbage[2],Info[3]
	menu_item_getinfo(Menu,Item,Garbage[0],Info,2,Garbage,1,Garbage[0])
	
	menu_destroy(Menu)
	
	new Selection = str_to_num(Info)
	
	if(!is_user_connected(Selection) || g_Phone[Selection][MODE])
		return client_print(id,print_chat,"[ARP] Invalid user.")
	
	if(g_Phone[Selection][CALLER] || g_Phone[Selection][CALLING])
		return client_print(id,print_chat,"[ARP] The line is busy.")
	
	if(g_Phone[Selection][RING] == 2)
		return set_task(6.0,"NoAnswer",id)
	
	new Menu[256],Name[33]
	get_user_name(id,Name,32)
	
	add(Menu,255,"ARP Call Menu^n^n")
	add(Menu,255,Name)
	add(Menu,255," is calling you^n^n1. Answer^n2. Ignore")
	
	g_Phone[Selection][CALLER] = id
	g_Phone[Selection][RINGING] = 0
	g_Phone[id][CALLING] = Selection
	
	if(g_Phone[Selection][RING] < 2)
		set_task(2.0,"Ring",Selection + PHONE_RING_OFFSET,"a",_,_,6)
	
	show_menu(Selection,(1<<0|1<<1),Menu,-1,g_AnswerMenu)
	
	return PLUGIN_CONTINUE
}

public Ring(id)
{
	id -= PHONE_RING_OFFSET
	
	if(++g_Phone[id][RINGING] >= 6)
	{
		if(task_exists(id + PHONE_RING_OFFSET))
			remove_task(id + PHONE_RING_OFFSET)
		
		NoAnswer(g_Phone[id][CALLER])
		
		return
	}
	
	if(g_Phone[id][RING] == 0)
		emit_sound(id,CHAN_AUTO,g_RingSound,1.0,ATTN_NORM,0,PITCH_NORM)
}

public NoAnswer(id)
	if(is_user_connected(id))
		client_print(id,print_chat,"[ARP] You received no answer.")

public _Phone(id,ItemId)
{
	new Menu[256],Pos,Keys = MENU_KEY_0
	
	Pos += formatex(Menu,255,"ARP Phone Menu^n^n")
	
	for(new Count;Count < ANSWER_ITEMS;Count++)
	{
		Keys |= (1<<Count)
		
		Pos += formatex(Menu[Pos],255 - Pos,"%d. %s ",Count + 1,g_StatusMenuItems[Count])
		
		if(Count == 0)
			Pos += formatex(Menu[Pos],255 - Pos,"%s",g_StatusSettings[g_Phone[id][MODE]])
		else if(Count == 1)
			Pos += formatex(Menu[Pos],255 - Pos,"%s",g_RingSettings[g_Phone[id][RING]])
		
		Pos += formatex(Menu[Pos],255 - Pos,"^n")
	}
	
	formatex(Menu[Pos],255 - Pos,"^n0. Exit")
	
	g_ItemId[id] = ItemId
	show_menu(id,Keys,Menu,-1,g_StatusMenu)
}

public _Subscription(id,ItemId)
	client_print(id,print_chat,"[ARP] This item cannot be used. Use a phone, instead.")

public CmdSay(id)
{
	//return PLUGIN_CONTINUE
	
	new Args[256],Msg[512],Name[33],Mode
	read_args(Args,255)
	remove_quotes(Args)
	trim(Args)
	// going to use name as a temporary cache
	read_argv(0,Name,32)
	Mode = equali(Name,"say_team") ? 1 : 0
	get_user_name(id,Name,32)
	
	new travTrieIter:Iter = GetTravTrieIterator(Mode ? g_SayTeamTrie : g_SayTrie),PluginStr[10],Handler[64],Plugin,Forward,Return
	static Key[128],Value[512]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,127)
		Value[0] = 0
		ReadTravTrieString(Iter,Value,511)
		
		if(!Value[0] || equali(Args,Value))
		{
			strtok(Key,PluginStr,9,Handler,63,'|')
			Plugin = str_to_num(PluginStr)
			Forward = CreateOneForward(Plugin,Handler,FP_CELL,FP_CELL,FP_STRING)
			if(!Forward || !ExecuteForward(Forward,Return,id,Mode,Args))
			{
				log_error(AMX_ERR_NATIVE,"Could not execute forward to %d: %s",Plugin,Handler)
				return PLUGIN_HANDLED
			}
			DestroyForward(Forward)
			
			switch(Return)
			{
				case 1 : return PLUGIN_HANDLED
				case 2 : break
			}
		}
	}
	DestroyTravTrieIterator(Iter)
	
	//while(replace(Args,255,"%s","") || replace(Args,255,"%d","") || replace(Args,255,"%i","") || replace(Args,255,"%f","") || replace(Args,255,"%c","")) { }
	//if(equali(Args,"%s") || equali(Args,"%d") || equali(Args,"%i") || equali(Args,"%f") || equali(Args,"%c")) return PLUGIN_HANDLED
	replace_all(Args,255,"%","%%")
	
	if(!strlen(Args))
		return PLUGIN_CONTINUE
	
	if(is_user_alive(id))
	{		
		if(equali(Args,"//",2))
		{
			new Players[32],Playersnum,Player,Float:SndOrigin[3],Float:RcvOrigin[3],Float:Range = get_pcvar_float(p_Range) * BASE_DISTANCE
			get_players(Players,Playersnum)
			
			replace(Args,255,"// ","")
			if(Args[0] == '/' && Args[1] == '/')
				replace(Args,255,"//","")
			
			format(Msg,511,"[OOC] %s: (( %s ))",Name,Args)
			
			for(new Count;Count < Playersnum;Count++)
			{
				Player = Players[Count]
				if(!is_user_alive(Player))
					continue
				 
				entity_get_vector(Player,EV_VEC_origin,RcvOrigin)
				entity_get_vector(id,EV_VEC_origin,SndOrigin)	
				
				if(get_distance_f(RcvOrigin,SndOrigin) <= Range)
					ARP_ChatMessage(id,Player,Msg)
			}
			
			return End(Msg)
		}
			
		if(equali(Args,"/cnn ",5))
		{
			new Float:Cnn = get_pcvar_float(p_Cnn)
			if(!Cnn)
			{
				client_print(id,print_chat,"[ARP] CNN is currently disabled.")
				return PLUGIN_HANDLED
			}
			else if(get_gametime() - g_LastCnn[id] < Cnn)
			{
				client_print(id,print_chat,"[ARP] You must wait before you issue another headline.")
				return PLUGIN_HANDLED
			}
			
			g_LastCnn[id] = get_gametime()
			
			replace(Args,255,"/cnn ","")
			if(!strlen(Args))
				return PLUGIN_HANDLED
				
			format(Msg,255,"(CNN) %s: %s",Name,Args)
			
			ARP_ChatMessage(id,0,Msg)
			//ARP_ChatMessage(id,0,Msg)
			client_cmd(0,"spk fvox/alert")
			
			return End(Msg)
		}
		else if(equali(Args,"/advert ",8))
		{
			new Float:Advert = get_pcvar_float(p_Advert)
			if(!Advert)
			{
				client_print(id,print_chat,"[ARP] Advertising is currently disabled.")
				return PLUGIN_HANDLED
			}
			else if(get_gametime() - g_LastAdvert[id] < Advert)
			{
				client_print(id,print_chat,"[ARP] You must wait before you issue another advertisement.")
				return PLUGIN_HANDLED
			}
			
			g_LastAdvert[id] = get_gametime()
			
			replace(Args,255,"/advert ","")
			if(!strlen(Args))
				return PLUGIN_HANDLED
				
			format(Msg,255,"(ADVERT) %s: %s",Name,Args)
			
			ARP_ChatMessage(id,0,Msg)
			//ARP_ChatMessage(id,0,Msg)
			
			return End(Msg)
		}
		else if(equali(Args,"/ooc ",5))
		{
			if(!get_pcvar_num(p_Ooc))
			{
				client_print(id,print_chat,"[ARP] OOC chat is currently disabled.")
				return PLUGIN_HANDLED
			}
			
			replace(Args,255,"/ooc ","")
			if(!strlen(Args))
				return PLUGIN_HANDLED
			
			OOCMessage(Name,Args)
			
			return End(Msg)
		}
		else if(equali(Args,"/me ",4) || equali(Args,"/action ",8) || equali(Args,"/m ",3))
		{
			replace(Args,255,"/me ","")
			replace(Args,255,"/m ","")
			replace(Args,255,"/action ","")
			
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"(ACTION) %s %s",Name,Args)
				case 2 :
				{
					new Type[10]
					CleanUp(Args,255,Type)
					
					Args[0] = tolower(Args[0])
					
					format(Msg,255,"%s %s",Name,Args)
				}
			}
			
			new Players[32],Playersnum
			get_players(Players,Playersnum)
				
			for(new Count;Count < Playersnum;Count++)
				if(is_user_alive(Players[Count]))
					Message(id,Players[Count],BASE_DISTANCE * get_pcvar_float(p_Range),Msg)
			
			return End(Msg)
		}
		else if(equali(Args,"/shout ",7) || equali(Args,"/s ",3))
		{
			replace(Args,255,"/shout ","")
			replace(Args,255,"/s ","")
			new Len = strlen(Args)
			if(!Len)
				return PLUGIN_HANDLED
			
			for(new Count;Count < Len;Count++)
				Args[Count] = toupper(Args[Count])
			
			Len--
				
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"(SHOUT) %s: %s",Name,Args)
				case 2 :
				{
					new Type[10]
					CleanUp(Args,255,Type)
					
					new Len = strlen(Args) - 1
					if(Args[Len] == '.' || Args[Len] == '?' || Args[Len] == '!')
						Args[Len] = 0
							
					format(Msg,255,"%s shouts, ^"%s!^"",Name,Args)
				}
			}
			
			new Players[32],Playersnum
			get_players(Players,Playersnum)
				
			for(new Count;Count < Playersnum;Count++)
				if(is_user_alive(Players[Count]))
					Message(id,Players[Count],2 * BASE_DISTANCE * get_pcvar_float(p_Range),Msg)
			
			PrintBugMessage(id,Msg)
			
			return End(Msg)
		}		
		else if(equali(Args,"/quiet ",7) || equali(Args,"/whisper ",9) || equali(Args,"/w ",3) || equali(Args,"/q ",3))
		{
			replace(Args,255,"/quiet ","")
			replace(Args,255,"/q ","")
			replace(Args,255,"/whisper ","")
			replace(Args,255,"/w ","")
			
			new Len = strlen(Args)
			if(!Len)
				return PLUGIN_HANDLED
			
			Len--
			
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"(QUIET) %s: ... %s ...",Name,Args)
				case 2 :
				{
					new Type[10]
					CleanUp(Args,255,Type)
					
					new Len = strlen(Args) - 1
					if(Args[Len] == '.' || Args[Len] == '?' || Args[Len] == '!')
						Args[Len] = 0
					
					strtolower(Args)
							
					format(Msg,255,"%s whispers, ^"... %s ...^"",Name,Args)
				}
			}
			
			new Players[32],Playersnum
			get_players(Players,Playersnum)
				
			for(new Count;Count < Playersnum;Count++)
				if(is_user_alive(Players[Count]))
					Message(id,Players[Count],0.5 * BASE_DISTANCE * get_pcvar_float(p_Range),Msg)
			
			PrintBugMessage(id,Msg)
			
			return End(Msg)
		}
		else if(equali(Args,"/com ",5))
		{
			if(!ARP_IsCop(id))
			{
				client_print(id,print_chat,"[ARP] You are not part of the police force.")
				return PLUGIN_HANDLED
			}
		
			replace(Args,255,"/com ","")
			
			new Len = strlen(Args)
			if(!Len)
				return PLUGIN_HANDLED
				
			Len--
			
			if(get_pcvar_num(p_Capscom))
				strtoupper(Args)
				
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"(COM) %s: %s",Name,Args)
				case 2 :
				{
					new Type[10]
					CleanUp(Args,255,Type)
					
					format(Msg,255,"%s says over the police radio, ^"%s^"",Name,Args)
				}
			}
			
			new Players[32],Playersnum
			get_players(Players,Playersnum)
				
			for(new Count;Count < Playersnum;Count++)
				if(is_user_alive(Players[Count]) && ARP_IsCop(Players[Count]))
				{
					ARP_ChatMessage(id,Players[Count],Msg)
					client_cmd(Players[Count],"spk ^"%s^"",g_RadioSound)
				}
			
			PrintBugMessage(id,Msg)
			
			return End(Msg)
		}
		else if(equali(Args,"/hangup",7))
		{
			if(!g_Phone[id][CALLER] && !g_Phone[id][CALLING])
			{
				client_print(id,print_chat,"[ARP] You are not on the phone.")
				return PLUGIN_HANDLED
			}
			
			new Call = g_Phone[id][CALLER] ? g_Phone[id][CALLER] : g_Phone[id][CALLING]
			
			client_print(id,print_chat,"[ARP] You have hung up the phone.")
			client_print(Call,print_chat,"[ARP] The phone has been hung up.")
			
			g_Phone[id][CALLER] = 0
			g_Phone[id][CALLING] = 0
			g_Phone[Call][CALLER] = 0
			g_Phone[Call][CALLING] = 0
			
			ARP_ItemDone(id)
			ARP_ItemDone(Call)
			
			return End(Msg)
		}
		else if(equali(Args,"/sms ",5))
		{
			if(!ARP_GetUserItemNum(id,g_Motorola) && !ARP_GetUserItemNum(id,g_Nokia) && !ARP_GetUserItemNum(id,g_Sony))
			{
				client_print(id,print_chat,"[ARP] You do not have a phone.")
				return PLUGIN_HANDLED
			}
			
			new Target[33]
			replace(Args,255,"/sms ","")
			remove_quotes(Args)
			trim(Args)
			
			parse(Args,Target,32,Msg,1)
			copy(Msg,255,Args)
			replace(Msg,255,Target,"")
			trim(Msg)
			
			new Index = cmd_target(id,Target,0)
			if(!Index || !is_user_alive(Index))
			{
				client_print(id,print_chat,"[ARP] Could not find a user matching your input.")
				return PLUGIN_HANDLED
			}
			
			if(!ARP_GetUserItemNum(Index,g_Motorola) && !ARP_GetUserItemNum(Index,g_Nokia) && !ARP_GetUserItemNum(Index,g_Sony))
			{
				client_print(id,print_chat,"[ARP] That user does not have a phone.")
				return PLUGIN_HANDLED
			}
			
			format(Msg,511,"(SMS) %s: %s",Name,Msg)
			ARP_ChatMessage(id,Index,Msg)
			ARP_ChatMessage(id,id,Msg)
			
			client_cmd(id,"say ^"/me sends an SMS message.^"")
			
			//ARP_ChatMessage(id,Index,Msg)
			//ARP_ChatMessage(id,id,Msg)
			
			//emit_sound(id,CHAN_AUTO,g_SmsSound,1.0,ATTN_NORM,0,PITCH_NORM)
			emit_sound(Index,CHAN_AUTO,g_SmsSound,1.0,ATTN_NORM,0,PITCH_NORM)
			
			return End(Msg)
		}
		else if(equali(Args,"/911 ",5))
		{
			new Players[32],Playersnum,Player
			get_players(Players,Playersnum)
			
			replace(Args,255,"/911 ","")
			remove_quotes(Args)
			trim(Args)
			
			strtoupper(Args)
			
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"(9/11 EMERGENCY) %s: %s",Name,Args)
				case 2 :
				{
					new Type[10]
					CleanUp(Args,255,Type)
					
					format(Msg,255,"%s calls over 9/11, ^"%s^"",Name,Args)
				}
			}
			
			for(new i;i < Playersnum;i++)
			{
				Player = Players[i]
				if(ARP_IsMed(Player) || ARP_IsCop(Player) || Player == id)
				{
					//ARP_ChatMessage(id,Player,Msg)
					ARP_ChatMessage(id,Player,Msg)
					Play911Sound(Player)
					set_task(1.0,"Play911Sound",Player + 32)
					set_task(2.0,"Play911Sound",Player + 32)
				}
			}
			
			client_cmd(id,"say ^"/me calls 911.^"")
			
			return End(Msg)
		}
		else if(!Mode)
		{
			new Call = g_Phone[id][CALLER] ? g_Phone[id][CALLER] : g_Phone[id][CALLING]
			if(Call && (g_Phone[Call][CALLER] == id || g_Phone[Call][CALLING] == id) && g_Phone[Call][TALKING] == 1 && g_Phone[id][TALKING] == 1)
			{
				switch(get_pcvar_num(p_Printmode))
				{
					case 0 :
						return PLUGIN_HANDLED
					case 1 :
						format(Msg,255,"(PHONE) %s: %s",Name,Args)
					case 2 :
					{
						new Type[10]
						CleanUp(Args,255,Type)
						format(Args,255,"over the phone, ^"%s^"",Args)
					}
				}
				
				format(Msg,511,"%s says %s",Name,Args)
				ARP_ChatMessage(id,Call,Msg)
				format(Msg,511,"You say %s",Args)
				ARP_ChatMessage(id,id,Msg)
				
				//client_print(Call,print_chat,"%s says %s",Name,Msg)
				//client_print(id,print_chat,"You say %s",Msg)
				
				PrintBugMessage(id,Msg)
				
				return End(Msg)
			}
			
			new Type[10]
			switch(get_pcvar_num(p_Printmode))
			{
				case 0 :
					return PLUGIN_HANDLED
				case 1 :
					format(Msg,255,"%s: %s",Name,Args)
				case 2 :
				{
					CleanUp(Args,255,Type)
					
					format(Msg,255,"%s %s, ^"%s^"",Name,Type,Args)
				}
			}
			
			new Players[32],Playersnum
			get_players(Players,Playersnum)
			
			for(new Count;Count < Playersnum;Count++)
				if(is_user_alive(Players[Count]))
					Message(id,Players[Count],BASE_DISTANCE * get_pcvar_float(p_Range) * (equali(Type,"yells") ? 1.5 : 1.0),Msg)
				
			PrintBugMessage(id,Msg)
			
			return End(Msg)
		}
	}
		
	if(Mode)
	{
		if(!get_pcvar_num(p_Ooc))
		{
			client_print(id,print_chat,"[ARP] OOC chat is currently disabled.")
			return PLUGIN_HANDLED
		}
		
		OOCMessage(Name,Args)
	}
	
	return End(Msg)
}

public Play911Sound(id) id < 32 ? client_cmd(id,"spk ^"%s^"",g_911Sound) : client_cmd(id - 32,"spk ^"%s^"",g_911Sound2)

CleanUp(Args[],PassLen,Mode[10])
{
	new Len = strlen(Args) - 1
	if(Args[Len] != '.' && Args[Len] != '?' && Args[Len] != '!' && Args[Len] != ',' && Len < 255)
	{
		Args[Len += 1] = '.'
		Args[Len + 1] = 0
	}
	else if(Len > PassLen)
	{
		Args[Len] = '.'
		Args[Len + 1] = 0
	}
	
	switch(Args[Len])
	{
		case '.' :
			Mode = "says"
		case '?' :
			Mode = "asks"
		case '!' :
			Mode = "yells"
		case ',' :
			Mode = "continues"
	}
	
	replace_all(Args,PassLen," i "," I ")
	replace_all(Args,PassLen," i."," I.")
	replace_all(Args,PassLen,"i'","I'")
	
	if(get_pcvar_num(p_Lol))
	{
		replace_all(Args,PassLen,"lol","haha")
		replace_all(Args,PassLen,"lmao","haha")
		replace_all(Args,PassLen,"lmfao","haha")
		replace_all(Args,PassLen,"rofl","haha")
	}
	
	Args[0] = toupper(Args[0])
}

End(Msg[])
{
	if(get_pcvar_num(p_LogChat))
		ARP_Log("%s",Msg)
	else if(get_pcvar_num(p_Printconsole))
		server_print("%s",Msg)
	
	return PLUGIN_HANDLED
}

public EventHudRender(Name[],Data[],Len)
{
	if(get_pcvar_num(p_Ooc) != 2 || Data[1] != HUD_TER)
		return
	
	new id = Data[0]
	
	for(new Count;Count < MAX_LINES;Count++)
	{
		if(!Count)
		{
			static Title[33]
			get_pcvar_string(p_HudTitle,Title,32)
			ARP_AddHudItem(id,HUD_TER,0,Title)
		}
		if(g_OOCText[Count][0])
			ARP_AddHudItem(id,HUD_TER,0,g_OOCText[Count])
	}
		
	/*if(--g_Counter <= 0)
	{
		RefreshMessages()
		g_Counter = REFRESH_TIME
	}*/
}

public RefreshMessages()
	for(new Count;Count < MAX_LINES;Count++)
		copy(g_OOCText[Count],128,Count == MAX_LINES - 1 ? "" : g_OOCText[Count + 1])

OOCMessage(Name[],Args[])
{
	//replace_all(Args,255,"^%","%%")
	
	server_print("%s: (( %s ))",Name,Args)
	
	switch(get_pcvar_num(p_Ooc))
	{
		case 1 :
			client_print(0,print_chat,"%s: (( %s ))",Name,Args)
		case 2 :
		{
			client_print(0,print_console,"%s: (( %s ))",Name,Args)
			
			format(g_OOCText[MAX_LINES-1],128,"%s: %s ",Name,Args)
			ARP_AddHudItem(-1,HUD_TER,1,g_OOCText[MAX_LINES - 1])
			client_cmd(0,"spk %s",g_OocSound)
			
			RefreshMessages()
		}
	}
	
	return PLUGIN_HANDLED
}

// thanks to the harbu code for this, was too lazy to rewrite it
Message(sender,reciever,Float:Dist,const Msg[])
{
	new Float:SndOrigin[3],Float:RcvOrigin[3]
	entity_get_vector(reciever,EV_VEC_origin,RcvOrigin)
	entity_get_vector(sender,EV_VEC_origin,SndOrigin)	
	
	if(get_distance_f(RcvOrigin,SndOrigin) <= Dist)
		ARP_ChatMessage(sender,reciever,Msg)
}

GetPhonePlayers(Players[32],&Playersnum,Player)
{
	for(new id = 1;id <= 32;id++)
	{		
		if(!is_user_connected(id) || !is_user_alive(id) || (!ARP_GetUserItemNum(id,g_Motorola) && !ARP_GetUserItemNum(id,g_Nokia) && !ARP_GetUserItemNum(id,g_Sony)) || id == Player)
			continue
		
		Players[Playersnum++] = id
	}
	/*get_players(Players,Playersnum,"ac")
	
	for(new Count,id;Count < Playersnum;Count++)
	{
		id = Players[Count]
		if((!ARP_GetUserItemNum(id,MOTOROLA_ID) && !ARP_GetUserItemNum(id,NOKIA_ID) && !ARP_GetUserItemNum(id,SONY_ID)) || id == Player)
		{
			Pop(Players,Count)
			Playersnum--
		}
	}*/
}

public _Bug(id,ItemId)
{
	ARP_ItemDone(id)
	
	new Index,Body
	get_user_aiming(id,Index,Body,100)
	
	if(!Index || !is_user_alive(Index))
		return client_print(id,print_chat,"[ARP] You are not looking at any people to bug.")
	
	g_Bugged[Index] |= (1<<(id - 1))
	
	new Name[33]
	get_user_name(Index,Name,32)
	
	return client_print(id,print_chat,"[ARP] You have bugged %s.",Name)
}

public _Scanner(id,ItemId)
{
	ARP_ItemDone(id)
	
	new Index,Body
	get_user_aiming(id,Index,Body,100)
	
	if(!Index || !is_user_alive(Index))
		Index = id
	
	emit_sound(id,CHAN_ITEM,g_ScanSound,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
	
	if(Index == id)
		client_print(id,print_chat,"[ARP] You begin scanning yourself.")
	else
	{
		new Name[33]
		get_user_name(id,Name,32)
		client_print(Index,print_chat,"[ARP] %s is scanning you for bugs.",Name)
		
		get_user_name(Index,Name,32)
		client_print(id,print_chat,"[ARP] You are scanning %s for bugs.",Name)
	}
	
	new Params[2]
	Params[0] = id
	Params[1] = Index
	set_task(5.0,"Scan",_,Params,2)
}

public Scan(Params[2])
{
	new id = Params[0],Index = Params[1],Players[32],Playersnum,Bugsnum
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
		if(g_Bugged[Index] & (1<<(Players[Count]) - 1))
			Bugsnum++
	
	if(Bugsnum)
	{
		emit_sound(id,CHAN_ITEM,g_FoundSound,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
		
		if(Index == id)
			client_print(id,print_chat,"[ARP] You found %d bugs on yourself and removed them.",Bugsnum)
		else
		{
			new Name[33]
			get_user_name(id,Name,32)
			client_print(Index,print_chat,"[ARP] %s scanned you and found %d bugs, which were removed.",Name,Bugsnum)
			
			get_user_name(Index,Name,32)
			client_print(id,print_chat,"[ARP] You scanned %s and found %d bugs which you removed.",Name,Bugsnum)
		}
	}
	else
	{
		emit_sound(id,CHAN_ITEM,g_NotFoundSound,VOL_NORM,ATTN_NORM,0,PITCH_NORM)
		
		if(Index == id)
			client_print(id,print_chat,"[ARP] You found no bugs on yourself.")
		else
		{
			new Name[33]
			get_user_name(id,Name,32)
			client_print(Index,print_chat,"[ARP] %s scanned you and found no bugs.",Name)
			
			get_user_name(Index,Name,32)
			client_print(id,print_chat,"[ARP] You scanned %s and found no bugs.",Name)
		}
	}
	
	g_Bugged[Index] = 0
}

PrintBugMessage(id,Msg[])
{
	new Players[32],Playersnum
	get_players(Players,Playersnum)
			
	for(new Count;Count < Playersnum;Count++)
		if(is_user_alive(Players[Count]) && g_Bugged[id] & (1<<(Players[Count] - 1)))
			client_print(Players[Count],print_chat,"[BUG] %s",Msg)
}

// Not a true pop, but I couldn't think of anything else to call it
/*Pop(Array[32],Num)
{	
	new Size = sizeof Array
	
	for(new Count = Num;Count < Size;Count++)
		Array[Count] = Array[Count + 1]

	Array[Size - 1] = 0
	
	return 1
}*/

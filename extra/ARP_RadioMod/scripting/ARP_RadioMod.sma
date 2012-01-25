#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

// Comment this if you don't want players to need to have an item to use com (only for 911 workers)
#define RADIO_ITEM

new p_Channels
new p_Capscom
new p_PrintMode
new p_Lol

new g_Channel[33]
new g_Query[512]
new g_Menu[] = "RpRadioMenu"
new g_Radio

new g_RadioSound[] = "hgrunt/_comma.wav"

public ARP_Init()
{
	ARP_RegisterPlugin("Radio Mod","1.0","Hawk552","Allows players to change radio channels")
	
	ARP_AddChat("","CmdSay")
	
	p_Channels = register_cvar("arp_radio_channels","10")
	p_Capscom = register_cvar("arp_capscom","1")
	p_PrintMode = register_cvar("arp_printmode","1")
	p_Lol = register_cvar("arp_message_lol","0")
	
	register_menucmd(register_menuid(g_Menu),1023,"MenuHandle")
}

public plugin_precache()
	precache_sound(g_RadioSound)

public ARP_RegisterItems()
	g_Radio = ARP_RegisterItem("Radio","_Radio","Allows players to switch radio channels")

public _Radio(id)
{
	new Channel[32]
	g_Channel[id] > -1 ? format(Channel,31,"%d",g_Channel[id] + 1) : format(Channel,31,"911")
	
	format(g_Query,511,"Radio Menu^n^n1. Channel: %s^n^n0. Exit",Channel)
	show_menu(id,MENU_KEY_1|MENU_KEY_0,g_Query,-1,g_Menu)
}

public MenuHandle(id,Key)
{
	if(Key)
		return
	
	new Channels = get_pcvar_num(p_Channels)
	Channels - 1 == g_Channel[id] ? (g_Channel[id] = IsEmergency(id) ? -1 : 0) : g_Channel[id]++
	_Radio(id)
}

public CmdSay(id)
{	
	static Args[256],Msg[512]
	read_args(Args,255)
	
	if(containi(Args,"/com") == -1)
		return PLUGIN_CONTINUE
#if defined RADIO_ITEM
	else if(!ARP_GetUserItemNum(id,g_Radio))
#else
	else if(!ARP_GetUserItemNum(id,g_Radio) && !IsEmergency(id))
#endif
	{
		client_print(id,print_chat,"[ARP] You do not have a radio.")
		return PLUGIN_HANDLED
	}
	
	replace(Args,255,"/com","")
	remove_quotes(Args)
	trim(Args)
	
	new Players[32],Playersnum,Player,Name[33]
	get_players(Players,Playersnum)
	
	new Channel[32]
	g_Channel[id] > -1 ? format(Channel,31,"%d",g_Channel[id] + 1) : format(Channel,31,"911")
	
	get_user_name(id,Name,32)
	
	switch(get_pcvar_num(p_PrintMode))
	{
		case 0 :
			return PLUGIN_HANDLED
		case 1 :
		{
			if(get_pcvar_num(p_Capscom)) strtoupper(Args)
			format(Msg,511,"(RADIO CHAN %s) %s : %s",Channel,Name,Args)
		}
		case 2 :
		{
			new Type[10]
			CleanUp(Args,255,Type)
			
			if(get_pcvar_num(p_Capscom)) strtoupper(Args)
		
			format(Msg,511,"%s says over channel %s, ^"%s^"",Name,Channel,Args)
		}
	}
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		if(!is_user_alive(Player))
			continue
		
		if(g_Channel[id] == -1)
		{
#if defined RADIO_ITEM
			if(IsEmergency(Player) && ARP_GetUserItemNum(Player,g_Radio))
#else
			if(IsEmergency(Player))
#endif
			{	
				client_print(Player,print_chat,"%s",Msg)
				client_cmd(Player,"spk ^"%s^"",g_RadioSound)
			}
		}
		else if(g_Channel[id] == g_Channel[Player] && ARP_GetUserItemNum(Player,g_Radio))
		{
			client_print(Player,print_chat,"%s",Msg)
			client_cmd(Player,"spk ^"%s^"",g_RadioSound)
		}
	}
	
	return PLUGIN_HANDLED
}

IsEmergency(id)
	return ARP_IsMed(id) || ARP_IsCop(id)
	
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
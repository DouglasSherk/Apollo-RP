#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

new g_iWarnLevel[33]
new g_iAttacker[33]

new g_pIncrease
new g_pLower
new g_pLowerInterval
new g_pBan

new g_szMenu[] = "DMMenu"

public ARP_Init()
{
	ARP_RegisterPlugin("DM Guard","1.0","Hawk552","Prevents players from DMing")
	
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	
	register_event("DeathMsg","fnEventDeathMsg","a")
	
	// The warn level goes up to 100. If it reaches 100, then the player is kicked.
	
	// How much it should increase per kill
	g_pIncrease = register_cvar("arp_dm_increase","34")
	// How much it should lower every interval
	g_pLower = register_cvar("arp_dm_lower","10")
	// Every this many seconds, will be lowered by amx_danger_lower
	g_pLowerInterval = register_cvar("arp_dm_lower_interval","5")
	// Kick, perm ban or bantime
	g_pBan = register_cvar("arp_dm_bantime","0")
	
	register_menucmd(register_menuid(g_szMenu),1023,"MenuHandle")
	
	set_task(get_pcvar_float(g_pLowerInterval),"fnLowerDanger")
	
	//set_task(1.0,"ShowMessage",_,_,_,"b")
}

public client_disconnect(id)
	g_iWarnLevel[id] = 0

public fnLowerDanger()
{
	static iPlayers[32], iPlayersnum, iPlayer, iCvar
	get_players(iPlayers,iPlayersnum)
	iCvar = get_pcvar_num(g_pBan)
	
	for(new iCount = 0;iCount < iPlayersnum;iCount++)
	{
		iPlayer = iPlayers[iCount]
		
		if(g_iWarnLevel[iPlayer] >= 100)
			iCvar == -1 ? server_cmd("kick #%d ^"Warn level over 100^"",get_user_userid(iPlayer)) : server_cmd("banid %d #%d ^"Warning level over 100^" kick",iCvar,get_user_userid(iPlayer))
		else if(g_iWarnLevel[iPlayer] > 0)
			g_iWarnLevel[iPlayer] = clamp(g_iWarnLevel[iPlayer] - get_pcvar_num(g_pLower),0,100)
	}
	
	set_task(get_pcvar_float(g_pLowerInterval),"fnLowerDanger")
}

public fnEventDeathMsg()
{
	new iAttacker = read_data(1),iVictim = read_data(2)
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || iAttacker == iVictim)
		return
	
	g_iAttacker[iVictim] = iAttacker
	
	static szMenu[512],szName[33]
	get_user_name(iAttacker,szName,32)
	
	format(szMenu,511,"Did %s DM you?^n^n1. Yes^n2. No^n^n0. Exit",szName)
	show_menu(iVictim,MENU_KEY_1|MENU_KEY_2|MENU_KEY_0,szMenu,-1,g_szMenu)
}

public MenuHandle(id,Key)
	if(!Key && g_iAttacker[id])
	{
		new Name[33]
		get_user_name(g_iAttacker[id],Name,32)
		
		g_iWarnLevel[g_iAttacker[id]] += get_pcvar_num(g_pIncrease)
		client_print(id,print_chat,"[ARP] You have increased %s's warn level.",Name)
		
		get_user_name(id,Name,32)
		client_print(g_iAttacker[id],print_chat,"[ARP] %s has increased your warning level.",Name)
	}

public EventHudRender(Name[],Data[],Len)
{
	new id = Data[0]
	if(!is_user_alive(id) || Data[1] != HUD_PRIM || ARP_SqlHandle() == Empty_Handle)
		return
		
	g_iWarnLevel[id] = clamp(g_iWarnLevel[id],0,100)
	
	if(g_iWarnLevel[id]) ARP_AddHudItem(id,HUD_PRIM,0,"DMing Level: %d",g_iWarnLevel[id])
}

#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>

new g_Soda
new g_Fries
new g_Milk
new g_Hotdog
new g_Pizza
new g_Hamburger
new g_Pasta
new g_Steak

new p_HungerEnabled

new g_Starving[33]
new g_Eating[33]

public ARP_Init()
{
	ARP_RegisterPlugin("Hunger Mod",ARP_VERSION,"The Apollo RP Team","Creates hunger-related items and settings")
	
	p_HungerEnabled = register_cvar("arp_hunger_enabled","1")
	
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	
	set_task(15.0,"SetHunger",_,_,_,"b")
	set_task(1.0,"CheckHunger",_,_,_,"b")
}

public plugin_init() register_event("DeathMsg","EventDeathMsg","a")

public CheckHunger()
{
	if(!get_pcvar_num(p_HungerEnabled)) return
	
	new Players[32],Playersnum,id,Hunger
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		id = Players[Count]
		if(!is_user_alive(id)) continue
		
		Hunger = ARP_GetUserHunger(id)
		
		if(!g_Starving[id] && Hunger >= 75)
		{					
			client_print(id,print_chat,"[ARP] You are starting to get very hungry.")
			g_Starving[id] = 1
			ARP_SetUserSpeed(id,Speed_Mul,0.75)
		}
		else if(g_Starving[id] == 1 && Hunger >= 90)
		{
			client_print(id,print_chat,"[ARP] You are starving. You will no longer receive a salary until you eat.")
			g_Starving[id] = 2
		}
		else if(g_Starving[id] && Hunger < 90)
			g_Starving[id] = 1
		else if(g_Starving[id] && Hunger < 75)
		{
			ARP_SetUserSpeed(id,Speed_Mul,1.0/0.75)
			g_Starving[id] = 0
		}
	}
}

public SetHunger()
{
	if(!get_pcvar_num(p_HungerEnabled) || random_num(0,5)) return
	
	new Players[32],Playersnum,id
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		id = Players[Count]
		if(!is_user_alive(id)) continue
		
		ARP_SetUserHunger(id,ARP_GetUserHunger(id) + 1)
	}
}

public EventDeathMsg()
	client_disconnect(read_data(2))

public client_disconnect(id)
	g_Starving[id] = g_Eating[id] = 0

public ARP_Salary(id)
{
	if(get_pcvar_num(p_HungerEnabled) && g_Starving[id] == 2) return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public EventHudRender(Name[],Data[],Len)
{
	new id = Data[0]
	if(!is_user_alive(id) || Data[1] != HUD_PRIM || !get_pcvar_num(p_HungerEnabled) || ARP_SqlHandle() == Empty_Handle)
		return
	
	new Hunger = ARP_GetUserHunger(id)
	ARP_AddHudItem(id,HUD_PRIM,0,"Hunger: %d%%",Hunger)
	
	if(g_Starving[id] == 2) ARP_AddHudItem(id,HUD_PRIM,0,"Starving: No Salary")
}

public ARP_RegisterItems()
{
	g_Soda = ARP_RegisterItem("Soda","_Food","A can of soda, heals 5 hunger.",1)
	g_Fries = ARP_RegisterItem("Fries","_Food","A bag of fries, heals 10 hunger.",1)
	g_Milk = ARP_RegisterItem("Milk","_Food","A box of milk, heals 15 hunger.",1)
	g_Hotdog = ARP_RegisterItem("Hotdog","_Food","A weiner wrapped in bread, heals 25 hunger.",1)
	g_Pizza = ARP_RegisterItem("Pizza","_Food","A slice of pepperoni pizza, heals 30 hunger.",1)
	g_Hamburger = ARP_RegisterItem("Hamburger","_Food","A hamburger made of beef, heals 40 hunger.",1)
	g_Pasta = ARP_RegisterItem("Pasta","_Food","A plate of pasta with tomato sauce, heals 50 hunger.",1)
	g_Steak = ARP_RegisterItem("Steak","_Food","A long well cooked piece of beef, heals 80 hunger.",1)
}

//public client_PreThink(id)
//	if(g_Starving[id] || g_Eating[id])
//		entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id] / (1.5 * (g_Starving[id] ? 1 : 0) + 1.5 * g_Eating[id]))

public _Food(id,ItemId)
{
	if(g_Eating[id])
	{
		client_print(id,print_chat,"[ARP] You are already eating.")
		return ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
	}
	
	new CurArray[4],Msg[9] = "eating"
	CurArray[0] = id
	CurArray[1] = ItemId
	
	if(ItemId == g_Soda)
	{
		CurArray[2] = 5
		Msg = "drinking"
	}
	else if(ItemId == g_Fries)
		CurArray[2] = 10
	else if(ItemId == g_Milk)
	{
		CurArray[2] = 15
		Msg = "drinking"
	}
	else if(ItemId == g_Hotdog)
		CurArray[2] = 25
	else if(ItemId == g_Pizza)
		CurArray[2] = 30
	else if(ItemId == g_Hamburger)
		CurArray[2] = 40
	else if(ItemId == g_Pasta)
		CurArray[2] = 50
	else if(ItemId == g_Steak)
		CurArray[2] = 80
	
	CurArray[3] = Msg[0] == 'e' ? 1 : 0
	
	if(ARP_GetUserHunger(id) < CurArray[2])
	{
		ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
		return client_print(id,print_chat,"[ARP] You don't feel like %s this right now.",Msg)
	}
	
	new ItemName[33]
	ARP_GetItemName(ItemId,ItemName,32)
	
	client_print(id,print_chat,"[ARP] You are %s the %s.",Msg,ItemName)
	
	//if(!g_Starving[id]) g_MaxSpeed[id] = entity_get_float(id,EV_FL_maxspeed)
	ARP_SetUserSpeed(id,Speed_Mul,0.5)
	g_Eating[id] = 1
	
	ARP_ItemSet(id)
	
	set_task(1.0,"Eat",_,CurArray,3)
	
	return PLUGIN_CONTINUE
}

public Eat(CurArray[4])
{
	new id = CurArray[0],Food = CurArray[2],Hunger = ARP_GetUserHunger(id)
	
	if(Food > 5 && Hunger > 0)
	{
		Food -= 5
		ARP_SetUserHunger(id,Hunger - 5)
		
		CurArray[2] = Food
		
		set_task(1.0,"Eat",_,CurArray,3)
	}
	else
	{
		ARP_SetUserHunger(id,Hunger - Food)
		
		new ItemName[33]
		ARP_GetItemName(CurArray[1],ItemName,32)
		
		client_print(id,print_chat,"[ARP] You are done %s the %s.",CurArray[3] ? "drinking" : "eating",ItemName)
		
		ARP_ItemDone(id)
		
		if(g_Starving[id])
			switch(Hunger)
			{
				case 75 .. 90 : g_Starving[id] = 1
				case 0 .. 74 : g_Starving[id] = 0
			}
		
		ARP_SetUserSpeed(id,Speed_Mul,2.0)
		
		g_Eating[id] = 0
	}
}
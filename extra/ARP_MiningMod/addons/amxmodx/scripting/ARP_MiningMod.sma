#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <engine>

#define MENU_OPTIONS 4

new g_File[] = "mining.ini"

new TravTrie:g_Materials

new g_LightSprite

new g_Material[33][33]

new g_LastUse[33]

stock g_MaxPlayers

new Float:g_MaxSpeed[33]
new Float:g_FailChance[33]

public ARP_Init()
{
	ARP_RegisterPlugin("Mining Mod","1.1","Hawk552","Creates raw materials which can be harvested")
	
	ReadConfig()
	
	set_task(1.0,"CheckMines",_,_,_,"b")
}

ReadConfig()
{
	new File = ARP_FileOpen(g_File,"r")
	if(!File)
	{
		log_amx("Error opening ^"%s^".",g_File)
		return
	}
	
	g_Materials = TravTrieCreate()
	
	new Buffer[128],Name[33],TravTrie:Reading,Left[33],Right[33],Count
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		
		if(!Buffer[0] || Buffer[0] == ';') continue
		
		if(!Reading && Buffer[0] != '{') copy(Name,32,Buffer)
		
		if(Buffer[0] == '{')
		{
			Reading = TravTrieCreate()
			continue
		}
		else if(Buffer[0] == '}')
		{
			trim(Name)
			remove_quotes(Name)
			
			TravTrieSetString(Reading,"last_time","0")
			
			TravTrieGetString(Reading,"num",Buffer,127)
			TravTrieSetString(Reading,"current_num",Buffer)
			
			TravTrieSetString(Reading,"name",Name)
			
			TravTrieSetCellEx(g_Materials,++Count,Reading)
			
			Reading = Invalid_TravTrie
			continue
		}
		
		if(Reading)
		{						
			parse(Buffer,Left,32,Right,32)
			trim(Left)
			remove_quotes(Left)
			
			if(!Buffer[0] || Buffer[0] == ';' || strlen(Buffer) < 5) continue
			
			TravTrieSetString(Reading,Left,Right)
		}
	}
	
	fclose(File)
}

public plugin_init()
{
	g_MaxPlayers = get_maxplayers()
	
	ARP_RegisterCmd("arp_reloadmining","CmdReloadMining","<ADMIN> - reloads mining")
}

public CmdReloadMining(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,1))
		return PLUGIN_HANDLED
	
// Insurance policy.
#if 000
	for(new Index = 1;Index <= g_MaxPlayers;Index++)
		if(task_exists(Index))
		{
			client_print(Index,print_chat,"[ARP] Your production has been cancelled due to a reloading of the mining configuration. Please try again." )
			return PLUGIN_HANDLED
		}
#endif // 000
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Materials),TravTrie:Material
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieCell(Iter,Material)
		
		TravTrieDestroy(Material)
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieDestroy(g_Materials)
	
	ReadConfig()
	
	console_print(id,"The mining configuration has been reloaded.")
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	g_LastUse[id] = 0
	g_MaxSpeed[id] = 0.0
}

public plugin_precache()
{
	g_LightSprite = precache_model("sprites/lgtning.spr") 
	
	// TO DO: Precache models
}

public CheckMines()
{
	new travTrieIter:Iter = GetTravTrieIterator(g_Materials),TravTrie:Material,Temp[64],Exploded[3][8],Active,Origin[3],Float:LastTime,Float:RespawnTime
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieCell(Iter,Material)
		
		TravTrieGetString(Material,"active",Temp,63)
		Active = str_to_num(Temp)
		
		if(Active)
		{
			TravTrieGetString(Material,"model",Temp,63)
			if(!Temp[0])
			{				
				TravTrieGetString(Material,"origin",Temp,63)
				parse(Temp,Exploded[0],7,Exploded[1],7,Exploded[2],7)
				
				for(new Count;Count < 3;Count++)
					Origin[Count] = str_to_num(Exploded[Count])
				
				message_begin(MSG_PVS,SVC_TEMPENTITY,Origin)
				write_byte(TE_BEAMTORUS)
				write_coord(Origin[0])
				write_coord(Origin[1])
				write_coord(Origin[2])
				write_coord(Origin[0] + 24)
				write_coord(Origin[1] + 45)
				write_coord(Origin[2] + -66)
				write_short(g_LightSprite)
				write_byte(0) // starting frame
				write_byte(15) // frame rate in 0.1s
				write_byte(10) // life in 0.1s
				write_byte(10) // line width in 0.1s
				write_byte(1) // noise amplitude in 0.01s
				write_byte(255)
				write_byte(255)
				write_byte(255)
				write_byte(300) // brightness
				write_byte(1) // scroll speed in 0.1s
				message_end()
			}
		}
		else
		{
			TravTrieGetString(Material,"last_time",Temp,63)
			LastTime = str_to_float(Temp)
			
			TravTrieGetString(Material,"respawn_time",Temp,63)
			RespawnTime = str_to_float(Temp)
			
			if(get_systime() - LastTime > RespawnTime)
			{
				TravTrieGetString(Material,"respawn_chance",Temp,63)
				LastTime = str_to_float(Temp)
				
				if(random_float(0.0,1.0) > LastTime)
				{
					format(Temp,63,"%d",get_systime())
					TravTrieSetString(Material,"last_time",Temp)
					continue
				}
				
				TravTrieSetString(Material,"active","1")
				TravTrieGetString(Material,"num",Temp,63)
				TravTrieSetString(Material,"current_num",Temp)
				
				// TO DO: spawn the model
			}
		}
	}
	DestroyTravTrieIterator(Iter)
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
	
	if(g_MaxSpeed[id])
		entity_set_float(id,EV_FL_maxspeed,1.0)
	
	if(!(entity_get_int(id,EV_INT_button) & IN_USE) || entity_get_int(id,EV_INT_oldbuttons) & IN_USE)
		return
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Materials)
	static TravTrie:Material,Temp[64],Exploded[3][8],Active,Float:Origin[3],Float:PlayerOrigin[3],Time,SysTime,Name[33]
	entity_get_vector(id,EV_VEC_origin,PlayerOrigin)
	
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,g_Material[id],32)
		ReadTravTrieCell(Iter,Material)
		TravTrieGetString(Material,"name",Name,32)
		
		TravTrieGetString(Material,"active",Temp,63)
		Active = str_to_num(Temp)
		
		if(Active)
		{
			TravTrieGetString(Material,"origin",Temp,63)
			parse(Temp,Exploded[0],7,Exploded[1],7,Exploded[2],7)
			
			for(new Count;Count < 3;Count++)
				Origin[Count] = str_to_float(Exploded[Count])
			
			if(get_distance_f(Origin,PlayerOrigin) <= 50.0)
			{
				TravTrieGetString(Material,"cooldown_time",Temp,63)
				Time = str_to_num(Temp)
				
				SysTime = get_systime()
				
				if(SysTime - g_LastUse[id] < Time)
				{
					client_print(id,print_chat,"[ARP] Please wait %d seconds to mine this ore.",Time - SysTime + g_LastUse[id])
					return
				}
				
				new Menu = menu_create(Name,"MineMenuHandle"),Press = random_num(0,MENU_OPTIONS - 1)
				for(new Count;Count < MENU_OPTIONS;Count++)
					menu_additem(Menu,Count == Press ? "Press This Button" : "Do Not Press This Button","")
				menu_display(id,Menu)
				
				//g_Material[id] = Material
				
				return
			}
		}
	}
	DestroyTravTrieIterator(Iter)
}

public MineMenuHandle(id,Menu,Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	new TravTrie:Material
	TravTrieGetCell(g_Materials,g_Material[id],Material)
	
	new Temp[64],TempId = id
	TravTrieGetString(Material,"active",Temp,63)
	
	if(!str_to_num(Temp))
	{
		menu_destroy(Menu)
		client_print(id,print_chat,"[ARP] This node has been completely harvested.")
		return
	}
	
	new Exploded[3][8],Float:Origin[3],Float:PlayerOrigin[3]
	TravTrieGetString(Material,"origin",Temp,63)
	
	parse(Temp,Exploded[0],7,Exploded[1],7,Exploded[2],7)
	
	for(new Count;Count < 3;Count++)
		Origin[Count] = str_to_float(Exploded[Count])
	
	entity_get_vector(id,EV_VEC_origin,PlayerOrigin)
	
	if(get_distance_f(Origin,PlayerOrigin) >= 50.0)
	{
		menu_destroy(Menu)
		client_print(id,print_chat,"[ARP] You are too far from this ore.")
		return
	}
	
	g_LastUse[id] = get_systime()
	
	new Garbage[2],Name[2]
	menu_item_getinfo(Menu,Item,Garbage[0],Garbage,1,Name,1,Garbage[0])
	
	menu_destroy(Menu)
	
	if(Name[0] == 'D')
	{
		client_print(id,print_chat,"[ARP] You pressed the wrong button.")
		return
	}
	
	g_FailChance[id] = 0.0
	
	new Float:Time,ItemId,Flag,ItemIds[1]
	Temp[0] = 0
	for(new Count = 1,Key[33];Count < 10;Count++)
	{
		format(Key,32,"item%d_name",Count)
		TravTrieGetString(Material,Key,Temp,63)
		
		if(Count == 1 && !Temp[0])
		{
			TravTrieGetString(Material,"harvest_time",Temp,63)
			Time = str_to_float(Temp)
			
			Temp[0] = 0
			TravTrieGetString(Material,"failchance",Temp,63)
			g_FailChance[id] = str_to_float(Temp)
			
			Flag = 1
			
			break
		}

		ARP_FindItemId(Temp,ItemIds,1)
		ItemId = ItemIds[0]
		if(!ARP_ValidItemId(ItemId))
		{
			log_amx("Invalid item: %s",Temp)
			continue
		}
		
		if(!id)
			id = TempId
		if(!ARP_GetUserItemNum(id,ItemId))
			continue
		
		format(Key,32,"item%d_time",Count)
		TravTrieGetString(Material,Key,Temp,63)
		Time = str_to_float(Temp)
		
		format(Key,32,"item%d_failchance",Count)
		TravTrieGetString(Material,Key,Temp,63)
		g_FailChance[id] = str_to_float(Temp)
		
		format(Key,32,"item%d_useup",Count)
		TravTrieGetString(Material,Key,Temp,63)
		if(str_to_num(Temp))
			ARP_TakeUserItem(id,ItemId,1)
		
		Flag = 1
		
		break
	}
	
	if(!Flag)
	{
		static MOTD[4096],Name[33]
		new Len,Time,Chance
		Len += format(MOTD[Len],4096 - Len,"One of the following items is required to harvest this:^n^n")
		Len += format(MOTD[Len],4096 - Len,"'NAME' 'HARVEST TIME' 'FAILURE CHANCE' 'USE UP'^n")
		for(new Count = 1,Key[33];Count < 10;Count++)
		{
			Name[0] = 0
			
			format(Key,32,"item%d_name",Count)
			TravTrieGetString(Material,Key,Name,32)
			
			if(!Name[0])
				break
			
			format(Key,32,"item%d_time",Count)
			TravTrieGetString(Material,Key,Temp,63)
			Time = str_to_num(Temp)
			
			format(Key,32,"item%d_failchance",Count)
			TravTrieGetString(Material,Key,Temp,63)
			Chance = floatround(str_to_float(Temp) * 100)
			
			format(Key,32,"item%d_useup",Count)
			TravTrieGetString(Material,Key,Temp,63)
			
			Len += format(MOTD[Len],4096 - Len,"%d. %s %d %d%% %s^n",Count,Name,Time,Chance,Temp[0] == '1' ? "Yes" : "No")
		}
		show_motd(id,MOTD,"Items Required")
		
		return
	}
	
	set_task(Time,"HarvestMaterial",id)
	
	ARP_ItemSet(id)
	
	client_print(id,print_chat,"[ARP] You are now harvesting.")
	
	g_MaxSpeed[id] = entity_get_float(id,EV_FL_maxspeed)
}

public HarvestMaterial(id)
{
	ARP_ItemDone(id)
	
	entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id])
	g_MaxSpeed[id] = 0.0
	
	if(random_float(0.0,1.0) < g_FailChance[id])
	{
		client_print(id,print_chat,"[ARP] You failed to mine any ore.")
		return
	}
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Materials),Name[33],TravTrie:Material,Temp[64],TravTrie:PlayerMaterial
	TravTrieGetCell(g_Materials,g_Material[id],PlayerMaterial)
	
	while(MoreTravTrie(Iter))
	{
		//ReadTravTrieKey(Iter,Name,32)
		ReadTravTrieCell(Iter,Material)
		TravTrieGetString(Material,"name",Name,32)
		
		if(Material == PlayerMaterial) break
	}
	DestroyTravTrieIterator(Iter)
	
	new Item = ARP_FindItem(Name)
	if(!ARP_ValidItemId(Item) || !Material)
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact administrator. Your mining has been cancelled.")
		return
	}
	
#define HOW_MUCH_HAYLEE_SUCKS 10

	new HayleeIsABitch[33],ItemIDs[HOW_MUCH_HAYLEE_SUCKS],Count = 1
	for(;Count <= HOW_MUCH_HAYLEE_SUCKS;Count++)
	{
		formatex(HayleeIsABitch,32,"random%d",Count)
		Temp[0] = 0
		TravTrieGetString(Material,HayleeIsABitch,Temp,63)
		
		if(Temp[0] != 0)
		{
			ItemIDs[Count - 1] = ARP_FindItem(Temp)
			
			if(!ARP_ValidItemId(ItemIDs[Count - 1]))
			{
				client_print(id,print_chat,"[ARP] Internal error; please contact administrator. Your mining has been cancelled.")
				return
			}
		}
		else break
	}
	
	new hayleeBetterPayMe50Dollars = random(Count)
	if ( hayleeBetterPayMe50Dollars != 0 )
		Item = ItemIDs[hayleeBetterPayMe50Dollars - 1]
	
	TravTrieGetString(Material,"mine_amount",Temp,63)
	new ItemNum = str_to_num(Temp)
	TravTrieGetString(Material,"mine_amount_random",Temp,63)
	new ItemNumRand = str_to_num(Temp),Rand = ItemNumRand ? random_num(0,str_to_num(Temp)) : 0,Total = ItemNum + Rand
	
	TravTrieGetString(Material,"current_num",Temp,63)
	new AmountLeft = str_to_num(Temp)
	
	if(AmountLeft <= Total)
	{
		Total = AmountLeft
		client_print(id,print_chat,"[ARP] This ore is now exhausted.")
		
		TravTrieSetString(Material,"active","0")
		format(Temp,63,"%d",get_systime())
		TravTrieSetString(Material,"last_time",Temp)
	}
	
	ARP_GiveUserItem(id,Item,Total)	
	
	format(Temp,63,"%d",AmountLeft - Total)
	TravTrieSetString(Material,"current_num",Temp)
	
	ARP_GetItemName(Item,Name,32)
	
	client_print(id,print_chat,"[ARP] You have harvested %d %ss.",Total,Name)
}
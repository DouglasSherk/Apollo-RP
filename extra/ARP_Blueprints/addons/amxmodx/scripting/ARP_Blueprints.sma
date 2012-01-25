#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <time>

new g_File[] = "blueprints.ini"

new TravTrie:g_Blueprints
new Trie:g_AllBlueprints

new g_MOTD[4096]

new gMenu

stock g_MaxPlayers

new pInventFactor
new pCopyFactor

new gItemId[33]
new Float:gTimeToMake[33]
new Float:gStartedTime[33]

public plugin_init() 
{
	register_dictionary("time.txt")
	register_event("DeathMsg","EventDeathMsg","a")
	
	ARP_RegisterEvent("HUD_Render","EventHUDRender")
	
	gMenu = menu_create( "Blueprint Main Menu^n^nThis menu allows you to handle your^nblueprints. To see what each blueprint^nrequires, use it in your^ninventory.", "MenuBlueprintsHandle" )
	menu_additem( gMenu, "* Cancel Production", .callback = menu_makecallback( "IsProducing" ) )
	menu_addblank( gMenu, 0 )
	menu_additem( gMenu, "Craft" )
	menu_additem( gMenu, "Study" )
	menu_additem( gMenu, "Copy" )
	
	pInventFactor = register_cvar( "arp_blueprint_invent_factor", "20.0" )
	pCopyFactor = register_cvar( "arp_blueprint_copy_factor", "5.0" )
	
	g_MaxPlayers = get_maxplayers()
	
	ARP_RegisterCmd("arp_reloadblueprints","CmdReloadBlueprints","<ADMIN> - reloads blueprints")
}

public IsProducing( id, menu, item )
	return task_exists( id ) ? ITEM_IGNORE : ITEM_DISABLED

public EventHUDRender( const name[], const data[], len )
{
	new id = data[0], channel = data[1]
	if ( channel != HUD_PRIM || !task_exists( id ) )
		return
	
	static name[33], timeLeft[33]
	ARP_GetItemName( gItemId[id], name, 32 )
	ARP_AddHudItem( id, HUD_PRIM, 0, "Producing: %s", name )
	get_time_length( id, floatround( gStartedTime[id] + gTimeToMake[id] - get_gametime(), floatround_ceil ), timeunit_seconds, timeLeft, 32 )
	ARP_AddHudItem( id, HUD_PRIM, 0, "Time Left: %s", timeLeft )
}

public CmdReloadBlueprints(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,1))
		return PLUGIN_HANDLED
	
// Insurance policy.
#if 000
	for(new Index = 1;Index <= g_MaxPlayers;Index++)
		if(task_exists(Index))
		{
			client_print(Index,print_chat,"[ARP] Your production has been cancelled due to a reloading of the blueprint configuration. Please try again." )
			return PLUGIN_HANDLED
		}
#endif // 000
	
	new travTrieIter:Iter = GetTravTrieIterator(g_Blueprints),Key[64],Garbage[2],Blueprint[10],TravTrie:BlueprintNum
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Garbage,1)
		ReadTravTrieString(Iter,Key,63)
		
		strtok(Key,Blueprint,9,Garbage,1,'|')
		
		BlueprintNum = TravTrie:str_to_num(Blueprint)
		
		TravTrieDestroy(BlueprintNum)
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieDestroy(g_Blueprints)
	
	ReadConfig()
	
	console_print(id,"The blueprints configuration has been reloaded.")
	
	return PLUGIN_HANDLED
}

public ARP_Init()
{
	ARP_RegisterPlugin("Blueprint Mod","1.0","Hawk552","Allows users to create items using blueprints")
	
	ARP_RegisterChat("/blueprints","MenuBlueprints","Shows the blueprints menu")
	
	ARP_RegisterEvent("Menu_Display","EventMenuDisplay")
}

public EventDeathMsg()
{
	new id = read_data(2)
	if(task_exists(id))
	{
		client_print(id,print_chat,"[ARP] Your production has stopped due to your death.")
		remove_task(id)
		ARP_ItemDone(id)
	}
}

public EventMenuDisplay( name[], data[], len )
	ARP_AddMenuItem( data[0], "Blueprints", "MenuBlueprints" )

public MenuBlueprints( id )
{
	menu_display( id, gMenu )
	return PLUGIN_HANDLED
}

public MenuBlueprintsHandle( id, menu, item )
{
	switch ( item )
	{
		case 0 :
		{
			new itemName[33]
			ARP_GetItemName( gItemId[id], itemName, 32 )
			client_print( id, print_chat, "[ARP] You have cancelled your production of %s.", itemName )
			
			remove_task( id )
			ARP_ItemDone( id )
		}
		case 1 :
			UseBlueprints( id )
		case 2 :
			InventBlueprints( id )
		case 3 :
			CopyBlueprints( id )
	}
	
	return PLUGIN_HANDLED
}

public plugin_end()
{
	new travTrieIter:Iter = GetTravTrieIterator(g_Blueprints),Temp[10],Garbage[2],Left[10],TravTrie:CurTrie
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieString(Iter,Temp,9)
		
		strtok(Temp,Left,9,Garbage,1,'|')
		
		CurTrie = TravTrie:str_to_num(Left)
		TravTrieDestroy(CurTrie)
	}
	DestroyTravTrieIterator(Iter)
	
	TravTrieDestroy(g_Blueprints)
}

ReadConfig()
{
	new File = ARP_FileOpen(g_File,"r")
	if(!File)
	{
		log_amx("Error opening ^"%s^".",g_File)
		return
	}
	
	g_Blueprints = TravTrieCreate()
	
	new Buffer[128],Name[33],TravTrie:Reading,Results[1],Left[33],Right[33],Float:Time,CachedName[33]
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		replace(Buffer,127,"^n","")
		
		if(!Buffer[0] || Buffer[0] == ';') continue
		
		if(!Reading && Buffer[0] != '{') 
		{
			copy(Name,32,Buffer)
			copy(CachedName,32,Buffer)
		}
		
		if(Buffer[0] == '{')
		{
			Reading = TravTrieCreate()
			//log_amx("Creating travtrie: %d",Reading)
			continue
		}
		else if(Buffer[0] == '}')
		{
			format(Buffer,127,"%d|%f",Reading,Time)
	
#if 000 // Hawk552
			if(!ARP_FindItemId(Name,Results,1))
			{
				log_amx("Unknown item (root creation): %s",Buffer)
				continue
			}
#endif // Hawk552

			trim(Name)
			remove_quotes(Name)
			
			if(equali(Name,""))
			{
				copy(Name,32,CachedName)
				trim(Name)
				remove_quotes(Name)
				
				log_amx("Breach detected. Attempted fix: %s",!equali(Name,"") ? "Succeeded" : "Failed")
				Reading = Invalid_TravTrie
				continue
			}
			
			TravTrieSetString(g_Blueprints,Name,Buffer)
			
			format(Buffer,127,"Blueprint - %s",Name)
			
			if(!TrieKeyExists(g_AllBlueprints,Buffer))
			{
				ARP_RegisterItem(Buffer,"_Blueprint","Allows you to create an item",0)
				TrieSetString(g_AllBlueprints,Buffer,"")
			}
			
			Reading = Invalid_TravTrie
			continue
		}
		
		//static TravTrie:Temp
		//Temp = Reading
		if(Reading)
		{				
			/* SOMEWHERE BETWEEN HERE AND THE NEXT COMMENT, Reading GETS SET TO 0 */
			
			parse(Buffer,Left,32,Right,32)
			trim(Left)
			remove_quotes(Left)
			
			if(equali(Left,"*time"))
			{
				Time = str_to_float(Right)
				continue
			}
			else if(strlen(Left) < 5 || Left[0] == 0)
				continue
			
			if(!ARP_FindItemId(Left,Results,1))
			{
				log_amx("Unknown item: %s",Left)
			//	continue
			}
			
			/* RELOAD READING */
			
			//if(!Reading)
			//	Reading = Temp
			
			TravTrieSetCellEx(Reading,Results[0],max(str_to_num(Right),0))
			//TravTrieSetString(Reading,"zomgwtf",Right)
		}
	}
	
	fclose(File)
}

public ARP_RegisterItems()
{
	g_AllBlueprints = TrieCreate()
	ReadConfig()
}

public _Blueprint(id,ItemId)
{
	new Name[33],Float:Time,TravTrie:ItemsRequired,Split[33],Left[10],Right[10]
	ARP_GetItemName(ItemId,Name,32)
	
	replace(Name,32,"Blueprint - ","")
	
	new Results[1]
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact an administrator.")
		return
	}
	
	TravTrieGetString(g_Blueprints,Name,Split,32)
	
	strtok(Split,Left,9,Right,9,'|')
	
	ItemsRequired = TravTrie:str_to_num(Left)
	Time = str_to_float(Right)
	
	new Len = format(g_MOTD,4096,"You require the following items:^n^n")
	
	new travTrieIter:Iter = GetTravTrieIterator(ItemsRequired),Temp[10],ItemName[33],Num
	
	if(!ItemsRequired || !Iter)
	{
		ARP_Log("Error getting iterator: %d / %d^nName:%s",_:ItemsRequired,_:Iter,Name)
		return
	}
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Temp,9)
		ReadTravTrieCell(Iter,Num)
		
		ARP_GetItemName(str_to_num(Temp),ItemName,32)
		Len += Num ? format(g_MOTD[Len],4096 - Len,"%s: %d^n",ItemName,Num) : format(g_MOTD[Len],4096 - Len,"%s: (Not Consumed)",ItemName)
	}
	DestroyTravTrieIterator(Iter)
	
	new TimeLength[33]
	get_time_length(id,floatround(Time),timeunit_seconds,TimeLength,32)
	
	format(g_MOTD[Len],4096 - Len,"^n* Time required for production: %s^n^nSay /blueprints to open the blueprint menu.",TimeLength)
	
	show_motd(id,g_MOTD,"Items Required")
}

UseBlueprints(id)
{
	if(task_exists(id))
	{
		client_print(id,print_chat,"[ARP] You are already producing an item.")
		return PLUGIN_HANDLED
	}
	
	new Menu = menu_create("Blueprints - Use^n^nThis menu allows you to use your^nblueprints for creating items.^n^n","MenuUseBlueprints"),travTrieIter:Iter = GetTravTrieIterator(g_Blueprints),Key[64],Garbage[2],Num,ItemName[64],ItemId,ItemIds[1]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,63)
		ReadTravTrieString(Iter,Garbage,1)
		
		format(ItemName,63,"Blueprint - %s",Key)
		ARP_FindItemId(ItemName,ItemIds,1)
		ItemId = ItemIds[0]
		
		if(!ARP_ValidItemId(ItemId) || !ARP_GetUserItemNum(id,ItemId)) continue
	
		menu_additem(Menu,Key,"")
		
		Num++
	}
	DestroyTravTrieIterator(Iter)
	
	Num ? menu_display(id,Menu) : client_print(id,print_chat,"[ARP] You do not have any blueprints.")
	
	return PLUGIN_HANDLED
}

InventBlueprints( id )
{
	if(task_exists(id))
	{
		client_print(id,print_chat,"[ARP] You are already producing an item.")
		return PLUGIN_HANDLED
	}
	
	new Menu = menu_create("Blueprints - Invent^n^nThis menu allows you to create^nnew blueprints.^n^n","MenuInventBlueprints"),travTrieIter:Iter = GetTravTrieIterator(g_Blueprints),Key[64],Garbage[2],Num,ItemName[64],ItemId,ItemIds[1],ItemIdStr[12]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,63)
		ReadTravTrieString(Iter,Garbage,1)
		
		ARP_FindItemId(ItemName,ItemIds,1)
		ItemId = ItemIds[0]
	
		num_to_str(ItemId,ItemIdStr,charsmax(ItemIdStr))
	
		menu_additem(Menu,Key,ItemIdStr)
		
		Num++
	}
	DestroyTravTrieIterator(Iter)
	
	Num ? menu_display(id,Menu) : client_print(id,print_chat,"[ARP] No blueprints exist.")
	
	return PLUGIN_HANDLED
}

CopyBlueprints( id )
{
	if(task_exists(id))
	{
		client_print(id,print_chat,"[ARP] You are already producing an item.")
		return PLUGIN_HANDLED
	}
	
	new Menu = menu_create("Blueprints - Copy^n^nThis menu allows you to copy^nblueprints that you have.^n^n","MenuCopyBlueprints"),travTrieIter:Iter = GetTravTrieIterator(g_Blueprints),Key[64],Garbage[2],Num,ItemName[64],ItemId,ItemIds[1]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Key,63)
		ReadTravTrieString(Iter,Garbage,1)
		
		format(ItemName,63,"Blueprint - %s",Key)
		ARP_FindItemId(ItemName,ItemIds,1)
		ItemId = ItemIds[0]
		
		if(!ARP_ValidItemId(ItemId) || !ARP_GetUserItemNum(id,ItemId)) continue
	
		menu_additem(Menu,Key,"")
		
		Num++
	}
	DestroyTravTrieIterator(Iter)
	
	Num ? menu_display(id,Menu) : client_print(id,print_chat,"[ARP] You do not have any blueprints.")
	
	return PLUGIN_HANDLED
}

public MenuInventBlueprints(id,Menu,Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	new Name[33],Float:Time,Split[33],Left[10],Right[10]
	menu_item_getinfo(Menu,Item,Split[0],Split,1,Name,32,Split[0])
	
	format(Name,32,"Blueprint - %s",Name)
	
	new Results[1]
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact an administrator.")
		menu_destroy(Menu)
		return
	}
	
	new Blueprint = Results[0]
	
	replace(Name,32,"Blueprint - ","")
	
	TravTrieGetString(g_Blueprints,Name,Split,32)
	
	strtok(Split,Left,9,Right,9,'|')
	Time = str_to_float(Right) * get_pcvar_float(pInventFactor)
	
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] The item you are producing could not be found. Please contact an administrator.")
		menu_destroy(Menu)
		return
	}
	
	ConfirmMenu( id, Blueprint, Time )
	
	menu_destroy(Menu)
}

public MenuUseBlueprints(id,Menu,Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	new Name[33],Float:Time,TravTrie:ItemsRequired,Split[33],Left[10],Right[10]
	menu_item_getinfo(Menu,Item,Split[0],Split,1,Name,32,Split[0])
	
	format(Name,32,"Blueprint - %s",Name)
	
	new Results[1]
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact an administrator.")
		menu_destroy(Menu)
		return
	}
	
	replace(Name,32,"Blueprint - ","")
	
	TravTrieGetString(g_Blueprints,Name,Split,32)
	
	strtok(Split,Left,9,Right,9,'|')
	ItemsRequired = TravTrie:str_to_num(Left)
	Time = str_to_float(Right)
	
	new Len = format(g_MOTD,4096,"You lack the following items:^n^n"),PrevLen = Len
	
	new travTrieIter:Iter = GetTravTrieIterator(ItemsRequired),Temp[10],ItemId,Num,PlayerNum,ItemName[33]
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Temp,9)
		ItemId = str_to_num(Temp)
		
		PlayerNum = ARP_GetUserItemNum(id,ItemId)
		ReadTravTrieCell(Iter,Num)
		
		if(PlayerNum < Num || (!Num && !PlayerNum))
		{
			ARP_GetItemName(ItemId,ItemName,32)
			Len += Num ? format(g_MOTD[Len],4096 - Len,"%s: %d^n",ItemName,Num - PlayerNum) : format(g_MOTD[Len],4096 - Len,"%s: (Not Consumed)",ItemName)
		}
	}
	DestroyTravTrieIterator(Iter)
	
	if(Len != PrevLen)
	{
		show_motd(id,g_MOTD,"Items Required")
		menu_destroy(Menu)
		return
	}
	
	Iter = GetTravTrieIterator(ItemsRequired)
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieKey(Iter,Temp,9)
		ItemId = str_to_num(Temp)
		ReadTravTrieCell(Iter,Num)
		
		ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) - Num)
	}
	DestroyTravTrieIterator(Iter)
	
	ARP_SetUserItemNum(id,Results[0],ARP_GetUserItemNum(id,Results[0]) - 1)
	
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] The item you are producing could not be found. Please contact an administrator.")
		menu_destroy(Menu)
		return
	}
	
	ConfirmMenu( id, Results[0], Time )
	
	menu_destroy(Menu)
}

public MenuCopyBlueprints(id,Menu,Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	new Name[33],Float:Time,Split[33],Left[10],Right[10]
	menu_item_getinfo(Menu,Item,Split[0],Split,1,Name,32,Split[0])
	
	format(Name,32,"Blueprint - %s",Name)
	
	new Results[1]
	if(!ARP_FindItemId(Name,Results,1))
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact an administrator.")
		menu_destroy(Menu)
		return
	}
	
	replace(Name,32,"Blueprint - ","")
	
	TravTrieGetString(g_Blueprints,Name,Split,32)
	
	strtok(Split,Left,9,Right,9,'|')
	Time = str_to_float(Right) * get_pcvar_float(pCopyFactor)
	
	ConfirmMenu( id, Results[0], Time )
	
	menu_destroy(Menu)
}

ConfirmMenu( id, itemId, Float:timeToMake )
{
	gItemId[id] = itemId
	gTimeToMake[id] = timeToMake
	
	new itemName[64], timeToMakeLine[64], title[256]
	ARP_GetItemName( itemId, itemName, charsmax( itemName ) )
	
	get_time_length( id, floatround( timeToMake ), timeunit_seconds, timeToMakeLine, charsmax( timeToMakeLine ) )
	
	format( itemName, charsmax( itemName ), "Item: %s", itemName )
	format( timeToMakeLine, charsmax( timeToMakeLine ), "Time to Make: %s", timeToMakeLine )
	formatex( title, charsmax( title ), "Confirm Item Creation^n^n%s^n%s", itemName, timeToMakeLine )
	
	new menu = menu_create( title, "ConfirmMenuHandle" )
	menu_additem( menu, "Confirm" )
	menu_display( id, menu )
}

public ConfirmMenuHandle( id, menu, item )
{
	menu_destroy( menu )
	
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new itemName[33]
	ARP_GetItemName( gItemId[id], itemName, charsmax( itemName ) )
	
	client_print( id, print_chat, "[ARP] You begin producing a %s.", itemName )
	
	gStartedTime[id] = get_gametime()
	
	ARP_ItemSet( id )
	
	new data[1]
	data[0] = gItemId[id]
	set_task( gTimeToMake[id], "CreateItem", id, data, 1 )
	
	return PLUGIN_HANDLED
}

public CreateItem(Params[],id)
{
	new Name[33],ItemId = Params[0]
	ARP_GetItemName(ItemId,Name,32)
	
	client_print(id,print_chat,"[ARP] You have finished producing a %s.",Name)
	
	ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
	
	ARP_ItemDone(id)
}

public client_disconnect(id) if(task_exists(id)) remove_task(id)
// Uncomment to use files instead of nVault.
//#define __FILE_MODE

#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#if !defined __FILE_MODE
#include <nvault>
#endif

new gItemReserve
new gMoneyIssued

new gItemRate
new gItem

new gMenu[33]

new gNPC

#if !defined __FILE_MODE
new gVault
#endif

public plugin_init()
{
	ARP_RegisterPlugin( "Treasury NPC", "1.0", "Hawk552", "Allows players to exchange their items for money" )
	
	register_clcmd( "exchangemoney", "CmdExchangeMoney" )
	register_clcmd( "exchangeitem", "CmdExchangeItem" )
	
	ARP_RegisterCmd( "arp_reloadtreasury", "CmdReloadTreasury", "<ADMIN> - reloads Treasury NPC settings" )
	
#if defined __FILE_MODE
	new fileName[64], temp[33], garbage
	get_configsdir( fileName, 63 )
	add( fileName, 63, "/arp/treasury-issuance.ini" )
	
	read_file( fileName, 0, temp, 32, garbage )
	gItemReserve = str_to_num( temp )
	read_file( fileName, 1, temp, 32, garbage )
	gMoneyIssued = str_to_num( temp )
#else
	gVault = nvault_open( "arp_treasury" )
	gItemReserve = nvault_get( gVault, "item_reserve" )
	gMoneyIssued = nvault_get( gVault, "money_issued" )
#endif
}

#if !defined __FILE_MODE
public plugin_end()
	nvault_close( gVault )
#endif

public plugin_precache()
	ReadSettings( 1 )

public CmdReloadTreasury( id, level, cid )
{
	if ( !ARP_CmdAccess( id, cid, 1 ) )
		return PLUGIN_HANDLED
		
	new previousRate = gItemRate, previousItem = gItem
	
	ReadSettings( 0 )
	
	console_print( id, "Treasury NPC settings have been reloaded" )
	
	new itemName[33]
	ARP_GetItemName( gItem, itemName, 32 )
	
	if ( gItem != previousItem )
		client_print( 0, print_chat, "[ARP] The Treasury NPC is now exchanging %s for money.", itemName )
	
	if ( gItemRate != previousRate )
	{
		new previousName[33]
		ARP_GetItemName( previousItem, previousName, 32 )
		client_print( 0, print_chat, "[ARP] The Treasury NPC exchange rate has changed from $%d/%s to $%d/%s.", previousRate, previousName, gItemRate, itemName )
	}
	
	return PLUGIN_HANDLED
}

ReadSettings( firstRun )
{
	new file = ARP_FileOpen( "treasury.ini", "r" )
	if ( !file )
	{
		log_amx( "Error opening file: treasury.ini" )
		return
	}
	
	new buffer[128], name[33], item[33], model[64], zone, garbage[1], Float:origin[3], Float:angle, temp[3][10], right[64]
	while ( !feof( file ) )
	{		
		fgets( file, buffer, charsmax( buffer ) )
		trim( buffer )
		replace( buffer, charsmax( buffer ), "^n", "" )
		
		if ( !strlen( buffer ) || buffer[0] == ';' )
			continue
		
		if ( equali( buffer, "name", 4 ) )
		{
			parse( buffer, garbage, 0, name, charsmax( name ) )
			remove_quotes( name )
			trim( name )
		}
		else if ( equali( buffer, "item", 4 ) )
		{
			parse( buffer, garbage, 0, item, charsmax( item ) )
			remove_quotes( item )
			trim( item )
		}
		else if ( equali( buffer, "model", 5 ) )
		{
			parse( buffer, garbage, 0, model, charsmax( model ) )
			remove_quotes( model )
			trim( model )
		}
		else if ( equali( buffer, "zone", 4 ) )
			zone = 1
		else if ( equali( buffer, "angle", 5 ) )
		{
			parse( buffer, garbage, 0, temp[0], 9 )
			remove_quotes( temp[0] )
			trim( temp[0] )
			angle = str_to_float( temp[0] )
		}
		else if ( equali( buffer, "origin", 6 ) )
		{
			parse( buffer, garbage, 0, right, charsmax( right ) )
			remove_quotes( right )
			trim( right )
			parse( right, temp[0], 9, temp[1], 9, temp[2], 9 )
			origin[0] = str_to_float( temp[0] )
			origin[1] = str_to_float( temp[1] )
			origin[2] = str_to_float( temp[2] )
		}
		else if ( equali( buffer, "rate", 4 ) )
		{
			parse( buffer, garbage, 0, temp[0], 9 )
			remove_quotes( temp[0] )
			trim( temp[0] )
			gItemRate = str_to_num( temp[0] )
		}
	}
	
	gItem = ARP_FindItem( item )
	if ( !ARP_ValidItemId( gItem ) )
		ARP_Log( "Could not find item: %s", item )
	else
	{
		new itemName[33]
		ARP_GetItemName( gItem, itemName, charsmax( itemName ) )
		if ( !equali( item, itemName ) )
			ARP_Log( "Could not find direct match for item: %s (found %s)", item, itemName )
	}
	
	if ( firstRun )
	{
		precache_model( model )
		gNPC = ARP_RegisterNpc( name, origin, angle, model, "NpcHandle", zone )
	}
	
	fclose( file )
}

WriteIssuance()
{
#if defined __FILE_MODE
	new fileName[64], temp[33]
	get_configsdir( fileName, 63 )
	add( fileName, 63, "/arp/treasury-issuance.ini" )
	
	num_to_str( gItemReserve, temp, 32 )
	write_file( fileName, temp, 0 )
	num_to_str( gMoneyIssued, temp, 32 )
	write_file( fileName, temp, 1 )
#else
	new temp[33]
	num_to_str( gItemReserve, temp, 32 )
	nvault_set( gVault, "item_reserve", temp )
	num_to_str( gMoneyIssued, temp, 32 )
	nvault_set( gVault, "money_issued", temp )
#endif
}

public NpcHandle( id, npc )
{
	new itemName[33]
	ARP_GetItemName( gItem, itemName, 32 )
	
	new title[128]
	formatex( title, charsmax( title ), "Treasury Exchange - %s^n^nCurrent Exchange Rate:^n$%d per 1 %s^n^nReserves: %d %s^nReceipts Issued: $%d", itemName, gItemRate, itemName, gItemReserve, itemName, gMoneyIssued )

	if ( gMenu[id] )
		menu_destroy( gMenu[id] )
		
	gMenu[id] = menu_create( title, "MenuHandle" )
	formatex( title, charsmax( title ), "%s for Money", itemName )
	menu_additem( gMenu[id], title )
	formatex( title, charsmax( title ), "Money for %s", itemName )
	menu_additem( gMenu[id], title )
	
	menu_display( id, gMenu[id] )
}

public MenuHandle( id, menu, item )
{
	menu_destroy( gMenu[id] )
	gMenu[id] = 0

	if ( item == MENU_EXIT || !ARP_NpcDistance( id, gNPC ) )
		return PLUGIN_HANDLED
	
	new itemName[33]
	ARP_GetItemName( gItem, itemName, 32 )
	
	client_print( id, print_chat, "[ARP] Please enter the amount of %s you would like to exchange.", itemName )
	
	client_cmd( id, "messagemode %s", item ? "exchangemoney" : "exchangeitem" )
	
	return PLUGIN_HANDLED
}

public CmdExchangeMoney( id )
{
	new args[33]
	read_args( args, 32 )
	
	remove_quotes( args )
	trim( args )
	
	// They just hit enter.
	if ( !strlen( args ) || equali( args, "cancel" ) )
		return PLUGIN_HANDLED
	
	new amount = str_to_num( args )
	if ( amount <= 0 )
	{
		client_print( id, print_chat, "[ARP] You must enter a positive amount of items." )
		return PLUGIN_HANDLED
	}
	
	new cost = gItemRate * amount, wallet = ARP_GetUserWallet( id )
	if ( wallet < cost )
	{
		client_print( id, print_chat, "[ARP] You do not have enough money in your wallet." )
		return PLUGIN_HANDLED
	}
	
	new itemName[33]
	ARP_GetItemName( gItem, itemName, 32 )
	
	if ( gItemReserve < amount )
	{
		client_print( id, print_chat, "[ARP] The Treasury does not have enough %s on deposit to exchange.", itemName )
		return PLUGIN_HANDLED
	}
	
	ARP_SetUserWallet( id, wallet - cost )
	ARP_GiveUserItem( id, gItem, amount )
	
	client_print( id, print_chat, "[ARP] You have exchanged $%d for %d %s at a rate of $%d/%s.", cost, amount, itemName, gItemRate, itemName )
	
	gItemReserve -= amount
	gMoneyIssued -= cost
	
	WriteIssuance()
	
	return PLUGIN_HANDLED
}

public CmdExchangeItem( id )
{
	new args[33]
	read_args( args, 32 )
	
	remove_quotes( args )
	trim( args )
	
	// They just hit enter.
	if ( !strlen( args ) || equali( args, "cancel" ) )
		return PLUGIN_HANDLED
	
	new amount = str_to_num( args )
	if ( amount <= 0 )
	{
		client_print( id, print_chat, "[ARP] You must enter a positive amount of items." )
		return PLUGIN_HANDLED
	}
	
	new itemName[33]
	ARP_GetItemName( gItem, itemName, 32 )
	
	new cost = gItemRate * amount
	if ( !ARP_TakeUserItem( id, gItem, amount ) )
	{
		client_print( id, print_chat, "[ARP] You do not have enough %s.", itemName )
		return PLUGIN_HANDLED
	}
	
	ARP_SetUserWallet( id, ARP_GetUserWallet( id ) + cost )
	
	client_print( id, print_chat, "[ARP] You have exchanged %d %s for $%d at a rate of $%d/%s.", amount, itemName, cost, gItemRate, itemName )
	
	gItemReserve += amount
	gMoneyIssued += cost
	
	WriteIssuance()
	
	return PLUGIN_HANDLED
}
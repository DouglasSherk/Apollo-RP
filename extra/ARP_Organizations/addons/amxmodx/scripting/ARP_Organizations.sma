#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

new Class:gOrganizationList
new TravTrie:gOrganizations

new gMenu
new gAcceptMenu
new gBankMenu
new gMenus[33]

new gCurrentOrg[33][33]
new gCurrentAuth[33][36]

new gAdminMode[33]
new gInvitedBy[33]
// Prevents exploits.
new gFlag[33]

new gMaxPlayers

new gCallback

enum RANKS
{
	MEMBER = 0,
	RECRUITER,
	BANKER,
	OWNER,
	FOUNDER
}

new gRanks[RANKS][] =
{
	"Member",
	"Recruiter",
	"Banker",
	"Owner",
	"Founder"
}

public plugin_init()
{
	ARP_ClassLoad( "_master_organizations", "OrganizationsLoadedHandle", .table = "arp_organizations_list" )
	
	ARP_RegisterChat( "/orgs", "OrganizationMenu", "Manage organizations" )
	ARP_RegisterChat( "/organizations", "OrganizationMenu", "Manage organizations" )
	
	gOrganizations = TravTrieCreate()
	
	ARP_RegisterEvent( "Core_Save", "EventCoreSave" )
	ARP_RegisterEvent( "Menu_Display", "EventMenuDisplay" )
	
	gMenu = menu_create( ".", "MainMenuHandle" )
	menu_additem( gMenu, "Bank Account" )
	menu_additem( gMenu, "Members" )
	menu_additem( gMenu, "Administrate" )
	menu_additem( gMenu, "." )

	gAcceptMenu = menu_create( ".", "AcceptMenuHandle" )
	menu_additem( gAcceptMenu, "Yes" )
	menu_additem( gAcceptMenu, "No" )
	menu_setprop( gAcceptMenu, MPROP_EXIT, MEXIT_NEVER )
	
	gBankMenu = menu_create( ".", "BankMenuHandle" )
	menu_additem( gBankMenu, "Deposit" )
	menu_additem( gBankMenu, "Withdraw", .callback = menu_makecallback( "BankMenuCallback" ) )
	
	register_clcmd( "orgdeposit", "CmdOrgDeposit" )
	register_clcmd( "orgwithdraw", "CmdOrgWithdraw" )
	register_clcmd( "orgcreate", "CmdOrgCreate" )
	register_clcmd( "orgsalary", "CmdOrgSalary" )
	
	gCallback = menu_makecallback( "CallbackReject" )
	
	gMaxPlayers = get_maxplayers()
}

public CallbackReject()
	return ITEM_DISABLED

public ARP_Salary( id )
{	
	new totalPay, travTrieIter:iter = GetTravTrieIterator( gOrganizations ), name[33], Class:organization, authid[36], salary, RANKS:rank, bank, classAuthid[36], oldBank
	get_user_authid( id, authid, 35 )
	while ( MoreTravTrie( iter ) )
	{
		ReadTravTrieKey( iter, name, 32 )
		ReadTravTrieCell( iter, organization )

		GetUserProperties( authid, name, salary, rank )
		GetOrgProperties( name, bank, classAuthid, 35 )
		oldBank = bank

		salary > bank ? ( salary = bank, bank = 0 ) : ( bank -= salary )

		if ( oldBank != bank )
			SetOrgProperties( name, bank, classAuthid )

		totalPay += salary
	}
	DestroyTravTrieIterator( iter )
	
	if ( totalPay )
		ARP_SetUserBank( id, ARP_GetUserBank( id ) + totalPay )
}

public EventCoreSave()
	SaveAll( 0 )

public plugin_end()
	SaveAll( 1 )

SaveAll( close )
{
	ARP_ClassSave( gOrganizationList, close )
	
	new travTrieIter:iter = GetTravTrieIterator( gOrganizations ), Class:organization
	while ( MoreTravTrie( iter ) )
	{
		ReadTravTrieCell( iter, organization )
		ARP_ClassSave( organization, close )
	}
	DestroyTravTrieIterator( iter )
}

public ARP_Init()
{
	ARP_RegisterPlugin( "Organizations", "1.0", "Hawk552", "Allows players to create and manage organizations" )
}

public CmdOrgSalary( id )
{
	if ( !gFlag[id] )
		return PLUGIN_HANDLED
	
	gFlag[id] = 0
	
	new args[33]
	read_args( args, 32 )
	
	remove_quotes( args )
	trim( args )
	
	new amount = str_to_num( args )
	if ( amount < 0 )
	{
		client_print( id, print_chat, "[ARP] You must enter a positive or zero salary." )
		return PLUGIN_HANDLED
	}
	
	new RANKS:rank, salary
	GetUserProperties( gCurrentAuth[id], gCurrentOrg[id], salary, rank )
	SetUserProperties( gCurrentAuth[id], gCurrentOrg[id], amount, rank )
	
	client_print( id, print_chat, "[ARP] You have set %s's salary to $%d/hr.", gCurrentAuth[id], amount )
	
	return PLUGIN_HANDLED
}

public CmdOrgDeposit( id )
{
	new args[33]
	read_args( args, 32 )
	
	remove_quotes( args )
	trim( args )
	
	// They just hit enter.
	if ( !strlen( args ) || equali( args, "cancel" ) )
		return PLUGIN_HANDLED
	
	new amount = str_to_num( args ), wallet = ARP_GetUserWallet( id )
	if ( amount <= 0 )
	{
		client_print( id, print_chat, "[ARP] You must deposit a positive amount of money." )
		return PLUGIN_HANDLED
	}
	
	if ( amount > wallet )
	{
		client_print( id, print_chat, "[ARP] You do not have enough money in your wallet." )
		return PLUGIN_HANDLED
	}
	
	new bank, authid[36]
	GetOrgProperties( gCurrentOrg[id], bank, authid, 35 )
	
	ARP_SetUserWallet( id, wallet - amount )
	SetOrgProperties( gCurrentOrg[id], bank + amount, authid )
	
	client_print( id, print_chat, "[ARP] You have deposited $%d into the %s bank account.", amount, gCurrentOrg[id] )
	
	return PLUGIN_HANDLED
}

public CmdOrgWithdraw( id )
{
	if ( !gFlag[id] )
		return PLUGIN_HANDLED
	
	gFlag[id] = 0
	
	new salary, RANKS:rank, authid[36]
	get_user_authid( id, authid, 35 )
	GetUserProperties( authid, gCurrentOrg[id], salary, rank )
	
	if ( rank < BANKER )
		return PLUGIN_HANDLED
	
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
		client_print( id, print_chat, "[ARP] You must deposit a positive amount of money." )
		return PLUGIN_HANDLED
	}
	
	new bank
	GetOrgProperties( gCurrentOrg[id], bank, authid, 35 )
	
	if ( bank < amount )
	{
		client_print( id, print_chat, "[ARP] %s does not have enough money in its bank account ($%d available).", gCurrentOrg[id], bank )
		return PLUGIN_HANDLED
	}
	
	ARP_SetUserWallet( id, ARP_GetUserWallet( id ) + amount )
	SetOrgProperties( gCurrentOrg[id], bank - amount, authid )
	
	client_print( id, print_chat, "[ARP] You have withdrawn $%d from the %s bank account.", amount, gCurrentOrg[id] )
	
	return PLUGIN_HANDLED
}

public CmdOrgCreate( id )
{
	if ( GetUserOrg( id ) )
	{
		client_print( id, print_chat, "[ARP] You have already formed an organization." )
		return PLUGIN_HANDLED
	}
	
	new args[33], authid[36], value[64]
	read_args( args, 32 )
	get_user_authid( id, authid, 35 )
	
	remove_quotes( args )
	trim( args )
	
	if ( strlen( args ) > 24 )
	{
		client_print( id, print_chat, "[ARP] Your organization name is too long." )
		return PLUGIN_HANDLED
	}
	
	if ( GetOrgProperties( args ) )
	{
		client_print( id, print_chat, "[ARP] An organization by that name already exists." )
		return PLUGIN_HANDLED
	}
	
	replace_all( args, charsmax( args ), " [*]", "" )
	
	formatex( value, 63, "0|%s", authid )
	ARP_ClassSetString( gOrganizationList, args, value )
	
	ARP_ClassLoad( args, "OrganizationLoadedHandle", .table = "arp_organizations" )
	
	ARP_EscapeString( args, 32 )
	client_print( id, print_chat, "[ARP] You have created the organization %s.", args )
	
	return PLUGIN_HANDLED
}

public EventMenuDisplay( name[], data[], len )
	ARP_AddMenuItem( data[0], "Organizations", "OrganizationMenu" )

public OrganizationMenu( id )
{
	if ( gMenus[id] )
		menu_destroy( gMenus[id] )
	
	gMenus[id] = menu_create( "Organization List^n^nManage your organizations here.", "OrganizationMenuHandle" )
	new ClassIter:iter = ARP_ClassGetIterator( gOrganizationList ), name[33], Class:organization, authid[36], value[64], classAuthid[36], bank
	if ( !GetUserOrg( id ) )
		menu_additem( gMenus[id], "* Create Organization" )
	
	get_user_authid( id, authid, 35 )
	
	while ( ARP_ClassMoreData( iter ) )
	{
		value[0] = 0
		
		ARP_ClassReadKey( iter, name, charsmax( name ) )
		ARP_ClassReadInt( iter )
		TravTrieGetCell( gOrganizations, name, organization )
		
		ARP_ClassGetString( organization, authid, value, charsmax( value ) )
		GetOrgProperties( name, bank, classAuthid, 35 )
		
		if ( strlen( value ) )
		{
			//strtok( value, pieces[0], 10, pieces[1], 10, '|' )
			//rank = str_to_num( pieces[0] )
			//salary = str_to_num( pieces[1] )
			menu_additem( gMenus[id], name )
		}
		else if ( equali( authid, classAuthid ) )
		{
			add( name, charsmax( name ), " [*]" )
			menu_additem( gMenus[id], name )
		}
	}
	ARP_ClassDestroyIterator( iter )
	
	menu_display( id, gMenus[id] )
}

public OrganizationMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		goto endOfOrgMenu
	
	// They picked "Create Organization" / "Delete Organization"
	if ( !item && !GetUserOrg( id ) )
	{
		client_print( id, print_chat, "[ARP] Please type the name of the organization you want to form." )
		client_cmd( id, "messagemode orgcreate" )
	
		goto endOfOrgMenu
	}
	
	new name[33], Class:organization, dummy
	menu_item_getinfo( menu, item, dummy, "", 0, name, 32, dummy )
	
	replace( name, charsmax( name ), " [*]", "" )
	
	TravTrieGetCell( gOrganizations, name, organization )
	
	if ( organization == Invalid_Class )
	{
		client_print( id, print_chat, "[ARP] This organization no longer exists." )
		goto endOfOrgMenu
	}

	new playerAuthid[36], classAuthid[36], bank, RANKS:rank, salary
	GetOrgProperties( name, bank, classAuthid, 35 )
	get_user_authid( id, playerAuthid, 35 )
	GetUserProperties( playerAuthid, name, salary, rank )
	
	copy( gCurrentOrg[id], 32, name )
	
	new title[128]
	if ( equali( playerAuthid, classAuthid ) )
		menu_item_setname( gMenu, 3, "Disband Organization" )
	else
		menu_item_setname( gMenu, 3, "Leave Organization" )
	
	if ( salary )
		formatex( title, charsmax( title ), "Organization - %s^n^nSalary: $%d/hr^nRank: %s", name, salary, gRanks[rank] )
	else
		formatex( title, charsmax( title ), "Organization - %s^n^nRank: %s", name, gRanks[rank] )
	
	menu_setprop( gMenu, MPROP_TITLE, title )
	
	menu_display( id, gMenu )
	
endOfOrgMenu:
	menu_destroy( menu )
	gMenus[id] = 0
	return PLUGIN_HANDLED
}

GetUserOrg( id, orgName[] = "", len = 0 )
{
	new ClassIter:iter = ARP_ClassGetIterator( gOrganizationList ), name[33], classAuthid[36], playerAuthid[36], bank
	get_user_authid( id, playerAuthid, 35 )
	while ( ARP_ClassMoreData( iter ) )
	{
		ARP_ClassReadKey( iter, name, 32 )
		ARP_ClassReadString( iter, classAuthid, 0 )
		
		GetOrgProperties( name, bank, classAuthid, 35 )
		
		if ( equali( classAuthid, playerAuthid ) )
		{
			copy( orgName, len, name )
			return 1
		}
	}
	ARP_ClassDestroyIterator( iter )
	
	return 0
}

public BankMenuHandle( id, menu, item )
{
	switch ( item )
	{
		case 0 :
		{
			client_print( id, print_chat, "[ARP] Please enter the amount that you would like to deposit." )
			client_cmd( id, "messagemode orgdeposit" )
		}
		case 1 :
		{
			new salary, RANKS:rank, authid[36]
			get_user_authid( id, authid, 35 )
			GetUserProperties( authid, gCurrentOrg[id], salary, rank )
			
			if ( rank < BANKER )
			{
				client_print( id, print_chat, "[ARP] You do not have permission to withdraw money from the %s bank account.", gCurrentOrg[id] )
				return PLUGIN_HANDLED
			}
			
			gFlag[id] = 1
			
			client_print( id, print_chat, "[ARP] Please enter the amount that you would like to withdraw." )
			client_cmd( id, "messagemode orgwithdraw" )
		}
	}
	
	return PLUGIN_HANDLED
}

public BankMenuCallback( id, menu, item )
{
	//if ( item != 1 || menu != gBankMenu )
	//	return ITEM_IGNORE
	
	new salary, RANKS:rank, authid[36]
	get_user_authid( id, authid, 35 )
	GetUserProperties( authid, gCurrentOrg[id], salary, rank )
	
	return rank < BANKER ? ITEM_DISABLED : ITEM_IGNORE
}

public MainMenuHandle( id, menu, item )
{
/*
	if ( gMenus[id] )
	{
		menu_destroy( gMenus[id] )
		gMenus[id] = 0
	}
*/
	
	switch ( item )
	{
		case 0 :
		{
			new bank
			GetOrgProperties( gCurrentOrg[id], bank )
			
			new title[64]
			formatex( title, 63, "Bank Management - %s^n^nBank: $%d", gCurrentOrg[id], bank )
			menu_setprop( gBankMenu, MPROP_TITLE, title )
			
			menu_display( id, gBankMenu )
		}
		case 1, 2 :
		{	
			new title[64]
			formatex( title, 63, "Organization Members - %s", gCurrentOrg[id] )
			
			gMenus[id] = menu_create( title, "OrganizationMembersMenuHandle" )

			new authid[36], salary, RANKS:rank
			get_user_authid( id, authid, 35 )
			GetUserProperties( authid, gCurrentOrg[id], salary, rank )

			if ( rank >= RECRUITER )
			{
				menu_additem( gMenus[id], "* Invite" )
				menu_addblank( gMenus[id], 0 )
			}
			
			if ( item == 2 )
			{				
				if ( rank < BANKER )
				{
					client_print( id, print_chat, "[ARP] You do not have permission to administrate this organization." )
					menu_destroy( gMenus[id] )
					gMenus[id] = 0
					return PLUGIN_HANDLED
				}
				
				gAdminMode[id] = 1
			}
			else 
				gAdminMode[id] = 0
			
			new Class:organization, playerAuthid[36], name[33], match, bank
			TravTrieGetCell( gOrganizations, gCurrentOrg[id], organization )
			
			GetOrgProperties( gCurrentOrg[id], bank, authid, 35 )
			for ( new i = 1; i <= gMaxPlayers; i++ )
			{
				if ( !is_user_connected( i ) )
					continue

				get_user_authid( i, playerAuthid, 35 )
				if ( equali( playerAuthid, authid ) )
				{
					get_user_name( i, name, 32 )
					formatex( title, 63, "%s [Founder]", name )
					menu_additem( gMenus[id], title, authid, .callback = gCallback )
					match = 1
					break
				}
			}

			if ( !match )
			{
				formatex( title, 63, "%s [Founder]", authid )
				menu_additem( gMenus[id], title, authid, .callback = gCallback )
			}
			else
				match = 0
			
			new ClassIter:iter = ARP_ClassGetIterator( organization )
			while ( ARP_ClassMoreData( iter ) )
			{
				ARP_ClassReadKey( iter, authid, 35 )
				ARP_ClassReadString( iter, "", 0 )

				for ( new i = 1; i <= gMaxPlayers; i++ )
				{
					if ( !is_user_connected( i ) )
						continue

					get_user_authid( i, playerAuthid, 35 )
					if ( equali( playerAuthid, authid ) )
					{
						get_user_name( i, name, 32 )
						menu_additem( gMenus[id], name, authid )
						match = 1
						break
					}
				}

				if ( !match )
					menu_additem( gMenus[id], authid, authid )
				else
					match = 0
			}
			ARP_ClassDestroyIterator( iter )
			
			menu_display( id, gMenus[id] )
		}
		case 3 :
		{
			new bank, classAuthid[36], playerAuthid[36]
			GetOrgProperties( gCurrentOrg[id], bank, classAuthid, 35 )

			get_user_authid( id, playerAuthid, 35 )

			if ( equali( classAuthid, playerAuthid ) )
			{
				ARP_ClassDeleteKey( gOrganizationList, gCurrentOrg[id] )
			
				new Class:organization
				TravTrieGetCell( gOrganizations, gCurrentOrg[id], organization )
			
				TravTrieDeleteKey( gOrganizations, gCurrentOrg[id] )
				ARP_ClassDestroy( organization )
			
				client_print( id, print_chat, "[ARP] You have disbanded this organization since you are the founder." )

				return PLUGIN_HANDLED
			}

			new Class:organization
			TravTrieGetCell( gOrganizations, gCurrentOrg[id], organization )
			
			ARP_ClassDeleteKey( organization, playerAuthid )

			client_print( id, print_chat, "[ARP] You have left this organization." )
		}
	}
	
	return PLUGIN_HANDLED
}
	
public OrganizationMembersMenuHandle( id, menu, item )
{
	if ( item == MENU_EXIT )
		return PLUGIN_HANDLED
	
	new authid[36], salary, RANKS:rank
	get_user_authid( id, authid, 35 )
	GetUserProperties( authid, gCurrentOrg[id], salary, rank )
	
	if ( !item && rank >= RECRUITER )
	{
		menu_destroy( menu )
			
		new title[64], name[33], idStr[3], authid[36], garbage
		formatex( title, charsmax( title ), "Invite to Organization - %s", gCurrentOrg[id] )
		gMenus[id] = menu_create( title, "InviteMenuHandle" )
			
		for ( new i = 1; i <= gMaxPlayers; i++ )
			if ( is_user_connected( i ) && !is_user_bot( i ) )
			{
				get_user_authid( i, authid, 35 )
					
				if ( GetUserProperties( authid, gCurrentOrg[id], garbage, RANKS:garbage ) )
					continue
					
				get_user_name( i, name, 32 )
				num_to_str( i, idStr, 2 )
					
				menu_additem( gMenus[id], name, idStr )
			}
		
		if ( authid[0] )
			menu_display( id, gMenus[id] )
		else
			client_print( id, print_chat, "[ARP] There is nobody available for inviting." )
		
		return PLUGIN_HANDLED
	}

	if ( gAdminMode[id] )
	{			
		new dummy
		menu_item_getinfo( menu, item, dummy, authid, 35, "", 0, dummy )
		AdministrateUser( id, authid )
		
		return PLUGIN_HANDLED
	}
	else
	{
		new authid[36], dummy
		menu_item_getinfo( menu, item, dummy, "", 0, authid, 35, dummy )
		GetUserProperties( authid, gCurrentOrg[id], salary, rank )
		
		client_print( id, print_chat, "[ARP] Report on %s.", authid )
		client_print( id, print_chat, "[ARP] Salary: $%d/hr.", salary )
		client_print( id, print_chat, "[ARP] Rank: %s", gRanks[rank] )
	}
	
	menu_destroy( menu )
	gMenus[id] = 0
	return PLUGIN_HANDLED
}

AdministrateUser( id, const authid[] )
{
	new salary, RANKS:rank
	GetUserProperties( authid, gCurrentOrg[id], salary, rank )
	
	copy( gCurrentAuth[id], 35, authid )
		
	new text[64]
	formatex( text, 63, "Administrate User - %s", authid )
	gMenus[id] = menu_create( text, "AdministrateMenuHandle" )
	formatex( text, 63, "Salary: $%d/hr", salary )
	menu_additem( gMenus[id], text )
	formatex( text, 63, "Rank: %s", gRanks[rank] )
	menu_additem( gMenus[id], text )
	menu_additem( gMenus[id], "Remove" )
	menu_display( id, gMenus[id] )
}

public AdministrateMenuHandle( id, menu, item )
{
	menu_destroy( menu )
	gMenus[id] = 0
	
	switch ( item )
	{
		case 0 :
		{
			client_print( id, print_chat, "[ARP] Please type out the salary you would like to give to %s.", gCurrentAuth[id] )
			gFlag[id] = 1
			client_cmd( id, "messagemode orgsalary" )
		}
		case 1 :
		{
			new RANKS:rank, salary
			GetUserProperties( gCurrentAuth[id], gCurrentOrg[id], salary, rank )
			
			new authid[36], RANKS:userRank
			get_user_authid( id, authid, 35 )
			GetUserProperties( authid, gCurrentOrg[id], salary, userRank )
			
			// Allow owners to set other owners.
			rank += RANKS:1
			if ( userRank >= OWNER )
				rank %= OWNER + RANKS:1
			else
				rank %= userRank
			
			client_print( id, print_chat, "[ARP] %s has been set to a %s.", gCurrentAuth[id], gRanks[rank] )
			
			SetUserProperties( gCurrentAuth[id], gCurrentOrg[id], salary, rank )
			
			AdministrateUser( id, gCurrentAuth[id] )
		}
		case 2 :
		{
			new RANKS:rank, salary
			GetUserProperties( gCurrentAuth[id], gCurrentOrg[id], salary, rank )
			
			new authid[36], RANKS:userRank
			get_user_authid( id, authid, 35 )
			GetUserProperties( authid, gCurrentOrg[id], salary, userRank )
			
			if ( rank >= userRank && userRank != OWNER )
			{
				client_print( id, print_chat, "[ARP] You cannot delete someone with this rank." )
				return PLUGIN_HANDLED
			}
			
			new Class:organization
			TravTrieGetCell( gOrganizations, gCurrentOrg[id], organization )
			ARP_ClassDeleteKey( organization, gCurrentAuth[id] )
			
			client_print( id, print_chat, "[ARP] %s has been removed from this organization.", gCurrentAuth[id] )
		}
	}
	
	return PLUGIN_HANDLED
}

public InviteMenuHandle( id, menu, item )
{
	new name[33], idStr[3], dummy
	menu_item_getinfo( menu, item, dummy, idStr, 2, name, 32, dummy )
	
	menu_destroy( menu )
	gMenus[id] = 0
	
	new index = str_to_num( idStr )
	if ( !is_user_connected( index ) )
		return PLUGIN_HANDLED
	
	if ( gMenus[index] )
	{
		menu_destroy( gMenus[index] )
		gMenus[index] = 0
	}
	
	copy( gCurrentOrg[index], 32, gCurrentOrg[id] )
	
	gInvitedBy[index] = id
	
	new text[128]
	formatex( text, charsmax( text ), "Accept Invite?^n^nYou have been invited into:^n%s^n^nWould you like to accept?", gCurrentOrg[id] )
	menu_setprop( gAcceptMenu, MPROP_TITLE, text )
	menu_display( index, gAcceptMenu )
	
	return PLUGIN_HANDLED
}

public AcceptMenuHandle( id, menu, item )
{
	new name[33], fmt[33]
	get_user_name( id, name, 32 )
	copy( fmt, 32, gCurrentOrg[id] )
	ARP_EscapeString( fmt, 32 )
	
	if ( !item )
	{
		new authid[36]
		get_user_authid( id, authid, 35 )
		SetUserProperties( authid, gCurrentOrg[id], 0, MEMBER )
		
		client_print( id, print_chat, "[ARP] You have joined %s.", fmt )
		client_print( gInvitedBy[id], print_chat, "[ARP] %s has accepted your invite into %s.", name, fmt )
	}
	else
	{
		client_print( id, print_chat, "[ARP] You have declined the invitation to %s.", fmt )
		client_print( gInvitedBy[id], print_chat, "[ARP] %s has declined your invite into %s.", name, fmt )
	}
	
	return PLUGIN_HANDLED
}

GetUserProperties( const authid[], const org[], &salary, &RANKS:rank )
{
	new Class:organization, salaryStr[10], rankStr[2]
	TravTrieGetCell( gOrganizations, org, organization )
	
	static tmp[256], ownerAuthid[36], garbage
	tmp[0] = 0
	ARP_ClassGetString( organization, authid, tmp, charsmax( tmp ) )
	
	GetOrgProperties( org, garbage, ownerAuthid, 35 )
	
	strtok( tmp, salaryStr, 10, rankStr, 1, '|' )
	salary = str_to_num( salaryStr )
	rank = RANKS:str_to_num( rankStr )
	
	if ( equali( ownerAuthid, authid ) )
	{
		rank = FOUNDER
		return 1
	}
	
	return strlen( tmp ) > 0
}

SetUserProperties( const authid[], const org[], salary, RANKS:rank )
{
	new Class:organization
	TravTrieGetCell( gOrganizations, org, organization )
	
	static tmp[256]
	formatex( tmp, charsmax( tmp ), "%d|%d", salary, RANKS:rank )
	
	ARP_ClassSetString( organization, authid, tmp )
}
	
GetOrgProperties( const name[], &bank = 0, authid[] = "", len = 0 )
{
	static tmp[256], bankStr[33]
	tmp[0] = 0
	ARP_ClassGetString( gOrganizationList, name, tmp, charsmax( tmp ) )
	
	strtok( tmp, bankStr, 32, authid, len, '|' )
	bank = str_to_num( tmp )
	
	return strlen( tmp ) > 0
}

SetOrgProperties( const name[], bank, authid[] )
{
	static tmp[256]
	formatex( tmp, charsmax( tmp ), "%d|%s", bank, authid )
	
	ARP_ClassSetString( gOrganizationList, name, tmp )
}

public OrganizationsLoadedHandle( Class:classId, const class[], data[] )
{
	gOrganizationList = classId
	
	new ClassIter:iter = ARP_ClassGetIterator( classId ), name[33]
	while ( ARP_ClassMoreData( iter ) )
	{
		ARP_ClassReadKey( iter, name, charsmax( name ) )
		// Move the iterator forward.
 		ARP_ClassReadInt( iter )
		ARP_ClassLoad( name, "OrganizationLoadedHandle", .table = "arp_organizations" )
	}
	ARP_ClassDestroyIterator( iter )
}

public OrganizationLoadedHandle( Class:classId, const class[], data[] )
	TravTrieSetCell( gOrganizations, class, classId )
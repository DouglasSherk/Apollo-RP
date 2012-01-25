#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <fakemeta>
#include <engine>
#include <HamSandwich>
#include <ApolloRP_Chat>
#include <ApolloRP_Zone>

#define CNN_MESSAGES 5
#define TRADE_MESSAGES 5

new gTradeMessages[TRADE_MESSAGES][128]
new gTradeMessageNum = -1

new gMessages[CNN_MESSAGES][128]
new gMessageNum = -1

new gZone[] = "Trading Floor"

new gMaxPlayers

new Float:gLastTime

public ARP_Init()
{
	ARP_RegisterPlugin( "Trading Mod", "1.0", "Hawk552", "Allows players to trade" )
	
	ARP_RegisterEvent( "HUD_Render", "EventHUDRender" )
	ARP_RegisterEvent( "Chat_Message", "EventChatMessage" )
	
	ARP_AddChat( _, "CmdSay" )
	ARP_AddCommand( "say /trade", "Sends a persistent message to everyone on the trading floor" )
	
	gMaxPlayers = get_maxplayers()
}

public CmdSay( id, mode, args[] )
{
	new len = strlen( "/trade " )
	if ( equali( args, "/trade ", len ) )
	{
		new zone[33]
		ARP_GetUserZone( id, zone, 32 )
		
		if ( !equali( zone, gZone ) )
		{
			client_print( id, print_chat, "[ARP] You must be on the trading floor to use this command." )
			return PLUGIN_HANDLED
		}
		
		new msg[256], name[33], time[16]
		get_user_name( id, name, 32 )
		
		get_time( "[%H:%M]", time, 15 )
		
		format( msg, charsmax( msg ), "%s %s: %s", time, name, args[len] )
		
		trim( msg )
		remove_quotes( msg )
		
		gTradeMessageNum = ( gTradeMessageNum + 1 ) % TRADE_MESSAGES

		copy( gTradeMessages[gTradeMessageNum], 127, msg )
		
		format( msg, charsmax( msg ), "(TRADE) %s: %s", name, args[len] )
		
		for ( new i = 1; i <= gMaxPlayers; i++ )
		{
			if ( !is_user_alive( i ) )
				continue
			
			ARP_GetUserZone( i, zone, 32 )
			if ( equali( zone, gZone ) )
				ARP_ChatMessage( id, i, msg )
		}
			
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public EventChatMessage( name[], data[], len )
{	
	new Float:curTime = get_gametime()
	if ( !equali( data[2], "(CNN)", 5 ) || curTime - gLastTime < 0.01 )
		return

	gLastTime = curTime

	static msg[256], time[16]
	copy( msg, charsmax( msg ), data[2] )
	get_time( "[%H:%M]", time, 15 )
	replace( msg, charsmax( msg ), "(CNN)", time )

	gMessageNum = ( gMessageNum + 1 ) % CNN_MESSAGES

	copy( gMessages[gMessageNum], 127, msg )
}

public EventHUDRender( name[], data[], len )
{	
	new id = data[0]
	if ( !is_user_alive( id ) || !ARP_PlayerReady( id ) || ARP_SqlHandle() == Empty_Handle || data[1] != HUD_SEC )
		return
	
	new zone[33]
	ARP_GetUserZone( id, zone, 32 )
	
	if ( equali( zone, gZone ) )
	{
		if ( gMessageNum != -1 )
		{
			ARP_AddHudItem( id, HUD_SEC, 0, "Headlines" )
			for ( new i = gMessageNum, num; num < CNN_MESSAGES; i--, num++ )
			{
				if ( i == -1 ) 
					i = CNN_MESSAGES - 1
				if ( gMessages[i][0] )
					ARP_AddHudItem( id, HUD_SEC, 0, gMessages[i] )
			}
		}
		
		if ( gTradeMessageNum != - 1 )
		{
			if ( gMessageNum != - 1 )
				ARP_AddHudItem( id, HUD_SEC, 0, " " )
			
			ARP_AddHudItem( id, HUD_SEC, 0, "Trade Calls" )
			for ( new i = gTradeMessageNum, num; num < TRADE_MESSAGES; i--, num++ )
			{
				if ( i == -1 ) 
					i = TRADE_MESSAGES - 1
				if ( gTradeMessages[i][0] )
					ARP_AddHudItem( id, HUD_SEC, 0, gTradeMessages[i] )
			}
		}
	}
}
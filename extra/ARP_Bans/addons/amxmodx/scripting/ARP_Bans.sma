#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <time>

enum GlobalHost
{
	host,
	user,
	pass,
	db
}

// Feel free to connect to this using SQLyog/Navicat or whatever you want to look at these bans.
new gGlobalBansHost[GlobalHost][] =
{
	"bans.apollorp.org",
	"arp_guest",
	"arp_guest",
	"arp_bans"
}

new Trie:gGlobalBans

new Class:gClass[33]

new gTable[] = "arp_bans"

new Handle:gTuple

public ARP_Init()
	ARP_RegisterPlugin( "Bans", "1.0", "Hawk552", "Manages server bans" )

public plugin_init()
{
	register_concmd( "arp_ban", "CmdBan", ADMIN_BAN, "<player> <time> <reason> - bans a player" )
	register_concmd( "arp_unban", "CmdUnBan", ADMIN_BAN, "<steamid> - unbans a player" )
	register_concmd( "arp_bans_reload", "CmdBansReload", ADMIN_BAN, "- reloads bans" )

	gGlobalBans = TrieCreate()
	
	register_dictionary( "time.txt" )

	gTuple = SQL_MakeDbTuple( gGlobalBansHost[host], gGlobalBansHost[user], gGlobalBansHost[pass], gGlobalBansHost[db] )
	ReloadBans()
}

public CmdBansReload( id, level, cid )
{
	if ( !ARP_CmdAccess( id, cid, 1 ) )
		return PLUGIN_HANDLED
	
	ReloadBans()
	
	console_print( id, "Bans have been reloaded." )
	
	return PLUGIN_HANDLED
}

ReloadBans()
	if ( ARP_SqlMode() == MYSQL )
		SQL_ThreadQuery( gTuple, "GlobalBansHandler", "SELECT * FROM arp_bans;" ) 

public GlobalBansHandler( failState, Handle:query, error[], errorNum, data[], size, Float:queueTime )
{
	switch ( failState )
	{
		case TQUERY_CONNECT_FAILED :
		{
			ARP_Log( "The central bans database (%s) is down. Bans could not be retrieved.", gGlobalBansHost[host] )
			return
		}
		case TQUERY_QUERY_FAILED :
		{
			ARP_Log( "The central bans database (%s) is having technical problems. Bans could not be retrieved.", gGlobalBansHost[host] )
			return
		}
	}
		
	if ( errorNum )
	{
		ARP_Log( "Error fetching global bans: %s", error )
		return
	}
	
	TrieClear( gGlobalBans )

	new authid[36]
	while ( SQL_MoreResults( query ) )
	{
		SQL_ReadResult( query, 0, authid, 35 )
		TrieSetCell( gGlobalBans, authid, SQL_ReadResult( query, 1 ) )
		SQL_NextRow( query )
	}	
}

/* Taken from admincmd.sma, with a few tweaks */
public CmdBan(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	new target[32], minutes[8], reason[64]
	
	read_argv(1, target, 31)
	read_argv(2, minutes, 7)
	read_argv(3, reason, 63)
	
	new player = cmd_target(id, target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF)
	
	if (!player)
		return PLUGIN_HANDLED

	new authid[32], name2[32], authid2[32], name[32]
	new userid2 = get_user_userid(player)

	get_user_authid(player, authid2, 31)
	get_user_authid(id, authid, 31)
	get_user_name(player, name2, 31)
	get_user_name(id, name, 31)
	
	log_amx("Ban: ^"%s<%d><%s><>^" ban and kick ^"%s<%d><%s><>^" (minutes ^"%s^") (reason ^"%s^")", name, get_user_userid(id), authid, name2, userid2, authid2, minutes, reason)
	
	new temp[64], banned[16], nNum = str_to_num(minutes)
	if (nNum)
		format(temp, 63, "%L", player, "FOR_MIN", minutes)
	else
		format(temp, 63, "%L", player, "PERM")

	format(banned, 15, "%L", player, "BANNED")
	
	console_print( player, "This server is running Apollo RP Bans." )
	console_print( player, "You are banned from this server." )
	console_print( player, "--------------------------------" )
	console_print( player, "Your name when banned:    %s", name2 )
	console_print( player, "Your Steam ID:            %s", authid2 )
	console_print( player, "Administrator name:       %s", name )
	console_print( player, "Administrator Steam ID:   %s", authid )
	if ( nNum )
	{
		console_print( player, "Banned for:               %s", minutes )
		console_print( player, "Ban time remaining:       %s", minutes )
	}
	else
		console_print( player, "Banned for:               Permanently" )
	console_print( player, "Reason:                   %s", reason )
	
	if ( gClass[player] )
	{
		static bannedInfo[512]
		replace_all( name, charsmax( name ), "|", "[" )
		replace_all( name2, charsmax( name2 ), "|", "[" )
		formatex( bannedInfo, charsmax( bannedInfo ), "%s|%s|%s|%d|%s|%d", name2, name, authid, str_to_num( minutes ), reason, get_systime() )
		ARP_ClassSetString( gClass[player], "banned", bannedInfo )
	}
	else
		console_print( id, "The player's data has not loaded yet -- this ban will not be saved and you will have to redo it if they rejoin." )

	if (reason[0])
		server_cmd("kick #%d ^"%s (%s %s)^"", userid2, reason, banned, temp)
	else
		server_cmd("kick #%d ^"%s %s^"", userid2, banned, temp)

	
	// Display the message to all clients

	new msg[256];
	new len;
	new maxpl = get_maxplayers();
	for (new i = 1; i <= maxpl; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i))
		{
			len = formatex(msg, charsmax(msg), "%L", i, "BAN");
			len += formatex(msg[len], charsmax(msg) - len, " %s ", name2);
			if (nNum)
			{
				len += formatex(msg[len], charsmax(msg) - len, "%L", i, "FOR_MIN", minutes);
			}
			else
			{
				len += formatex(msg[len], charsmax(msg) - len, "%L", i, "PERM");
			}
			if (strlen(reason) > 0)
			{
				formatex(msg[len], charsmax(msg) - len, " (%L: %s)", i, "REASON", reason);
			}
			show_activity_id(i, id, name, msg);
		}
	} 
	
	console_print(id, "[AMXX] %L", id, "CLIENT_BANNED", name2)
	
	return PLUGIN_HANDLED
}

public CmdUnBan(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[32]
	read_argv(1, arg, 31)
	
	SingleChange( id, arg, 1 )
	
	return PLUGIN_HANDLED
}

SingleChange( id, steamId[], mode )
{
	new data[2]
	data[0] = mode
	data[1] = id == 0 ? 33 : id
	ARP_ClassLoad( steamId, "SingleChangeLoadedHandle", data, gTable )
}

public SingleChangeLoadedHandle( Class:classId, const className[], const data[] )
{
	new id = data[1], mode = data[0], authid[32], name[32]
	if ( id == 33 )
		id = 0 
	
	if ( mode == 1 )
	{
		new temp[2]
		ARP_ClassGetString( classId, "banned", temp, charsmax( temp ) )
		
		if ( temp[0] )
		{
			ARP_ClassDeleteKey( classId, "banned" )
			
			get_user_name(id, name, 31)

			show_activity_key("ADMIN_UNBAN_1", "ADMIN_UNBAN_2", name, className)

			get_user_authid(id, authid, 31)
			log_amx("Cmd: ^"%s<%d><%s><>^" unban ^"%s^"", name, get_user_userid(id), authid, className)
		}
		else
			console_print( id, "That Steam ID is not banned" )
	}
	else
	{
		
	}
}

public client_putinserver( id )
{
	new authid[36]
	get_user_authid( id, authid, charsmax( authid ) )
	
	if ( TrieKeyExists( gGlobalBans, authid ) )
	{
		new status
		TrieGetCell( gGlobalBans, authid, status )
		
		if ( status )
			server_cmd( "kick #%d ^"%s^"", get_user_userid( id ), "Globally banned from all RP servers." )
		
		return
	}
	
	new idStr[3]
	num_to_str( id, idStr, charsmax( idStr ) )
	
	ARP_ClassLoad( authid, "ClassLoadedHandle", idStr, gTable )
}

public client_disconnect( id )
	if ( gClass[id] != Invalid_Class )
		ARP_ClassSave( gClass[id], 1 )

public ClassLoadedHandle( Class:classId, const className[], const data[] )
{	
	new id = str_to_num( data )
	gClass[id] = classId
	
	if ( !is_user_connected( id ) )
	{
		client_disconnect( id )
		return
	}
	
	new bannedInfo[2]
	ARP_ClassGetString( classId, "banned", bannedInfo, charsmax( bannedInfo ) )
	
	if ( strlen( bannedInfo ) )
		BanUser( id )
}
	
public BanUser( id )
{
	if ( !is_user_connected( id ) )
	{
		client_disconnect( id )
		return
	}
	
	new bannedTime, timeLeft
	
	static bannedInfo[512]
	ARP_ClassGetString( gClass[id], "banned", bannedInfo, charsmax( bannedInfo ) )
	
	static pieces[6][64], authid[36], bannedFor[33], timeRemaining[33]
	ExplodeStringEx( pieces, 6, 63, bannedInfo, '|' )
	get_user_authid( id, authid, charsmax( authid ) )
	
	timeLeft = str_to_num( pieces[5] ) + str_to_num( pieces[3] ) * 60  - get_systime()
	get_time_length( id, bannedTime = str_to_num( pieces[3] ) * 60, timeunit_seconds, bannedFor, charsmax( bannedFor ) )
	get_time_length( id, timeLeft, timeunit_seconds, timeRemaining, charsmax( timeRemaining ) )
	
	if ( timeLeft < 0 && bannedTime > 0 )
		return
	
	console_print( id, "This server is running Apollo RP Bans." )
	console_print( id, "You are banned from this server." )
	console_print( id, "--------------------------------" )
	console_print( id, "Your name when banned:    %s", pieces[0] )
	console_print( id, "Your Steam ID:            %s", authid )
	console_print( id, "Administrator name:       %s", pieces[1] )
	console_print( id, "Administrator Steam ID:   %s", pieces[2] )
	if ( bannedTime )
	{
		console_print( id, "Banned for:               %s", bannedFor )
		console_print( id, "Ban time remaining:       %s", timeRemaining )
	}
	else
		console_print( id, "Banned for:               Permanently" )
	console_print( id, "Reason:                   %s", pieces[4] )
	
	new temp[64]
	if ( bannedTime )
		formatex( temp, charsmax( temp ), "banned for %d minutes total [rejoin in %d]",floatround( bannedTime / 60.0 - 0.01, floatround_ceil ), floatround( timeLeft / 60.0 - 0.01, floatround_ceil ) )
	else
		formatex( temp, charsmax( temp ), "banned permanently" )
	
	if ( strlen( pieces[4] ) > 1 )
		server_cmd( "kick #%d ^"%s (%s)^"", get_user_userid( id ), pieces[4], temp )
	else
		server_cmd( "kick #%d ^"%s^"", get_user_userid( id ), temp )
}

ExplodeStringEx( Output[][], Max, Size, Input[], Delimiter )
{
    new Idx, l = strlen(Input), Len;
    do Len += (1 + copyc( Output[Idx], Size, Input[Len], Delimiter ));
    while( (Len < l) && (++Idx < Max) )
    return Idx;
}
#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>
#include <hamsandwich>
#include <tsx>
#include <tsfun>
#include <fakemeta>

new Float:gOffMap[3]

new pRespawnTime

new Float:gDead[33]

new gMsgTSFade
new gMsgDeathMsg

new gMaxPlayers

public plugin_init()
{
	//register_plugin( "Death Fix", "1.0", "Hawk552" )
	ARP_RegisterPlugin( "Death Fix", "1.0", "Hawk552", "Fixes crashes on death" )

	ARP_RegisterEvent( "Player_Die", "EventPlayerDeath" )
	ARP_RegisterEvent( "HUD_Render", "EventHUDRender" )
	ARP_RegisterEvent( "Chat_Message", "EventChatMessage" )

	RegisterHam( Ham_Killed, "player", "HamKilled" )
	RegisterHam( Ham_TakeDamage, "player", "HamTakeDamage" )
	RegisterHam( Ham_Spawn, "player", "HamSpawn" )
	
	register_forward( FM_UpdateClientData, "ForwardUpdateClientDataPost", 1 )
	register_forward( FM_Touch, "ForwardTouch" )

	gMsgTSFade = get_user_msgid( "TSFade" )
	gMsgDeathMsg = get_user_msgid( "DeathMsg" )

	pRespawnTime = register_cvar( "arp_respawn_time", "10.0" )

	gMaxPlayers = get_maxplayers()

	set_task( 1.0, "BlindAll", .flags = "b" )
	
	gOffMap = Float:{ 4096.0, 4096.0, 4096.0 }
}

public ForwardTouch( ptr, ptd )
	return ( 1 <= ptr <= 32 && gDead[ptr] ) || ( 1 <= ptd <= 32 && gDead[ptd] ) ? FMRES_SUPERCEDE : FMRES_IGNORED

public ForwardUpdateClientDataPost( id, sendWeapons, cdHandle )
{
    if ( !is_user_alive( id ) || !gDead[id] )
        return FMRES_IGNORED
    
    set_cd( cdHandle, CD_ID, 0 )
    
    return FMRES_HANDLED
}

public EventChatMessage( name[], data[], len )
{
	new id = data[0], target = data[1]
	if ( id > 32 || id < 0 )
		id = 0
	if ( target > 32 || target < 0 )
		target = 0
	
	if ( gDead[id] || gDead[target] )
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public EventHUDRender( const name[], const data[], len )
{
	new id = data[0], channel = data[1]
	if ( channel != HUD_QUAT || !gDead[id] )
		return
	
	new timeLeft = floatround( get_pcvar_float( pRespawnTime ) - get_gametime() + gDead[id], floatround_ceil )
	if ( timeLeft > 0 )
	{
		// fail for ARP_ClientPrint
		static text[64]
		formatex( text, charsmax( text ), "You must wait %d seconds to spawn.", timeLeft )
		ARP_ClientPrint( id, text )
	}
	else
		ARP_ClientPrint( id, "Press attack to spawn." )
}

public client_PreThink( id )
	if ( gDead[id] )
	{
		if ( !is_user_alive( id ) )
			gDead[id] = 0.0
		
		new button = entity_get_int( id, EV_INT_button )
		entity_set_int( id, EV_INT_button, 0 )
	
		if ( button & ( IN_ATTACK | IN_ATTACK2 ) && !( entity_get_int( id, EV_INT_oldbuttons ) & ( IN_ATTACK | IN_ATTACK2 ) ) 
		&& get_gametime() - gDead[id] > get_pcvar_float( pRespawnTime ) )
		{
			static ents[64]
			new ent, num
			while ( ( ent = find_ent_by_class( ent, "info_player_deathmatch" ) ) )
				ents[num++] = ent 
			ent = 0
			while ( ( ent = find_ent_by_class( ent, "info_player_start" ) ) )
				ents[num++] = ent 
			
			new Float:origin[3]
			entity_get_vector( ents[random_num( 0, num )], EV_VEC_origin, origin )
			
			if ( origin[0] > 4095.0 || origin[1] > 4095.0 || origin[2] > 4095.0
			|| origin[0] < -4095.0 || origin[1] < -4095.0 || origin[2] < -4095.0
			|| -0.1 <= origin[0] <= 0.1 || -0.1 <= origin[1] <= 0.1 || -0.1 <= origin[2] <= 0.1 )
			{
				entity_set_int( id, EV_INT_oldbuttons, 0 )
				return
			}
			
			entity_set_origin( id, origin )
			entity_set_float( id, EV_FL_health, 100.0 )
			entity_set_int( id, EV_INT_solid, SOLID_BBOX )
			entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) & ~EF_NODRAW )
			
			BlindUser( id, 0 )
			
			ARP_ItemDone( id )
				
			gDead[id] = 0.0
		}
	}

public EventPlayerDeath( const name[], const data[], len )
	return BlockKilled( data[0], data[1] )

public HamSpawn( id )
{
	if ( !is_user_connected( id ) )
		return HAM_IGNORED
	
	BlindUser( id, 0 )
	
	gDead[id] = 0.0
	ARP_ItemDone( id )
	
	return HAM_IGNORED
}

public client_disconnect( id )
	gDead[id] = 0.0

public BlindAll()
	for ( new id = 1; id <= gMaxPlayers; id++ )
		if ( !is_user_alive( id ) || gDead[id] )
			BlindUser( id, 1 )

public HamKilled( id )
{
	BlockKilled( id, 0 )
	set_msg_block( gMsgDeathMsg, BLOCK_ONCE )
}

BlockKilled( id, killer )
{
	new Float:curTime = get_gametime()
	if ( curTime - gDead[id] < 1.0 )
		return PLUGIN_HANDLED
	
	ARP_ItemSet( id )
	
	client_print( id, print_chat, "[ARP] You have died." )
	
	entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) | EF_NODRAW )
	entity_set_vector( id, EV_VEC_origin, gOffMap )
	entity_set_origin( id, gOffMap )
	entity_set_int( id, EV_INT_solid, SOLID_NOT )
	
	for ( new count = 1; count <= 35; count++ )
		client_cmd( id, "weapon_%d;drop", count )
	
	new name[33]
	if ( 1 <= killer <= 32 )
	{
		new garbage, weapon = ts_getuserwpn( killer, garbage, garbage, garbage )
		xmod_get_wpnname( weapon ? weapon : TSW_KUNG_FU, name, 32 )
	}
	if ( !name[0] && killer )
		pev( killer, pev_classname, name, 32 )
	
	emessage_begin( MSG_ALL, gMsgDeathMsg )
	ewrite_byte( 1 <= killer <= 32 ? killer : 0 )
	ewrite_byte( id )
	ewrite_string( name )
	emessage_end()

	gDead[id] = curTime

	BlindUser( id, 1 )
	
	return PLUGIN_HANDLED
}

BlindUser( id, mode )
{
	if ( !is_user_connected( id ) )
		return
	
	message_begin( MSG_ONE_UNRELIABLE, gMsgTSFade, _, id )
	write_short( mode ? ~0 : 0 )
	write_short( ~0 )
	write_short( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 255 )
	message_end()
}

public HamTakeDamage( id, inflictor, attacker, Float:damage, damageBits )
{
	new Float:health = entity_get_float( id, EV_FL_health )
	if ( health - damage <= 0.0 )
	{
		SetHamParamFloat( 4, health - 1.0 )
		BlockKilled( id, attacker )
	}
	
	return HAM_IGNORED
}

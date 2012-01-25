#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <engine>
#include <ApolloRP>
#include <tsx>
#include <tsfun>

new gTazerSound[] = "arp/tazer.wav"

new gItemTazerAttachment

new gMsgScreenFade

new gLightningSprite

new gTazerAttachment[33]

new Float:gMaxSpeed[33]

public plugin_init()
{
	ARP_RegisterPlugin( "Tazer Attachment", "1.0", "Hawk552", "Extra attachment to shotguns which allows them to be used as tazers" )
	
	RegisterHam( Ham_TakeDamage, "player", "HamTakeDamage" )
	
	gMsgScreenFade = get_user_msgid( "ScreenFade" )
	
	register_event( "DeathMsg", "EventDeathMsg", "a" )
}

public plugin_precache()
{
	gLightningSprite = precache_model( "sprites/lgtning.spr" )
	precache_sound( gTazerSound )
}

public client_PreThink( id )
	if ( gMaxSpeed[id] )
		entity_set_float( id, EV_FL_maxspeed, 1.0 )

public HamTakeDamage( id, inflictor, attacker, Float:damage, damageType )
{
	if ( attacker > 32 || attacker < 1 || id > 32 || id < 1 || inflictor < 1 || inflictor > 32 )
		return HAM_IGNORED

	new garbage, weapon = ts_getuserwpn( attacker, garbage, garbage, garbage )	
	switch ( weapon )
	{
		case TSW_USAS, TSW_M3, TSW_SPAS:
		{
		}		
		default :
			return HAM_IGNORED
	}	
	
	if ( ( weapon == TSW_USAS && 49.9 <= damage <= 50.1 )
	||	 ( weapon == TSW_M3 && 34.9 <= damage <= 35.1 )
	||	 9.9 <= damage <= 10.9 )
		return HAM_IGNORED
		
	if ( gTazerAttachment[attacker] )
	{		
		new pOrigin[3],tOrigin[3]
		get_user_origin( id, pOrigin )
		get_user_origin( attacker, tOrigin )
		
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_BEAMPOINTS )
		write_coord( pOrigin[0] )
		write_coord( pOrigin[1] )
		write_coord( pOrigin[2] )
		write_coord( tOrigin[0] )
		write_coord( tOrigin[1] )
		write_coord( tOrigin[2] )
		write_short( gLightningSprite )
		write_byte( 1 ) // framestart
		write_byte( 5 ) // framerate
		write_byte( 8 ) // life
		write_byte( 20 ) // width
		write_byte( 30 ) // noise
		write_byte( 200 ) // r, g, b
		write_byte( 200 ) // r, g, b
		write_byte( 200 ) // r, g, b
		write_byte( 200 ) // brightness
		write_byte( 200 ) // speed
		message_end()

		//message_begin(MSG_PVS,SVC_TEMPENTITY,tOrigin)
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_SPARKS )
		write_coord( tOrigin[0] )
		write_coord( tOrigin[1] )
		write_coord( tOrigin[2] )
		message_end()
		
		if ( !gMaxSpeed[id] )
			gMaxSpeed[id] = entity_get_float( id, EV_FL_maxspeed )
		//g_SpeedMode[Index] = 0
		
		//ARP_SetUserSpeed( attacker, Speed_Mul, 0.5 )
		
		set_rendering( id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16 )
		
		emit_sound( id, CHAN_AUTO, gTazerSound, 1.0, ATTN_NORM, 0, PITCH_NORM )
		
		//fakedamage(Index,"Tazer",10.0,DMG_SHOCK /* 256 SHOCK */)
		
		//if(get_user_health(id) <= 0)
		//	return
			
		for ( new i = 1; i <= 35; i++ )
			client_cmd( id, "weapon_%d;drop", i )
		
		set_task( 1.0, "ScreenFade", id + 1273821 )
		//set_task( 2.0, "HeartBeat", id )
		if ( task_exists( id ) )
			remove_task( id )
		set_task( 5.0, "Clear", id )
		
		SetHamParamFloat( 4, 0.0 )
	}   
	
	return HAM_IGNORED
}

public ScreenFade( id )
{
	id -= 1273821
	
	new fadeTime = floatround( ( 1<<10 ) * 10.0 * ( 3 ) ) 
	
	message_begin( MSG_ONE_UNRELIABLE, gMsgScreenFade, _, id )
	write_short( fadeTime )
	write_short( fadeTime ) 
	write_short( 0x0000 ) 
	write_byte( 0 ) 
	write_byte( 0 )  
	write_byte( 0 )   
	write_byte( 255 )
	message_end()
}

public Clear( id )
{
	new Float:punch[3]
	
	for ( new i; i <= 2; i++ )
		punch[i] = random_float( -50.0, 50.0 )
	
	entity_set_vector( id, EV_VEC_punchangle, punch )
	
	//entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id])
	//g_MaxSpeed[id] = 0.0
	
	//ARP_SetUserSpeed( id, Speed_Mul, 2.0 )
	entity_set_float( id, EV_FL_maxspeed, gMaxSpeed[id] )
	gMaxSpeed[id] = 0.0
	
	set_rendering( id, kRenderFxNone, 255, 255, 255, kRenderNormal, 16 )
}

public ARP_RegisterItems()
	gItemTazerAttachment = ARP_RegisterItem( "Tazer Attachment", "ItemTazerAttachment", "Makes all shotgun rounds tazer their targets" )

public ItemTazerAttachment( id, itemId )
{
	new garbage, weapon = ts_getuserwpn( id, garbage, garbage, garbage )	
	switch ( weapon )
	{
		case TSW_USAS, TSW_M3, TSW_SPAS:
		{
		}		
		default :
		{
			client_print( id, print_chat, "[APR] You are not wielding a shotgun." )
			return PLUGIN_HANDLED
		}
	}	
	
	gTazerAttachment[id] = !gTazerAttachment[id]
	client_print( id, print_chat, "[ARP] You have %sabled your tazer attachment.", gTazerAttachment[id] ? "en" : "dis" )
	
	return PLUGIN_HANDLED
}

public client_disconnect( id )
{
	gMaxSpeed[id] = 0.0
	gTazerAttachment[id] = 0
}

public EventDeathMsg()
	client_disconnect( read_data( 2 ) )
#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <hamsandwich>
#include <tsx>
#include <tsfun>
#include <fakemeta>

new gMaxPlayers

new gMsgTSFade

new pRegenTime

new gLastHealth[33]

public ARP_Init()
{
	ARP_RegisterPlugin( "Combat Mod", "1.0", "Hawk552", "Modifies combat" )
	
	set_task( 5.0, "HealAll" )
	set_task( 1.0, "BlindAll", _, _, _, "b" )
	
	//Ignore the hits if it is from TSW_KUNG_FU
	register_forward( FM_TraceLine, "ForwardTraceLine", 1 )
	register_forward( FM_TraceHull, "ForwardTraceHull", 1 )

}

public plugin_init()
{
	RegisterHam( Ham_TakeDamage, "player", "HamTakeDamage" )
	
	gMaxPlayers = get_maxplayers()
	
	gMsgTSFade = get_user_msgid( "TSFade" )
	
	pRegenTime = register_cvar( "arp_regen_time", "2" )
}

public HealAll()
{
	for ( new id = 1, health; id <= gMaxPlayers; id++ )
		if ( is_user_alive( id ) )
		{
			health = get_user_health( id )
			if ( health < 100 )
			{
				set_user_health( id, health + 1 )
				if ( gLastHealth[id] < 20 && health + 1 >= 20 )
				{
					BlindUser( id, 0 )
					client_print( id, print_chat, "[ARP] You have recovered from your wounds." )
					ARP_SetUserSpeed( id, Speed_None )
					set_user_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 255 )
				}
			}
			
			gLastHealth[id] = health + 1
		}
	
	new Float:regenTime = get_pcvar_float( pRegenTime )
	if ( regenTime >= 0.1 )
		set_task( regenTime, "HealAll" )
}

public BlindAll()
	for ( new id = 1; id <= gMaxPlayers; id++ )
		if ( is_user_alive( id ) && get_user_health( id ) < 20 )
			BlindUser( id, 1 )


BlindUser( id, mode )
{
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
	if ( attacker > 32 || attacker <= 0 )
		return HAM_IGNORED
	
	static dummy
	switch ( ts_getuserwpn( attacker, dummy, dummy, dummy ) )
	{
		case TSW_KUNG_FU, 0 :
			return HAM_SUPERCEDE
	}

	new health = get_user_health( id )
	if ( health - damage < 1 )
		SetHamParamFloat( 4, float( health - 1 ) )
	
	if ( health - damage < 20 && health > 20 )
	{
		BlindUser( id, 1 )
		client_print( id, print_chat, "[ARP] You are now blacking out from your wounds. You will recover shortly." )
		ARP_SetUserSpeed( id, Speed_Override, 0.1 )
		set_user_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 90 )
	}
	
	return HAM_IGNORED
}

public client_PreThink( id )
	if ( get_user_health( id ) < 20 )
	{		
		// thanks to harbu for this part, although it's pretty easy to replicate
		new bufferstop = entity_get_int(id,EV_INT_button)

		if(bufferstop != 0)
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK & ~IN_ATTACK2 & ~IN_ALT1 & ~IN_USE)

		if((bufferstop & IN_JUMP) && (entity_get_int(id,EV_INT_flags) & ~FL_ONGROUND & ~FL_DUCKING))
			entity_set_int(id,EV_INT_button,entity_get_int(id,EV_INT_button) & ~IN_JUMP)
	}

public ForwardTraceLine(Float:v1[3],Float:v2[3],NoMonsters,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new garbage
	switch(ts_getuserwpn(SkipEnt,garbage,garbage,garbage,garbage))
	{
		case TSW_KUNG_FU, 0: {}
		default: return FMRES_IGNORED
	}
	
	new Ptr2
	engfunc(EngFunc_TraceLine,v1,v2,NoMonsters,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(is_user_alive(Hit))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED
}

public ForwardTraceHull(Float:v1[3],Float:v2[3],NoMonsters,Hull,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new garbage
	switch(ts_getuserwpn(SkipEnt,garbage,garbage,garbage,garbage))
	{
		case TSW_KUNG_FU, 0: {}
		default: return FMRES_IGNORED
	}
	
	new Ptr2
	engfunc(EngFunc_TraceHull,v1,v2,NoMonsters,Hull,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(is_user_alive(Hit))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED	
}
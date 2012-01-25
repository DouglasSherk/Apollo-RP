#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <ApolloRP>
#include <ApolloRP_Zone>

#define MAX_ZONES 32

new Trie:gZones

public plugin_init()
{
	ARP_RegisterPlugin( "PvP Mode", "1.0", "Hawk552", "Enables PvP zones" )
	
	ARP_RegisterEvent( "HUD_Render", "EventHUDRender" )
	
	gZones = TrieCreate()
	
	new file = ARP_FileOpen( "pvp.ini", "r" )
	if ( !file )
	{
		log_amx( "Error opening file: pvp.ini" )
		return
	}
	
	new buffer[33]
	while ( !feof( file ) )
	{
		fgets( file, buffer, charsmax( buffer ) )
		replace( buffer, charsmax( buffer ), "^n", "" )
		
		if ( strlen( buffer ) > 1 )
			TrieSetString( gZones, buffer, "" )
	}
	fclose( file )
	
	RegisterHam( Ham_TakeDamage, "player", "HamTakeDamage" )
	
	register_forward( FM_TraceLine, "ForwardTraceLine", 1 )
	register_forward( FM_TraceHull, "ForwardTraceHull", 1 )
}

public EventHUDRender( const name[], const data[], len )
{
	new id = data[0]
	if ( !is_user_alive( id ) || !ARP_PlayerReady( id ) || ARP_SqlHandle() == Empty_Handle || data[1] != HUD_PRIM )
		return
	
	static zone[33]
	ARP_GetUserZone( id, zone, 32 )
	
	if ( TrieKeyExists( gZones, zone ) )
		ARP_AddHudItem( id, HUD_PRIM, 0, "PvP Zone" )
}

public HamTakeDamage( id, inflictor, attacker, Float:damage, damageBits )
{
	if ( attacker > 32 || attacker < 1 || id < 1 || id > 32 )
		return HAM_IGNORED
	
	new zone[33]
	ARP_GetUserZone( id, zone, 32 )
	if ( !TrieKeyExists( gZones, zone ) )
	{
		SetHamParamFloat( 4, 0.0 )
		return HAM_IGNORED
	}
	
	ARP_GetUserZone( attacker, zone, 32 )
	if ( !TrieKeyExists( gZones, zone ) )
	{
		SetHamParamFloat( 4, 0.0 )
		return HAM_IGNORED
	}
	
	return HAM_IGNORED
}

public ForwardTraceLine(Float:v1[3],Float:v2[3],NoMonsters,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt) || !( 1 <= SkipEnt <= 32 ) )
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceLine,v1,v2,NoMonsters,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(SkipEnt != Hit && 1 <= Hit <= 32 && is_user_connected(Hit))
	{
		static zone[33]
		ARP_GetUserZone( Hit, zone, 32 )
		if ( !TrieKeyExists( gZones, zone ) )
		{
			set_tr(TR_flFraction,1.0)
			return FMRES_IGNORED
		}
	}
	
	return FMRES_IGNORED
}

public ForwardTraceHull(Float:v1[3],Float:v2[3],NoMonsters,Hull,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt) || !( 1 <= SkipEnt <= 32 ) )
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceHull,v1,v2,NoMonsters,Hull,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if(SkipEnt != Hit && 1 <= Hit <= 32 && is_user_connected(Hit))
	{
		static zone[33]
		ARP_GetUserZone( Hit, zone, 32 )
		if ( !TrieKeyExists( gZones, zone ) )
		{
			set_tr(TR_flFraction,1.0)
			return FMRES_IGNORED
		}
	}
	
	return FMRES_IGNORED	
}
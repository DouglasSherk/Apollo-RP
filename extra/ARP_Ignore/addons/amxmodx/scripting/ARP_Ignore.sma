#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <engine>
#include <hamsandwich>
#include <fun>
#include <fakemeta>

new Float:gLastIgnore[33]
new gMarked[33][33]
new gPlayerSolid[33]
new gMaxPlayers

public ARP_Init()
{
	ARP_RegisterPlugin( "Ignore Mod", "1.0", "Hawk552", "Allows players to ignore each other" )
	gMaxPlayers = get_maxplayers()
}

public plugin_init()
{
	ARP_AddChat( _, "CmdSay" )

	ARP_AddCommand( "say /ignore <name>", "toggles ignoring a player" )
	
	ARP_RegisterEvent( "Chat_Message", "EventChatMessage" )
    
	register_forward( FM_TraceLine, "ForwardTraceLine", 1 )
	register_forward( FM_TraceHull, "ForwardTraceHull", 1 )
	RegisterHam( Ham_TakeDamage, "player", "HamTakeDamagePre", 0 )
	register_forward( FM_AddToFullPack, "ForwardAddToFullPack", 1 )
	register_forward( FM_PlayerPreThink, "ForwardPlayerPreThink" )
	register_forward( FM_PlayerPostThink, "ForwardPlayerPostThink" )
}

public EventChatMessage( name[], data[], len )
{
	new id = data[0], target = data[1]
	if ( id > 32 || id < 0 )
		id = 0
	if ( target > 32 || target < 0 )
		target = 0
	
	if ( gMarked[id][target] || gMarked[target][id] )
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public client_disconnect( id )
	for ( new index = 1; index <= gMaxPlayers; index++ )
		gMarked[id][index] = gMarked[index][id] = 0

public HamTakeDamagePre( victim, inflictor, attacker, Float:damage, damageBits )
{
	if ( attacker > 32 || attacker < 1 )
		return HAM_IGNORED

	if( gMarked[victim][attacker] || gMarked[attacker][victim] )
		SetHamParamFloat( 4, 0.0 )

	return HAM_IGNORED
}

public ForwardAddToFullPack(ES,e,Ent,Host,HostFlags,Player,pSet)
{
	if(Player && is_user_alive(Host) && is_user_alive(Ent) && (gMarked[Host][Ent] || (gMarked[Ent][Host]) ) )
	{
		//set_es(ES,ES_RenderMode,kRenderTransAlpha)
		//set_es(ES,ES_RenderFx,kRenderFxGlowShell)
		//set_es(ES,ES_RenderAmt,0)
		set_es(ES,ES_Solid,SOLID_NOT)
		set_es(ES,ES_Effects,get_es(ES,ES_Effects)|EF_NODRAW)
		set_es(ES,ES_Origin,Float:{-4096.0,-4096.0,-4096.0})
	}
	
	return FMRES_IGNORED
}
	
public CmdSay( id, mode, args[] )
{
	if ( equali( args, "/ignore", 7 ) )
	{
		new target[33], temp[2]
		parse( args, temp, 1, target, 32 )
		
		new name[33] 
		get_user_name( id, name, 32 )
		
		new index = cmd_target( id, target, 0 ), Float:curTime = get_gametime()
		if ( !index )
		{
			client_print( id, print_chat, "[ARP] Could not find a user matching your input." )
			return PLUGIN_HANDLED
		}
		else if ( ARP_IsCop( index ) )
		{
			client_print( id, print_chat, "[ARP] You cannot ignore a cop." )
			return PLUGIN_HANDLED
		}
		else if ( id == index )
		{
			client_print( id, print_chat, "[ARP] You cannot ignore yourself." )
			return PLUGIN_HANDLED
		}
		else if ( gLastIgnore[id] && curTime - gLastIgnore[id] < 120.0 )
		{
			client_print( id, print_chat, "[ARP] You must wait two minutes before ignoring again." )
			return PLUGIN_HANDLED
		}
		
		gLastIgnore[id] = curTime
		
		get_user_name( index, target, 32 )
		
		if ( ( gMarked[id][index] = !gMarked[id][index] ) )
		{
			client_print( id, print_chat, "[ARP] You are now ignoring %s.", target )
			client_print( index, print_chat, "[ARP] %s is now ignoring you.", name )
		}
		else
		{
			client_print( id, print_chat, "[ARP] You are no longer ignoring %s.", target )
			client_print( index, print_chat, "[ARP] %s is no longer ignoring you.", name )
		}
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public ForwardTraceLine(Float:v1[3],Float:v2[3],NoMonsters,SkipEnt,Ptr)
{
	if( !( 1 <= SkipEnt <= 32 ) || !is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceLine,v1,v2,NoMonsters,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if( SkipEnt != Hit && 1 <= Hit <= 32 && is_user_alive(Hit) && (gMarked[Hit][SkipEnt] || (gMarked[SkipEnt][Hit]) ))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED
}

public ForwardTraceHull(Float:v1[3],Float:v2[3],NoMonsters,Hull,SkipEnt,Ptr)
{
	if(!is_user_alive(SkipEnt))
		return FMRES_IGNORED
	
	new Ptr2
	engfunc(EngFunc_TraceHull,v1,v2,NoMonsters,Hull,SkipEnt,Ptr2)
	new Hit = get_tr2(0,TR_pHit)
	if( SkipEnt != Hit && 1 <= Hit <= 32 && is_user_alive(Hit) && (gMarked[Hit][SkipEnt] || (gMarked[SkipEnt][Hit]) ))
		set_tr(TR_flFraction,1.0)
	
	return FMRES_IGNORED	
}

public ForwardPlayerPreThink(id)
{	
	for(new Count = 1;Count <= gMaxPlayers;Count++)
	{
		if(!is_user_connected(Count) || Count == id || (!gMarked[id][Count] && !gMarked[Count][id]))
			continue
		
		gPlayerSolid[Count] = pev(Count,pev_solid)
		set_pev(Count,pev_solid,SOLID_NOT)
	}
	
	return FMRES_IGNORED
}

public ForwardPlayerPostThink(id)
{
	for(new Count = 1;Count <= gMaxPlayers;Count++)
	{
		if(!is_user_connected(Count) || Count == id || (!gMarked[id][Count] && !gMarked[Count][id]))
			continue
		
		set_pev(Count,pev_solid,gPlayerSolid[Count])
	}
	
	return FMRES_IGNORED
}
#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <hamsandwich>
#include <tsx>
#include <tsfun>
#include <fakemeta>
#include <xs>

new TravTrie:gMonsterSpawns

new gModel[] = "models/player/gordon/gordon.mdl"
new gClassname[] = "monster_arp_civilian"

enum MODES
{
	NORMAL = 0,
	// Last Known Position
	TALKING
}

public ARP_Init()
{
	ARP_RegisterPlugin( "Monster Mod - Civilian", "1.0", "Hawk552", "Fills the maps with civilians" )
	
	new file = ARP_FileOpen( "monsters-civilian.ini", "r" )
	if ( !file )
	{
		log_amx( "Error opening file: monsters-civilian.ini" )
		return
	}
	
	gMonsterSpawns = TravTrieCreate()
	
	new buffer[128], TravTrie:current, left[33], right[33]
	while ( !feof( file ) )
	{
		fgets( file, buffer, charsmax( buffer ) )
		replace( buffer, charsmax( buffer ), "^n", "" )
		
		if ( !buffer[0] || buffer[0] == ';' ) 
			continue
		
		if ( buffer[0] == '{' )
		{
			current = TravTrieCreate()
			//log_amx("Creating travtrie: %d",Reading)
			continue
		}
		else if ( buffer[0] == '}' )
		{
			TravTrieSetString( current, "lastSpawn", "0" )
			TravTrieSetCellEx( gMonsterSpawns, _:current, 0 )
			
			current = Invalid_TravTrie
			
			continue
		}
		
		static TravTrie:temp
		temp = current
		if ( current )
		{						
			parse( buffer, left, charsmax( left ), right, charsmax( right ) )
			trim( left )
			remove_quotes( left )
			trim( right )
			remove_quotes( right )
			
			if ( !buffer[0] || buffer[0] == ';' || strlen( buffer ) < 5 ) 
				continue
			
			if ( !current )
				current = temp
			
			TravTrieSetString( current, left, right )
		}
	}
	
	fclose( file )
	
	set_task( 10.0, "CheckSpawns", _, _, _, "b" )
}

public CheckSpawns()
{
	new travTrieIter:iter = GetTravTrieIterator( gMonsterSpawns ), TravTrie:key, garbage, 
		Float:origin[3], originPieces[3][11], Float:fraction, hit, solid,
		maxNum, num, ent, temp[33], Float:delay, Float:curTime = get_gametime()
		
	while ( MoreTravTrie( iter ) )
	{
		ReadTravTrieKeyEx( iter, _:key )
		ReadTravTrieCell( iter, garbage )
		
		TravTrieGetString( key, "num", temp, charsmax( temp ) )
		maxNum = str_to_num( temp )
		
		ent = num = 0
		while ( ( ent = find_ent_by_class( ent, gClassname ) ) )
			if ( pev( ent, pev_iuser1 ) == _:key )
				num++
			
		for ( new i = 1; i <= 2048; i++ )
		{
			if ( !pev_valid( i ) )
				continue
			
			static className[33]
			pev( i, pev_netname, className, 32 )
			
			if ( equali( className, gClassname ) )
				num++
		}
			
		if ( num >= maxNum )
			continue
		
		TravTrieGetString( key, "delay", temp, charsmax( temp ) )
		delay = str_to_float( temp )
		
		TravTrieGetString( key, "lastSpawn", temp, charsmax( temp ) )
		if ( curTime - str_to_float( temp ) < delay )
			continue
		
		TravTrieGetString( key, "origin", temp, charsmax( temp ) )
		parse( temp, originPieces[0], 10, originPieces[1], 10, originPieces[2], 10 )
		origin[0] = str_to_float( originPieces[0] )
		origin[1] = str_to_float( originPieces[1] )
		origin[2] = str_to_float( originPieces[2] )
		
		// Something is obstructing it.
		engfunc( EngFunc_TraceHull, origin, origin, 0, HULL_HUMAN, 0, 0 )
		global_get( glb_trace_fraction, fraction )
		hit = global_get( glb_trace_ent )
		solid = is_valid_ent( hit ) ? pev( hit, pev_solid ) : 0
		if ( ( solid != SOLID_NOT && solid != SOLID_TRIGGER ) || fraction < 1.0 )
			continue
		
		SpawnMonster( _:key, origin )
		float_to_str( curTime, temp, charsmax( temp ) )
		TravTrieSetString( key, "lastSpawn", temp )
	}
	
	DestroyTravTrieIterator( iter )
}

public plugin_precache()
{
	precache_model( gModel )
	//gWeaponSprite = precache_model( "sprites/gun_muzzle.spr" )
}

public plugin_init()
	//register_think( gClassname, "EventThink" )
	register_forward( FM_Think, "ForwardThink" )

public CivilianHandle( id, ent )
{
	client_print( id, print_chat, "Civilian: Hello." )
	set_pev( ent, pev_iuser2, TALKING )
	set_pev( ent, pev_euser1, id )
	set_pev( ent, pev_fuser1, get_gametime() )
}

public SpawnMonster( tag, Float:origin[3] )
{
	new ent = ARP_RegisterNpc( "Civilian", origin, 0.0, gModel, "CivilianHandle" )
	entity_set_string( ent, EV_SZ_netname, gClassname )
	entity_set_int( ent, EV_INT_flags, FL_MONSTER )
	entity_set_int( ent, EV_INT_fixangle, 1 )
	entity_set_model( ent, gModel )
	//entity_set_origin( ent, gOrigin )
	entity_set_origin( ent, origin )
	entity_set_size( ent, Float:{ -16.0, -16.0, -36.0 }, Float:{ 16.0, 16.0, 36.0 } )
	entity_set_int( ent, EV_INT_solid, SOLID_BBOX )
	entity_set_int( ent, EV_INT_movetype, MOVETYPE_PUSHSTEP )
	entity_set_byte( ent, EV_BYTE_controller1, 125 )
	entity_set_byte( ent, EV_BYTE_controller2, 125 )
	entity_set_byte( ent, EV_BYTE_controller3, 125 )
	entity_set_byte( ent, EV_BYTE_controller4, 125 )
	entity_set_int( ent, EV_INT_sequence, 24 )
	entity_set_float( ent, EV_FL_gravity, 1.0 )
	entity_set_float( ent, EV_FL_friction, 1.0 )
	entity_set_float( ent, EV_FL_animtime, 2.0 )
	entity_set_float( ent, EV_FL_framerate, 1.0 )
	//entity_set_float( ent, EV_FL_health, 100.0 )
	//entity_set_float( ent, EV_FL_takedamage, DAMAGE_AIM )
	entity_set_float( ent, EV_FL_nextthink, 0.1 + get_gametime() )
	drop_to_floor( ent )
	
	// ARP-specific stuff
	// Starting location
	entity_set_vector( ent, EV_VEC_vuser1, origin )
	// Tag (TravTrie)
	entity_set_int( ent, EV_INT_iuser1, tag )
	entity_set_int( ent, EV_INT_iuser2, _:NORMAL )
	
#if 0
	new weapon = create_entity( "info_target" )
	entity_set_string( weapon, EV_SZ_classname, "arp_monster_weapon" )
	entity_set_model( weapon, gWeaponModel )
	entity_set_edict( weapon, EV_ENT_aiment, ent )
	entity_set_int( weapon, EV_INT_movetype, MOVETYPE_FOLLOW )
#endif
	
	// Because of the drop to floor, it may be different now.
	pev( ent, pev_origin, origin )
	new target[3]
	FVecIVec( origin, target )
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, target )
	write_byte( TE_TELEPORT )
	write_coord( target[0] )
	write_coord( target[1] )
	write_coord( target[2] )
	message_end()
	
	return ent
}

public EventBodyThink( ent )
	remove_entity( ent )

public ForwardThink( ent )
{
	static className[33]
	pev( ent, pev_netname, className, 32 )
	if ( !equali( gClassname, className ) )
		return
	
	static Float:entOrigin[3], Float:plOrigin[3], Float:angles[3], Float:lastTalked, player
	new MODES:mode = MODES:pev( ent, pev_iuser2 )
	player = pev( ent, pev_euser1 )
	pev( ent, pev_fuser1, lastTalked )
	
	new Float:curTime = get_gametime()
	pev( ent, pev_origin, entOrigin )
			
	static Float:start[3], Float:target[3]
	pev( ent, pev_vuser1, start )
	pev( ent, pev_vuser2, target )
	
	static originStr[33], Float:boundaries1[3], Float:boundaries2[3], originPieces[3][11], Float:distance[3]
	//target = origin
	
	new TravTrie:travTrie = TravTrie:pev( ent, pev_iuser1 )
	
	switch ( mode )
	{
		case NORMAL :
		{
			TravTrieGetString( travTrie, "boundaries1", originStr, charsmax( originStr ) )
			parse( originStr, originPieces[0], 10, originPieces[1], 10, originPieces[2], 10 )
			boundaries1[0] = str_to_float( originPieces[0] )
			boundaries1[1] = str_to_float( originPieces[1] )
			boundaries1[2] = str_to_float( originPieces[2] )
			
			TravTrieGetString( travTrie, "boundaries2", originStr, charsmax( originStr ) )
			parse( originStr, originPieces[0], 10, originPieces[1], 10, originPieces[2], 10 )
			boundaries2[0] = str_to_float( originPieces[0] )
			boundaries2[1] = str_to_float( originPieces[1] )
			boundaries2[2] = str_to_float( originPieces[2] )
			
			if ( vector_length( target ) < 1.0 || vector_distance( entOrigin, target ) < 25.0 
				|| 	( vector_length( boundaries1 ) && vector_length( boundaries2 ) &&
						( entOrigin[0] < boundaries1[0] || entOrigin[1] < boundaries1[1] 
						|| entOrigin[0] > boundaries2[0] || entOrigin[1] > boundaries2[1] ) ) )
			{
				CalculateTarget( ent )
				pev( ent, pev_vuser2, target )
			}
			
			// The vector denoting the distance between the bot's origin and their target.
			distance[0] = target[0] - entOrigin[0]
			distance[1] = target[1] - entOrigin[1]
			
			xs_vec_normalize( distance, distance )
			xs_vec_mul_scalar( distance, 100.0, distance )
			
			target[0] = entOrigin[0] + distance[0]
			target[1] = entOrigin[1] + distance[1]
			target[2] = entOrigin[2]
			
			engfunc( EngFunc_TraceHull, entOrigin, target, 0, HULL_HUMAN, ent, 0 )
			
			new Float:fraction
			get_tr2( 0, TR_flFraction, fraction )
			
			if ( fraction < 0.999 && mode == NORMAL )	
			{			
				CalculateTarget( ent )
				pev( ent, pev_vuser2, target )
			}
		}
		
		case TALKING :
		{
			if ( is_user_connected( player ) && is_user_alive( player ) )
			{
				if ( curTime - lastTalked > 10.0 )
					set_pev( ent, pev_iuser2, NORMAL )
				
				pev( player, pev_origin, plOrigin )
				distance[0] = plOrigin[0] - entOrigin[0]
				distance[1] = plOrigin[1] - entOrigin[1]
				distance[2] = 0.0
			}
			else
				set_pev( ent, pev_iuser2, NORMAL )
		}
	}
	
	xs_vec_normalize( distance, distance )
			
	engfunc( EngFunc_VecToAngles, distance, angles )
	
	set_pev( ent, pev_angles, angles )
	
	set_pev( ent, pev_sequence, mode ? 1 : 17 )
	
	xs_vec_mul_scalar( distance, mode ? 0.0 : 100.0, distance )
	entity_set_vector( ent, EV_VEC_velocity, distance )
	
	if ( !( pev( ent, pev_flags ) & ( FL_FLY | FL_SWIM ) ) )
		drop_to_floor( ent )
	
	entity_set_float( ent, EV_FL_nextthink, 0.1 + get_gametime() )
}

CalculateTarget( ent )
{
	static Float:origin[3], Float:target[3], originStr[33], Float:boundaries1[3], Float:boundaries2[3], originPieces[3][11]
	
	pev( ent, pev_origin, origin )
	target = origin
	
	new TravTrie:travTrie = TravTrie:pev( ent, pev_iuser1 ), yourBoundariesAreTooSmall
	
	TravTrieGetString( travTrie, "boundaries1", originStr, charsmax( originStr ) )
	parse( originStr, originPieces[0], 10, originPieces[1], 10, originPieces[2], 10 )
	boundaries1[0] = str_to_float( originPieces[0] )
	boundaries1[1] = str_to_float( originPieces[1] )
	boundaries1[2] = str_to_float( originPieces[2] )
	
	TravTrieGetString( travTrie, "boundaries2", originStr, charsmax( originStr ) )
	parse( originStr, originPieces[0], 10, originPieces[1], 10, originPieces[2], 10 )
	boundaries2[0] = str_to_float( originPieces[0] )
	boundaries2[1] = str_to_float( originPieces[1] )
	boundaries2[2] = str_to_float( originPieces[2] )
	
	if ( boundaries1[0] > boundaries2[0] || boundaries1[1] > boundaries2[1] || boundaries1[2] > boundaries2[2] )
	{
		if ( boundaries1[0] > boundaries2[0] )
			swap( boundaries1[0], boundaries2[0] )
		if ( boundaries1[1] > boundaries2[1] )
			swap( boundaries1[1], boundaries2[1] )
		if ( boundaries1[2] > boundaries2[2] )
			swap( boundaries1[2], boundaries2[2] )
		
		formatex( originStr, charsmax( originStr ), "%d %d %d", floatround( boundaries1[0] ), floatround( boundaries1[1] ), floatround( boundaries1[2] ) )
		TravTrieSetString( travTrie, "boundaries1", originStr )
		
		formatex( originStr, charsmax( originStr ), "%d %d %d", floatround( boundaries2[0] ), floatround( boundaries2[1] ), floatround( boundaries2[2] ) )
		TravTrieSetString( travTrie, "boundaries2", originStr )
	}

	if ( vector_length( boundaries1 ) && vector_length( boundaries2 ) )
		// Your boundaries suck if they're closer than that.
		while ( vector_distance( target, origin ) < 100.0 && yourBoundariesAreTooSmall++ < 50 )
		{
			target[0] = random_float( boundaries1[0], boundaries2[0] )
			target[1] = random_float( boundaries1[1], boundaries2[1] )
		}
	else
		while ( vector_distance( target, origin ) < 500.0 )
		{
			target = origin
			target[0] += random_float( -4096.0, 4096.0 )
			target[1] += random_float( -4096.0, 4096.0 )
		}
	
	if ( yourBoundariesAreTooSmall >= 50 )
		ARP_Log( "Boundaries are too small at: %f %f %f / %f %f %f", boundaries1[0], boundaries1[1], boundaries1[2], boundaries2[0], boundaries2[1], boundaries2[2] )
	
	set_pev( ent, pev_vuser2, target )
	set_pev( ent, pev_iuser2, NORMAL )
	
	return 1
}

swap( &any:a, &any:b )
{
	static temp
	temp = a
	a = b
	b = temp
}

stock bool:fm_is_ent_visible(index, entity) 
{
    new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
    pev(index, pev_origin, origin)
    pev(index, pev_view_ofs, view_ofs)
    xs_vec_add(origin, view_ofs, eyespos)

    new Float:entpos[3]
    pev(entity, pev_origin, entpos)
    engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

    switch (pev(entity, pev_solid)) {
        case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
    }
    
    new Float:fraction
    global_get(glb_trace_fraction, fraction)
    if (fraction == 1.0)
        return true

    return false
}

// the dot product is performed in 2d, making the view cone infinitely tall
// Patched by Hawk552 to actually work.
stock bool:fm_is_in_viewcone(index, ent) {
	new Float:point[3]
	pev(ent, pev_origin, point)
	
	new Float:angles[3]
	pev(index, pev_angles, angles)
	engfunc(EngFunc_MakeVectors, angles)
	global_get(glb_v_forward, angles)
	angles[2] = 0.0

	new Float:origin[3], Float:diff[3], Float:norm[3]
	pev(index, pev_origin, origin)
	xs_vec_sub(point, origin, diff)
	diff[2] = 0.0
	xs_vec_normalize(diff, norm)

	new Float:dot, Float:fov = M_PI / 2.0
	dot = xs_vec_dot(norm, angles)
	if (dot >= floatcos(fov))
		return true

	return false
}
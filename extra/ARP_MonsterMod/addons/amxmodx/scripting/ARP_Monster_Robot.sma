#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <hamsandwich>
#include <tsx>
#include <tsfun>
#include <fakemeta>
#include <xs>

new gMaxPlayers

new gMsgTSFade

new TravTrie:gMonsterSpawns

new gModel[] = "models/player/robot/robot.mdl"
new gClassname[] = "monster_arp_robot"

new gWeaponModel[] = "models/p_mp5k.mdl"
new gWeaponSound[] = "debris/zap1.wav"
//new gWeaponSprite

new gDeadBodyClassname[] = "monster_arp_robot_body"

new gSpriteLightning

enum MODES
{
	NORMAL = 0,
	// Last Known Position
	LKP
}

public ARP_Init()
{
	ARP_RegisterPlugin( "Monster Mod - Robot", "1.0", "Hawk552", "Fills the maps with monsters to be killed" )
	
	new file = ARP_FileOpen( "monsters-robot.ini", "r" )
	if ( !file )
	{
		log_amx( "Error opening file: monsters-robot.ini" )
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
	precache_sound( gWeaponSound )
	//gWeaponSprite = precache_model( "sprites/gun_muzzle.spr" )
	
	gSpriteLightning = precache_model("sprites/lgtning.spr") // Lightning sprite
}

public plugin_init()
{
	new ent = SpawnMonster( 0, Float:{ 0.0, 0.0, 0.0 } )
	RegisterHamFromEntity( Ham_TakeDamage, ent, "HamTakeDamage" )
	remove_entity( pev( ent, pev_euser3 ) )
	remove_entity( ent )
	
	gMaxPlayers = get_maxplayers()
	
	register_think( gClassname, "EventThink" )
	register_think( gDeadBodyClassname, "EventBodyThink" )
	
	register_forward( FM_EmitSound, "ForwardEmitSound" )
	
	gMsgTSFade = get_user_msgid( "TSFade" )
}

public client_PreThink( id )
{
	new button = pev( id, pev_button ) & ( IN_ATTACK | IN_JUMP )
	static Float:velocity[3]
	pev( id, pev_velocity, velocity )
	
	if ( vector_length( velocity ) > 250.0 || button )
		ForwardEmitSound( id, 0, "" )
}

public ForwardEmitSound( id, channel, sound[] )
{
	if ( !is_user_alive( id ) )
		return FMRES_IGNORED
	
	new ent, target
	while ( ( ent = find_ent_by_class( ent, gClassname ) ) )
	{
		target = pev( ent, pev_euser1 )
		if ( get_entity_distance( id, ent ) < 500 && ( !is_user_alive( target ) || !fm_is_ent_visible( target, ent ) ) && fm_is_ent_visible( id, ent ) )
		{
			set_pev( ent, pev_euser1, id )
			set_pev( ent, pev_euser2, id )
		}
	}
	
	return FMRES_IGNORED
}

IsTriggerHurt( ent )
{
	new className[33]
	pev( ent, pev_classname, className, 32 )
	
	return equali( className, "trigger_hurt" )
}

public HamTakeDamage( ent, inflictor, attacker, Float:damage, damageBits )
{
	new model[33]
	pev( ent, pev_model, model, 32 )
	
	if ( !equali( model, gModel ) )
		return HAM_IGNORED
	
	if ( inflictor && IsTriggerHurt( inflictor ) )
	{
		SetHamParamFloat( 4, 0.0 )
		return HAM_SUPERCEDE
	}
	
	if ( attacker && IsTriggerHurt( attacker ) )
	{
		SetHamParamFloat( 4, 0.0 )
		return HAM_SUPERCEDE
	}
	
	new Float:health
	pev( ent, pev_health, health )
	
	if ( health - damage <= 0.0 )
	{
		SetHamParamFloat( 4, health - 1.0 )
		
		new Float:origin[3], Float:angles[3]
		pev( ent, pev_origin, origin )
		pev( ent, pev_angles, angles )
		
		remove_entity( pev( ent, pev_euser3 ) )
		
		entity_set_string( ent, EV_SZ_classname, gDeadBodyClassname )
		entity_set_int( ent, EV_INT_solid, SOLID_NOT )
		entity_set_int( ent, EV_INT_sequence, 31 )
		entity_set_float( ent, EV_FL_nextthink, get_gametime() + 10.0 )
	}
	
	if ( is_valid_ent( attacker ) )
	{
		if ( is_user_alive( attacker ) )
			set_pev( ent, pev_euser1, attacker )
		
		static Float:origin[3], target[3], Float:attackerOrigin[3], Float:direction[3]
		pev( ent, pev_origin, origin )
		FVecIVec( origin, target )
		pev( attacker, pev_origin, attackerOrigin )
		
		direction[0] = attackerOrigin[0] - origin[0]
		direction[1] = attackerOrigin[1] - origin[1]
		direction[2] = attackerOrigin[2] - origin[2]
		
		message_begin( MSG_PVS, SVC_TEMPENTITY, target )
		write_byte( TE_BLOOD )
		write_coord( target[0] )
		write_coord( target[1] )
		write_coord( target[2] )
		FVecIVec( direction, target )
		write_coord( target[0] )
		write_coord( target[1] )
		write_coord( target[2] )
		write_byte( 247 )
		write_byte( 30 )
		message_end()
	}
	
	return HAM_IGNORED
}

public SpawnMonster( tag, Float:origin[3] )
{
	new ent = create_entity( "info_target" )
	entity_set_string( ent, EV_SZ_netname, "Man in Black" )
	entity_set_string( ent, EV_SZ_classname, gClassname )
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
	entity_set_float( ent, EV_FL_health, 500.0 )
	entity_set_float( ent, EV_FL_takedamage, DAMAGE_AIM )
	entity_set_float( ent, EV_FL_nextthink, 0.1 + get_gametime() )
	drop_to_floor( ent )
	
	// ARP-specific stuff
	// Starting location
	entity_set_vector( ent, EV_VEC_vuser1, origin )
	// Tag (TravTrie)
	entity_set_int( ent, EV_INT_iuser1, tag )
	
	new weapon = create_entity( "info_target" )
	entity_set_string( weapon, EV_SZ_classname, "arp_monster_weapon" )
	entity_set_model( weapon, gWeaponModel )
	entity_set_edict( weapon, EV_ENT_aiment, ent )
	entity_set_int( weapon, EV_INT_movetype, MOVETYPE_FOLLOW )
	entity_set_edict( ent, EV_ENT_euser3, weapon )
	
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

public EventThink( ent )
{
	static Float:entOrigin[3], Float:plOrigin[3], Float:direction[3], Float:angles[3], Float:lastShot, Float:lastSpot, origin[3], player, lkp, Float:mins[3]
	player = pev( ent, pev_euser1 )
	lkp = pev( ent, pev_euser2 )
	pev( ent, pev_fuser1, lastShot )
	pev( ent, pev_fuser2, lastSpot )
	
	new Float:curTime = get_gametime()
	pev( ent, pev_origin, entOrigin )
	
	if ( is_user_alive( player ) )
	{
		if ( pev( player,pev_flags ) & FL_NOTARGET )
		{
			set_pev( ent, pev_euser1, player = 0 )
			
			goto dontTarget
		}
		
		set_pev( ent, pev_sequence, 1 )
		
		new tooFar = get_entity_distance( player, ent ) > 1500
		if ( tooFar || !fm_is_ent_visible( player, ent ) )
		{
			if ( tooFar || curTime - lastSpot > 3.0 )
				set_pev( ent, pev_euser1, player = 0 )
			
			goto dontTarget
		}	
		
		pev( player, pev_origin, plOrigin )
		pev( player, pev_mins, mins )
		
		// Stunting.
		if ( mins[2] < -17.0 && !( pev( player, pev_button ) & IN_DUCK ) )
			plOrigin[2] -= 10.0
		
		set_pev( ent, pev_vuser2, plOrigin )
		set_pev( ent, pev_iuser2, LKP )
		
		set_pev( ent, pev_fuser2, curTime )
		
		xs_vec_sub( plOrigin, entOrigin, direction )
		
		engfunc( EngFunc_VecToAngles, direction, angles )
		set_pev( ent, pev_angles, angles )
		
		if ( curTime - lastShot > 1.5 )
		{
			static Float:target[3], endPos[3], hit
			
			angles[0] += random_float( -5.0, 5.0 )
			angles[1] += random_float( -5.0, 5.0 )
			angles[2] += random_float( -5.0, 5.0 )
			angles[0] *= -1
			
			angle_vector( angles, ANGLEVECTOR_FORWARD, direction )
			
			xs_vec_mul_scalar( direction, 1500.0, direction )
			xs_vec_add( entOrigin, direction, target )
			
			// Storing into angles although that's stupid.
			pev( ent, pev_origin, angles )
			FVecIVec( angles, origin )
			
#if 0
			message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
			write_byte( TE_SPRITE )
			write_coord( origin[0] )
			write_coord( origin[1] )
			write_coord( origin[2] )
			write_short( gWeaponSprite )
			write_byte( 10 )
			write_byte( 10 )
			message_end()
#endif
			
			engfunc( EngFunc_TraceLine, entOrigin, target, 0, ent, 0 )
			hit = global_get( glb_trace_ent )
			global_get( glb_trace_endpos, target )
			
			FVecIVec( target, endPos )
			
			set_pev( ent, pev_fuser1, curTime )
			
			emit_sound( ent, CHAN_AUTO, gWeaponSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )

#if 0
			message_begin( MSG_PVS, SVC_TEMPENTITY, origin )
			write_byte( TE_TRACER )
			write_coord( origin[0] )
			write_coord( origin[1] )
			write_coord( origin[2] + 30 )
			write_coord( endPos[0] )
			write_coord( endPos[1] )
			write_coord( endPos[2] )
			message_end()
#else
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte( TE_BEAMPOINTS )
			write_coord( origin[0] )
			write_coord( origin[1] )
			write_coord( origin[2] ) // start location
			write_coord( endPos[0] )
			write_coord( endPos[1] )
			write_coord( endPos[2] ) // end location
			write_short( gSpriteLightning ) // spritename
			write_byte( 1 ) // start frame
			write_byte( 10 ) // framerate
			write_byte( 5 ) // life
			write_byte( 50 ) // line width
			write_byte( random_num( 20, 120 ) ) // amplitude
			write_byte( 150 )
			write_byte( 150 )
			write_byte( 255 ) // color
			write_byte( 100 ) // brightness
			write_byte( 100 ) // speed
			message_end()
#endif			
			
			if ( !is_user_alive( hit ) )
			{
				FVecIVec( target, endPos )
				
				message_begin( MSG_PVS, SVC_TEMPENTITY, endPos )
				write_byte( TE_GUNSHOT )
				write_coord( endPos[0] )
				write_coord( endPos[1] )
				write_coord( endPos[2] )
				message_end()
			}
			else if ( !get_user_godmode( hit ) )			
			{
				new health = get_user_health( hit )
				if ( health - 100 < 1 )
					ARP_UserKill( hit, 1, 0 )
				else
				{
					set_user_health( hit, health - 100 )
					
					message_begin( MSG_ONE_UNRELIABLE, gMsgTSFade, _, hit )
					write_short( 255 )
					write_short( 255 )
					write_short( 0 )
					write_byte( 255 )
					write_byte( 0 )
					write_byte( 0 )
					write_byte( 80 )
					message_end()
				}
			}
		}
	}
	
dontTarget:
	// Acquire new target.
	if ( !player || !is_user_alive( player ) )
	{
		set_pev( ent, pev_euser1, 0 )
		for ( new id = 1; id <= gMaxPlayers; id++ )
		{
			if ( !is_user_alive( id ) || id == ent || !fm_is_ent_visible( id, ent ) || !fm_is_in_viewcone( ent, id ) || pev( id, pev_flags ) & FL_NOTARGET )
				continue
			
			set_pev( ent, pev_euser1, id )
			set_pev( ent, pev_euser2, id )
			
			// Block this think to add a slight delay.
			goto end
		}
		
		static Float:start[3], Float:target[3]
		pev( ent, pev_vuser1, start )
		pev( ent, pev_vuser2, target )
		
		static originStr[33], Float:boundaries1[3], Float:boundaries2[3], originPieces[3][11]
		//target = origin
		
		new TravTrie:travTrie = TravTrie:pev( ent, pev_iuser1 )
		
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
		static Float:distance[3]
		distance[0] = target[0] - entOrigin[0]
		distance[1] = target[1] - entOrigin[1]
		
		xs_vec_normalize( distance, distance )
		xs_vec_mul_scalar( distance, 100.0, distance )
		
		target[0] = entOrigin[0] + distance[0]
		target[1] = entOrigin[1] + distance[1]
		target[2] = entOrigin[2]
		
		engfunc( EngFunc_TraceHull, entOrigin, target, 0, HULL_HUMAN, ent, 0 )
		
		new Float:fraction, MODES:mode = MODES:pev( ent, pev_iuser2 )
		get_tr2( 0, TR_flFraction, fraction )
		new id = get_tr2( 0, TR_pHit )
		
		if ( mode == LKP && is_valid_ent( id ) )
		{
			static className[33]
			pev( id, pev_classname, className, charsmax( className ) )
			
			if ( equali( className, "func_door" ) || equali( className, "func_door_rotating" ) )
			{
				static targetName[33]
				pev( id, pev_targetname, targetName, charsmax( targetName ) )
				
				if ( !strlen( targetName ) )
				{
					force_use( ent, id )
					fake_touch( id, ent )
				}
				
				goto skipFraction
			}
		}
		
		if ( fraction < 0.999 && mode == NORMAL )	
		{			
			CalculateTarget( ent )
			pev( ent, pev_vuser2, target )
		}
		
skipFraction:	
		switch ( mode )
		{
			case NORMAL :
			{
				distance[0] = target[0] - entOrigin[0]
				distance[1] = target[1] - entOrigin[1]
			}
			case LKP :
			{
				if ( curTime - lastSpot > 10.0 )
				{
					CalculateTarget( ent )
					goto end
				}
				
				static Float:curRotation[3]
				curRotation = plOrigin
				
				pev( lkp, pev_origin, plOrigin )
				
				new breakOuter
				for ( new Float:radius = 150.1, Float:angle; radius <= 500.0 && !breakOuter; radius += 50.0 )
					for ( angle = 0.0; angle < M_PI * 2; angle += M_PI/18 )
					{
						curRotation[0] += radius * floatcos( angle )
						curRotation[1] += radius * floatsin( angle )
						
						engfunc( EngFunc_TraceHull, plOrigin, curRotation, 0, HULL_HUMAN, lkp, 0 )
						
						get_tr2( 0, TR_flFraction, fraction )
						
						if ( fraction == 1.0 )
						{				
							curRotation[2] = entOrigin[2]
							
							engfunc( EngFunc_TraceHull, curRotation, entOrigin, 0, HULL_HUMAN, ent, 0 )
						
							get_tr2( 0, TR_flFraction, fraction )
							
							if ( fraction == 1.0 )
							{
								breakOuter = 1
								distance[0] = curRotation[0] - entOrigin[0]
								distance[1] = curRotation[1] - entOrigin[1]
								break
							}
						}
						
						curRotation = plOrigin
					}
			}
		}
		
		set_pev( ent, pev_sequence, mode ? 16 : 17 )
		
		xs_vec_normalize( distance, distance )
		
		engfunc( EngFunc_VecToAngles, distance, angles )
		
		set_pev( ent, pev_angles, angles )
		
		xs_vec_mul_scalar( distance, mode ? 250.0 : 100.0, distance )
		entity_set_vector( ent, EV_VEC_velocity, distance )
		
		if ( !( pev( ent, pev_flags ) & ( FL_FLY | FL_SWIM ) ) )
			drop_to_floor( ent )
	}
	
end:
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
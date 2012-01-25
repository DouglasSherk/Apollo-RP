#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <engine>
#include <fakemeta>

enum GOGGLES
{
	NONE,
	THERMAL,
	NIGHT,
	WAVE
}

new gLastRender[33]
new gCloaked[33]

new GOGGLES:gGoggles[33]

new gLaserMic[33]

new gTags[GOGGLES][] = 
{
	"Disabled",
	"Thermal",
	"Night",
	"Wave"
}

new gMenu

//new pLights
new pRange

new gBeamSprite

new gLastMessage

/* From Rope Mod by EJL & SpaceDude */

new Float:RpDelay[33]

#define HOLD_T 20.0
#define ROPE_DELAY 0.5
#define TE_BEAMENTPOINT 1
#define TE_KILLBEAM 99
#define DELTA_T 0.1		// seconds
#define BEAMLIFE 100		// deciseconds
#define MOVEACCELERATION 150	// units per second^2
#define REELSPEED 200		// units per second

new hooklocation[33][3]
new hooklength[33]
new bool:hooked[33]
new Float:beamcreated[33]

new global_gravity
new s_rope

public ARP_Init()
{
	ARP_RegisterPlugin( "Spy Mod", "1.0", "Hawk552", "Adds spy items" )
	
	gMenu = menu_create( "Select Goggle Mode", "MenuGoggles" )
	
	for ( new GOGGLES:i; i < GOGGLES; i++ )
		menu_additem( gMenu, gTags[i] )
	
	register_forward( FM_AddToFullPack, "ForwardAddToFullPack", 1 )
	register_forward( FM_PlayerPostThink, "ForwardPlayerPostThink" )
	
	ARP_RegisterEvent( "Chat_Message", "EventChatMessage" )
	
	set_task( 0.1, "ShowLights", _, _, _, "b" )
}

public _LaserMicrophone( id, itemId )
{
	gLaserMic[id] = !gLaserMic[id]
	client_print( id, print_chat, "[ARP] You have %sabled your laser microphone.", gLaserMic[id] ? "en" : "dis" )
}

public EventChatMessage( name[], data[], len )
{	
	new id = data[0]
	if ( id == gLastMessage ) 
		return
	
	gLastMessage = id
	
	set_task( 0.1, "ResetLastMessage" )
	
	new players[32], playersNum, player, lookAt[3], chatPosition[3]
	get_players( players, playersNum )
	
	get_user_origin( id, chatPosition )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		if ( id == player || !gLaserMic[player] )
			continue
		
		get_user_origin( player, lookAt, 3 )
		
		if ( get_distance( lookAt, chatPosition ) > floatround( get_pcvar_float( pRange ) * 300.0 ) )
			continue
		
		static newMessage[256]
		copy( newMessage, 255, "(LASER MIC) " )
		add( newMessage, 255, data[2] )
		
		ARP_ChatMessage( id, player, newMessage )
	}
}

public ResetLastMessage()
	gLastMessage = 0

public client_disconnect( id )
{
	gGoggles[id] = NONE
	gCloaked[id] = 0
	gLaserMic[id] = 0
	
	RpDelay[id] = 0.0
	hooked[id] = false
	
	set_pev( id, pev_renderamt, 255.0 )
}

public EventDeathMsg()
	client_disconnect( read_data( 2 ) )

public plugin_precache()
{
	gBeamSprite = precache_model( "sprites/laserbeam.spr" )
	
	s_rope = precache_model("sprites/rope.spr")
	precache_sound("weapons/xbow_hit2.wav")
}

public plugin_init()
{
	//pLights = register_cvar( "arp_lights", "m" )
	pRange = register_cvar( "arp_message_range", "1.0" )
	
	register_event( "DeathMsg", "EventDeathMsg", "a" )
}

public ARP_RegisterItems()
{
	ARP_RegisterItem( "Spy Goggles", "_Goggles", "Gives user better vision" )
	ARP_RegisterItem( "Spy Rope", "_Rope", "Allows user to scale walls" )
	ARP_RegisterItem( "Spy Cloak", "_Cloak", "Cloaks user" )
	ARP_RegisterItem( "Spy Laser Microphone", "_LaserMicrophone", "Allows user to listen to far-away conversations" )
}

public _Cloak( id, itemId )
{
	gCloaked[id] = !gCloaked[id]
	client_print( id, print_chat, "[ARP] You are now %scloaked.", gCloaked[id] ? "" : "un" )
	
	if ( !gCloaked[id] )
		set_pev( id, pev_renderamt, 255.0 )
}

public _Goggles( id, itemId )
	menu_display( id, gMenu )

public MenuGoggles( id, menu, GOGGLES:item )
{
	gGoggles[id] = item
	client_print( id, print_chat, "[ARP] You have switched your goggles to ^"%s^" mode.", gTags[item] )
	
	return PLUGIN_HANDLED
}

public ShowLights()
{
	new players[32], playersNum, player, id, origin[3], otherOrigin[3], j, distance
	get_players( players, playersNum )
	
	for ( new i; i < playersNum; i++ )
	{
		player = players[i]
		switch ( gGoggles[player] )
		{
			case THERMAL :
			{
				get_user_origin( player, origin )
				
				message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, player )
				write_byte( TE_DLIGHT )
				write_coord( origin[0] )
				write_coord( origin[1] )
				write_coord( origin[2] )
				write_byte( 9999999 )
				write_byte( 5 )
				write_byte( 0 )
				write_byte( 0 )
				write_byte( 5 )
				write_byte( 1 )
				write_byte( 1 )
				message_end()
				
				for ( j = 0; j < playersNum; j++ )
				{
					id = players[j]
					distance = get_entity_distance( id, player )
					if ( id == player || distance > 2000 || is_visible( id, player ) ) 
						continue
					
					get_user_origin( id, otherOrigin )
					
					//#define	TE_BEAMENTS                 8
					// write_byte(TE_BEAMENTS)
					// write_short(start entity) 
					// write_short(end entity) 
					// write_short(sprite index) 
					// write_byte(starting frame) 
					// write_byte(frame rate in 0.1's) 
					// write_byte(life in 0.1's) 
					// write_byte(line width in 0.1's) 
					// write_byte(noise amplitude in 0.01's) 
					// write_byte(red)
					// write_byte(green)
					// write_byte(blue)
					// write_byte(brightness)
					// write_byte(scroll speed in 0.1's)
					
					message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, player )
					write_byte( TE_BEAMENTS )
					write_short( player )
					write_short( id )
					write_short( gBeamSprite ) // sprite index
					write_byte( 0 ) // starting frame
					write_byte( 0 ) // frame rate in 0.1's
					write_byte( 1 ) // life in 0.1's
					write_byte( 1 ) // line width in 0.1's
					write_byte( 0 ) // noise amplitude in 0.01's
					write_byte( 255 )
					write_byte( 0 )
					write_byte( 0 )
					write_byte( 150 + 105/distance ) // brightness)
					write_byte( 0 ) // scroll speed in 0.1's
					message_end()
				}
			}
			case NIGHT :
			{				
				get_user_origin( player, origin )
				
				message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, player )
				write_byte( TE_DLIGHT )
				write_coord( origin[0] )
				write_coord( origin[1] )
				write_coord( origin[2] )
				write_byte( 9999999 )
				write_byte( 0 )
				write_byte( 255 )
				write_byte( 0 )
				write_byte( 5 )
				write_byte( 1 )
				write_byte( 1 )
				message_end()
			}
		}
	}
}

public ForwardAddToFullPack( ES, e, ent, host, hostFlags, player, pSet )
{
	if ( !pev_valid( ent ) )
		return FMRES_IGNORED
	
	switch ( gGoggles[host] )
	{
		case THERMAL :
		{
			if ( !is_user_alive( ent ) )
				return FMRES_IGNORED
			
			set_es( ES, ES_RenderFx, kRenderFxGlowShell )
			set_es( ES, ES_RenderAmt, 40 )
			set_es( ES, ES_RenderColor, { 255, 0, 0 } )
		}
		
		case WAVE :
		{
			if ( is_user_alive( ent ) )
				return FMRES_IGNORED
			
			static className[33]
			pev( ent, pev_classname, className, 32 )
			
			if ( equali( className, "func_ladder" ) )
				return FMRES_IGNORED
			
			set_es( ES, ES_RenderMode, 5 )
			set_es( ES, ES_RenderAmt, 200 )
			set_es( ES, ES_RenderColor, { 80, 80, 255 } )
		}
	}
	
	return FMRES_IGNORED
}

public ForwardPlayerPostThink( id )
{
	if ( !gCloaked[id] )
		return
	
	new Float:velocity[3]
	pev( id, pev_velocity, velocity )
	
	new Float:speed = velocity[0] * velocity[0] + velocity[1] * velocity[1] - 400
	if ( pev( id, pev_button ) & IN_DUCK )
		speed -= 600
	
	new Float:renderAmount = float( gLastRender[id] = clamp( gLastRender[id] + floatround( speed / 50 ), 0, 255 ) )
	
	set_pev( id, pev_renderfx, kRenderFxNone )
	set_pev( id, pev_rendercolor, Float:{ 0.0, 0.0, 0.0 } )
	set_pev( id, pev_rendermode, kRenderTransAlpha )
	set_pev( id, pev_renderamt, renderAmount )
}

/* From Rope Mod by EJL & SpaceDude */

public hooktask(parm[]) {
	new id = parm[0]
	new user_origin[3], user_look[3], user_direction[3], move_direction[3]
	new A[3], D[3], buttonadjust[3]
	new acceleration, velocity_TA, desired_velocity_TA
	new velocity[3], null[3]
	new Float:tmpVector[3]

	if (!is_user_alive(id)) {
		release(id)
		return
	}

	if (beamcreated[id] + BEAMLIFE/10 <= get_gametime()) {
		beamentpoint(id)
	}

	null[0] = 0
	null[1] = 0
	null[2] = 0

	get_user_origin(id, user_origin)
	get_user_origin(id, user_look,2)
	
	entity_get_vector(id, EV_VEC_velocity, tmpVector)
	FVecIVec(tmpVector, velocity)

	buttonadjust[0]=0
	buttonadjust[1]=0

	if (get_user_button(id)&IN_FORWARD) {
		buttonadjust[0]+=1
	}
	if (get_user_button(id)&IN_BACK) {
		buttonadjust[0]-=1
	}
	if (get_user_button(id)&IN_MOVERIGHT) {
		buttonadjust[1]+=1
	}
	if (get_user_button(id)&IN_MOVELEFT) {
		buttonadjust[1]-=1
	}
	if (get_user_button(id)&IN_JUMP) {
		buttonadjust[2]+=1
	}
	if (get_user_button(id)&IN_DUCK) {
		buttonadjust[2]-=1
	}

	if (buttonadjust[0] || buttonadjust[1]) {
		user_direction[0] = user_look[0] - user_origin[0]
		user_direction[1] = user_look[1] - user_origin[1]

		move_direction[0] = buttonadjust[0]*user_direction[0] + user_direction[1]*buttonadjust[1]
		move_direction[1] = buttonadjust[0]*user_direction[1] - user_direction[0]*buttonadjust[1]
		move_direction[2] = 0

		velocity[0] += floatround(move_direction[0] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
		velocity[1] += floatround(move_direction[1] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
	}
	if (buttonadjust[2]) {
		hooklength[id] -= floatround(buttonadjust[2] * REELSPEED * DELTA_T)
	}
	if (hooklength[id] < 100) {
		(hooklength[id]) = 100
	}

	A[0] = hooklocation[id][0] - user_origin[0]
	A[1] = hooklocation[id][1] - user_origin[1]
	A[2] = hooklocation[id][2] - user_origin[2]

	D[0] = A[0]*A[2] / get_distance(null,A)
	D[1] = A[1]*A[2] / get_distance(null,A)
	D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

	new aDistance = get_distance(null,D) ? get_distance(null,D) : 1
	acceleration = - global_gravity * D[2] / aDistance

	velocity_TA = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
	desired_velocity_TA = (get_distance(user_origin,hooklocation[id]) - hooklength[id] /*- 10*/) * 4

	if (get_distance(null,D)>10) {
		velocity[0] += floatround((acceleration * DELTA_T * D[0]) / get_distance(null,D))
		velocity[1] += floatround((acceleration * DELTA_T * D[1]) / get_distance(null,D))
		velocity[2] += floatround((acceleration * DELTA_T * D[2]) / get_distance(null,D))
	}

	velocity[0] += ((desired_velocity_TA - velocity_TA) * A[0]) / get_distance(null,A)
	velocity[1] += ((desired_velocity_TA - velocity_TA) * A[1]) / get_distance(null,A)
	velocity[2] += ((desired_velocity_TA - velocity_TA) * A[2]) / get_distance(null,A)

	IVecFVec(velocity, tmpVector)
	entity_set_vector(id, EV_VEC_velocity, tmpVector)
}

// Renamed to _Rope from rope_toggle
public _Rope(id) {
	if (!hooked[id] && is_user_alive(id)){
		if(RpDelay[id] > get_gametime() - ROPE_DELAY)
			return PLUGIN_HANDLED
		RpDelay[id] = get_gametime()
		attach(id)
	}
	else if (hooked[id])
	{
		release(id)
	}
	
	return PLUGIN_HANDLED
}

public attach(id){
	new parm[1], user_origin[3]
	parm[0] = id
	hooked[id] = true
	get_user_origin(id, user_origin)
	get_user_origin(id, hooklocation[id], 3)
	
	// Added by Hawk552
	new Float:origin[3]
	IVecFVec( hooklocation[id], origin )
	
	if ( PointContents( origin ) != CONTENTS_SOLID )
	{
		//hooked[id] = false
		//return
	}
	// End Hawk552
	
	hooklength[id] = get_distance(hooklocation[id],user_origin)
	global_gravity = get_cvar_num("sv_gravity")
	set_user_gravity(id,0.001)
	beamentpoint(id)
	
	if ( get_distance( user_origin, hooklocation[id] ) > 50 )
		emit_sound(id, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(DELTA_T, "hooktask", 200+id, parm, 1, "b")
	//set_task(HOLD_T, "let_go",77545+id,parm, 1)
	server_cmd("ropemissile_chk %d 1",id)
}

public let_go(parm[]){
	release(parm[0])
	return PLUGIN_CONTINUE
}


public release(id){
	hooked[id] = false
	killbeam(id)
	set_user_gravity(id)
	remove_task(200+id)
	remove_task(77545+id)
	remove_task(77578+id)
}

public beamentpoint(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMENTPOINT )
	write_short( id )
	write_coord( hooklocation[id][0] )
	write_coord( hooklocation[id][1] )
	write_coord( hooklocation[id][2] )
	write_short( s_rope )	// sprite index
	write_byte( 0 )		// start frame
	write_byte( 0 )		// framerate
	write_byte( BEAMLIFE )	// life
	write_byte( 2 )	// width
	write_byte( 1 )		// noise
	write_byte( 250 )	// r, g, b
	write_byte( 250 )	// r, g, b
	write_byte( 250 )	// r, g, b
	write_byte( 250 )	// brightness
	write_byte( 0 )		// speed
	message_end( )
	beamcreated[id] = get_gametime()
}

public killbeam(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_KILLBEAM )
	write_short( id )
	message_end()
}
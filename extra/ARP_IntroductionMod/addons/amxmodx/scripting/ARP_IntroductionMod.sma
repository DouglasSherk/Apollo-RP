#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <fakemeta>
#include <hamsandwich>

#define INTRODUCTION_SOUND

new Class:gClass[33]
new gWelcomed[33]
new Float:gOrigin[33][3]
new Float:gCurOrigin[33][3]

new gStage[33]

new gMaxPlayers

new gMenu
new gMenuTitle[] = "ARPIntroductionMenu"

new TravTrie:gLocations

new gCameraClassname[] = "arp_introduction_camera"
new gCameraModel[] = "models/rpgrocket.mdl"

#if defined INTRODUCTION_SOUND
new gIntroSound[] = "sound/ProjectMobius/mp3/intro.mp3"
#endif // INTRODUCTION_SOUND

public ARP_Init()
	ARP_RegisterPlugin( "Introduction Mod", "1.0", "Hawk552", "Gives new players an introduction to the server" )

public plugin_precache()
{
	precache_model( gCameraModel )
	
#if defined INTRODUCTION_SOUND
	if ( file_exists( gIntroSound ) )
		precache_generic( gIntroSound )
#endif // INTRODUCTION_SOUND
}

public plugin_init()
{
	RegisterHam( Ham_Spawn, "player", "HamSpawnPost", 1 )
	
	register_menucmd( register_menuid( gMenuTitle ), MENU_KEY_1, "IntroductionMenuHandle" )
	
	set_task( 1.0, "UnStupidify", .flags = "b" )
	
	register_clcmd("resetme","resetme") 
	
	ARP_RegisterEvent( "Core_Save", "EventCoreSave" )
	
	register_forward( FM_UpdateClientData, "ForwardUpdateClientDataPost", 1 )
	
	gMaxPlayers = get_maxplayers()
	
	gMenu = menu_create( "Would you like an introduction to the^nserver?", "MenuHandle" )
	menu_additem( gMenu, "Yes" )
	menu_additem( gMenu, "No, but ask me later" )
	menu_additem( gMenu, "No, and never ask me again" )
	menu_setprop( gMenu, MPROP_EXIT, MEXIT_NEVER )
	
	new file = ARP_FileOpen( "introduction.ini", "r" )
	if ( !file )
	{
		log_amx( "Error opening file: introduction.ini" )
		return
	}
	
	gLocations = TravTrieCreate()
	
	new buffer[512], TravTrie:current, left[33], right[512], num = 1, Float:origin[3], Float:angles[3], ent
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
			TravTrieGetString( current, "origin", buffer, charsmax( buffer ) )
			StringToVector( buffer, origin )
			
			TravTrieGetString( current, "angles", buffer, charsmax( buffer ) )
			StringToVector( buffer, angles )
			
			if ( vector_length( angles ) > 0.1 || vector_length( origin ) > 0.1 )
			{
				ent = create_entity( "info_target" )
				entity_set_string( ent, EV_SZ_classname, gCameraClassname )
				entity_set_model( ent, gCameraModel )
				entity_set_origin( ent, origin )
				entity_set_vector( ent, EV_VEC_angles, angles )
				entity_set_int( ent, EV_INT_iuser1, num )
				set_rendering( ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 ) 
			}
			
			TravTrieSetCellEx( gLocations, num++, current )
			
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
}

public ForwardUpdateClientDataPost( id, sendWeapons, cdHandle )
{
    if ( !is_user_alive( id ) || !gStage[id] )
        return FMRES_IGNORED
    
    set_cd( cdHandle, CD_ID, 0 )
    
    return FMRES_HANDLED
}

public UnStupidify()
	for ( new id = 1; id <= gMaxPlayers; id++ )
		if ( is_user_connected( id ) && gStage[id] )
			DoIntroduction( id, 0 )

DoIntroduction( id, flag )
{	
	new TravTrie:nextLocation, TravTrie:isThereANext
	TravTrieGetCellEx( gLocations, flag ? ++gStage[id] : gStage[id], nextLocation )
	TravTrieGetCellEx( gLocations, gStage[id] + 1, isThereANext )
	
	new ent
	while ( ( ent = find_ent_by_class( ent, gCameraClassname ) ) )
		if ( entity_get_int( ent, EV_INT_iuser1 ) == gStage[id] )
		{
			entity_get_vector( ent, EV_VEC_origin, gCurOrigin[id] )
			entity_set_origin( id, gCurOrigin[id] )
			
			attach_view( id, ent )
			break
		}
	
	static description[512]
	TravTrieGetString( nextLocation, "description", description, charsmax( description ) )
	
	replace_all( description, charsmax( description ), "\n", "^n" )
	add( description, charsmax( description ), isThereANext != Invalid_TravTrie ? "^n^n1. Continue" : "^n^n1. Finish" )
	
	show_menu( id, MENU_KEY_1, description, -1, gMenuTitle )
}

public client_PreThink( id )
	if ( gStage[id] )
	{
		entity_set_origin( id, gCurOrigin[id] )
		entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } )
	}

public IntroductionMenuHandle( id, item )
{
	new TravTrie:isThereANext
	TravTrieGetCellEx( gLocations, gStage[id] + 1, isThereANext )
	
	if ( isThereANext != Invalid_TravTrie )		
		DoIntroduction( id, 1 )
	else
	{
		entity_set_float( id, EV_FL_gravity, 1.0 )
		entity_set_int( id, EV_INT_solid, SOLID_BBOX )		
		entity_set_origin( id, gOrigin[id] )
		entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) & ~EF_NODRAW )
		entity_set_int( id, EV_INT_flags, entity_get_int( id, EV_INT_flags ) & ~FL_NOTARGET )
		ARP_SetUserSpeed( id, Speed_None )
		
		gStage[id] = 0
		
		gWelcomed[id] = 1
		
		client_print( id, print_chat, "[ARP] You have completed the introduction." )
		attach_view( id, id )
	}
	
	return PLUGIN_HANDLED
}

public MenuHandle( id, menu, item )
{	
	switch ( item )
	{
		case 0 :
		{			
			entity_set_float( id, EV_FL_gravity, 0.000001 )
			entity_set_int( id, EV_INT_solid, SOLID_NOT )
			ARP_SetUserSpeed( id, Speed_Override, 0.1 )
			entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) | EF_NODRAW )
			entity_set_int( id, EV_INT_flags, entity_get_int( id, EV_INT_flags ) | FL_NOTARGET )
			
			DoIntroduction( id, 1 )
		}
		case 1 :
			gWelcomed[id] = 2
		case 2 :
			gWelcomed[id] = 1
	}
	
	return PLUGIN_HANDLED
}

public plugin_end()
	menu_destroy( gMenu )

public EventCoreSave()
	for ( new id = 1; id <= gMaxPlayers; id++ )
		if ( gClass[id] != Invalid_Class )
			ARP_ClassSave( gClass[id] )

public resetme(id)gWelcomed[id]=0

public client_putinserver( id )
{
	gStage[id] = 0
	
	new authid[36], idStr[3]
	get_user_authid( id, authid, charsmax( authid ) )
	num_to_str( id, idStr, charsmax( idStr ) )
	
	ARP_ClassLoad( authid, "ClassLoadedHandle", idStr )
}

public client_disconnect( id )
{
	if ( gClass[id] != Invalid_Class )
		ARP_ClassSave( gClass[id], 1 )
	
	gWelcomed[id] = 0
}

public ClassLoadedHandle( Class:classId, const className[], const data[] )
{
	new id = str_to_num( data )
	gClass[id] = classId
	
	gWelcomed[id] = ARP_ClassGetInt( classId, "welcomed" )
	
	ARP_ClassSaveHook( classId, "ClassSaveHandle", data )
}

public ClassSaveHandle( Class:classId, const className[], const data[] )
{
	new welcomed = gWelcomed[str_to_num( data )]
	ARP_ClassSetInt( classId, "welcomed", welcomed == 2 ? 0 : welcomed )
}

public HamSpawnPost( id )
{
	if ( !is_user_connected( id ) || !is_user_alive( id ) )
		return
	
	if ( gClass[id] == Invalid_Class )
	{
		set_task( 1.0, "HamSpawnPost", id )
		return
	}
	
	if ( !gWelcomed[id] )
	{
		entity_get_vector( id, EV_VEC_origin, gOrigin[id] )
		menu_display( id, gMenu )
#if defined INTRODUCTION_SOUND
		set_task( 0.1, "PlayMusic", id )
#endif // INTRODUCTION_SOUND
	}
}

public PlayMusic( id )
	client_cmd( id, "mp3 play %s", gIntroSound )

StringToVector( const string[], Float:vector[3] )
{
	new vectorPieces[3][11]
	parse( string, vectorPieces[0], 10, vectorPieces[1], 10, vectorPieces[2], 10 )
	vector[0] = str_to_float( vectorPieces[0] )
	vector[1] = str_to_float( vectorPieces[1] )
	vector[2] = str_to_float( vectorPieces[2] )
}
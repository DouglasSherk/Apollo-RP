#if defined _ApolloRP_included
	#endinput
#endif

#define _ApolloRP_included

#include <amxmodx>
#include <engine>
#include <fun>

#include <ApolloRP_Const>
#include <ApolloRP_Edict>
#include <ApolloRP_SQL>
#include <ApolloRP_Player>
#include <ApolloRP_Jobs>
#include <ApolloRP_Properties>
#include <ApolloRP_Data>
#include <ApolloRP_Items>
#include <ApolloRP_HUD>
#include <ApolloRP_NPCs>
#include <ApolloRP_Menus>
#include <ApolloRP_Commands>
#include <ApolloRP_TS>
#include <ApolloRP_SC>
#include <ApolloRP_Speed>
#include <ApolloRP_Events>
 
/* 

This is the header file for all ARP functions. It also contains
some documentation on how to use them. These functions require the
main plugin (usually named arp_core.amxx/sma) to be running, otherwise
they will fail to load.

*/

#if AMXX_VERSION_NUM < 175
	#endinput
#endif

#pragma library "arp"

#define ARP_VERSION "1.3"
#define DPRP_PLATFORM "3.3"

// Gets the ARP version
native ARP_Version(version[],len)

// Registers a plugin to ARP
native ARP_RegisterAddon(const description[])

// Checks if an addon is loaded
// returns the plugin id of the plugin
native ARP_AddonLoaded(const name[])

// Gets the trie containing the list of addons loaded
// it is recommended that you don't use this,
// but it can sometimes be useful
native TravTrie:ARP_AddonTrie()

// Gets the configuration directory for ARP files
native ARP_GetConfigsdir(configsdir[],len)

// Opens a file
// Prioritizes the map based config file
// If it doesn't exist, it opens the core file
// const file[] - Name of the file to open, from ./arp/
// const mode[] - Mode to use, as in fopen
native ARP_FileOpen(const file[],const mode[])

// Logs an event
// Automatically detects cvar settings
native ARP_Log(const message[],{Float,Sql,Result,_}:...)

// Precaches a model
// This checks to make sure it won't go over the precache limit,
// and that the file to be precached actually exists.
// REMOVED
//native ARP_PrecacheModel(const model[])

// Precaches a sound
// This checks to make sure it won't go over the precache limit,
// and that the file to be precached actually exists.
// REMOVED
//native ARP_PrecacheSound(const sound[])

// Prints a message to a user via HUD or print_center, depending on cvars
// id - person to print to; use 0 for everyone
// const message[] - message to print
// {Float,Sql,Result,_}:... - allows formatting of message
native ARP_ClientPrint(id,const message[],{Float,Sql,Result,_}:...)

// Throws an error at the core
// error - the error type (refer to amxconst.inc)
// fatal - whether or not this should shut the core down
// reason[] - reason for error
native ARP_ThrowError(error,fatal,const reason[],{Float,Sql,Result,_}:...)

// called when SQL and stuff are ready
forward ARP_Init()

// called whenever an event happens
forward ARP_Event(name[],data[],len)

// called when the core is shutting down due to a fatal error
// cannot be blocked
// it is advised that you run any final commands here and pause("d")
forward ARP_Error(const reason[])

// Registers a plugin to AMXX and ARP
stock ARP_RegisterPlugin(const name[],const version[],const author[],const description[])
{
	static Name[64]
	format(Name,63,"ARP - %s",name)

	ARP_RegisterAddon(description)
	register_plugin(Name,version,author)

	return SUCCEEDED
}

// Converts a string, i.e. "abc" to a number (in this case, "a" = 1, 
// "b" = 2, "c" = 4, so 7 in total).
// Returns the number.
stock ARP_AccessToInt(string[])
{
	new Access
	
	for(new Count;Count < JOB_ACCESSES;Count++)
		if(containi(string,g_JobLiterals[Count]) != -1)
			Access |= (1<<Count)
	
	return Access
}

// Reverses the process of ARP_AccessToInt.
stock ARP_IntToAccess(access,string[],len)
{
	copy(string,len,"")
	
	for(new Count;Count < JOB_ACCESSES;Count++)
		if(access & (1<<Count))
			add(string,len,g_JobLiterals[Count])
}

// Gets the admin access
// If id is specified as a player that is connected,
// it will return whether or not the user is an admin.
stock ARP_AdminAccess(id = 0)
{
	new String[JOB_ACCESSES + 1]
	get_cvar_string(g_AdminAccessCvar,String,JOB_ACCESSES)
	
	new Flag = ARP_AccessToInt(String)
	
	if(id)
		return is_user_connected(id) ? ARP_GetUserAccess(id) & Flag : FAILED
	
	return Flag
}

// Thanks to xeroblood
stock ExplodeString( p_szOutput[][], p_iMax, p_szInput[], p_iSize, p_szDelimiter )
{
	new iIdx = 0, l = strlen(p_szInput)
	new iLen = (1 + copyc( p_szOutput[iIdx], p_iSize, p_szInput, p_szDelimiter ))
	while( (iLen < l) && (++iIdx < p_iMax) )
		iLen += (1 + copyc( p_szOutput[iIdx], p_iSize, p_szInput[iLen], p_szDelimiter ))
	return iIdx
}  

stock ARP_UserKill(id,flag,killer = 0)
{
	new Data[2]
	Data[0] = id
	Data[1] = killer
	if(ARP_CallEvent("Player_Die",Data,2))
		return FAILED

	entity_set_edict(id,EV_ENT_dmg_inflictor,0)
	
	user_kill(id,flag)

	return SUCCEEDED
}


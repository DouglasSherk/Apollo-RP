#if defined _ApolloRP_Player_included
	#endinput
#endif

#define _ApolloRP_Player_included

#include <ApolloRP>

// Checks whether or not the player's account is loaded
native ARP_PlayerReady(id)

// Gets time to payday in ARP units (2 seconds = 1 second, or something like that)
native ARP_GetPayday()

// Gets how hungry the person is (1-100)
native ARP_GetUserHunger(id)

// Sets how hungry the person is (1-100)
native ARP_SetUserHunger(id,hunger)

// Sets the amount of money in someone's wallet
native ARP_SetUserWallet(id,cash)

// Gets the amount of money in someone's wallet
native ARP_GetUserWallet(id)

// Sets the amount of money in someone's bank account
native ARP_SetUserBank(id,cash)

// Gets the amount of money in someone's bank account
native ARP_GetUserBank(id)

// Gets a user's access (personal AND job access [but not job rights])
native ARP_GetUserAccess(id)

// Sets a user's access.
// NOTE: This does NOT allow them to keep their old flags - to do this,
// you should use ARP_SetUserAccess(id,myflags|ARP_GetUserAccess(id))
native ARP_SetUserAccess(id,access)

// called when a user's salary comes
// return PLUGIN_HANDLED to block
forward ARP_Salary(id)

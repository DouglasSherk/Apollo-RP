#if defined _ApolloRP_Menus_included
	#endinput
#endif

#define _ApolloRP_Menus_included

#include <ApolloRP>

// Adds a menu item to the master menu
// NOTE: Only call this during the "clientmenu" event
// id - player to add the menu to
// const name[] - name of the menu item
// const handler[] - function to call when the key is pressed
native ARP_AddMenuItem(id,const name[],const handler[])

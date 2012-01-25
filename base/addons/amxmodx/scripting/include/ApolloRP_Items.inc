#if defined _ApolloRP_Items_included
	#endinput
#endif

#define _ApolloRP_Items_included

#include <ApolloRP>

// This will register an item that can be used in game.
// This MUST be run during ARP_RegisterItems and no other time.
// Returns FAILED (0) on failure, or an item id on success
// name[] - name of item, ex. "Lamp Shade"
// handler[] - function to call when it is used
// description - what the item is like, i.e. "Tastes like chicken."
// remove - whether or not the item should be taken away once used, if it is
// disposable
native ARP_RegisterItem(name[],handler[],description[],remove = 0)

// Will find an item based on search string, with the same method as FindJobId.
native ARP_FindItemId(searchstring[],results[],maxresults)

// Determines whether an item id is valid or not
native ARP_ValidItemId(itemid)

// Will get an item's name based on an item id.
// itemid - id of the item
// name - where to store the name
// len - length of name
native ARP_GetItemName(itemid,name[],len)

// Gets user item num
native ARP_GetUserItemNum(id,itemid)

// Sets user item id to whatever value
native ARP_SetUserItemNum(id,itemid,num)

// Forces a user to use an item.
// Note that they must possess at least 1 of the item with the specified
// itemid.
// Setting useup to 1 makes it such that it will both check if the user has the item,
// and that if it's disposable is on, it gets used up
// Setting it to 0 both ignores whether or not the user has the item, as well as
// the disposable setting
native ARP_ForceUseItem(id,itemid,useup = 1)

// Sets their item to done so that they can start using other items again
native ARP_ItemDone(id)

// Artificially tells the core that the user is using an item.
// To end this, use ARP_ItemDone.
native ARP_ItemSet(id)

// called when you can register items
forward ARP_RegisterItems()

stock ARP_FindItem(searchstring[])
{
	new Results[1]
	ARP_FindItemId(searchstring,Results,1)
	
	return ARP_ValidItemId(Results[0]) ? Results[0] : FAILED
}

stock ARP_GiveUserItem(id,itemid,num)
{
	if(!is_user_connected(id) || !ARP_ValidItemId(itemid)) return FAILED
	
	return ARP_SetUserItemNum(id,itemid,max(ARP_GetUserItemNum(id,itemid) + num,0))
}

stock ARP_TakeUserItem(id,itemid,num)
{
	if(!is_user_connected(id) || !ARP_ValidItemId(itemid)) return FAILED
	
	new CurrentAmount = ARP_GetUserItemNum(id,itemid)
	if(CurrentAmount < num) return FAILED
	
	return ARP_SetUserItemNum(id,itemid,max(CurrentAmount - num,0))
}
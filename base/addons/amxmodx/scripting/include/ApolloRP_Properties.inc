#if defined _ApolloRP_Properties_included
	#endinput
#endif

#define _ApolloRP_Properties_included

#include <ApolloRP>

// Checks to be sure a property is valid.
native ARP_ValidPropertyName(const internalname[])

// Checks to be sure a property is valid.
native ARP_ValidProperty(property)

// Adds a property.
// const internalname[] - what it will be called inside ARP
// const externalname[] - what it appears as to players
// const ownername[] - owner name as it appears on the door
// const ownerauth[] - steamid of the owner
// price - how much it costs (0 to disable)
// locked - whether it's locked or not
// access - access as an int for who can go in
// profit - how much money the property has made
native ARP_AddProperty(const internalname[],const externalname[],const ownername[],const ownerauth[],price,locked,access,profit)

// Removes a property.
// property - the property to remove
native ARP_DeleteProperty(property)

// Checks to be sure a door is valid.
native ARP_ValidDoorName(targetname[] = "",entid = 0)

// Checks to be sure a door is valid.
native ARP_ValidDoor(door)

// Adds a door.
// NOTE: You only need to specify targetname OR entid, not both
// const targetname[] - targetname of the door
// entid - entid of the door
// const internalname[] - internal name of the door
native ARP_AddDoor(const targetname[],entid,const internalname[])

// Removes a door.
// door - the door to remove
native ARP_DeleteDoor(door)

native ARP_PropertyMatch(targetname[] = "",entid = 0,internalname[] = "")

native ARP_DoorMatch(targetname[] = "",entid = 0)

native ARP_PropertyGetInternalName(property,externalname[],len)

native ARP_PropertyGetExternalName(property,externalname[],len)

native ARP_PropertySetExternalName(property,externalname[])

native ARP_PropertyGetOwnerName(property,ownername[],len)

native ARP_PropertySetOwnerName(property,ownername[])

native ARP_PropertyGetOwnerAuth(property,ownerauth[],len)

native ARP_PropertySetOwnerAuth(property,ownerauth[])

native ARP_PropertyGetPrice(property)

native ARP_PropertySetPrice(property,price)

native ARP_PropertyGetLocked(property)

native ARP_PropertySetLocked(property,locked)

native ARP_PropertyGetAccess(property)

native ARP_PropertySetAccess(property,access)

native ARP_PropertyGetProfit(property)

native ARP_PropertySetProfit(property,profit)

native ARP_PropertyAddAccess(property,authid[])

native ARP_PropertyRemoveAccess(property,authid[])

native ARP_PropertyClearAccess(property)

// called when someone buys a property
// return PLUGIN_HANDLED to stop
forward ARP_BuyProperty(id,doorid,const targetname[])

stock ARP_GiveKey(property,id)
{
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	ARP_PropertyAddAccess(property,Authid)
}

stock ARP_TakeKey(property,id)
{
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	ARP_PropertyRemoveAccess(property,Authid)
}

stock ARP_PropertyGetOwner(property)
{
	new Authid[36]
	ARP_PropertyGetOwnerAuth(property,Authid,35)
	
	new PlayerAuthid[36],Players[32],Playersnum,Player
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		get_user_authid(Player,PlayerAuthid,35)
		
		if(equali(Authid,PlayerAuthid))
			return Player
	}
	
	return FAILED
}

stock ARP_PropertySetOwner(property,id)
{	
	new Authid[36]
	get_user_authid(id,Authid,35)
	
	ARP_PropertySetOwnerAuth(property,Authid)
	
	return SUCCEEDED
}


#if defined _ApolloRP_NPCs_included
	#endinput
#endif

#define _ApolloRP_NPCs_included

#include <ApolloRP>

// Registers an NPC or zone. Note that this actually creates
// the NPC for you and sets it up as well. If zone is set to 1,
// the NPC will have no model, and anyone passing through the area will see
// the message explaining how to talk to the NPC. This is useful for ATMs,
// or NPCs that already exist in the map that you don't want to strip out.
// name[] - name of the NPC, ex. "Edeka Cashier"
// Float:origin[3] - where to spawn the NPC
// Float:angle - which direction it should face (0.0-180.0)
// model[] - the model the NPC should use (if not a zone)
// handler[] - function to call when a user presses "e" next to it
// zone - whether or not the NPC is a zone or human-looking figure
// property[] - the internal name of the property that it belongs to
native ARP_RegisterNpc(name[],Float:origin[3],Float:angle,model[],handler[],zone=0,property[] = "")

// returns SUCCEDED if is NPC, FAILED otherwise
native ARP_IsNpc(entid)

// Gets an NPC's name
stock ARP_GetNpcName(npc,string[],len)
{
	if(!is_valid_ent(npc) || !ARP_IsNpc(npc))
		return FAILED
	
	entity_get_string(npc,EV_SZ_noise1,string,len)
	
	return SUCCEEDED
}

// Gets the distance between a player and an NPC
stock ARP_NpcDistance(id,npc)
{
	if(!is_user_connected(id))
		return FAILED
	
	new Float:PlOrigin[3],Float:NpcOrigin[3]
	entity_get_vector(id,EV_VEC_origin,PlOrigin)
	entity_get_vector(npc,EV_VEC_origin,NpcOrigin)
	
	if(get_distance_f(PlOrigin,NpcOrigin) > 100.0)
	{
		client_print(id,print_chat,"[ARP] You are too far from this NPC.")
		return FAILED
	}
	
	return SUCCEEDED
}

stock ARP_GetNpcProperty(npc)
{
	if(!is_valid_ent(npc) || !ARP_IsNpc(npc))
		return -1
	
	new Property[64],Index
	entity_get_string(npc,EV_SZ_noise2,Property,63)
	
	if(!(Index = ARP_PropertyMatch(_,_,Property)))
		return -1
	
	return Index
}

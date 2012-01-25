#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

public plugin_init() 
	ARP_AddChat(_,"CmdSay")

public ARP_Init()
{
	ARP_RegisterPlugin("Say Commands","1.0","Hawk552","Allows players to use items with a chat command")
	ARP_AddCommand("say /item <itemname>","Allows usage of items in binds or chat")
}

public ARP_Error(const Reason[])
	pause("d")

public CmdSay(id,Mode,Args[])
{
	if(!is_user_alive(id) || !equali(Args,"/item",5))
		return PLUGIN_CONTINUE
	
	static ItemName[64],Dummy[2]
	parse(Args,Dummy,1,ItemName,63)
	
	new Items[2],Num = ARP_FindItemId(ItemName,Items,2)
	switch(Num)
	{
		case 0 :
			client_print(id,print_chat,"[ARP] Item ^"%s^" does not exist.",ItemName)
		case 1 :
			UseItem(id,Items[0])
		default :
		{
			client_print(id,print_chat,"[ARP] There is more than one item matching ^"%s^". You are using the first result.",ItemName)
			UseItem(id,Items[0])
		}
	}
	
	return PLUGIN_HANDLED
}

UseItem(id,ItemId)
{
	new ItemName[64]
	ARP_GetItemName(ItemId,ItemName,63)
	
	if(!ARP_GetUserItemNum(id,ItemId))
		return client_print(id,print_chat,"[ARP] You have no %ss.",ItemName)
	
	client_print(id,print_chat,"[ARP] Using %s.",ItemName)
	
	return ARP_ForceUseItem(id,ItemId,1)
}

#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

public ARP_Init() 
	ARP_RegisterPlugin("Dummy Items","1.0","Hawk552","Adds extra, non-functional items")	

public ARP_RegisterItems()
{
	new File = ARP_FileOpen("dummyitems.ini","r")
	if(!File)
		return
	
	new Buffer[256],Left[128],Right[128],Mode
	while(!feof(File))
	{
		fgets(File,Buffer,255)
		
		if(strlen(Buffer) < 2 || Buffer[0] == ';')
			continue
		
		replace(Buffer,255,"^n","")
		
		Mode = 0
		if(containi(Buffer,"(remove)") != -1)
		{
			replace(Buffer,255,"(remove)","")
			Mode = 1
		}
		
		parse(Buffer,Left,127,Right,127)
		remove_quotes(Left)
		trim(Left)
		remove_quotes(Right)
		trim(Right)
		
		ARP_RegisterItem(Left,"ItemHandle",Right,Mode)
	}
	
	fclose(File)
}

public ItemHandle(id,ItemId)
{
	client_print(id,print_chat,"[ARP] This item is unusable.")

	return ARP_ItemDone(id)
}
		

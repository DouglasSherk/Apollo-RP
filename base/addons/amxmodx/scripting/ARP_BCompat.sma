#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

new TravTrie:g_ArrayTrie

public plugin_init()
{	
	register_srvcmd("amx_additems","CmdSetItems")
	register_srvcmd("amx_delitems","CmdSetItems")	
}

public ARP_Init()
	ARP_RegisterPlugin("Backwards Compability",ARP_VERSION,"The Apollo RP Team","Allows Harbu items to be ran on ARP")

public ARP_Error(const Reason[])
	pause("d")

public ARP_RegisterItems()
{
	g_ArrayTrie = TravTrieCreate()
	
	new File = ARP_FileOpen("bcompat.ini","r")
	if(!File)
		set_fail_state("Configuration file not found")
	
	new Buffer[256],Name[64],ItemIDString[10],Command[64],ItemID,UseUpString[10],UseUp,ARPItemID
	while(!feof(File))
	{		
		fgets(File,Buffer,255)
		if(Buffer[0] == ';')
			continue
		
		parse(Buffer,ItemIDString,9,Name,63,Command,63,UseUpString,9)
		
		remove_quotes(Command)
		trim(Command)
		remove_quotes(Name)
		trim(Name)
		
		ItemID = str_to_num(ItemIDString)
		UseUp = str_to_num(UseUpString)
		
		if(!ItemID || !Command[0] || strlen(Command) < 2 || ARP_FindItemId(Name,UseUpString,1))
			continue
		
		ARPItemID = ARP_RegisterItem(Name,"ItemHandler"," ",UseUp)
		format(Command,63,"^"%s^" %d",Command,ARPItemID)
		
		TravTrieSetStringEx(g_ArrayTrie,ItemID,Command)
	}	
	
	fclose(File)
}

public plugin_end()
	TravTrieDestroy(g_ArrayTrie)

public ItemHandler(id,ARPItemID)
{
	if(!TravTrieSize(g_ArrayTrie))
		return
	
	new travTrieIter:Iter = GetTravTrieIterator(g_ArrayTrie),Command[64],OldCommand[64],ItemIDStr[10],ItemIDStr2[10]
	format(ItemIDStr,9,"%d",ARPItemID)
	
	while(MoreTravTrie(Iter))
	{
		ReadTravTrieString(Iter,OldCommand,63)
		strbreak(OldCommand,Command,63,ItemIDStr2,9)
			
		if(equali(ItemIDStr,ItemIDStr2))
			break
	}
	DestroyTravTrieIterator(Iter)
		
	remove_quotes(Command)
	trim(Command)
	
	new ID[10]
	format(ID,9,"%d",id)
	
	replace_all(Command,63,"<id>",ID)
	
	server_cmd("%s",Command)
	
	ARP_ItemDone(id)
}

public CmdSetItems()
{
	new Arg[33]
	read_argv(1,Arg,32)
	
	new id = cmd_target(0,Arg,0)
	if(!id || !is_user_alive(id))
		return
	
	new Command[6],Mode = 1
	read_argv(0,Command,5)
	
	if(equali(Command,"amx_d",5))
		Mode = -1
	
	read_argv(2,Arg,32)
	new ItemID = str_to_num(Arg)
	
	read_argv(3,Arg,32)
	new Num = str_to_num(Arg)
	
	new OldServerCmd[64],ServerCmd[64],ARPItemID,ItemIDStr[10]
	TravTrieGetStringEx(g_ArrayTrie,ItemID,OldServerCmd,63)
	
	strbreak(OldServerCmd,ServerCmd,63,ItemIDStr,9)
	remove_quotes(ServerCmd)
	trim(ServerCmd)
	
	ARPItemID = str_to_num(ItemIDStr)
	
	ARP_SetUserItemNum(id,ARPItemID,ARP_GetUserItemNum(id,ARPItemID) + Mode * Num)
}
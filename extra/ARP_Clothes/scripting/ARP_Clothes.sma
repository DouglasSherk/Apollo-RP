#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

#define DEFAULT_MODEL "collector-civilian"

new g_Clothes[33][33]

new g_DefaultModel[] = DEFAULT_MODEL

public plugin_init()	
	for(new Count;Count < 33;Count++)
		copy(g_Clothes[Count],32,g_DefaultModel)

public ARP_Init()
	ARP_RegisterPlugin("Clothes Mod","1.0","Hawk552","Restricts model usage")

public ARP_Error(const Reason[])
	pause("d")

public ARP_RegisterItems()
{
	new Model[128],Model2[128],File = ARP_FileOpen("clothes.ini","r")	
	if(!File)
	{
		set_fail_state("Clothes file missing")
		return
	}

	while(!feof(File))
	{	
		fgets(File,Model,127)
		switch(Model[0])
		{
			case 0:
				continue
			case ';':
				continue
		}
		
		format(Model2,127,"models/player/%s/%s.mdl",Model,Model)
		
		if(file_exists(Model2))
		{
			precache_generic(Model2)
			
			Model[0] = toupper(Model[0])
			add(Model,127," Clothes")
			ARP_RegisterItem(Model,"_Clothes",Model,0)
		}
		else
			ARP_ThrowError(AMX_ERR_GENERAL,0,"Model doesn't exist: %s",Model2)
	}
	
	format(Model2,127,"models/player/%s/%s.mdl",g_DefaultModel,g_DefaultModel)
	file_exists(Model2) ? precache_model(Model2) : ARP_ThrowError(AMX_ERR_GENERAL,0,"Model doesn't exist: %s",Model2)
	
	return
}

public client_putinserver(id)
	set_user_info(id,"model",g_DefaultModel)
	
public client_infochanged(id)
{
	new NewModel[33]
	get_user_info(id,"model",NewModel,32)
	
	if(equali(NewModel,g_DefaultModel))
		return PLUGIN_CONTINUE
	
	if(!equali(NewModel,g_Clothes[id]))
	{
		set_user_info(id,"model",g_Clothes[id])
		client_print(id,print_chat,"[ARP] You may not change clothes that way.")
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
	copy(g_Clothes[id],32,g_DefaultModel)

public _Clothes(id,ItemId)
{
	new Name[33]
	ARP_GetItemName(ItemId,Name,32)
	
	replace(Name,32," Clothes","")
	
	Name[0] = tolower(Name[0])
	
	copy(g_Clothes[id],32,Name)
	set_user_info(id,"model",Name)
	
	client_print(id,print_chat,"[ARP] You changed your clothes.")
	
	ARP_ItemDone(id)
}
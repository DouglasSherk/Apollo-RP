#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <fakemeta>

#define MAX_MODELS 3

new g_Models[MAX_MODELS][] = 
{
	"5eefd3eb081a92671878ec3ff6c81e07",
	"0ba223514932b1bda71d573abcc7296c",
	"6efe3f9f58e795ef09634a99a4c3be08"	
}

new p_Punish

public ARP_Init()
{
	ARP_RegisterPlugin("Crash Model Blocker","1.0","Hawk552","Blocks models which crash players")
	
	p_Punish = register_cvar("arp_model_punish","60")
}

public client_infochanged(id)
{
	new Model[33]
	get_user_info(id,"model",Model,32)
	
	strtolower(Model)
	
	new MD5[34]
	md5(Model,MD5)
	
	for(new i;i < MAX_MODELS;i++)
		if(equali(g_Models[i],MD5))
		{
			new Cvar = get_pcvar_num(p_Punish)
			Cvar == -1 ? server_cmd("kick #%d ^"Using a restricted model^"",get_user_userid(id)) : server_cmd("banid %d #%d ^"Using a restricted model^" kick",Cvar,get_user_userid(id))
			
			return
		}
}

public client_putinserver(id)
	client_infochanged(id)
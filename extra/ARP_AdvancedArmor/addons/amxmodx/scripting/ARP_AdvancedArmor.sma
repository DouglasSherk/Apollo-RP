#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <hamsandwich>

enum ARMOR
{
	NONE = 0,
	ASSAULT,
	POWER
}

#define ARMOR_USEUP 1

new ARMOR:g_Titanium[33]

new p_KevlarPenetration
new p_PowerPenetration

public plugin_init() register_event("DeathMsg","EventDeathMsg","a")

public ARP_Init() 
{
	ARP_RegisterPlugin("Advanced Armor","1.0","Hawk552","Creates items that give strong protection to the wearer")
	
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	
	p_KevlarPenetration = register_cvar("arp_kevlar_penetration","0.5")
	p_PowerPenetration = register_cvar("arp_power_penetration","0.1")
	
	RegisterHam(Ham_TakeDamage,"player","_Ham_TakeDamage")
}

public ARP_RegisterItems()
{
	ARP_RegisterItem("Assault Suit","_AssaultSuit","Protects the wearer significantly against damage to the head and chest",ARMOR_USEUP)
	ARP_RegisterItem("Power Armor","_PowerArmor","Stops almost all damage against the wearer",ARMOR_USEUP)
}

public EventHudRender(Name[],Data[],Len)	
{
	new id = Data[0]
	if(Data[1] == HUD_PRIM && g_Titanium[id]) 
		switch(g_Titanium[id])
		{
			case ASSAULT: ARP_AddHudItem(id,HUD_PRIM,0,"Armor: Assault Suit")
			case POWER: ARP_AddHudItem(id,HUD_PRIM,0,"Armor: Power Armor")
		}
}

public _AssaultSuit(id)
{
	client_print(id,print_chat,"[ARP] You slip on an Assault Suit. Your head and chest are now protected.")
	g_Titanium[id] = ASSAULT
}

public _PowerArmor(id)
{
	client_print(id,print_chat,"[ARP] You don Power Armor. You are now well protected against most types of damage.")
	g_Titanium[id] = POWER
}

public _Ham_TakeDamage(id,Inflictor,Attacker,Float:Damage,DamageBits)
{
	switch(g_Titanium[id])
	{
		case ASSAULT:
		{
			new Body,Garbage
			get_user_attacker(id,Garbage,Body)
			
			if(Body == HIT_HEAD || Body == HIT_CHEST || Body == HIT_STOMACH)
				SetHamParamFloat(4,Damage * get_pcvar_float(p_KevlarPenetration))
		}
		case POWER:
			SetHamParamFloat(4,Damage * get_pcvar_float(p_PowerPenetration))
	}
	
	return HAM_IGNORED
}

public EventDeathMsg()
	g_Titanium[read_data(2)] = NONE

public client_disconnect(id)
	g_Titanium[id] = NONE
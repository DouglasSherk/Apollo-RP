#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>
#include <fakemeta>
#include <tfcx>

public plugin_init()
{
	ARP_RegisterPlugin("TFC Compatibility",ARP_VERSION,"The ApolloRP Team","Provides TFC support for ARP")
	
	register_event("ResetHUD","EventResetHUD","be")

/*
	new MaxEnts = global_get(glb_maxEntities),TargetName[2],ClassName[33],TempEnt = create_entity("info_target")
	for(new Ent = 1;Ent < MaxEnts + 1;Ent++)
		if(pev_valid(Ent))
		{
			pev(Ent,pev_classname,ClassName,32)
			pev(Ent,pev_targetname,TargetName,1)
			
			if(TargetName[0] && (equali(ClassName,"func_door") || equali(ClassName,"func_door_rotating")))
				force_use(TempEnt,Ent)
		}
	remove_entity(TempEnt)
*/
}

public ARP_Error(const Reason[])
	pause("d")

public ARP_RegisterItems()
{
	ARP_RegisterItem("Knife","_Knife","A knife used for cutting things",1)
}

public _Knife(id,ItemId)
{
	give_item(id,"tf_weapon_knife")
}

public EventResetHUD(id)
	set_task(0.1,"StripWeapoons",id)

public StripWeapons(id)
{
	strip_user_weapons(id)

	tfc_setweaponbammo(id,TFC_WPN_CALTROP,0)
	tfc_setweaponbammo(id,TFC_WPN_CONCUSSIONGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_NORMALGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_NAILGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_MIRVGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_NAPALMGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_GASGRENADE,0)
	tfc_setweaponbammo(id,TFC_WPN_EMPGRENADE,0)
}

public client_PreThink(id)
{
	tfc_setbammo(id,TFC_AMMO_NADE1,0)
	tfc_setbammo(id,TFC_AMMO_NADE2,0)
}
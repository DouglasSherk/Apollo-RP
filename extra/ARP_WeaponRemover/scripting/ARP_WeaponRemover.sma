#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

public plugin_init()
{
	register_plugin("Weapon Remover","1.0","Hawk552")
	
	new Ent
	while((Ent = find_ent_by_class(Ent,"ts_groundweapon")) != 0)
		remove_entity(Ent)
}
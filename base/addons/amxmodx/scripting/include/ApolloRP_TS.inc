#if defined _ApolloRP_TS_included
	#endinput
#endif

#define _ApolloRP_TS_included

#define TS_MAX_WEAPONS 39

stock ts_giveweapon(id,weapon,clip,extra)
{
	new weaponid[10],extraclip[10],extraflags[10]

	num_to_str(weapon,weaponid,9)
	num_to_str(clip,extraclip,9)
	num_to_str(extra,extraflags,9)

	new ent = ts_weaponspawn(weaponid,"5",extraclip,extraflags,Float:{0.0,0.0,0.0})
	if(!ent)
		return PLUGIN_CONTINUE

	force_use(id,ent)

	remove_entity(ent)

	return PLUGIN_HANDLED
}

#if defined _ApolloRP_SC_included
	#endinput
#endif

#define _ApolloRP_SC_included

#define SC_MAX_WEAPONS 31

stock ARP_TakeDamage( victim, attacker, inflictor, const classname[], Float:damage, damageType )
{
	new data[128]
	data[0] = victim
	data[1] = attacker
	data[2] = inflictor
	data[3] = _:damage
	data[4] = damageType
	copy( data[5], sizeof data - 6, classname )

	new Float:takeDamage = entity_get_float( victim, EV_FL_takedamage )
	if ( takeDamage <= 0.0 )
		return FAILED

	if ( ARP_CallEvent( "Edict_Damage", data, sizeof data ) )
		return FAILED

	new Float:health = entity_get_float( victim, EV_FL_health )
	if ( health - damage <= 0.0 )
	{
		if ( ARP_CallEvent( "Edict_Kill", data, 2 ) )
			return FAILED

		if ( 1 <= victim <= 32 )
		{
			ARP_UserKill( victim, 0, attacker )
			return SUCCEEDED
		}
		else
			entity_set_int( victim, EV_INT_flags, entity_get_int( victim, EV_INT_flags ) | FL_KILLME )
	}

	entity_set_float( victim, EV_FL_health, health - damage )
}
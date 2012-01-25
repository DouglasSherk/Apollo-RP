#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>

new g_Started[33]

public plugin_init() 	
	register_event("ResetHUD","EventResetHUD","b")

public ARP_Init()
	ARP_RegisterPlugin("Notifications","1,0","Hawk552","Adds sounds for joining/leaving and OOC")

public EventResetHUD(id)
	if(!g_Started[id])
	{
		new Players[32],Playersnum
		get_players(Players,Playersnum)
		
		for(new Count;Count < Playersnum;Count++)
			client_cmd(Players[Count],id == Players[Count] ? "spk arp/notifications/playerstart.wav" : "spk arp/notifications/playerjoin.wav")
		
		g_Started[id] = 1
	}

public plugin_precache()
{
	precache_sound("arp/notifications/playerjoin.wav")
	precache_sound("arp/notifications/playerleave.wav")
	precache_sound("arp/notifications/message.wav")
	precache_sound("arp/notifications/playerstart.wav")
}

public client_disconnect(id)
{
	client_cmd(0,"spk arp/notifications/playerleave.wav")
	
	g_Started[id] = 0
}

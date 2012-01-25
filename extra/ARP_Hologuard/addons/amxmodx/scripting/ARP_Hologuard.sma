#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <bot_api>
#include <engine>
#include <fakemeta>
#include <fun>
#include <xs>
#include <tsfun>
#include <tsx>

new g_Name[] = "Hologuard"

new g_User
new g_Move = 1

new Float:Time

new g_Aggressors[33]

new g_Hello[] = "arp/hologuard/hello.wav"
new g_Greeting[] = "arp/hologuard/greeting.wav"
new g_Disable1[] = "arp/hologuard/cya1.wav"
new g_Disable2[] = "arp/hologuard/cya2.wav"
new g_Follow[] = "arp/hologuard/follow.wav"
new g_Stay[] = "arp/hologuard/stay.wav"
new g_Guard[] = "arp/hologuard/guard.wav"
new g_Drop[] = "arp/hologuard/drop.wav"
new g_Default1[] = "arp/hologuard/default1.wav"
new g_Default2[] = "arp/hologuard/default2.wav"
new g_Default3[] = "arp/hologuard/default3.wav"

public plugin_init() 
{	
	//register_clcmd("say","CmdSay")
	//ARP_RegisterEvent("Player_Say","CmdSay")
	ARP_AddChat(_,"CmdSay")
	
	register_event("DeathMsg","EventDeathMsg","a")
}

public ARP_Init()
	ARP_RegisterPlugin("Hologuard","1.0","Hawk552","Allows players to spawn a bodyguard")

public plugin_precache()
{
	precache_sound(g_Hello)
	precache_sound(g_Greeting)
	precache_sound(g_Disable1)
	precache_sound(g_Disable2)
	precache_sound(g_Follow)
	precache_sound(g_Stay)
	precache_sound(g_Guard)
	precache_sound(g_Drop)
	precache_sound(g_Default1)
	precache_sound(g_Default2)
	precache_sound(g_Default3)
}

public client_damage(Attacker,id,Damage,Weapon,Body,TA)
{
	if(!is_user_connected(Attacker) || !is_user_connected(id))
		return
	
	if(g_User == id || is_bot(id))
		g_Aggressors[Attacker] = 1
	else if(Attacker == g_User)
		g_Aggressors[id] = 1
}

public ARP_RegisterItems()
	ARP_RegisterItem("Hologuard","_Hologuard","A personal bodyguard capable of combat",1)

public _Hologuard(id,ItemId)
{	
	new Bot = FindBot()
	if(Bot)
	{
		client_print(id,print_chat,"[ARP] Sorry, the Hologuard service is currently in use.")
		ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
		
		return PLUGIN_HANDLED
	}
	
	new Players = get_playersnum(),MaxPlayers = get_maxplayers()
	if(MaxPlayers - Players < 2)
	{
		client_print(id,print_chat,"[ARP] There are too many players on the server to use the Hologuard.")
		ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
		
		return PLUGIN_HANDLED
	}
	
	for(new Count;Count <= 32;Count++)
		g_Aggressors[Count] = 0
	
	Bot = create_bot(g_Name)
	set_user_info(Bot,"model","agent")
	
	g_User = id
	Time = get_gametime()
	
	return set_task(0.1,"Spawn",Bot)
}

public Spawn(id)
{
	DispatchSpawn(id)
	
	new Float:Origin[3]
	entity_get_vector(g_User,EV_VEC_origin,Origin)
	
	Origin[1] -= 50.0
	entity_set_origin(id,Origin)
	
	if(!is_user_alive(id))
	{
		set_task(0.1,"Spawn",id)
		return
	}
	
	set_task(0.1,"Greet",id)
	
	ts_giveweapon(id,TSW_ABERETTAS,250,0)
	ts_giveweapon(id,TSW_MP5K,250,0)
}

public Greet(id)
{
	engclient_cmd(id,"say ^"Hi. I'm your personal holographic bodyguard. I'll defend you against any attackers.^"")
	PlaySound(id,g_Greeting)
}

public CmdSay(id,Mode,Args[])
{	
	if(!equali(Args,"hologuard",9))
		return
	
	replace(Args,255,"hologuard","")
	
	new Float:Origin[3],Float:BotOrigin[3],Bot = FindBot()
	if(!Bot)
		return
	
	entity_get_vector(id,EV_VEC_origin,Origin)
	entity_get_vector(Bot,EV_VEC_origin,BotOrigin)
	
	if(vector_distance(Origin,BotOrigin) > 500.0 || g_User != id)
		return
	
	if(containi(Args,"disable") != -1 || containi(Args,"turn off") != -1 || containi(Args,"not needed") != -1)
	{
		PlaySound(Bot,random_num(0,1) == 0 ? g_Disable1 : g_Disable2)
		
		remove_bot(Bot)
	}
	else if(containi(Args,"stay") != -1)
	{
		PlaySound(Bot,g_Move ? g_Stay : g_Follow)
		g_Move = !g_Move
	}
	else if(containi(Args,"come") != -1 || containi(Args,"follow") != -1)
	{
		g_Move = 1
		PlaySound(Bot,g_Follow)
	}
	else if(containi(Args,"guard") != -1)
	{
		new Index,Body
		get_user_aiming(id,Index,Body,100)
		
		if(is_user_alive(Index))
		{
			PlaySound(Bot,g_Guard)
			g_User = Index
		}
	}
	else if(containi(Args,"drop") != -1)
	{
		engclient_cmd(Bot,"drop")
		PlaySound(Bot,g_Drop)
	}
	else if(containi(Args,"hello") != -1)
		PlaySound(Bot,g_Hello)
	else
		switch(random_num(0,2))
		{
			case 0 :
				PlaySound(Bot,g_Default1)
			case 1 :
				PlaySound(Bot,g_Default2)
			case 2 :
				PlaySound(Bot,g_Default3)
		}
}

public EventDeathMsg()
{
	new id = read_data(2)
	if(FindBot() == id)
		remove_bot(id)
	
	g_Aggressors[id] = 0
}

public client_putinserver(id)
{
	new Bot = FindBot()
	if(!Bot)
		return
	
	new Players = get_playersnum(),MaxPlayers = get_maxplayers()
	if(MaxPlayers - Players > 1)
		return
	
	client_print(g_User,print_chat,"[ARP] Your hologuard must be removed as there are not enough slots on the server to support it.")
	
	remove_bot(Bot)
}

public client_disconnect(id)
{
	new Bot = FindBot()
	if(Bot && g_User == id)
		remove_bot(Bot)
	
	g_Aggressors[id] = 0
}
	
public bot_think(id)
{
	if(FindBot() != id)
		return
	
	new User = fm_is_ent_visible(id,g_User) ? g_User : 0,Float:Origin[3],Float:BotOrigin[3]
	entity_get_vector(id,EV_VEC_origin,BotOrigin)	
	
	new Players[32],Playersnum,Player
	get_players(Players,Playersnum,"a")
	
	for(new Count,Float:Distance = 9999999.0,Float:CmpDistance;Count < Playersnum;Count++)
	{
		Player = Players[Count]
		if(Player == id || Player == g_User || !g_Aggressors[Player] || !fm_is_ent_visible(id,Player))
			continue
		
		entity_get_vector(Player,EV_VEC_origin,Origin)
		
		CmpDistance = vector_distance(Origin,BotOrigin)
		
		if((CmpDistance < Distance))
		{
			Distance = CmpDistance
			User = Player
		}
	}
	
	if(!User)
		return
	
	entity_get_vector(User,EV_VEC_origin,Origin)
	new Float:Distance = vector_distance(Origin,BotOrigin),Buttons = random(2) == 1 ? IN_USE : 0
	
	Origin[2] -= 10.0
	set_bot_angles(id,Origin)
	
	if((User != g_User || g_Move) && is_user_alive(User) && ((User != g_User) || (User == g_User  && Distance > 200.0)))
	{
		new Float:Velocity[3],Float:Factor
		
		for(new Count;Count < 3;Count++)
		{
			Velocity[Count] = 20.0 * (Origin[Count] - BotOrigin[Count])
			
			if(floatabs(Velocity[Count]) > 280.0 && floatabs(Velocity[Count]) >= floatabs(Velocity[0]) && floatabs(Velocity[Count]) >= floatabs(Velocity[1]) && floatabs(Velocity[Count]) >= floatabs(Velocity[2]))
				Factor = floatabs(Velocity[Count]) / 280.0
		}
		
		if(Factor)
			for(new Count;Count < 3;Count++)
				Velocity[Count] /= Factor
			
		if(Velocity[2] > 0.0)
			Velocity[2] = -floatabs(Velocity[2])
			
		entity_set_vector(id,EV_VEC_velocity,Velocity)
	}
	
	new Dummy,Clip,Ammo,Weapon = ts_getuserwpn(id,Clip,Ammo,Dummy,Dummy)
	if(Clip == 0 && Ammo == 0 && Weapon != TSW_KUNG_FU && get_gametime() - Time > 5)
		engclient_cmd(id,"drop")
	
	if(User == g_User)
	{
		set_bot_data(id,bot_buttons,Buttons)
		return
	}
	
	switch(Weapon)
	{
		case TSW_KATANA,TSW_KUNG_FU,TSW_CKNIFE,TSW_SKNIFE:
		{
			Buttons |= (Distance < 75.0 && random(2) == 1) ? IN_ATTACK : 0
			if(Buttons & IN_ATTACK && random(2) == 1)
			{
				Buttons |= IN_ATTACK2
				Buttons -= IN_ATTACK
			}
		}
		default:
		{			
			if(Clip == 0)
				Buttons = IN_RELOAD
			else
				Buttons |= random(2) == 1 ? IN_ATTACK : 0
		}
	}
		
	set_bot_data(id,bot_buttons,Buttons)
}

FindBot()
{
	new Players[32],Playersnum
	get_players(Players,Playersnum,"d")
	
	for(new Count,Name[33];Count < Playersnum;Count++)
		if(is_bot(Players[Count]))
		{
			get_user_name(Players[Count],Name,32)
			if(equali(Name,g_Name))
				return Players[Count]
		}
	
	return 0
}

stock bool:fm_is_ent_visible(index, entity) 
{
    new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
    pev(index, pev_origin, origin)
    pev(index, pev_view_ofs, view_ofs)
    xs_vec_add(origin, view_ofs, eyespos)

    new Float:entpos[3]
    pev(entity, pev_origin, entpos)
    engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

    switch (pev(entity, pev_solid)) {
        case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
    }
    
    new Float:fraction
    global_get(glb_trace_fraction, fraction)
    if (fraction == 1.0)
        return true

    return false
}

PlaySound(id,sample[])
	emit_sound(id,CHAN_AUTO,sample,VOL_NORM,ATTN_NORM,0,PITCH_LOW)

#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>
#include <fun>

new g_ClassName[] = "murder_body"

new p_Time
new p_DeathMsg
new p_ShowAttacker

new g_MsgDeathMsg

public plugin_init()
{
	register_plugin("Murder Mod","1.0","Hawk552")
	
	register_event("DeathMsg","EventDeathMsg","a")
	
	p_Time = register_cvar("arp_murder_time","60.0")
	p_DeathMsg = register_cvar("arp_murder_deathmsg","1")
	p_ShowAttacker = register_cvar("arp_murder_showattacker","1")
	
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	set_msg_block(g_MsgDeathMsg,get_pcvar_num(p_DeathMsg) ? BLOCK_SET : BLOCK_NOT)
	
	register_think(g_ClassName,"MurderThink")
	
	//register_clcmd("set_seq","SetSeq")
	
	set_task(10.0,"CheckView")
}

public client_disconnect(id)
{
	new Ent
	while((Ent = find_ent_by_class(Ent,g_ClassName)) != 0)
	{
		if(entity_get_int(Ent,EV_INT_iuser1) == id)
			entity_set_int(Ent,EV_INT_iuser1,0)
		
		if(entity_get_edict(Ent,EV_ENT_owner) == id)
			remove_entity(Ent)
	}
}

public ARP_Init()
	ARP_RegisterPlugin("Murder Mod","1.0","Hawk552","Creates dead bodies lasting longer")

public ARP_RegisterItems()
{
	ARP_RegisterItem("Forensics Kit","_ForensicsKit","Allows players to check a victim and killer")
	ARP_RegisterItem("Mop","_Mop","Cleans up dead bodies")
}

public _Mop(id)
{
	new Index,Body
	get_user_aiming(id,Index,Body,700)
	
	if(!Index)
	{
		client_print(id,print_chat,"[ARP] You are not looking at a dead body.")
		return
	}
	
	static ClassName[33]
	entity_get_string(Index,EV_SZ_classname,ClassName,32)
	
	if(!equali(ClassName,g_ClassName))
	{
		client_print(id,print_chat,"[ARP] You are not looking at a dead body.")
		return
	}
	
	client_cmd(id,"say ^"/me mops up the dead body^"")
	
	remove_entity(Index)
	client_print(id,print_chat,"[ARP] You have cleaned up this body.")
}

public _ForensicsKit(id)
{
	new Index,Body
	get_user_aiming(id,Index,Body,700)
	
	if(!Index)
	{
		client_print(id,print_chat,"[ARP] You are not looking at a dead body.")
		return
	}
	
	static ClassName[33]
	entity_get_string(Index,EV_SZ_classname,ClassName,32)
	
	if(!equali(ClassName,g_ClassName))
	{
		client_print(id,print_chat,"[ARP] You are not looking at a dead body.")
		return
	}
	
	static VictimName[33],AttackerName[33]
	new Attacker = entity_get_int(Index,EV_INT_iuser1)
	get_user_name(entity_get_edict(Index,EV_ENT_owner),VictimName,32)
	
	if(Attacker)
		get_user_name(Attacker,AttackerName,32)
	
	client_cmd(id,"say ^"/me dusts the body for fingerprints^"")
	
	new CurrentTime[10] 
	get_time("%H:%M:%S",CurrentTime,9) 
	
	new DeathTime[10]
	entity_get_string(Index,EV_SZ_noise1,DeathTime,9)
	
	client_print(id,print_chat,"[ARP] Victim name: %s",VictimName)
	client_print(id,print_chat,"[ARP] Attacker name: %s",AttackerName)
	client_print(id,print_chat,"[ARP] Time of death: %s (Current time: %s)",DeathTime,CurrentTime)
}

public SetSeq()
{
	new Ent = find_ent_by_class(-1,g_ClassName),Arg[32]
	read_argv(1,Arg,31)
	
	new Num = str_to_num(Arg)
	
	entity_set_int(Ent,EV_INT_sequence,Num)
}

public EventDeathMsg()
{
	new Data[2]
	Data[0] = read_data(1)
	Data[1] = read_data(2)
	
	set_msg_block(g_MsgDeathMsg,get_pcvar_num(p_DeathMsg) ? BLOCK_SET : BLOCK_NOT)
	
	set_task(2.0,"DelayedDeathMsg",_,Data,2)
}

public DelayedDeathMsg(Data[])
{	
	new Float:Origin[3],Float:Angle[3],Model[33],Attacker = Data[0],id = Data[1]
	entity_get_vector(id,EV_VEC_origin,Origin)
	entity_get_vector(id,EV_VEC_v_angle,Angle)
	entity_get_string(id,EV_SZ_model,Model,32)
	
	Origin[2] -= 40.0
	entity_set_origin(id,Origin)
	Origin[2] += 40.0
	
	new CurrentTime[10] 
	get_time("%H:%M:%S",CurrentTime,9) 
	
	new Ent = create_entity("info_target")
	
	entity_set_string(Ent,EV_SZ_classname,g_ClassName)
	entity_set_model(Ent,Model)
	entity_set_int(Ent,EV_INT_movetype,MOVETYPE_FLY)
	entity_set_int(Ent,EV_INT_sequence,148)
	entity_set_size(Ent,Float:{-6.0,-12.0,-6.0},Float:{6.0,12.0,6.0})
	entity_set_int(Ent,EV_INT_solid,SOLID_BBOX)
	entity_set_float(Ent,EV_FL_nextthink,get_pcvar_num(p_Time) + halflife_time())
	entity_set_vector(Ent,EV_VEC_v_angle,Angle)
	entity_set_edict(Ent,EV_ENT_owner,id)
	entity_set_int(Ent,EV_INT_iuser1,Attacker)
	entity_set_string(Ent,EV_SZ_noise1,CurrentTime)
	
	entity_set_origin(Ent,Origin)
	drop_to_floor(Ent)
	entity_get_vector(Ent,EV_VEC_origin,Origin)
	Origin[2] += 13.0
	entity_set_origin(Ent,Origin)
		
	set_task(get_pcvar_float(p_Time),"MurderThink",Ent)
}

public CheckView()
{
	new Players[32],Playersnum,id
	get_players(Players,Playersnum)
	
	for(new i;i < Playersnum;i++)
	{
		id = Players[i]
		
		new Index,Body
		get_user_aiming(id,Index,Body,300)
		
		if(!Index)
			continue
		
		static ClassName[33]
		entity_get_string(Index,EV_SZ_classname,ClassName,32)
		
		if(!equal(ClassName,g_ClassName))
			continue
			
		static Msg[128],VictimName[33],AttackerName[33]
		
		new Attacker = entity_get_int(Index,EV_INT_iuser1)
		get_user_name(entity_get_edict(Index,EV_ENT_owner),VictimName,32)
		
		if(Attacker)
			get_user_name(Attacker,AttackerName,32)
		
		format(Msg,127,"Victim: %s^n",VictimName)
		if(Attacker && get_pcvar_num(p_ShowAttacker))
		{
			add(Msg,127,"Attacker: ")
			add(Msg,127,AttackerName)
		}
		
		client_print(id,print_center,"%s",Msg)
	}
	
	set_task(0.1,"CheckView")
}

public MurderThink(Ent) remove_entity(Ent)
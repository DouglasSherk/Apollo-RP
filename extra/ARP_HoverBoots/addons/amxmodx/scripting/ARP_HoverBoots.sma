// Thanks to -]ToC[-Bludy

#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>
#include <fun>

// Change this line to the access level you want and recompile if you wish to set it differently.
#define ADMIN_ACCESS ADMIN_IMMUNITY

new bool: isflying[33]
new bool: flytoggle[33]
new Float: Velocity[33][3]
new fly_trail
new light

new p_FlyMode
new p_FlySpeed
new p_FlyTrailBrightness
new p_FlyTrails
new p_HoverGrav

new g_HoverBoots

public plugin_precache()
{
	fly_trail = precache_model("sprites/zbeam4.spr")
	light = precache_model("sprites/lgtning.spr") 
	
	return PLUGIN_CONTINUE
}

public ARP_Init() ARP_RegisterPlugin("Hover Boots","0.9.5.3","-]ToC[-Bludy","Allows players to fly - Ported by Hawk552")

public ARP_RegisterItems() g_HoverBoots = ARP_RegisterItem("Hover Boots","_HoverBoots","Allows you to fly")

public plugin_init() 
{	
	register_clcmd("+fly","make_fly",0,"Makes you change into fly mode")
	register_clcmd("-fly","stop_fly",0,"Makes you change back from fly mode to normal")
	
	p_FlyMode = register_cvar("arp_hover_flymode","1")
	p_FlySpeed = register_cvar("arp_hover_flyspeed","500")
	p_FlyTrailBrightness = register_cvar("arp_hover_flytrailbrightness","255")
	p_FlyTrails = register_cvar("arp_hover_flytrails","1")
	p_HoverGrav = register_cvar("arp_hover_grav","0.001")
	
	register_event("DeathMsg","EventDeathMsg","a")
}

public EventDeathMsg()
	stop_fly(read_data(2))

public client_disconnect(id)
	stop_fly(id)

public _HoverBoots(id)
{
	client_print(id,print_chat,"[ARP] You %s your hover boots.",isflying[id] ? "take off" : "put on")
	
	isflying[id] ? stop_fly(id) : make_fly(id)
}

public make_fly(id)
{
	if(get_pcvar_num(p_FlyMode) == 0 || !is_user_alive(id) || !ARP_GetUserItemNum(id,g_HoverBoots)) return PLUGIN_HANDLED
	
	if(flytoggle[id])
	{
		stop_fly(id)
		return PLUGIN_HANDLED
	}
	
	EnterFly(id)
	
	return PLUGIN_HANDLED
}

EnterFly(id)
{
	new teamname[20]
	get_user_team(id,teamname,19)
	
	if(get_pcvar_num(p_FlyTrails) == 1)
	{
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte(22)
		write_short(id)
		write_short(fly_trail)
		write_byte(50)
		write_byte(10)
		write_byte(255)
		write_byte(255)
		write_byte(255)
		write_byte(get_pcvar_num(p_FlyTrailBrightness))
		message_end()
		
		new Origin[3]
		get_user_origin(id,Origin)
		
		message_begin(MSG_ALL,SVC_TEMPENTITY)
		write_byte(19)
		write_coord(Origin[0])
		write_coord(Origin[1])
		write_coord(Origin[2])
		write_coord(Origin[0] + 24)
		write_coord(Origin[1] + 45)
		write_coord(Origin[2] + -66)
		write_short(light)
		write_byte(0) // starting frame
		write_byte(15) // frame rate in 0.1s
		write_byte(10) // life in 0.1s
		write_byte(20) // line width in 0.1s
		write_byte(1) // noise amplitude in 0.01s
		write_byte(255)
		write_byte(255)
		write_byte(255)
		write_byte(400) // brightness
		write_byte(1) // scroll speed in 0.1s
		message_end()
	}
	
	set_rendering(id,kRenderFxGlowShell,255,255,255,kRenderNormal,50)
	
	new parm[1]
	parm[0] = id
	
	set_user_gravity(id, get_pcvar_float(p_HoverGrav))
	
	set_task(0.1,"user_fly",5327+id, parm,1, "b")
	
	isflying[id] = true
}

public user_fly(parm[])
{
	if(get_pcvar_num(p_FlyMode) == 0) return PLUGIN_HANDLED
	
	new Float: xAngles[3]
	new Float: xOrigin[3]
	
	new xEnt
	
	new id
	id = parm[0]
	
	if(!is_user_alive(id)) stop_fly(id)
	
	if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_JUMP)  // FORWARD + MOVERIGHT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] -= 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_DUCK)  // FORWARD + MOVERIGHT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] -= 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_JUMP)  // FORWARD + MOVELEFT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] += 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_DUCK)  // FORWARD + MOVELEFT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] += 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_JUMP && get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_BACK)  // BACK + MOVERIGHT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] -= 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_BACK && get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_DUCK)  // BACK + MOVERIGHT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] -= 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_JUMP && get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_BACK)  // BACK + MOVELEFT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] += 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_BACK && get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_DUCK)  // BACK + MOVELEFT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] += 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_FORWARD) //  MOVERIGHT  + FORWARD
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] -= 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_BACK) // MOVERIGHT + BACK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] -= 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_FORWARD) // MOVELEFT + FORWARD
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] += 45
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_BACK) // MOVELEFT + BACK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] += 135
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_JUMP)  // FORWARD + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD && get_user_button(id)&IN_DUCK)  // FORWARD + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_BACK && get_user_button(id)&IN_JUMP)  // BACK + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] += 180
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_BACK && get_user_button(id)&IN_DUCK)  // BACK + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] += 180
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}	
	else if(get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_JUMP)  // MOVERIGHT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] -= 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVERIGHT && get_user_button(id)&IN_DUCK)  // MOVERIGHT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] -= 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_JUMP)  // MOVELEFT + JUMP
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = -45.0
		xAngles[1] += 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVELEFT && get_user_button(id)&IN_DUCK)  // MOVELEFT + DUCK
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 45.0
		xAngles[1] += 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_FORWARD) // FORWARD
		VelocityByAim(id, get_pcvar_num(p_FlySpeed) , Velocity[id])
	else if(get_user_button(id)&IN_BACK) // BACK
		VelocityByAim(id, -get_pcvar_num(p_FlySpeed) , Velocity[id])
	else if(get_user_button(id)&IN_DUCK) // DUCK
	{
		Velocity[id][0] = 0.0
		Velocity[id][1] = 0.0
		Velocity[id][2] = -get_pcvar_num(p_FlySpeed) * 1.0
	}
	else if(get_user_button(id)&IN_JUMP) // JUMP
	{
		Velocity[id][0] = 0.0
		Velocity[id][1] = 0.0
		Velocity[id][2] = get_pcvar_num(p_FlySpeed) * 1.0
	}
	else if(get_user_button(id)&IN_MOVERIGHT) // MOVERIGHT
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] -= 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else if(get_user_button(id)&IN_MOVELEFT) // MOVELEFT
	{
		entity_get_vector(id, EV_VEC_v_angle, xAngles)
		entity_get_vector(id, EV_VEC_origin, xOrigin)
		
		xEnt = create_entity("info_target")
		if(xEnt == 0) { 
			return PLUGIN_HANDLED_MAIN 
		}
		
		xAngles[0] = 0.0
		xAngles[1] += 90
		
		entity_set_origin(xEnt, xOrigin)
		entity_set_vector(xEnt, EV_VEC_v_angle, xAngles)
		
		VelocityByAim(xEnt, get_pcvar_num(p_FlySpeed), Velocity[id])
		
		remove_entity(xEnt)
	}
	else
	{
		Velocity[id][0] = 0.0
		Velocity[id][1] = 0.0
		Velocity[id][2] = 0.0
	}
	
	
	entity_set_vector(id, EV_VEC_velocity, Velocity[id])
	
	new Float: pOrigin[3]
	new Float: zOrigin[3]
	new Float: zResult[3]
	
	entity_get_vector(id, EV_VEC_origin, pOrigin)
	
	zOrigin[0] = pOrigin[0]
	zOrigin[1] = pOrigin[1]
	zOrigin[2] = pOrigin[2] - 1000
	
	trace_line(id,pOrigin, zOrigin, zResult)
	
	if(entity_get_int(id, EV_INT_sequence) != 8 && (zResult[2] + 100) < pOrigin[2] && is_user_alive(id) && (Velocity[id][0] > 0.0 && Velocity[id][1] > 0.0 && Velocity[id][2] > 0.0)) 
		entity_set_int(id, EV_INT_sequence, 8)
	
	return PLUGIN_HANDLED
}

public stop_fly(id)
{
	if(get_pcvar_num(p_FlyMode) == 0) return PLUGIN_HANDLED
	
	if(!isflying[id]) return PLUGIN_HANDLED
	
	if(get_pcvar_num(p_FlyTrails) == 1)
	{
		message_begin( MSG_ONE,SVC_TEMPENTITY,{0,0,0},id )
		write_byte(99)
		write_short(id)
		message_end()
	}
	
	set_rendering(id,kRenderFxNone,255,255,255,kRenderNormal,16)
	
	set_user_gravity(id)
	
	isflying[id] = false
	flytoggle[id] = false
	remove_task(5327+id)
	
	return PLUGIN_HANDLED
}
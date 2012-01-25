#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <fakemeta>
#include <hamsandwich>
#include <tsx>
#include <tsfun>

new g_Gunslinger
new g_AdamantiumSkeleton
new g_Criticals
new g_Finesse
new g_IronFist
new g_ParalyzingPalm
new g_LightStep
new g_Marksman
new g_Ninja
new g_FastMetabolism

new g_FirstWeapon[33]

new g_LastRender[33]

public ARP_Init()
{
	register_plugin("Perk Mod","1.0","Hawk552")
	
	register_forward(FM_PlayerPreThink,"ForwardPlayerPreThink")
	register_forward(FM_PlayerPostThink,"ForwardPlayerPostThink")
	register_forward(FM_UpdateClientData,"ForwardUpdateClientData",1)
	
	RegisterHam(Ham_TakeDamage,"player","_Ham_TakeDamage")
	
	register_event("ResetHUD","EventResetHUD","be")
	register_event("WeaponInfo","EventWeaponInfo","be")
	
	register_clcmd("fullupdate","CmdFullUpdate")
	
	set_task(0.1,"SetPunch",_,_,_,"b")
}

public client_disconnect(id) g_FirstWeapon[id] = 0

public SetPunch()
{
	new Players[32],Playersnum,Player,Garbage,Float:Punchangle[3]
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
	{		
		Player = Players[Count]
		
		if(ARP_GetUserItemNum(Player,g_Gunslinger)) continue
		
		switch(ts_getuserwpn(Player,Garbage,Garbage,Garbage))
		{
			case TSW_KATANA,TSW_KUNG_FU,TSW_CKNIFE,TSW_SKNIFE,TSW_TKNIFE:
				continue
			default:
			{
				if(!g_FirstWeapon[Player]) continue
				
				for(new Count;Count < 3;Count++)
					Punchangle[Count] = random_float(-2.0,2.0)
				
				set_pev(Player,pev_punchangle,Punchangle)
			}
		}
	}
}

public CmdFullUpdate() return PLUGIN_HANDLED

public EventResetHUD(id)
{
	if(!is_user_alive(id)) return
	
	if(ARP_GetUserItemNum(id,g_FastMetabolism)) set_task(0.1,"SetHealth",id)
	
	if(ARP_GetUserItemNum(id,g_LightStep)) set_user_footsteps(id,0)
	
	if(ARP_GetUserItemNum(id,g_Finesse)) set_user_maxspeed(id,get_user_maxspeed(id) * 1.1)
}

public EventWeaponInfo(id)
{
	g_FirstWeapon[id] = 1
		
	if(ARP_GetUserItemNum(id,g_Finesse)) set_user_maxspeed(id,get_user_maxspeed(id) * 1.1)
}

public SetHealth(id) set_user_health(id,110)

public ARP_RegisterItems()
{
	g_Gunslinger = ARP_RegisterItem("Gunslinger Perk","_Perk","Stabilizes gun targetting")
	g_AdamantiumSkeleton = ARP_RegisterItem("Adamantium Skeleton Perk","_Perk","Fu hits against you do 80 percent damage")
	g_Criticals = ARP_RegisterItem("Criticals Perk","_Perk","You occasionally deal 50 percent more damage")
	g_Finesse = ARP_RegisterItem("Finesse Perk","_Perk","You run slightly faster")
	g_IronFist = ARP_RegisterItem("Iron Fist Perk","_Perk","Your fu hits do 10 percent more damage")
	g_ParalyzingPalm = ARP_RegisterItem("Paralyzing Palm Perk","_Perk","Your fu hits occasionally stun your target")
	g_LightStep = ARP_RegisterItem("Light Step Perk","_Perk","Your footsteps make no sound")
	g_Marksman = ARP_RegisterItem("Marksman Perk","_Perk","You can use shotguns, rifles and machine-guns")
	g_Ninja = ARP_RegisterItem("Ninja Perk","_Perk","You fade into your surroundings slightly when standing still")
	g_FastMetabolism = ARP_RegisterItem("Fast Metabolism Perk","_Perk","You start with 110 HP")
}

public _Perk(id,ItemId) client_print(id,print_chat,"[ARP] This item cannot be used.")

public _Ham_TakeDamage(id,Inflictor,Attacker,Float:Damage,DamageBits)
{
	if(!is_user_alive(id) || !is_user_alive(Attacker)) return HAM_IGNORED
	
	new Dummy,Weapon = ts_getuserwpn(Attacker,Dummy,Dummy,Dummy,Dummy)
	if(Weapon == TSW_KUNG_FU)
	{
		if(ARP_GetUserItemNum(id,g_AdamantiumSkeleton)) Damage *= 0.8
		
		if(ARP_GetUserItemNum(Attacker,g_IronFist)) Damage *= 1.1
		
		if(ARP_GetUserItemNum(Attacker,g_ParalyzingPalm) && !random_num(0,7)) 
		{
			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("TSFade"),{0,0,0},id)
			write_short(1<<300)
			write_short(1<<300)
			write_short(1<<12)
			write_byte(0)
			write_byte(0) 
			write_byte(0)
			write_byte(255)
			message_end()
			
			new Float:Punchangle[3]
			for(new Count;Count < 3;Count++)
				Punchangle[Count] = random_float(-100.0,100.0)
	
			set_pev(id,pev_punchangle,Punchangle)
		}
	}
	
	if(ARP_GetUserItemNum(Attacker,g_Criticals) && !random_num(0,7)) Damage *= 1.5
	
	SetHamParamFloat(4,Damage)
	
	return HAM_IGNORED
}

public ForwardPlayerPreThink(id)
{
	if(!is_user_alive(id) || ARP_GetUserItemNum(id,g_Marksman)) return
	
	new Garbage
	switch(ts_getuserwpn(id,Garbage,Garbage,Garbage))
	{
		case TSW_M3,TSW_M4A1,TSW_MP5SD,TSW_USAS,TSW_AK47,TSW_AUG,TSW_M82A1,TSW_MP7,TSW_SPAS,TSW_UMP,TSW_MOSSBERG,TSW_M16A4,TSW_M60E3:
		{
			new Button = pev(id,pev_button)
			if(Button & IN_ATTACK)
			{
				if(!(pev(id,pev_oldbuttons) & IN_ATTACK)) client_print(id,print_chat,"[ARP] You need the ^"Marksman^" perk to be able to use this gun.")
				set_pev(id,pev_button,Button - IN_ATTACK)
			}
		}
	}
}

public ForwardPlayerPostThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	
	if(ARP_GetUserItemNum(id,g_Ninja))
	{	
		new Float:Velocity[3]
		pev(id,pev_velocity,Velocity)
		new Float:Speed = Velocity[0] + Velocity[1] + Velocity[2],Modifier = Speed != 0.0 ? 1 : -1,Float:RenderAmount = float((g_LastRender[id] = clamp(g_LastRender[id] + Modifier,0,255)) + 100),Dummy,Weapon = ts_getuserwpn(id,Dummy,Dummy,Dummy,Dummy)
		switch(Weapon)
		{
			case TSW_KATANA,TSW_KUNG_FU,TSW_CKNIFE,TSW_SKNIFE,TSW_TKNIFE:
				RenderAmount -= 50.0
		}
		
		set_pev(id,pev_renderfx,kRenderFxGlowShell)
		set_pev(id,pev_rendercolor,Float:{0.0,0.0,0.0})
		set_pev(id,pev_rendermode,kRenderTransAlpha)
		set_pev(id,pev_renderamt,RenderAmount)
	}
	
	return FMRES_IGNORED
}

public ForwardUpdateClientData(id,SendWeapons,CDHandle)
{
	if(!is_user_alive(id) || ARP_GetUserItemNum(id,g_Marksman))
		return FMRES_IGNORED
	
	new Garbage
	switch(ts_getuserwpn(id,Garbage,Garbage,Garbage))
	{
		case TSW_M3,TSW_M4A1,TSW_MP5SD,TSW_USAS,TSW_AK47,TSW_AUG,TSW_M82A1,TSW_MP7,TSW_SPAS,TSW_UMP,TSW_MOSSBERG,TSW_M16A4,TSW_M60E3,TSW_M61GRENADE,TSW_MP5K:
			set_cd(CDHandle,CD_ID,0)
	}
	
	return FMRES_HANDLED
}
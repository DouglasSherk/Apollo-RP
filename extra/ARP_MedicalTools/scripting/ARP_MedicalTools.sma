#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
//#include <tsfun>
#include <fun>
#include <ApolloRP>

enum _:HITSPOT
{
	GENERIC,
	HEAD,
	CHEST,	
	STOMACH,
	LEFTARM,
	RIGHTARM,
	LEFTLEG,
	RIGHTLEG
}

new g_Hits[HITSPOT][] = 
{
	"generic",
	"head",
	"chest",
	"stomach",
	"left arm",
	"right arm",
	"left leg",
	"right leg"
}

enum _:BLEEDING
{
	NONE = 0,
	LIGHTLY,
	MODERATELY,
	HEAVILY,
	MASSIVELY
}

new g_Bleed[BLEEDING][] =
{
	"None",
	"Light",
	"Moderate",
	"Heavy",
	"Massive"
}

new g_Damage[512]

new g_HitInfo[33][HITSPOT]
new g_Fell[33]
new g_Bleeding[33]
new g_Pain[33]
new g_HeartBeatSet[33]
new g_NoHoldGuns[33]
new g_Killed[33]

new p_HitSpeed
new p_PainHeal
new p_MaxPain
new p_BreakDamage
new p_BleedDamage
new p_BleedOut

new g_HeartBeat[] = "player/heartbeat1.wav"

new g_Splint
new g_Morphine
new g_Bandage
new g_Tensor
new g_Regenerator

//new g_Name[] = "Emergency Medical Hologram"

public plugin_init() 
{	
	p_HitSpeed = register_cvar("arp_medical_hitspeed","220")
	p_PainHeal = register_cvar("arp_medical_painheal","50")
	p_MaxPain = register_cvar("arp_medical_maxpain","200")
	p_BreakDamage = register_cvar("arp_medical_breakdamage","25")
	p_BleedDamage = register_cvar("arp_medical_bleeddamage","10")
	p_BleedOut = register_cvar("arp_medical_bleedout","0")
	
	register_forward(FM_PlayerPreThink,"PreThink")
	
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	ARP_RegisterEvent("Player_HealBegin","EventPlayerHealBegin")
	ARP_RegisterEvent("Player_HealEnd","EventPlayerHealEnd")
	
	//register_clcmd("say","CmdSay")
	
	register_event("DeathMsg","DeathMsg","a")
	register_event("WeaponInfo","WeaponPickUp","be")
	register_event("ResetHUD","EventResetHUD","b")
	
	set_task(5.0,"ScanUsers",_,_,_,"b")
}

public ARP_Init()
	ARP_RegisterPlugin("Medical Tools","1.0","Hawk552","Adds pain/damage effects and tools")

public ARP_Error(const Reason[])
	pause("d")

/*
public CmdSay(id)
{
	new Args[256]
	read_args(Args,255)
	
	remove_quotes(Args)
	trim(Args)
	
	if(!equali(Args,"computer",8))
		return
	
	replace(Args,255,"computer","")
	
	new Float:Origin[3],Float:BotOrigin[3],Bot = FindBot()
	if(!Bot)
	{
		if(!((containi(Args,"activate") != -1 || containi(Args,"initialize") != -1 || containi(Args,"start") != -1) && (containi(Args,"emh") != -1 || (containi(Args,"emergency") != -1 && containi(Args,"medical") != -1 && containi(Args,"hologram") != -1)))
			return
	
		new Players = get_playersnum(),MaxPlayers = get_maxplayers()
		if(MaxPlayers - Players < 2)
		{
			client_print(id,print_chat,"[ARP] There are too many players on the server to use the %s.",g_Name)
			return PLUGIN_HANDLED
		}
		
		Bot = create_bot(g_Name)
		set_user_info(Bot,"model","doctor")
		
		g_User = id
		Time = get_gametime()
		
		return set_task(0.1,"Spawn",Bot)
	}
}
*/

public ScanUsers()
{
	new Players[32],Playersnum,id
	get_players(Players,Playersnum,"ac")
	
	for(new Count;Count < Playersnum;Count++)
	{
		id = Players[Count]
		
		if(g_Bleeding[id])
			set_user_health(id,clamp(get_user_health(id) - random_num(0,g_Bleeding[id]),!get_pcvar_num(p_BleedOut),9999))
		
		switch(g_Pain[id])
		{
			case 20 .. 70:
			{
				ScreenPulse(id)
				
				RemoveEffects(id)
			}
			case 71 .. 9999:
			{
				FadeEffect(id)
			}
		}
	}
	
	if(g_Pain[id] > get_pcvar_num(p_MaxPain) && get_pcvar_num(p_BleedOut))
	{
		client_print(id,print_chat,"[ARP] You have gone into shock and died from pain.")
		ARP_UserKill(id,1)
	}
}

public ARP_RegisterItems()
{
	ARP_RegisterItem("Medical Triquarter","_MedicScanner","A scanner that helps doctors find the exact spot of pain.")
	g_Splint = ARP_RegisterItem("Splint","_Splint","An item that helps the pain when you fell from a high building.",1)
	g_Morphine = ARP_RegisterItem("Morphine","_Morphine","An item that helps ease the pain in the user's body.",1)
	g_Bandage = ARP_RegisterItem("Bandage","_Bandage","An item that stops bleeding and heals you.",1)
	g_Tensor = ARP_RegisterItem("Tensor Bandage","_ArmHeal","An item that allows use of the arm after it is injured",1)
	g_Regenerator = ARP_RegisterItem("Dermal Regenerator","_Regenerator","Heals a user's wounds completely",1)
	//g_EMH = ARP_RegisterItem("Emergency Medical Hologram","_Hologram","Heals user automatically if no doctors are on",1)
	ARP_RegisterItem("Medical Kit","_MedKit","A medical kit that gives you the items needed to help and save people.",1)
}

public DeathMsg()
{
	new id = read_data(2)
	
	client_disconnect(id)
	
	RemoveEffects(id)
	
	client_cmd(id,"stopsound")
	
	g_Killed[id] = 1
}

public client_disconnect(id)
{
	g_Pain[id] = 0
	g_Fell[id] = 0
	g_HeartBeatSet[id] = 0
	g_NoHoldGuns[id] = 0
	
	for(new Count;Count < HITSPOT;Count++)
		g_HitInfo[id][Count] = 0
		
	g_Bleeding[id] = 0
	
	client_cmd(id,"stopsound")
	set_user_maxspeed(id,320.0)	
}

public EventResetHUD(id)
	if(g_Killed[id])
	{
		client_disconnect(id)
		g_Killed[id] = 0
	}

public WeaponPickUp(id)
{
	if(g_NoHoldGuns[id])
	{
		client_print(id,print_chat,"[ARP] Your arms are too weak to pick up the weapon.")
		
		client_cmd(id,"drop")
		return PLUGIN_HANDLED
	}
	
	if(!get_pcvar_num(p_BleedOut) && get_user_health(id) < 10)
	{
		client_print(id,print_chat,"[ARP] You are in terrible shape and cannot use this gun. Get to a doctor!")
		
		client_cmd(id,"drop")
		return PLUGIN_HANDLED
	}
		
	return PLUGIN_CONTINUE
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	new id = victim
	
	if(hitplace == HIT_GENERIC && damage > get_pcvar_num(p_BreakDamage))
	{
		g_HitInfo[id][LEFTLEG]++
		g_HitInfo[id][RIGHTLEG]++
		
		if(!g_Fell[id])
		{
			g_Fell[id] = 1
			
			client_print(id,print_chat,"[ARP] You have fallen and are now slower!")
		}
	}
	
	if(!is_user_alive(id))
		return FAILED

	if(!is_user_connected(attacker))
	{
		g_Fell[id] = 1
		
		FadeEffect(id)
		return SUCCEEDED
	}
	
	new SufficientDamage = damage > get_pcvar_num(p_BreakDamage)
	switch(hitplace)
	{
		case HIT_HEAD:
		{
			g_HitInfo[id][HEAD]++
			
			if(SufficientDamage) FadeEffect(id)
		}
		case HIT_CHEST: g_HitInfo[id][CHEST]++
		case HIT_STOMACH: g_HitInfo[id][STOMACH]++
		case HIT_LEFTARM:
		{
			g_HitInfo[id][LEFTARM]++
			
			if(SufficientDamage && !g_NoHoldGuns[id] && random_num(1,4) == 2)
			{
				client_cmd(id,"drop")
				g_NoHoldGuns[id] = 1
				
				client_print(id,print_chat,"[ARP] You have taken a blow to your %s and can no longer hold weapons!",g_Hits[hitplace])
			}
		}
		case HIT_RIGHTARM:
		{
			g_HitInfo[id][RIGHTARM]++
			
			if(SufficientDamage && !g_NoHoldGuns[id] && random_num(1,4) == 2)
			{
				client_cmd(id,"drop")
				g_NoHoldGuns[id] = 1
				
				client_print(id,print_chat,"[ARP] You have taken a blow to your %s and can no longer hold weapons!",g_Hits[hitplace])
			}
		}
		case HIT_LEFTLEG:
		{
			g_HitInfo[id][LEFTLEG]++
			
			if(SufficientDamage && !g_Fell[id])
			{
				g_Fell[id] = 1
				
				client_print(id,print_chat,"[ARP] You have taken a blow to your %s and are now slower!",g_Hits[hitplace])
			}
		}
		case HIT_RIGHTLEG:
		{
			g_HitInfo[id][RIGHTLEG]++
			
			if(SufficientDamage && !g_Fell[id])
			{
				g_Fell[id] = 1
				
				client_print(id,print_chat,"[ARP] You have taken a blow to your %s and are now slower!",g_Hits[hitplace])
			}
		}
	}
	
	new Health = get_user_health(id)
	switch(Health)
	{
		case 1 .. 20 :
			FadeEffect(id)
		case 21 .. 50 :
		{
			ScreenPulse(id)
			
			RemoveEffects(id)
		}
	}	
	
	g_Pain[id] += damage	
		
	if(damage >= get_pcvar_num(p_BleedDamage)) g_Bleeding[id] = clamp(g_Bleeding[id] + 1,0,BLEEDING - 1)
	
	return SUCCEEDED
}

RemoveEffects(id)
{
	if(g_HeartBeatSet[id])
		client_cmd(id,"stopsound")
				
	g_HeartBeatSet[id] = 0
	
	if(pev(id,pev_maxspeed) == get_pcvar_num(p_HitSpeed))
		set_pev(id,pev_maxspeed,320.0)
}		

ScreenPulse(id)
{
	message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("TSFade"),{0,0,0},id)
	write_short(1<<300)
	write_short(1<<300)
	write_short(1<<12)
	write_byte(255)
	write_byte(0) 
	write_byte(0)
	write_byte(75)
	message_end()
}

FadeEffect(id)
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
	
	if(!g_HeartBeatSet[id])
		client_cmd(id,"spk %s",g_HeartBeat)
	
	g_HeartBeatSet[id] = 1
}

public PreThink(id)
	if(get_user_health(id) < 10 || g_Fell[id])
		set_user_maxspeed(id,get_pcvar_float(p_HitSpeed))
	
public EventPlayerHealBegin(Name[],Data[],Len)
{
	new id = Data[0],MedNum = ARP_MedNum()
	if(MedNum || (MedNum == 1 && !ARP_IsMed(id)))
	{
		client_print(id,print_chat,"[ARP] You cannot use this command as there are doctors on the server.")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public EventPlayerHealEnd(Name[],Data[],Len)
	client_disconnect(Data[0])

public EventHudRender(Name[],Data[],Len)	
{
	if(Data[1] != HUD_SEC)
		return
	
	new id = Data[0]
	if(!is_user_alive(id))
		return
	
	if(g_Bleeding[id])
	{		
		ARP_AddHudItem(id,HUD_SEC,0,"Pain: %d",g_Pain[id])
		ARP_AddHudItem(id,HUD_SEC,0,"Bleeding: %s",g_Bleed[g_Bleeding[id]])
	}
	else if(g_Pain[id])
		ARP_AddHudItem(id,HUD_SEC,0,"Pain: %d",g_Pain[id] = clamp(g_Pain[id] - 1,0,get_pcvar_num(p_MaxPain) + 1))
	
	if(g_NoHoldGuns[id])
		ARP_AddHudItem(id,HUD_SEC,0,"Broken Arms")
	
	if(g_Fell[id])
		ARP_AddHudItem(id,HUD_SEC,0,"Broken Legs")
	
	ARP_AddHudItem(id,HUD_SEC,0," ")
	
	new TotalHits
	for(new i = 1;i < HITSPOT;i++) 
		if(g_HitInfo[id][i]) 
		{
			static HitSpot[33]
			copy(HitSpot,32,g_Hits[i])
			HitSpot[0] = toupper(HitSpot[0])
			ARP_AddHudItem(id,HUD_SEC,0,"%s: %d hits",HitSpot,g_HitInfo[id][i])
			TotalHits += g_HitInfo[id][i]
		}
	
	if(TotalHits)
	{
		ARP_AddHudItem(id,HUD_SEC,0," ")
		ARP_AddHudItem(id,HUD_SEC,0,"Total: %d hits",TotalHits)
	}
}

ClearHits(id) for(new i = 1;i < HITSPOT;i++) g_HitInfo[id][i] = 0

public _MedicScanner(id,ItemId)
{
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
		return client_print(id,print_chat,"[ARP] You are not looking at another player.")
	
	client_print(id,print_chat,"[ARP] Scanning user for injuries. Stand by.")
	client_print(tid,print_chat,"[ARP] You are being scanned for injuries. Stand by.")
	
	new Params[2]
	Params[0] = id
	Params[1] = tid
	set_task(5.0,"ScanFinish",_,Params,2)
	
	return ARP_ItemSet(id)
}

public ScanFinish(Params[2])
{
	new id = Params[0], tid = Params[1], Players[32], Playersnum
	get_players(Players,Playersnum)
	
	new Damaged
	for(new Count; Count < HITSPOT; Count++) if(g_HitInfo[tid][Count]) Damaged = 1
	
	new Bleeding[33]
	format(Bleeding,32," is bleeding %s,",g_Bleed[g_Bleeding[id]])
	
	format(g_Damage,511,"[ARP] Player%s%s%s is at %d HP with %d pain%s",g_Fell[tid] ? " has fallen," : "",g_NoHoldGuns[tid] ? " cannot carry guns," : "",g_Bleeding[id] ? Bleeding : "",get_user_health(tid),g_Pain[tid],Damaged ? " and has" : "")
	
	for(new Count; Count < HITSPOT; Count++)
	{
		switch(g_HitInfo[tid][Count])
		{
			case 0:
				continue
			case 1:
				add(g_Damage,511," light")
			case 2:
				add(g_Damage,511," medium")
			case 3:
				add(g_Damage,511," heavy")
			default:
				add(g_Damage,511," massive")
		}
		add(g_Damage,511," damage to the ")
		add(g_Damage,511,g_Hits[Count])
		add(g_Damage,511,",")
	}
	
	// Remove the trailing comma.
	new Pos = strlen(g_Damage) - 1
	if(g_Damage[Pos] == ',') g_Damage[strlen(g_Damage) - 1] = '^0'
	
	client_print(id,print_chat,"%s.",g_Damage)
	
	ARP_ItemDone(id)
}

public _Splint(id,ItemId)
{
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
	{
		client_print(id,print_chat,"[ARP] You are not looking at another player.")
		return AddItem(id,ItemId)
	}
	
	if(!g_Fell[tid])
	{
		client_print(id,print_chat,"[ARP] This user is not injured in this area.")
		return AddItem(id,ItemId)
	}
	
	ARP_ItemSet(id)
	
	client_print(id,print_chat,"[ARP] You begin applying a splint to the player's legs.")
	client_print(tid,print_chat,"[ARP] A splint is being applied to your legs.")
	
	new Params[2]
	Params[0] = id
	Params[1] = tid
	set_task(5.0,"FallHeal",_,Params,2)
	
	return SUCCEEDED
}

public FallHeal(Params[2])
{
	new id = Params[0], tid = Params[1]
	
	client_print(id,print_chat,"[ARP] You finished applying the splint.")
	client_print(tid,print_chat,"[ARP] Your legs are now healed.")
	g_Fell[tid] = 0
	RemoveEffects(id)
	
	g_HitInfo[tid][LEFTLEG] = 0
	g_HitInfo[tid][RIGHTLEG] = 0
	
	set_user_maxspeed(tid,320.0)
	
	return ARP_ItemDone(id)
}

public _Morphine(id,ItemId)
{
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
	{
		client_print(id,print_chat,"[ARP] You are not looking at another player.")
		return AddItem(id,ItemId)
	}
	
	if(g_Pain[tid] <= 0)
	{
		client_print(id,print_chat,"[ARP] This user is not in pain.")
		return AddItem(id,ItemId)
	}
	
	client_print(id,print_chat,"[ARP] You have treated the player with morphine.")
	client_print(tid,print_chat,"[ARP] You have been given a dose of morphine.")
	
	ARP_ItemSet(id)
	
	new Params[2]
	Params[0] = id
	Params[1] = tid
	set_task(5.0,"MorphineFinish",_,Params,2)
	
	return SUCCEEDED
}

public MorphineFinish(Params[2])
{
	new id = Params[0], tid = Params[1]
	client_print(tid,print_chat,"[ARP] You started to feel the morphine hit.")
	client_print(id,print_chat,"[ARP] The morphine is now applied.")
	
	g_Pain[tid] = clamp(g_Pain[tid] - get_pcvar_num(p_PainHeal),0,get_pcvar_num(p_MaxPain))
	
	return ARP_ItemDone(id)
}

public _Bandage(id,ItemId)
{	
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
	{
		client_print(id,print_chat,"[ARP] You are not looking at another player.")
		return AddItem(id,ItemId)
	}
	
	if(!g_Bleeding[tid] && !g_HitInfo[tid][body])
	{
		client_print(id,print_chat,"[ARP] This user is not bleeding.")
		return AddItem(id,ItemId)
	}
	
	ARP_ItemSet(id)
	
	client_print(id,print_chat,"[ARP] You are applying a bandage on this user.")
	client_print(tid,print_chat,"[ARP] A bandage is being applied on you.")
	
	new Params[3]
	Params[0] = id
	Params[1] = tid
	Params[2] = body
	set_task(5.0,"BandageFinish",_,Params,3)
	
	return SUCCEEDED
}

public BandageFinish(Params[3])
{
	new id = Params[0],tid = Params[1]
	
	client_print(id,print_chat,"[ARP] The bandage is now applied")
	client_print(tid,print_chat,"[ARP] The bandage is now applied.")
	
	if(--g_Bleeding[tid] > 0)
		client_print(id,print_chat,"[ARP] This user is still bleeding: %s.",g_Bleed[g_Bleeding[tid]])
	{
		g_Bleeding[tid] = 0
		client_print(id,print_chat,"[ARP] This user is no longer bleeding.")
		client_print(tid,print_chat,"[ARP] You are no longer bleeding.")
	}
	
	if(--g_HitInfo[tid][Params[2]] < 0) g_HitInfo[tid][Params[2]] = 0
	
	ARP_ItemDone(id)
}

public _ArmHeal(id,ItemId)
{
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
	{
		client_print(id,print_chat,"[ARP] You are not looking at another player.")
		return AddItem(id,ItemId)
	}
	
	if(!g_NoHoldGuns[tid])
	{
		client_print(id,print_chat,"[ARP] This user is not injured in this area.")
		return AddItem(id,ItemId)
	}
	
	ARP_ItemSet(id)
	
	client_print(id,print_chat,"[ARP] You start to apply the tensor bandage.")
	client_print(tid,print_chat,"[ARP] A tensor bandage is being applied to your arm.")
	
	new Params[2]
	Params[0] = id
	Params[1] = tid
	set_task(5.0,"ArmFinish",_,Params,2)
	
	return SUCCEEDED
}

public ArmFinish(Params[2])
{
	new id = Params[0], tid = Params[1]
	
	client_print(id,print_chat,"[ARP] The user's arms are now healed.")
	client_print(tid,print_chat,"[ARP] Your arms are now healed.")
	
	g_NoHoldGuns[tid] = 0
	
	g_HitInfo[tid][LEFTARM] = 0
	g_HitInfo[tid][RIGHTARM] = 0
	
	return ARP_ItemDone(id)
}

public _MedKit(id,ItemId)
{
	new Splint = ARP_GetUserItemNum(id,g_Splint), 
	Morphine = ARP_GetUserItemNum(id,g_Morphine),
	Bandage = ARP_GetUserItemNum(id,g_Bandage), 
	Tensor = ARP_GetUserItemNum(id,g_Tensor),
	Regenerator = ARP_GetUserItemNum(id,g_Regenerator)

	client_print(id,print_chat,"[ARP] You opened the medical kit.")
	
	ARP_SetUserItemNum(id,g_Tensor,Tensor + 1)
	ARP_SetUserItemNum(id,g_Morphine,Morphine + 2)
	ARP_SetUserItemNum(id,g_Splint,Splint + 1)
	ARP_SetUserItemNum(id,g_Bandage,Bandage + 5)
	ARP_SetUserItemNum(id,g_Regenerator,Regenerator + 1)
}

public _Regenerator(id,ItemId)
{	
	new tid, body
	get_user_aiming(id,tid,body,100)
	
	if(!is_user_connected(tid))
	{
		client_print(id,print_chat,"[ARP] You are not looking at another player.")
		return AddItem(id,ItemId)
	}
	
	if(get_user_health(tid) >= 100)
	{
		client_print(id,print_chat,"[ARP] This user is already at max health.")
		return AddItem(id,ItemId)
	}
	
	client_print(id,print_chat,"[ARP] You apply the dermal regenerator.")
	client_print(tid,print_chat,"[ARP] A dermal regenerator is applied onto you.")
	
	new Params[2]
	Params[0] = id
	Params[1] = tid
	
	set_task(1.0,"HealUser",_,Params,2)
	set_rendering(tid,kRenderFxGlowShell,255,255,255,kRenderNormal,16)
	
	return SUCCEEDED
}

public HealUser(Params[2])
{
	new id = Params[0],tid = Params[1],Float:Health = entity_get_float(tid,EV_FL_health)
	
	if(Health >= 100.0)
	{
		client_print(id,print_chat,"[ARP] The player has finished healing.")
		client_print(tid,print_chat,"[ARP] You are now finished healing.")
		
		ClearHits(tid)
		
		return set_rendering(tid,kRenderFxNone,255,255,255,kRenderNormal,16)
	}
	
	entity_set_float(tid,EV_FL_health,Health + 1.0)
	return set_task(1.0,"HealUser",_,Params,2)
}

AddItem(id,ItemId)
	return ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
	
/*
IsInjured(id)
{
	new Num = g_Pain[id] || g_Fell[id] || g_HeartBeatSet[id] || g_NoHoldGuns[id] || g_Bleeding[id]
	for(new Count;Count < HITSPOT;Count++)
		Num = Num || g_HitInfo[id][Count]
	
	return Num
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

PlaySound(id,sample[])
	emit_sound(id,CHAN_AUTO,sample,VOL_NORM,ATTN_NORM,0,PITCH_LOW)
*/

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

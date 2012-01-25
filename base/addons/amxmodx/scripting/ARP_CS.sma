#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

const m_pActiveItem = 373

new gMsgHideWeapon
new gMsgScoreInfo

new g_AddItemCalled

#define HIDE_ALL (1<<3)|(1<<4)|(1<<6)

#define CS_MAX_WEAPONS 33

#define TASK_OFFSET 123133

enum WEAPON
{
	ITEMID = 0,
	AMMOTYPE
}

new gWeaponNames[CS_MAX_WEAPONS][] = 
{
	"",
	"weapon_p228", 
	"",
	"weapon_scout", 
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10", 
	"weapon_aug", 
	"weapon_smokegrenade",
	"weapon_elite", 
	"weapon_fiveseven",
	"weapon_ump45", 
	"weapon_sg550", 
	"weapon_galil",
	"weapon_famas",
	"weapon_usp", 
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90", 
	"",
	""
}

new gWeapon[CS_MAX_WEAPONS][WEAPON] =
{
	{0,0},	// None
	{0,1},	// P228 (13, 52, .357)
	{0,0},
	{0,2},	// Scout (10, 90, 7.62mm NATO)
	{0,0},	// HE Grenade
	{0,3},	// XM1014 (7, 32, 12 Gauge)
	{0,0},	// C4
	{0,4},	// MAC10 (30, 100, .45 ACP)
	{0,5},	// AUG (30, 90, 5.56mm NATO)
	{0,0},	// Smoke Grenade
	{0,6},	// Berettas (30, 120, 9mm Parabellum)
	{0,7},	// Five-seveN (20, 100, 5.7mm NATO)
	{0,4},	// UMP (25, 100, .45 ACP)
	{0,2},	// Sig550 (20, 90, 7.62mm NATO)
	{0,5},	// Galil (35, 90, 5.56mm NATO)
	{0,5},	// FAMAS (25, 90, 5.56mm NATO)
	{0,4},	// USP (12, 100, .45 ACP)
	{0,6},	// GLOCK-18 (20, 120, 9mm Parabellum)
	{0,8},	// AWP (10, 30, .338 Lapua Magnum)
	{0,6},	// MP5 Navy (30, 120, 9mm Parabellum)
	{0,9},	// M249 (100, 200, 5.56mm Parabellum)
	{0,3},	// M3 (8, 32, 12 Gauge)
	{0,5},	// M4A1 (30, 90, 5.56mm NATO)
	{0,6},	// TMP (30, 120, 9mm Parabellum)
	{0,5},	// G3SG1 (30, 90, 5.56mm NATO)
	{0,0},	// Flashbang
	{0,10},	// Desert Eagle (7, 35, .50 AE)
	{0,5},	// Sig552 (30, 90, 5.56mm NATO)
	{0,2},	// AK-47 (30, 90, 7.62mm NATO)
	{0,0},	// Knife
	{0,7},	// P90 (50, 100, 5.7mm NATO)
	{0,0},	// Vest
	{0,0}	// Vest + helmet
}

#define AMMO_TYPES 11

new gMaxAmmo[AMMO_TYPES] =
{
	0,
	52, 	// .357
	90,		// 7.62mm NATO
	32,		// 12 Gauge
	100,	// .45 ACP
	90,		// 5.56mm NATO	
	120,	// 9mm Parabellum
	100,	// 5.7mm NATO
	30,		// .338 Lapua Magnum
	200,	// 5.56mm Parabellum
	35		// .50 AE
}

new g_357
new g_762NATO
new g_12Gauge
new g_45ACP
new g_556NATO
new g_9mmParabellum
new g_57
new g_338
new g_556Parabellum
new g_50AE

enum MODEL
{
	_V = 0,
	_P
}

new gPrevModel[33][MODEL][33]
new gPrevWeapon[33]

new pRespawnTime

public plugin_init()
{
	ARP_RegisterPlugin("CS Compatibility",ARP_VERSION,"The ApolloRP Team","Provides CS support for ARP")
	
	if(!module_exists("csx") && !module_exists("cstrike"))
	{
		ARP_Log("The CS compatibility plugin has been enabled in a non-CS mod.")
		pause("d")
		
		return
	}
	
	RegisterHam(Ham_Spawn,"player","HamSpawn")
	RegisterHam(Ham_TakeDamage,"player","HamTakeDamage")
	RegisterHam(Ham_Killed,"player","HamKilled")
	
	pRespawnTime = register_cvar("arp_respawn_time","2")
	
	register_event("ResetHUD", "EventResetHUD","b")
	register_event("CurWeapon","EventCurWeapon","be","1=1")
	
	set_cvar_string("humans_join_team","t")
	set_cvar_num("mp_limitteams",32)
	set_cvar_num("mp_autoteambalance",0)
	set_cvar_num("mp_friendlyfire",1)
	
	ARP_RegisterEvent("HUD_AddItem","EventHudAddItem")
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	
	gMsgHideWeapon = get_user_msgid("HideWeapon")
	gMsgScoreInfo = get_user_msgid("ScoreInfo")
	
	register_message(gMsgHideWeapon,"MsgHideWeapon")
	register_message(get_user_msgid("TextMsg"),"MsgTextMsg")
	register_message(get_user_msgid("SendAudio"),"MsgSendAudio")
	
	ARP_RegisterCmd("holster","CmdHolster","- holsters or unholsters a weapon")
	ARP_RegisterChat("/holster","CmdHolster","- holsters or unholsters a weapon")
	
	register_forward(FM_CmdStart,"ForwardCmdStart")
	
	set_task(1.0,"CheckSpawns",_,_,_,"b")
}

public ARP_Error(const Reason[])
	pause("d")

public EventCurWeapon(id)
{
	new Weapon = read_data(2)
	
	if(Weapon != gPrevWeapon[id])
		gPrevModel[id][_V][0] = 0
	else if(gPrevModel[id][_V][0])
	{		
		entity_get_string(id,EV_SZ_viewmodel,gPrevModel[id][_V],32)
		entity_get_string(id,EV_SZ_weaponmodel,gPrevModel[id][_P],32)
		
		entity_set_string(id,EV_SZ_viewmodel,"")
		entity_set_string(id,EV_SZ_weaponmodel,"")
	}
}

public ForwardCmdStart(id,UCHandle) 
{
	if(!gPrevModel[id][_V][0])
		return FMRES_IGNORED
	
	new Buttons = get_uc(UCHandle,UC_Buttons)
	Buttons &= ~IN_ATTACK
	Buttons &= ~IN_ATTACK2
	set_uc(UCHandle,UC_Buttons,Buttons)
	
	return FMRES_IGNORED
}

public CmdHolster(id)
{
	new Weapon = get_user_weapon(id)
	if(Weapon)
	{
		if(gPrevModel[id][_V][0])
		{			
			entity_set_string(id,EV_SZ_viewmodel,gPrevModel[id][_V])
			entity_set_string(id,EV_SZ_weaponmodel,gPrevModel[id][_P])
			
			gPrevModel[id][_V][0] = gPrevWeapon[id] = 0
			
			client_print(id,print_chat,"[ARP] You have unholstered your weapon.")
		}
		else
		{
			gPrevWeapon[id] = Weapon
			
			entity_get_string(id,EV_SZ_viewmodel,gPrevModel[id][_V],32)
			entity_get_string(id,EV_SZ_weaponmodel,gPrevModel[id][_P],32)
			
			entity_set_string(id,EV_SZ_viewmodel,"")
			entity_set_string(id,EV_SZ_weaponmodel,"")
			
			client_print(id,print_chat,"[ARP] You have holstered your weapon.")
		}
	}
	
	return PLUGIN_HANDLED
}

public CheckSpawns()
{
	new Players[32],Playersnum,Player,CsTeams:Team
	get_players(Players,Playersnum)
	
	for(new i;i < Playersnum;i++)
	{
		Player = Players[i]
		Team = cs_get_user_team(Player)
		if(!is_user_alive(Player) && (Team == CS_TEAM_T || Team == CS_TEAM_CT) && !task_exists(Player) && !task_exists(Player + TASK_OFFSET))
			set_task(get_pcvar_float(pRespawnTime),"Spawn",Player)
	}
}

public Spawn(id)
	ExecuteHam(Ham_Spawn,id)

public ARP_RegisterItems()
{
	new CSWeaponNames[CS_MAX_WEAPONS][2][] =
	{
		{"",""},
		{"SIG P228","Handgun; Non-Restricted; .357 SIG"},
		{"",""},
		{"Steyr Scout","Rifle; Restricted; 7.62mm NATO"},
		{"HE Grenade","Grenade; Prohibited"},
		{"Benelli M4 Super 90","Shotgun; Restricted; 12 Gauge"},
		{"C4 Plastique Explosive","Explosive; Prohibited"},
		{"MAC-10","Sub-machine Gun; Non-Restricted; .45 ACP"},
		{"Steyr AUG","Assault Rifle; Restricted; 5.56mm NATO"},
		{"Smoke Grenade","Grenade; Non-Restricted"},
		{"Dual Beretta 92s","Pistol; Non-Restricted; 9mm Parabellum"},
		{"FN Five-seveN","Pistol; Non-Restricted; 5.7x28mm FN"},
		{"H&K UMP","Sub-machine Gun; Non-Restricted; .45 ACP"},
		{"SIG SG 550","Rifle; Restricted; 7.62mm NATO"},
		{"IMI Galil AR","Assault Rifle; Restricted; 5.56mm NATO"},
		{"MAS FAMAS","Assault Rifle; Restricted; 5.56mm NATO"},
		{"H&K USP Tactical","Pistol; Restricted; .45 ACP"},
		{"GLOCK-18","Pistol; Non-Restricted; 9mm Parabellum"},
		{"AI Artic Warfare Magnum","Rifle; Restricted; .338 Lapua Magnum"},
		{"H&K MP5-N","Sub-machine Gun; Non-Restricted; 9mm Parabellum"},
		{"FN M249 SAW","Machine Gun; Prohibited; 5.56mm Parabellum"},
		{"Benelli M3 Super 90","Shotgun; Non-Restricted; 12 Gauge"},
		{"Colt M4A1","Assault Rifle; Restricted; 5.56mm NATO"},
		{"Steyr TMP","Sub-machine Gun; Restricted; 9mm Parabellum"},
		{"H&K G3SG/1","Rifle; Restricted; 5.56mm NATO"},
		{"Stun Grenade","Grenade; Restricted"},
		{"IMI Desert Eagle","Pistol; Non-Restricted; .50 AE"},
		{"SIG SG 552","Assault Rifle; Restricted; 5.56mm NATO"},
		{"Kalashnikova AK-47","Assault Rifle; Restricted; 7.62mm NATO"},
		{"Hunting Knife","Knife; Non-Restricted"},
		{"FN P90","Sub-machine Gun; Non-Restricted; 5.7x28mm FN"},
		{"Kevlar","Armor; Non-Restricted"},
		{"Kevlar & Helmet","Armor; Non-Restricted"}
	}
	
	for(new Count;Count < CS_MAX_WEAPONS;Count++)
		if(CSWeaponNames[Count][0][0])
			gWeapon[Count][ITEMID] = ARP_RegisterItem(CSWeaponNames[Count][0],"_Weapon",CSWeaponNames[Count][1],1)
		
	g_357 = ARP_RegisterItem(".357 SIG Ammo","_Ammo","Ammunition",1)
	g_762NATO = ARP_RegisterItem("7.62mm NATO Ammo","_Ammo","Ammunition",1)
	g_12Gauge = ARP_RegisterItem("12 Gauge Ammo","_Ammo","Ammunition",1)
	g_45ACP = ARP_RegisterItem(".45 ACP Ammo","_Ammo","Ammunition",1)
	g_556NATO = ARP_RegisterItem("5.56mm NATO Ammo","_Ammo","Ammunition",1)
	g_9mmParabellum = ARP_RegisterItem("9mm Parabellum Ammo","_Ammo","Ammunition",1)
	g_57 = ARP_RegisterItem("5.7x28mm FN Ammo","_Ammo","Ammunition",1)
	g_338 = ARP_RegisterItem(".338 Lapua Magnum Ammo","_Ammo","Ammunition",1)
	g_556Parabellum = ARP_RegisterItem("5.56mm Parabellum Ammo","_Ammo","Ammunition",1)
	g_50AE = ARP_RegisterItem(".50 AE Ammo","_Ammo","Ammunition",1)
}

public plugin_precache()
	register_forward(FM_Spawn,"ForwardSpawn")

public plugin_natives()
{
	set_module_filter("ModuleFilter")
	set_native_filter("NativeFilter")
}

public _Weapon(id,ItemId)
{
	new Weapon
	for(new i;i < CS_MAX_WEAPONS;i++)
		if(ItemId == gWeapon[i][ITEMID])
		{
			Weapon = i
			break
		}
	
	if(!Weapon)
		// wtf?
		return
	
	new Group = WeaponGroup(Weapon)
	if(Group)
		drop_weapons(id,Group)
	
	give_item(id,gWeaponNames[Weapon])
}

public _Ammo(id,ItemId)
{
	new Mode
	if(ItemId == g_357)
		Mode = 1
	else if(ItemId == g_762NATO)
		Mode = 2
	else if(ItemId == g_12Gauge)
		Mode = 3
	else if(ItemId == g_45ACP)
		Mode = 4
	else if(ItemId == g_556NATO)
		Mode = 5
	else if(ItemId == g_9mmParabellum)
		Mode = 6
	else if(ItemId == g_57)
		Mode = 7
	else if(ItemId == g_338)
		Mode = 8
	else if(ItemId == g_556Parabellum)
		Mode = 9
	else if(ItemId == g_50AE)
		Mode = 10
	else return
	
	new Weapon = get_user_weapon(id)
	if(gWeapon[Weapon][AMMOTYPE] != Mode)
	{
		client_print(id,print_chat,"[ARP] You are not holding a weapon that uses this ammo.",gWeapon[Weapon][AMMOTYPE],Mode)
		ARP_GiveUserItem(id,ItemId,1)
		return
	}
	
	cs_set_user_bpammo(id,Weapon,gMaxAmmo[Mode])
	
	client_print(id,print_chat,"[ARP] You have loaded up on ammo.")
}

// Hawk552: Backup function in case ARP_HUD.amxx is disabled.
public EventHUDRender(Name[],Data[],Len)
{	
	if(Data[1] == HUD_PRIM && is_user_alive(Data[0]) && !g_AddItemCalled)
		cs_set_user_money(Data[0],ARP_GetUserWallet(Data[0]))
	
	return PLUGIN_CONTINUE
}

public EventHudAddItem(Name[],Data[],Len)
{		
	if(Data[1] != HUD_PRIM) return PLUGIN_CONTINUE
	
	new id = Data[0]
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	
	if(equali(Data[2],"Wallet: $",9))
	{
		g_AddItemCalled = 1
		cs_set_user_money(id,ARP_GetUserWallet(id))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public MsgTextMsg()
{	
	new arg2[22]
	get_msg_arg_string(2,arg2,21)
	if(equal(arg2,"#Game_teammate_attack") || equal(arg2,"#Killed_Teammate") || equal(arg2,"#Game_teammate_kills"))
		return PLUGIN_HANDLED
	
	if(get_msg_args() < 3 || get_msg_argtype(3) != ARG_STRING)
		return PLUGIN_CONTINUE

	new arg3[16]
	get_msg_arg_string(3,arg3,15)
	if(equal(arg3,"#Game_radio"))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public MsgSendAudio()
{
	new arg2[3]
	get_msg_arg_string(2, arg2, 2)
	//if(equal(arg2[1], "!MRAD_FIREINHOLE"))
	if(arg2[1] == '!')
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public ForwardSpawn(id)
{
	static ObjectiveEnts[][] = 
	{
		"func_bomb_target",
		"info_bomb_target",
		"hostage_entity",
		"monster_scientist",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone"
	}, ClassName[33]
	
	pev(id,pev_classname,ClassName,32)
	
	for(new i;i < sizeof ObjectiveEnts;i++)
		if(equali(ClassName,ObjectiveEnts[i]))
		{
			remove_entity(id)
			return FMRES_SUPERCEDE
		}
	
	return FMRES_IGNORED
}

public client_PreThink(id)
{
#if 000
	new Weapon = 1<<get_user_weapon(id),Button = entity_get_int(id,EV_INT_button)
	if(Weapon & 1<<CSW_KNIFE|1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE && Button & IN_ATTACK2)
	{
		new pActiveItem = get_pdata_cbase(id,m_pActiveItem)
		ExecuteHam(Ham_Item_Holster,pActiveItem,1)
	}
#endif
}

public ModuleFilter(const Module[])
{
    if(equali(Module,"cstrike") || equali(Module,"csx") || equali(Module,"xstats"))
        return PLUGIN_HANDLED
	
    return PLUGIN_CONTINUE
}

public NativeFilter(const Name[],Index,Trap)
{
    if(!Trap)
        return PLUGIN_HANDLED
        
    return PLUGIN_CONTINUE
}

public HamKilled(id,Killer)
{	
	if(!(1 <= Killer <= 32))
		return HAM_IGNORED
	
	new CsTeams:Team = cs_get_user_team(Killer)
	if(Team == cs_get_user_team(id))
	{
		new Frags = get_user_frags(Killer) + 2
		set_user_frags(Killer,Frags)
		
		message_begin(MSG_BROADCAST,gMsgScoreInfo)
		write_byte(Killer)
		write_short(Frags)
		write_short(get_user_deaths(Killer))
		write_short(0)
		write_short(_:Team)
		message_end()
	}
	
	return HAM_IGNORED
}

public HamTakeDamage(Victim,Inflictor,Attacker,Float:Damage,DamageBits)
{
	if(is_user_alive(Victim) && is_user_alive(Inflictor) && cs_get_user_team(Victim) == cs_get_user_team(Attacker))
		SetHamParamFloat(4,Damage * 3.0)
	
	return HAM_IGNORED
}

public HamSpawn(id)
	set_task(0.1,"StripWeapons",id)

public StripWeapons(id)
	strip_user_weapons(id)

public MsgHideWeapon()
	set_msg_arg_int(1,ARG_BYTE,get_msg_arg_int(1)|HIDE_ALL)

public EventResetHUD(id) 
{
	message_begin(MSG_ONE_UNRELIABLE,gMsgHideWeapon,_,id)
	write_byte(HIDE_ALL)
	message_end()
}

WeaponGroup( weapon )
{
    //primary returns 1, secondary returns 2
    switch ( weapon )
    {
        case CSW_SCOUT, CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_AWP, CSW_MP5NAVY, CSW_M249, CSW_M3, CSW_M4A1, CSW_TMP, CSW_G3SG1, CSW_SG552, CSW_AK47, CSW_P90: return 1
        case CSW_P228, CSW_ELITE, CSW_FIVESEVEN, CSW_USP, CSW_GLOCK18, CSW_DEAGLE: return 2
    }
    
    return 0
}

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
    // Get user weapons
    static weapons[32], num, i, weaponid
    num = 0 // reset passed weapons count (bugfix)
    get_user_weapons(id, weapons, num)
    
    // Loop through them and drop primaries or secondaries
    for (i = 0; i < num; i++)
    {
        // Prevent re-indexing the array
        weaponid = weapons[i]
        
        if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
        {
            // Get the weapon entity
            static wname[32]//, weapon_ent
            get_weaponname(weaponid, wname, sizeof wname - 1)
            //weapon_ent = fm_find_ent_by_owner(-1, wname, id);
            
            // Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
            //set_pev(weapon_ent, pev_iuser1, cs_get_user_bpammo(id, weaponid))
            
            // Player drops the weapon and looses his bpammo
            engclient_cmd(id, "drop", wname)
            //fm_set_user_bpammo(id, weaponid, 0)
        }
    }
}
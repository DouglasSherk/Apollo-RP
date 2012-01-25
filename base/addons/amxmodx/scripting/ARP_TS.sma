#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>
#include <fakemeta>
#include <tsx>
#include <tsfun>
#include <sqlx>

new g_9Parabellum
new g_12Gauge
new g_556NATO
new g_45ACP
new g_50AE
new g_762Soviet
new g_57FN
new g_50BMG
new g_10Auto
new g_22Hornet
new g_454Casull
new g_32ACP
new g_762NATO

new g_AttachMenu[] = "ARP_AttachMenu"

new g_Keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9

new g_Attachments[33]
new g_Gun[33]
new g_Cell[33]

enum WEAPON
{
	ITEMID = 0,
	ATTACHMENTS
}

new g_GunStats[TS_MAX_WEAPONS][WEAPON] = 
{
	{0,0},
	{50,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SILENCER},
	{0,0},
	{51,TSA_SILENCER},
	{52,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE},
	{53,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{54,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE},
	{55,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{56,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SILENCER},
	{57,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SILENCER},
	{0,0},
	{58,TSA_FLASHLIGHT|TSA_LASERSIGHT},
	{59,TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{60,TSA_SCOPE},
	{61,TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{62,TSA_LASERSIGHT|TSA_SILENCER},
	{0,0},
	{63,TSA_LASERSIGHT|TSA_SILENCER},
	{64,TSA_LASERSIGHT},
	{65,TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{66,TSA_FLASHLIGHT|TSA_LASERSIGHT},
	{67,0},
	{68,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SILENCER},
	{69,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE|TSA_SILENCER},
	{70,0},
	{71,0},
	{72,TSA_FLASHLIGHT|TSA_LASERSIGHT},
	{73,TSA_FLASHLIGHT|TSA_LASERSIGHT|TSA_SCOPE},
	{74,TSA_LASERSIGHT},
	{0,0},
	{0,0},
	{75,TSA_LASERSIGHT|TSA_SCOPE},
	{76,0},
	{77,TSA_LASERSIGHT},
	{78,0},
	{79,0},
	{0,0},
	{0,0},
	{80,TSA_LASERSIGHT|TSA_SCOPE}
}

new g_WeaponAmmo[TS_MAX_WEAPONS] =
{
	0,//"",
	210,//"glock18",
	// what the fuck is this anyway?
	0,//"unk1",
	210,//"uzi",
	60,//"m3",
	90,//"m4a1",
	210,//"mp5sd",
	210,//"mp5k",
	210,//"aberettas",
	175,//"mk23",
	175,//"amk23",
	60,//"usas",
	70,//"deagle",
	90,//"ak47",
	200,//"57",
	90,//"aug",
	210,//"auzi",
	300,//"skorpion",
	30,//"m82a1",
	200,//"mp7",
	60,//"spas",
	200,//"gcolts",
	100,//"glock20",
	175,//"ump",
	0,//"m61grenade",
	0,//"cknife",
	60,//"mossberg",
	90,//"m16a4",
	150,//"mk1",
	0,//"c4",
	200,//"a57",
	50,//"rbull",
	90,//"m60e3",
	60,//"sawed_off",
	0,//"katana",
	0,//"sknife",
	0,//"kungfu",
	0,//"tknife",
	35,//"contender"	
}

new g_AmmoTypes[TS_MAX_WEAPONS] =
{
	0,//"",
	1,//"glock18",
	// what the fuck is this anyway?
	0,//"unk1",
	1,//"uzi",
	2,//"m3",
	3,//"m4a1",
	1,//"mp5sd",
	1,//"mp5k",
	1,//"aberettas",
	4,//"mk23",
	4,//"amk23",
	2,//"usas",
	5,//"deagle",
	6,//"ak47",
	7,//"57",
	3,//"aug",
	1,//"auzi",
	12,//"skorpion",
	8,//"m82a1",
	7,//"mp7",
	2,//"spas",
	4,//"gcolts",
	9,//"glock20",
	4,//"ump",
	0,//"m61grenade",
	0,//"cknife",
	2,//"mossberg",
	3,//"m16a4",
	10,//"mk1",
	0,//"c4",
	7,//"a57",
	11,//"rbull",
	3,//"m60e3",
	2,//"sawed_off",
	0,//"katana",6
	0,//"sknife",
	0,//"kungfu",
	0,//"tknife",
	13//"contender"
}

new Handle:g_SqlHandle

new g_WeaponTable[] = "arp_weapons"

public plugin_init()
{
	ARP_RegisterPlugin("TS Compatibility",ARP_VERSION,"The ApolloRP Team","Provides TS support for ARP")
	
	if(!module_exists("tsx") && !module_exists("tsfun"))
	{
		ARP_Log("The TS compatibility plugin has been enabled in a non-TS mod.")
		pause("d")
		
		return
	}
	
	ARP_RegisterCmd("arp_addgun","CmdAddGun","(ADMIN) <weaponid> <ammo> <extra> <save (0/1)> - adds gun to wall")
	
	register_menucmd(register_menuid(g_AttachMenu),g_Keys,"AttachMenuHandle")
}

public ARP_Error(const Reason[])
	pause("d")

public plugin_natives()
{
	set_module_filter("ModuleFilter")
	set_native_filter("NativeFilter")
}

public ModuleFilter(const Module[])
{
    if(equali(Module,"tsx") || equali(Module,"tsfun") || equali(Module,"xstats"))
        return PLUGIN_HANDLED
	
    return PLUGIN_CONTINUE
}

public NativeFilter(const Name[],Index,Trap)
{
    if(!Trap)
        return PLUGIN_HANDLED
        
    return PLUGIN_CONTINUE
}

public ARP_RegisterItems()
{
	new TSWeaponNames[TS_MAX_WEAPONS][2][] =
	{
		{"",""},
		{"GLOCK-18","Handgun; Non-Restricted; 9mm Parabellum"},
		{"",""},
		{"Mini-Uzi","Sub-machine Gun; Non-Restricted; 9mm Parabellum"},
		{"Benelli M3","Shotgun; Restricted; 12 gauge 2 3/4^""},
		{"Colt M4A1","Rifle; Restricted; 5.56mm (NATO)"},
		{"H&K MP5SDA5","Sub-machine Gun; Restricted; 9mm Parabellum"},
		{"H&K MP5K","Sub-machine Gun; Non-Restricted; 9mm Parabellum"},
		{"Akimbo Beretta 92Fs","Handgun(s); Non-Restricted; 9mm Parabellum"},
		{"H&K SOCOM MK23","Handgun; Non-Restricted; .45 ACP"},
		{"",""},
		{"Daewoo USAS-12","Shotgun; Restricted; 12 gauge 2 3/4^""},
		{"IMI Desert Eagle","Handgun; Non-Restricted; .50 AE"},
		{"Kalashnikova AK-47","Rifle; Prohibited; 7.62mm"},
		{"FN Five-seveN Tactical","Handgun; Non-Restricted; 5.7mm"},
		{"Steyr AUG","Rifle; Restricted; 5.56mm (NATO)"},
		{"",""},
		{"vz. 61 ^"Skorpion^"","Sub-machine Gun; Non-Restricted; .32 ACP"},
		{"Barrett M82A1","Rifle; Prohibited; .50 BMG"},
		{"H&K MP7","Sub-machine Gun; Non-Restricted; 4.6mm"},
		{"SPAS-12","Shotgun; Restricted; 12 gauge 2 3/4^""},
		{"Golden Colt 1911A1s","Handgun; Non-Restricted; .45 ACP"},
		{"GLOCK-20C","Handgun; Non-Restricted; 10mm Auto"},
		{"H&K UMP","Sub-machine Gun; Non-Restricted; .45 ACP"},
		{"M61 Grenade","Special; Prohibited"},
		{"Combat Knife","Special; Non-Restriced"},
		{"Mossberg 500","Shotgun; Non-Restriced; 12 gauge 2 3/4^""},
		{"Colt M16A4","Rifle; Restricted; 5.56mm (NATO)"},
		{"Ruger MK1","Handgun; Non-Restricted; .22 LR"},
		{"",""},
		{"",""},
		{"Taurus Raging Bull","Handgun; Restricted; .454 Casull"},
		{"U.S. Ordnance M60E3","Machine-gun; Prohibited; 7.62mm (NATO)"},
		{"Sawed-Off Shotgun","Shotgun; Prohibited; 12 gauge 2 3/4^""},
		{"Katana","Special; Non-Restricted"},
		{"Seal Knife","Special; Non-Restricted"},
		{"G2 Contender","Handgun; Prohibited; 7.62mm NATO"},
		{"",""},
		{"",""}
	}
	
	for(new Count;Count < TS_MAX_WEAPONS;Count++)
		if(TSWeaponNames[Count][0][0])
			g_GunStats[Count][ITEMID] = ARP_RegisterItem(TSWeaponNames[Count][0],"_WeaponHandle",TSWeaponNames[Count][1],1)
	
	g_9Parabellum = ARP_RegisterItem("9mm Parabellum Ammo","_Ammo","9mm Parabellum ammo for weapons",1)
	g_12Gauge = ARP_RegisterItem("12 Gauge Shells Ammo","_Ammo","12 Gauge shells for weapons",1)
	g_556NATO = ARP_RegisterItem("5.56mm NATO Ammo","_Ammo","5.56mm NATO ammo for weapons",1)
	g_45ACP = ARP_RegisterItem(".45 ACP Ammo","_Ammo",".45 ACP ammo for weapons",1)
	g_50AE = ARP_RegisterItem(".50 AE Ammo","_Ammo",".50 AE ammo for weapons",1)
	g_762Soviet = ARP_RegisterItem("7.62mm Soviet Ammo","_Ammo","7.62mm Soviet ammo for weapons",1)
	g_57FN = ARP_RegisterItem("5.7mm FN Ammo","_Ammo","5.7mm FN ammo for weapons",1)
	g_50BMG = ARP_RegisterItem(".50 BMG Ammo","_Ammo",".50 BMG ammo for weapons",1)
	g_10Auto = ARP_RegisterItem("10mm Auto Ammo","_Ammo","10mm Auto ammo for weapons",1)
	g_22Hornet = ARP_RegisterItem(".22 Hornet Ammo","_Ammo",".22 Hornet ammo for weapons",1)
	g_454Casull = ARP_RegisterItem(".454 Casull Ammo","_Ammo",".454 Casull ammo for weapons",1)
	g_32ACP = ARP_RegisterItem(".32 ACP Ammo","_Ammo",".32 ACP ammo for weapons",1)
	g_762NATO = ARP_RegisterItem("7.62mm NATO Ammo","_Ammo","7.62mm NATO ammo for weapons",1)
	
#if 0
	new SCWeaponNames[SC_MAX_WEAPONS][2][] =
	{
		{"",""},
		{"Crowbar","Melee; Non-Restricted"},
		{"9mm Handgun","Handgun; Non-Restricted; 9mm"},
		{".357 Handgun","Handgun; Non-Restricted; .357"},
		{"9mm Assault Rifle","Sub-machine Gun; Non-Restricted; 9mm/AR Grenades"},
		{"",""},
		{"Crossbow","Special; Restricted; Bolts"},
		{"Shotgun","Shotgun; Non-Restricted; Shells"},
		{"Rocket-Propelled Grenade Launcher","Explosive; Prohibited; Rockets"},
		{"Gauss Gun","Energy; Prohibited; Cells"},
		{"EGON Gun","Energy; Prohibited; Cells"},
		{"Hornet Gun","Alien; Restricted"},
		{"Hand Grenade","Explosive; Restricted"},
		{"Trip Mine","Explosive; Restricted"},
		{"Satchel","Explosive; Restricted"},
		{"Snark","Alien; Restricted"},
		{"Akimbo Uzis","Sub-machine Gun; Non-Restricted; 9mm"},
		{"Uzi","Sub-machine Gun; Non-Restricted; 9mm"},
		{"Medkit","Special; Non-Restricted"},
		{"",""},
		{"Pipe Wrench","Melee; Non-Restricted"},
		{"Minigun","Machine-gun; Prohibited; Chaingun Ammo"},
		{"Grapple Gun","Alien; Non-Restricted"},
		{"Sniper Rifle","Rifle; Restricted; 7.62"},
		{"",""},
		{"",""},
		{"",""},
		{"",""},
		{"",""},
		{"",""},
		{"",""}
	}
	
	for(new Count;Count < SC_MAX_WEAPONS;Count++)
		if(SCWeaponNames[Count][0][0])
			g_GunStats[Count][ITEMID] = ARP_RegisterItem(SCWeaponNames[Count][0],"_WeaponHandle",SCWeaponNames[Count][1],1)

	g_357
	g_Buckshot
	g_762
	g_Bolts
	g_Cells
	g_RPG
	g_ARGrenades
	g_9mm
	g_Minigun
#endif
}

public CmdAddGun(id,level,cid)
{
	if(!ARP_CmdAccess(id,cid,5))
		return PLUGIN_HANDLED
	
	new WeaponId[33],Ammo[33],Flags[33],Save[33],Float:Origin[3]
	entity_get_vector(id,EV_VEC_origin,Origin)
	
	read_argv(1,WeaponId,32)
	read_argv(2,Ammo,32)
	read_argv(3,Flags,32)
	read_argv(4,Save,32)
	
	ts_weaponspawn(WeaponId,"15",Ammo,Flags,Origin)
	
	if(!str_to_num(Save))
		return PLUGIN_HANDLED
		
	new WeapId = str_to_num(WeaponId),Clip = str_to_num(Ammo),Spawnflags = str_to_num(Flags)
	
	new Query[256]
	format(Query,255,"INSERT INTO %s VALUES ('%d','%d','%d','%d','%d','%d')",g_WeaponTable,WeapId,Clip,Spawnflags,floatround(Origin[0]),floatround(Origin[1]),floatround(Origin[2]))
	
	SQL_ThreadQuery(g_SqlHandle,"IgnoreHandle",Query)
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	ARP_Log("Cmd: ^"%s<%d><%s><>^" add gun spawn (origin ^"%f %f %f^") (weaponid ^"%s^") (ammo ^"%s^") (flags ^"%s^") (save ^"%d^")",Name,get_user_userid(id),Authid,Origin[0],Origin[1],Origin[2],WeaponId,Ammo,Flags,Save)
	
	show_activity(id,Name,"Add weapon spawn")
	
	return PLUGIN_HANDLED
}

public ARP_Init()
{	
	g_SqlHandle = ARP_SqlHandle()
	
	// Don't do gunspawns if in SQLite.
	if(ARP_SqlMode() == SQLITE)
		return
	
	new Query[256]
	
	format(Query,255,"CREATE TABLE IF NOT EXISTS %s (weaponid INT(11),clips INT(11),flags INT(11),x INT(11),y INT(11),z INT(11))",g_WeaponTable)
	SQL_ThreadQuery(g_SqlHandle,"IgnoreHandle",Query)
	
	format(Query,255,"SELECT * FROM %s",g_WeaponTable)
	SQL_ThreadQuery(g_SqlHandle,"FetchSpawns",Query)
}

public FetchSpawns(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Internal error: consult developer.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new WeaponId[33],Clips[33],Flags[33],Float:Origin[3]
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query,0,WeaponId,32)
		SQL_ReadResult(Query,1,Clips,32)
		SQL_ReadResult(Query,2,Flags,32)
		Origin[0] = float(SQL_ReadResult(Query,3))
		Origin[1] = float(SQL_ReadResult(Query,4))
		Origin[2] = float(SQL_ReadResult(Query,5))
		
		ts_weaponspawn(WeaponId,"15",Clips,Flags,Origin)
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize) 
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return log_amx("Could not connect to SQL database.")//set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return log_amx("Internal error: consult developer. Error: %s",Error)
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	return PLUGIN_CONTINUE
}

public _WeaponHandle(id,ItemId)
{	
	g_Attachments[id] = 0
	g_Gun[id] = ItemId
	
	_Weapon(id,ItemId)
}

public _Weapon(id,ItemId)
{		
	new Menu[512],Pos,Cell = -1,Num,ItemName[33]
	ARP_GetItemName(ItemId,ItemName,32)
	Pos += format(Menu,511,"ARP %s Attachments^n^n",ItemName)
	
	for(new Count;Count < TS_MAX_WEAPONS;Count++)
		if(g_GunStats[Count][ITEMID] == ItemId && g_GunStats[Count][ITEMID])
		{			
			Cell = Count
			g_Cell[id] = Count
			break
		}
	
	if(Cell == -1)
		return
	
	if(!g_GunStats[Cell][ATTACHMENTS])
	{
		GiveWeapon(id)
		return
	}
	
	if(g_GunStats[Cell][ATTACHMENTS] & TSA_FLASHLIGHT)
		Pos += format(Menu[Pos],511 - Pos,"%d. Flashlight %s^n",++Num,g_Attachments[id] & TSA_FLASHLIGHT ? "*" : "")
	if(g_GunStats[Cell][ATTACHMENTS] & TSA_LASERSIGHT)
		Pos += format(Menu[Pos],511 - Pos,"%d. Lasersight %s^n",++Num,g_Attachments[id] & TSA_LASERSIGHT ? "*" : "")
	if(g_GunStats[Cell][ATTACHMENTS] & TSA_SCOPE)
		Pos += format(Menu[Pos],511 - Pos,"%d. Scope %s^n",++Num,g_Attachments[id] & TSA_SCOPE ? "*" : "")
	if(g_GunStats[Cell][ATTACHMENTS] & TSA_SILENCER)
		Pos += format(Menu[Pos],511 - Pos,"%d. Suppressor %s^n",++Num,g_Attachments[id] & TSA_SILENCER ? "*" : "")
		
	format(Menu[Pos],511-Pos,"^n0. Done")
	
	new Keys = (1<<9)
	for(new Count;Count < Num;Count++)	
		Keys |= (1<<Count)
	
	show_menu(id,Keys,Menu,-1,g_AttachMenu)
}

public AttachMenuHandle(id,Key)
{
	new Attachments[4],Num,Temp
	Temp = g_GunStats[g_Cell[id]][ATTACHMENTS]
	for(new Count;Count < 4;Count++)
		if(Temp & TSA_FLASHLIGHT)
		{
			Attachments[Num++] = TSA_FLASHLIGHT
			// &= ~x seems to be broken
			Temp -= TSA_FLASHLIGHT
		}
		else if(Temp & TSA_LASERSIGHT)
		{
			Attachments[Num++] = TSA_LASERSIGHT
			Temp -= TSA_LASERSIGHT
		}
		else if(Temp & TSA_SCOPE)
		{
			Attachments[Num++] = TSA_SCOPE
			Temp -= TSA_SCOPE
		}
		else if(Temp & TSA_SILENCER)
		{
			Attachments[Num++] = TSA_SILENCER
			Temp -= TSA_SILENCER
		}
	
	if(Key != 9 && !Attachments[Key])
	{
		_Weapon(id,g_Gun[id])
		return
	}
	
	if(Key == 9)
	{
		GiveWeapon(id)
		return
	}
	
	if(!(g_Attachments[id] & Attachments[Key]))
		g_Attachments[id] += Attachments[Key]
	else
		g_Attachments[id] -= Attachments[Key]
		
	_Weapon(id,g_Gun[id])
}	

GiveWeapon(id)
	ts_giveweapon(id,g_Cell[id],250,g_Attachments[id])

public _Ammo(id,ItemId)
{
	new Mode
	
	if(ItemId == g_9Parabellum)
		Mode = 1
	else if(ItemId == g_12Gauge)
		Mode = 2
	else if(ItemId == g_556NATO)
		Mode = 3 
	else if(ItemId == g_45ACP)
		Mode = 4
	else if(ItemId == g_50AE)
		Mode = 5
	else if(ItemId == g_762Soviet)
		Mode = 6
	else if(ItemId == g_57FN)
		Mode = 7
	else if(ItemId == g_50BMG)
		Mode = 8
	else if(ItemId == g_10Auto)
		Mode = 9
	else if(ItemId == g_22Hornet)
		Mode = 10
	else if(ItemId == g_454Casull)
		Mode = 11
	else if(ItemId == g_32ACP)
		Mode = 12
	else if(ItemId == g_762NATO)
		Mode = 13
	else
		return PLUGIN_HANDLED
		
	new Dummy,Wpn = ts_getuserwpn(id,Dummy,Dummy,Dummy,Dummy)
	if(Mode == g_AmmoTypes[Wpn] && ts_setuserammo(id,Wpn,g_WeaponAmmo[Wpn]))
		return ARP_ClientPrint(id,"You loaded up on ammo.")

	ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
	return ARP_ClientPrint(id,"You are not wielding any weapon with this ammo type.")
}	

 // Avalanches Ammo Code (Thanks for letting me use it)
 // Set a user's ammo amount
 public ts_setuserammo(id,weapon,ammo) {

   // Kung Fu
   if(weapon == 36) {
     client_cmd(id,"weapon_0"); // switch to kung fu
     return 0; // stop now
   }

   // Invalid Weapon
   if(weapon < 0 || weapon > 35) {
     return 0; // stop now
   }

   client_cmd(id,"weapon_%d",weapon); // switch to whatever weapon

   // C4 or Katana
   if(weapon == 29 || weapon == 34) {
     return 0; // stop now
   }

   // TS AMMO OFFSETS
   new tsweaponoffset[37];
   tsweaponoffset[1] = 51; // Glock18
   tsweaponoffset[3] = 50; // Uzi
   tsweaponoffset[4] = 52; // M3
   tsweaponoffset[5] = 53; // M4A1
   tsweaponoffset[6] = 50; // MP5SD
   tsweaponoffset[7] = 50; // MP5K
   tsweaponoffset[8] = 50; // Beretta
   tsweaponoffset[9] = 51; // Socom
   tsweaponoffset[11] = 52; // USAS
   tsweaponoffset[12] = 59; // Desert Eagle
   tsweaponoffset[13] = 55; // AK47
   tsweaponoffset[14] = 56; // Fiveseven
   tsweaponoffset[15] = 53; // Steyr AUG
   tsweaponoffset[17] = 61; // Skorpion
   tsweaponoffset[18] = 57; // Barret
   tsweaponoffset[19] = 56; // Mp7
   tsweaponoffset[20] = 52; // Spas
   tsweaponoffset[21] = 51; // Golden Colts
   tsweaponoffset[22] = 58; // Glock20
   tsweaponoffset[23] = 51; // UMP
   tsweaponoffset[24] = 354; // M61 Grenade
   tsweaponoffset[25] = 366; // Combat Knife
   tsweaponoffset[26] = 52; // Mossberg
   tsweaponoffset[27] = 53; // M16
   tsweaponoffset[28] = 59; // Ruger Mk1
   tsweaponoffset[31] = 60; // Raging Bull
   tsweaponoffset[32] = 53; // M60
   tsweaponoffset[33] = 52; // Sawed Off
   tsweaponoffset[35] = 486; // Seal Knife
   tsweaponoffset[36] = 62; // Contender

   new currentent = -1, tsgun = 0; // used for getting user's weapon_tsgun

   // get origin
   new Float:origin[3];
   entity_get_vector(id,EV_VEC_origin,origin);

   // loop through "user's" entities (whatever is stuck to user, basically)
   while((currentent = find_ent_in_sphere(currentent,origin,Float:1.0)) != 0) {
     new classname[32];
     entity_get_string(currentent,EV_SZ_classname,classname,31);

     if(equal(classname,"weapon_tsgun")) { // Found weapon_tsgun
       tsgun = currentent; // remember it
     }

   }

   // Couldn't find weapon_tsgun
   if(tsgun == 0) {
     return 0; // stop now
   }

   // Get some of their current settings
   new currclip, currammo, currmode, currextra;
   ts_getuserwpn(id,currclip,currammo,currmode,currextra);

   set_pdata_int(tsgun,tsweaponoffset[weapon],ammo); // set their ammo

   // Grenade or knife, set clip
   if(weapon == 24 || weapon == 25 || weapon == 35) {
     set_pdata_int(tsgun,41,ammo); // special clip storage
     set_pdata_int(tsgun,839,ammo); // more special clip storage
     currclip = ammo; // change what we send to WeaponInfo
     ammo = 0; // once again, change what we send to WeaponInfo
   }
   else { // Not a grenade or knife, set ammo
     set_pdata_int(tsgun,850,ammo); // special ammo storage
   }

   // Update user's HUD
   message_begin(MSG_ONE,get_user_msgid("WeaponInfo"),{0,0,0},id);
   write_byte(weapon);
   write_byte(currclip);
   write_short(ammo);
   write_byte(currmode);
   write_byte(currextra);
   message_end();

   return 1; // wooh!
 }
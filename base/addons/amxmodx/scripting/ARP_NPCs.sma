#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <ApolloRP>
#include <ApolloRP_Chat>
#include <engine>
#include <tsx>
#include <tsfun>

#define NPC_TYPES 5
#define GUNSHOP_MODES 3
#define MAX_NPCS 50

new g_Npcs[NPC_TYPES][] = 
{
	"shop",
	"bank",
	"doctor",
	"gunshop",
	"atm"
}

new g_NpcHandlers[NPC_TYPES][] =
{
	"EdekaHandle",
	"BankHandle",
	"DoctorHandle",
	"GunshopHandle",
	"AtmHandle"
}

enum SELLING
{
	ITEMID = 0,
	COST,
	// only applies to gunshop
	LICENSE
}

#define MAX_WEAPONS 38
new g_WeaponAmmo[MAX_WEAPONS] =
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
	210,//"tmp",
	30,//"m82a1",
	200,//"mp7",
	60,//"spas",
	175,//"gcolts",
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
	0,//"kung_fu",
	0//"tknife"
}

// the max possible in any given area is 44 assuming
// that the user for some reason makes everything
// restricted or non-restricted
new g_NonRestricted[50][44][SELLING]
new g_Restricted[50][44][SELLING]
new g_Licenses[50][44][SELLING]
new g_WeaponNum[50][3]
new g_RobProfile[50][33]
new g_Heal[50] = {-1,...}

new g_Selling[50][50][SELLING]
new g_NpcNum
new g_ItemNum[50] = {1,...}
new g_NpcId[50]
//new g_Targetnames[50][33]
//new g_Type[50]
//new Float:g_Time[50]
//new g_Extra[50][50]

new g_MenuPage[33]
new g_Keys = MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9
new g_EdekaMenu[] = "ARP_EdekaMenu"
new g_BankMenu[] = "ARP_BankMenu"
new g_DoctorMenu[] = "ARP_DoctorMenu"
new g_AtmMenu[] = "ARP_AtmMenu"
new g_AtmUse[] = "ARP_AtmUseMenu"
new g_GunshopMenu[] = "ARP_GunshopMenu"
new g_GunshopUseMenu[] = "ARP_GunshopUseMenu"

// for ATM machines/gunshop
new g_Mode[33]

new g_ModeNames[GUNSHOP_MODES][] =
{
	"Permitted",
	"Restricted",
#if GUNSHOP_MODES == 4
	"Licenses",
	"Fill Ammo"
#else
	"Licenses"
#endif
}

new g_CurNpc[33]
new g_CurNpcId[33]
new Float:g_MaxSpeed[33]

new p_FillCost
new p_ProfitFraction

enum MODS
{
	HL = 0,
	TS
}

new MODS:g_Mod

public plugin_init()
{
	register_menucmd(register_menuid(g_EdekaMenu),g_Keys,"EdekaMenuHandle")
	register_menucmd(register_menuid(g_BankMenu),g_Keys,"BankMenuHandle")
	register_menucmd(register_menuid(g_DoctorMenu),g_Keys,"DoctorMenuHandle")
	register_menucmd(register_menuid(g_AtmMenu),g_Keys,"AtmMenuHandle")
	register_menucmd(register_menuid(g_AtmUse),g_Keys,"AtmUseMenuHandle")
	register_menucmd(register_menuid(g_GunshopMenu),g_Keys,"GunshopMenuHandle")
	register_menucmd(register_menuid(g_GunshopUseMenu),g_Keys,"GunshopUseMenuHandle")
	
	//register_clcmd("say","CmdSay")
	//ARP_RegisterEvent("Player_Say","CmdSay")
	ARP_AddChat(_,"CmdSay")
	
	p_FillCost = register_cvar("arp_ammofill_cost","50")
	p_ProfitFraction = register_cvar("arp_profit_fraction","0.25")
	
	//register_event("CurWeapon","EventCurWeapon","be")
	
	ARP_AddCommand("say /withdraw","Withdraw money if facing a banker")
	ARP_AddCommand("say /deposit","Deposit money if facing a banker")
	
	register_event("DeathMsg","EventDeathMsg","a")
	
	if(module_exists("tsfun") || module_exists("tsx")) g_Mod = TS
	// No such module
	else /*if(module_exists("svencoop")*/ g_Mod = HL
}

public plugin_natives()
{
    set_module_filter("ModuleFilter")
    set_native_filter("NativeFilter")
}

public ModuleFilter(const Module[])
{
    if(equali(Module,"tsfun") || equali(Module,"tsx") || equali(Module,"xstats"))
        return PLUGIN_HANDLED
	
    return PLUGIN_CONTINUE
}

public NativeFilter(const Name[],Index,Trap)
{
    if(!Trap)
        return PLUGIN_HANDLED
        
    return PLUGIN_CONTINUE
}

public ARP_Error(const Reason[])
	pause("d")

public ARP_Init()
{
	ARP_RegisterPlugin("NPCs",ARP_VERSION,"The Apollo RP Team","Adds basic NPCs")
	
	new FileName[128],ConfigsDir[64],Model[64],Float:Angle,Float:Origin[3],Cache[3][12],Type,Sell[64],Name[33],Temp[64],Zone,Property[64]
	
	new File = ARP_FileOpen("npcs.ini","r"),Buffer[128]
	if(!File)
		return
	
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		
		new End = strlen(Buffer) - 1
		if(Buffer[0] == ';' || End <= 0)
			continue
		
		if(Buffer[End] == '^n') Buffer[End] = '^0'
		
		if(containi(Buffer,"[END]") != -1)
		{
			if(file_exists(Model))
			{
				precache_model(Model)
				
				g_NpcId[g_NpcNum++] = ARP_RegisterNpc(Name,Origin,Angle,Model,g_NpcHandlers[Type],Zone,Property)
				Zone = 0
				
				Property[0] = 0
			}
		}
		else if(containi(Buffer,"name") != -1)
		{
			parse(Buffer,FileName,1,ConfigsDir,63)
			trim(ConfigsDir)
			remove_quotes(ConfigsDir)
			
			copy(Name,32,ConfigsDir)
		}
		else if(containi(Buffer,"type") != -1)
		{
			parse(Buffer,ConfigsDir,1,FileName,63)
			trim(FileName)
			remove_quotes(FileName)
			
			for(new Count;Count < NPC_TYPES;Count++)
				if(equal(g_Npcs[Count],FileName))
					Type = Count
			}
		else if(containi(Buffer,"model") != -1)
		{
			// using configsdir as cache/temp
			parse(Buffer,ConfigsDir,1,Model,63)
			remove_quotes(Model)
		}
		else if(containi(Buffer,"angle") != -1)
		{
			// using file and configsdir as cache/temp
			parse(Buffer,ConfigsDir,1,FileName,63)
			remove_quotes(FileName)
			
			Angle = str_to_float(FileName)
		}
		else if(containi(Buffer,"origin") != -1)
		{
			parse(Buffer,FileName,1,ConfigsDir,63)
			remove_quotes(ConfigsDir)
			
			parse(ConfigsDir,Cache[0],11,Cache[1],11,Cache[2],11)
			
			for(new Count;Count < 3;Count++)
				Origin[Count] = str_to_float(Cache[Count])
		}
		else if(containi(Buffer,"sell") != -1)
		{
			parse(Buffer,FileName,1,Sell,63)
			remove_quotes(Sell)
			
			parse(Sell,FileName,63,ConfigsDir,63,Temp,63)
			
			// Legacy RobMod handler code.
			if(equali(FileName,"0"))
				continue
			else if(is_str_num(FileName))
				g_Selling[g_NpcNum][g_ItemNum[g_NpcNum]][ITEMID] = str_to_num(FileName)
			else
			{
				remove_quotes(FileName)
				while(replace(FileName,63,"_"," ") || replace(FileName,63,"^n","")) { }
				
				new Results[1]
				ARP_FindItemId(FileName,Results,1)
				g_Selling[g_NpcNum][g_ItemNum[g_NpcNum]][ITEMID] = Results[0]
			}
			
			g_Selling[g_NpcNum][g_ItemNum[g_NpcNum]][COST] = str_to_num(ConfigsDir)
			g_Selling[g_NpcNum][g_ItemNum[g_NpcNum]++][LICENSE] = str_to_num(Temp)
		}	
		else if(containi(Buffer,"heal") != -1)
		{
			parse(Buffer,FileName,1,Sell,63)
			remove_quotes(Sell)
			
			g_Heal[g_NpcNum] = str_to_num(Sell)
		}
		else if(containi(Buffer,"addgun") != -1)
		{
			parse(Buffer,FileName,1,Sell,63)
			remove_quotes(Sell)
			
			parse(Sell,FileName,63,ConfigsDir,63,Temp,63)
			
			remove_quotes(FileName)
			while(replace(FileName,63,"_"," ") || replace(FileName,63,"^n","")) { }
			
			new Results[1],License = clamp(str_to_num(Temp),0,2)
			ARP_FindItemId(FileName,Results,1)
			
			if(!ARP_ValidItemId(Results[0]))
			{
				//ARP_ThrowError(0,"Weapon/License ^"%s^" does not exist.",FileName)
				ARP_Log("Weapon/License %s does not exist.",FileName)
				continue
			}
			
			switch(License)
			{
				case 0 :
				{
					g_NonRestricted[g_NpcNum][g_WeaponNum[g_NpcNum][0]][COST] = str_to_num(ConfigsDir)
					g_NonRestricted[g_NpcNum][g_WeaponNum[g_NpcNum][0]][ITEMID] = Results[0]
					
					g_WeaponNum[g_NpcNum][0]++
				}
				case 1 :
				{
					g_Restricted[g_NpcNum][g_WeaponNum[g_NpcNum][1]][COST] = str_to_num(ConfigsDir)
					g_Restricted[g_NpcNum][g_WeaponNum[g_NpcNum][1]][ITEMID] = Results[0]
					
					g_WeaponNum[g_NpcNum][1]++
				}
				case 2 :
				{
					g_Licenses[g_NpcNum][g_WeaponNum[g_NpcNum][2]][COST] = str_to_num(ConfigsDir)
					g_Licenses[g_NpcNum][g_WeaponNum[g_NpcNum][2]][ITEMID] = Results[0]
					
					g_WeaponNum[g_NpcNum][2]++
				}
			}
		}
		else if(containi(Buffer,"zone") != -1)
			Zone = 1
		else if(containi(Buffer,"property") != -1)
		{
			parse(Buffer,ConfigsDir,1,Property,63)
			remove_quotes(Property)
			trim(Property)
		}
		else if(containi(Buffer,"robprofile") != -1)
		{
			parse(Buffer,ConfigsDir,1,g_RobProfile[g_NpcNum],63)
			remove_quotes(g_RobProfile[g_NpcNum])
			trim(g_RobProfile[g_NpcNum])
		}
	}
	
	fclose(File)
}

public EdekaHandle(id,Ent)
{
	g_MenuPage[id] = 0
	Edeka(id,Ent)
}

Edeka(id,Ent)
{
	new Npc = FindNpc(Ent)//,ItemName[33],Menu[512],Len = sizeof Menu - 1,Pos,Num,Keys = (1<<7|1<<8|1<<9)
	
	g_CurNpc[id] = Npc
	g_CurNpcId[id] = Ent
	
	new Menu = menu_create("ARP Shop","EdekaMenuHandle"),ItemName[33],ItemNum[10],Command[64]
	if(g_RobProfile[Npc][0])
	{
		menu_additem(Menu,"* Rob","-1")
		menu_addblank(Menu,0)
	}
	for(new Count = 1;Count < g_ItemNum[Npc];Count++)
	{
		ARP_ValidItemId(g_Selling[Npc][Count][ITEMID]) ? ARP_GetItemName(g_Selling[Npc][Count][ITEMID],ItemName,32) : copy(ItemName,32,"BAD ITEM ID: Contact admin")
		format(Command,63,"%s - $%d",ItemName,g_Selling[Npc][Count][COST])
		num_to_str(g_Selling[Npc][Count][ITEMID],ItemNum,9)
		menu_additem(Menu,Command,ItemNum)
	}
	
	menu_display(id,Menu)
	
	/*
	Pos += format(Menu[Pos],Len - Pos,"ARP Shop^n^n")
	
	new HasProfile = (g_RobProfile[Npc][0] && !g_MenuPage[id]) ? 1 : 0
	for(new Count = g_MenuPage[id] * 7 - 1;Count < g_MenuPage[id] * 7 + 7 - HasProfile;Count++)
	{		
		if(Count >= g_ItemNum[Npc])
			continue
		
		Keys |= (1<<Num)
		
		if(Count == -1 && g_RobProfile[Npc][0])
			Pos += format(Menu[Pos],Len - Pos,"%d. Rob^n",++Num)
		else
		{			
			ARP_ValidItemId(g_Selling[Npc][Count][ITEMID]) ? ARP_GetItemName(g_Selling[Npc][Count][ITEMID],ItemName,32) : copy(ItemName,32,"BAD ITEM ID: Contact admin")
			
			Pos += format(Menu[Pos],Len - Pos,"%d. %s - $%d^n",++Num,ItemName,g_Selling[Npc][Count][COST])
		}
	}
	Pos += format(Menu[Pos],Len - Pos,"^n8. Last Page^n9. Next Page^n^n0. Exit")
	
	show_menu(id,Keys,Menu,-1,g_EdekaMenu)*/
}	

public EdekaMenuHandle(id,Menu,Item)	
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT || !ARP_NpcDistance(id,g_CurNpcId[id]))
		return
			
	//new Item = g_MenuPage[id] * 7 + Key,UserCash = ARP_GetUserWallet(id)
	new UserCash = ARP_GetUserWallet(id)
	//if(!g_RobProfile[g_CurNpc[id]][0])
	//	Item--
	
	//if(!g_Selling[g_CurNpc[id]][Item][ITEMID] && Item)
	//{
	//	Edeka(id,g_CurNpcId[id])
	//	return
	//}
	
	if(!Item && g_RobProfile[g_CurNpc[id]][0])
	{
		new Data[34]
		Data[0] = id
		copy(Data[1],32,g_RobProfile[g_CurNpc[id]])
		
		ARP_CallEvent("Rob_Begin",Data,34)
		
		return
	}
	
	if(!g_RobProfile[g_CurNpc[id]][0]) Item++
		
	if(UserCash < g_Selling[g_CurNpc[id]][Item][COST])
	{
		client_print(id,print_chat,"[ARP] You don't have enough money for that item.")
		return
	}
	
	new ItemName[33]
	if(!ARP_ValidItemId(g_Selling[g_CurNpc[id]][Item][ITEMID]))
	{
		client_print(id,print_chat,"[ARP] This item is broken; please contact the administrator.")
		return
	}
	
	ARP_GetItemName(g_Selling[g_CurNpc[id]][Item][ITEMID],ItemName,32)
	
	ARP_SetUserItemNum(id,g_Selling[g_CurNpc[id]][Item][ITEMID],ARP_GetUserItemNum(id,g_Selling[g_CurNpc[id]][Item][ITEMID]) + 1)
	ARP_SetUserWallet(id,UserCash - g_Selling[g_CurNpc[id]][Item][COST])
	
	new Property = ARP_GetNpcProperty(g_CurNpcId[id])
	if(ARP_ValidProperty(Property))
		ARP_PropertySetProfit(Property,floatround(ARP_PropertyGetProfit(Property) + g_Selling[g_CurNpc[id]][Item][COST] * get_pcvar_float(p_ProfitFraction)))
	
	client_print(id,print_chat,"[ARP] You have bought 1 %s.",ItemName)
}

public BankHandle(id,Ent)
{
	new Npc = FindNpc(Ent),Menu[512],Len = sizeof Menu - 1
	
	g_CurNpc[id] = Npc
	g_CurNpcId[id] = Ent
	
	copy(Menu,Len,"ARP Bank^n^n1. Withdraw/Deposit^n2. Buy ATM Card ($10)^n3. Buy Debit Card ($100)^n4. Rob^n^n0. Exit")
	show_menu(id,g_Keys,Menu,-1,g_BankMenu)	
}

public BankMenuHandle(id,Key)
{
	if(!ARP_NpcDistance(id,g_CurNpcId[id]))
		return
	
	switch(Key)
	{
		case 0 :
			client_print(id,print_chat,"[ARP] Type /withdraw or /deposit to withdraw/deposit.")
		case 1 :
		{
			new Results[1],Cash = ARP_GetUserWallet(id)
			ARP_FindItemId("ATM Card",Results,1)
			
			if(!Results[0])
			{
				client_print(id,print_chat,"[ARP] Internal error: contact admin.")
				return
			}
			
			if(Cash < 10)
			{
				client_print(id,print_chat,"[ARP] You don't have enough money.")
				return
			}
			
			ARP_SetUserItemNum(id,Results[0],ARP_GetUserItemNum(id,Results[0]) + 1)
			ARP_SetUserWallet(id,Cash - 10)
			
			new ItemName[33]
			ARP_GetItemName(Results[0],ItemName,32)
			
			client_print(id,print_chat,"[ARP] You have purchased 1 %s.",ItemName)
		}
		case 2 :
		{
			new Results[1],Cash = ARP_GetUserWallet(id)
			ARP_FindItemId("Debit Card",Results,1)
			
			if(!Results[0])
			{
				client_print(id,print_chat,"[ARP] Internal error: contact admin.")
				return
			}
			
			if(Cash < 100)
			{
				client_print(id,print_chat,"[ARP] You don't have enough money.")
				return
			}
			
			ARP_SetUserItemNum(id,Results[0],ARP_GetUserItemNum(id,Results[0]) + 1)
			ARP_SetUserWallet(id,Cash - 100)
			
			new ItemName[33]
			ARP_GetItemName(Results[0],ItemName,32)
			
			client_print(id,print_chat,"[ARP] You have purchased 1 %s.",ItemName)
		}
		case 3 :
		{
			if(!g_RobProfile[g_CurNpc[id]][0])
				return
			
			new Data[34]
			Data[0] = id
			copy(Data[1],32,g_RobProfile[g_CurNpc[id]])
			
			ARP_CallEvent("Rob_Begin",Data,34)
			
			return
		}
	}
}

public CmdSay(id,Mode,Args[])
{	
	static Index,Body,Mode = 0
	get_user_aiming(id,Index,Body,100)
	
	if(equali(Args,"/withdraw",9))
		Mode = 1
	else if(equali(Args,"/deposit",8))
		Mode = 2
	else if(equali(Args,"/transfer",9))
		Mode = 3
	else
		return PLUGIN_CONTINUE
	
	new ItemIds[1]
	ARP_FindItemId("Debit Card",ItemIds,1)
	if(Mode == 1 && ARP_ValidItemId(ItemIds[0]) && ARP_GetUserItemNum(id,ItemIds[0]))
	{
		Cash(id,Args,Mode)
		return PLUGIN_HANDLED
	}
	
	new NpcName[33]
	
	if(Index)
	{
		new Classname[33]
		entity_get_string(Index,EV_SZ_classname,Classname,32)
		
		if(equali(Classname,"arp_npc") || equali(Classname,"arp_zone"))
		{			
			if(ARP_GetNpcName(Index,NpcName,32) && containi(NpcName,g_Npcs[1]) != -1)
			{
				Cash(id,Args,Mode)
				return PLUGIN_HANDLED
			}
		}
	}
	
	new EntList[1]
	if(find_sphere_class(id,"arp_zone",100.0,EntList,1))
	{
		Index = EntList[0]
		if(ARP_GetNpcName(Index,NpcName,32) && containi(NpcName,g_Npcs[1]) != -1)
		{
			Cash(id,Args,Mode)
			return PLUGIN_HANDLED
		}
	}
	
	client_print(id,print_chat,"[ARP] You are not looking at a Banker.")
	
	//Cash(id,Args,Mode)
	
	return PLUGIN_HANDLED
}

Cash(id,Args[],Mode)
{
	if(Mode == 3)
	{
		new Name[33],StrAmount[33],Amount,Temp[2]
		parse(Args,Temp,1,Name,32,StrAmount,32)
		
		new Target = cmd_target(id,Name,0)
		if(!Target)
		{
			client_print(id,print_chat,"[ARP] Could not find a user matching your input.")
			return PLUGIN_HANDLED
		}
		
		Amount = str_to_num(StrAmount)
		new Bank = ARP_GetUserBank(id)
		if(Amount > Bank)
		{
			client_print(id,print_chat,"[ARP] You do not have enough money in your bank account.")
			return PLUGIN_HANDLED
		}
		
		if(Amount < 1)
		{
			client_print(id,print_chat,"[ARP] Invalid amount; please enter a whole number.")
			return PLUGIN_HANDLED
		}
		
		ARP_SetUserBank(Target,ARP_GetUserBank(Target) + Amount)
		ARP_SetUserBank(id,Bank - Amount)
		
		get_user_name(Target,Name,32)
		client_print(id,print_chat,"[ARP] You have transferred %s $%d.",Name,Amount)
		get_user_name(id,Name,32)
		client_print(Target,print_chat,"[ARP] You have been transferred $%d by %s.",Amount,Name)
		
		return PLUGIN_HANDLED
	}
	
	new AmountStr[64],Temp[2]
	
	remove_quotes(Args)
	parse(Args,Temp,1,AmountStr,63)
	
	new Amount = str_to_num(AmountStr),Cash = Mode == 1 ? ARP_GetUserBank(id) : ARP_GetUserWallet(id)
	if(Amount < 1)
	{
		client_print(id,print_chat,"[ARP] You did not specify a valid amount.")
		return PLUGIN_HANDLED
	}
	else if(Amount > Cash)
	{
		client_print(id,print_chat,"[ARP] You do not have enough money in your %s.",Mode == 1 ? "bank account" : "wallet")
		return PLUGIN_HANDLED
	}
	
	ARP_SetUserWallet(id,Mode == 1 ? ARP_GetUserWallet(id) + Amount : ARP_GetUserWallet(id) - Amount)
	ARP_SetUserBank(id,Mode == 1 ? ARP_GetUserBank(id) - Amount : ARP_GetUserBank(id) + Amount)
	
	client_print(id,print_chat,"[ARP] You have %s $%d %s your bank account.",Mode == 1 ? "withdrawn" : "deposited",Amount,Mode == 1 ? "from" : "into")
	
	return PLUGIN_HANDLED
}

public DoctorHandle(id,Ent)
{
	g_MenuPage[id] = 0
	Doctor(id,Ent)
}

Doctor(id,Ent)
{
	new Npc = FindNpc(Ent)//,ItemName[33],Menu[512],Len = sizeof Menu - 1,Pos,Num
	
	g_CurNpc[id] = Npc
	g_CurNpcId[id] = Ent
	
	new Menu = menu_create("ARP Doctor","DoctorMenuHandle"),ItemName[33],ItemNum[10]
	if(g_Heal[Npc] >= 0) 
	{
		new Heal[64]
		format(Heal,63,"* Heal Me ($%d)",g_Heal[Npc])
		menu_additem(Menu,Heal,"-1")
		menu_addblank(Menu,0)
	}
	new Command[64]
	for(new Count = 1;Count < g_ItemNum[Npc];Count++)
	{
		ARP_ValidItemId(g_Selling[Npc][Count][ITEMID]) ? ARP_GetItemName(g_Selling[Npc][Count][ITEMID],ItemName,32) : copy(ItemName,32,"BAD ITEM ID: Contact admin")
		num_to_str(g_Selling[Npc][Count][ITEMID],ItemNum,9)
		format(Command,63,"%s - $%d",ItemName,g_Selling[Npc][Count][COST])
		menu_additem(Menu,Command,ItemNum)
	}
	
	menu_display(id,Menu)
}

public DoctorMenuHandle(id,Menu,Item)	
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT || !ARP_NpcDistance(id,g_CurNpcId[id]))
		return
		
	//new Item = g_MenuPage[id] * 7 + Key,Cash = ARP_GetUserWallet(id)
	new Cash = ARP_GetUserWallet(id)
	//if(!g_Selling[g_CurNpc[id]][Item][COST])
	//{
	//	Doctor(id,g_CurNpcId[id])
	//	return
	//}
	
	//if(g_Heal[g_CurNpc[id]] >= 0)
	//	Item--
	
	//if(Item && !g_Selling[g_CurNpc[id]][Item][ITEMID])
	//{
	//	Doctor(id,g_CurNpcId[id])
	//	return
	//}
	
	if(g_Heal[g_CurNpc[id]] < 0) Item++
	
	if(ARP_GetUserWallet(id) < g_Selling[g_CurNpc[id]][Item][COST])
	{
		client_print(id,print_chat,"[ARP] You don't have enough money for that item.")
		return
	}
	
	new ItemName[33]
	if(g_Heal[g_CurNpc[id]] >= 0 && !Item)
	{
		if(get_user_health(id) >= 100)
		{
			client_print(id,print_chat,"[ARP] You are not injured.")
			return
		}
		
		if(g_MaxSpeed[id])
		{
			client_print(id,print_chat,"[ARP] You are already being healed.")
			return
		}
		
		new Cash = ARP_GetUserWallet(id)
		if(Cash < g_Heal[g_CurNpc[id]])
		{
			client_print(id,print_chat,"[ARP] You do not have enough money to be healed.")
			return
		}
		
		new Data[1]
		Data[0] = id
		if(ARP_CallEvent("Player_HealBegin",Data,1))
			return
		
		g_MaxSpeed[id] = 1.0//entity_get_float(id,EV_FL_maxspeed)
		
		ARP_SetUserSpeed(id,Speed_Override,0.1)
		
		set_task(1.0,"HealUser",id)
		
		ARP_SetUserWallet(id,Cash - g_Heal[g_CurNpc[id]])
		
		client_print(id,print_chat,"[ARP] You are now being healed.")
		
		set_rendering(id,kRenderFxGlowShell,255,255,255,kRenderNormal,16)
		
		return
	}				
	
	if(!ARP_ValidItemId(g_Selling[g_CurNpc[id]][Item][ITEMID]))
	{
		client_print(id,print_chat,"[ARP] This item is broken; please contact the administrator.")
		return
	}
	
	ARP_GetItemName(g_Selling[g_CurNpc[id]][Item][ITEMID],ItemName,32)
	
	ARP_SetUserItemNum(id,g_Selling[g_CurNpc[id]][Item][ITEMID],ARP_GetUserItemNum(id,g_Selling[g_CurNpc[id]][Item][ITEMID]) + 1)
	ARP_SetUserWallet(id,Cash - g_Selling[g_CurNpc[id]][Item][COST])
	
	client_print(id,print_chat,"[ARP] You have bought 1 %s.",ItemName)
}

public HealUser(id)
{
	if(!is_user_alive(id) || !g_MaxSpeed[id])
		return
	
	if(get_user_health(id) >= 100)
	{
		new Data[1]
		Data[0] = id
		if(ARP_CallEvent("Player_HealEnd",Data,1))
			return
		
		client_print(id,print_chat,"[ARP] You are now completely healed.")
		
		set_rendering(id,kRenderFxNone,255,255,255,kRenderNormal,16)
		
		//entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id])
		ARP_SetUserSpeed(id,Speed_None)
		g_MaxSpeed[id] = 0.0
		
		return
	}
	
	entity_set_float(id,EV_FL_health,entity_get_float(id,EV_FL_health) + 1.0)
	
	set_task(1.0,"HealUser",id)
}

public AtmHandle(id,Ent)
{
	new Results[1],Items = ARP_FindItemId("ATM Card",Results,1)
	if(!Items)
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact administrator.")
		return
	}
	
	if(!ARP_GetUserItemNum(id,Results[0]))
	{
		client_print(id,print_chat,"[ARP] You don't have an ATM card.")
		return
	}
	
	new Npc = FindNpc(Ent),Menu[512],Len = sizeof Menu - 1
	
	g_CurNpc[id] = Npc
	g_CurNpcId[id] = Ent
	
	copy(Menu,Len,"ARP ATM^n^n1. Withdraw^n2. Deposit^n^n0. Exit")
	show_menu(id,g_Keys,Menu,-1,g_AtmMenu)	
}

public AtmMenuHandle(id,Key)
{	
	if(!ARP_NpcDistance(id,g_CurNpcId[id]))
		return
	
	if(Key != 0 && Key != 1)
	{
		if(Key != 9)
			AtmHandle(id,g_CurNpcId[id])
		
		return
	}
	
	g_Mode[id] = Key
	
	new Menu[512],String[] = "Withdraw"
	String = Key ? "Deposit" : "Withdraw"
	
	format(Menu,511,"ARP ATM %s^n^n1. %s $10^n2. %s $20^n3. %s $50^n4. %s $100^n5. %s $250^n6. %s $500^n7. %s $1000^n^n0. Exit",String,String,String,String,String,String,String,String)
	
	show_menu(id,g_Keys,Menu,-1,g_AtmUse)
}

public AtmUseMenuHandle(id,Key)
{
	if(!ARP_NpcDistance(id,g_CurNpcId[id]))
		return
	
	if(Key > 6)
	{
		if(Key != 9)
			AtmMenuHandle(id,g_Mode[id])
		
		return
	}
	
	new Amount
	switch(Key)
	{
		case 0 :
		Amount = 10
		case 1 :
		Amount = 20
		case 2 :
		Amount = 50
		case 3 :
		Amount = 100
		case 4 :
		Amount = 250
		case 5 :
		Amount = 500
		case 6 :
		Amount = 1000
	}
	
	new Cash = g_Mode[id] ? ARP_GetUserWallet(id) : ARP_GetUserBank(id) 
	if(Amount > Cash)
	{
		client_print(id,print_chat,"[ARP] You don't have enough money in your %s.",g_Mode[id] ? "wallet" : "bank account")
		return
	}
	
	ARP_SetUserBank(id,g_Mode[id] ? ARP_GetUserBank(id) + Amount : ARP_GetUserBank(id) - Amount)
	ARP_SetUserWallet(id,g_Mode[id] ? ARP_GetUserWallet(id) - Amount : ARP_GetUserWallet(id) + Amount)
	
	client_print(id,print_chat,"[ARP] You have %s $%d %s your bank account.",g_Mode[id] ? "deposited" : "withdrawn",Amount,g_Mode[id] ? "into" : "from")
}

public GunshopHandle(id,Ent)
{
	g_MenuPage[id] = 0
	Gunshop(id,Ent)
}

Gunshop(id,Ent)
{
	new Npc = FindNpc(Ent),Menu[512],Len = sizeof Menu - 1,Pos,Num,Keys = MENU_KEY_0
	
	g_CurNpc[id] = Npc
	g_CurNpcId[id] = Ent
	
	Pos += format(Menu[Pos],Len - Pos,"ARP Gunshop^n^n")
	for(new Count;Count < GUNSHOP_MODES;Count++)
	{
		if(g_Mod == TS || !equali(g_ModeNames[Count],"Fill Ammo"))
		{
			Pos += format(Menu[Pos],Len - Pos,"%d. %s^n",++Num,g_ModeNames[Count])
			Keys |= (1<<Count)
		}
	}
	Pos += format(Menu[Pos],Len - Pos,"^n0. Exit")
	
	show_menu(id,Keys,Menu,-1,g_GunshopMenu)
}

public GunshopMenuHandle(id,Key)
{
	g_MenuPage[id] = 0
	// can't think of a better name, sorry
	GunshopMenuHandle2(id,Key)
}

GunshopMenuHandle2(id,Key)
{
	if(!ARP_NpcDistance(id,g_CurNpcId[id]))
		return
	
	if(Key >= GUNSHOP_MODES)
	{
		if(Key != 9)
			Gunshop(id,g_CurNpcId[id])
		
		return
	}
	
	g_Mode[id] = Key
	new ItemName[33],ItemId
	
	switch(Key)
	{
		// non-restricted
		case 0 .. 1 :
		{
			new Results[1]
			ARP_FindItemId(g_ModeNames[Key],Results,1)
			ItemId = Results[0]
		}
		/*// Restricted
		case 1 :
		{
			new Results[2]
			ARP_FindItemId(g_ModeNames[1],Results,2)
			
			for(new Count;Count < 2;Count++)
				if(Results[Count])
			{
				ARP_GetItemName(Results[Count],ItemName,32)
				
				if(containi(g_ModeNames[0],ItemName) == -1)
					ItemId = Results[Count]
			}
		}*/
		case 2 :
			ItemId = -1
		case 3 :
		{
			if(g_Mod != TS) return
			
			new Cost = get_pcvar_num(p_FillCost),Money = ARP_GetUserWallet(id)
			if(Cost > Money)
			{
				client_print(id,print_chat,"[ARP] You do not have enough money for this. ($%d)",Cost)
				return
			}
			
			new Temp,Ammo,Weapon = ts_getuserwpn(id,Temp,Ammo,Temp,Temp)
			if(!g_WeaponAmmo[Weapon])
			{
				client_print(id,print_chat,"[ARP] You must be wielding a weapon that uses ammo.")
				return
			}
			
			if(Ammo >= g_WeaponAmmo[Weapon])
			{
				client_print(id,print_chat,"[ARP] Your ammo for this gun is already topped up.")
				return
			}
			
			ts_setuserammo(id,Weapon,g_WeaponAmmo[Weapon])
			
			ARP_SetUserWallet(id,Money - Cost)
			
			new Property = ARP_GetNpcProperty(g_CurNpcId[id])
			if(ARP_ValidProperty(Property))
				ARP_PropertySetProfit(Property,floatround(ARP_PropertyGetProfit(Property) + Cost * get_pcvar_float(p_ProfitFraction)))
			
			client_print(id,print_chat,"[ARP] Your ammo has been refilled.")
			
			return
		}
	}
	
	//client_print(id,print_chat,"ModeNames: [%s],ItemId: %d,Results: %d,Key: %d,g_Mode: %d",g_ModeNames[Key],ItemId,Results[0],Key,g_Mode[id])
	
	if(!ItemId && ItemId != -1)
	{
		client_print(id,print_chat,"[ARP] Internal error; please contact administrator.")
		return
	}
	
	if(ItemId != -1 && !ARP_GetUserItemNum(id,ItemId))
	{
		client_print(id,print_chat,"[ARP] You do not have a %s license.",g_ModeNames[g_Mode[id]])
		return
	}
	
	//new Menu[512],Pos,Len = sizeof Menu - 1,CountNum
	new Menu = menu_create("ARP Gunshop","GunshopUseMenuHandle")
	
	for(new Count,Command[64];Count < g_WeaponNum[g_CurNpc[id]][g_Mode[id]];Count++)
	{
		switch(g_Mode[id])
		{
			case 0 :
				if(ARP_ValidItemId(g_NonRestricted[g_CurNpc[id]][Count][ITEMID]))
				{	
					ARP_GetItemName(g_NonRestricted[g_CurNpc[id]][Count][ITEMID],ItemName,32)
					format(Command,63,"%s - $%d",ItemName,g_NonRestricted[g_CurNpc[id]][Count][COST])
				}
				else
					format(Command,63,"BAD ITEM ID: Contact admin")
			case 1 :
				if(ARP_ValidItemId(g_Restricted[g_CurNpc[id]][Count][ITEMID]))
				{
					ARP_GetItemName(g_Restricted[g_CurNpc[id]][Count][ITEMID],ItemName,32)
					format(Command,63,"%s - $%d",ItemName,g_Restricted[g_CurNpc[id]][Count][COST])
				}
				else
					format(Command,63,"BAD ITEM ID: Contact admin")
			case 2 :
				if(ARP_ValidItemId(g_Licenses[g_CurNpc[id]][Count][ITEMID]))
				{
					ARP_GetItemName(g_Licenses[g_CurNpc[id]][Count][ITEMID],ItemName,32)
					format(Command,63,"%s - $%d",ItemName,g_Licenses[g_CurNpc[id]][Count][COST])
				}
				else
					format(Command,63,"BAD ITEM ID: Contact admin")
		}
		
		menu_additem(Menu,Command,"")
	}
	
	g_WeaponNum[g_CurNpc[id]][g_Mode[id]] ? menu_display(id,Menu) : client_print(id,print_chat,"[ARP] There are no items in this category.")
}

// getting a bit long
public GunshopUseMenuHandle(id,Menu,Item)
{	
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT || !ARP_NpcDistance(id,g_CurNpcId[id]))
		return
	
	new Cost,ItemName[33],ItemId
	switch(g_Mode[id])
	{
		case 0 :
		{
			ItemId = g_NonRestricted[g_CurNpc[id]][Item][ITEMID]
			Cost = g_NonRestricted[g_CurNpc[id]][Item][COST]
		}
		case 1 :
		{
			ItemId = g_Restricted[g_CurNpc[id]][Item][ITEMID]
			Cost = g_Restricted[g_CurNpc[id]][Item][COST]
		}
		case 2 :
		{
			ItemId = g_Licenses[g_CurNpc[id]][Item][ITEMID]
			Cost = g_Licenses[g_CurNpc[id]][Item][COST]
		}
	}
	
	if(!ARP_ValidItemId(ItemId))
	{
		client_print(id,print_chat,"[ARP] This item is broken; please contact an administrator.")
		return
	}
	
	new Money = ARP_GetUserWallet(id),Total = Money - Cost
	
	if(Total < 0)
	{
		client_print(id,print_chat,"[ARP] You do not have enough money for this item.")
		GunshopMenuHandle2(id,g_Mode[id])
		return
	}
	
	ARP_GetItemName(ItemId,ItemName,32)
	ARP_SetUserItemNum(id,ItemId,ARP_GetUserItemNum(id,ItemId) + 1)
	
	client_print(id,print_chat,"[ARP] You have purchased a %s.",ItemName)
	
	ARP_SetUserWallet(id,Total)
	
	new Property = ARP_GetNpcProperty(g_CurNpcId[id])
	if(ARP_ValidProperty(Property))
		ARP_PropertySetProfit(Property,floatround(ARP_PropertyGetProfit(Property) + Cost * get_pcvar_float(p_ProfitFraction)))
}

//public client_PreThink(id)
//	if(g_MaxSpeed[id])
//		entity_set_float(id,EV_FL_maxspeed,0.1)
	
public EventDeathMsg()
{
	new id = read_data(2)
	//entity_set_float(id,EV_FL_maxspeed,g_MaxSpeed[id])
	ARP_SetUserSpeed(id,Speed_None)
	g_MaxSpeed[id] = 0.0
}

FindNpc(Ent)
{
	for(new Count;Count < 50;Count++)
		if(Ent == g_NpcId[Count])
			return Count
		
	return FAILED
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
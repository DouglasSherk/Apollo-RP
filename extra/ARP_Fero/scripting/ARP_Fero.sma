#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <engine>

new Class:g_Class[33]

enum _:HUD_CVARS
{
	X = 0,
	Y,
	R,
	G,
	B,
	CHANGED
}

new p_Hud[HUD_NUM][HUD_CVARS]
new g_HudDefault[HUD_NUM][HUD_CVARS]
new g_Hud[33][HUD_NUM][HUD_CVARS]
new g_SettingChannel[33]
new g_SettingAspect[33]

public plugin_init()
{	
	ARP_RegisterEvent("Menu_Display","EventClientMenu")
	ARP_RegisterEvent("HUD_Render","EventHudRender")
	//ARP_RegisterEvent("Class_Save","EventSaveClass")
	
	set_task(0.5,"GetCvars")
}

public ARP_Init()
	ARP_RegisterPlugin("Fero","1.0","Hawk552","Gives users access to their HUDs")

public GetCvars()
	for(new Count,Cvar[33];Count < HUD_NUM;Count++)
	{
		format(Cvar,32,"arp_hud%d_x",Count + 1)
		p_Hud[Count][X] = get_cvar_pointer(Cvar)
		g_HudDefault[Count][X] = _:get_pcvar_float(p_Hud[Count][X])
		
		format(Cvar,32,"arp_hud%d_y",Count + 1)
		p_Hud[Count][Y] = get_cvar_pointer(Cvar)
		g_HudDefault[Count][Y] = _:get_pcvar_float(p_Hud[Count][Y])
		
		format(Cvar,32,"arp_hud%d_r",Count + 1)
		p_Hud[Count][R] = get_cvar_pointer(Cvar)
		g_HudDefault[Count][R] = get_pcvar_num(p_Hud[Count][R])
		
		format(Cvar,32,"arp_hud%d_g",Count + 1)
		p_Hud[Count][G] = get_cvar_pointer(Cvar)
		g_HudDefault[Count][G] = get_pcvar_num(p_Hud[Count][G])
		
		format(Cvar,32,"arp_hud%d_b",Count + 1)
		p_Hud[Count][B] = get_cvar_pointer(Cvar)
		g_HudDefault[Count][B] = get_pcvar_num(p_Hud[Count][B])
	}

public client_putinserver(id)
{
	for(new Count;Count < HUD_NUM;Count++)
		SetDefaults(id,Count)
	
	new Authid[36],Data[10]
	get_user_authid(id,Authid,35)
	
	num_to_str(id,Data,9)
	
	ARP_ClassLoad(Authid,"HudLoaded",Data)
}

SetDefaults(id,Channel)
{
	g_Hud[id][Channel][X] = g_HudDefault[Channel][X]
	g_Hud[id][Channel][Y] = g_HudDefault[Channel][Y]
	g_Hud[id][Channel][R] = g_HudDefault[Channel][R]
	g_Hud[id][Channel][G] = g_HudDefault[Channel][G]
	g_Hud[id][Channel][B] = g_HudDefault[Channel][B]
}

public client_disconnect(id)
	if(g_Class[id])
		ARP_ClassSave(g_Class[id],1)
	
public HudLoaded(Class:class_id,const class[],data[])
{
	new Player = str_to_num(data)
	g_Class[Player] = class_id
	
	ARP_ClassSaveHook(class_id,"EventSaveClass",data)
	
	for(new Count2;Count2 < HUD_NUM;Count2++)
	{
		new Settings[64],Req[64]
		format(Req,63,"HUD%d",Count2 + 1)
		ARP_ClassGetString(class_id,Req,Settings,63)
		
		if(!strlen(Settings))
			continue
		
		new XS[13],YS[13],RS[13],GS[13],BS[13]
		strtok(Settings,XS,12,Settings,63,'|')
		strtok(Settings,YS,12,Settings,63,'|')
		strtok(Settings,RS,12,Settings,63,'|')
		strtok(Settings,GS,12,Settings,63,'|')
		strtok(Settings,BS,12,Settings,63,'|')
		
		g_Hud[Player][Count2][X] = _:(str_to_float(XS) / 100.0)
		g_Hud[Player][Count2][Y] = _:(str_to_float(YS) / 100.0)
		g_Hud[Player][Count2][R] = str_to_num(RS)
		g_Hud[Player][Count2][G] = str_to_num(GS)
		g_Hud[Player][Count2][B] = str_to_num(BS)
	}
}

/*public ARP_ClassLoaded(Class:class_id,const class[])
{
	server_print("Class Called: %s",class)
	if(equali(class,"STEAM_0:",8))
	{
		new Class[64],Authid[36],Players[32],Playersnum,Player
		copy(Class,63,class)
		get_players(Players,Playersnum)
		
		server_print("Class: %s | class: %s",Class,class)
		
		for(new Count;Count < Playersnum;Count++)
		{
			Player = Players[Count]
			get_user_authid(Player,Authid,35)
			if(equali(Authid,Class))
			{
				server_print("Player found")
				
				g_Class[Player] = class_id
				
				for(new Count2;Count2 < HUD_NUM;Count2++)
				{
					new Settings[64],Req[64]
					format(Req,63,"HUD%d",Count2 + 1)
					ARP_ClassGetString(class_id,Req,Settings,63)
					
					server_print("[LOADING] Req: %s | Settings: %s",Req,Settings)
					
					if(!strlen(Settings))
						return
					
					new XS[13],YS[13],RS[13],GS[13],BS[13]
					strtok(Settings,XS,12,Settings,63,'|')
					strtok(Settings,YS,12,Settings,63,'|')
					strtok(Settings,RS,12,Settings,63,'|')
					strtok(Settings,GS,12,Settings,63,'|')
					strtok(Settings,BS,12,Settings,63,'|')
					
					server_print("%s %s %s %s %s",XS,YS,RS,GS,BS)
					
					g_Hud[Player][Count2][X] = _:(str_to_float(XS) / 100.0)
					g_Hud[Player][Count2][Y] = _:(str_to_float(YS) / 100.0)
					g_Hud[Player][Count2][R] = str_to_num(RS)
					g_Hud[Player][Count2][G] = str_to_num(GS)
					g_Hud[Player][Count2][B] = str_to_num(BS)
				}
			}
		}
	}
}*/

public EventClientMenu(Name[],Data[],Len)
{
	new id = Data[0]
	ARP_AddMenuItem(id,"HUD Settings","HudMenu")
}

public EventSaveClass(Class:ClassId,Name[],Data[])
{	
	new id = str_to_num(Data)
	for(new Count,Settings[64],Req[64];Count < HUD_NUM;Count++)
	{		
		if(!g_Hud[id][Count][CHANGED])
			continue
		
		format(Req,63,"HUD%d",Count + 1)
		format(Settings,63,"%d|%d|%d|%d|%d",floatround(Float:g_Hud[id][Count][X] * 100.0),floatround(Float:g_Hud[id][Count][Y] * 100.0),g_Hud[id][Count][R],g_Hud[id][Count][G],g_Hud[id][Count][B])
		ARP_ClassSetString(ClassId,Req,Settings)
			
		ARP_ClassGetString(ClassId,Req,Settings,63)
	}
}

public EventHudRender(Name[],Data[],Len)
{	
	new id = Data[0]
	if(g_SettingAspect[id] && Data[1] == g_SettingChannel[id])
	{
		ARP_AddHudItem(id,g_SettingChannel[id],0,"SAMPLE TEXT")
		
		new Message[128]
		format(Message,127,"Hit: %s to adjust HUD, E to end.",g_SettingAspect[id] == 1 ? "W, A, S, D" : "W, S")
		
		ARP_ClientPrint(id,Message)
	}
		
	SetCvars(id)
}

/*public ARP_Event(Name[],Data[],Len)
	if(equali(Name,"clientmenu"))
	{	
		new id = Data[0]
		ARP_AddMenuItem(id,"HUD Settings","HudMenu")
	}
	else if(equali(Name,"savingclass") && equali(Data[1],"HUD_",4))
	{
		new id = g_LastDisconnected
		for(new Count,Settings[64],Req[64];Count < HUD_NUM;Count++)
		{		
			format(Req,63,"HUD%d",Count + 1)
			format(Settings,63,"%f|%f|%d|%d|%d",Float:g_Hud[id][Count][X],Float:g_Hud[id][Count][Y],g_Hud[id][Count][R],g_Hud[id][Count][G],g_Hud[id][Count][B])
			ARP_ClassSetString(g_Class[id],Req,Settings)
			
			ARP_ClassGetString(g_Class[id],Req,Settings,63)
			server_print("Req: %s | Settings: %s",Req,Settings)
		}
	}
	else if(equali(Name,"hudrender"))
	{
		if(Data[1] == HUD_QUAT)
			ARP_HudDisplay(Data[0])
		
		SetCvars(Data[0])
	}*/

public HudMenu(id)
{
	new Menu = menu_create("HUD Settings - Channel","HudChannel")
	menu_additem(Menu,"HUD 1","")
	menu_additem(Menu,"HUD 2","")
	menu_additem(Menu,"HUD 3","")
	menu_additem(Menu,"Auxiliary HUD","")
	menu_addblank(Menu,0)
	menu_additem(Menu,"Reset All Defaults","")
	menu_display(id,Menu,0)
}

public HudChannel(id,Menu,Item)
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT)
		return
	
	if(Item == 4)
	{
		client_print(id,print_chat,"[ARP] You have set all of your HUD channels back to their server defaults.")
		
		for(new Count;Count < HUD_NUM;Count++)
			SetDefaults(id,Count)
		
		return
	}
		
	if(get_cvar_num("arp_hud4_type") != 2 && Item == 3)
	{
		client_print(id,print_chat,"[ARP] This HUD cannot be adjusted.")
		return
	}
	
	g_SettingChannel[id] = Item
	
	Menu = menu_create("HUD Settings - Aspect","HudAspect")
	menu_additem(Menu,"Position","")
	menu_addblank(Menu,0)
	menu_additem(Menu,"Red Amount","")
	menu_additem(Menu,"Green Amount","")
	menu_additem(Menu,"Blue Amount","")
	menu_addblank(Menu,0)
	menu_additem(Menu,"Reset Channel Defaults","")
	menu_display(id,Menu,0)	
}

public HudAspect(id,Menu,Item)
{
	menu_destroy(Menu)
	
	if(Item == MENU_EXIT)
		return
	
	if(Item == 4)
	{
		client_print(id,print_chat,"[ARP] You have set this HUD channel back to it's server default.")
		
		SetDefaults(id,g_SettingChannel[id])
		return
	}
	
	g_SettingAspect[id] = Item + 1
	
	drop_to_floor(id)
	new Float:Origin[3]
	entity_get_vector(id,EV_VEC_origin,Origin)
	
	Origin[2] -= 1.0
	
	entity_set_origin(id,Origin)
}

public client_PreThink(id)
{
	if(!g_SettingAspect[id])
		return
	
	new Button = entity_get_int(id,EV_INT_button),OldButtons = entity_get_int(id,EV_INT_oldbuttons)
	if(Button & IN_USE && !(OldButtons & IN_USE))
	{
		new Float:Origin[3]
		entity_get_vector(id,EV_VEC_origin,Origin)
		
		Origin[2] += 5.0
		
		entity_set_origin(id,Origin)
		drop_to_floor(id)
		
		client_print(id,print_chat,"[ARP] You have locked your HUD in this setup.")
		g_SettingAspect[id] = 0	
		
		return
	}
	if(Button & IN_FORWARD && !(OldButtons & IN_FORWARD))
	{
		switch(g_SettingAspect[id])
		{
			case 1 :
				g_Hud[id][g_SettingChannel[id]][Y] = _:floatclamp(Float:g_Hud[id][g_SettingChannel[id]][Y] - 0.025,0.0,1.0)
			case 2 :
				g_Hud[id][g_SettingChannel[id]][R] = clamp(g_Hud[id][g_SettingChannel[id]][R] + 25,0,255)
			case 3 :
				g_Hud[id][g_SettingChannel[id]][G] = clamp(g_Hud[id][g_SettingChannel[id]][G] + 25,0,255)
			case 4 :
				g_Hud[id][g_SettingChannel[id]][B] = clamp(g_Hud[id][g_SettingChannel[id]][B] + 25,0,255)
		}
		
		g_Hud[id][g_SettingChannel[id]][CHANGED] = 1
		ARP_RefreshHud(id,g_SettingChannel[id])
	}
	if(Button & IN_BACK && !(OldButtons & IN_BACK))
	{
		switch(g_SettingAspect[id])
		{
			case 1 :
				g_Hud[id][g_SettingChannel[id]][Y] = _:floatclamp(Float:g_Hud[id][g_SettingChannel[id]][Y] + 0.025,0.0,1.0)
			case 2 :
				g_Hud[id][g_SettingChannel[id]][R] = clamp(g_Hud[id][g_SettingChannel[id]][R] - 25,0,255)
			case 3 :
				g_Hud[id][g_SettingChannel[id]][G] = clamp(g_Hud[id][g_SettingChannel[id]][G] - 25,0,255)
			case 4 :
				g_Hud[id][g_SettingChannel[id]][B] = clamp(g_Hud[id][g_SettingChannel[id]][B] - 25,0,255)
		}
		
		g_Hud[id][g_SettingChannel[id]][CHANGED] = 1
		ARP_RefreshHud(id,g_SettingChannel[id])
	}
	if(Button & IN_MOVELEFT && !(OldButtons & IN_MOVELEFT) && g_SettingAspect[id] == 1)
	{
		g_Hud[id][g_SettingChannel[id]][X] = _:floatclamp(Float:g_Hud[id][g_SettingChannel[id]][X] - 0.025,0.0,1.0)
		
		g_Hud[id][g_SettingChannel[id]][CHANGED] = 1
		ARP_RefreshHud(id,g_SettingChannel[id])
	}
	
	if(Button & IN_MOVERIGHT && !(OldButtons & IN_MOVERIGHT) && g_SettingAspect[id] == 1)
	{
		g_Hud[id][g_SettingChannel[id]][X] = _:floatclamp(Float:g_Hud[id][g_SettingChannel[id]][X] + 0.025,0.0,1.0)
		
		g_Hud[id][g_SettingChannel[id]][CHANGED] = 1
		ARP_RefreshHud(id,g_SettingChannel[id])
	}
	
	//client_print(id,print_chat,"[ARP] Values: %d | %f",g_Hud[id][g_SettingChannel[id]][X],g_Hud[id][g_SettingChannel[id]][X])
}

SetCvars(id)
	for(new Count;Count < HUD_NUM;Count++)
	{
		set_pcvar_float(p_Hud[Count][X],Float:g_Hud[id][Count][X])
		set_pcvar_float(p_Hud[Count][Y],Float:g_Hud[id][Count][Y])
		set_pcvar_num(p_Hud[Count][R],g_Hud[id][Count][R])
		set_pcvar_num(p_Hud[Count][G],g_Hud[id][Count][G])
		set_pcvar_num(p_Hud[Count][B],g_Hud[id][Count][B])
	}
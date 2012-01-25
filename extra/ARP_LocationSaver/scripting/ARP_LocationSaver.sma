#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
//#include <hamsandwich>
#include <ApolloRP>

new Class:g_Class[33]
new Float:g_Origin[33][3]

//new g_LastDisconnected

public plugin_init()
{	
	//ARP_RegisterEvent("Class_Save","EventSavingClass")
	
	register_event("ResetHUD","EventResetHUD","be")
	
	//RegisterHam(Ham_Spawn,"EventResetHUD","player")
}

public ARP_Init()
	ARP_RegisterPlugin("Location Saver","1.0","Hawk552","Saves the user's location until they rejoin")

public EventResetHUD(id)
	set_task(0.1,"MovePlayer",id)

public MovePlayer(id)
	// primitive epsilon format
	if(is_user_alive(id) && floatabs(g_Origin[id][0]) + floatabs(g_Origin[id][1]) + floatabs(g_Origin[id][2]) > 0.1)
	{
		engfunc(EngFunc_SetOrigin,id,g_Origin[id])
		
		g_Origin[id][0] = 0.0
		g_Origin[id][1] = 0.0
		g_Origin[id][2] = 0.0
	}
		
public client_putinserver(id)
{
	new Authid[36],Data[10]
	get_user_authid(id,Authid,35)
	
	num_to_str(id,Data,9)
	
	ARP_ClassLoad(Authid,"PositionLoad",Data)
}

public client_disconnect(id)
	if(g_Class[id])
		ARP_ClassSave(g_Class[id],1)

public PositionLoad(Class:class_id,const class[],data[])
{
	ARP_ClassSaveHook(class_id,"EventSavingClass",data)
	
	new Player = str_to_num(data)

	g_Class[Player] = class_id
	
	static Location[128],Left[33],Middle[33],Right[33],Float:Origin[3]
	ARP_ClassGetString(class_id,"location",Location,127)
	
	parse(Location,Left,32,Middle,32,Right,32)
	
	Origin[0] = str_to_float(Left)
	Origin[1] = str_to_float(Middle)
	// account for epsilon offset
	Origin[2] = str_to_float(Right) + 0.01
	
	new TR
	engfunc(EngFunc_TraceHull,Origin,Origin,0,HULL_HUMAN,0,TR)
	if(!get_tr2(TR,TR_StartSolid) && !get_tr2(TR,TR_AllSolid) && get_tr2(TR,TR_InOpen))
		g_Origin[Player] = Origin
}
	
public EventSavingClass(Class:ClassId,Name[],Data[])
{
	new Float:Origin[3],Float:Start[3],Float:End[3],id = str_to_num(Data)
	if(is_user_alive(id))
	{
		pev(id,pev_origin,Start)
		
		End = Start
		End[2] = -4096.0
		
		engfunc(EngFunc_TraceLine,Start,End,0,id,0)
		get_tr2(0,TR_vecEndPos,Origin)
		
		Origin[2] += 36.1
	}
	
	static Tmp[128]
	format(Tmp,127,"%f %f %f",Origin[0],Origin[1],Origin[2])
	
	ARP_ClassSetString(g_Class[id],"location",Tmp)
}
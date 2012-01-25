#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <fakemeta>
#include <engine>

#define MAX_PROFILES 20
#define MAX_STEPS 30

#define CUFFED (1<<0)
#define KILLED (1<<1)
#define LEAVE (1<<2)
#define CASH (1<<3)

//#define GLOW (1<<0)
//#define LIGHTS (1<<1)
//#define SIREN (1<<2)

#define SOUND_VOL VOL_NORM
#define SOUND_ATTN ATTN_NORM
#define SOUND_PITCH PITCH_NORM
#define SOUND_FLAGS 0

enum _:ROBPROFILE
{
	CASHSECOND = 0,
	CASHMAX,
	STOPON,
	NAME,
	COOLDOWN,
	ARRESTED_END,
	KILLED_END,
	LEAVE_END,
	DONE_END,
	START,
	RADIUS,
	ORIGIN,
	FLAGS,
	MINPLAYERS,
	MINCOPS
}

enum _:STEP_TYPE
{
	WAIT = 0,
	USE,
	EFFECTS,
	MESSAGEONE,
	MESSAGEALL,
	END,
	LOCK,
	UNLOCK,
	GLOW,
	LIGHTS,
	SOUND
}

new g_RobPattern[MAX_PROFILES][MAX_STEPS][33]
new g_RobSteps[MAX_PROFILES]
new g_RobProfile[MAX_PROFILES][ROBPROFILE][64]
new g_RobProfiles

new g_RobCurProfile
new g_RobCurStep
new g_RobCurPlayer
new g_RobLastTime
new g_RobTimeElapsed
new g_RobEnd
new g_RobEffects

//new g_AlarmNotPrecached

new g_File[] = "rob.ini"

//new g_Alarm[] = "arp/alarm.wav"
new g_Alarm[MAX_PROFILES][64]	//Keep this parallel with g_RobSteps
new g_AlarmsCtr

public plugin_init()	
	register_event("DeathMsg","EventDeathMsg","a")

public ARP_Error(const Reason[])
	pause("d")

public plugin_precache()
{
	new properPath[70]
	for (new ctr = 0; ctr < g_AlarmsCtr; ctr++)
	{
		formatex(properPath,69,"%s",g_Alarm[ctr])
		file_exists(properPath) ? precache_sound(g_Alarm[ctr]) : log_amx("ARP Rob Mod - '%s' was not found.",properPath)
	}

}
//	file_exists(g_Alarm) ? precache_sound(g_Alarm) : ARP_ThrowError(AMX_ERR_NATIVE,0,"%s not precached; alarm %d disabled.",g_Alarm,/*g_AlarmNotPrecached = */1)

public EventDeathMsg()
{
	new id = read_data(2)
	
	if(g_RobCurProfile && id == g_RobCurPlayer && g_RobProfile[g_RobCurProfile][STOPON][0] & KILLED)
	{		
		new Data[2]
		Data[0] = id
		Data[1] = KILLED
		
		if(ARP_CallEvent("Rob_End",Data,2))
			return
		
		new Name[33],Authid[36]
		get_user_name(id,Name,32)
		get_user_authid(id,Authid,35)
		
		ARP_Log("Rob: ^"%s<%d><%s><>^" dies while robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
		
		new Message[128]
		copy(Message,127,g_RobProfile[g_RobCurProfile][KILLED_END])
		
		replace_all(Message,127,"#name#",Name)
		
		RobEnd()
		
		client_print(0,print_chat,"[ARP] %s",Message)
		
		g_RobCurProfile = 0
	}
}

public client_disconnect(id)
	if(g_RobCurProfile && id == g_RobCurPlayer && g_RobProfile[g_RobCurProfile][STOPON][0] & LEAVE)
	{
		new Data[2]
		Data[0] = id
		Data[1] = LEAVE
		
		if(ARP_CallEvent("Rob_End",Data,2))
			return
		
		new Name[33],Authid[36]
		get_user_name(id,Name,32)
		get_user_authid(id,Authid,35)
		
		ARP_Log("Rob: ^"%s<%d><%s><>^" disconnects while robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
		
		new Message[128]
		copy(Message,127,g_RobProfile[g_RobCurProfile][LEAVE_END])
		
		replace_all(Message,127,"#name#",Name)
		
		client_print(0,print_chat,"[ARP] %s",Message)
		
		RobEnd()
		
		g_RobCurProfile = 0
	}

public ARP_Init()
{
	ARP_RegisterPlugin("Rob Mod",ARP_VERSION,"The Apollo RP Team","Provides robbing functionality")
	
	new File = ARP_FileOpen(g_File,"rt+")
	if(!File)
		return
	
	new Buffer[128],Left[64],Right[64]
	while(!feof(File))
	{
		fgets(File,Buffer,127)
		
		if(Buffer[0] == ';' || !Buffer[0])
			continue
		
		if(containi(Buffer,"[") != -1 && containi(Buffer,"]") != -1)
		{
			g_RobProfiles++
			replace(Buffer,127,"[","")
			replace(Buffer,127,"]","")
			
			trim(Buffer)
			
			copy(g_RobProfile[g_RobProfiles][NAME],63,Buffer)
		}
		else if(containi(Buffer,"cashsecond") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][CASHSECOND][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"cashmax") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][CASHMAX][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"stopon") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][STOPON][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"cooldown") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][COOLDOWN][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"radius") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][RADIUS][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"origin") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			
			new XS[10],YS[10],ZS[10]
			parse(Right,XS,9,YS,9,ZS,9)
			
			g_RobProfile[g_RobProfiles][ORIGIN][0] = str_to_num(XS)			
			g_RobProfile[g_RobProfiles][ORIGIN][1] = str_to_num(YS)	
			g_RobProfile[g_RobProfiles][ORIGIN][2] = str_to_num(ZS)	
		}
		else if(containi(Buffer,"cuffedend") != -1)
		{
			parse(Buffer,Left,63,g_RobProfile[g_RobProfiles][ARRESTED_END],63)
			remove_quotes(g_RobProfile[g_RobProfiles][ARRESTED_END])
		}
		else if(containi(Buffer,"killedend") != -1)
		{
			parse(Buffer,Left,63,g_RobProfile[g_RobProfiles][KILLED_END],63)
			remove_quotes(g_RobProfile[g_RobProfiles][KILLED_END])
		}
		else if(containi(Buffer,"leaveend") != -1)
		{
			parse(Buffer,Left,63,g_RobProfile[g_RobProfiles][LEAVE_END],63)
			remove_quotes(g_RobProfile[g_RobProfiles][LEAVE_END])
		}
		else if(containi(Buffer,"doneend") != -1)
		{
			parse(Buffer,Left,63,g_RobProfile[g_RobProfiles][DONE_END],63)
			remove_quotes(g_RobProfile[g_RobProfiles][DONE_END])
		}
		else if(containi(Buffer,"start") != -1)
		{
			parse(Buffer,Left,63,g_RobProfile[g_RobProfiles][START],63)
			remove_quotes(g_RobProfile[g_RobProfiles][START])
		}
		else if(containi(Buffer,"flags") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][FLAGS][0] = ARP_AccessToInt(Right)
		}
		else if(containi(Buffer,"minplayers") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][MINPLAYERS][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"mincops") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobProfile[g_RobProfiles][MINCOPS][0] = str_to_num(Right)
		}
		else if(containi(Buffer,"!wait") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<WAIT)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1] = str_to_num(Right)
		}
		else if(containi(Buffer,"!use") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<USE)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		else if(containi(Buffer,"!messageone") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<MESSAGEONE)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		else if(containi(Buffer,"!messageall") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<MESSAGEALL)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
	/*	else if(containi(Buffer,"!effects") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			if(containi(Right,"glow") != -1)
				g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][1] |= (1<<GLOW)
			if(containi(Right,"lights") != -1)
				g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][1] |= (1<<LIGHTS)
			if(containi(Right,"siren") != -1)
				g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][1] |= (1<<SIREN)
			
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][0] |= (1<<EFFECTS)
		}
	*/
		else if(containi(Buffer,"!glow") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<GLOW)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		else if(containi(Buffer,"!lights") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<LIGHTS)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		else if(containi(Buffer,"!sound") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<SOUND)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
			
			parse(Buffer,Left,63,Right,63)
			
			new soundPath[64], alreadyExists
			
			parse(Right,soundPath,63,Left,63)	//Too early to use the volume for anything.

			for (new ctr = 0; ctr < g_AlarmsCtr; ctr++)
			{
				if (equali(soundPath, g_Alarm[ctr]))	//Though Linux may be csae sensitive, downloads will occur on Windows.
				{
					alreadyExists = 1
					break
				}
			}
			if (!alreadyExists)
				formatex(g_Alarm[g_AlarmsCtr++], 63, soundPath)
			//g_Alarm[g_RobSteps[g_RobProfiles]]
		}
		else if(containi(Buffer,"!end") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][0] = (1<<END)
		}
		else if(containi(Buffer,"!lock") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<LOCK)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		else if(containi(Buffer,"!unlock") != -1)
		{
			parse(Buffer,Left,63,Right,63)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]][0] = (1<<UNLOCK)
			remove_quotes(Right)
			copy(g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles]++][1],62,Right)
		}
		if(containi(Buffer,"@!") != -1)
			g_RobPattern[g_RobProfiles][g_RobSteps[g_RobProfiles] - 1][0] |= (1<<STEP_TYPE)
	}
	
	fclose(File)
}

public ARP_Event(Name[],Data[],Len)
{	
	if((equali(Name,"Player_Cuffed") || equali(Name,"Player_Jailed")) && g_RobCurProfile && g_RobProfile[g_RobCurProfile][STOPON][0] & CUFFED && g_RobCurPlayer == Data[0])
	{
		new id = Data[0]
		Data[2] = CUFFED
		
		if(ARP_CallEvent("Rob_End",Data,2))
			return
		
		new Name[33],Authid[36]
		get_user_name(id,Name,32)
		get_user_authid(id,Authid,35)
		
		ARP_Log("Rob: ^"%s<%d><%s><>^" is arrested while robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
		
		new Message[128]
		copy(Message,127,g_RobProfile[g_RobCurProfile][ARRESTED_END])
		
		replace_all(Message,127,"#name#",Name)
		
		RobEnd()
		
		client_print(0,print_chat,"[ARP] %s",Message)
		
		g_RobCurProfile = 0
		
		return
	}
	
	if(!equali(Name,"Rob_Begin"))
		return
	
	new id = Data[0]
	
	if(g_RobCurProfile)
	{
		new Name[33]
		get_user_name(g_RobCurPlayer,Name,32)
		client_print(id,print_chat,"[ARP] %s is already robbing.",Name)
		
		return
	}
	
	for(new Count;Count <= g_RobProfiles;Count++)
		if(equali(Data[1],g_RobProfile[Count][NAME]))
		g_RobCurProfile = Count
	
	if(!g_RobCurProfile)
		return
	
	if(floatround(get_gametime()) - g_RobLastTime < g_RobProfile[g_RobCurProfile][COOLDOWN][0] && g_RobLastTime)
	{
		g_RobCurProfile = 0
		client_print(id,print_chat,"[ARP] This place has been robbed recently; please wait.")
		
		return
	}
	
	if(g_RobProfile[g_RobCurProfile][FLAGS][0] & ARP_GetUserAccess(Data[0]))
	{
		g_RobCurProfile = 0
		client_print(Data[0],print_chat,"[ARP] You are not allowed to rob this place.")
		
		return
	}
	
	if(get_playersnum() < g_RobProfile[g_RobCurProfile][MINPLAYERS][0])
	{
		g_RobCurProfile = 0
		client_print(Data[0],print_chat,"[ARP] There are not enough players in the server to rob this place.")
		
		return
	}
	
	if(ARP_CopNum() < g_RobProfile[g_RobCurProfile][MINCOPS][0])
	{
		g_RobCurProfile = 0
		client_print(Data[0],print_chat,"[ARP] There are not enough cops in the server to rob this place.")
		
		return
	}
	
	new Name[33],Authid[36]
	get_user_name(id,Name,32)
	get_user_authid(id,Authid,35)
	
	ARP_Log("Rob: ^"%s<%d><%s><>^" begins robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
	
	new Message[128]
	copy(Message,127,g_RobProfile[g_RobCurProfile][START])
	
	replace_all(Message,127,"#name#",Name)
	
	client_print(0,print_chat,"[ARP] %s",Message)
	
	g_RobCurStep = 0
	g_RobTimeElapsed = 0
	g_RobEnd = 0
	
	g_RobCurPlayer = Data[0]
	
	set_task(1.0,"GiveMoney",Data[0])
	
	ExecuteStep()
}

public GiveMoney(id)
{
	if(!g_RobCurProfile)
		return
	
	if(++g_RobTimeElapsed * g_RobProfile[g_RobCurProfile][CASHSECOND][0] > g_RobProfile[g_RobCurProfile][CASHMAX][0] && g_RobProfile[g_RobCurProfile][STOPON][0] & CASH)
	{
		new Data[2]
		Data[0] = id
		Data[1] = CASH
		
		if(ARP_CallEvent("Rob_End",Data,2))
			return
		
		new Name[33],Authid[36]
		get_user_name(id,Name,32)
		get_user_authid(id,Authid,35)
		
		ARP_Log("Rob: ^"%s<%d><%s><>^" finishes robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
		
		new Message[128]
		copy(Message,127,g_RobProfile[g_RobCurProfile][DONE_END])
		
		replace_all(Message,127,"#name#",Name)
		
		RobEnd()
		
		client_print(0,print_chat,"[ARP] %s",Message)
		
		g_RobCurProfile = 0
		
		return
	}
	
	if(is_user_connected(id))
	{
		ARP_SetUserWallet(id,ARP_GetUserWallet(id) + g_RobProfile[g_RobCurProfile][CASHSECOND][0])
		
		new Float:Origin[3],Float:pOrigin[3]
		Origin[0] = float(g_RobProfile[g_RobCurProfile][ORIGIN][0])
		Origin[1] = float(g_RobProfile[g_RobCurProfile][ORIGIN][1])
		Origin[2] = float(g_RobProfile[g_RobCurProfile][ORIGIN][2])
		
		pev(id,pev_origin,pOrigin)
		
		if(vector_distance(Origin,pOrigin) > float(g_RobProfile[g_RobCurProfile][RADIUS][0]) && g_RobProfile[g_RobCurProfile][STOPON][0] & LEAVE)
		{
			new Data[2]
			Data[0] = id
			Data[1] = LEAVE
			
			if(ARP_CallEvent("Rob_End",Data,2))
				return
			
			new Name[33],Authid[36]
			get_user_name(id,Name,32)
			get_user_authid(id,Authid,35)
			
			ARP_Log("Rob: ^"%s<%d><%s><>^" leaves while robbing the %s",Name,get_user_userid(id),Authid,g_RobProfile[g_RobCurProfile][NAME])
			
			new Message[128]
			copy(Message,127,g_RobProfile[g_RobCurProfile][LEAVE_END])
			
			replace_all(Message,127,"#name#",Name)
			
			RobEnd()
			
			client_print(0,print_chat,"[ARP] %s",Message)
			
			g_RobCurProfile = 0
			
			return
		}
	}
	
	set_task(1.0,"GiveMoney",id)
}

public ExecuteStep()
{
	if(!g_RobCurProfile || g_RobCurStep >= g_RobSteps[g_RobCurProfile])
		return
	
	new Repeat,Step = g_RobPattern[g_RobCurProfile][g_RobCurStep][0]
	
	if(!(Step & (1<<STEP_TYPE)) || g_RobEnd)
	{
		if(Step & (1<<WAIT))
		{
			set_task(float(g_RobPattern[g_RobCurProfile][g_RobCurStep][1]),"ExecuteStep")
			Repeat = 1
		}
		if(Step & (1<<USE))
		{
			new Ent = str_to_num(g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
			if(!Ent || floatround(floatlog(float(Ent)) + 0.5) < strlen(g_RobPattern[g_RobCurProfile][g_RobCurStep][1]))
			{
				Ent = 0
				while((Ent = find_ent_by_tname(Ent,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])) != 0)
					UseEnt(Ent)
			}
			else
				UseEnt(Ent)
		}
		//	if(Step & (1<<EFFECTS))
		//	{
		
		//	}
		if(Step & (1<<GLOW))
		{			
			new RS[10],GS[10],BS[10]
			parse(g_RobPattern[g_RobCurProfile][g_RobCurStep][1],RS,9,GS,9,BS,9)
			
			new R = str_to_num(RS), G = str_to_num(GS), B = str_to_num(BS)

			set_rendering(g_RobCurPlayer, R != 255 || G != 255 || B != 255 ? kRenderFxGlowShell : kRenderFxNone, R, G, B)
		}
		if(Step & (1<<LIGHTS))	//!lights "R G B Health Decay LightRadius"
		{
			new lightProperties[6][10]	//A single variable may not be bad if automatic looping is added.
			//new RS[10],GS[10],BS[10], health[10], decay[10], lightRadius[10]
			parse(g_RobPattern[g_RobCurProfile][g_RobCurStep][1],lightProperties[0],9,lightProperties[1],9,lightProperties[2],9,lightProperties[3],9,lightProperties[4],9,lightProperties[5],9)
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
			write_byte(TE_DLIGHT); // TE_DLIGHT
			write_coord(g_RobProfile[g_RobCurProfile][ORIGIN][0])	// x
			write_coord(g_RobProfile[g_RobCurProfile][ORIGIN][1])	// y
			write_coord(g_RobProfile[g_RobCurProfile][ORIGIN][2])	// z
			write_byte(str_to_num(lightProperties[5]))		// radius
			write_byte(str_to_num(lightProperties[0]))		// r
			write_byte(str_to_num(lightProperties[1]))		// g
			write_byte(str_to_num(lightProperties[2]))		// b
			write_byte(str_to_num(lightProperties[3]))		// life
			write_byte(str_to_num(lightProperties[4]))		// decay rate
			message_end();

		}
		if(Step & (1<<SOUND))	//!sound "arp/hologuard/greeting.wav Float:Volume"
		{
			new soundPath[64]
			copy(soundPath,63,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])

			new entity = create_entity("info_target")
			engfunc(EngFunc_EmitSound, entity, CHAN_AUTO, soundPath, SOUND_VOL, SOUND_ATTN, SOUND_FLAGS, SOUND_PITCH)
			//log_amx("Played sound %s with volume %f.", soundPath, str_to_float(volume))
			//log_amx("Original string: ^"%s^".", g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
			remove_entity(entity)
		}
		
		if(Step & (1<<MESSAGEONE))
			if(is_user_connected(g_RobCurPlayer))
				client_print(g_RobCurPlayer,print_chat,"%s",g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
		if(Step & (1<<MESSAGEALL))
			client_print(0,print_chat,"%s",g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
		if(Step & (1<<END))
		{
			new Data[2]
			Data[0] = g_RobCurPlayer
			Data[1] = CASH
			
			if(ARP_CallEvent("Rob_End",Data,2))
				return
			
			new Name[33],Authid[36]
			get_user_name(Data[0],Name,32)
			get_user_authid(Data[0],Authid,35)
			
			ARP_Log("Rob: ^"%s<%d><%s><>^" finishes robbing the %s",Name,get_user_userid(Data[0]),Authid,g_RobProfile[g_RobCurProfile][NAME])
			
			new Message[128]
			copy(Message,127,g_RobProfile[g_RobCurProfile][DONE_END])
			
			replace_all(Message,127,"#name#",Name)
			
			RobEnd()
			
			client_print(0,print_chat,"[ARP] %s",Message)
			
			g_RobCurProfile = 0
			
			return
		}
		if(Step & (1<<LOCK))
		{
			new propertyID
			//Implement t| and e| tags; if neither are present assume internal name.
			if (g_RobPattern[g_RobCurProfile][g_RobCurStep][2] == '|')
			{	    //g_RobPattern[g_RobCurProfile][g_RobCurStep][1]
				if (g_RobPattern[g_RobCurProfile][g_RobCurStep][1] == 'e')	//Ent ID
				{
					new temp[16]
					copy(temp,15,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
					replace(temp,15,"e|","")
					propertyID = ARP_PropertyMatch(_,str_to_num(temp))
				}
				else								//Let's assume this is a target name (t|)
				{
					new temp[16]
					copy(temp,15,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
					replace(temp,15,"t|","")
				}
			}
			else									//Internal name
				propertyID = ARP_PropertyMatch(_,_,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
			
			ARP_PropertySetLocked(propertyID, 1)
		}
		
		if(Step & (1<<UNLOCK))
		{
			new propertyID
			//Implement t| and e| tags; if neither are present assume internal name.
			if (g_RobPattern[g_RobCurProfile][g_RobCurStep][2] == '|')
			{	    //g_RobPattern[g_RobCurProfile][g_RobCurStep][1]
				new temp[16]
				copy(temp,15,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
			
				if(g_RobPattern[g_RobCurProfile][g_RobCurStep][1] == 'e')	//Ent ID
				{
					replace(temp,15,"e|","")
					propertyID = ARP_PropertyMatch(_,str_to_num(temp))
				}
				else if(g_RobPattern[g_RobCurProfile][g_RobCurStep][1] == 't') //Let's assume this is a target name (t|)
				{
					replace(temp,15,"t|","")
					propertyID = ARP_PropertyMatch(temp)
				}
			}
			else									//Internal name
				propertyID = ARP_PropertyMatch(_,_,g_RobPattern[g_RobCurProfile][g_RobCurStep][1])
			
			ARP_PropertySetLocked(propertyID, 0)
		}
	}
	
	g_RobCurStep++
	
	if(!Repeat && !g_RobEnd)
		ExecuteStep()
}

UseEnt(Ent)
{
	new Players[32],Playersnum
	get_players(Players,Playersnum)

	new id = Players[0]

	force_use(id,Ent)
	fake_touch(Ent,id)
}

RobEnd()
{
	g_RobEnd = 1
	g_RobLastTime = floatround(get_gametime())
	if(g_RobEffects & GLOW)
		set_rendering(g_RobCurPlayer)

	g_RobEffects = 0

	for(new Count;Count < g_RobSteps[g_RobCurProfile];Count++)
		if(g_RobPattern[g_RobCurProfile][Count][0] & (1<<STEP_TYPE))
		{
			g_RobCurStep = Count
			ExecuteStep()
		}
}
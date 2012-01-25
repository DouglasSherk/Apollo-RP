#include <amxmodx>
#include <amxmisc>
#include <ApolloRP>
#include <ApolloRP_Chat>

new g_JobIds[512]
new g_JobNum

new g_MenuPage[33]

//new g_MainMenu[] = "ARP_JobFairMenu"
new g_ListMenu[] = "ARP_JobFairList"
new g_AcceptMenu[] = "ARP_AcceptMenu"

new g_Menu[512]

new g_JobPending[33]

public plugin_init()
{	
	ARP_RegisterChat("/jobs","CmdHelp","- shows the job menu")
	
	//register_menucmd(register_menuid(g_MainMenu),1023,"MainMenuHandle")
	register_menucmd(register_menuid(g_ListMenu),1023,"ListMenuHandle")
	register_menucmd(register_menuid(g_AcceptMenu),1023,"AcceptMenuHandle")
	
	ARP_RegisterEvent("Menu_Display","EventMenuDisplay")
}

public ARP_Init()
{
	ARP_RegisterPlugin("Job Fair","1.0","Hawk552","Gives players access to low-pay jobs")
	set_task(5.0,"GetJobs")
}

public EventMenuDisplay(Name[],Data[],Len)
{
	new id = Data[0],Jobs[1]
	if(ARP_FindJobId("Unemployed",Jobs,1) && ARP_GetUserJobId(id) == Jobs[0])
		ARP_AddMenuItem(id,"Job Listing","CmdHelp")
}

public ARP_Error(const Reason[])
	pause("d")

public CmdHelp(id,Menu,Args[])
{
	//copy(g_Menu,511,"ARP Help^n^n1. Job Listing^n2. Help Commands^n3. Items List^n^n0. Exit")
	//show_menu(id,MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_0,g_Menu,-1,g_MainMenu)
	MainMenuHandle(id,0)
	
	return PLUGIN_HANDLED
}

public MainMenuHandle(id,Key)
	switch(Key)
	{
		case 0 :
		{
			new Pos,Num,JobName[33],Keys = (1<<7|1<<8|1<<9)
			Pos += format(g_Menu,511,"ARP Job Listing^n^n")
			for(new Count = g_MenuPage[id] * 7;Count < g_MenuPage[id] * 7 + 7;Count++)
			{
				if(Count >= g_JobNum)
					break
				
				if(!ARP_ValidJobId(g_JobIds[Count]) || !g_JobIds[Count])
					continue
					
				Keys |= (1<<Num++)
				ARP_GetJobName(g_JobIds[Count],JobName,32)
				Pos += format(g_Menu[Pos],511 - Pos,"%d. %s^n",Num,JobName)
			}
			format(g_Menu[Pos],511 - Pos,"^n8. Last Page^n9. Next Page^n^n0. Exit")
			
			show_menu(id,Keys,g_Menu,-1,g_ListMenu)
		}
		/*case 1 :
		{
			client_cmd(id,"arp_help")
			client_print(id,print_chat,"[ARP] The command listing has been displayed in your console.")
		}
		case 2 :
		{
			client_cmd(id,"arp_itemlist")
			client_print(id,print_chat,"[ARP] The item list has been displayed in your console.")
		}*/
	}

public ListMenuHandle(id,Key)
{
	if(Key == 9)
		return
	
	if(Key == 8)
	{
		if(g_MenuPage[id] * 7 + 7 < g_JobNum)
			g_MenuPage[id]++
		
		MainMenuHandle(id,0)
		
		return
	}
	if(Key == 7)
	{
		if(g_MenuPage[id])
			g_MenuPage[id]--
		
		MainMenuHandle(id,0)
		
		return
	}
	
	new JobId = g_MenuPage[id] * 7 + Key,JobName[33],Access[JOB_ACCESSES + 1]
	ARP_IntToAccess(ARP_GetJobAccess(g_JobIds[JobId]),Access,JOB_ACCESSES)
	ARP_GetJobName(g_JobIds[JobId],JobName,32)
	
	g_JobPending[id] = g_JobIds[JobId]

	format(g_Menu,511,"ARP Job Listing^n^nJob Name: %s^nSalary: $%d/h^nAccess: %s^n^n1. Accept^n2. Deny",JobName,ARP_GetJobSalary(g_JobIds[JobId]),Access)
	show_menu(id,MENU_KEY_1|MENU_KEY_2,g_Menu,-1,g_AcceptMenu)
}	

public AcceptMenuHandle(id,Key)
	if(!Key)
	{
		ARP_SetUserJobId(id,g_JobPending[id])
		client_print(id,print_chat,"[ARP] You have accepted this job.")
	}
	else
		MainMenuHandle(id,0)
	
public GetJobs()
{
	new File = ARP_FileOpen("jobfair.ini","r"),Filename[128]
	if(!File)
	{
		set_fail_state("Could not find job fair file for this map.")
		return
	}
	
	while(!feof(File))
	{
		// using Filename as cache; don't let the name deceive you
		fgets(File,Filename,127)
		remove_quotes(Filename)
		trim(Filename)
		replace(Filename,127,"^n","")
		
		if(strlen(Filename) == 1)
		{
			new Num = ARP_GetJobsNum(),Access = ARP_AccessToInt(Filename)
			for(new Count;Count < Num;Count++)
				if(ARP_ValidJobId(Count) && ARP_GetJobAccess(Count) == Access)
					AddJob(Count)
		}
		else
		{
			new JobId[1]
			ARP_FindJobId(Filename,JobId,1)
			
			if(JobId[0])
				AddJob(JobId[0])
		}
	}
	
	fclose(File)
}

AddJob(JobID)
{
	for(new Count;Count < g_JobNum;Count++)
		if(g_JobIds[Count] == JobID)
			return
	
	g_JobIds[g_JobNum++] = JobID
}

#if defined _ApolloRP_Jobs_included
	#endinput
#endif

#define _ApolloRP_Jobs_included

#include <ApolloRP>

// Self explanatory: it gets the amount of jobs currently loaded in the database.
native ARP_GetJobsNum()

// This will get the name of a job id. As in, you input 2, and it
// will give you back "MCPD Officer" or whatever the server has 2 as.
// jobid - this is the id of the job you want to get the name of
// name[] - this is the array to store the job as a string into
// len - this is the max len of name
// This will return 0 if the job does not exist or it fails for some
// reason, and will return 1 if it succeeds.
native ARP_GetJobName(jobid,name[],len)

// This will give you the salary of a job id, measured in $.
// jobid - this is the id of the job you want to get the salary of
native ARP_GetJobSalary(jobid)

//
native ARP_GetJobAccess(jobid)

// Checks if the job id is valid
// jobid - id of the job to check
native ARP_ValidJobId(jobid)

// This will find a job ID based on a search string. Basically, if you're
// looking for the job "Hacker" and you input "Hack", it will give you the
// Job ID of "Hacker". If, however, there is another job called "Computer Hacker",
// it will insert all the results it gets into the results[] array to a max of
// maxresults. If it finds nothing, it will return 0 (FAILED), otherwise it will
// return the amount of results (i.e. if it finds 2, it will return 2)
native ARP_FindJobId(searchstring[],results[],maxresults)

// Adds a job to the jobs database. Returns 1 on success, 0 on failure.
// name[] - name of the job, ex. "Porn Star"
// salary - the amount of money anyone with the job gets every hour
// access - access all users get who have this job, in the form of an integer
native ARP_AddJob(name[],salary,access)

// Deletes a job and sets everyone who has the job to unemployed.
// jobid - id of the job to delete
native ARP_DeleteJob(jobid)

// Gets a user's job rights
native ARP_GetUserJobRight(id)

// Sets a user's job rights.
// NOTE: This does NOT allow them to keep their old flags - to do this,
// you should use ARP_SetUserJobRight(id,myflags|ARP_GetUserJobRight(id))
native ARP_SetUserJobRight(id,flags)

// Gets a user's job id
native ARP_GetUserJobId(id)

// Sets a user's job id
native ARP_SetUserJobId(id,jobid)

stock ARP_FindJob(searchstring[])
{
	new Results[1]
	ARP_FindJobId(searchstring,Results,1)
	
	return ARP_ValidJobId(Results[0]) ? Results[0] : FAILED
}

// Checks if a player is a cop
stock ARP_IsCop(id)
{
	new UserAccess = ARP_GetUserAccess(id),Temp[JOB_ACCESSES + 1]
	get_cvar_string(g_PoliceAccessCvar,Temp,JOB_ACCESSES)
	
	new JobAccess = ARP_AccessToInt(Temp)
	
	if(UserAccess & JobAccess)
		return SUCCEEDED
		
	return FAILED
}

// Checks if a player is medical (i.e. doctor)
stock ARP_IsMed(id)
{
	new UserAccess = ARP_GetUserAccess(id),Temp[JOB_ACCESSES + 1]
	get_cvar_string(g_MedicalAccessCvar,Temp,JOB_ACCESSES)
	
	new JobAccess = ARP_AccessToInt(Temp)
	
	if(UserAccess & JobAccess)
		return SUCCEEDED
		
	return FAILED
}

// Checks if a player is an ARP admin
stock ARP_IsAdmin(id)
{
	new UserAccess = ARP_GetUserAccess(id),Temp[JOB_ACCESSES + 1]
	get_cvar_string(g_AdminAccessCvar,Temp,JOB_ACCESSES)
	
	new JobAccess = ARP_AccessToInt(Temp)
	
	if(UserAccess & JobAccess)
		return SUCCEEDED
		
	return FAILED
}

// Checks if a player is a job admin
stock ARP_IsJobAdmin(id)
{
	new UserAccess = ARP_GetUserJobRight(id),Temp[JOB_ACCESSES + 1]
	get_cvar_string(g_AdminAccessCvar,Temp,JOB_ACCESSES)
	
	new JobAccess = ARP_AccessToInt(Temp)
	
	if(UserAccess & JobAccess)
		return SUCCEEDED
		
	return FAILED
}

stock ARP_CopNum()
{
	new Players[32],Playersnum,Num
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
		if(ARP_IsCop(Players[Count]))
			Num++
	
	return Num
}

stock ARP_MedNum()
{
	new Players[32],Playersnum,Num
	get_players(Players,Playersnum)
	
	for(new Count;Count < Playersnum;Count++)
		if(ARP_IsMed(Players[Count]))
			Num++
	
	return Num
}

// Checks if a user has job rights to a job id
stock ARP_JobAccess(id,jobid)
{
	if(!ARP_ValidJobId(jobid) || !is_user_connected(id))
		return FAILED
	
	return ARP_GetUserJobRight(id) & ARP_GetJobAccess(jobid)
}

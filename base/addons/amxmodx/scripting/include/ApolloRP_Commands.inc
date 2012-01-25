#if defined _ApolloRP_Commands_included
	#endinput
#endif

#define _ApolloRP_Commands_included

#include <ApolloRP>

// Adds a command to the list, aids in user interfacing
// command[] - command to register, i.e. "say /users"
// description[] - the description, i.e. "Shows user list"
native ARP_AddCommand(const command[],const description[])

// Registers a clcmd and adds it to the ARP help database.
stock ARP_RegisterCmd(command[],handler[],description[])
{
	ARP_AddCommand(command,description)
	
	register_clcmd(command,handler,_,description)
}

// cmd_access adapted to ARP access system
stock ARP_CmdAccess(id,cid,num)
{
  new StrAccess[JOB_ACCESSES + 1]
  get_cvar_string("arp_admin_access",StrAccess,JOB_ACCESSES)
	
  new Access = ARP_AccessToInt(StrAccess)
	
  new has_access = 0
  if ( id==(is_dedicated_server()?0:1) ) {
    has_access = 1
  /*} else if ( level==ADMIN_ADMIN ) {
    if ( is_user_admin(id) )
      has_access = 1*/
  } else if ( ARP_GetUserAccess(id) & Access ) {
    has_access = 1
  } else if (Access == 0) {
	has_access = 1
  }

  if ( has_access==0 ) {
    console_print(id,"%L",id,"NO_ACC_COM")
    return 0
  }
  if (read_argc() < num) {
    new hcmd[64], hinfo[256], hflag
    get_concmd(cid,hcmd,63,hflag,hinfo,255,0)
    console_print(id,"%L:  %s %s",id,"USAGE",hcmd,hinfo)
    return 0
  }
  return 1
}


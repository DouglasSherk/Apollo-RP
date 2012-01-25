#if defined _ApolloRP_SQL_included
	#endinput
#endif

#define _ApolloRP_SQL_included

#include <ApolloRP>
#include <sqlx>

native SQLMODE:ARP_SqlMode()

// Gets SQL handle
native Handle:ARP_SqlHandle()

// Gets the name of a table
native ARP_GetTable(TABLES:table,value[],len)

stock ARP_SqlEscape(string[],len)
{
	switch(ARP_SqlMode())
	{
		case MYSQL :
		{
			replace_all(string,len,"\\","\\\\")
			replace_all(string,len,"\0","\\0")
			replace_all(string,len,"\n","\\n")
			replace_all(string,len,"\r","\\r")
			replace_all(string,len,"\x1a","\Z")
			replace_all(string,len,"'","\'")
			replace_all(string,len,"^"","\^"")
		}
		case SQLITE :
			replace_all(string,len,"'","''")
	}
}

/*
 * Don't use this
 */
native ARP_CleverQueryBackend(Handle:db_tuple, const handler[], const query[], const data[]="", dataSize=0)

/**
 * Prepares and executes a query.
 * This will not interrupt gameplay in the event of a poor/lossed 
 *  connection, however, the interface is more complicated and 
 *  asynchronous.  Furthermore, a new connection/disconnection is 
 *  made for each query to simplify driver support. It will use
 *  non-threaded queries whenever possible such as when no players
 *  are in the server and when the map has ended.
 *
 * The handler should look like:
 *
 * @param failstate - One of the three TQUERY_ defines.
 * @param query - Handle to the query, do not free it.
 * @param error - An error message, if any.
 * @param errnum - An error code, if any.
 * @param data - Data array you passed in.
 * @param size - Size of the data array you passed in.
 * @param queuetime - Amount of gametime that passed while the query was resolving.
 * 
 * public QueryHandler(failstate, Handle:query, error[], errnum, data[], size, Float:queuetime)
 *
 * Note! The handle you pass in is a DB Tuple, NOT an active connection!
 * Note! The handle does not need to be freed.
 * Also note: This function is not guaranteed to be in another thread
 *  (in fact - it's not).  You're seeing data "after the fact", 
 *  and as such to execute another query you should run 
 *  ARP_CleverQuery again with new data.
 */
stock ARP_CleverQuery(Handle:db_tuple, const handler[], const query[], const data[]="", dataSize=0)
{
	if(ARP_SqlHandle() == Empty_Handle) return FAILED
	return ARP_CleverQueryBackend(db_tuple,handler,query,data,dataSize) ? SQL_ThreadQuery(db_tuple,handler,query,data,dataSize) : PLUGIN_HANDLED
}
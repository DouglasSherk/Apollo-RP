#if defined _ApolloRP_Events_included
	#endinput
#endif

#define _ApolloRP_Events_included

// Calls an interceptable forward throughout all of ARP
// const name[] - name of the forward
// data[] - data to pass
// len - length of data array
native ARP_CallEvent(const name[],data[],len)

// Registers an event
// const name[] - name of the event
// const handler[] - the function to call when the event is called
native ARP_RegisterEvent(const name[],const handler[])

#if defined _ApolloRP_HUD_included
	#endinput
#endif

#define _ApolloRP_HUD_included

#include <ApolloRP>

// Adds a line to a user's hud
// Do not use "^n" here, it will be replaced by the core anyway
// Note that this can only be used when ARP_HudDisplay is called (not after or before)
// Channel is a channel from the "HUD_NUM" enum
native ARP_AddHudItem(id,channel,refresh,const item[],{Float,Sql,Result,_}:...)

// Refreshes the HUD specified
stock ARP_RefreshHud(id,channel)
	ARP_AddHudItem(id,channel,1," ")

// Called every second, when the HUD is displayed to a user.
// HUD items can be added using ARP_AddHudItem.
forward ARP_HudDisplay(id)
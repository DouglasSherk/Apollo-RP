#if defined _ApolloRP_Const_included
	#endinput
#endif

#define _ApolloRP_Const_included

#include <ApolloRP>

// Max number of NPCs
//#define MAX_NPCS 30

// Max accesses for jobs (1 per each letter of the alphabet)
#define JOB_ACCESSES 26

// Max items in the HUD display
#define MAX_HUD_ITEMS 30

// Max keys each door can have
#define MAX_KEYS 10

// Max rob profiles
#define MAX_ROB 20

// return types
enum
{
	FAILED = 0,
	SUCCEEDED
}

enum
{
	EDEKA711 = 0,
	DINER,
	BANK
}

enum _:HUD_NUM
{
	HUD_PRIM = 0,
	HUD_SEC,
	HUD_TER,
	HUD_QUAT
}

enum Color
{
	MSG_YELLOW = 1,
	MSG_GREEN,
	MSG_TEAM_COLOR,
	MSG_GREY,
	MSG_RED,
	MSG_BLUE
}

// Currently, ARP only supports these modes
enum SQLMODE
{
	NONE = 0,
	MYSQL,
	SQLITE
}

enum Class
{
	Invalid_Class = 0
}

// This is a stub right now
enum ClassMode
{
	ClassMode_Invalid = 0,
	ClassMode_SQL,
	ClassMode_File
}

enum Speed
{
	// Free all settings that current plugin has made
	Speed_None = 0,
	// Override speed and force it to this in all cases
	Speed_Override,
	// Multiply the player's base speed (what it would be if no mods were enabled) by the passed float
	Speed_Mul
}

stock g_PoliceAccessCvar[] = "arp_police_access"
stock g_MedicalAccessCvar[] = "arp_medical_access"
stock g_AdminAccessCvar[] = "arp_admin_access"

stock g_JobLiterals[JOB_ACCESSES][] = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
// Uncomment this if you need it, but the preferred method is to use ARP_AccessToInt
//stock g_JobInts[JOB_ACCESSES] = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152}

#define ACCESS_A (1<<0)
#define ACCESS_B (1<<1)
#define ACCESS_C (1<<2)
#define ACCESS_D (1<<3)
#define ACCESS_E (1<<4)
#define ACCESS_F (1<<5)
#define ACCESS_G (1<<6)
#define ACCESS_H (1<<7)
#define ACCESS_I (1<<8)
#define ACCESS_J (1<<9)
#define ACCESS_K (1<<10)
#define ACCESS_L (1<<11)
#define ACCESS_M (1<<12)
#define ACCESS_N (1<<13)
#define ACCESS_O (1<<14)
#define ACCESS_P (1<<15)
#define ACCESS_Q (1<<16)
#define ACCESS_R (1<<17)
#define ACCESS_S (1<<18)
#define ACCESS_T (1<<19)
#define ACCESS_U (1<<20)
#define ACCESS_V (1<<21)
#define ACCESS_W (1<<22)
#define ACCESS_X (1<<23)
#define ACCESS_Y (1<<24)
#define ACCESS_Z (1<<25)

enum TABLES
{
	USERS,
	JOBS,
	PROPERTIES,
	DOORS,
	KEYS,
	ITEMS,
	DATA
}


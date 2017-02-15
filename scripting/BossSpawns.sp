#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <autoexecconfig>
#include <boss_spawns>

#define PLUGIN_NAME	"[TF2] Boss Spawns"
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_TAG "[BossSpawns]"

#define MAX_ENTITY_LIMIT 4096

Handle g_hConVars[7];
char g_sPluginTag[256];

Float g_fPositionCache[3];
Float g_fBoundMin;
Float g_fBoundMax;

char g_sBoundMin[32];
char g_sBoundMax[32];

int g_iTrackEntity = -1;
int g_iHealthBar = -1;

bool g_bIsSkeletonKingSpawning;
int g_iSkeletonKingSpawner = -1;

bool g_bInvisible[MAX_ENTITY_LIMIT + 1];
int g_bMapStarted;

char g_sSkeletonKingSounds[9][PLATFORM_MAX_PATH] =
{
	"vo/halloween_mann_brothers/sf13_blutarch_enemies10.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies11.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies12.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies13.mp3",
	"vo/halloween_mann_brothers/sf13_blutarch_enemies13.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_enemies05.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_enemies06.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_enemies07.mp3",
	"vo/halloween_mann_brothers/sf13_redmond_enemies08.mp3"
};

char g_sMerasmusSounds[13][PLATFORM_MAX_PATH] =
{
	"vo/halloween_merasmus/sf12_hide_idles_demo01.mp3",
	"vo/halloween_merasmus/sf12_magic_backfire06.mp3",
	"vo/halloween_merasmus/sf12_magic_backfire07.mp3",
	"vo/halloween_merasmus/sf12_magic_backfire23.mp3",
	"vo/halloween_merasmus/sf12_magic_backfire29.mp3",
	"vo/halloween_merasmus/sf12_magicwords11.mp3",
	"misc/halloween/merasmus_appear.mp3",
	"misc/halloween/merasmus_death.mp3",
	"misc/halloween/merasmus_disappear.mp3",
	"misc/halloween/merasmus_float.mp3",
	"misc/halloween/merasmus_hiding_explode.mp3",
	"misc/halloween/merasmus_spell.mp3",
	"misc/halloween/merasmus_stun.mp3"
};

char g_sHorsemannSounds[6][PLATFORM_MAX_PATH] =
{
	"ui/halloween_boss_summon_rumble.mp3",
	"vo/halloween_boss/knight_dying.mp3",
	"vo/halloween_boss/knight_spawn.mp3",
	"vo/halloween_boss/knight_alert.mp3",
	"weapons/halloween_boss/knight_axe_hit.mp3",
	"weapons/halloween_boss/knight_axe_miss.mp3"
};

char g_sMonoculusSounds[15][PLATFORM_MAX_PATH] =
{
	"vo/halloween_eyeball/eyeball_biglaugh01.mp3",
	"vo/halloween_eyeball/eyeball_boss_pain01.mp3",
	"vo/halloween_eyeball/eyeball_teleport01.mp3",
	"ui/halloween_boss_summon_rumble.mp3",
	"ui/halloween_boss_chosen_it.mp3",
	"ui/halloween_boss_defeated_fx.mp3",
	"ui/halloween_boss_defeated.mp3",
	"ui/halloween_boss_player_becomes_it.mp3",
	"ui/halloween_boss_summoned_fx.mp3",
	"ui/halloween_boss_summoned.mp3",
	"ui/halloween_boss_tagged_other_it.mp3",
	"ui/halloween_boss_escape.mp3",
	"ui/halloween_boss_escape_sixty.mp3",
	"ui/halloween_boss_escape_ten.mp3",
	"ui/halloween_boss_tagged_other_it.mp3"
};

/*char g_sGhostSounds[16][PLATFORM_MAX_PATH] =
{
	"vo/halloween_moan1.mp3",
	"vo/halloween_moan2.mp3",
	"vo/halloween_moan3.mp3",
	"vo/halloween_moan4.mp3",
	"vo/halloween_boo1.mp3",
	"vo/halloween_boo2.mp3",
	"vo/halloween_boo3.mp3",
	"vo/halloween_boo4.mp3",
	"vo/halloween_boo5.mp3",
	"vo/halloween_boo6.mp3",
	"vo/halloween_boo7.mp3",
	"vo/halloween_haunted1.mp3",
	"vo/halloween_haunted2.mp3",
	"vo/halloween_haunted3.mp3",
	"vo/halloween_haunted4.mp3",
	"vo/halloween_haunted5.mp3"
};*/

char g_sGhostMoanSounds[4][PLATFORM_MAX_PATH] =
{
	"vo/halloween_moan1.mp3",
	"vo/halloween_moan2.mp3",
	"vo/halloween_moan3.mp3",
	"vo/halloween_moan4.mp3"
};

char g_sGhostBooSounds[7][PLATFORM_MAX_PATH] =
{
	"vo/halloween_boo1.mp3",
	"vo/halloween_boo2.mp3",
	"vo/halloween_boo3.mp3",
	"vo/halloween_boo4.mp3",
	"vo/halloween_boo5.mp3",
	"vo/halloween_boo6.mp3",
	"vo/halloween_boo7.mp3"
};

char g_sGhostEffectSounds[5][PLATFORM_MAX_PATH] =
{
	"vo/halloween_haunted1.mp3",
	"vo/halloween_haunted2.mp3",
	"vo/halloween_haunted3.mp3",
	"vo/halloween_haunted4.mp3",
	"vo/halloween_haunted5.mp3"
};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "abrandnewday, reworked by Keith Warren (Drixevel)",
	description = "Simple plugin to allow server operators to spawn bosses.",
	version = PLUGIN_VERSION,
	url = "http://www.drixevel.com/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	CreateNative("TF2_SpawnHatman", Native_SpawnHatman);
	CreateNative("TF2_SpawnEyeboss", Native_SpawnEyeboss);
	CreateNative("TF2_SpawnMerasmus", Native_SpawnMerasmus);
	CreateNative("TF2_SpawnSkeleton", Native_SpawnSkeleton);
	CreateNative("TF2_SpawnSkeletonKing", Native_SpawnSkeletonKing);
	CreateNative("TF2_SpawnGhost", Native_SpawnGhost);

	RegPluginLibrary("boss_spawns");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("BossSpawns.phrases");

	g_hConVars[0] = CreateConVar("sm_bossspawns_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hConVars[1] = CreateConVar("sm_bossspawns_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hConVars[2] = CreateConVar("sm_bossspawns_hitboxes", "1", "Enable hitbox scaling on spawned bosses: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hConVars[3] = CreateConVar("sm_bossspawns_bounds", "0.1, 5.0", "Lower (optional) and upper bounds for resizing, separated with a comma.", FCVAR_PLUGIN);
	g_hConVars[4] = CreateConVar("sm_bossspawns_spawnsounds", "1", "Enable spawn sounds for bosses: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hConVars[5] = CreateConVar("sm_bossspawns_chattag", "{gold}[BossSpawns]", "Tag for plugin to use: (Uses color tags, max 64 characters)");
	g_hConVars[6] = CreateConVar("sm_bossspawns_verbose", "1", "Enable spawn verbose messages: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig();

	for (new i = 0; i < sizeof(g_hConVars); i++)
	{
		HookConVarChange(g_hConVars[i], HandleCvars);
	}

	RegAdminCmd("sm_hatman", Command_SpawnHatman, ADMFLAG_GENERIC, "Spawns the Horsemann - Usage: sm_hatman <scale> <glow 0/1>");
	RegAdminCmd("sm_eyeboss", Command_SpawnEyeBoss, ADMFLAG_GENERIC, "Spawns the MONOCULUS! - Usage: sm_eyeboss <scale> <glow 0/1>");
	RegAdminCmd("sm_eyeboss_red", Command_SpawnEyeBossRED, ADMFLAG_GENERIC, "Spawns the RED Spectral MONOCULUS! - Usage: sm_eyeboss_red <scale> <glow 0/1>");
	RegAdminCmd("sm_eyeboss_blue", Command_SpawnEyeBossBLU, ADMFLAG_GENERIC, "Spawns the BLU Spectral MONOCULUS! - Usage: sm_eyeboss_blue <scale> <glow 0/1>");
	RegAdminCmd("sm_merasmus", Command_SpawnMerasmus, ADMFLAG_GENERIC, "Spawns Merasmus - Usage: sm_merasmus <scale> <glow 0/1>");
	RegAdminCmd("sm_skelegreen", Command_SpawnGreenSkeleton, ADMFLAG_GENERIC, "Spawns a Green Skeleton - Usage: sm_skelegreen <scale> <glow 0/1>");
	RegAdminCmd("sm_skelered", Command_SpawnREDSkeleton, ADMFLAG_GENERIC, "Spawns a RED Skeleton - Usage: sm_skelered <scale> <glow 0/1>");
	RegAdminCmd("sm_skeleblue", Command_SpawnBLUSkeleton, ADMFLAG_GENERIC, "Spawns a BLU Skeleton - Usage: sm_skeleblue <scale> <glow 0/1>");
	RegAdminCmd("sm_skeleking", Command_SpawnSkeletonKing, ADMFLAG_GENERIC, "Spawns a Skeleton King - Usage: sm_skeleking <scale> <glow 0/1>");
	RegAdminCmd("sm_ghost", Command_SpawnGhost, ADMFLAG_GENERIC, "Spawns a Ghost - Usage: sm_ghost <scale> <glow 0/1>");

	RegAdminCmd("sm_slayhatman", Command_SlayHatman, ADMFLAG_GENERIC, "Slays all Horsemenn on the map - Usage: sm_slayhatman");
	RegAdminCmd("sm_slayeyeboss", Command_SlayEyeBoss, ADMFLAG_GENERIC, "Slays all MONOCULUS! on the map - Usage: sm_slayeyeboss");
	RegAdminCmd("sm_slayeyeboss_red", Command_SlayEyeBossRED, ADMFLAG_GENERIC, "Slays all RED Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_red");
	RegAdminCmd("sm_slayeyeboss_blue", Command_SlayEyeBossBLU, ADMFLAG_GENERIC, "Slays all BLU Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_blue");
	RegAdminCmd("sm_slaymerasmus", Command_SlayMerasmus, ADMFLAG_GENERIC, "Slays all Merasmus on the map - Usage: sm_slaymerasmus");
	RegAdminCmd("sm_slayskelegreen", Command_SlayGreenSkeleton, ADMFLAG_GENERIC, "Slays all Green Skeletons on the map - Usage: sm_slayskelegreen");
	RegAdminCmd("sm_slayskelered", Command_SlayREDSkeleton, ADMFLAG_GENERIC, "Slays all RED Skeletons on the map - Usage: sm_slayskelered");
	RegAdminCmd("sm_slayskeleblue", Command_SlayBLUSkeleton, ADMFLAG_GENERIC, "Slays all BLU Skeletons on the map - Usage: sm_slayskeleblue");
	RegAdminCmd("sm_slayskeleking", Command_SlaySkeletonKing, ADMFLAG_GENERIC, "Slays all Skeleton Kings on the map - Usage: sm_slayskeleking");
	RegAdminCmd("sm_slayghost", Command_SlayGhost, ADMFLAG_GENERIC, "Slays all Ghosts on the map - Usage: sm_slayghost");
}

public void OnConfigsExecuted()
{
	PrintToServer("%s %t", PLUGIN_TAG, "console initializing");

	ParseConVarToLimits(g_hConVars[3], g_sBoundMin, sizeof(g_sBoundMin), g_fBoundMin, g_sBoundMax, sizeof(g_sBoundMax), g_fBoundMax);
	GetConVarString(g_hConVars[5], g_sPluginTag, sizeof(g_sPluginTag));

	if (GetConVarBool(g_hConVars[1]))
	{
		PrintToServer("%s %t", PLUGIN_TAG, "console initialized");
		PrintToServer("%s %t", PLUGIN_TAG, "console hitbox status", GetConVarBool(g_hConVars[2]) ? "ON" : "OFF");
	}
}

public HandleCvars(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new iNewValue = StringToInt(newValue);

	if (cvar == g_hConVars[0])
	{
		Setg_hConVarstring(g_hConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == g_hConVars[3])
	{
		ParseConVarToLimits(g_hConVars[3], g_sBoundMin, sizeof(g_sBoundMin), g_fBoundMin, g_sBoundMax, sizeof(g_sBoundMax), g_fBoundMax);
	}
	else if (cvar == g_hConVars[5])
	{
		strcopy(g_sPluginTag, sizeof(g_sPluginTag), newValue);
	}
}

public void OnPluginEnd()
{
	new entity;

	while ((entity = FindEntityByClassname(entity, "headless_hatman")) != !IsValidEntity(entity))
	{
		Handle hEvent = CreateEvent("pumpkin_lord_killed", true);
		FireEvent(hEvent);
		AcceptEntityInput(entity, "Kill");
	}

	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != !IsValidEntity(entity))
	{
		Handle hEvent = CreateEvent("eyeball_boss_killed", true);
		FireEvent(hEvent);
		AcceptEntityInput(entity, "Kill");
	}

	while ((entity = FindEntityByClassname(entity, "merasmus")) != !IsValidEntity(entity))
	{
		Handle hEvent = CreateEvent("merasmus_killed", true);
		FireEvent(hEvent);
		AcceptEntityInput(entity, "Kill");
	}

	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != !IsValidEntity(entity)) //Kills Skeleton King as well.
	{
		AcceptEntityInput(entity, "Kill");
	}

	while ((entity = FindEntityByClassname(entity, "simple_bot")) != !IsValidEntity(entity))
	{
		char sName[32];
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));

		if (StrEqual(sName, "SpawnedGhost"))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

void ParseConVarToLimits(Handle hConVar, char[] sMinString, int iMinLength, Float& fMin, char[] sMaxString, int iMaxLength, Float& fMax)
{
	int iSplitResult;

	char szBounds[256];
	GetConVarString(hConVar, szBounds, sizeof(szBounds));

	if ((iSplitResult = SplitString(szBounds, ",", sMinString, iMinLength)) != -1 && (fMin = StringToFloat(sMinString)) >= 0.0)
	{
		TrimString(sMinString);
		strcopy(sMaxString, iMaxLength, szBounds[iSplitResult]);
	}
	else
	{
		strcopy(sMinString, iMinLength, "0.0");
		fMin = 0.0;
		strcopy(sMaxString, iMaxLength, szBounds);
	}

	TrimString(szMaxString);
	fMax = StringToFloat(szMaxString);

	int iMarkInMin = FindCharInString(sMinString, '.'), iMarkInMax = FindCharInString(sMaxString, '.');
	Format(sMinString, iMinLength, "%s%s%s", (iMarkInMin == 0 ? "0" : ""), sMinString, (iMarkInMin == -1 ? ".0" : (iMarkInMin == (strlen(sMinString) - 1) ? "0" : "")));
	Format(sMaxString, iMaxLength, "%s%s%s", (iMarkInMax == 0 ? "0" : ""), sMaxString, (iMarkInMax == -1 ? ".0" : (iMarkInMax == (strlen(sMaxString) - 1) ? "0" : "")));

	if (fMin > fMax)
	{
		Float fTemp = fMax;
		fMax = fMin;
		fMin = fTemp;
	}
}

/***************************************************/
//Spawn Commands

public Action:Command_SpawnHatman(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = 1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("headless_hatman", "", fScale, 0, 10.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{mediumorchid}Horseless Headless Horsemann");

	return Plugin_Handled;
}

public Action:Command_SpawnEyeBoss(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = 1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("eyeball_boss", "", fScale, 5, 50.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{mythical}Monoculus");

	return Plugin_Handled;
}

public Action:Command_SpawnEyeBossRED(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = 1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("eyeball_boss", "", fScale, 2, -25.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{orangered}Red Spectral Monoculus");

	return Plugin_Handled;
}

public Action:Command_SpawnEyeBossBLU(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = 1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("eyeball_boss", "", fScale, 1, -25.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{cyan}Blue Spectral Monoculus");

	return Plugin_Handled;
}

public Action:Command_SpawnMerasmus(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = 1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("merasmus", "", fScale, 0, 0.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}Merasmus!{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{limegreen}Merasmus");

	return Plugin_Handled;
}

public Action:Command_SpawnGreenSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = -1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("tf_zombie", "", fScale, 0, 0.0, "2", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {community}Green Skeleton{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{green}Green Skeleton");

	return Plugin_Handled;
}

public Action:Command_SpawnREDSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s%t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = -1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("tf_zombie", "", fScale, 2, 0.0, "0", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {red}RED Skeleton{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{red}Red Skeleton");

	return Plugin_Handled;
}

public Action:Command_SpawnBLUSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = -1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("tf_zombie", "", fScale, 3, 0.0, "1", bGlow ? true : false))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{blue}Blue Skeleton");

	return Plugin_Handled;
}

public Action:Command_SpawnSkeletonKing(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = -1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("tf_zombie_spawner", "", fScale, 0, 0.0, "0", bGlow ? true : false, true))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{unusual}Skeleton King");

	if (GetConVarBool(g_hConVars[4]))
	{
		EmitSoundToAll(g_sSkeletonKingSounds[GetRandomInt(0, 8)], client, _, _, _, 1.0);
	}

	return Plugin_Handled;
}

public Action:Command_SpawnGhost(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	if (!IsClientInGame(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "Command is in-game only");
		return Plugin_Handled;
	}

	new String:szScale[5] = "0.0";
	new String:sGlow[5] = "0";

	new Float:fScale = -1.0;
	new bool:bGlow = false;

	if (args > 0)
	{
		GetCmdArg(1, szScale, sizeof(szScale));
		TrimString(szScale);

		GetCmdArg(2, sGlow, sizeof(sGlow));
		TrimString(sGlow);

		fScale = StringToFloat(szScale);

		if (fScale <= 0.0)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size specified");
			return Plugin_Handled;
		}
		else if (fScale < g_fBoundMin || fScale > g_fBoundMax)
		{
			CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid size out of bounds", g_sBoundMin, g_sBoundMax);
			return Plugin_Handled;
		}

		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}

	if (!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s %t", g_sPluginTag, "reply invalid spawn point");
		return Plugin_Handled;
	}

	if (CheckEntityLimit(client))
	{
		return Plugin_Handled;
	}

	if (!SpawnBoss("simple_bot", "SpawnedGhost", fScale, 0, 0.0, "0", bGlow ? true : false, false, true))
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn a {unusual}Ghost{default} for some reason.", g_sPluginTag);
		return Plugin_Handled;
	}

	ProcessActivity(client, "{azure}Ghost");

	return Plugin_Handled;
}

ProcessActivity(client, const String:sBossName[])
{
	if (GetConVarBool(g_hConVars[6]))
	{
		CShowActivity2(client, g_sPluginTag, " %t", "spawned boss prefix message", sBossName);
		CReplyToCommand(client, "%s %t", g_sPluginTag, "spawned boss prefix reply", sBossName);
	}

	LogAction(client, -1, "'%L' %t", client, "spawned boss prefix message", sBossName);
}

/***************************************************/
//Spawn Function

bool:SpawnBoss(const String:sEntityClass[], const String:sEntityName[], Float:scale = -1.0, team = 0, Float:offset = 0.0, String:skin[1] = "-1", bool:glow = false, bool:SkeletonKing = false, bool:Ghost = false)
{
	new entity = CreateEntityByName(sEntityClass);

	if (IsValidEntity(entity))
	{
		if (strlen(sEntityName) != 0)
		{
			DispatchKeyValue(entity, "targetname", sEntityName);
		}

		DispatchSpawn(entity);

		if (scale != -1.0)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);

			if (GetConVarBool(g_hConVars[2]))
			{
				ResizeHitbox(entity, sEntityClass, scale);
			}

			g_fPositionCache[2] -= scale;
		}

		if (team != 0)
		{
			SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
		}

		if (offset != 0.0)
		{
			g_fPositionCache[2] -= offset;
		}

		if (!StrEqual(skin, "-1"))
		{
			DispatchKeyValue(entity, "skin", skin);
		}

		if (glow)
		{
			SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);
		}

		if (SkeletonKing)
		{
			SetEntProp(entity, Prop_Data, "m_nSkeletonType", 1);
			AcceptEntityInput(entity, "Enable");
			g_iSkeletonKingSpawner = entity;
			g_bIsSkeletonKingSpawning = true;
		}

		if (Ghost)
		{
			SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		}

		TeleportEntity(entity, g_fPositionCache, NULL_VECTOR, NULL_VECTOR);

		if (Ghost)
		{
			AttachParticle(entity, "ghost_appearation", _, 5.0);
			SetEntityModel(entity, "models/props_halloween/ghost.mdl");

			g_bInvisible[entity] = false;

			CreateTimer(GetRandomFloat(5.0, 10.0), Timer_ToggleInvis, EntIndexToEntRef(entity));

			new flags = GetEntityFlags(entity) | FL_NOTARGET;
			SetEntityFlags(entity, flags);

			SDKHook(entity, SDKHook_Touch, GhostThink);
		}

		return true;
	}

	return false;
}

/***************************************************/
//Ghost Functions (consolidating later)

public GhostThink(entity)
{
	if (!IsValidEntity(entity))
	{
		return;
	}

	if (CheckEntityLimit(0))
	{
		return;
	}

	static Float:flLastCall;
	if (GetEngineTime() - 0.1 <= flLastCall)
	{
		return;
	}

	flLastCall = GetEngineTime();

	if (IsValidEntity(entity) && !g_bInvisible[entity])
	{
		new Float:vecGhostOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecGhostOrigin);

		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}

			new Float:vecClientOrigin[3];
			GetClientAbsOrigin(i, vecClientOrigin);

			new Float:flDistance = GetVectorDistance(vecGhostOrigin, vecClientOrigin);

			if (flDistance < 0)
			{
				flDistance *= -1.0;
			}

			if (flDistance <= 240.0)
			{
				ScarePlayer(entity, i);
			}
		}
	}
}

public Action:Timer_ToggleInvis(Handle:timer, any:data)
{
	new entity = EntRefToEntIndex(data);

	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		new String:sClass[32];
		GetEntityClassname(entity, sClass, sizeof(sClass));

		if (StrEqual(sClass, "simple_bot"))
		{
			switch (g_bInvisible[entity])
			{
			case true:
				{
					SetEntityModel(entity, "models/props_halloween/ghost.mdl");
					AttachParticle(entity, "ghost_appearation", _, 5.0);
					SetEntityRenderColor(entity, _, _, _, 255);
					SetEntityRenderMode(entity, RENDER_NORMAL);
					EmitSoundToAll(g_sGhostMoanSounds[GetRandomInt(0, sizeof(g_sGhostMoanSounds)-1)], entity);
					EmitSoundToAll(g_sGhostEffectSounds[GetRandomInt(0, sizeof(g_sGhostEffectSounds)-1)], entity);
					CreateTimer(GetRandomFloat(5.0, 10.0), Timer_ToggleInvis, EntIndexToEntRef(entity));
					g_bInvisible[entity] = false;
				}
			case false:
				{
					AttachParticle(entity, "ghost_appearation", _, 5.0);
					SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(entity, _, _, _, 0);
					SetVariantString("ParticleEffectStop");
					AcceptEntityInput(entity, "DispatchEffect");
					EmitSoundToAll(g_sGhostEffectSounds[GetRandomInt(0, sizeof(g_sGhostEffectSounds)-1)], entity);
					SetEntityModel(entity, "models/humans/group01/female_01.mdl");
					CreateTimer(GetRandomFloat(60.0, 120.0), Timer_ToggleInvis, EntIndexToEntRef(entity));
					g_bInvisible[entity] = true;
				}
			}
		}
	}
}

AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[] = "", Float:flZOffset = 0.0, Float:flSelfDestruct = 0.0)
{
	if (!g_bMapStarted)
	{
		return -1;
	}

	new iParticle = CreateEntityByName("info_particle_system");

	if (!IsValidEdict(iParticle))
	{
		return 0;
	}

	new Float:flPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
	flPos[2] += flZOffset;

	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(iParticle, "targetname", "killme%dp@later");
	DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
	DispatchSpawn(iParticle);

	SetVariantString("!activator");
	AcceptEntityInput(iParticle, "SetParent", iEntity);
	ActivateEntity(iParticle);

	if (strlen(strAttachPoint))
	{
		SetVariantString(strAttachPoint);
		AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
	}

	AcceptEntityInput(iParticle, "start");

	if (flSelfDestruct > 0.0)
	{
		CreateTimer(flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle));
	}

	return iParticle;
}

public Action:Timer_DeleteParticle(Handle:timer, any:data)
{
	new iEntity = EntRefToEntIndex(data);

	if (iEntity > MaxClients)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
}

ScarePlayer(entity, client)
{
	static Float:flLastScare[MAXPLAYERS+1];
	static Float:flLastBoo;

	if (!IsValidEntity(entity) || !IsValidClient(client))
	{
		return;
	}

	if ((GetEngineTime() - 5.0) <= flLastScare[client])
	{
		return;
	}

	flLastScare[client] = GetEngineTime();

	if (GetEngineTime() - 1.0 > flLastBoo)
	{
		flLastBoo = GetEngineTime();
		EmitSoundToAll(g_sGhostBooSounds[ GetRandomInt(0, sizeof(g_sGhostBooSounds) - 1)], entity);
	}

	CreateTimer(0.5, Timer_StunPlayer, GetClientUserId(client));
}

public Action:Timer_StunPlayer(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);

	if (IsValidClient(client))
	{
		TF2_StunPlayer(client, 5.0, _, TF_STUNFLAGS_GHOSTSCARE);
	}
}

/***************************************************/
//Slay Commands

public Action:Command_SlayHatman(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "headless_hatman")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}Horseless Headless Horsemann{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(entity, "Kill");

		CShowActivity2(client, g_sPluginTag, "{default}Slayed the {unusual}Horseless Headless Horsemann");
		LogAction(client, -1, "\"%L\" slayed boss: Horseless Headless Horsemann", client);
		CReplyToCommand(client, "%s {default}You've slayed the {unusual}Horseless Headless Horsemann", g_sPluginTag);
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBoss(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}MONOCULUS!{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 5)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {unusual}MONOCULUS!");
			LogAction(client, -1, "\"%L\" slayed boss: MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {unusual}MONOCULUS!", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBossRED(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {red}RED Spectral MONOCULUS!{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 2)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {red}RED Spectral MONOCULUS!");
			LogAction(client, -1, "\"%L\" slayed boss: RED Spectral MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {red}RED Spectral MONOCULUS!", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBossBLU(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {blue}BLU Spectral MONOCULUS!{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 1)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");

			CShowActivity(client, g_sPluginTag, "{default}Slayed the {blue}BLU Spectral MONOCULUS!");
			LogAction(client, -1, "\"%L\" slayed boss: BLU Spectral MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {blue}BLU Spectral MONOCULUS!", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayMerasmus(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while((entity = FindEntityByClassname(entity, "merasmus")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay {unusual}Merasmus{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new Handle:g_Event = CreateEvent("merasmus_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(entity, "Kill");

		CShowActivity2(client, g_sPluginTag, "{default}Slayed {unusual}Merasmus!");
		LogAction(client, -1, "\"%L\" slayed boss: Merasmus", client);
		CReplyToCommand(client, "%s {default}You've slayed the {unusual}Merasmus", g_sPluginTag);
	}
	return Plugin_Handled;
}

public Action:Command_SlayGreenSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {community}Green Skeleton{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 3)
		{
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {community}Green Skeleton!");
			LogAction(client, -1, "\"%L\" slayed boss: Green Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {community}Green Skeleton", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayREDSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {red}RED Skeleton{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 1)
		{
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {red}RED Skeleton!");
			LogAction(client, -1, "\"%L\" slayed boss: RED Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {red}RED Skeleton", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayBLUSkeleton(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {blue}BLU Skeleton{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 2)
		{
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {blue}BLU Skeleton!");
			LogAction(client, -1, "\"%L\" slayed boss: BLU Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {blue}BLU Skeleton", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlaySkeletonKing(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}Skeleton King{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new String:sBuffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));

		if (StrEqual(sBuffer, "SkeletonKing"))
		{
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {unusual}Skeleton King!");
			LogAction(client, -1, "\"%L\" slayed boss: Skeleton King", client);
			CReplyToCommand(client, "%s {default}You've slayed the {unusual}Skeleton King", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayGhost(client, args)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		return Plugin_Handled;
	}

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "simple_bot")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}Ghost{default} for some reason.", g_sPluginTag);
			return Plugin_Handled;
		}

		new String:sBuffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));

		if (StrEqual(sBuffer, "SpawnedGhost"))
		{
			AcceptEntityInput(entity, "Kill");

			CShowActivity2(client, g_sPluginTag, "{default}Slayed the {unusual}Ghost!");
			LogAction(client, -1, "\"%L\" slayed boss: Ghost", client);
			CReplyToCommand(client, "%s {default}You've slayed the {unusual}Ghost", g_sPluginTag);
		}
	}
	return Plugin_Handled;
}

/***************************************************/

SetTeleportEndPoint(client)
{
	new Float:vAngles[3];
	new Float:vOrigin[3];
	new Float:vBuffer[3];
	new Float:vStart[3];
	new Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_fPositionCache[0] = vStart[0] + (vBuffer[0]*Distance);
		g_fPositionCache[1] = vStart[1] + (vBuffer[1]*Distance);
		g_fPositionCache[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "monster_resource"))
	{
		g_iHealthBar = entity;
	}
	else if (g_iTrackEntity == -1 && StrEqual(classname, "headless_hatman"))
	{
		g_iTrackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
	}
	else if (g_iTrackEntity == -1 && StrEqual(classname, "eyeball_boss"))
	{
		g_iTrackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
	}
	else if (g_iTrackEntity == -1 && StrEqual(classname, "merasmus"))
	{
		g_iTrackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
	}
	else if (g_iTrackEntity == -1 && StrEqual(classname, "tf_zombie_spawner"))
	{
		g_iTrackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
	}

	if (StrEqual(classname, "tf_zombie") && g_bIsSkeletonKingSpawning)
	{
		DispatchKeyValue(entity, "targetname", "SkeletonKing");

		if (IsValidEntity(g_iSkeletonKingSpawner))
		{
			AcceptEntityInput(g_iSkeletonKingSpawner, "kill");
			g_iSkeletonKingSpawner = -1;
		}

		g_bIsSkeletonKingSpawning = false;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == -1) return;
	else if (entity == g_iTrackEntity)
	{
		g_iTrackEntity = FindEntityByClassname(-1, "headless_hatman");
		if (g_iTrackEntity == entity)
		{
			g_iTrackEntity = FindEntityByClassname(entity, "headless_hatman");
		}
		if (g_iTrackEntity > -1)
		{
			SDKHook(g_iTrackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
		UpdateBossHealth(g_iTrackEntity);
	}
	else if (entity == g_iTrackEntity)
	{
		g_iTrackEntity = FindEntityByClassname(-1, "eyeball_boss");
		if (g_iTrackEntity == entity)
		{
			g_iTrackEntity = FindEntityByClassname(entity, "eyeball_boss");
		}
		if (g_iTrackEntity > -1)
		{
			SDKHook(g_iTrackEntity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
		}
		UpdateBossHealth(g_iTrackEntity);
	}
	else if (entity == g_iTrackEntity)
	{
		g_iTrackEntity = FindEntityByClassname(-1, "merasmus");
		if (g_iTrackEntity == entity)
		{
			g_iTrackEntity = FindEntityByClassname(entity, "merasmus");
		}
		if (g_iTrackEntity > -1)
		{
			SDKHook(g_iTrackEntity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
		}
		UpdateBossHealth(g_iTrackEntity);
	}
	else if (entity == g_iTrackEntity)
	{
		g_iTrackEntity = FindEntityByClassname(-1, "tf_zombie_spawner");
		if (g_iTrackEntity == entity)
		{
			g_iTrackEntity = FindEntityByClassname(entity, "tf_zombie_spawner");
		}
		if (g_iTrackEntity > -1)
		{
			SDKHook(g_iTrackEntity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
		}
		UpdateBossHealth(g_iTrackEntity);
	}
}

public OnHorsemannDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public OnMonoculusDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public OnMerasmusDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public OnSkeletonKingDamaged(victim, attacker, inflictor, Float:damage, damagetype)
{
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public UpdateDeathEvent(entity)
{
	if (IsValidEntity(entity))
	{
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if (HP <= (maxHP * 0.75))
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
			if (HP <= -1)
			{
				SetEntProp(entity, Prop_Data, "m_takedamage", 0);
			}
		}
	}
}

public UpdateBossHealth(entity)
{
	if (g_iHealthBar == -1) return;
	new percentage;
	if (IsValidEntity(entity))
	{
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if (HP <= 0)
		{
			percentage = 0;
		}
		else
		{
			percentage = RoundToCeil(float(HP) / (maxHP / 4) * 255);
		}
	}
	else
	{
		percentage = 0;
	}
	SetEntProp(g_iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", percentage);
}

/***************************************************/
//Natives

public Native_SpawnHatman(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new Float:scale = Float:GetNativeCell(5);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(7);

	if (SpawnBoss("headless_hatman", "", scale, 0, 10.0, "0", bGlow))
	{
		if (bSpew)
		{
			CShowActivity2(client, g_sPluginTag, "{default}Spawned the {unusual}Horseless Headless Horsemann via natives!");
			LogAction(client, -1, "\"%L\" spawned boss via natives: Horseless Headless Horsemann", client);
			CReplyToCommand(client, "%s {default}You've spawned the {unusual}Horseless Headless Horsemann via natives!", g_sPluginTag);
		}
	}
	else
	{
		if (bSpew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason via natives.", g_sPluginTag);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, could not spawn Hatman.");
	}
}

public Native_SpawnEyeboss(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new Float:scale = Float:GetNativeCell(5);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(7);
	new type = GetNativeCell(8);

	if (SpawnBoss("eyeball_boss", "", scale, type, 50.0, "0", bGlow))
	{
		if (bSpew)
		{
			switch (type)
			{
			case 0:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned the {unusual}MONOCULUS via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {unusual}MONOCULUS via natives!", g_sPluginTag);
				}
			case 1:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned the {red}RED Spectral MONOCULUS via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: RED Spectral MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {red}RED Spectral MONOCULUS via natives!", g_sPluginTag);
				}
			case 2:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned the {blue}BLU Spectral MONOCULUS via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Spectral MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {blue}BLU Spectral MONOCULUS via natives!", g_sPluginTag);
				}
			}
		}
	}
	else
	{
		switch (type)
		{
		case 0:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'regular', could not spawn Eyeboss 'regular'.");
			}
		case 1:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'red', could not spawn Eyeboss 'red'.");
			}
		case 2:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'blue', could not spawn Eyeboss 'blue'.");
			}
		}
	}
}

public Native_SpawnMerasmus(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new Float:scale = Float:GetNativeCell(5);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(7);

	if (SpawnBoss("merasmus", "", scale, 0, 0.0, "0", bGlow))
	{
		if (bSpew)
		{
			CShowActivity2(client, g_sPluginTag, "{default}Spawned {unusual}Merasmus via natives!");
			LogAction(client, -1, "\"%L\" spawned boss via natives: Merasmus", client);
			CReplyToCommand(client, "%s {default}You've spawned {unusual}Merasmus via natives!", g_sPluginTag);
		}
	}
	else
	{
		if (bSpew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}Merasmus!{default} for some reason via natives.", g_sPluginTag);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, could not spawn Merasmus.");
	}
}

public Native_SpawnSkeleton(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new Float:scale = Float:GetNativeCell(5);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(7);
	new type = GetNativeCell(8);

	new String:sSkin[1] = "0";
	IntToString(type, sSkin, sizeof(sSkin));

	if (SpawnBoss("tf_zombie", "", scale, type, 0.0, sSkin, bGlow))
	{
		if (bSpew)
		{
			switch (type)
			{
			case 0:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned a {community}Green Skeleton via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: Green Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {community}Green Skeleton via natives!", g_sPluginTag);
				}
			case 1:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned a {red}RED Skeleton via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: RED Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {red}RED Skeleton via natives!", g_sPluginTag);
				}
			case 2:
				{
					CShowActivity2(client, g_sPluginTag, "{default}Spawned a {blue}BLU Skeleton via natives!");
					LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {blue}BLU Skeleton via natives!", g_sPluginTag);
				}
			}
		}
	}
	else
	{
		switch (type)
		{
		case 0:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn the {community}Green Skeleton{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Green', could not spawn Eyeboss 'Green'.");
			}
		case 1:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn the {red}RED Skeleton{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Red', could not spawn Eyeboss 'Red'.");
			}
		case 2:
			{
				if (bSpew) CReplyToCommand(client, "%s {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason via natives.", g_sPluginTag);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Blue', could not spawn Eyeboss 'Blue'.");
			}
		}
	}
}

public Native_SpawnSkeletonKing(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(5);

	if (SpawnBoss("tf_zombie_spawner", "", 1.0, 0, 0.0, "-1", bGlow, true))
	{
		if (bSpew)
		{
			CShowActivity2(client, g_sPluginTag, "{default}Spawned a {unusual}Skeleton King via natives!");
			LogAction(client, -1, "\"%L\" spawned boss via natives: Skeleton King", client);
			CReplyToCommand(client, "%s {default}You've spawned {unusual}Skeleton King via natives!", g_sPluginTag);
		}
	}
	else
	{
		if (bSpew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason via natives.", g_sPluginTag);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, could not spawn Skeleton King.");
	}
}

public Native_SpawnGhost(Handle:plugin, numParams)
{
	if (!GetConVarBool(g_hConVars[1]))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}

	new client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Ghost, invalid client index.");
	}

	g_fPositionCache[0] = Float:GetNativeCell(2);
	g_fPositionCache[1] = Float:GetNativeCell(3);
	g_fPositionCache[2] = Float:GetNativeCell(4);
	new bool:bGlow = GetNativeCell(6);
	new bool:bSpew = GetNativeCell(5);

	if (SpawnBoss("simple_bot", "SpawnedGhost", 1.0, 0, 0.0, "-1", bGlow, false, true))
	{
		if (bSpew)
		{
			CShowActivity2(client, g_sPluginTag, "{default}Spawned a {unusual}Ghost via natives!");
			LogAction(client, -1, "\"%L\" spawned boss via natives: Ghost", client);
			CReplyToCommand(client, "%s {default}You've spawned {unusual}Ghost via natives!", g_sPluginTag);
		}
	}
	else
	{
		if (bSpew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Ghost{default} for some reason via natives.", g_sPluginTag);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Ghost, could not spawn Ghost.");
	}
}

/***************************************************/

bool:IsValidClient(i, bool:replay = true)
{
	if (i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if (replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}

bool:CheckEntityLimit(client)
{
	if (GetEntityCount() >= GetMaxEntities() - 32)
	{
		CReplyToCommand(client, "%s {default}Too many entities have been spawned, reload the map.", g_sPluginTag);
		return true;
	}

	return false;
}

ResizeHitbox(entity, const String:sEntityClass[], Float:fScale = 1.0)
{
	new Float:vecBossMin[3], Float:vecBossMax[3];
	if (StrEqual(sEntityClass, "headless_hatman"))
	{
		vecBossMin[0] = -25.5, vecBossMin[1] = -38.5, vecBossMin[2] = -11.0;
		vecBossMax[0] = 18.0, vecBossMax[1] = 38.0, vecBossMax[2] = 138.5;
	}
	else if (StrEqual(sEntityClass, "eyeball_boss"))
	{
		vecBossMin[0] = -50.0, vecBossMin[1] = -50.0, vecBossMin[2] = -50.0;
		vecBossMax[0] = 50.0, vecBossMax[1] = 50.0, vecBossMax[2] = 50.0;
	}
	else if (StrEqual(sEntityClass, "merasmus"))
	{
		vecBossMin[0] = -58.5, vecBossMin[1] = -49.5, vecBossMin[2] = -30.5;
		vecBossMax[0] = 92.5, vecBossMax[1] = 49.5, vecBossMax[2] = 190.5;
	}

	new Float:vecScaledBossMin[3], Float:vecScaledBossMax[3];

	vecScaledBossMin = vecBossMin;
	vecScaledBossMax = vecBossMax;

	ScaleVector(vecScaledBossMin, fScale);
	ScaleVector(vecScaledBossMax, fScale);
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecScaledBossMin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
}

public OnMapEnd()
{
	g_bMapStarted = false;
}

//Lets put this behemoth of a function at the bottom shall we... get it the hell out of the way.
public OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel("models/humans/group01/female_01.mdl", true); //Simple_bots default model
	PrecacheModel("models/props_halloween/ghost.mdl", true);	//Ghost model itself
	PrecacheModel("ghost_appearation", true);					//Ghost appear & disappear particle

	g_iHealthBar = FindEntityByClassname(-1, "monster_resource");
	if (g_iHealthBar == -1)
	{
		g_iHealthBar = CreateEntityByName("monster_resource");
		if (g_iHealthBar != -1)
		{
			DispatchSpawn(g_iHealthBar);
		}
	}

	PrecacheModel("models/bots/headless_hatman.mdl", true);
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
	PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl", true);
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl", true);
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl", true);
	PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
	PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl", true);

	new i, String:sBuffer[PLATFORM_MAX_PATH];

	for (i = 1; i <= 2; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_boss/knight_alert0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 4; i++)
	{
		new String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_attack0%d.mp3", i);
		PrecacheSound(iString, true);
	}

	for (i = 1; i <= 2; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_boss/knight_death0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 4; i++)
	{
		new String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_laugh0%d.mp3", i);
		PrecacheSound(iString, true);
	}

	for (i = 1; i <= 3; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_boss/knight_pain0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 3; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_eyeball/eyeball_laugh0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 3; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_eyeball/eyeball_mad0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 13; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_eyeball/eyeball0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_eyeball/eyeball%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 17; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_appears0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_appears%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 11; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_attacks0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_attacks%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 54; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_headbomb0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_headbomb%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 33; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_held_up0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_held_up%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 2; i <= 4; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_island0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 3; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_bcon_skullhat0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 2; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_combat_idle0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 12; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_defeated0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_defeated%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 9; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_found0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 3; i <= 6; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_grenades0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 1; i <= 26; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_headbomb_hit0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_headbomb_hit%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 19; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_hide_heal10%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_hide_heal1%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 49; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_hide_idles0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_hide_idles%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 16; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_leaving0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_leaving%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	for (i = 1; i <= 5; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_pain0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 4; i <= 8; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_ranged_attack0%d.mp3", i);
		PrecacheSound(sBuffer, true);
	}

	for (i = 2; i <= 13; i++)
	{
		if (i < 10)
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_staff_magic0%d.mp3", i);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "vo/halloween_merasmus/sf12_staff_magic%d.mp3", i);
		}

		if (FileExists(sBuffer))
		{
			PrecacheSound(sBuffer, true);
		}
	}

	PrecacheSounds(g_sHorsemannSounds, sizeof(g_sHorsemannSounds));
	PrecacheSounds(g_sMonoculusSounds, sizeof(g_sMonoculusSounds));
	PrecacheSounds(g_sMerasmusSounds, sizeof(g_sMerasmusSounds));
	PrecacheSounds(g_sSkeletonKingSounds, sizeof(g_sSkeletonKingSounds));
	//PrecacheSounds(g_sGhostSounds, sizeof(g_sSkeletonKingSounds));
	PrecacheSounds(g_sGhostMoanSounds, sizeof(g_sGhostMoanSounds));
	PrecacheSounds(g_sGhostBooSounds, sizeof(g_sGhostBooSounds));
	PrecacheSounds(g_sGhostEffectSounds, sizeof(g_sGhostEffectSounds));
}

PrecacheSounds(const String:strSounds[][], iArraySize)
{
	for (new i = 0; i < iArraySize; i++)
	{
		if (!PrecacheSound(strSounds[i]))
		{
			PrintToChatAll("Faild to precache sound: %s", strSounds[i]);
		}
	}
}

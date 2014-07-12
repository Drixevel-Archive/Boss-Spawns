#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <autoexecconfig>

#define PLUGIN_NAME	"[TF2] Boss Spawns"
#define PLUGIN_VERSION "1.0.0"

#define PLUGIN_TAG "[BossSpawns]"
#define PLUGIN_TAG_COLORED "{unusual}[BossSpawns]"

new Handle:ConVars[4] = {INVALID_HANDLE, ...};
new bool:cv_Enabled = true, cv_HitboxScale = true;

new Float:g_pos[3];

new Float:g_fBoundMin;
new Float:g_fBoundMax;

new String:g_szBoundMin[16];
new String:g_szBoundMax[16];

new g_trackEntity = -1;
new g_healthBar = -1;

new bool:gSK_IsSpawning = false;
new gSK_Spawner = -1;

/***************************************************/
//Plugin Starts

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "abrandnewday, reworked by Keith Warren (Jack of Designs)",
	description = "Spawn Halloween bosses using commands, natives or ConVars.",
	version = PLUGIN_VERSION,
	url = "http://www.jackofdesigns.com/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
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
	
	RegPluginLibrary("boss_spawns");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	PrintToConsole(0, "%s Boss Spawns is initializing...", PLUGIN_TAG);
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig_SetFile("BossSpawns");
		
	ConVars[0] = AutoExecConfig_CreateConVar("sm_bossspawns_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	ConVars[1] = AutoExecConfig_CreateConVar("sm_bossspawns_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[2] = AutoExecConfig_CreateConVar("sm_bossspawns_hitboxes", "1", "Enable hitbox scaling on spawned bosses: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[3] = AutoExecConfig_CreateConVar("sm_bossspawns_bounds", "0.1, 5.0", "Lower (optional) and upper bounds for resizing, separated with a comma.", FCVAR_PLUGIN);
	
	AutoExecConfig_ExecuteFile();
	
	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
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
	
	RegAdminCmd("sm_slayhatman", Command_SlayHatman, ADMFLAG_GENERIC, "Slays all Horsemenn on the map - Usage: sm_slayhatman");
	RegAdminCmd("sm_slayeyeboss", Command_SlayEyeBoss, ADMFLAG_GENERIC, "Slays all MONOCULUS! on the map - Usage: sm_slayeyeboss");
	RegAdminCmd("sm_slayeyeboss_red", Command_SlayEyeBossRED, ADMFLAG_GENERIC, "Slays all RED Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_red");
	RegAdminCmd("sm_slayeyeboss_blue", Command_SlayEyeBossBLU, ADMFLAG_GENERIC, "Slays all BLU Spectral MONOCULUS! on the map - Usage: sm_slayeyeboss_blue");
	RegAdminCmd("sm_slaymerasmus", Command_SlayMerasmus, ADMFLAG_GENERIC, "Slays all Merasmus on the map - Usage: sm_slaymerasmus");
	RegAdminCmd("sm_slayskelegreen", Command_SlayGreenSkeleton, ADMFLAG_GENERIC, "Slays all Green Skeletons on the map - Usage: sm_slayskelegreen");
	RegAdminCmd("sm_slayskelered", Command_SlayREDSkeleton, ADMFLAG_GENERIC, "Slays all RED Skeletons on the map - Usage: sm_slayskelered");
	RegAdminCmd("sm_slayskeleblue", Command_SlayBLUSkeleton, ADMFLAG_GENERIC, "Slays all BLU Skeletons on the map - Usage: sm_slayskeleblue");
	RegAdminCmd("sm_slayskeleking", Command_SlaySkeletonKing, ADMFLAG_GENERIC, "Slays all Skeleton Kings on the map - Usage: sm_slayskeleking");
	
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	cv_HitboxScale = GetConVarBool(ConVars[2]);
	ParseConVarToLimits(ConVars[3], g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
	
	if (cv_Enabled)
	{
		PrintToConsole(0, "%s Boss Spawns has been fully initialized.", PLUGIN_TAG);
		PrintToConsole(0, "%s Hitbox Scaling: %s", PLUGIN_TAG, cv_HitboxScale ? "ON" : "OFF");
	}
}

public HandleCvars(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true)) return;

	new iNewValue = StringToInt(newValue);

	if (cvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == ConVars[1])
	{
		cv_Enabled = bool:iNewValue;
	}
	else if (cvar == ConVars[2])
	{
		cv_HitboxScale = bool:iNewValue;
	}
	else if (cvar == ConVars[3])
	{
		ParseConVarToLimits(ConVars[3], g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
	}
}

public OnPluginEnd()
{
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "headless_hatman")) != -1)
	{
		if (IsValidEntity(entity))
		{
			new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (IsValidEntity(entity))
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, "merasmus")) != -1)
	{
		if (IsValidEntity(entity))
		{
			new Handle:g_Event = CreateEvent("merasmus_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
		}
	}
	while((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

ParseConVarToLimits(const Handle:hConvar, String:szMinString[], const iMinStringLength, &Float:fMin, String:szMaxString[], const iMaxStringLength, &Float:fMax)
{
	new iSplitResult;
	decl String:szBounds[256];
	GetConVarString(hConvar, szBounds, sizeof(szBounds));
	
	if ((iSplitResult = SplitString(szBounds, ",", szMinString, iMinStringLength)) != -1 && (fMin = StringToFloat(szMinString)) >= 0.0)
	{
		TrimString(szMinString);
		strcopy(szMaxString, iMaxStringLength, szBounds[iSplitResult]);
	}
	else
	{
		strcopy(szMinString, iMinStringLength, "0.0");
		fMin = 0.0;
		strcopy(szMaxString, iMaxStringLength, szBounds);
	}
	
	TrimString(szMaxString);
	fMax = StringToFloat(szMaxString);
	
	new iMarkInMin = FindCharInString(szMinString, '.'), iMarkInMax = FindCharInString(szMaxString, '.');
	Format(szMinString, iMinStringLength, "%s%s%s", (iMarkInMin == 0 ? "0" : ""), szMinString, (iMarkInMin == -1 ? ".0" : (iMarkInMin == (strlen(szMinString) - 1) ? "0" : "")));
	Format(szMaxString, iMaxStringLength, "%s%s%s", (iMarkInMax == 0 ? "0" : ""), szMaxString, (iMarkInMax == -1 ? ".0" : (iMarkInMax == (strlen(szMaxString) - 1) ? "0" : "")));
	
	if (fMin > fMax)
	{
		new Float:fTemp = fMax;
		fMax = fMin;
		fMin = fTemp;
	}
}

/***************************************************/
//Spawn Commands

public Action:Command_SpawnHatman(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("headless_hatman", fScale, 0, 10.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}Horseless Headless Horsemann!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Horseless Headless Horsemann", client);
		CReplyToCommand(client, "%s {default}You've spawned the {unusual}Horseless Headless Horsemann!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	
	return Plugin_Handled;
}

public Action:Command_SpawnEyeBoss(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("eyeball_boss", fScale, 5, 50.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: MONOCULUS", client);
		CReplyToCommand(client, "%s {default}You've spawned the {unusual}MONOCULUS!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnEyeBossRED(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("eyeball_boss", fScale, 2, 50.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {red}RED Spectral MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: RED Spectral MONOCULUS", client);
		CReplyToCommand(client, "%s {default}You've spawned the {red}RED Spectral MONOCULUS!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnEyeBossBLU(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("eyeball_boss", fScale, 1, 50.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {blue}BLU Spectral MONOCULUS!", client);
		LogAction(client, -1, "\"%L\" spawned boss: BLU Spectral MONOCULUS", client);
		CReplyToCommand(client, "%s {default}You've spawned the {blue}BLU Spectral MONOCULUS!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnMerasmus(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("merasmus", fScale, 0, 0.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned {unusual}Merasmus!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Merasmus", client);
		CReplyToCommand(client, "%s {default}You've spawned {unusual}Merasmus!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}Merasmus!{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnGreenSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("tf_zombie", fScale, 3, 0.0, "2", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {community}Green Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Green Skeleton", client);
		CReplyToCommand(client, "%s {default}You've spawned {community}Green Skeleton!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {community}Green Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnREDSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s%t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("tf_zombie", fScale, 1, 0.0, "0", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {red}RED Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: RED Skeleton", client);
		CReplyToCommand(client, "%s {default}You've spawned {red}RED Skeleton!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {red}RED Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnBLUSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("tf_zombie", fScale, 2, 0.0, "1", bGlow ? true : false))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {blue}BLU Skeleton!", client);
		LogAction(client, -1, "\"%L\" spawned boss: BLU Skeleton", client);
		CReplyToCommand(client, "%s {default}You've spawned {blue}BLU Skeleton!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SpawnSkeletonKing(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	if (!IsValidClient(client))
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG_COLORED, "Command is in-game only");
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
			CReplyToCommand(client, "%s {default}Invalid size specified", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
		{
			CReplyToCommand(client, "%s {default}Size must be between %s and %s", PLUGIN_TAG_COLORED, g_szBoundMin, g_szBoundMax);
			return Plugin_Handled;
		}
		
		if (StrEqual(sGlow, "1"))
		{
			bGlow = true;
		}
	}
	
	if(!SetTeleportEndPoint(client))
	{
		CReplyToCommand(client, "%s {default}Could not find spawn point", PLUGIN_TAG_COLORED);
		return Plugin_Handled;
	}
	
	if (CheckEntityLimit(client)) return Plugin_Handled;
	
	if (SpawnBoss("tf_zombie_spawner", -1.0, 0, 0.0, "0", bGlow ? true : false, true))
	{
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {unusual}Skeleton King!", client);
		LogAction(client, -1, "\"%L\" spawned boss: Skeleton King", client);
		CReplyToCommand(client, "%s {default}You've spawned {unusual}Skeleton King!", PLUGIN_TAG_COLORED);
	}
	else
	{
		CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason.", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

/***************************************************/
//Spawn Function

bool:SpawnBoss(const String:sEntityClass[64], Float:scale = -1.0, team = 0, Float:offset = 0.0, String:skin[1] = "-1", bool:glow = false, bool:SkeletonKing = false)
{
	new entity = CreateEntityByName(sEntityClass);
	if (IsValidEntity(entity))
	{
		DispatchSpawn(entity);
		if (scale != -1.0)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale);
			if (cv_HitboxScale) ResizeHitbox(entity, sEntityClass, scale);
		}
		
		if (team != 0) SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
		if (offset != 0.0) g_pos[2] -= offset;
		if (!StrEqual(skin, "-1")) DispatchKeyValue(entity, "skin", skin);
		if (glow) SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);
		
		if (SkeletonKing)
		{
			SetEntProp(entity, Prop_Data, "m_nSkeletonType", 1);
			AcceptEntityInput(entity, "Enable");
			gSK_Spawner = entity;
			gSK_IsSpawning = true;
		}
		
		TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
		return true;
	}
	return false;
}

/***************************************************/
//Slay Commands

public Action:Command_SlayHatman(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "headless_hatman")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}Horseless Headless Horsemann{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new Handle:g_Event = CreateEvent("pumpkin_lord_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(entity, "Kill");
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}Horseless Headless Horsemann", client);
		LogAction(client, -1, "\"%L\" slayed boss: Horseless Headless Horsemann", client);
		CReplyToCommand(client, "%s {default}You've slayed the {unusual}Horseless Headless Horsemann", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBoss(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 5)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}MONOCULUS!", client);
			LogAction(client, -1, "\"%L\" slayed boss: MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {unusual}MONOCULUS!", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBossRED(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {red}RED Spectral MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 2)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {red}RED Spectral MONOCULUS!", client);
			LogAction(client, -1, "\"%L\" slayed boss: RED Spectral MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {red}RED Spectral MONOCULUS!", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayEyeBossBLU(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "eyeball_boss")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {blue}BLU Spectral MONOCULUS!{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 1)
		{
			new Handle:g_Event = CreateEvent("eyeball_boss_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {blue}BLU Spectral MONOCULUS!", client);
			LogAction(client, -1, "\"%L\" slayed boss: BLU Spectral MONOCULUS", client);
			CReplyToCommand(client, "%s {default}You've slayed the {blue}BLU Spectral MONOCULUS!", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayMerasmus(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while((entity = FindEntityByClassname(entity, "merasmus")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay {unusual}Merasmus{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new Handle:g_Event = CreateEvent("merasmus_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(entity, "Kill");
		CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed {unusual}Merasmus", client);
		LogAction(client, -1, "\"%L\" slayed boss: Merasmus", client);
		CReplyToCommand(client, "%s {default}You've slayed the {unusual}Merasmus", PLUGIN_TAG_COLORED);
	}
	return Plugin_Handled;
}

public Action:Command_SlayGreenSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {community}Green Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 3)
		{
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {community}Green Skeleton!", client);
			LogAction(client, -1, "\"%L\" slayed boss: Green Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {community}Green Skeleton", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayREDSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {red}RED Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 1)
		{
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {red}RED Skeleton!", client);
			LogAction(client, -1, "\"%L\" slayed boss: RED Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {red}RED Skeleton", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlayBLUSkeleton(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {blue}BLU Skeleton{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		new m_iTeamNum = GetEntProp(entity, Prop_Data, "m_iTeamNum");
		if (m_iTeamNum == 2)
		{
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {blue}BLU Skeleton!", client);
			LogAction(client, -1, "\"%L\" slayed boss: BLU Skeleton", client);
			CReplyToCommand(client, "%s {default}You've slayed the {blue}BLU Skeleton", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SlaySkeletonKing(client, args)
{
	if (!cv_Enabled) return Plugin_Handled;
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
	{
		if (!IsValidEntity(entity))
		{
			CReplyToCommand(client, "%s {default}Couldn't slay the {unusual}Skeleton King{default} for some reason.", PLUGIN_TAG_COLORED);
			return Plugin_Handled;
		}
		
		decl String:sBuffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
		
		if (StrEqual(sBuffer, "SkeletonKing"))
		{
			AcceptEntityInput(entity, "Kill");
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s slayed the {unusual}Skeleton King!", client);
			LogAction(client, -1, "\"%L\" slayed boss: Skeleton King", client);
			CReplyToCommand(client, "%s {default}You've slayed the {unusual}Skeleton King", PLUGIN_TAG_COLORED);
		}
	}
	return Plugin_Handled;
}

/***************************************************/

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
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
		g_healthBar = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, "headless_hatman"))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, "eyeball_boss"))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, "merasmus"))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
	}
	else if (g_trackEntity == -1 && StrEqual(classname, "tf_zombie_spawner"))
	{
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
	}
	
	if (StrEqual(classname, "tf_zombie") && gSK_IsSpawning)
	{		
		DispatchKeyValue(entity, "targetname", "SkeletonKing");
				
		if (IsValidEntity(gSK_Spawner))
		{
			AcceptEntityInput(gSK_Spawner, "kill");
			gSK_Spawner = -1;
		}
		
		gSK_IsSpawning = false;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == -1) return;
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, "headless_hatman");
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, "headless_hatman");
		}
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnHorsemannDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, "eyeball_boss");
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, "eyeball_boss");
		}
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMonoculusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, "merasmus");
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, "merasmus");
		}
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
	else if (entity == g_trackEntity)
	{
		g_trackEntity = FindEntityByClassname(-1, "tf_zombie_spawner");
		if (g_trackEntity == entity)
		{
			g_trackEntity = FindEntityByClassname(entity, "tf_zombie_spawner");
		}
		if (g_trackEntity > -1)
		{
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnSkeletonKingDamaged);
		}
		UpdateBossHealth(g_trackEntity);
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
	if (g_healthBar == -1) return;
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
	SetEntProp(g_healthBar, Prop_Send, "m_iBossHealthPercentageByte", percentage);
}

/***************************************************/
//Natives

public Native_SpawnHatman(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}
	
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new bool:bGlow = GetNativeCell(7);
	
	if (SpawnBoss("headless_hatman", scale, 0, 10.0, "0", bGlow))
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}Horseless Headless Horsemann via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Horseless Headless Horsemann", client);
			CReplyToCommand(client, "%s {default}You've spawned the {unusual}Horseless Headless Horsemann via natives!", PLUGIN_TAG_COLORED);
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Horseless Headless Horsemann!{default} for some reason via natives.", PLUGIN_TAG_COLORED);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Hatman, could not spawn Hatman.");
	}
}

public Native_SpawnEyeboss(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}
	
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new type = GetNativeCell(7);
	new bool:bGlow = GetNativeCell(8);
	
	if (SpawnBoss("eyeball_boss", scale, type, 50.0, "0", bGlow))
	{
		if (spew)
		{
			switch (type)
			{
			case 0:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {unusual}MONOCULUS via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {unusual}MONOCULUS via natives!", PLUGIN_TAG_COLORED);
				}
			case 1:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {red}RED Spectral MONOCULUS via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: RED Spectral MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {red}RED Spectral MONOCULUS via natives!", PLUGIN_TAG_COLORED);
				}
			case 2:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned the {blue}BLU Spectral MONOCULUS via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Spectral MONOCULUS", client);
					CReplyToCommand(client, "%s {default}You've spawned the {blue}BLU Spectral MONOCULUS via natives!", PLUGIN_TAG_COLORED);
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
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}MONOCULUS!{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'regular', could not spawn Eyeboss 'regular'.");
			}
		case 1:
			{
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn {red}RED Spectral MONOCULUS!{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'red', could not spawn Eyeboss 'red'.");
			}
		case 2:
			{
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn {blue}BLU Spectral MONOCULUS!{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'blue', could not spawn Eyeboss 'blue'.");
			}
		}
	}
}

public Native_SpawnMerasmus(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}
	
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new bool:bGlow = GetNativeCell(7);
	
	if (SpawnBoss("merasmus", scale, 0, 0.0, "0", bGlow))
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned {unusual}Merasmus via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Merasmus", client);
			CReplyToCommand(client, "%s {default}You've spawned {unusual}Merasmus via natives!", PLUGIN_TAG_COLORED);
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn {unusual}Merasmus!{default} for some reason via natives.", PLUGIN_TAG_COLORED);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Merasmus, could not spawn Merasmus.");
	}
}

public Native_SpawnSkeleton(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}
	
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new Float:scale = Float:GetNativeCell(6);
	new type = GetNativeCell(7);
	new bool:bGlow = GetNativeCell(8);
	
	new String:sSkin[1] = "0";
	
	switch (type)
	{
	case 1:	Format(sSkin, sizeof(sSkin), "0");
	case 2:	Format(sSkin, sizeof(sSkin), "1");
	case 3:	Format(sSkin, sizeof(sSkin), "2");
	}
	
	if (SpawnBoss("tf_zombie", scale, type, 0.0, sSkin, bGlow))
	{
		if (spew)
		{
			switch (type)
			{
			case 0:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {community}Green Skeleton via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: Green Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {community}Green Skeleton via natives!", PLUGIN_TAG_COLORED);
				}
			case 1:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {red}RED Skeleton via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: RED Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {red}RED Skeleton via natives!", PLUGIN_TAG_COLORED);
				}
			case 2:
				{
					CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {blue}BLU Skeleton via natives!", client);
					LogAction(client, -1, "\"%L\" spawned boss via natives: BLU Skeleton", client);
					CReplyToCommand(client, "%s {default}You've spawned {blue}BLU Skeleton via natives!", PLUGIN_TAG_COLORED);
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
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn the {community}Green Skeleton{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Green', could not spawn Eyeboss 'Green'.");
			}
		case 1:
			{
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn the {red}RED Skeleton{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Red', could not spawn Eyeboss 'Red'.");
			}
		case 2:
			{
				if (spew) CReplyToCommand(client, "%s {default}Couldn't spawn the {blue}BLU Skeleton{default} for some reason via natives.", PLUGIN_TAG_COLORED);
				ThrowNativeError(SP_ERROR_INDEX, "Error spawning Eyeboss 'Blue', could not spawn Eyeboss 'Blue'.");
			}
		}
	}
}

public Native_SpawnSkeletonKing(Handle:plugin, numParams)
{
	if (!cv_Enabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin currently disabled.");
	}
	
	new client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, invalid client.");
	}
	
	g_pos[0] = Float:GetNativeCell(2);
	g_pos[1] = Float:GetNativeCell(3);
	g_pos[2] = Float:GetNativeCell(4);
	new bool:spew = GetNativeCell(5);
	new bool:bGlow = GetNativeCell(6);
	
	if (SpawnBoss("tf_zombie_spawner", 1.0, 0, 0.0, "-1", bGlow, true))
	{
		if (spew)
		{
			CShowActivity(client, "{unusual}[BOSS] ", "{default}%s spawned a {unusual}Skeleton King via natives!", client);
			LogAction(client, -1, "\"%L\" spawned boss via natives: Skeleton King", client);
			CReplyToCommand(client, "%s {default}You've spawned {unusual}Skeleton King via natives!", PLUGIN_TAG_COLORED);
		}
	}
	else
	{
		if (spew)
		{
			CReplyToCommand(client, "%s {default}Couldn't spawn the {unusual}Skeleton King{default} for some reason via natives.", PLUGIN_TAG_COLORED);
		}
		ThrowNativeError(SP_ERROR_INDEX, "Error spawning Skeleton King, could not spawn Skeleton King.");
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
	if (GetEntityCount() >= GetMaxEntities()-32)
	{
		CReplyToCommand(client, "%s {default}Too many entities have been spawned, reload the map.", PLUGIN_TAG_COLORED);
		return true;
	}
	return false;
}

ResizeHitbox(entity, const String:sEntityClass[64], Float:fScale = 1.0)
{
	decl Float:vecBossMin[3], Float:vecBossMax[3];
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
	
	decl Float:vecScaledBossMin[3], Float:vecScaledBossMax[3];
	
	vecScaledBossMin = vecBossMin;
	vecScaledBossMax = vecBossMax;
	
	ScaleVector(vecScaledBossMin, fScale);
	ScaleVector(vecScaledBossMax, fScale);
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecScaledBossMin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecScaledBossMax);
}

//Lets put this behemoth of a function at the bottom shall we... get it the hell out of the way.
public OnMapStart()
{
	g_healthBar = FindEntityByClassname(-1, "monster_resource");
	if (g_healthBar == -1)
	
	g_healthBar = CreateEntityByName("monster_resource");
	if (g_healthBar != -1)
	{
		DispatchSpawn(g_healthBar);
	}
	
	PrecacheModel("models/bots/headless_hatman.mdl", true); 
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
	
	for(new i = 1; i <= 2; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_alert0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 4; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 2; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_death0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 4; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_laugh0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_boss/knight_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("vo/halloween_boss/knight_dying.wav", true);
	PrecacheSound("vo/halloween_boss/knight_spawn.wav", true);
	PrecacheSound("vo/halloween_boss/knight_alert.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav", true);
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav", true);
	
	PrecacheModel("models/props_halloween/halloween_demoeye.mdl", true);
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl", true);
	
	for(new i = 1; i <= 3; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball_laugh0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball_mad0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 13; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_eyeball/eyeball%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav", true);
	PrecacheSound("vo/halloween_eyeball/eyeball_teleport01.wav", true);
	PrecacheSound("ui/halloween_boss_summon_rumble.wav", true);
	PrecacheSound("ui/halloween_boss_chosen_it.wav", true);
	PrecacheSound("ui/halloween_boss_defeated_fx.wav", true);
	PrecacheSound("ui/halloween_boss_defeated.wav", true);
	PrecacheSound("ui/halloween_boss_player_becomes_it.wav", true);
	PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
	PrecacheSound("ui/halloween_boss_summoned.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
	PrecacheSound("ui/halloween_boss_escape.wav", true);
	PrecacheSound("ui/halloween_boss_escape_sixty.wav", true);
	PrecacheSound("ui/halloween_boss_escape_ten.wav", true);
	PrecacheSound("ui/halloween_boss_tagged_other_it.wav", true);
	
	PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl", true);
	
	for(new i = 1; i <= 17; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 11; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 54; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 33; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 2; i <= 4; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_island0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_skullhat0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 1; i <= 2; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_combat_idle0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 12; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 9; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_found0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 3; i <= 6; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_grenades0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 26; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 19; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal10%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal1%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 49; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 16; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 5; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 4; i <= 8; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_ranged_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 2; i <= 13; i++)
	{
		decl String:iString[PLATFORM_MAX_PATH];
		if (i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic%d.wav", i);
		if (FileExists(iString))
		{
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav", true);
	
	PrecacheSound("misc/halloween/merasmus_appear.wav", true);
	PrecacheSound("misc/halloween/merasmus_death.wav", true);
	PrecacheSound("misc/halloween/merasmus_disappear.wav", true);
	PrecacheSound("misc/halloween/merasmus_float.wav", true);
	PrecacheSound("misc/halloween/merasmus_hiding_explode.wav", true);
	PrecacheSound("misc/halloween/merasmus_spell.wav", true);
	PrecacheSound("misc/halloween/merasmus_stun.wav", true);
	
	PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
	PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl", true);
}
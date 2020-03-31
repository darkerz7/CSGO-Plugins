//====================================================================================================
//
// Name: entWatch
// Author: Prometheum & zaCade
// Description: Monitor entity interactions.
//
//====================================================================================================
#pragma semicolon 1
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <adminmenu>
#tryinclude <entWatch>
#tryinclude <csgocolors_fix>
#pragma newdecls required

#define PLUGIN_VERSION "3.8.145"

//uncomment the next line if you using DynamicChannels: https://github.com/Vauff/DynamicChannels
//#define DYNAMIC_CHANNELS
#if defined DYNAMIC_CHANNELS
#include <DynamicChannels>
#endif

//----------------------------------------------------------------------------------------------------
// Purpose: Entity data
//----------------------------------------------------------------------------------------------------
enum entities
{
	String:ent_name[32],
	String:ent_shortname[32],
	String:ent_color[32],
	String:ent_buttonclass[32],
	String:ent_filtername[32],
	bool:ent_hasfiltername,
	bool:ent_blockpickup,
	bool:ent_allowtransfer,
	bool:ent_forcedrop,
	bool:ent_chat,
	bool:ent_hud,
	ent_hammerid,
	ent_weaponid,
	ent_buttonid,
	ent_ownerid,
	ent_mode, // 0 = No iButton, 1 = Spam protection only, 2 = Cooldowns, 3 = Limited uses, 4 = Limited uses with cooldowns, 5 = Cooldowns after multiple uses.
	ent_uses,
	ent_maxuses,
	ent_cooldown,
	ent_cooldowntime,
	ent_glowent,
	ent_glow_r,
	ent_glow_g,
	ent_glow_b,
};

int entArray[512][entities],
	entArraySize = 512,
	triggerArray[512],
	triggerSize = 512;

//----------------------------------------------------------------------------------------------------
// Purpose: Color settings
//----------------------------------------------------------------------------------------------------
char color_tag[16]        = "{green}",
	color_name[16]        = "{default}",
	color_steamid[16]     = "{grey}",
	color_use[16]         = "{lightblue}",
	color_pickup[16]      = "{lime}",
	color_drop[16]        = "{pink}",
	color_disconnect[16]  = "{orange}",
	color_death[16]       = "{orange}",
	color_warning[16]     = "{orange}";

//----------------------------------------------------------------------------------------------------
// Purpose: Client settings
//----------------------------------------------------------------------------------------------------
Handle g_hCookie_Restricted  = null,
	g_hCookie_RestrictedLength = null,
	g_hCookie_RestrictedIssued = null,
	g_hCookie_RestrictedBy	  = null,
	g_hCookie_Display		  = null,
	g_hCookie_HudPos		  = null,
	g_hCookie_HudColor		  = null;

bool g_bRestricted[MAXPLAYERS + 1] = false;
char g_sRestrictedBy[MAXPLAYERS + 1][64];
int  g_iRestrictedLength[MAXPLAYERS + 1],
	g_iRestrictedIssued[MAXPLAYERS + 1],
	g_iAdminMenuTarget[MAXPLAYERS + 1];

//----------------------------------------------------------------------------------------------------
// Purpose: Plugin settings
//----------------------------------------------------------------------------------------------------
ConVar g_hCvar_DisplayEnabled,
	g_hCvar_DisplayCooldowns,
	g_hCvar_ModeTeamOnly,
	g_hCvar_ConfigColor,
	g_hCvar_Glow,
	g_hCvar_Default_BanTime,
	g_hCvar_HUD_Channel;

Handle g_hAdminMenu,
	g_hOnBanForward,
	g_hOnUnbanForward;

bool g_bRoundTransition  = false,
	g_bConfigLoaded     = false,
	g_bLateLoad = false;
	
bool isMapRunning;
bool g_bPostWarmUp = false;

bool g_bGlow = true;
int g_iHUDChannel = 5;

bool g_bDisplay[MAXPLAYERS + 1]     = false;
bool g_bDisplay2[MAXPLAYERS + 1]     = false;
float g_DefaultHudPos[2];
int g_DefaultHudColor[3];
int ItemIdx=1;
char ShowCools[64][512];
char ShowCoolsPlayerName[64][512];
float HudPosition[MAXPLAYERS+1][2];
int HudColor[MAXPLAYERS+1][3];
//----------------------------------------------------------------------------------------------------
// Purpose: Plugin information
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name         = "entWatch",
	author       = "Prometheum & zaCade. Edits: George & Obus & BotoX & Hikka & DarkerZ[RUS]",
	description  = "Notify players about entity interactions.",
	version      = PLUGIN_VERSION,
	url          = "https://github.com/darkerz7/CSGO-Plugins/tree/master/EntWatch%20Hud"
};

public APLRes AskPluginLoad2(Handle hThis, bool bLate, char[] sError, int iErr_max)
{
	CreateNative("entWatch_IsClientBanned", Native_IsClientBanned);
	CreateNative("entWatch_BanClient", Native_BanClient);
	CreateNative("entWatch_UnbanClient", Native_UnbanClient);
	CreateNative("entWatch_IsSpecialItem", Native_IsSpecialItem);
	CreateNative("entWatch_HasSpecialItem", Native_HasSpecialItem);

	RegPluginLibrary("entWatch");

	g_bLateLoad = bLate;

	return APLRes_Success;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Plugin initialization
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	CreateConVar("entwatch_version", PLUGIN_VERSION, "Current version of entWatch", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvar_DisplayEnabled    = CreateConVar("entwatch_display_enable", "1", "Enable/Disable the display.", _, true, 0.0, true, 1.0);
	g_hCvar_DisplayCooldowns  = CreateConVar("entwatch_display_cooldowns", "1", "Show/Hide the cooldowns on the display.", _, true, 0.0, true, 1.0);
	g_hCvar_ModeTeamOnly      = CreateConVar("entwatch_mode_teamonly", "1", "Enable/Disable team only mode.", _, true, 0.0, true, 1.0);
	g_hCvar_ConfigColor       = CreateConVar("entwatch_config_color", "color_classic", "The name of the color config.", _);
	g_hCvar_Glow              = CreateConVar("entwatch_glow", "1", "Enable/Disable the glow.", _, true, 0.0, true, 1.0);
	g_hCvar_Default_BanTime   = CreateConVar("entwatch_bantime", "0", "Default ban time (0-43200)", _, true, 0.0, true, 43200.0);
	g_hCvar_HUD_Channel       = CreateConVar("entwatch_hud_channel", "5", "Change HUD Channel/Group Dynamic channel.", _, true, 0.0, true, 5.0);

	g_hCookie_Display     = RegClientCookie("entwatch_display", "", CookieAccess_Private);
	g_hCookie_Restricted  = RegClientCookie("entwatch_restricted", "", CookieAccess_Private);
	g_hCookie_RestrictedLength = RegClientCookie("entwatch_restrictedlength", "", CookieAccess_Private);
	g_hCookie_RestrictedIssued = RegClientCookie("entwatch_restrictedissued", "", CookieAccess_Private);
	g_hCookie_RestrictedBy     = RegClientCookie("entwatch_restrictedby", "", CookieAccess_Private);
	g_hCookie_HudPos      = RegClientCookie("entwatch_hudpos", "", CookieAccess_Private);
	g_hCookie_HudColor    = RegClientCookie("entwatch_hudcolor", "", CookieAccess_Private);

	Handle hTopMenu;

	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE)) OnAdminMenuReady(hTopMenu);
	
	RegConsoleCmd("sm_status", Command_Status);

	RegAdminCmd("sm_eban", Command_Restrict, ADMFLAG_BAN);
	RegAdminCmd("sm_ebanlist", Command_EBanlist, ADMFLAG_BAN);
	RegAdminCmd("sm_eunban", Command_Unrestrict, ADMFLAG_BAN);
	RegAdminCmd("sm_etransfer", Command_Transfer, ADMFLAG_BAN);
	RegAdminCmd("sm_setcooldown", Command_Cooldown, ADMFLAG_BAN);
	RegAdminCmd("sm_ew_reloadconfig", Command_ReloadConfig, ADMFLAG_CONFIG);
	RegAdminCmd("sm_ewdebugarray", Command_DebugArray, ADMFLAG_CONFIG);
	
	RegConsoleCmd("sm_hud", Command_ToggleHUD);
	RegConsoleCmd("sm_hudpos", Command_Hudpos);
	RegConsoleCmd("sm_hudcolor", Command_HudColor);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	HookConVarChange(g_hCvar_Glow, Cvar_Glow_Changed);
	HookConVarChange(g_hCvar_HUD_Channel, Cvar_HUD_Channel_Changed);

	CreateTimer(1.0, Timer_DisplayHUD, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Cooldowns, _, TIMER_REPEAT);

	LoadTranslations("entWatch.phrases");
	LoadTranslations("common.phrases");

	AutoExecConfig(true, "plugin.entWatch");

	g_hOnBanForward = CreateGlobalForward("entWatch_OnClientBanned", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnUnbanForward = CreateGlobalForward("entWatch_OnClientUnbanned", ET_Ignore, Param_Cell, Param_Cell);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

public void Cvar_Glow_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGlow = GetConVarBool(convar);
	if(!g_bGlow)
		for (int index = 0; index < entArraySize; index++)
		{
			if (IsValidEdict(entArray[index][ent_glowent])) AcceptEntityInput(entArray[index][ent_glowent], "Kill");
		}
}

public void Cvar_HUD_Channel_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHUDChannel = GetConVarInt(convar);
}

//----------------------------------------------------------------------------------------------------
// Purpose: Main ban function
//----------------------------------------------------------------------------------------------------
void EBanClient(int iClient, const char[] sLength, int iAdmin)
{
	int iBanLen = StringToInt(sLength);
	int iBanDuration = (iBanLen - GetTime()) / 60;

	if (iAdmin != 0)
	{
		char sAdminSID[64];
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdminSID, sizeof(sAdminSID));
		FormatEx(g_sRestrictedBy[iClient], sizeof(g_sRestrictedBy[]), "%s (%N)", sAdminSID, iAdmin);

		SetClientCookie(iClient, g_hCookie_RestrictedBy, sAdminSID);
	} else {
		FormatEx(g_sRestrictedBy[iClient], sizeof(g_sRestrictedBy[]), "Console");
		SetClientCookie(iClient, g_hCookie_RestrictedBy, "Console");
	}

	switch (iBanLen) {
		case 0: {
			iBanDuration = 0;
			g_bRestricted[iClient] = true;
			LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\"", iAdmin, iClient);
		}
	}
	if (iBanLen != 1)
	{
		g_iRestrictedLength[iClient] = iBanLen;
		SetClientCookie(iClient, g_hCookie_RestrictedLength, sLength);
		LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\" for %d Minutes", iAdmin, iClient, iBanDuration);
	} else {
		iBanDuration = -1;
		g_iRestrictedLength[iClient] = 1;
		SetClientCookie(iClient, g_hCookie_RestrictedLength, "1");
		LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\" permanently", iAdmin, iClient);
	}

	char sIssueTime[64];
	FormatEx(sIssueTime, sizeof(sIssueTime), "%d", GetTime());

	g_iRestrictedIssued[iClient] = GetTime();
	SetClientCookie(iClient, g_hCookie_RestrictedIssued, sIssueTime);

	CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iAdmin, color_warning, "restricted", color_name, iClient);

	Call_StartForward(g_hOnBanForward);
	Call_PushCell(iAdmin);
	Call_PushCell(iBanDuration);
	Call_PushCell(iClient);
	Call_Finish();
}

//----------------------------------------------------------------------------------------------------
// Purpose: Main unban function
//----------------------------------------------------------------------------------------------------
void EUnbanClient(int iClient, int iAdmin)
{
	g_bRestricted[iClient] = false;
	g_iRestrictedLength[iClient] = 0;
	g_iRestrictedIssued[iClient] = 0;
	g_sRestrictedBy[iClient][0] = '\0';
	SetClientCookie(iClient, g_hCookie_RestrictedLength, "0");
	SetClientCookie(iClient, g_hCookie_RestrictedBy, "");
	SetClientCookie(iClient, g_hCookie_RestrictedIssued, "");

	CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iAdmin, color_warning, "unrestricted", color_name, iClient);
	LogAction(iAdmin, iClient, "\"%L\" unrestricted \"%L\"", iAdmin, iClient);

	Call_StartForward(g_hOnUnbanForward);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_Finish();
}
//----------------------------------------------------------------------------------------------------
// Purpose: Safeguard against adminmenu unloading
//----------------------------------------------------------------------------------------------------
public void OnLibraryRemoved(const char[] sName) {
	if (strcmp(sName, "adminmenu") == 0) g_hAdminMenu = INVALID_HANDLE;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Add our entries to the main admin menu
//----------------------------------------------------------------------------------------------------
public void OnAdminMenuReady(Handle hAdminMenu)
{
	if (hAdminMenu == g_hAdminMenu) return;

	g_hAdminMenu = hAdminMenu;

	TopMenuObject hMenuObj = AddToTopMenu(g_hAdminMenu, "entWatch_commands", TopMenuObject_Category, AdminMenu_Commands_Handler, INVALID_TOPMENUOBJECT);

	switch (hMenuObj) {
		case INVALID_TOPMENUOBJECT: return;
	}

	AddToTopMenu(g_hAdminMenu, "entWatch_banlist", TopMenuObject_Item, Handler_EBanList, hMenuObj, "sm_ebanlist", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "entWatch_ban", TopMenuObject_Item, Handler_EBan, hMenuObj, "sm_eban", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "entWatch_transfer", TopMenuObject_Item, Handler_Transfer, hMenuObj, "sm_etransfer", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "entWatch_give", TopMenuObject_Item, Handler_Give, hMenuObj, "sm_egive", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "entWatch_unban", TopMenuObject_Item, Handler_EUnban, hMenuObj, "sm_eunban", ADMFLAG_BAN);
}

//----------------------------------------------------------------------------------------------------
// Purpose: Menu Stuff
//----------------------------------------------------------------------------------------------------
public void AdminMenu_Commands_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "entWatch Commands", iParam1);
		case TopMenuAction_DisplayTitle: FormatEx(sBuffer, iMaxlen, "%T:", "entWatch Commands", iParam1);
	}
}

public void Handler_EBanList(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "List Banned Clients", iParam1);
		case TopMenuAction_SelectOption: Menu_List(iParam1);
	}
}

public void Handler_EBan(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "Ban a Client", iParam1);
		case TopMenuAction_SelectOption: Menu_EBan(iParam1);
	}
}

public void Handler_Transfer(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "Transfer an item", iParam1);
		case TopMenuAction_SelectOption: Menu_Transfer(iParam1);
	}
}

public void Handler_Give(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "Give an Item", iParam1);
		case TopMenuAction_SelectOption: Menu_Give(iParam1);
	}
}

public void Handler_EUnban(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "Unban a Client", iParam1);
		case TopMenuAction_SelectOption: Menu_EUnban(iParam1);
	}
}

void Menu_List(int iClient) {
	int iBannedClients;

	Menu hListMenu = CreateMenu(MenuHandler_Menu_List);
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Banned Clients", iClient);
	hListMenu.SetTitle(sMenuTranslate);
	hListMenu.ExitBackButton = true;

	for (int i = 1; i < MaxClients + 1; i++)
	{
		if (IsClientInGame(i) && AreClientCookiesCached(i))
		{
			char sBanLen[32];
			GetClientCookie(i, g_hCookie_RestrictedLength, sBanLen, sizeof(sBanLen));
			int iBanLen = StringToInt(sBanLen);

			if ((iBanLen != 0 && iBanLen >= GetTime()) || iBanLen == 1 || g_bRestricted[i])
			{
				int iUserID = GetClientUserId(i);
				char sUserID[12], sBuff[64];
				FormatEx(sBuff, sizeof(sBuff), "%N (#%i)", i, iUserID);
				FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);

				hListMenu.AddItem(sUserID, sBuff);
				iBannedClients++;
			}
		}
	}

	if (!iBannedClients) {char sMenuItem[128];Format(sMenuItem, sizeof(sMenuItem), "%T.", "No Banned Clients", iClient);hListMenu.AddItem("", sMenuItem, ITEMDRAW_DISABLED);}

	hListMenu.Display(iClient, MENU_TIME_FOREVER);
}

void Menu_EBan(int iClient) {
	Menu hEBanMenu = CreateMenu(MenuHandler_Menu_EBan);
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Ban a Client", iClient);
	hEBanMenu.SetTitle(sMenuTranslate);
	hEBanMenu.ExitBackButton = true;
	AddTargetsToMenu2(hEBanMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	hEBanMenu.Display(iClient, MENU_TIME_FOREVER);
}

void Menu_Transfer(int iClient) {
	Menu hTransferMenu = CreateMenu(MenuHandler_Menu_Transfer);
	char sMenuTemp[64], sIndexTemp[16];
	int iHeldCount = 0;
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Transfer an item", iClient);
	hTransferMenu.SetTitle(sMenuTranslate);
	hTransferMenu.ExitBackButton = true;

	for (int i = 0; i < entArraySize; i++)
	{
		if (entArray[i][ent_allowtransfer])
		{
			if (entArray[i][ent_ownerid] != -1)
			{
				IntToString(i, sIndexTemp, sizeof(sIndexTemp));
				FormatEx(sMenuTemp, sizeof(sMenuTemp), "%s | %N (#%i)", entArray[i][ent_name], entArray[i][ent_ownerid], GetClientUserId(entArray[i][ent_ownerid]));
				hTransferMenu.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);
				iHeldCount++;
			}
		}
	}

	if (!iHeldCount) {char sMenuItem[128];Format(sMenuItem, sizeof(sMenuItem), "%T.", "No transferable items currently held", iClient);hTransferMenu.AddItem("", sMenuItem, ITEMDRAW_DISABLED);}

	hTransferMenu.Display(iClient, MENU_TIME_FOREVER);
}

void Menu_Give(int iClient) {
	Menu hTransferMenu = CreateMenu(MenuHandler_Menu_Give);
	char sMenuTemp[64], sIndexTemp[16];
	int iHeldCount = 0;
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Give an Item", iClient);
	hTransferMenu.SetTitle(sMenuTranslate);
	hTransferMenu.ExitBackButton = true;

	for (int i = 0; i < entArraySize; i++)
	{
		if (entArray[i][ent_allowtransfer])
		{
			if (entArray[i][ent_ownerid] == -1)
			{
				if (IsValidEdict(entArray[i][ent_weaponid]))
				{
					IntToString(i, sIndexTemp, sizeof(sIndexTemp));
					FormatEx(sMenuTemp, sizeof(sMenuTemp), "%s | #%i", entArray[i][ent_name], entArray[i][ent_hammerid]);
					hTransferMenu.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);
					iHeldCount++;
				}
			}
		}
	}

	if (!iHeldCount) {char sMenuItem[128];Format(sMenuItem, sizeof(sMenuItem), "%T.", "No Give items currently held", iClient);hTransferMenu.AddItem("", sMenuItem, ITEMDRAW_DISABLED);}

	hTransferMenu.Display(iClient, MENU_TIME_FOREVER);
}

void Menu_EUnban(int iClient)
{
	int iBannedClients;

	Menu hEUnbanMenu = CreateMenu(MenuHandler_Menu_EUnban);
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Unban a Client", iClient);
	hEUnbanMenu.SetTitle(sMenuTranslate);
	hEUnbanMenu.ExitBackButton = true;

	for (int i = 1; i < MaxClients + 1; i++)
	{
		if (IsClientInGame(i) && AreClientCookiesCached(i))
		{
			char sBanLen[32];
			GetClientCookie(i, g_hCookie_RestrictedLength, sBanLen, sizeof(sBanLen));
			int iBanLen = StringToInt(sBanLen);

			if ((iBanLen != 0 && iBanLen >= GetTime()) || iBanLen == 1 || g_bRestricted[i])
			{
				int iUserID = GetClientUserId(i);
				char sUserID[12], sBuff[64];
				FormatEx(sBuff, sizeof(sBuff), "%N (#%i)", i, iUserID);
				FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);

				hEUnbanMenu.AddItem(sUserID, sBuff);
				iBannedClients++;
			}
		}
	}

	if (!iBannedClients) {char sMenuItem[128];Format(sMenuItem, sizeof(sMenuItem), "%T.", "No Banned Clients", iClient);hEUnbanMenu.AddItem("", sMenuItem, ITEMDRAW_DISABLED);}

	hEUnbanMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_List(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: {
			if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));

			if (iTarget != 0) Menu_ListTarget(iParam1, iTarget);
			else {
				CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning,"Player no longer available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int MenuHandler_Menu_EBan(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: {
			if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));

			if (iTarget != 0) Menu_EBanTime(iParam1, iTarget);
			else {
				CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning,"Player no longer available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int MenuHandler_Menu_Transfer(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: {
			if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iEntityIndex = StringToInt(sOption);

			if (entArray[iEntityIndex][ent_ownerid] != -1) Menu_TransferTarget(iParam1, iEntityIndex);
			else CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning, "Item no longer available");
		}
	}
}

public int MenuHandler_Menu_Give(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: {
			if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iEntityIndex = StringToInt(sOption);

			if (entArray[iEntityIndex][ent_ownerid] == -1) Menu_GiveTarget(iParam1, iEntityIndex);
			else CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning, "Item is already picked up");
		}
	}
}

public int MenuHandler_Menu_EUnban(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: {
			if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));

			if (iTarget != 0) EUnbanClient(iTarget, iParam1);
			else {
				CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning, "Player no longer available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

void Menu_TransferTarget(int iClient, int iEntityIndex)
{
	Menu hTransferTarget = CreateMenu(MenuHandler_Menu_TransferTarget);
	char sMenuTemp[64], sIndexTemp[32];
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Transfer iTarget", iClient);
	hTransferTarget.SetTitle(sMenuTranslate);
	hTransferTarget.ExitBackButton = true;

	g_iAdminMenuTarget[iClient] = iEntityIndex;
	Format(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(iClient));
	Format(sMenuTemp, sizeof(sMenuTemp), "%N (#%s)", iClient, sIndexTemp);
	hTransferTarget.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);

	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != GetClientTeam(entArray[iEntityIndex][ent_ownerid]) || i == iClient) continue;

		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N (#%s)", i, sIndexTemp);
		hTransferTarget.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);
	}

	hTransferTarget.Display(iClient, MENU_TIME_FOREVER);
}

void Menu_GiveTarget(int iClient, int iEntityIndex)
{
	Menu hTransferTarget = CreateMenu(MenuHandler_Menu_GiveTarget);
	char sMenuTemp[64], sIndexTemp[32];
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Give iTarget", iClient);
	hTransferTarget.SetTitle(sMenuTranslate);
	hTransferTarget.ExitBackButton = true;


	g_iAdminMenuTarget[iClient] = iEntityIndex;
	
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i)<2) continue;

		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N (#%s)", i, sIndexTemp);
		hTransferTarget.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);
	}

	hTransferTarget.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_TransferTarget(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel: {
			switch (iParam2) {
				case MenuCancel_ExitBack: Menu_Transfer(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[64];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iEntityIndex = g_iAdminMenuTarget[iParam1];
			int iReceiver = GetClientOfUserId(StringToInt(sOption));

			switch(iReceiver) {
				case 0: {
					CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning,"Receiver is not valid anymore");
					return;
				}
			}

			if (entArray[iEntityIndex][ent_allowtransfer])
			{
				if (entArray[iEntityIndex][ent_ownerid] != -1)
				{
					if (IsValidEdict(entArray[iEntityIndex][ent_weaponid]))
					{
						int iCurOwner = entArray[iEntityIndex][ent_ownerid];

						if (GetClientTeam(iReceiver) != GetClientTeam(iCurOwner))
						{
							CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning,"The receivers team differs from the targets team");
							return;
						}

						char ssBuffer_classname[64];
						GetEdictClassname(entArray[iEntityIndex][ent_weaponid], ssBuffer_classname, sizeof(ssBuffer_classname));

						CS_DropWeapon(iCurOwner, entArray[iEntityIndex][ent_weaponid], false);
						GivePlayerItem(iCurOwner, ssBuffer_classname);

						if (entArray[iEntityIndex][ent_chat])
						{
							entArray[iEntityIndex][ent_chat] = false;
							FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
							entArray[iEntityIndex][ent_chat] = true;
						}
						else FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);

						CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iParam1, color_warning, "transfered all items", color_name, iCurOwner, color_warning, "tai to", color_name, iReceiver);

						LogAction(iParam1, iCurOwner, "\"%L\" transfered all items from \"%L\" to \"%L\"", iParam1, iCurOwner, iReceiver);
					}
				}
				else CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning,"Item is not valid anymore");
			}
		}
	}
}

public int MenuHandler_Menu_GiveTarget(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel: {
			switch (iParam2) {
				case MenuCancel_ExitBack: Menu_Transfer(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[64];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iEntityIndex = g_iAdminMenuTarget[iParam1];
			int iReceiver = GetClientOfUserId(StringToInt(sOption));
			
			switch(iReceiver) {
				case 0: {
					CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Receiver is not valid anymore");
					return;
				}
			}

			if (entArray[iEntityIndex][ent_allowtransfer])
			{
				if (entArray[iEntityIndex][ent_ownerid] == -1)
				{
					if (IsValidEdict(entArray[iEntityIndex][ent_weaponid]))
					{
						if ((GetClientTeam(iReceiver) != 2)&&(GetClientTeam(iReceiver) != 3))
						{
							CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning,"The receivers team is not CT or TER");
							return;
						}
						
						if (entArray[iEntityIndex][ent_chat])
						{
							entArray[iEntityIndex][ent_chat] = false;
							FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
							entArray[iEntityIndex][ent_chat] = true;
						}
						else FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);

						CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%s \x07%s%t \x07%s%N", color_tag, color_name, iParam1, color_warning, "give item", entArray[iEntityIndex][ent_color], entArray[iEntityIndex][ent_name], color_warning, "tai to", color_name, iReceiver);

						LogAction(iParam1, iReceiver, "\"%L\" gived %s item to \"%L\"", iParam1,entArray[iEntityIndex][ent_name], iReceiver);
					}
					else CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Item dont pickable");
				}
				else CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Item is already picked up");
			}
		}
	}
}

void Menu_EBanTime(int iClient, int iTarget)
{
	Menu hEBanMenuTime = CreateMenu(MenuHandler_Menu_EBanTime);
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T %N:", "Ban Time for", iClient, iTarget);
	hEBanMenuTime.SetTitle(sMenuTranslate);
	hEBanMenuTime.ExitBackButton = true;

	g_iAdminMenuTarget[iClient] = iTarget;
	char sMenuItem[128];
	Format(sMenuItem, sizeof(sMenuItem), "%T", "Temporary", iClient);
	hEBanMenuTime.AddItem("0", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "10 %T", "Minutes", iClient);
	hEBanMenuTime.AddItem("10", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "1 %T", "Hour", iClient);
	hEBanMenuTime.AddItem("60", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "1 %T", "Day", iClient);
	hEBanMenuTime.AddItem("1440", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "1 %T", "Week", iClient);
	hEBanMenuTime.AddItem("10080", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "1 %T", "Month", iClient);
	hEBanMenuTime.AddItem("40320", sMenuItem);
	Format(sMenuItem, sizeof(sMenuItem), "%T", "Permanent", iClient);
	hEBanMenuTime.AddItem("1", sMenuItem);

	hEBanMenuTime.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_EBanTime(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel:
		{
			switch(iParam2){
				case MenuCancel_ExitBack: Menu_EBan(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[64];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = g_iAdminMenuTarget[iParam1];

			if (iTarget != 0)
			{
				if (strcmp(sOption, "0") == 0) EBanClient(iTarget, "0", iParam1);
				else if (strcmp(sOption, "1") == 0) EBanClient(iTarget, "1", iParam1);
				else {
					char sBanLen[64];
					Format(sBanLen, sizeof(sBanLen), "%d", GetTime() + (StringToInt(sOption) * 60));

					EBanClient(iTarget, sBanLen, iParam1);
				}
			} else {
				CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning, "Player no longer available");
				Menu_EBan(iParam1);
			}
		}
	}
}

void Menu_ListTarget(int iClient, int iTarget)
{
	Menu hListTargetMenu = CreateMenu(MenuHandler_Menu_ListTarget);
	char sMenuTranslate[128];
	Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T: %N", "Banned Client", iClient, iTarget);
	hListTargetMenu.SetTitle(sMenuTranslate);
	hListTargetMenu.ExitBackButton = true;

	char sBanExpiryDate[64], sBanIssuedDate[64], sBanDuration[64], sBannedBy[64], sUserID[15];
	int iBanExpiryDate = g_iRestrictedLength[iTarget];
	int iBanIssuedDate = g_iRestrictedIssued[iTarget];
	int iBanDuration = (iBanExpiryDate - iBanIssuedDate) / 60;
	int iUserID = GetClientUserId(iTarget);

	char sBanExpiryDateBuf[64],sBanIssuedDateBuf[64];
	FormatTime(sBanExpiryDateBuf, sizeof(sBanExpiryDateBuf), NULL_STRING, iBanExpiryDate);
	FormatTime(sBanIssuedDateBuf, sizeof(sBanIssuedDateBuf), NULL_STRING, iBanIssuedDate);
	FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);

	if (!g_bRestricted[iTarget])
	{
		if (iBanExpiryDate != 1)
		{
			FormatEx(sBanDuration, sizeof(sBanDuration), "%T: %d %s", "Duration", iClient, iBanDuration, SingularOrMultiple(iBanDuration)?"Minutes":"Minute");
			FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "%T: %s", "Expires", iClient, sBanExpiryDateBuf);
		} else {
			FormatEx(sBanDuration, sizeof(sBanDuration), "%T: %T", "Duration", iClient, "Permanent", iClient);
			FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "%T: %T", "Expires", iClient, "Never", iClient);
		}
	} else {
		FormatEx(sBanDuration, sizeof(sBanDuration), "%T: %T", "Duration", iClient, "Temporary", iClient);
		FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "%T: %T", "Expires", iClient, "On Map Change", iClient);
	}

	FormatEx(sBanIssuedDate, sizeof(sBanIssuedDate), "%T: %s", "Issued on", iClient, !(iBanIssuedDate == 0) ? sBanIssuedDateBuf:"Unknown");
	FormatEx(sBannedBy, sizeof(sBannedBy), "%T: %s", "Admin SID", iClient, g_sRestrictedBy[iTarget][0] ? g_sRestrictedBy[iTarget]:"Unknown");

	hListTargetMenu.AddItem("", sBannedBy, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanIssuedDate, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanExpiryDate, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanDuration, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", "", ITEMDRAW_SPACER);
	char sMenuItem[128];
	Format(sMenuItem, sizeof(sMenuItem), "%T", "Unban", iClient);
	hListTargetMenu.AddItem(sUserID, sMenuItem);

	hListTargetMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_ListTarget(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel:
		{
			switch (iParam2) {
				case MenuCancel_ExitBack: Menu_List(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));

			if (iTarget != 0) EUnbanClient(iTarget, iParam1);
			else {
				CPrintToChat(iParam1, "\x07%s[entWatch]\x07%s %t", color_tag, color_warning, "Player no longer available");
				Menu_List(iParam1);
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Set variables
//----------------------------------------------------------------------------------------------------
public void OnMapStart()
{
	CleanData();
	LoadColors();
	LoadConfig();
	
	isMapRunning = true;
}

public void OnMapEnd()
{
    isMapRunning = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Hook RoundStart event
//----------------------------------------------------------------------------------------------------
public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_bConfigLoaded && g_bRoundTransition) CPrintToChatAll("\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "welcome");

	if((GameRules_GetProp("m_bWarmupPeriod") == 1)||g_bPostWarmUp)
	{
		g_bPostWarmUp = false;
		for (int index = 0; index < entArraySize; index++)
		{
			SDKUnhook(entArray[index][ent_buttonid], SDKHook_Use, OnButtonUse);
			entArray[index][ent_weaponid]       = -1;
			entArray[index][ent_buttonid]       = -1;
			entArray[index][ent_ownerid]        = -1;
			entArray[index][ent_cooldowntime]   = -1;
			entArray[index][ent_uses]           = 0;
			if (IsValidEdict(entArray[index][ent_glowent])) AcceptEntityInput(entArray[index][ent_glowent], "Kill");
			entArray[index][ent_glowent]		= -1;
		}
	}
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		g_bPostWarmUp = true;
	}
	g_bRoundTransition = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Hook RoundEnd event
//----------------------------------------------------------------------------------------------------
public Action Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		for (int index = 0; index < entArraySize; index++)
		{
			SDKUnhook(entArray[index][ent_buttonid], SDKHook_Use, OnButtonUse);
			entArray[index][ent_weaponid]       = -1;
			entArray[index][ent_buttonid]       = -1;
			entArray[index][ent_ownerid]        = -1;
			entArray[index][ent_cooldowntime]   = -1;
			entArray[index][ent_uses]           = 0;
			if (IsValidEdict(entArray[index][ent_glowent])) AcceptEntityInput(entArray[index][ent_glowent], "Kill");
			entArray[index][ent_glowent]		= -1;
		}
	}

	g_bRoundTransition = true;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Set client cookies once cached
//----------------------------------------------------------------------------------------------------
public void OnClientCookiesCached(int iClient)
{
	char sBuffer_cookie[32];
	
	GetClientCookie(iClient, g_hCookie_Display, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_bDisplay[iClient] = view_as<bool>(StringToInt(sBuffer_cookie));

	GetClientCookie(iClient, g_hCookie_RestrictedLength, sBuffer_cookie, sizeof(sBuffer_cookie));

	if (StringToInt(sBuffer_cookie) != 1 && StringToInt(sBuffer_cookie) <= GetTime()) {
		g_iRestrictedLength[iClient] = 0;
		SetClientCookie(iClient, g_hCookie_RestrictedLength, "0");
	}
	else g_iRestrictedLength[iClient] = StringToInt(sBuffer_cookie);

	GetClientCookie(iClient, g_hCookie_RestrictedIssued, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_iRestrictedIssued[iClient] = StringToInt(sBuffer_cookie);

	GetClientCookie(iClient, g_hCookie_RestrictedBy, sBuffer_cookie, sizeof(sBuffer_cookie));
	FormatEx(g_sRestrictedBy[iClient], sizeof(g_sRestrictedBy[]), "%s", sBuffer_cookie);
	
	GetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,"")){
		Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%f/%f", g_DefaultHudPos[0], g_DefaultHudPos[1]);
		SetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie);
		HudPosition[iClient][0] = g_DefaultHudPos[0];
		HudPosition[iClient][1] = g_DefaultHudPos[1];
	}else 
	{
		char Explode_HudPosition[2][32];
		ExplodeString(sBuffer_cookie, "/", Explode_HudPosition, 2, 32);
		HudPosition[iClient][0] = StringToFloat(Explode_HudPosition[0]);
		HudPosition[iClient][1] = StringToFloat(Explode_HudPosition[1]);
	}
	
	GetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,"")){
		Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%i/%i/%i", g_DefaultHudColor[0], g_DefaultHudColor[1], g_DefaultHudColor[2]);
		SetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie);
		HudColor[iClient][0] = g_DefaultHudColor[0];
		HudColor[iClient][1] = g_DefaultHudColor[1];
		HudColor[iClient][2] = g_DefaultHudColor[2];
	}else 
	{
		char Explode_HudColor[3][8];
		ExplodeString(sBuffer_cookie, "/", Explode_HudColor, 3, 8);
		HudColor[iClient][0] = StringToInt(Explode_HudColor[0]);
		HudColor[iClient][1] = StringToInt(Explode_HudColor[1]);
		HudColor[iClient][2] = StringToInt(Explode_HudColor[2]);
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Hook weapons and update banned clients to int method
//----------------------------------------------------------------------------------------------------
public void OnClientPutInServer(int iClient)
{
	SDKHookEx(iClient, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHookEx(iClient, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKHookEx(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	g_bDisplay2[iClient] = true;
	if (!AreClientCookiesCached(iClient))
	{
		HudPosition[iClient][0] = g_DefaultHudPos[0];
		HudPosition[iClient][1] = g_DefaultHudPos[1];
		HudColor[iClient][0] = g_DefaultHudColor[0];
		HudColor[iClient][1] = g_DefaultHudColor[1];
		HudColor[iClient][2] = g_DefaultHudColor[2];
		g_bDisplay2[iClient] = true;
		g_bDisplay[iClient] = false;
	}

	g_bRestricted[iClient] = false;

	if (!AreClientCookiesCached(iClient)) g_iRestrictedLength[iClient] = 0;
	else
	{
		char sRestricted[32];
		GetClientCookie(iClient, g_hCookie_Restricted, sRestricted, sizeof(sRestricted));

		switch(StringToInt(sRestricted)) {
			case 1: {
				SetClientCookie(iClient, g_hCookie_RestrictedLength, "1");
				SetClientCookie(iClient, g_hCookie_Restricted, "0");
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Notify of Disconnect if they had a special weapon and unhook weapons
//----------------------------------------------------------------------------------------------------
public void OnClientDisconnect(int iClient)
{
	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_ownerid] != -1 && entArray[index][ent_ownerid] == iClient)
			{
				entArray[index][ent_ownerid] = -1;

				//if (entArray[index][ent_forcedrop] && IsValidEdict(entArray[index][ent_weaponid])) CS_DropWeapon(iClient, entArray[index][ent_weaponid], false); // Add glow function on drop

				//else if (entArray[index][ent_chat])
				if (entArray[index][ent_chat])
				{
					char sBuffer_steamid[32];
					GetClientAuthId(iClient, AuthId_Steam2, sBuffer_steamid, sizeof(sBuffer_steamid));
					ReplaceString(sBuffer_steamid, sizeof(sBuffer_steamid), "STEAM_", "", true);

					for (int iPly = 1; iPly <= MaxClients; iPly++)
					{
						if (IsClientConnected(iPly) && IsClientInGame(iPly)) {
							if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT))) {
								CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iClient, color_disconnect, color_steamid, sBuffer_steamid, color_disconnect, color_disconnect, "disconnect", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
				}
			}
		}
	}

	SDKUnhook(iClient, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKUnhook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKUnhook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);

	//g_bDisplay[iClient] = false;
	g_bDisplay[iClient] = false;
	g_bDisplay2[iClient] = true;
	g_bRestricted[iClient] = false;
	g_iRestrictedLength[iClient] = 0;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Notify of Death if they had a special weapon
//----------------------------------------------------------------------------------------------------
public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_ownerid] != -1 && entArray[index][ent_ownerid] == iClient)
			{
				entArray[index][ent_ownerid] = -1;

				if (entArray[index][ent_forcedrop] && IsValidEdict(entArray[index][ent_weaponid])) CS_DropWeapon(iClient, entArray[index][ent_weaponid], false);

				else if (entArray[index][ent_chat])
				{
					char sBuffer_steamid[32];
					GetClientAuthId(iClient, AuthId_Steam2, sBuffer_steamid, sizeof(sBuffer_steamid));
					ReplaceString(sBuffer_steamid, sizeof(sBuffer_steamid), "STEAM_", "", true);

					for (int iPly = 1; iPly <= MaxClients; iPly++)
					{
						if (IsClientConnected(iPly) && IsClientInGame(iPly))
						{
							if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT))) {
								CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iClient, color_death, color_steamid, sBuffer_steamid, color_death, color_death, "death", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Notify when they pick up a special weapon
//----------------------------------------------------------------------------------------------------
public Action OnWeaponEquip(int iClient, int iWeapon)
{
	if (g_bConfigLoaded && !g_bRoundTransition && IsValidEdict(iWeapon))
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(iWeapon))
			{
				if (entArray[index][ent_weaponid] != -1 && entArray[index][ent_weaponid] == iWeapon)
				{
					entArray[index][ent_ownerid] = iClient;
					DisableGlow(index);

					if (entArray[index][ent_chat])
					{
						char sBuffer_steamid[32];
						GetClientAuthId(iClient, AuthId_Steam2, sBuffer_steamid, sizeof(sBuffer_steamid));
						ReplaceString(sBuffer_steamid, sizeof(sBuffer_steamid), "STEAM_", "", true);

						for (int iPly = 1; iPly <= MaxClients; iPly++)
						{
							if (IsClientConnected(iPly) && IsClientInGame(iPly))
							{
								if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
								{
									CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iClient, color_pickup, color_steamid, sBuffer_steamid, color_pickup, color_pickup, "pickup", entArray[index][ent_color], entArray[index][ent_name]);
								}
							}
						}
					}

					break;
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Notify when they drop a special weapon
//----------------------------------------------------------------------------------------------------
public Action OnWeaponDrop(int iClient, int iWeapon)
{
	if (g_bConfigLoaded && !g_bRoundTransition && IsValidEdict(iWeapon))
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(iWeapon))
			{
				if (entArray[index][ent_weaponid] != -1 && entArray[index][ent_weaponid] == iWeapon)
				{
					entArray[index][ent_ownerid] = -1;
					GlowWeapon(index);
					
					if (entArray[index][ent_chat])
					{
						char sBuffer_steamid[32];
						GetClientAuthId(iClient, AuthId_Steam2, sBuffer_steamid, sizeof(sBuffer_steamid));
						ReplaceString(sBuffer_steamid, sizeof(sBuffer_steamid), "STEAM_", "", true);

						for (int iPly = 1; iPly <= MaxClients; iPly++)
						{
							if (IsClientConnected(iPly) && IsClientInGame(iPly))
							{
								if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
								{
									CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iClient, color_drop, color_steamid, sBuffer_steamid, color_drop, color_drop, "drop", entArray[index][ent_color], entArray[index][ent_name]);
								}
							}
						}
					}

					break;
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose: Prevent banned players from picking up special weapons
//----------------------------------------------------------------------------------------------------
public Action OnWeaponCanUse(int iClient, int iWeapon)
{
	if (IsFakeClient(iClient)) return Plugin_Handled;

	if (g_bConfigLoaded && !g_bRoundTransition && IsValidEdict(iWeapon))
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(iWeapon))
			{
				if (entArray[index][ent_weaponid] == -1)
				{
					entArray[index][ent_weaponid] = iWeapon;

					if (entArray[index][ent_buttonid] == -1 && entArray[index][ent_mode] != 0)
					{
						char sBuffer_targetname[32];
						Entity_GetTargetName(iWeapon, sBuffer_targetname, sizeof(sBuffer_targetname));

						int iButton = -1;
						while ((iButton = FindEntityByClassname(iButton, entArray[index][ent_buttonclass])) != -1)
						{
							if (IsValidEdict(iButton))
							{
								char sBuffer_parentname[32];
								Entity_GetParentName(iButton, sBuffer_parentname, sizeof(sBuffer_parentname));

								if (StrEqual(sBuffer_targetname, sBuffer_parentname))
								{
									SDKHookEx(iButton, SDKHook_Use, OnButtonUse);
									entArray[index][ent_buttonid] = iButton;
									break;
								}
							}
						}
					}
				}
				
				else if (entArray[index][ent_weaponid] == iWeapon)
				{
					if (entArray[index][ent_blockpickup] || g_bRestricted[iClient] || (GetClientButtons(iClient) & IN_USE)) return Plugin_Handled;

					if (g_iRestrictedLength[iClient] != 1 && g_iRestrictedLength[iClient] != 0 && g_iRestrictedLength[iClient] <= GetTime())
					{
						g_iRestrictedLength[iClient] = 0;
						SetClientCookie(iClient, g_hCookie_RestrictedLength, "0");
						return Plugin_Continue;
					}

					if (g_iRestrictedLength[iClient] > GetTime() || g_iRestrictedLength[iClient] == 1) return Plugin_Handled;
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Notify when they use a special weapon
//----------------------------------------------------------------------------------------------------
public Action OnButtonUse(int iButton, int iActivator, int iCaller, UseType uType, float fvalue)
{
	if (g_bConfigLoaded && !g_bRoundTransition && IsValidEdict(iButton))
	{
		int iOffset = FindDataMapInfo(iButton, "m_bLocked");
		if (iOffset != -1 && GetEntData(iButton, iOffset, 1)) return Plugin_Handled;

		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_buttonid] != -1 && entArray[index][ent_buttonid] == iButton)
			{
				if (entArray[index][ent_ownerid] != iActivator && entArray[index][ent_ownerid] != iCaller) return Plugin_Handled;
				else if (entArray[index][ent_hasfiltername]) DispatchKeyValue(iActivator, "targetname", entArray[index][ent_filtername]);

				char sBuffer_steamid[32];
				GetClientAuthId(iActivator, AuthId_Steam2, sBuffer_steamid, sizeof(sBuffer_steamid));
				ReplaceString(sBuffer_steamid, sizeof(sBuffer_steamid), "STEAM_", "", true);

				switch (entArray[index][ent_mode]) {
					case 1: return Plugin_Changed;
					case 2: {
						if (entArray[index][ent_cooldowntime] <= -1)
						{
							for (int iPly = 1; iPly <= MaxClients; iPly++)
							{
								if (IsClientConnected(iPly) && IsClientInGame(iPly))
								{
									if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iActivator) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
									{
										CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iActivator, color_use, color_steamid, sBuffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
									}
								}
							}
		
							entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
							return Plugin_Changed;
						}
					}
					case 3: {
						if (entArray[index][ent_uses] < entArray[index][ent_maxuses])
						{
							for (int iPly = 1; iPly <= MaxClients; iPly++)
							{
								if (IsClientConnected(iPly) && IsClientInGame(iPly))
								{
									if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iActivator) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
									{
										CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iActivator, color_use, color_steamid, sBuffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
									}
								}
							}
		
							entArray[index][ent_uses]++;
							return Plugin_Changed;
						}
					}
					
					case 4: {
						if (entArray[index][ent_uses] < entArray[index][ent_maxuses] && entArray[index][ent_cooldowntime] <= -1)
						{
							for (int iPly = 1; iPly <= MaxClients; iPly++)
							{
								if (IsClientConnected(iPly) && IsClientInGame(iPly))
								{
									if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iActivator) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
									{
										CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iActivator, color_use, color_steamid, sBuffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
									}
								}
							}
		
							entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
							entArray[index][ent_uses]++;
							return Plugin_Changed;
						}
					}
					case 5: {
						if (entArray[index][ent_cooldowntime] <= -1)
						{
							for (int iPly = 1; iPly <= MaxClients; iPly++)
							{
								if (IsClientConnected(iPly) && IsClientInGame(iPly))
								{
									if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(iPly) == GetClientTeam(iActivator) || !IsPlayerAlive(iPly) || CheckCommandAccess(iPly, "entWatch_chat", ADMFLAG_CHAT)))
									{
										CPrintToChat(iPly, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, iActivator, color_use, color_steamid, sBuffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
									}
								}
							}
		
							entArray[index][ent_uses]++;
							if (entArray[index][ent_uses] >= entArray[index][ent_maxuses])
							{
								entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
								entArray[index][ent_uses] = 0;
							}
		
							return Plugin_Changed;
						}
					}
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Calculate cooldown time
//----------------------------------------------------------------------------------------------------

public Action Timer_Cooldowns(Handle timer)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		for (int index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_cooldowntime] >= 0)
			{
				entArray[index][ent_cooldowntime]--;
			}
		}
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Check status
//----------------------------------------------------------------------------------------------------
public Action Command_Status(int iClient, int iArgs)
{
	if (iArgs != 0 && CheckCommandAccess(iClient, "", ADMFLAG_BAN, true))
	{
		char sArguments[64];
		char CStatus[64];
		int iTarget = -1;
		GetCmdArg(1, sArguments, sizeof(sArguments));
		iTarget = FindTarget(iClient, sArguments);

		switch(iTarget){
			case -1: return Plugin_Handled;
		}

		if (AreClientCookiesCached(iTarget))
		{
			GetClientCookie(iTarget, g_hCookie_RestrictedLength, CStatus, sizeof(CStatus));

			if (g_bRestricted[iTarget])
			{
				CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s %t", color_tag, color_warning, color_name, iTarget, color_warning, "is temporarily restricted");
				return Plugin_Handled;
			}

			switch(StringToInt(CStatus)) {
				case 0: {
					CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s %t", color_tag, color_warning, color_name, iTarget, color_warning, "is not restricted");
					return Plugin_Handled;
				}
				
				case 1: {
					CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s %t", color_tag, color_warning, color_name, iTarget, color_warning, "is permanently restricted");
					return Plugin_Handled;
				}
			}
			if (StringToInt(CStatus) <= GetTime())
			{
				CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s %t", color_tag, color_warning, color_name, iTarget, color_warning, "is not restricted");
				g_iRestrictedLength[iTarget] = 0;
				SetClientCookie(iTarget, g_hCookie_RestrictedLength, "0");

				return Plugin_Handled;
			}

			char sRemainingTime[128];
			char sFRemainingTime[128];
			GetClientCookie(iTarget, g_hCookie_RestrictedLength, sRemainingTime, sizeof(sRemainingTime));
			int iTstamp = (StringToInt(sRemainingTime) - GetTime());

			int iDays = (iTstamp / 86400);
			int iHours = ((iTstamp / 3600) % 24);
			int iMinutes = ((iTstamp / 60) % 60);
			int iSeconds = (iTstamp % 60);

			if (iTstamp > 86400)
				FormatEx(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s, %d %s, %d %s", iDays, SingularOrMultiple(iDays)?"Days":"Day", iHours, SingularOrMultiple(iHours)?"Hours":"Hour", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
			else if (iTstamp > 3600)
				FormatEx(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s, %d %s", iHours, SingularOrMultiple(iHours)?"Hours":"Hour", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
			else if (iTstamp > 60)
				FormatEx(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
			else FormatEx(sFRemainingTime, sizeof(sFRemainingTime), "%d %s", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");

			CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s %t: \x04%s", color_tag, color_warning, color_name, iTarget, color_warning, "is restricted for another", sFRemainingTime);

			return Plugin_Handled;
		} else {
			CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s \x07%s%N\x07%s%t", color_tag, color_warning, color_name, iTarget, color_warning, "cookies havent loaded yet");
			return Plugin_Handled;
		}
	}

	if (g_bRestricted[iClient])
	{
		CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status restricted");
		return Plugin_Handled;
	}

	if (AreClientCookiesCached(iClient))
	{
		if (g_iRestrictedLength[iClient] >= 1)
		{
			if (g_iRestrictedLength[iClient] != 1 && g_iRestrictedLength[iClient] != 0 && g_iRestrictedLength[iClient] <= GetTime())
			{
				g_iRestrictedLength[iClient] = 0;
				SetClientCookie(iClient, g_hCookie_RestrictedLength, "0");

				CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status unrestricted");
				return Plugin_Handled;
			}

			switch (g_iRestrictedLength[iClient]) {
				case 1: {
					CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t \x04(permanent)", color_tag, color_warning, "status restricted");
					return Plugin_Handled;
				}
			}
			
			if (g_iRestrictedLength[iClient] > 1)
			{
				char sRemainingTime[128];
				char sFRemainingTime[128];
				GetClientCookie(iClient, g_hCookie_RestrictedLength, sRemainingTime, sizeof(sRemainingTime));
				int iTstamp = (StringToInt(sRemainingTime) - GetTime());

				int iDays = (iTstamp / 86400);
				int iHours = ((iTstamp / 3600) % 24);
				int iMinutes = ((iTstamp / 60) % 60);
				int iSeconds = (iTstamp % 60);

				if (iTstamp > 86400)
					Format(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s, %d %s, %d %s", iDays, SingularOrMultiple(iDays)?"Days":"Day", iHours, SingularOrMultiple(iHours)?"Hours":"Hour", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
				else if (iTstamp > 3600)
					Format(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s, %d %s", iHours, SingularOrMultiple(iHours)?"Hours":"Hour", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
				else if (iTstamp > 60)
					Format(sFRemainingTime, sizeof(sFRemainingTime), "%d %s, %d %s", iMinutes, SingularOrMultiple(iMinutes)?"Minutes":"Minute", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");
				else
					Format(sFRemainingTime, sizeof(sFRemainingTime), "%d %s", iSeconds, SingularOrMultiple(iSeconds)?"Seconds":"Second");

				CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t \x04(%s)", color_tag, color_warning, "status restricted", sFRemainingTime);

				return Plugin_Handled;
			}

			CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status restricted");
		} else CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status unrestricted");
	} else CReplyToCommand(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "cookies loading");
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Ban a client
//----------------------------------------------------------------------------------------------------
public Action Command_Restrict(int iClient, int iArgs)
{
	if (GetCmdArgs() < 1)
	{
		CReplyToCommand(iClient, "\x07%s[entWatch] \x07%sUsage: sm_eban <target>", color_tag, color_warning);
		return Plugin_Handled;
	}

	char sTarget_argument[64];
	GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

	int iTarget = -1;
	if ((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;

	if (GetCmdArgs() > 1)
	{
		char sLen[64], sFlength[64];
		GetCmdArg(2, sLen, sizeof(sLen));

		FormatEx(sFlength, sizeof(sFlength), "%d", GetTime() + (StringToInt(sLen) * 60));

		if (StringToInt(sLen) != 0) EBanClient(iTarget, sFlength, iClient);
		else {
			EBanClient(iTarget, "1", iClient);
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	int cvarLen = GetConVarInt(g_hCvar_Default_BanTime);
	char cvarsFlength[64];
	FormatEx(cvarsFlength, sizeof(cvarsFlength), "%d", GetTime() + (cvarLen * 60));
	if (cvarLen != 0) EBanClient(iTarget, cvarsFlength, iClient);
	else {
		EBanClient(iTarget, "1", iClient);
	}
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Lists the clients that are currently on the server and banned
//----------------------------------------------------------------------------------------------------
public Action Command_EBanlist(int iClient, int iArgs)
{
	char sBuff[1024];
	bool bFirst = true;
	Format(sBuff, sizeof(sBuff), "%T", "No players found", iClient);

	for (int i = 1; i < MaxClients + 1; i++)
	{
		if(!IsClientInGame(i)) continue;

		if (AreClientCookiesCached(i))
		{
			char sBanLen[32];
			GetClientCookie(i, g_hCookie_RestrictedLength, sBanLen, sizeof(sBanLen));
			int iBanLen = StringToInt(sBanLen);

			if ((iBanLen != 0 && iBanLen >= GetTime()) || iBanLen == 1)
			{
				if (bFirst)
				{
					bFirst = false;
					FormatEx(sBuff, sizeof(sBuff), "");
				} else FormatEx(sBuff, sizeof(sBuff), "%s, ", sBuff);

				FormatEx(sBuff, sizeof(sBuff), "%s%N (#%i)", sBuff, i, GetClientUserId(i));
			}
		}
		else if (g_bRestricted[i])
		{
			if (bFirst)
 			{
 				bFirst = false;
 				FormatEx(sBuff, sizeof(sBuff), "");
 			} else FormatEx(sBuff, sizeof(sBuff), "%s, ", sBuff);
 			
 			FormatEx(sBuff, sizeof(sBuff), "%s%N (#%i)", sBuff, i, GetClientUserId(i));
		}
	}

	CReplyToCommand(iClient, "\x07%s[entWatch]\x07%s %t: \x07%s%s", color_tag, color_warning, "Currently e-banned", color_name, sBuff);
	FormatEx(sBuff, sizeof(sBuff), "");
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Unban a client
//----------------------------------------------------------------------------------------------------
public Action Command_Unrestrict(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		CReplyToCommand(iClient, "\x07%s[entWatch] \x07%sUsage: sm_eunban <iTarget>", color_tag, color_warning);
		return Plugin_Handled;
	}

	char sTarget_argument[64];
	GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

	int iTarget = -1;
	if ((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;

	EUnbanClient(iTarget, iClient);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Transfer a special weapon from a iClient to another
//----------------------------------------------------------------------------------------------------
public Action Command_Transfer(int iClient, int iArgs)
{
	if (iArgs != 2)
	{
		CReplyToCommand(iClient, "\x07%s[entWatch] \x07%sUsage: sm_etransfer <owner> <receiver>", color_tag, color_warning);
		return Plugin_Handled;
	}

	bool bFoundWeapon = false;
	int iEntityIndex = -1,
		iWeaponCount = 0,
		iTarget = -1,
		iReceiver = -1;

	char sTarget_argument[64], sReceiver_argument[64];
	GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));
	GetCmdArg(2, sReceiver_argument, sizeof(sReceiver_argument));

	if ((iReceiver = FindTarget(iClient, sReceiver_argument, false)) == -1) return Plugin_Handled;

	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		if (sTarget_argument[0] == '$')
		{
			strcopy(sTarget_argument, sizeof(sTarget_argument), sTarget_argument[1]);

			for (int i = 0; i < entArraySize; i++)
			{
				if (strcmp(sTarget_argument, entArray[i][ent_name], false) == 0 || strcmp(sTarget_argument, entArray[i][ent_shortname], false) == 0)
				{
					iWeaponCount++;
					bFoundWeapon = true;
					iEntityIndex = i;
				}
			}
		} else {
			iTarget = FindTarget(iClient, sTarget_argument, false);

			if (iTarget != -1)
			{
				if (GetClientTeam(iTarget) != GetClientTeam(iReceiver))
				{
					CPrintToChat(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "The receivers team differs from the targets team");
					return Plugin_Handled;
				}

				for (int index = 0; index < entArraySize; index++)
				{
					if (entArray[index][ent_ownerid] != -1 
					&& entArray[index][ent_ownerid] == iTarget 
					&& entArray[index][ent_allowtransfer] 
					&& IsValidEdict(entArray[index][ent_weaponid]))
					{
						char sBuffer_classname[64];
						GetEdictClassname(entArray[index][ent_weaponid], sBuffer_classname, sizeof(sBuffer_classname));

						CS_DropWeapon(iTarget, entArray[index][ent_weaponid], false);
						GivePlayerItem(iTarget, sBuffer_classname);

						if (entArray[index][ent_chat])
						{
							entArray[index][ent_chat] = false;
							FixedEquipPlayerWeapon(iReceiver, entArray[index][ent_weaponid]);
							entArray[index][ent_chat] = true;
						} else FixedEquipPlayerWeapon(iReceiver, entArray[index][ent_weaponid]);

						CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iClient, color_warning, "transfered all items", color_name, iTarget, color_warning, "tai to", color_name, iReceiver);
						LogAction(iClient, iTarget, "\"%L\" transfered all items from \"%L\" to \"%L\"", iClient, iTarget, iReceiver);
						return Plugin_Handled;
					}
				}
			} else return Plugin_Handled;
		}
	}

	if (iWeaponCount > 1)
	{
		Menu hEdictMenu = CreateMenu(EdictMenu_Handler);
		char sMenuTemp[64], sIndexTemp[16];
		int iHeldCount = 0;
		char sMenuTranslate[128];
		Format(sMenuTranslate, sizeof(sMenuTranslate), "[entWatch] %T:", "Edict targets", iClient);
		hEdictMenu.SetTitle(sMenuTranslate);

		for (int i = 0; i < entArraySize; i++)
		{
			if (strcmp(sTarget_argument, entArray[i][ent_name], false) == 0 || strcmp(sTarget_argument, entArray[i][ent_shortname], false) == 0)
			{
				if (entArray[i][ent_allowtransfer] && entArray[i][ent_ownerid] != -1)
				{
					IntToString(i, sIndexTemp, sizeof(sIndexTemp));
					Format(sMenuTemp, sizeof(sMenuTemp), "%s | %N (#%i)", entArray[i][ent_name], entArray[i][ent_ownerid], GetClientUserId(entArray[i][ent_ownerid]));
					hEdictMenu.AddItem(sIndexTemp, sMenuTemp, ITEMDRAW_DEFAULT);
					iHeldCount++;
				}
			}
		}

		switch(iHeldCount) {
			case 1: {
				iEntityIndex = StringToInt(sIndexTemp);
	
				if (entArray[iEntityIndex][ent_allowtransfer])
				{
					if (entArray[iEntityIndex][ent_ownerid] != -1)
					{
						if (IsValidEdict(entArray[iEntityIndex][ent_weaponid]))
						{
							int iCurOwner = entArray[iEntityIndex][ent_ownerid];
	
							if (GetClientTeam(iReceiver) != GetClientTeam(iCurOwner))
							{
								CPrintToChat(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "The receivers team differs from the targets team");
								delete hEdictMenu;
								return Plugin_Handled;
							}
	
							char sBuffer_classname[64];
							GetEdictClassname(entArray[iEntityIndex][ent_weaponid], sBuffer_classname, sizeof(sBuffer_classname));
	
							CS_DropWeapon(iCurOwner, entArray[iEntityIndex][ent_weaponid], false);
							GivePlayerItem(iCurOwner, sBuffer_classname);
	
							if (entArray[iEntityIndex][ent_chat])
							{
								entArray[iEntityIndex][ent_chat] = false;
								FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
								entArray[iEntityIndex][ent_chat] = true;
							} else FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
	
							CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iClient, color_warning, "transfered all items", color_name, iCurOwner, color_warning, "tai to", color_name, iReceiver);
	
							LogAction(iClient, iCurOwner, "\"%L\" transfered all items from \"%L\" to \"%L\"", iClient, iCurOwner, iReceiver);
						}
					} else CPrintToChat(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Target is not valid");
				}
	
				delete(hEdictMenu);
			}
		}
		if (iHeldCount >= 2)
		{
			g_iAdminMenuTarget[iClient] = iReceiver;
			hEdictMenu.Display(iClient, MENU_TIME_FOREVER);
		} else {
			CPrintToChat(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "No one is currently holding that item");
			delete hEdictMenu;
		}
	}
	else
	{
		if (entArray[iEntityIndex][ent_allowtransfer])
		{
			if (entArray[iEntityIndex][ent_ownerid] != -1)
			{
				if (IsValidEdict(entArray[iEntityIndex][ent_weaponid]))
				{
					int iCurOwner = entArray[iEntityIndex][ent_ownerid];

					char sBuffer_classname[64];
					GetEdictClassname(entArray[iEntityIndex][ent_weaponid], sBuffer_classname, sizeof(sBuffer_classname));

					CS_DropWeapon(iCurOwner, entArray[iEntityIndex][ent_weaponid], false);
					GivePlayerItem(iCurOwner, sBuffer_classname);

					if (entArray[iEntityIndex][ent_chat])
					{
						entArray[iEntityIndex][ent_chat] = false;
						FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
						entArray[iEntityIndex][ent_chat] = true;
					} else FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);

					bFoundWeapon = true;
					CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iClient, color_warning, "transfered all items", color_name, iCurOwner, color_warning, "tai to", color_name, iReceiver);
					LogAction(iClient, iCurOwner, "\"%L\" transfered all items from \"%L\" to \"%L\"", iClient, iCurOwner, iReceiver);
				}
			}
			else
			{
				int iEntity = Entity_GetEntityFromHammerID(entArray[iEntityIndex][ent_hammerid]);

				if (entArray[iEntityIndex][ent_chat])
				{
					entArray[iEntityIndex][ent_chat] = false;
					FixedEquipPlayerWeapon(iReceiver, iEntity);
					entArray[iEntityIndex][ent_chat] = true;
				} else FixedEquipPlayerWeapon(iReceiver, iEntity);

				bFoundWeapon = true;
				CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%s \x07%s%t \x07%s%N", color_tag, color_name, iClient, color_warning, "transfered", entArray[iEntityIndex][ent_color], entArray[iEntityIndex][ent_name], color_warning, "tai to", color_name, iReceiver);
				LogAction(iClient, -1, "\"%L\" transfered \"%s\" to \"%L\"", iClient, entArray[iEntityIndex][ent_name], iReceiver);
			}
		}
	}
	if (!bFoundWeapon) CPrintToChat(iClient, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Invalid item name");
	return Plugin_Handled;
}

public int EdictMenu_Handler(Menu hEdictMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_End:delete hEdictMenu;
		case MenuAction_Select:
		{
			char sSelected[32];
			GetMenuItem(hEdictMenu, iParam2, sSelected, sizeof(sSelected));
			int iEntityIndex = StringToInt(sSelected);
			int iReceiver = g_iAdminMenuTarget[iParam1];

			switch(iReceiver){
				case 0: {
					CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Receiver is not valid anymore");
					return;
				}
			}

			if (entArray[iEntityIndex][ent_allowtransfer])
			{
				if (entArray[iEntityIndex][ent_ownerid] != -1)
				{
					if (IsValidEdict(entArray[iEntityIndex][ent_weaponid]))
					{
						int iCurOwner = entArray[iEntityIndex][ent_ownerid];

						if (GetClientTeam(iReceiver) != GetClientTeam(iCurOwner))
						{
							CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "The receivers team differs from the targets team");
							return;
						}

						char sBuffer_classname[64];
						GetEdictClassname(entArray[iEntityIndex][ent_weaponid], sBuffer_classname, sizeof(sBuffer_classname));

						CS_DropWeapon(iCurOwner, entArray[iEntityIndex][ent_weaponid], false);
						GivePlayerItem(iCurOwner, sBuffer_classname);

						if (entArray[iEntityIndex][ent_chat])
						{
							entArray[iEntityIndex][ent_chat] = false;
							FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);
							entArray[iEntityIndex][ent_chat] = true;
						} else FixedEquipPlayerWeapon(iReceiver, entArray[iEntityIndex][ent_weaponid]);

						CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%s%t \x07%s%N \x07%s%t \x07%s%N", color_tag, color_name, iParam1, color_warning, "transfered all items", color_name, iCurOwner, color_warning, "tai to", color_name, iReceiver);
						LogAction(iParam1, iCurOwner, "\"%L\" transfered all items from \"%L\" to \"%L\"", iParam1, iCurOwner, iReceiver);
					}
				} else CPrintToChat(iParam1, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "Item is not valid anymore");
			}
		}
	}
}

public Action Command_DebugArray(int iClient, int iArgs)
{
	if (g_bConfigLoaded && !g_bRoundTransition)
	{
		for (int i = 0; i < entArraySize; i++) {
			CreateTimer(i*0.05, Debug_Timer, i);
		}
	} else CReplyToCommand(iClient, "\x07%s[entWatch] \x07%sConfig file has not yet loaded or the round is transitioning.", color_tag, color_warning);

	return Plugin_Handled;
}

public Action Debug_Timer(Handle timer, int i)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
			CReplyToCommand(iClient, "\x07%s[entWatch] \x07%sInfo at \x07%sindex \x04%i\x07%s: \x07%sWeaponID \x04%i\x07%s | \x07%sOwnerID \x04%i\x07%s | \x07%sHammerID \x04%i\x07%s | \x07%sName\x07%s \"\x04%s\x07%s\" | \x07%sShortName\x07%s \"\x04%s\x07%s\"", color_tag, color_warning, color_pickup, i, color_warning, color_pickup, entArray[i][ent_weaponid], color_warning, color_pickup, entArray[i][ent_ownerid], color_warning, color_pickup, entArray[i][ent_hammerid], color_warning, color_pickup, color_warning, entArray[i][ent_name], color_warning, color_pickup, color_warning, entArray[i][ent_shortname], color_warning);
	}
	CReplyToCommand(0, "\x07%s[entWatch] \x07%sInfo at \x07%sindex \x04%i\x07%s: \x07%sWeaponID \x04%i\x07%s | \x07%sOwnerID \x04%i\x07%s | \x07%sHammerID \x04%i\x07%s | \x07%sName\x07%s \"\x04%s\x07%s\" | \x07%sShortName\x07%s \"\x04%s\x07%s\"", color_tag, color_warning, color_pickup, i, color_warning, color_pickup, entArray[i][ent_weaponid], color_warning, color_pickup, entArray[i][ent_ownerid], color_warning, color_pickup, entArray[i][ent_hammerid], color_warning, color_pickup, color_warning, entArray[i][ent_name], color_warning, color_pickup, color_warning, entArray[i][ent_shortname], color_warning);
}


void CleanData()
{
	for (int index = 0; index < entArraySize; index++)
	{
		FormatEx(entArray[index][ent_name],         32, "");
		FormatEx(entArray[index][ent_shortname],    32, "");
		FormatEx(entArray[index][ent_color],        32, "");
		FormatEx(entArray[index][ent_buttonclass],  32, "");
		FormatEx(entArray[index][ent_filtername],   32, "");
		entArray[index][ent_hasfiltername]  = false;
		entArray[index][ent_blockpickup]    = false;
		entArray[index][ent_allowtransfer]  = false;
		entArray[index][ent_forcedrop]      = false;
		entArray[index][ent_chat]           = false;
		entArray[index][ent_hud]            = false;
		entArray[index][ent_hammerid]       = -1;
		entArray[index][ent_weaponid]       = -1;
		entArray[index][ent_buttonid]       = -1;
		entArray[index][ent_ownerid]        = -1;
		entArray[index][ent_mode]           = 0;
		entArray[index][ent_uses]           = 0;
		entArray[index][ent_maxuses]        = 0;
		entArray[index][ent_cooldown]       = 0;
		entArray[index][ent_cooldowntime]   = -1;
		entArray[index][ent_glowent]		= -1;
		entArray[index][ent_glow_r]         = 255;
		entArray[index][ent_glow_g]         = 255;
		entArray[index][ent_glow_b]         = 255;
	}

	for (int index = 0; index < triggerSize; index++) triggerArray[index] = 0;

	entArraySize = 0;
	triggerSize = 0;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Load color settings
//----------------------------------------------------------------------------------------------------
stock void LoadColors()
{
	Handle hKeyValues = CreateKeyValues("colors");
	char sBuffer_config[128];
	char sBuffer_path[PLATFORM_MAX_PATH];
	char sBuffer_temp[16];

	GetConVarString(g_hCvar_ConfigColor, sBuffer_config, sizeof(sBuffer_config));
	FormatEx(sBuffer_path, sizeof(sBuffer_path), "cfg/sourcemod/entwatch/colors/%s.cfg", sBuffer_config);
	FileToKeyValues(hKeyValues, sBuffer_path);

	KvRewind(hKeyValues);

	KvGetString(hKeyValues, "color_tag", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_tag, sizeof(color_tag), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_name", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_name, sizeof(color_name), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_steamid", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_steamid, sizeof(color_steamid), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_use", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_use, sizeof(color_use), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_pickup", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_pickup, sizeof(color_pickup), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_drop", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_drop, sizeof(color_drop), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_disconnect", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_disconnect, sizeof(color_disconnect), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_death", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_death, sizeof(color_death), "%s", sBuffer_temp);

	KvGetString(hKeyValues, "color_warning", sBuffer_temp, sizeof(sBuffer_temp));
	FormatEx(color_warning, sizeof(color_warning), "%s", sBuffer_temp);
	
	KvGetString(hKeyValues, "color_hud_red", sBuffer_temp, sizeof(sBuffer_temp), "255");
	g_DefaultHudColor[0] = StringToInt(sBuffer_temp);
	
	KvGetString(hKeyValues, "color_hud_green", sBuffer_temp, sizeof(sBuffer_temp), "255");
	g_DefaultHudColor[1] = StringToInt(sBuffer_temp);
	
	KvGetString(hKeyValues, "color_hud_blue", sBuffer_temp, sizeof(sBuffer_temp), "255");
	g_DefaultHudColor[2] = StringToInt(sBuffer_temp);
	
	KvGetString(hKeyValues, "color_hud_posx", sBuffer_temp, sizeof(sBuffer_temp), "0.0");
	g_DefaultHudPos[0] = StringToFloat(sBuffer_temp);
	
	KvGetString(hKeyValues, "color_hud_posy", sBuffer_temp, sizeof(sBuffer_temp), "0.4");
	g_DefaultHudPos[1] = StringToFloat(sBuffer_temp);
	
	delete hKeyValues;
}

//----------------------------------------------------------------------------------------------------
// Purpose: Load configurations
//----------------------------------------------------------------------------------------------------
stock void LoadConfig()
{
	Handle hKeyValues = CreateKeyValues("entities");
	char sBuffer_map[128], sBuffer_path[PLATFORM_MAX_PATH], sBuffer_path_override[PLATFORM_MAX_PATH], sBuffer_temp[32];
	int sBuffer_amount;

	GetCurrentMap(sBuffer_map, sizeof(sBuffer_map));
	FormatEx(sBuffer_path, sizeof(sBuffer_path), "cfg/sourcemod/entwatch/maps/%s.cfg", sBuffer_map);
	FormatEx(sBuffer_path_override, sizeof(sBuffer_path_override), "cfg/sourcemod/entwatch/maps/%s_override.cfg", sBuffer_map);
	if (FileExists(sBuffer_path_override)) {
		FileToKeyValues(hKeyValues, sBuffer_path_override);
		LogMessage("Loading %s", sBuffer_path_override);
	} else {
		FileToKeyValues(hKeyValues, sBuffer_path);
		LogMessage("Loading %s", sBuffer_path);
	}

	KvRewind(hKeyValues);
	if (KvGotoFirstSubKey(hKeyValues))
	{
		g_bConfigLoaded = true;
		entArraySize = 0;
		triggerSize = 0;

		do
		{
			KvGetString(hKeyValues, "maxamount", sBuffer_temp, sizeof(sBuffer_temp));
			sBuffer_amount = StringToInt(sBuffer_temp);

			for (int i = 0; i < sBuffer_amount; i++)
			{
				KvGetString(hKeyValues, "name", sBuffer_temp, sizeof(sBuffer_temp));
				FormatEx(entArray[entArraySize][ent_name], 32, "%s", sBuffer_temp);

				KvGetString(hKeyValues, "shortname", sBuffer_temp, sizeof(sBuffer_temp));
				FormatEx(entArray[entArraySize][ent_shortname], 32, "%s", sBuffer_temp);

				KvGetString(hKeyValues, "color", sBuffer_temp, sizeof(sBuffer_temp));
				FormatEx(entArray[entArraySize][ent_color], 32, "%s", sBuffer_temp);
				entArray[entArraySize][ent_glow_r]=255;
				entArray[entArraySize][ent_glow_g]=255;
				entArray[entArraySize][ent_glow_b]=255;
				if(StrEqual(sBuffer_temp,"{green}",false)){entArray[entArraySize][ent_glow_r]=0;entArray[entArraySize][ent_glow_g]=255;entArray[entArraySize][ent_glow_b]=0;}
				if(StrEqual(sBuffer_temp,"{default}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=255;entArray[entArraySize][ent_glow_b]=255;}
				if(StrEqual(sBuffer_temp,"{darkred}",false)){entArray[entArraySize][ent_glow_r]=140;entArray[entArraySize][ent_glow_g]=0;entArray[entArraySize][ent_glow_b]=0;}
				if(StrEqual(sBuffer_temp,"{purple}",false)){entArray[entArraySize][ent_glow_r]=128;entArray[entArraySize][ent_glow_g]=0;entArray[entArraySize][ent_glow_b]=128;}
				if(StrEqual(sBuffer_temp,"{lightgreen}",false)){entArray[entArraySize][ent_glow_r]=144;entArray[entArraySize][ent_glow_g]=238;entArray[entArraySize][ent_glow_b]=144;}
				if(StrEqual(sBuffer_temp,"{lime}",false)){entArray[entArraySize][ent_glow_r]=199;entArray[entArraySize][ent_glow_g]=234;entArray[entArraySize][ent_glow_b]=7;}
				if(StrEqual(sBuffer_temp,"{red}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=0;entArray[entArraySize][ent_glow_b]=0;}
				if(StrEqual(sBuffer_temp,"{grey}",false)){entArray[entArraySize][ent_glow_r]=128;entArray[entArraySize][ent_glow_g]=128;entArray[entArraySize][ent_glow_b]=128;}
				if(StrEqual(sBuffer_temp,"{olive}",false)){entArray[entArraySize][ent_glow_r]=112;entArray[entArraySize][ent_glow_g]=130;entArray[entArraySize][ent_glow_b]=56;}
				if(StrEqual(sBuffer_temp,"{a}",false)){entArray[entArraySize][ent_glow_r]=192;entArray[entArraySize][ent_glow_g]=192;entArray[entArraySize][ent_glow_b]=192;}
				if(StrEqual(sBuffer_temp,"{lightblue}",false)){entArray[entArraySize][ent_glow_r]=173;entArray[entArraySize][ent_glow_g]=216;entArray[entArraySize][ent_glow_b]=230;}
				if(StrEqual(sBuffer_temp,"{blue}",false)){entArray[entArraySize][ent_glow_r]=0;entArray[entArraySize][ent_glow_g]=0;entArray[entArraySize][ent_glow_b]=255;}
				if(StrEqual(sBuffer_temp,"{d}",false)){entArray[entArraySize][ent_glow_r]=102;entArray[entArraySize][ent_glow_g]=153;entArray[entArraySize][ent_glow_b]=204;}
				if(StrEqual(sBuffer_temp,"{pink}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=105;entArray[entArraySize][ent_glow_b]=180;}
				if(StrEqual(sBuffer_temp,"{darkorange}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=140;entArray[entArraySize][ent_glow_b]=0;}
				if(StrEqual(sBuffer_temp,"{orange}",false)){entArray[entArraySize][ent_glow_r]=240;entArray[entArraySize][ent_glow_g]=94;entArray[entArraySize][ent_glow_b]=35;}
				if(StrEqual(sBuffer_temp,"{white}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=255;entArray[entArraySize][ent_glow_b]=255;}
				if(StrEqual(sBuffer_temp,"{yellow}",false)){entArray[entArraySize][ent_glow_r]=112;entArray[entArraySize][ent_glow_g]=130;entArray[entArraySize][ent_glow_b]=56;}
				if(StrEqual(sBuffer_temp,"{magenta}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=105;entArray[entArraySize][ent_glow_b]=180;}
				if(StrEqual(sBuffer_temp,"{silver}",false)){entArray[entArraySize][ent_glow_r]=192;entArray[entArraySize][ent_glow_g]=192;entArray[entArraySize][ent_glow_b]=192;}
				if(StrEqual(sBuffer_temp,"{bluegrey}",false)){entArray[entArraySize][ent_glow_r]=102;entArray[entArraySize][ent_glow_g]=153;entArray[entArraySize][ent_glow_b]=204;}
				if(StrEqual(sBuffer_temp,"{lightred}",false)){entArray[entArraySize][ent_glow_r]=255;entArray[entArraySize][ent_glow_g]=90;entArray[entArraySize][ent_glow_b]=0;}
				if(StrEqual(sBuffer_temp,"{cyan}",false)){entArray[entArraySize][ent_glow_r]=0;entArray[entArraySize][ent_glow_g]=150;entArray[entArraySize][ent_glow_b]=220;}
				if(StrEqual(sBuffer_temp,"{gray}",false)){entArray[entArraySize][ent_glow_r]=128;entArray[entArraySize][ent_glow_g]=128;entArray[entArraySize][ent_glow_b]=128;}
				

				KvGetString(hKeyValues, "buttonclass", sBuffer_temp, sizeof(sBuffer_temp));
				FormatEx(entArray[entArraySize][ent_buttonclass], 32, "%s", sBuffer_temp);

				KvGetString(hKeyValues, "filtername", sBuffer_temp, sizeof(sBuffer_temp));
				FormatEx(entArray[entArraySize][ent_filtername], 32, "%s", sBuffer_temp);

				KvGetString(hKeyValues, "hasfiltername", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_hasfiltername] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "blockpickup", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_blockpickup] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "allowtransfer", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_allowtransfer] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "forcedrop", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_forcedrop] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "chat", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_chat] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "hud", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_hud] = StrEqual(sBuffer_temp, "true", false);

				KvGetString(hKeyValues, "hammerid", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_hammerid] = StringToInt(sBuffer_temp);

				KvGetString(hKeyValues, "mode", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_mode] = StringToInt(sBuffer_temp);

				KvGetString(hKeyValues, "maxuses", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_maxuses] = StringToInt(sBuffer_temp);

				KvGetString(hKeyValues, "cooldown", sBuffer_temp, sizeof(sBuffer_temp));
				entArray[entArraySize][ent_cooldown] = StringToInt(sBuffer_temp);

				KvGetString(hKeyValues, "trigger", sBuffer_temp, sizeof(sBuffer_temp));

				int tindex = StringToInt(sBuffer_temp);
				if(tindex)
				{
					triggerArray[triggerSize] = tindex;
					triggerSize++;
				}

				entArraySize++;
			}
		}
		while (KvGotoNextKey(hKeyValues));
	} else {
		g_bConfigLoaded = false;
		LogMessage("Could not load %s", sBuffer_path);
	}

	delete hKeyValues;
}

//----------------------------------------------------------------------------------------------------
// Purpose: init Glow weapon on Drop weapons
//----------------------------------------------------------------------------------------------------
stock void GlowWeapon(int index)
{
	if(g_bGlow)
	{
		if (!IsValidEdict(entArray[index][ent_glowent]))
		{
			char sModelPath[PLATFORM_MAX_PATH];
			float fWOrigin[3], fWAngle[3];

			// Get the original model path
			GetEntPropString(entArray[index][ent_weaponid], Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
			ReplaceString(sModelPath, sizeof(sModelPath), "_dropped", "", false);
			
			// Find the location of the weapon
			GetEntPropVector(entArray[index][ent_weaponid], Prop_Send, "m_vecOrigin", fWOrigin);
			GetEntPropVector(entArray[index][ent_weaponid], Prop_Send, "m_angRotation", fWAngle);

			// Create & set dynamic glow entity and give properties
			entArray[index][ent_glowent] = CreateEntityByName("prop_dynamic_glow");
			
			DispatchKeyValue(entArray[index][ent_glowent], "model", sModelPath);
			DispatchKeyValue(entArray[index][ent_glowent], "disablereceiveshadows", "1");
			DispatchKeyValue(entArray[index][ent_glowent], "disableshadows", "1");
			DispatchKeyValue(entArray[index][ent_glowent], "solid", "0");
			DispatchKeyValue(entArray[index][ent_glowent], "spawnflags", "256");
			SetEntProp(entArray[index][ent_glowent], Prop_Send, "m_CollisionGroup", 11);
			
			//Fix Origin
			fWOrigin[0]-=Cosine(DegToRad(fWAngle[1]))*5;
			fWOrigin[1]-=Cosine(DegToRad(fWAngle[1]-90))*5;
			
			// Spawn and teleport the entity
			DispatchSpawn(entArray[index][ent_glowent]);
			TeleportEntity(entArray[index][ent_glowent], fWOrigin, fWAngle, NULL_VECTOR);

			// Give glowing effect to the entity
			SetEntProp(entArray[index][ent_glowent], Prop_Send, "m_bShouldGlow", true, true);
			SetEntPropFloat(entArray[index][ent_glowent], Prop_Send, "m_flGlowMaxDist", 10000000.0);

			// Set glowing color
			int color_glow[4];
			color_glow[0]=entArray[index][ent_glow_r];
			color_glow[1]=entArray[index][ent_glow_g];
			color_glow[2]=entArray[index][ent_glow_b];
			color_glow[3]=200;
			SetVariantColor(color_glow);
			AcceptEntityInput(entArray[index][ent_glowent], "SetGlowColor");

			// Set the activator and group the entity
			SetVariantString("!activator");
			AcceptEntityInput(entArray[index][ent_glowent], "SetParent", entArray[index][ent_weaponid]);

			AcceptEntityInput(entArray[index][ent_glowent], "TurnOn");
			AcceptEntityInput(entArray[index][ent_glowent], "SetGlowEnabled");
		} else 
		{
			AcceptEntityInput(entArray[index][ent_glowent], "TurnOn");
			AcceptEntityInput(entArray[index][ent_glowent], "SetGlowEnabled");
		}
	}
}
//----------------------------------------------------------------------------------------------------
// Purpose: Disable glow
//----------------------------------------------------------------------------------------------------
stock void DisableGlow(int index) {
	if(g_bGlow)
	{
		if (IsValidEdict(entArray[index][ent_glowent]))
		{
			AcceptEntityInput(entArray[index][ent_glowent], "SetGlowDisabled");
			AcceptEntityInput(entArray[index][ent_glowent], "TurnOff");
		}
	}
}


public Action Command_ReloadConfig(int iClient, int iArgs)
{
	CleanData();
	LoadColors();
	LoadConfig();

	return Plugin_Handled;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (triggerSize > 0 && StrContains(sClassname, "trigger_", false) != -1 && IsValidEntity(iEntity)) SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	if (StrContains(sClassname, "weapon_", false) != -1 && IsValidEntity(iEntity) && isMapRunning) SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned2);
}

public void OnEntitySpawned2(int iEntity)
{
	int iHammerID = GetEntProp(iEntity, Prop_Data, "m_iHammerID");
	for (int index = 0; index < entArraySize; index++)
	{
		if ((entArray[index][ent_hammerid] == iHammerID)  && ((entArray[index][ent_weaponid] == -1) || (!IsValidEntity(entArray[index][ent_weaponid]))))
		{
			//LogMessage("Found Item HammerID:%i EntityID:%i", iHammerID, iEntity);
			entArray[index][ent_weaponid] = iEntity;
			entArray[index][ent_glowent] = -1;
			GlowWeapon(index);
			if (entArray[index][ent_buttonid] == -1 && entArray[index][ent_mode] != 0)
			{
				char sBuffer_targetname[32];
				Entity_GetTargetName(iEntity, sBuffer_targetname, sizeof(sBuffer_targetname));

				int iButton = -1;
				while ((iButton = FindEntityByClassname(iButton, entArray[index][ent_buttonclass])) != -1)
				{
					if (IsValidEdict(iButton))
					{
						char sBuffer_parentname[32];
						Entity_GetParentName(iButton, sBuffer_parentname, sizeof(sBuffer_parentname));

						if (StrEqual(sBuffer_targetname, sBuffer_parentname))
						{
							SDKHookEx(iButton, SDKHook_Use, OnButtonUse);
							entArray[index][ent_buttonid] = iButton;
							break;
						}
					}
				}
			}
			break;
		}
	}
}

public void OnEntitySpawned(int iEntity)
{
	char sClassname[32];
	if(Entity_GetClassName(iEntity, sClassname, sizeof(sClassname)))
	{
		if (IsValidEntity(iEntity) && StrContains(sClassname, "trigger_", false) != -1)
		{
			int iHid = Entity_GetHammerID(iEntity);
			for (int index = 0; index < triggerSize; index++)
			{
				if (iHid == triggerArray[index]) {
					SDKHookEx(iEntity, SDKHook_Touch, OnTrigger);
					SDKHookEx(iEntity, SDKHook_EndTouch, OnTrigger);
					SDKHookEx(iEntity, SDKHook_StartTouch, OnTrigger);
				}
			}
		}
	}
}

public Action Command_Cooldown(int iClient, int iArgs)
{
	if (iArgs != 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_setcooldown <hammerid> <cooldown>");
		return Plugin_Handled;
	}

	char sHid[32], sCooldown[10];

	GetCmdArg(1, sHid, sizeof(sHid));
	GetCmdArg(2, sCooldown, sizeof(sCooldown));

	int iHammerid = StringToInt(sHid);

	for (int index = 0; index < entArraySize; index++) {
		if (entArray[index][ent_hammerid] == iHammerid) entArray[index][ent_cooldown] = StringToInt(sCooldown);
	}

	return Plugin_Handled;
}

public Action OnTrigger(int iEntity, int iOther)
{
    if (MaxClients >= iOther && 0 < iOther) {
    	if (IsClientConnected(iOther)) {
    		if (g_bRestricted[iOther]) return Plugin_Handled;

			else if (g_iRestrictedLength[iOther] != 1 && g_iRestrictedLength[iOther] != 0 && g_iRestrictedLength[iOther] <= GetTime())
			{
				g_iRestrictedLength[iOther] = 0;
				SetClientCookie(iOther, g_hCookie_RestrictedLength, "0");
				return Plugin_Continue;
			}

			else if (g_iRestrictedLength[iOther] > GetTime() || g_iRestrictedLength[iOther] == 1) return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

bool SingularOrMultiple(int iNum) {
	if (iNum > 1 || iNum == 0) return true;
	return false;
}

public int Native_IsClientBanned(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client/client is not in game or client cookies are not yet loaded");
		return false;
	}

	char sBuff[64];
	GetClientCookie(iClient, g_hCookie_RestrictedLength, sBuff, sizeof(sBuff));
	int iBanLen = StringToInt(sBuff);

	if ((iBanLen != 0 && iBanLen >= GetTime()) || iBanLen == 1)
	{
		SetNativeCellRef(2, iBanLen);
		return true;
	}

	return true;
}

public int Native_BanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);
	bool bIsTemporary = GetNativeCell(2);
	int iBanLen = GetNativeCell(3);

	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient/iClient is not in game or client cookies are not yet loaded");
		return false;
	}

	if (bIsTemporary)
	{
		EBanClient(iClient, "0", 0);
		return true;
	}

	if (iBanLen != 0)
	{
		iBanLen = GetTime() + (iBanLen * 60);
		if (iBanLen <= GetTime())
		{
			ThrowNativeError(SP_ERROR_PARAM, "Invalid ban length given");
			return false;
		}
	} else {
		EBanClient(iClient, "1", 0);
		return true;
	}

	char sBanLen[64];
	FormatEx(sBanLen, sizeof(sBanLen), "%d", iBanLen);

	EBanClient(iClient, sBanLen, 0);
	return true;
}

public int Native_UnbanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client/client is not in game or client cookies are not yet loaded");
		return false;
	}

	EUnbanClient(iClient, 0);

	return true;
}

public int Native_IsSpecialItem(Handle hPlugin, int iArgC)
{
	int entity = GetNativeCell(1);
	if (!g_bConfigLoaded || entity < MaxClients || !IsValidEdict(entity) || !IsValidEntity(entity)) return false;

	for (int index = 0; index < entArraySize; index++) {
		if (entArray[index][ent_buttonid] == entity) return true;
	}

	return false;
}

public int Native_HasSpecialItem(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);

	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient/iClient is not in game");
		return false;
	}

	for (int index = 0; index < entArraySize; index++)
	{
		if (entArray[index][ent_ownerid] == iClient) return true;
	}

	return false;
}

stock void FixedEquipPlayerWeapon(int iClient, int iWeapon)
{
	int wSlot = GetSlotCSGO(iWeapon);
	if((wSlot>=0) && (wSlot<=2))
	{
		int TargetWInSlot = GetPlayerWeaponSlot(iClient, wSlot);
		if(TargetWInSlot != -1) CS_DropWeapon(iClient, TargetWInSlot, false);
		float iClientOrigin[3];
		GetClientAbsOrigin(iClient,iClientOrigin);
		TeleportEntity(iWeapon, iClientOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}

stock bool IsValidPlayer(int client){
	if (0 < client <= MaxClients && IsClientInGame(client)) return true;
	else return false;
}

public Action Timer_DisplayHUD(Handle timer, int client)
{
	//if (GameRules_GetProp("m_bWarmupPeriod") == 1)
	//	return Plugin_Continue;
	
	if (GetConVarBool(g_hCvar_DisplayEnabled))
	{
		if (g_bConfigLoaded && !g_bRoundTransition)
		{
			char buffer_teamtext[10][512];
			ItemIdx = 1 ;
			char buffer_hud[512];
			for (int index = 0; index < entArraySize; index++)
			{
				if (entArray[index][ent_hud] && entArray[index][ent_ownerid] != -1)
				{
					//128
					char buffer_temp[512];
					//13
					char buffer_name[64];
					if (GetConVarBool(g_hCvar_DisplayCooldowns))
					{
						if (entArray[index][ent_mode] == 2)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d]: ",entArray[index][ent_shortname], entArray[index][ent_cooldowntime]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%s]: ", entArray[index][ent_shortname],"R");
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else if (entArray[index][ent_mode] == 3)
						{
							if (entArray[index][ent_uses] < entArray[index][ent_maxuses])
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d/%d]: ", entArray[index][ent_shortname], entArray[index][ent_uses], entArray[index][ent_maxuses]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d/%d]: ", entArray[index][ent_shortname], entArray[index][ent_uses], entArray[index][ent_maxuses]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else if (entArray[index][ent_mode] == 4)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d]: ", entArray[index][ent_shortname], entArray[index][ent_cooldowntime]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								if (entArray[index][ent_uses] < entArray[index][ent_maxuses])
								{
									Format(buffer_temp, sizeof(buffer_temp), "%s[%d/%d]: ", entArray[index][ent_shortname], entArray[index][ent_uses], entArray[index][ent_maxuses]);
									Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
									if(GetClientTeam(entArray[index][ent_ownerid])==3)
									{
										ShowCools[ItemIdx] = buffer_temp;
										ShowCoolsPlayerName[ItemIdx] = buffer_name;
										ItemIdx++;
									}
								}
								else
								{
									Format(buffer_temp, sizeof(buffer_temp), "%s[%s]: ", entArray[index][ent_shortname], "D");
									Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
									if(GetClientTeam(entArray[index][ent_ownerid])==3)
									{
										ShowCools[ItemIdx] = buffer_temp;
										ShowCoolsPlayerName[ItemIdx] = buffer_name;
										ItemIdx++;
									}
								}
							}
						}
						else if (entArray[index][ent_mode] == 5)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d]: ", entArray[index][ent_shortname], entArray[index][ent_cooldowntime]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "%s[%d/%d]: ", entArray[index][ent_shortname], entArray[index][ent_uses], entArray[index][ent_maxuses]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(GetClientTeam(entArray[index][ent_ownerid])==3)
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else
						{
							Format(buffer_temp, sizeof(buffer_temp), "%s[%s]: ", entArray[index][ent_shortname], "N/A");
							Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
							if(GetClientTeam(entArray[index][ent_ownerid])==3)
							{
								ShowCools[ItemIdx] = buffer_temp;
								ShowCoolsPlayerName[ItemIdx] = buffer_name;
								ItemIdx++;
							}
						}
					}
					else
					{
						Format(buffer_temp, sizeof(buffer_temp), "%s: ", entArray[index][ent_shortname]);
						Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
						if(GetClientTeam(entArray[index][ent_ownerid])==3)
						{
							ShowCools[ItemIdx] = buffer_temp;
							ShowCoolsPlayerName[ItemIdx] = buffer_name;
							ItemIdx++;
						}
					}
					if (strlen(buffer_temp) + strlen(buffer_teamtext[GetClientTeam(entArray[index][ent_ownerid])]) <= sizeof(buffer_teamtext[]))
					{
						StrCat(buffer_teamtext[GetClientTeam(entArray[index][ent_ownerid])], sizeof(buffer_teamtext[]), buffer_temp);
					}
				}
			}
			
			for( int idx=1 ; idx <ItemIdx;idx++)
			{
				StrCat(buffer_hud,512,ShowCools[idx]);
				StrCat(buffer_hud,512,ShowCoolsPlayerName[idx]);
				if(idx != ItemIdx-1)
				{
					StrCat(buffer_hud,512,"\n");
				}
			}
			
			if(ItemIdx >= 2)
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsFakeClient(i))
					{
						if (g_bDisplay2[i])
						{
							if((HudPosition[i][0] < 0.0) || (HudPosition[i][1] < 0.0))
							{
								if((HudColor[i][0] < 0) || (HudColor[i][0] > 255) || (HudColor[i][1] < 0) || (HudColor[i][1] > 255) || (HudColor[i][2] < 0) || (HudColor[i][2] > 255))
								{
									SetHudTextParams(g_DefaultHudPos[0], g_DefaultHudPos[1], 1.1, g_DefaultHudColor[0], g_DefaultHudColor[1], g_DefaultHudColor[2], 255, 0, 0.0, 0.0, 0.0);
								} else 
								{
									SetHudTextParams(g_DefaultHudPos[0], g_DefaultHudPos[1], 1.1, HudColor[i][0], HudColor[i][1], HudColor[i][2], 255, 0, 0.0, 0.0, 0.0);
								}
							}
							else
							{
								if((HudColor[i][0] < 0) || (HudColor[i][0] > 255) || (HudColor[i][1] < 0) || (HudColor[i][1] > 255) || (HudColor[i][2] < 0) || (HudColor[i][2] > 255))
								{
									SetHudTextParams(HudPosition[i][0], HudPosition[i][1], 1.1, g_DefaultHudColor[0], g_DefaultHudColor[1], g_DefaultHudColor[2], 255, 0, 0.0, 0.0, 0.0);
								} else 
								{
									SetHudTextParams(HudPosition[i][0], HudPosition[i][1], 1.1, HudColor[i][0], HudColor[i][1], HudColor[i][2], 255, 0, 0.0, 0.0, 0.0);
								}
							}
							#if defined DYNAMIC_CHANNELS
							ShowHudText(i, GetDynamicChannel(g_iHUDChannel), buffer_hud);
							#else
							ShowHudText(i, g_iHUDChannel, buffer_hud);
							#endif
						}
					}
				}
			}
			else if(ItemIdx <= 1)
			{
				return Plugin_Continue;
			}
			for (int ply = 1; ply <= MaxClients; ply++)
			{
				if (IsClientConnected(ply) && IsClientInGame(ply))
				{
					if (g_bDisplay[ply])
					{
						char buffer_text[512];
						
						for (int teamid = 0; teamid < sizeof(buffer_teamtext); teamid++)
						{
							if (!GetConVarBool(g_hCvar_ModeTeamOnly) || (GetConVarBool(g_hCvar_ModeTeamOnly) && GetClientTeam(ply) == teamid || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								if (strlen(buffer_teamtext[teamid]) + strlen(buffer_text) <= sizeof(buffer_text))
								{
									StrCat(buffer_text, sizeof(buffer_text), buffer_teamtext[teamid]);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Command_Hudpos(int client, int args)
{
	if (GetCmdArgs() < 2)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_hudpos <x> <y>", color_tag, color_warning);
		return Plugin_Handled;
	}
	char buffer[128];
	float HudPosX_validate;
	float HudPosY_validate;
	GetCmdArg(1, buffer, sizeof(buffer));
	HudPosX_validate = StringToFloat(buffer);
	
	GetCmdArg(2, buffer, sizeof(buffer));
	HudPosY_validate = StringToFloat(buffer);
	
	if(HudPosX_validate >= 0.0 && HudPosY_validate >= 0.0)
	{
		HudPosition[client][0]=HudPosX_validate;
		HudPosition[client][1]=HudPosY_validate;
		char sBuffer_cookie[32];
		Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%f/%f", HudPosition[client][0], HudPosition[client][1]);
		SetClientCookie(client, g_hCookie_HudPos, sBuffer_cookie);
	} else 
	{
		CPrintToChat(client, "\x07%s[entWatch] \x03%t", color_tag, "hudpos_wrong");
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "\x07%s[entWatch] \x03%t", color_tag, "hudpos");
	
	return Plugin_Handled;
}

public Action Command_HudColor(int client, int args)
{
	if (GetCmdArgs() < 3)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_hudcolor <R> <G> <B>", color_tag, color_warning);
		return Plugin_Handled;
	}
	char buffer[128];
	int color_validate[3];
	GetCmdArg(1, buffer, sizeof(buffer));
	color_validate[0] = StringToInt(buffer);
	
	GetCmdArg(2, buffer, sizeof(buffer));
	color_validate[1] = StringToInt(buffer);
	
	GetCmdArg(3, buffer, sizeof(buffer));
	color_validate[2] = StringToInt(buffer);
	
	if((color_validate[0] >= 0) && (color_validate[0] <= 255) && (color_validate[1] >= 0) && (color_validate[1] <= 255) && (color_validate[2] >= 0) && (color_validate[2] <= 255))
	{
		HudColor[client][0]=color_validate[0];
		HudColor[client][1]=color_validate[1];
		HudColor[client][2]=color_validate[2];
		char sBuffer_cookie[32];
		Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%i/%i/%i", HudColor[client][0], HudColor[client][1], HudColor[client][2]);
		SetClientCookie(client, g_hCookie_HudColor, sBuffer_cookie);
	} else 
	{
		CPrintToChat(client, "\x07%s[entWatch] \x03%t", color_tag, "hudcolor_wrong");
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "\x07%s[entWatch] \x03%t", color_tag, "hudcolor");
	
	return Plugin_Handled;
}

public Action Command_ToggleHUD(int client, int args)
{
	if (g_bDisplay2[client])
	{
		CPrintToChat(client, "\x07%s[entWatch] \x0b%t", color_tag, "display disabled");
		g_bDisplay2[client] = false;
	}
	else
	{
		CPrintToChat(client, "\x07%s[entWatch] \x07%t", color_tag, "display enabled");
		g_bDisplay2[client] = true;
	}
	return Plugin_Handled;
}

stock int GetSlotCSGO(int eWeapon)
{
	/*Slots:
	Invalid/Unknown: -1
	Primary: 0
	Secondary: 1
	Melee(Knife): 2
	Projectile(Grenades): 3
	Explosive(c4): 4
	*/
	char wClassName[64];
	GetEntityClassname(eWeapon,wClassName,sizeof(wClassName));
	
	if((StrEqual(wClassName,"weapon_elite",false))||(StrEqual(wClassName,"weapon_deagle",false))||(StrEqual(wClassName,"weapon_fiveseven",false))||
		(StrEqual(wClassName,"weapon_glock",false))||(StrEqual(wClassName,"weapon_revolver",false))||(StrEqual(wClassName,"weapon_usp_silencer",false))||
		(StrEqual(wClassName,"weapon_cz75a",false))||(StrEqual(wClassName,"weapon_hkp2000",false))||(StrEqual(wClassName,"weapon_p250",false))||
		(StrEqual(wClassName,"weapon_tec9",false)))
	{
		return 1;
	} else if((StrEqual(wClassName,"weapon_knife",false))||(StrEqual(wClassName,"weapon_knifegg",false))||(StrEqual(wClassName,"weapon_taser",false))||
		(StrEqual(wClassName,"weapon_axe",false))||(StrEqual(wClassName,"weapon_hammer",false))||(StrEqual(wClassName,"weapon_spanner",false)))
	{
		return 2;
	} else if((StrEqual(wClassName,"weapon_decoy",false))||(StrEqual(wClassName,"weapon_flashbang",false))||(StrEqual(wClassName,"weapon_hegrenade",false))||
		(StrEqual(wClassName,"weapon_incgrenade",false))||(StrEqual(wClassName,"weapon_molotov",false))||(StrEqual(wClassName,"weapon_smokegrenade",false))||
		(StrEqual(wClassName,"weapon_tagrenade",false))||(StrEqual(wClassName,"weapon_diversion",false))||(StrEqual(wClassName,"weapon_snowball",false)))
	{
		return 3;
	} else if((StrEqual(wClassName,"weapon_ak47",false))||(StrEqual(wClassName,"weapon_aug",false))||(StrEqual(wClassName,"weapon_awp",false))||
		(StrEqual(wClassName,"weapon_bizon",false))||(StrEqual(wClassName,"weapon_famas",false))||(StrEqual(wClassName,"weapon_g3sg1",false))||
		(StrEqual(wClassName,"weapon_galilar",false))||(StrEqual(wClassName,"weapon_m4a1",false))||(StrEqual(wClassName,"weapon_m4a1_silencer",false))||
		(StrEqual(wClassName,"weapon_m249",false))||(StrEqual(wClassName,"weapon_negev",false))||(StrEqual(wClassName,"weapon_p90",false))||
		(StrEqual(wClassName,"weapon_scar20",false))||(StrEqual(wClassName,"weapon_ssg08",false))||(StrEqual(wClassName,"weapon_ump45",false))||
		(StrEqual(wClassName,"weapon_xm1014",false))||(StrEqual(wClassName,"weapon_mac10",false))||(StrEqual(wClassName,"weapon_mag7",false))||
		(StrEqual(wClassName,"weapon_mp7",false))||(StrEqual(wClassName,"weapon_mp9",false))||(StrEqual(wClassName,"weapon_nova",false))||
		(StrEqual(wClassName,"weapon_sawedoff",false))||(StrEqual(wClassName,"weapon_sg556",false)))
	{
		return 0;
	} else if((StrEqual(wClassName,"weapon_c4",false))||(StrEqual(wClassName,"weapon_breachcharge",false))||(StrEqual(wClassName,"weapon_bumpmine",false))||
		(StrEqual(wClassName,"weapon_healthshot",false))||(StrEqual(wClassName,"weapon_shield",false)))
	{
		return 4;
	} else return -1;
}
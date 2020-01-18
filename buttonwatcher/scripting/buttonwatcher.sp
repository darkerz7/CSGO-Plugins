#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors_csgo>
#include <clientprefs>
#include <entWatch>
#include <adminmenu>

#define MAX_EDICTS        2048

Handle g_hCookie_BBans  = null,
	g_hCookie_BBansLength = null,
	g_hCookie_BBansIssued = null,
	g_hCookie_BBansBy	  = null,
	g_hCookie_Buttons     = null;

bool g_bBBans[MAXPLAYERS + 1] = false;
char g_sBBansBy[MAXPLAYERS + 1][64];
int  g_iBBansLength[MAXPLAYERS + 1],
	g_iBBansIssued[MAXPLAYERS + 1];
	
bool g_bButtons[MAXPLAYERS + 1] = false;
	
Handle g_hAdminMenu;

int g_iAdminMenuTarget[MAXPLAYERS + 1];

ConVar g_hCvar_ButtonsEnabled;
bool g_bButtonsEnabled = true;

bool isMapRunning;

int g_aButtons[MAX_EDICTS],
	g_iMaxButtons = 0;

public Plugin:myinfo =
{
	name = "Button Watcher with BBans",
	author = "DarkerZ [RUS]",
	description = "Generates an output when a button is pressed and Bans Clients",
	version = "1.8",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("button_watcher.phrases");
	
	//Hooks
	HookEntityOutput("func_button", "OnPressed", PressBTN);
	HookEntityOutput("momentary_rot_button", "OnPressed", PressBTN);
	HookEntityOutput("func_rot_button", "OnPressed", PressBTN);
	
	//HookEventEx("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_Pre);
	
	//CVARs
	g_hCvar_ButtonsEnabled    = CreateConVar("sm_buttons_view", "1", "Enable/Disable Global the display Buttons.", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvar_ButtonsEnabled, Cvar_ButtonsEnabled);
	
	//Reg Cookies
	g_hCookie_BBans  = RegClientCookie("buttonwatcher_BBans", "", CookieAccess_Private);
	g_hCookie_BBansLength = RegClientCookie("buttonwatcher_BBanslength", "", CookieAccess_Private);
	g_hCookie_BBansIssued = RegClientCookie("buttonwatcher_BBansissued", "", CookieAccess_Private);
	g_hCookie_BBansBy     = RegClientCookie("buttonwatcher_BBansby", "", CookieAccess_Private);
	g_hCookie_Buttons     = RegClientCookie("buttonwatcher_Buttons", "", CookieAccess_Private);
	
	//command
	RegAdminCmd("sm_bban", Command_BBan, ADMFLAG_BAN);
	RegAdminCmd("sm_unbban", Command_UnBBan, ADMFLAG_BAN);
	RegAdminCmd("sm_bbanlist", Command_BBanlist, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_bstatus", Command_BStat);
	RegConsoleCmd("sm_buttons", Command_Buttons);
	
	//timer for unbban
	CreateTimer(30.0, TimerClientUnBBanCheck, _, TIMER_REPEAT);
	
	//menu
	Handle hTopMenu;

	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE)) OnAdminMenuReady(hTopMenu);
}

public void Cvar_ButtonsEnabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bButtonsEnabled = GetConVarBool(convar);
}

public void OnLibraryRemoved(const char[] sName) {
	if (strcmp(sName, "adminmenu") == 0) g_hAdminMenu = INVALID_HANDLE;
}

public void OnAdminMenuReady(Handle hAdminMenu)
{
	if (hAdminMenu == g_hAdminMenu) return;

	g_hAdminMenu = hAdminMenu;

	TopMenuObject hMenuObj = AddToTopMenu(g_hAdminMenu, "Buttons_commands", TopMenuObject_Category, AdminMenu_Commands_Handler, INVALID_TOPMENUOBJECT);

	switch (hMenuObj) {
		case INVALID_TOPMENUOBJECT: return;
	}

	AddToTopMenu(g_hAdminMenu, "Buttons_banlist", TopMenuObject_Item, Handler_BBanList, hMenuObj, "sm_bbanlist", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Buttons_ban", TopMenuObject_Item, Handler_BBan, hMenuObj, "sm_bban", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Buttons_unban", TopMenuObject_Item, Handler_UnBBan, hMenuObj, "sm_unbban", ADMFLAG_BAN);
}

public void AdminMenu_Commands_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%s", "Buttons Commands", iParam1);
		case TopMenuAction_DisplayTitle: FormatEx(sBuffer, iMaxlen, "%s", "Buttons Commands:", iParam1);
	}
}

public void Handler_BBanList(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%s", "List Buttons Banned Clients", iParam1);
		case TopMenuAction_SelectOption: Menu_BBan_List(iParam1);
	}
}

public void Handler_BBan(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%s", "Buttons Ban a Client", iParam1);
		case TopMenuAction_SelectOption: Menu_BBan(iParam1);
	}
}

public void Handler_UnBBan(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iParam1, char[] sBuffer, int iMaxlen) {
	switch (hAction) {
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%s", "Buttons Unban a Client", iParam1);
		case TopMenuAction_SelectOption: Menu_UnBBan(iParam1);
	}
}

void Menu_BBan_List(int iClient) {
	int iBannedClients;

	Menu hListMenu = CreateMenu(MenuHandler_Menu_BBan_List);
	hListMenu.SetTitle("[EYE] Buttons Banned Clients:");
	hListMenu.ExitBackButton = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_bBBans[i])
			{
				int iUserID = GetClientUserId(i);
				char sUserID[12], sBuff[64];
				
				FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);
				FormatEx(sBuff, sizeof(sBuff), "%N(#%i)", i, GetClientUserId(i));
				hListMenu.AddItem(sUserID, sBuff);
				iBannedClients++;
			}
		}
	}

	if (!iBannedClients) hListMenu.AddItem("", "No Banned Clients.", ITEMDRAW_DISABLED);

	hListMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_BBan_List(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
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

			if (iTarget != 0) Menu_BBan_ListTarget(iParam1, iTarget);
			else {
				CPrintToChat(iParam1, "%t %t", "Chat Prefix", "BBan No Available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

void Menu_BBan_ListTarget(int iClient, int iTarget)
{
	Menu hListTargetMenu = CreateMenu(MenuHandler_Menu_BBan_ListTarget);
	hListTargetMenu.SetTitle("[EYE] Buttons Banned Client: %N", iTarget);
	hListTargetMenu.ExitBackButton = true;

	char sBanExpiryDate[64], sBanIssuedDate[64], sBanDuration[64], sBannedBy[64], sUserID[15];
	int iBanExpiryDate = g_iBBansLength[iTarget]*60 + g_iBBansIssued[iTarget];
	int iBanIssuedDate = g_iBBansIssued[iTarget];
	int iBanDuration = g_iBBansLength[iTarget];
	int iUserID = GetClientUserId(iTarget);

	FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);

	if (g_bBBans[iTarget])
	{
		if (iBanDuration == -1)
		{
			FormatEx(sBanDuration, sizeof(sBanDuration), "Duration: Temporary");
			FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "Expires: On Map Change");
		}
		if (iBanDuration == 0)
		{
			FormatEx(sBanDuration, sizeof(sBanDuration), "Duration: Permanent");
			FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "Expires: Never");
		}
		if (iBanDuration > 0)
		{
			FormatEx(sBanDuration, sizeof(sBanDuration), "Duration: %i Minutes", iBanDuration);
			char sBufTime[32];
			FormatTime(sBufTime, sizeof(sBufTime), "%m/%d/%Y | %H:%M",iBanExpiryDate);
			FormatEx(sBanExpiryDate, sizeof(sBanExpiryDate), "Expires: %s", sBufTime);
		}
	}
	char sBufTimeIss[32];
	if(!(iBanIssuedDate==0)) FormatTime(sBufTimeIss, sizeof(sBufTimeIss), "%m/%d/%Y | %H:%M",iBanIssuedDate);
	else FormatEx(sBufTimeIss, sizeof(sBufTimeIss), "Unknown");
	FormatEx(sBanIssuedDate, sizeof(sBanIssuedDate), "Issued on: %s", sBufTimeIss);
	FormatEx(sBannedBy, sizeof(sBannedBy), "Admin SID: %s", g_sBBansBy[iTarget][0] ? g_sBBansBy[iTarget]:"Unknown");

	hListTargetMenu.AddItem("", sBannedBy, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanIssuedDate, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanExpiryDate, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", sBanDuration, ITEMDRAW_DISABLED);
	hListTargetMenu.AddItem("", "", ITEMDRAW_SPACER);
	hListTargetMenu.AddItem(sUserID, "Unban");

	hListTargetMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_BBan_ListTarget(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel:
		{
			switch (iParam2) {
				case MenuCancel_ExitBack: Menu_BBan_List(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));

			if (iTarget != 0) UnBBanClient(iTarget, iParam1);
			else {
				CPrintToChat(iParam1, "%t %t", "Chat Prefix", "BBan No Available");
				Menu_BBan_List(iParam1);
			}
		}
	}
}

void Menu_BBan(int iClient) {
	Menu hBBanMenu = CreateMenu(MenuHandler_Menu_BBan);
	hBBanMenu.SetTitle("[EYE] Buttons Ban a Client:");
	hBBanMenu.ExitBackButton = true;
	AddTargetsToMenu2(hBBanMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	hBBanMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_BBan(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
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

			if (iTarget != 0) Menu_BBanTime(iParam1, iTarget);
			else {
				CPrintToChat(iParam1, "%t %t", "Chat Prefix", "BBan No Available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

void Menu_BBanTime(int iClient, int iTarget)
{
	Menu hBBanMenuTime = CreateMenu(MenuHandler_Menu_BBanTime);
	hBBanMenuTime.SetTitle("[EYE] Buttons Ban Time for %N:", iTarget);
	hBBanMenuTime.ExitBackButton = true;

	g_iAdminMenuTarget[iClient] = iTarget;
	hBBanMenuTime.AddItem("-1", "Temporary");
	hBBanMenuTime.AddItem("1", "1 Minute");
	hBBanMenuTime.AddItem("10", "10 Minutes");
	hBBanMenuTime.AddItem("30", "30 Minutes");
	hBBanMenuTime.AddItem("60", "1 Hour");
	hBBanMenuTime.AddItem("240", "4 Hours");
	hBBanMenuTime.AddItem("720", "12 Hours");
	hBBanMenuTime.AddItem("1440", "1 Day");
	hBBanMenuTime.AddItem("2880", "2 Days");
	hBBanMenuTime.AddItem("4320", "3 Days");
	hBBanMenuTime.AddItem("10080", "1 Week");
	hBBanMenuTime.AddItem("20160", "2 Week");
	hBBanMenuTime.AddItem("40320", "1 Month");
	hBBanMenuTime.AddItem("0", "Permanent");

	hBBanMenuTime.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_BBanTime(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End:delete hMenu;
		case MenuAction_Cancel:
		{
			switch(iParam2){
				case MenuCancel_ExitBack: Menu_BBan(iParam1);
			}
		}

		case MenuAction_Select:
		{
			char sOption[64];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = g_iAdminMenuTarget[iParam1];

			if (iTarget != 0)
			{
				if (strcmp(sOption, "-1") == 0) BBanClient(iTarget, "-1", iParam1);
				else if (strcmp(sOption, "0") == 0) BBanClient(iTarget, "0", iParam1);
				else {
					BBanClient(iTarget, sOption, iParam1);
				}
			} else {
				CPrintToChat(iParam1, "%t %t", "Chat Prefix", "BBan No Available");
				Menu_BBan(iParam1);
			}
		}
	}
}

void Menu_UnBBan(int iClient)
{
	int iBannedClients;

	Menu hUnBBanMenu = CreateMenu(MenuHandler_Menu_UnBBan);
	hUnBBanMenu.SetTitle("[EYE] Buttons Unban a Client:");
	hUnBBanMenu.ExitBackButton = true;

	for (int i = 1; i < MaxClients + 1; i++)
	{
		if (IsClientInGame(i))
		{
			if (g_bBBans[i])
			{
				if(g_iBBansLength[i]==-1)
				{
					int iUserID = GetClientUserId(i);
					char sUserID[12], sBuff[64];
					FormatEx(sBuff, sizeof(sBuff), "%N (#%i)[T]", i, iUserID);
					FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);
					
					hUnBBanMenu.AddItem(sUserID, sBuff);
					iBannedClients++;
				}
				if(g_iBBansLength[i]==0)
				{
					int iUserID = GetClientUserId(i);
					char sUserID[12], sBuff[64];
					FormatEx(sBuff, sizeof(sBuff), "%N (#%i)[P]", i, iUserID);
					FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);
					
					hUnBBanMenu.AddItem(sUserID, sBuff);
					iBannedClients++;
				}
				if(g_iBBansLength[i]>0)
				{
					int iTLeft = (g_iBBansLength[i]*60 + g_iBBansIssued[i] - GetTime())/60;
					if(iTLeft<0) iTLeft=0;
					
					int iUserID = GetClientUserId(i);
					char sUserID[12], sBuff[64];
					FormatEx(sBuff, sizeof(sBuff), "%N (#%i)[L:%i]", i, iUserID, iTLeft);
					FormatEx(sUserID, sizeof(sUserID), "%d", iUserID);
					
					hUnBBanMenu.AddItem(sUserID, sBuff);
					iBannedClients++;
				}
			}
		}
	}

	if (!iBannedClients) hUnBBanMenu.AddItem("", "No Banned Clients.", ITEMDRAW_DISABLED);

	hUnBBanMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Menu_UnBBan(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
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

			if (iTarget != 0) UnBBanClient(iTarget, iParam1);
			else {
				CPrintToChat(iParam1, "%t %t", "Chat Prefix", "BBan No Available");

				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iParam1, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

/*public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iButton = -1;
	while ((iButton = FindEntityByClassname(iButton, "func_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKHookEx(iButton, SDKHook_Use, OnButtonUse);
			SDKHookEx(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
	while ((iButton = FindEntityByClassname(iButton, "momentary_rot_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKHookEx(iButton, SDKHook_Use, OnButtonUse);
			SDKHookEx(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
	while ((iButton = FindEntityByClassname(iButton, "func_rot_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKHookEx(iButton, SDKHook_Use, OnButtonUse);
			SDKHookEx(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
}*/

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (StrContains(sClassname, "func_button", false) != -1 && IsValidEntity(iEntity) && isMapRunning)
	{
		SDKHookEx(iEntity, SDKHook_Use, OnButtonUse);
		SDKHookEx(iEntity, SDKHook_OnTakeDamage, OnButtonDamage);
		g_aButtons[g_iMaxButtons]=iEntity;
		g_iMaxButtons++;
	}
	if (StrContains(sClassname, "momentary_rot_button", false) != -1 && IsValidEntity(iEntity) && isMapRunning)
	{
		SDKHookEx(iEntity, SDKHook_Use, OnButtonUse);
		SDKHookEx(iEntity, SDKHook_OnTakeDamage, OnButtonDamage);
		g_aButtons[g_iMaxButtons]=iEntity;
		g_iMaxButtons++;
	}
	if (StrContains(sClassname, "func_rot_button", false) != -1 && IsValidEntity(iEntity) && isMapRunning)
	{
		SDKHookEx(iEntity, SDKHook_Use, OnButtonUse);
		SDKHookEx(iEntity, SDKHook_OnTakeDamage, OnButtonDamage);
		g_aButtons[g_iMaxButtons]=iEntity;
		g_iMaxButtons++;
	}
}

/*public Action Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iButton = -1;
	while ((iButton = FindEntityByClassname(iButton, "func_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKUnhook(iButton, SDKHook_Use, OnButtonUse);
			SDKUnhook(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
	while ((iButton = FindEntityByClassname(iButton, "momentary_rot_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKUnhook(iButton, SDKHook_Use, OnButtonUse);
			SDKUnhook(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
	while ((iButton = FindEntityByClassname(iButton, "func_rot_button")) != -1)
	{
		if (IsValidEdict(iButton))
		{
			SDKUnhook(iButton, SDKHook_Use, OnButtonUse);
			SDKUnhook(iButton, SDKHook_OnTakeDamage, OnButtonDamage);
		}
	}
}*/

public void OnMapStart()
{
	g_iMaxButtons = 0;
	isMapRunning = true;
}

public void OnMapEnd()
{
    isMapRunning = false;
}

public Action Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int index = 0; index < g_iMaxButtons; index++)
	{
		SDKUnhook(g_aButtons[index], SDKHook_Use, OnButtonUse);
		SDKUnhook(g_aButtons[index], SDKHook_OnTakeDamage, OnButtonDamage);
	}
}

public Action OnButtonUse(int iButton, int iActivator)
{
	if((IsValidEdict(iButton))&&(IsValidClient(iActivator)))
	{	
		if(entWatch_IsSpecialItem(iButton)) return Plugin_Continue;
	
		if(g_bBBans[iActivator]) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnButtonDamage(int iButton, int &iActivator)
{
	if((IsValidEdict(iButton))&&(IsValidClient(iActivator)))
	{	
		if(entWatch_IsSpecialItem(iButton)) return Plugin_Continue;
	
		if(g_bBBans[iActivator]) return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientCookiesCached(int iClient)
{
	char sBuffer_cookie[32];
	
	//buttons
	GetClientCookie(iClient, g_hCookie_Buttons, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_bButtons[iClient] = bool:StringToInt(sBuffer_cookie);
	
	//banned
	GetClientCookie(iClient, g_hCookie_BBans, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_bBBans[iClient] = bool:StringToInt(sBuffer_cookie);

	//length ban
	GetClientCookie(iClient, g_hCookie_BBansLength, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_iBBansLength[iClient] = StringToInt(sBuffer_cookie);

	//time ban
	GetClientCookie(iClient, g_hCookie_BBansIssued, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_iBBansIssued[iClient] = StringToInt(sBuffer_cookie);

	//who banned
	GetClientCookie(iClient, g_hCookie_BBansBy, sBuffer_cookie, sizeof(sBuffer_cookie));
	FormatEx(g_sBBansBy[iClient], sizeof(g_sBBansBy[]), "%s", sBuffer_cookie);
	
	//unban if time left
	if(g_bBBans[iClient])
	{
		if(g_iBBansLength[iClient]>0)
		{
			if((g_iBBansIssued[iClient]+(g_iBBansLength[iClient]*60))<GetTime())
			{
				g_bBBans[iClient] = false;
				g_iBBansLength[iClient] = -1;
				g_iBBansIssued[iClient] = 0;
				g_sBBansBy[iClient][0] = '\0';
				
				SetClientCookie(iClient, g_hCookie_BBans, "0");
				SetClientCookie(iClient, g_hCookie_BBansLength, "-1");
				SetClientCookie(iClient, g_hCookie_BBansIssued, "0");
				SetClientCookie(iClient, g_hCookie_BBansBy, "");
				
				LogMessage("[EYE] Unbanned button presses \"%L\" (Timeleft)", iClient);
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	g_bButtons[iClient] = false;
	g_bBBans[iClient] = false;
	g_iBBansLength[iClient] = -1;
	g_iBBansIssued[iClient] = 0;
	g_sBBansBy[iClient][0] = '\0';
}

public void BBanClient(int iClient, const char[] sLength, int iAdmin)
{
	int iBanLen = StringToInt(sLength);
	
	if (iAdmin != 0)
	{
		char sAdminSID[64];
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdminSID, sizeof(sAdminSID));
		FormatEx(g_sBBansBy[iClient], sizeof(g_sBBansBy[]), "%N (%s)", iAdmin, sAdminSID);

		SetClientCookie(iClient, g_hCookie_BBansBy, sAdminSID);
	} else {
		FormatEx(g_sBBansBy[iClient], sizeof(g_sBBansBy[]), "Console");
		SetClientCookie(iClient, g_hCookie_BBansBy, "Console");
	}
	
	//length ban
	if(iBanLen==-1) //temporarily
	{
		SetClientCookie(iClient, g_hCookie_BBans, "0");
		SetClientCookie(iClient, g_hCookie_BBansLength, "-1");
		
		g_bBBans[iClient] = true;
		g_iBBansLength[iClient] = -1;
		
		LogAction(iAdmin, iClient, "\"%L\" banned button presses \"%L\"", iAdmin, iClient);
		
		CPrintToChatAll("%t %t", "Chat Prefix", "BBan Temp", iAdmin, iClient);
	} else if(iBanLen==0) //permanently
	{
		SetClientCookie(iClient, g_hCookie_BBans, "1");
		SetClientCookie(iClient, g_hCookie_BBansLength, "0");
		
		g_bBBans[iClient] = true;
		g_iBBansLength[iClient] = 0;
		
		LogAction(iAdmin, iClient, "\"%L\" banned button presses \"%L\" permanently", iAdmin, iClient);
		
		CPrintToChatAll("%t %t", "Chat Prefix", "BBan Perm", iAdmin, iClient);
	} else 
	{
		SetClientCookie(iClient, g_hCookie_BBans, "1");
		SetClientCookie(iClient, g_hCookie_BBansLength, sLength);
		
		g_bBBans[iClient] = true;
		g_iBBansLength[iClient] = iBanLen;
		LogAction(iAdmin, iClient, "\"%L\" banned button presses \"%L\" for %d Minutes", iAdmin, iClient, iBanLen);
		
		char sTime[128];
		int iTstamp = (iBanLen*60);
			
		if(iTstamp<0) iTstamp=0;
				
		int iDays = (iTstamp / 86400);
		int iHours = ((iTstamp / 3600) % 24);
		int iMinutes = ((iTstamp / 60) % 60);
		int iSeconds = (iTstamp % 60);
			
		if (iTstamp >= 86400)
			Format(sTime, sizeof(sTime), "%d Days, %d Hours, %d Minutes, %d Seconds", iDays, iHours, iMinutes, iSeconds);
		else if (iTstamp >= 3600)
			Format(sTime, sizeof(sTime), "%d Hours, %d Minutes, %d Seconds", iHours, iMinutes, iSeconds);
		else if (iTstamp >= 60)
			Format(sTime, sizeof(sTime), "%d Minutes, %d Seconds", iMinutes, iSeconds);
		else
			Format(sTime, sizeof(sTime), "%d Seconds", iSeconds);
		
		CPrintToChatAll("%t %t", "Chat Prefix", "BBan Time", iAdmin, iClient, sTime);
	}
	
	//time ban
	char sIssueTime[64];
	FormatEx(sIssueTime, sizeof(sIssueTime), "%d", GetTime());
	SetClientCookie(iClient, g_hCookie_BBansIssued, sIssueTime);
	g_iBBansIssued[iClient] = GetTime();	
}

public void UnBBanClient(int iClient, int iAdmin)
{
	g_bBBans[iClient] = false;
	g_iBBansLength[iClient] = -1;
	g_iBBansIssued[iClient] = 0;
	g_sBBansBy[iClient][0] = '\0';
	
	SetClientCookie(iClient, g_hCookie_BBans, "0");
	SetClientCookie(iClient, g_hCookie_BBansLength, "-1");
	SetClientCookie(iClient, g_hCookie_BBansIssued, "0");
	SetClientCookie(iClient, g_hCookie_BBansBy, "");

	CPrintToChatAll("%t %t", "Chat Prefix","BBan Unban", iAdmin, iClient);
	LogAction(iAdmin, iClient, "\"%L\" Unbanned button presses \"%L\"", iAdmin, iClient);
}

public Action TimerClientUnBBanCheck(Handle hTimer)
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			if(g_bBBans[iClient])
			{
				if(g_iBBansLength[iClient]>0)
				{
					if((g_iBBansIssued[iClient]+(g_iBBansLength[iClient]*60))<GetTime())
					{
						g_bBBans[iClient] = false;
						g_iBBansLength[iClient] = -1;
						g_iBBansIssued[iClient] = 0;
						g_sBBansBy[iClient][0] = '\0';
						
						SetClientCookie(iClient, g_hCookie_BBans, "0");
						SetClientCookie(iClient, g_hCookie_BBansLength, "-1");
						SetClientCookie(iClient, g_hCookie_BBansIssued, "0");
						SetClientCookie(iClient, g_hCookie_BBansBy, "");
						
						CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan Unban TimeLeft");
						LogMessage("[EYE] Unbanned button presses \"%L\" (Timeleft)", iClient);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Command_BBan(int iClient, int iArgs)
{
	if (GetCmdArgs() < 1)
	{
		CReplyToCommand(iClient, "[EYE] Usage: sm_bban <target> [<time in minutes>]");
		return Plugin_Handled;
	}

	char sTarget_argument[64];
	GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

	int iTarget = -1;
	if ((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;

	if (GetCmdArgs() > 1)
	{
		char sLen[64];
		GetCmdArg(2, sLen, sizeof(sLen));

		if (StringToInt(sLen) <= -1) BBanClient(iTarget, "-1", iClient);
		else if (StringToInt(sLen) == 0) BBanClient(iTarget, "0", iClient);
		else BBanClient(iTarget, sLen, iClient);
		return Plugin_Handled;
	}

	BBanClient(iTarget, "0", iClient);
	return Plugin_Handled;
}

public Action Command_UnBBan(int iClient, int iArgs)
{
	if (iArgs != 1)
	{
		CReplyToCommand(iClient, "[EYE] Usage: sm_unbban <target>");
		return Plugin_Handled;
	}

	char sTarget_argument[64];
	GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

	int iTarget = -1;
	if ((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;

	UnBBanClient(iTarget, iClient);

	return Plugin_Handled;
}

public Action Command_BStat(int iClient, int iArgs)
{
	if (!g_bBBans[iClient])
	{
		CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Unbanned");
		return Plugin_Handled;
	} else
	{
		if(g_iBBansLength[iClient]==-1)
		{
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Temp");
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Admin",g_sBBansBy[iClient]);
			return Plugin_Handled;
		}
		if(g_iBBansLength[iClient]==0)
		{
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Perm");
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Admin",g_sBBansBy[iClient]);
			return Plugin_Handled;
		}
		if(g_iBBansLength[iClient]>0)
		{
			char sRemainingTime[128];
			int iTstamp = (g_iBBansLength[iClient]*60 + g_iBBansIssued[iClient] - GetTime());
			
			if(iTstamp<0) iTstamp=0;
				
			int iDays = (iTstamp / 86400);
			int iHours = ((iTstamp / 3600) % 24);
			int iMinutes = ((iTstamp / 60) % 60);
			int iSeconds = (iTstamp % 60);
			
			if (iTstamp >= 86400)
				Format(sRemainingTime, sizeof(sRemainingTime), "%d Days, %d Hours, %d Minutes, %d Seconds", iDays, iHours, iMinutes, iSeconds);
			else if (iTstamp >= 3600)
				Format(sRemainingTime, sizeof(sRemainingTime), "%d Hours, %d Minutes, %d Seconds", iHours, iMinutes, iSeconds);
			else if (iTstamp >= 60)
				Format(sRemainingTime, sizeof(sRemainingTime), "%d Minutes, %d Seconds", iMinutes, iSeconds);
			else
				Format(sRemainingTime, sizeof(sRemainingTime), "%d Seconds", iSeconds);
			
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Time",sRemainingTime);
			CPrintToChat(iClient, "%t %t", "Chat Prefix", "BBan You Banned Admin",g_sBBansBy[iClient]);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public Action Command_BBanlist(int iClient, int iArgs)
{
	char sBuff[1024];
	bool bFirst = true;
	Format(sBuff, sizeof(sBuff), "No players found.");

	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if (g_bBBans[i])
		{
			if (bFirst)
 			{
 				bFirst = false;
				CReplyToCommand(iClient, "[EYE] Currently BBanned:");
			}
			
			char sPlayerSID[64];
			GetClientAuthId(i, AuthId_Steam2, sPlayerSID, sizeof(sPlayerSID));
			
			if(g_iBBansLength[i]==-1)
			{
				FormatEx(sBuff, sizeof(sBuff), "%N(%s) [T] | A:%s", i, sPlayerSID, g_sBBansBy[i]);
				CReplyToCommand(iClient, ">%s",sBuff);
			}
			if(g_iBBansLength[i]==0)
			{
				FormatEx(sBuff, sizeof(sBuff), "%N(%s) [P] | A:%s", i, sPlayerSID, g_sBBansBy[i]);
				CReplyToCommand(iClient, ">%s",sBuff);
			}
			if(g_iBBansLength[i]>0)
			{
				int iTLeft = (g_iBBansLength[i]*60 + g_iBBansIssued[i] - GetTime())/60;
				if(iTLeft<0) iTLeft=0;
				
				FormatEx(sBuff, sizeof(sBuff), "%N(%s) [L:%i Minutes] | A:%s", i, sPlayerSID, iTLeft, g_sBBansBy[i]);
				CReplyToCommand(iClient, ">%s",sBuff);
			}
		}
	}
	if (bFirst) CReplyToCommand(iClient, "[EYE] Currently BBanned: No players found.");
	FormatEx(sBuff, sizeof(sBuff), "");
	return Plugin_Handled;
}

public Action Command_Buttons(int iClient, int iArgs)
{
	if(g_bButtons[iClient]==false) g_bButtons[iClient]=true;
	else g_bButtons[iClient]=false;
	if (g_bButtons[iClient]){
		SetClientCookie(iClient, g_hCookie_Buttons, "1");
		CPrintToChat(iClient, "%t %t", "Chat Prefix", "Buttons View Disabled");
	}else{
		SetClientCookie(iClient, g_hCookie_Buttons, "0");
		CPrintToChat(iClient, "%t %t", "Chat Prefix", "Buttons View Enabled");
	}
}

public Action PressBTN(const String:output[], caller, activator, Float:delay)
{
	if(!IsValidClient(activator)) return Plugin_Continue;
	if(!g_bButtonsEnabled) return Plugin_Continue;
	
	decl String:entity[512];
	GetEntPropString(caller, Prop_Data, "m_iName", entity, sizeof(entity));

	if(entWatch_IsSpecialItem(caller)) return Plugin_Continue;
	
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			if(!g_bButtons[i])
				CPrintToChat(i,"%t %t", "Chat Prefix", "Button Press", activator, entity, caller);
	//CPrintToChatAll("%t %t", "Chat Prefix", "Button Press", activator, entity, caller);
	
	LogMessage("[EYE] %L pressed the button %s [HammerID: %i]", activator, entity, caller);
	
	return Plugin_Continue;
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || !IsPlayerAlive(client) ) 
        return false; 
     
    return true; 
}

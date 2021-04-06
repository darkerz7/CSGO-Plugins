#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <csgocolors_fix>

#define MAX_LENGTH_MENU_BIG_TEXT 1024
#define MAX_LENGTH_COMMAND 128
#define MAX_LENGTH_TRANSLATE_COMMAND 128

Handle cDisableHM = INVALID_HANDLE;

bool g_bDisable[MAXPLAYERS + 1] = {false, ...};

StringMap g_smCommands;

public Plugin myinfo =
{
	name = "Help Menu MultiLanguage",
	author = "DarkerZ [RUS]",
	description = "Display a help menu to users",
	version = "1.1",
	url = "dark-skill.ru"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_helpmenu", Command_HelpMenu, "Display the help menu");
	LoadTranslations("helpmenu_multilang.phrases");
	
	cDisableHM = RegClientCookie("cookie_helpmenu", "Disable Help Menu", CookieAccess_Private);
	
	CFG_load();
	
	AddCommandListener(Button_F4_Bind, "rebuy");
	
	RegAdminCmd("sm_helpmenu_reload", Reload_cfg, ADMFLAG_ROOT);
}

public Action Command_HelpMenu(int client, int args)
{
	HelpMenu_Main(client);
	return Plugin_Handled;
}

public Action Button_F4_Bind(int client, char[] command, int args)
{
   HelpMenu_Commands(client);
   return Plugin_Continue;
}

public Action Reload_cfg(int client, int args)
{
	CFG_load();
	CPrintToChat(client, "%t %t", "Help Menu Tag", "Help Menu Config Reload");
	return Plugin_Handled;
}

void HelpMenu_Main(int client)
{
	Menu menu_main = CreateMenu(Handle_HelpMenu_Main);
	
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Help Menu Title", client);
	SetMenuTitle(menu_main, sMenuTranslate);
	
	char sMenuTranslateBig[MAX_LENGTH_MENU_BIG_TEXT];
	
	FormatEx(sMenuTranslateBig, sizeof(sMenuTranslateBig), "%T", "Help Text Main", client);
	Replace_Tags(sMenuTranslateBig);
	AddMenuItem(menu_main, "main_help", sMenuTranslateBig, ITEMDRAW_DISABLED);
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", g_bDisable[client] ? "Enable Show" : "No Longer Show", client);
	AddMenuItem(menu_main, g_bDisable[client] ? "main_show_off" : "main_show_on",  sMenuTranslate);
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Server Commands", client);
	AddMenuItem(menu_main, "main_command", sMenuTranslate);
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Server Rules", client);
	AddMenuItem(menu_main, "main_rules", sMenuTranslate);
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Server Info", client);
	AddMenuItem(menu_main, "main_info", sMenuTranslate);
	
	DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public int Handle_HelpMenu_Main(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			if(StrEqual(sOption, "main_show_on"))
			{
				g_bDisable[iParam1] = true;
				CPrintToChat(iParam1, "%t %t", "Help Menu Tag", "Help Menu Show Disable");
				SetClientCookie(iParam1, cDisableHM, "1");
				HelpMenu_Main(iParam1);
			} else if (StrEqual(sOption, "main_show_off"))
			{
				g_bDisable[iParam1] = false;
				CPrintToChat(iParam1, "%t %t", "Help Menu Tag","Help Menu Show Enable");
				SetClientCookie(iParam1, cDisableHM, "0");
				HelpMenu_Main(iParam1);
			} else if (StrEqual(sOption, "main_rules"))
			{
				HelpMenu_Rules(iParam1);
			} else if (StrEqual(sOption, "main_info"))
			{
				HelpMenu_Info(iParam1);
			} else if (StrEqual(sOption, "main_command"))
			{
				HelpMenu_Commands(iParam1);
			}
		}
	}
}

void HelpMenu_Rules(int client)
{
	Menu menu_main = CreateMenu(Handle_HelpMenu_Rules);
	
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Help Menu TRules", client);
	SetMenuTitle(menu_main, sMenuTranslate);
	
	char sMenuTranslateBig[MAX_LENGTH_MENU_BIG_TEXT];
	
	FormatEx(sMenuTranslateBig, sizeof(sMenuTranslateBig), "%T", "Help Text Rules", client);
	Replace_Tags(sMenuTranslateBig);
	AddMenuItem(menu_main, "rules_help", sMenuTranslateBig, ITEMDRAW_DISABLED);
	
	DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public int Handle_HelpMenu_Rules(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu; 
		case MenuAction_Cancel:
		{
			switch(iParam2)
			{
				case MenuCancel_Exit: HelpMenu_Main(iParam1);
			}
		}
	}
}

void HelpMenu_Info(int client)
{
	Menu menu_main = CreateMenu(Handle_HelpMenu_Info);
	
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Help Menu TInfo", client);
	SetMenuTitle(menu_main, sMenuTranslate);
	
	char sMenuTranslateBig[MAX_LENGTH_MENU_BIG_TEXT];
	
	FormatEx(sMenuTranslateBig, sizeof(sMenuTranslateBig), "%T", "Help Text Info", client);
	Replace_Tags(sMenuTranslateBig);
	AddMenuItem(menu_main, "info_help", sMenuTranslateBig, ITEMDRAW_DISABLED);
	
	DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public int Handle_HelpMenu_Info(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu; 
		case MenuAction_Cancel:
		{
			switch(iParam2)
			{
				case MenuCancel_Exit: HelpMenu_Main(iParam1);
			}
		}
	}
}

void HelpMenu_Commands(int client)
{
	Menu menu_main = CreateMenu(Handle_HelpMenu_Commands);
	
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "Help Menu TCommands", client);
	SetMenuTitle(menu_main, sMenuTranslate);
	
	char sComms[MAX_LENGTH_COMMAND], sMenuTraslateComms[MAX_LENGTH_TRANSLATE_COMMAND];
	StringMapSnapshot g_smCommandsSnapshot = g_smCommands.Snapshot();
	for(int i=0; i < g_smCommandsSnapshot.Length; i++)
	{
		g_smCommandsSnapshot.GetKey(i, sComms, sizeof(sComms));
		g_smCommands.GetString(sComms, sMenuTraslateComms, sizeof(sMenuTraslateComms));
		FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", sMenuTraslateComms, client);
		AddMenuItem(menu_main, sComms, sMenuTranslate);
	}
	
	DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public int Handle_HelpMenu_Commands(Menu hMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			FakeClientCommand(iParam1, sOption);
		}
	}
}

public void OnClientCookiesCached(int client) {
	char sValue[8];
	GetClientCookie(client, cDisableHM, sValue, sizeof(sValue));
	g_bDisable[client] = view_as<bool>(StringToInt(sValue));
}

public void OnClientPutInServer(int client)
{
	CreateTimer(5.0, Timer_HelpMain, client);
}

public Action Timer_HelpMain(Handle timer, any client) {
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		if(g_bDisable[client]==false) HelpMenu_Main(client);
}

void Replace_Tags(char[] msg)
{
	char sText[128];
	if(StrContains(msg, "{IP}") != -1)
	{
		int ip = FindConVar("hostip").IntValue;
		FormatEx(sText, sizeof(sText), "%d.%d.%d.%d", ip >>> 24 & 255, ip >>> 16 & 255, ip >>> 8 & 255, ip & 255); //IP
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{IP}", sText);
	}
	if(StrContains(msg, "{PORT}") != -1)
	{
		GetConVarString(FindConVar("hostport"), sText, sizeof(sText)); //PORT
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{PORT}", sText);
	}
	if(StrContains(msg, "{TIC}") != -1)
	{
		IntToString(RoundToZero(1.0/GetTickInterval()), sText, sizeof(sText));//TIC
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{TIC}", sText);
	}
	if(StrContains(msg, "{SERVERNAME}") != -1)
	{
		GetConVarString(FindConVar("hostname"), sText, sizeof(sText)); //SERVERNAME
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{SERVERNAME}", sText);
	}
	if(StrContains(msg, "{PL}") != -1)
	{
		IntToString(GetClientCount(), sText, sizeof(sText)); //PL
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{PL}", sText);
	}
	if(StrContains(msg, "{PLMAX}") != -1)
	{
		IntToString(GetMaxHumanPlayers(), sText, sizeof(sText)); //PLMAX
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{PLMAX}", sText);
	}
	if(StrContains(msg, "{MAP}") != -1)
	{
		GetCurrentMap(sText, sizeof(sText)); //MAP
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{MAP}", sText);
	}
	if(StrContains(msg, "{TIME}") != -1)
	{
		FormatTime(sText, sizeof(sText), "%H:%M:%S"); //TIME
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{TIME}", sText);
	}
	if(StrContains(msg, "{TIMELEFT}") != -1)
	{
		int timeleft; //TIMELEFT
		if (GetMapTimeLeft(timeleft) && timeleft > 0)
		{
			Format(sText, sizeof(sText), "%d:%02d", timeleft / 60, timeleft % 60);
		} else Format(sText, sizeof(sText), "0");
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{TIMELEFT}", sText);
	}
	if(StrContains(msg, "{DATE}") != -1)
	{
		FormatTime(sText, sizeof(sText), "%d/%m/%Y"); //DATE
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{DATE}", sText);
	}
	if(StrContains(msg, "{NEXTMAP}") != -1)
	{
		GetNextMap(sText, sizeof(sText)); //NEXTMAP
		ReplaceString(msg, MAX_LENGTH_MENU_BIG_TEXT, "{NEXTMAP}", sText);
	}
}

void CFG_load()
{
	if(g_smCommands) delete g_smCommands;
	KeyValues cfg = new KeyValues("HelpMenu");
	static char path[128], h[MAX_LENGTH_COMMAND], buf[MAX_LENGTH_TRANSLATE_COMMAND];
	if(!path[0]) BuildPath(Path_SM, path, 128, "configs/helpmenu.cfg");
	if(!cfg.ImportFromFile(path)) SetFailState("[HelpMenu] Config configs/helpmenu.cfg not found");
	else
	{
		cfg.Rewind();
		cfg.GotoFirstSubKey(false);
		g_smCommands = new StringMap();
		do
		{
			cfg.GetSectionName(h, MAX_LENGTH_COMMAND);
			cfg.GetString("", buf, MAX_LENGTH_TRANSLATE_COMMAND);
			g_smCommands.SetString(h, buf);
		}
		while (cfg.GotoNextKey(false));
		cfg.Rewind();
	}
	delete cfg;
}
#define EW_MODULE_MENU

#include <adminmenu>

Handle g_hAdminMenu;

stock void EWM_Menu_OnPluginStart()
{
	Handle hTopMenu;

	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE)) OnAdminMenuReady(hTopMenu);
}

//-------------------------------------------------------
// Purpose: Safeguard against adminmenu unloading
//-------------------------------------------------------
public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "adminmenu") == 0) g_hAdminMenu = INVALID_HANDLE;
}

//-------------------------------------------------------
// Purpose: Add our entries to the main admin menu
//-------------------------------------------------------
public void OnAdminMenuReady(Handle hAdminMenu)
{
	if (hAdminMenu == g_hAdminMenu) return;

	g_hAdminMenu = hAdminMenu;

	TopMenuObject hMenuObj = AddToTopMenu(g_hAdminMenu, "EntWatch_Commands", TopMenuObject_Category, EWM_Menu_AM_Handler, INVALID_TOPMENUOBJECT);

	switch (hMenuObj)
	{
		case INVALID_TOPMENUOBJECT: return;
	}

	AddToTopMenu(g_hAdminMenu, "EntWatch_ItemList", TopMenuObject_Item, EWM_Menu_AM_ItemList_Handler, hMenuObj, "sm_eitemlist", ADMFLAG_BAN);
	#if defined EW_MODULE_EBAN
	AddToTopMenu(g_hAdminMenu, "EntWatch_EBanList", TopMenuObject_Item, EWM_Menu_AM_EBanList_Handler, hMenuObj, "sm_eban", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "EntWatch_EUnBanList", TopMenuObject_Item, EWM_Menu_AM_EUnBanList_Handler, hMenuObj, "sm_eunban", ADMFLAG_BAN);
	#endif
	#if defined EW_MODULE_SPAWN
	AddToTopMenu(g_hAdminMenu, "EntWatch_SpawnItemList", TopMenuObject_Item, EWM_Menu_AM_SpawnItemList_Handler, hMenuObj, "sm_espawnitem", ADMFLAG_BAN);
	#endif
}

//-------------------------------------------------------
// Purpose: Menu Stuff
//-------------------------------------------------------
public void EWM_Menu_AM_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iClient, char[] sBuffer, int iMaxlen)
{
	switch (hAction)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "EntWatch Commands", iClient);
		case TopMenuAction_DisplayTitle: FormatEx(sBuffer, iMaxlen, "%T:", "EntWatch Commands Title", iClient);
	}
}

public void EWM_Menu_AM_ItemList_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iClient, char[] sBuffer, int iMaxlen)
{
	switch (hAction)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "List of Items", iClient);
		case TopMenuAction_SelectOption: EWM_Menu_PM_ItemList(iClient);
	}
}

#if defined EW_MODULE_EBAN
public void EWM_Menu_AM_EBanList_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iClient, char[] sBuffer, int iMaxlen)
{
	switch (hAction)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "EBan a Player", iClient);
		case TopMenuAction_SelectOption: EWM_Menu_PM_EBanList(iClient);
	}
}

public void EWM_Menu_AM_EUnBanList_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iClient, char[] sBuffer, int iMaxlen)
{
	switch (hAction)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "List of EBan", iClient);
		case TopMenuAction_SelectOption: EWM_Menu_PM_EUnBanList(iClient);
	}
}
#endif

#if defined EW_MODULE_SPAWN
public void EWM_Menu_AM_SpawnItemList_Handler(Handle hMenu, TopMenuAction hAction, TopMenuObject hObjID, int iClient, char[] sBuffer, int iMaxlen)
{
	switch (hAction)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "Spawn an Item", iClient);
		case TopMenuAction_SelectOption: EWM_Menu_PM_SpawnItemList(iClient);
	}
}
#endif

//-------------------------------------------------------
// Purpose: Menu Headers
//-------------------------------------------------------
void EWM_Menu_PM_ItemList(int iClient)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_ItemList_Handler);
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "List of Items", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.AllowTransfer && ItemTest.WeaponID != INVALID_ENT_REFERENCE)
		{
			char sIndexItem[32], sItemName[64];
			if(ItemTest.OwnerID != INVALID_ENT_REFERENCE)
				FormatEx(sItemName, sizeof(sItemName), "%s (%N|#%i)", ItemTest.Name, ItemTest.OwnerID, GetClientUserId(ItemTest.OwnerID));
			else FormatEx(sItemName, sizeof(sItemName), "%s (%T)", ItemTest.Name, "No owner", iClient);
			FormatEx(sIndexItem, sizeof(sIndexItem), "%d", i);
			hMenu.AddItem(sIndexItem, sItemName);
		}
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

#if defined EW_MODULE_EBAN
void EWM_Menu_PM_EBanList(int iClient)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_EBanList_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[32];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "Restrict Player", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	bool bNotFound = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || g_EbanClients[i].Banned) continue;
		
		bNotFound = false;
		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%s", i, sIndexTemp);
		hMenu.AddItem(sIndexTemp, sMenuTemp);
	}
	if(bNotFound)
	{
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "No Players", iClient);
		hMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_EUnBanList(int iClient)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_EUnBanList_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[32];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "List of EBan", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	bool bNotFound = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !g_EbanClients[i].Banned) continue;
		
		bNotFound = false;
		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%s", i, sIndexTemp);
		hMenu.AddItem(sIndexTemp, sMenuTemp);
	}
	if(bNotFound)
	{
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "No EBans", iClient);
		hMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_EBanDuration(int iClient, int iTarget)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_EBanDuration_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N", "EW_Tag", iClient, "EBan Duration for", iClient, iTarget);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	int iUserID = GetClientUserId(iTarget);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", -1, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Temporary", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 10, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "10 %T", "Minutes", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 60, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Hour", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 1440, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Day", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 10080, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Week", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 40320, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Month", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", 0, iUserID);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Permanently", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_EBanReason(int iClient, int iTarget, int iDuration)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_EBanReason_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[96];
	if(iDuration == -1) FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, "Temporary", iClient);
	else if(iDuration == 0) FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, "Permanently", iClient);
		else FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%i %T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, iDuration, "Minutes", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	int iUserID = GetClientUserId(iTarget);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Item misuse");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Item misuse", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Trolling on purpose");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trolling on purpose", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Throwing item away");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Throwing item away", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Not using an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not using an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Trimming team");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trimming team", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Not listening to leader");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not listening to leader", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Spamming an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Spamming an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Other");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Other", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_EBanInfo(int iClient, int iTarget)
{
	if(g_EbanClients[iTarget].Banned)
	{
		Menu hMenu = CreateMenu(EWM_Menu_PM_EBanInfo_Handler);
		char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[32];
		int iUserID = GetClientUserId(iTarget);
		FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T: %N |#%i", "EW_Tag", iClient, "EBan Info", iClient, iTarget, iUserID);
		hMenu.SetTitle(sMenuTranslate);
		hMenu.ExitBackButton = true;
		char sItemAdmin[128], sItemDuration[64], sItemIssued[64], sItemExpires[64], sItemReason[96], sTimeStamp[64];
		FormatTime(sTimeStamp, sizeof(sTimeStamp), NULL_STRING, g_EbanClients[iTarget].TimeStamp_Issued);
		FormatEx(sItemAdmin, sizeof(sItemAdmin), "%T: %s(%s)", "Admin", iClient, g_EbanClients[iTarget].Admin_Name, g_EbanClients[iTarget].Admin_SteamID);
		if(g_EbanClients[iTarget].Duration == -1)
		{
			FormatEx(sItemDuration, sizeof(sItemDuration), "%T: %T", "Duration", iClient, "Temporary", iClient);
			FormatEx(sItemIssued, sizeof(sItemIssued), "%T: %s", "Issued", iClient, sTimeStamp);
			FormatEx(sItemExpires, sizeof(sItemExpires), "%T: %T", "Expires", iClient, "On Map Change", iClient);
		} else if(g_EbanClients[iTarget].Duration == 0)
		{
			FormatEx(sItemDuration, sizeof(sItemDuration), "%T: %T", "Duration", iClient, "Permanently", iClient);
			FormatEx(sItemIssued, sizeof(sItemIssued), "%T: %s", "Issued", iClient, sTimeStamp);
			FormatEx(sItemExpires, sizeof(sItemExpires), "%T: %T", "Expires", iClient, "Never", iClient);
		} else
		{
			FormatEx(sItemDuration, sizeof(sItemDuration), "%T: %i %T", "Duration", iClient, g_EbanClients[iTarget].Duration, "Minutes", iClient);
			FormatEx(sItemExpires, sizeof(sItemExpires), "%T: %s", "Expires", iClient, sTimeStamp);
			FormatTime(sTimeStamp, sizeof(sTimeStamp), NULL_STRING, g_EbanClients[iTarget].TimeStamp_Issued - g_EbanClients[iTarget].Duration * 60);
			FormatEx(sItemIssued, sizeof(sItemIssued), "%T: %s", "Issued", iClient, sTimeStamp);
		}
		FormatEx(sItemReason, sizeof(sItemReason), "%T: %s\n", "Reason", iClient, g_EbanClients[iTarget].Reason);
		
		hMenu.AddItem("", sItemAdmin, ITEMDRAW_DISABLED);
		hMenu.AddItem("", sItemDuration, ITEMDRAW_DISABLED);
		hMenu.AddItem("", sItemIssued, ITEMDRAW_DISABLED);
		hMenu.AddItem("", sItemExpires, ITEMDRAW_DISABLED);
		hMenu.AddItem("", sItemReason, ITEMDRAW_DISABLED);
		
		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i", GetClientUserId(iTarget));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "UnEBan a Player", iClient);
		hMenu.AddItem(sIndexTemp, sMenuTemp);
		
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	} else
	{
		if(IsValidClient(iClient) && IsClientConnected(iClient)) CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Already UnEBanned");
	}
}
#endif

void EWM_Menu_PM_ItemInfo(int iClient, int iItemIndex)
{
	class_ItemList ItemTest;
	g_ItemList.GetArray(iItemIndex, ItemTest, sizeof(ItemTest));
	
	Menu hMenu = CreateMenu(EWM_Menu_PM_ItemInfo_Handler);
	char sMenuTranslate[128], sOwner[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T: %s", "EW_Tag", iClient, "Item Info", iClient, ItemTest.Name);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	if(ItemTest.OwnerID != INVALID_ENT_REFERENCE)
		FormatEx(sOwner, sizeof(sOwner), "%T: %N|#%i", "Owner", iClient, ItemTest.OwnerID, GetClientUserId(ItemTest.OwnerID));
	else FormatEx(sOwner, sizeof(sOwner), "%T: %T", "Owner", iClient, "No owner", iClient);
	//hMenu.AddItem("", sOwner, ITEMDRAW_DISABLED);
	char sItemBuffer[512];
	switch(ItemTest.Mode)
	{
		case 2: FormatEx(sItemBuffer, sizeof(sItemBuffer), "%s\n%T: %T\n%T: %i\n", sOwner, "Mode", iClient, "Mode 2", iClient, "CoolDown", iClient, ItemTest.CoolDown);
		case 3: FormatEx(sItemBuffer, sizeof(sItemBuffer), "%s\n%T: %T\n%T: %i\n", sOwner, "Mode", iClient, "Mode 3", iClient, "Max Uses", iClient, ItemTest.MaxUses);
		case 4: FormatEx(sItemBuffer, sizeof(sItemBuffer), "%s\n%T: %T\n%T: %i\n%T: %i", sOwner, "Mode", iClient, "Mode 4", iClient, "CoolDown", iClient, ItemTest.CoolDown, "Max Uses", iClient, ItemTest.MaxUses);
		case 5: FormatEx(sItemBuffer, sizeof(sItemBuffer), "%s\n%T: %T\n%T: %i\n%T: %i", sOwner, "Mode", iClient, "Mode 5", iClient, "CoolDown", iClient, ItemTest.CoolDown, "Max Uses", iClient, ItemTest.MaxUses);
		default: FormatEx(sItemBuffer, sizeof(sItemBuffer), "%s\n%T: %T\n\n", sOwner, "Mode", iClient, "Mode Default", iClient);
	}
	hMenu.AddItem("", sItemBuffer, ITEMDRAW_DISABLED);
	hMenu.AddItem("", "", ITEMDRAW_SPACER);
	#if defined EW_MODULE_EBAN
	char sItemTemp_eban[64], sItemBuffer_eban[64];
	int iUserId = INVALID_ENT_REFERENCE;
	if(ItemTest.OwnerID != INVALID_ENT_REFERENCE) iUserId = GetClientUserId(ItemTest.OwnerID);
	FormatEx(sItemTemp_eban, sizeof(sItemTemp_eban), "1/%i", iUserId);
	FormatEx(sItemBuffer_eban, sizeof(sItemBuffer_eban), "%T", "EBan a Player", iClient);
	hMenu.AddItem(sItemTemp_eban, sItemBuffer_eban);
	#endif
	#if defined EW_MODULE_TRANSFER
	char sItemTemp_transfer[64], sItemBuffer_transfer[64];
	FormatEx(sItemTemp_transfer, sizeof(sItemTemp_transfer), "2/%i", iItemIndex);
	FormatEx(sItemBuffer_transfer, sizeof(sItemBuffer_transfer), "%T", "Transfer Item", iClient);
	hMenu.AddItem(sItemTemp_transfer, sItemBuffer_transfer);
	#endif
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

#if defined EW_MODULE_TRANSFER
void EWM_Menu_PM_ItemTransfer(int iClient, int iItemIndex)
{
	class_ItemList ItemTest;
	g_ItemList.GetArray(iItemIndex, ItemTest, sizeof(ItemTest));
	
	if(!IsValidEdict(ItemTest.WeaponID))
	{
		CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Item not available");
		return;
	}
	
	Menu hMenu = CreateMenu(EWM_Menu_PM_ItemTransfer_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %s:", "EW_Tag", iClient, "Receiver of the Item", iClient, ItemTest.Name);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	bool bNotFound = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || i == ItemTest.OwnerID) continue;
		#if defined EW_MODULE_EBAN
		if(g_EbanClients[i].Banned) continue;
		#endif
		if(ItemTest.OwnerID != INVALID_ENT_REFERENCE)
			if(GetClientTeam(i) != GetClientTeam(ItemTest.OwnerID)) continue;
		
		bNotFound = false;
		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i", iItemIndex, GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%i", i, GetClientUserId(i));
		hMenu.AddItem(sIndexTemp, sMenuTemp);
	}
	if(bNotFound)
	{
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "No Receivers", iClient);
		hMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}
#endif

#if defined EW_MODULE_SPAWN
void EWM_Menu_PM_SpawnItemList(int iClient)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_SpawnItemList_Handler);
	char sMenuTranslate[128], sMenuTemp[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "List to Spawn", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	bool bNotFound = true;
	for(int i = 0; i<g_ItemConfig.Length; i++)
	{
		class_ItemConfig ItemTest;
		g_ItemConfig.GetArray(i, ItemTest, sizeof(ItemTest));
		if(!StrEqual(ItemTest.Spawner, ""))
		{
			bNotFound = false;
			char sIndexItem[32];
			FormatEx(sIndexItem, sizeof(sIndexItem), "%d", i);
			hMenu.AddItem(sIndexItem, ItemTest.Name);
		}
	}
	if(bNotFound)
	{
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "No Items for Spawn", iClient);
		hMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_SpawnItemStrip(int iClient, int iIndexItem)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_SpawnItemStrip_Handler);
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "Strip Weapon", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	char sIndexItem[64], sMenuTemp[64];
	FormatEx(sIndexItem, sizeof(sIndexItem), "%d/%d", iIndexItem, 1);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Strip Weapon", iClient);
	hMenu.AddItem(sIndexItem, sMenuTemp);
	FormatEx(sIndexItem, sizeof(sIndexItem), "%d/%d", iIndexItem, 0);
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not Strip Weapon", iClient);
	hMenu.AddItem(sIndexItem, sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_Menu_PM_SpawnItemTarget(int iClient, int iItemIndex, int iStrip)
{
	Menu hMenu = CreateMenu(EWM_Menu_PM_SpawnItemTarget_Handler);
	char sMenuTranslate[128], sIndexTemp[96], sMenuTemp[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "Recipient of a New Item", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	bool bNotFound = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i) || !IsClientConnected(i)) continue;
		if(GetClientTeam(i) != 2 && GetClientTeam(i) != 3) continue;
		#if defined EW_MODULE_EBAN
		if(g_EbanClients[i].Banned) continue;
		#endif
		
		bNotFound = false;
		FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%i", iItemIndex, iStrip, GetClientUserId(i));
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%N |#%i", i, GetClientUserId(i));
		hMenu.AddItem(sIndexTemp, sMenuTemp);
	}
	if(bNotFound)
	{
		FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "No Receivers", iClient);
		hMenu.AddItem("", sMenuTemp, ITEMDRAW_DISABLED);
	}
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}
#endif

//-------------------------------------------------------
// Purpose: Menu Handles
//-------------------------------------------------------
public int EWM_Menu_PM_ItemList_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iItemIndex = StringToInt(sOption);
			class_ItemList ItemTest;
			g_ItemList.GetArray(iItemIndex, ItemTest, sizeof(ItemTest));
			if(ItemTest.WeaponID != INVALID_ENT_REFERENCE)
			{
				EWM_Menu_PM_ItemInfo(iClient, iItemIndex);
			} else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Item not available");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

#if defined EW_MODULE_EBAN
public int EWM_Menu_PM_EBanList_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));
			if(IsValidClient(iTarget))
			{
				EWM_Menu_PM_EBanDuration(iClient, iTarget);
			} else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int EWM_Menu_PM_EUnBanList_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));
			if(IsValidClient(iTarget))
			{
				EWM_Menu_PM_EBanInfo(iClient, iTarget);
			} else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int EWM_Menu_PM_EBanDuration_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_Menu_PM_EBanList(iClient);
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[2][64];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 2, 64);
			int iDuration = StringToInt(Explode_sParam[0]);
			int iTarget = GetClientOfUserId(StringToInt(Explode_sParam[1]));
			if(IsValidClient(iTarget))
			{
				EWM_Menu_PM_EBanReason(iClient, iTarget, iDuration);
			}  else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int EWM_Menu_PM_EBanReason_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_Menu_PM_EBanList(iClient);
		case MenuAction_Select:
		{
			char sSelected[96], Explode_sParam[3][96], sReason[32];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 3, 96);
			int iDuration = StringToInt(Explode_sParam[0]);
			int iTarget = GetClientOfUserId(StringToInt(Explode_sParam[1]));
			FormatEx(sReason, sizeof(sReason), "%s", Explode_sParam[2]);
			if(IsValidClient(iTarget))
			{
				EWM_Eban_BanClient(iTarget, iClient, iDuration, sReason);
			}  else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}

public int EWM_Menu_PM_EBanInfo_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iTarget = GetClientOfUserId(StringToInt(sOption));
			if(IsValidClient(iTarget))
			{
				EWM_Eban_UnBanClient(iTarget, iClient, "No Reason");
			} else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				if (g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
				else delete hMenu;
			}
		}
	}
}
#endif

public int EWM_Menu_PM_ItemInfo_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_Menu_PM_ItemList(iClient);
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[2][64];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 2, 64);
			int iComm = StringToInt(Explode_sParam[0]);
			int iVar = StringToInt(Explode_sParam[1]);
			#if defined EW_MODULE_EBAN
			if(iComm == 1)
			{
				int iTarget = GetClientOfUserId(iVar);
				if(!IsValidClient(iTarget))
				{
					CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
					return;
				}
				EWM_Menu_PM_EBanDuration(iClient, iTarget);
			}
			#endif
			#if defined EW_MODULE_TRANSFER
			if(iComm == 2) EWM_Menu_PM_ItemTransfer(iClient, iVar);
			#endif
		}
	}
}

#if defined EW_MODULE_TRANSFER
public int EWM_Menu_PM_ItemTransfer_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_Menu_PM_ItemList(iClient);
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[2][64];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 2, 64);
			int iItemIndex = StringToInt(Explode_sParam[0]);
			int iReceiver = GetClientOfUserId(StringToInt(Explode_sParam[1]));
			if(!IsValidClient(iReceiver))
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Receiver is not valid anymore");
				return;
			}
			EWM_Transfer_Function(iClient, iItemIndex, iReceiver, true);
		}
	}
}
#endif

#if defined EW_MODULE_SPAWN
public int EWM_Menu_PM_SpawnItemList_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iIndexItem = StringToInt(sOption);
			EWM_Menu_PM_SpawnItemStrip(iClient, iIndexItem);
		}
	}
}

public int EWM_Menu_PM_SpawnItemStrip_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[2][64];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 2, 64);
			int iItemIndex = StringToInt(Explode_sParam[0]);
			int iStrip = StringToInt(Explode_sParam[1]);
			EWM_Menu_PM_SpawnItemTarget(iClient, iItemIndex, iStrip);
		}
	}
}

public int EWM_Menu_PM_SpawnItemTarget_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE) DisplayTopMenu(g_hAdminMenu, iClient, TopMenuPosition_LastCategory);
		case MenuAction_Select:
		{
			char sSelected[96], Explode_sParam[3][96];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 3, 96);
			int iItemIndex = StringToInt(Explode_sParam[0]);
			int iStrip = StringToInt(Explode_sParam[1]);
			int iUserID = StringToInt(Explode_sParam[2]);
			bool bStrip = false;
			if(iStrip == 1) bStrip= true;
			EWM_Spawn_Spawn(iClient, iUserID, iItemIndex, bStrip);
		}
	}
}
#endif
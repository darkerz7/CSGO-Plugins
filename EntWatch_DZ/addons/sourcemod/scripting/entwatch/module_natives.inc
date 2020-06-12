#define EW_MODULE_NATIVES

#tryinclude <EntWatch>

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hThis, bool bLate, char[] sError, int iErr_max)
{
	#if defined EW_MODULE_EBAN
	CreateNative("EntWatch_IsClientBanned", EWM_Natives_Native_IsClientBanned);
	CreateNative("EntWatch_BanClient", EWM_Natives_Native_BanClient);
	CreateNative("EntWatch_UnbanClient", EWM_Natives_Native_UnbanClient);
	#endif
	CreateNative("EntWatch_IsSpecialItem", EWM_Natives_Native_IsSpecialItem);
	CreateNative("EntWatch_HasSpecialItem", EWM_Natives_Native_HasSpecialItem);

	RegPluginLibrary("EntWatch");

	g_bLateLoad = bLate;

	return APLRes_Success;
}

stock void EWM_Natives_OnPluginStart()
{
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

#if defined EW_MODULE_EBAN
public int EWM_Natives_Native_IsClientBanned(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client");
		return false;
	}

	if(g_EbanClients[iClient].Banned)
	{
		SetNativeCellRef(2, g_EbanClients[iClient].TimeStamp_Issued);
		SetNativeCellRef(3, g_EbanClients[iClient].Duration);
		SetNativeString(4, g_EbanClients[iClient].Reason, 64, true);
		return true;
	}

	return false;
}

public int EWM_Natives_Native_BanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);
	int iAdmin = GetNativeCell(2);
	int iDuration = GetNativeCell(3);
	char sReason[64];
	GetNativeString(4, sReason, sizeof(sReason));

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	
	if(!IsValidClient(iAdmin) || !IsClientConnected(iAdmin)) iAdmin = 0;

	EWM_Eban_BanClient(iClient, iAdmin, iDuration, sReason);
	return true;
}

public int EWM_Natives_Native_UnbanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);
	int iAdmin = GetNativeCell(2);
	char sReason[64];
	GetNativeString(3, sReason, sizeof(sReason));

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	
	if(!IsValidClient(iAdmin) || !IsClientConnected(iAdmin)) iAdmin = 0;

	EWM_Eban_UnBanClient(iClient, iAdmin, sReason);
	return true;
}
#endif

public int EWM_Natives_Native_IsSpecialItem(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	
	int iEntity = GetNativeCell(1);
	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		for(int j = 0; j < ItemTest.ButtonsArray.Length; j++)
		{
			if(ItemTest.ButtonsArray.Get(j) == iEntity) return true;
		}
	}

	return false;
}

public int EWM_Natives_Native_HasSpecialItem(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}

	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.WeaponID != INVALID_ENT_REFERENCE)
			if(ItemTest.OwnerID == iClient) return true;
	}

	return false;
}
#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks> //only detour edition https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589
#include <clientprefs>
#include <csgocolors_fix>
#include <soundlib2_windows>

#define ALL_CLIENTS		-1

enum struct class_Sample
{
	int		Entity;
	char	File[PLATFORM_MAX_PATH];
	float	SndLength;
	float	Volume;
	float	InitVolume;
	bool	Playing;
	bool	Common;
	float	TimeShtamp;
	int		EntSource;
}

ArrayList g_aSample;
StringMap g_smSourceEnt;

Handle g_hCookie_Disable = INVALID_HANDLE;
Handle g_hCookie_Volume = INVALID_HANDLE;

static Handle g_hAcceptInput;
static int g_iSTSound;

bool	g_bDisabled[MAXPLAYERS + 1] = {false, ...};
int		g_iVolume[MAXPLAYERS + 1] = {100, ...};

int g_iRoundNum = 0;

public Plugin myinfo = {
	name = "Map Music Control with Dynamic Volume Control",
	author = "DarkerZ[RUS]",
	description = "Allows clients to adjust ambient sounds played by the map",
	version = "1.DZ.7_win",
	url = "dark-skill.ru"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	RegPluginLibrary("MapMusic");

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_aSample = new ArrayList(512);
	g_smSourceEnt = new StringMap();
	
	RegConsoleCmd("sm_mapmusic", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_music", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_volume", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_stopmusic", Command_StopMusic, "Toggles map music");
	RegConsoleCmd("sm_startmusic", Command_StartMusic, "Toggles map music");
	RegConsoleCmd("sm_playmusic", Command_StartMusic, "Toggles map music");
	
	LoadTranslations("MapMusic_DZ.phrases");
	
	g_hCookie_Disable	= RegClientCookie("cookie_map_music", "Disable Map Music", CookieAccess_Private);
	g_hCookie_Volume	= RegClientCookie("cookie_map_music_volume", "Disable Map Music Volume", CookieAccess_Private);
	SetCookieMenuItem(ItemCookieMenu, 0, "Map Music");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	
	char sConf[128];
	switch(GetEngineVersion())
	{
		case Engine_CSGO:       sConf = "sdktools.games\\engine.csgo";
		case Engine_CSS:        sConf = "sdktools.games\\engine.css";
		case Engine_TF2:        sConf = "sdktools.games\\engine.tf";
		case Engine_Left4Dead2: sConf = "sdktools.games\\engine.Left4Dead2";
		default: SetFailState("Game Engine ??");
	}

	Handle hGameConf = LoadGameConfigFile(sConf);

	if(hGameConf == null) SetFailState("Why you no has gamedata?");

	int iOffset = GameConfGetOffset(hGameConf, "AcceptInput");
	g_hAcceptInput = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	if(g_hAcceptInput == null) SetFailState("Failed to DHook \"AcceptInput\".");

	DHookAddParam(g_hAcceptInput, HookParamType_CharPtr);
	DHookAddParam(g_hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hAcceptInput, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP);
	DHookAddParam(g_hAcceptInput, HookParamType_Int);

	delete hGameConf;
}

public void OnClientCookiesCached(int iClient)
{
	char sBuffer_cookie[8];
	GetClientCookie(iClient, g_hCookie_Disable, sBuffer_cookie, sizeof(sBuffer_cookie));
	g_bDisabled[iClient] = view_as<bool>(StringToInt(sBuffer_cookie));
	GetClientCookie(iClient, g_hCookie_Volume, sBuffer_cookie, sizeof(sBuffer_cookie));
	if(StrEqual(sBuffer_cookie,""))
	{
		SetClientCookie(iClient, g_hCookie_Volume, "50");
		strcopy(sBuffer_cookie, sizeof(sBuffer_cookie), "50");
	}
	g_iVolume[iClient] = StringToInt(sBuffer_cookie);
}

public void OnClientDisconnect_Post(int iClient)
{
	g_bDisabled[iClient] = false;
	g_iVolume[iClient] = 50;
}

public void ItemCookieMenu(int iClient, CookieMenuAction hAction, any Info, char[] sBuffer, int iMaxlen)
{
	switch(hAction)
	{
		case CookieMenuAction_DisplayOption: FormatEx(sBuffer, iMaxlen, "%T", "MM Cookie Menu", iClient);
		case CookieMenuAction_SelectOption: MapMusicMenu(iClient);
	}
}

void MapMusicMenu(int iClient)
{
	Menu hMenu = CreateMenu(MapMusicMenuHandler, MENU_ACTIONS_DEFAULT);

	char sMenuTranslate[256];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T", "MM Tag Menu", iClient, "MM Menu Title", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T \n%T", "MM Menu Music", iClient, g_bDisabled[iClient] ? "MM Disabled" : "MM Enabled", iClient, "MM Menu AdjustDesc", iClient);
	hMenu.AddItem(g_bDisabled[iClient] ? "enable" : "disable", sMenuTranslate);

	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "MM Menu Vol", iClient, g_iVolume[iClient]);

	switch(g_iVolume[iClient])
	{
		case 100:	hMenu.AddItem("vol_90", sMenuTranslate);
		case 90:	hMenu.AddItem("vol_80", sMenuTranslate);
		case 80:	hMenu.AddItem("vol_70", sMenuTranslate);
		case 70:	hMenu.AddItem("vol_60", sMenuTranslate);
		case 60:	hMenu.AddItem("vol_50", sMenuTranslate);
		case 50:	hMenu.AddItem("vol_40", sMenuTranslate);
		case 40:	hMenu.AddItem("vol_30", sMenuTranslate);
		case 30:	hMenu.AddItem("vol_20", sMenuTranslate);
		case 20:	hMenu.AddItem("vol_10", sMenuTranslate);
		case 10:	hMenu.AddItem("vol_5", sMenuTranslate);
		case 5:		hMenu.AddItem("vol_100", sMenuTranslate);
		default:	hMenu.AddItem("vol_100", sMenuTranslate);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MapMusicMenuHandler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iParam2 == MenuCancel_ExitBack) ShowCookieMenu(iClient);
		case MenuAction_Select:
		{
			char sOption[8];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			if(StrEqual(sOption, "disable"))
			{
				g_bDisabled[iClient] = true;
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Disable");
				SetClientCookie(iClient, g_hCookie_Disable, "1");
				Client_StopSound(iClient);
			}else if(StrEqual(sOption, "enable"))
			{
				if(g_bDisabled[iClient]) Client_UpdateMusics(iClient);
				g_bDisabled[iClient] = false;
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Enable");
				SetClientCookie(iClient, g_hCookie_Disable, "0");
			}else if(StrContains(sOption, "vol") >= 0)
			{
				g_bDisabled[iClient] = false;
				SetClientCookie(iClient, g_hCookie_Disable, "0");
				g_iVolume[iClient] = StringToInt(sOption[4]);
				SetClientCookie(iClient, g_hCookie_Volume, sOption[4]);
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Volume", g_iVolume[iClient]);
				Client_UpdateMusics(iClient);
			}
			MapMusicMenu(iClient);
		}
	}
}

public void OnMapStart()
{
	g_aSample.Clear();
	g_smSourceEnt.Clear();
	g_iRoundNum = 0;
	g_iSTSound = FindStringTable("soundprecache");
	if(g_iSTSound == INVALID_STRING_TABLE) SetFailState("Failed to find string table \"soundprecache\".");
}

public void OnMapEnd()
{
	g_aSample.Clear();
	g_smSourceEnt.Clear();
}

public Action Event_RoundStart(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	g_aSample.Clear();
	g_iRoundNum++;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(IsValidEntity(iEntity))
	{
		if(sClassname[0] == 'a' && strcmp(sClassname, "ambient_generic") == 0)
		{
			SetEntProp(iEntity, Prop_Data, "m_spawnflags", GetEntProp(iEntity, Prop_Data, "m_spawnflags")|32);
			DHookEntity(g_hAcceptInput, false, iEntity);
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
		//fix ent spawned after ambient_generic
		char sEntName[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
		if(sEntName[0])//have targetname
		{
			int entRef;
			if(g_smSourceEnt.GetValue(sEntName, entRef)) g_smSourceEnt.SetValue(sEntName, EntIndexToEntRef(iEntity), true);
		}
	}
}

public void OnEntitySpawned(int iEntity)
{
	int iFlags = GetEntProp(iEntity, Prop_Data, "m_spawnflags");
	if(!(iFlags & 1))
	{
		char sSourceEntName[64], sEntName[64];
		GetEntPropString(iEntity, Prop_Data, "m_sSourceEntName", sSourceEntName, sizeof(sSourceEntName));
		if(sSourceEntName[0])
		{
			for (int i = 0; i <= GetEntityCount(); i++)
			{
				if (IsValidEntity(i))
				{
					GetEntPropString(i, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
					if(strcmp(sSourceEntName, sEntName, false) == 0)
					{
						g_smSourceEnt.SetValue(sSourceEntName, EntIndexToEntRef(i), true);
						break;
					}
				}
			}
		}
	}
}

public MRESReturn AcceptInput(int iEntity, Handle hReturn, Handle hParams)
{
	if(!IsValidEntity(iEntity)) return MRES_Ignored;
	
	char sCommand[128], sVolume[128];
	DHookGetParamString(hParams, 1, sCommand, sizeof(sCommand));
	
	int iType = -1;
	float fVolume = 0.0;
	iType = DHookGetParamObjectPtrVar(hParams, 4, 16, ObjectValueType_Int);

	if(iType == 1) 
		fVolume = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Float);
	else if(iType == 2)
	{
		DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, sVolume, sizeof(sVolume));
		StringToFloatEx(sVolume, fVolume);
	}
	
	char sSoundFile[PLATFORM_MAX_PATH], sSoundFileFullPath[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_iszSound", sSoundFile, sizeof(sSoundFile));
	//ignore nonmusic file
	if(!((StrContains(sSoundFile, ".mp3", false) != -1) || (StrContains(sSoundFile, ".wav", false) != -1))) return MRES_Ignored;
	
	class_Sample ItemSample;
	
	if(sSoundFile[0] == '*' || sSoundFile[0] == '#' || sSoundFile[0] == '~' || sSoundFile[0] == ')') FormatEx(ItemSample.File, PLATFORM_MAX_PATH, "%s", sSoundFile[1]);
		else FormatEx(ItemSample.File, PLATFORM_MAX_PATH, "%s", sSoundFile);
	
	FormatEx(sSoundFileFullPath, PLATFORM_MAX_PATH, "sound/%s", ItemSample.File);
	
	AddToStringTable(g_iSTSound, ItemSample.File);
	PrecacheSound(ItemSample.File, false);
	
	int iIndexEntity = EntIndexToEntRef(iEntity);
	bool bNotFound = true;
	for(int i = 0; i<g_aSample.Length; i++)
	{
		class_Sample ItemTest;
		g_aSample.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.Entity == iIndexEntity && strcmp(ItemTest.File, ItemSample.File, false) == 0) //WTF new soundfile in older ambient_generic
		{
			ItemSample = ItemTest;
			bNotFound = false;
			break;
		}
	}
	
	//detect new sample
	if(bNotFound)
	{
		Handle hFile = OpenSoundFile(sSoundFileFullPath, true);
		if(hFile == INVALID_HANDLE) return MRES_Ignored;
		
		ItemSample.SndLength = float(GetSoundLength(hFile));
		delete hFile;
		
		ItemSample.Entity = iIndexEntity;
		ItemSample.InitVolume = float(GetEntProp(iEntity, Prop_Data, "m_iHealth"));
		if(ItemSample.InitVolume < 0.1) ItemSample.InitVolume = 10.0;
		ItemSample.Volume = ItemSample.InitVolume;
		ItemSample.Playing = false;
		
		ItemSample.EntSource = iIndexEntity;
		int iFlags = GetEntProp(iEntity, Prop_Data, "m_spawnflags");
		if(!(iFlags & 1))
		{
			char sSourceEntName[64];
			GetEntPropString(iEntity, Prop_Data, "m_sSourceEntName", sSourceEntName, sizeof(sSourceEntName));
			if(sSourceEntName[0])
			{
				int entRef;
				if(g_smSourceEnt.GetValue(sSourceEntName, entRef))
				{
					int sourceEnt = EntRefToEntIndex(entRef);
					if(IsValidEntity(sourceEnt)) ItemSample.EntSource = entRef;
				}
			}
		}
		
		if(ItemSample.SndLength >= 4.0)
		{
			ItemSample.Common = false;
			g_aSample.PushArray(ItemSample, sizeof(ItemSample));
		} else ItemSample.Common = true;
	}
	
	if(strcmp(sCommand, "PlaySound", false) == 0 || strcmp(sCommand, "FadeIn", false) == 0 || (strcmp(sCommand, "Volume", false) == 0 && (fVolume >= 0.1)) || strcmp(sCommand, "ToggleSound", false) == 0)
	{
		if(!ItemSample.Common)
		{
			//Change Volume
			if(strcmp(sCommand, "Volume", false) == 0 && ItemSample.Volume != fVolume)
			{
				ItemSample.Volume = fVolume;
				if(!ItemSample.Playing)
				{
					ItemSample.Playing = true;
					ItemSample.TimeShtamp = GetGameTime() + ItemSample.SndLength - 1.0;
					SaveSample(ItemSample);
					DataPack pack;
					CreateDataTimer(ItemSample.SndLength, Timer_OnSoundEnd, pack, TIMER_FLAG_NO_MAPCHANGE);
					pack.WriteCell(ItemSample.Entity);
					pack.WriteString(ItemSample.File);
					pack.WriteCell(g_iRoundNum);
				}else SaveSample(ItemSample);
				
				PlaySampleAll(ItemSample);
				
				DHookSetReturn(hReturn, false);
				return MRES_Supercede;
			}
			
			//Already playing
			if(ItemSample.Playing)
			{
				if(strcmp(sCommand, "ToggleSound", false) == 0)
				{
					ItemSample.Playing = false;
					SaveSample(ItemSample);
					StopSoundEx(ALL_CLIENTS, ItemSample.File);
				}
				DHookSetReturn(hReturn, false);
				return MRES_Supercede;
			}
			
			ItemSample.Playing = true;
			ItemSample.TimeShtamp = GetGameTime() + ItemSample.SndLength - 1.0;
			SaveSample(ItemSample);
			PlaySampleAll(ItemSample);
			DataPack pack;
			CreateDataTimer(ItemSample.SndLength, Timer_OnSoundEnd, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(ItemSample.Entity);
			pack.WriteString(ItemSample.File);
			pack.WriteCell(g_iRoundNum);
			
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}else
		{
			PlaySampleAll(ItemSample);
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}else if(strcmp(sCommand, "StopSound", false) == 0 || strcmp(sCommand, "FadeOut", false) == 0 || (strcmp(sCommand, "Volume", false) == 0 && (fVolume < 0.1)))
	{
		if(!ItemSample.Common && ItemSample.Playing)
		{
			if(ItemSample.EntSource == ItemSample.Entity) StopSoundEx(ALL_CLIENTS, ItemSample.File);
			else StopSoundEx(ALL_CLIENTS, ItemSample.File, false, EntRefToEntIndex(ItemSample.EntSource)); //stoping loop sounds
			ItemSample.Playing = false;
			SaveSample(ItemSample);
		}else if(ItemSample.EntSource != ItemSample.Entity) StopSoundEx(ALL_CLIENTS, ItemSample.File, false, EntRefToEntIndex(ItemSample.EntSource)); //stoping loop sounds
	}else if(strcmp(sCommand, "Kill", false) == 0)
	{
		if(!ItemSample.Common)
		{
			if(ItemSample.Playing)
			{
				if(ItemSample.EntSource == ItemSample.Entity) StopSoundEx(ALL_CLIENTS, ItemSample.File);
				else StopSoundEx(ALL_CLIENTS, ItemSample.File, false, EntRefToEntIndex(ItemSample.EntSource)); //stoping loop sounds
			}
			RemoveSample(ItemSample);
		}else if(ItemSample.EntSource != ItemSample.Entity) StopSoundEx(ALL_CLIENTS, ItemSample.File, false, EntRefToEntIndex(ItemSample.EntSource)); //stoping loop sounds
	}
	
	return MRES_Handled;
}

void SaveSample(class_Sample ItemSample)
{
	for(int i = 0; i<g_aSample.Length; i++)
	{
		class_Sample ItemTest;
		g_aSample.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.Entity == ItemSample.Entity && strcmp(ItemTest.File, ItemSample.File, false) == 0)
		{
			g_aSample.SetArray(i, ItemSample, sizeof(ItemSample));
			return;
		}
	}
	g_aSample.PushArray(ItemSample, sizeof(ItemSample)); // not found
}

void RemoveSample(class_Sample ItemSample)
{
	for(int i = 0; i<g_aSample.Length; i++)
	{
		class_Sample ItemTest;
		g_aSample.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.Entity == ItemSample.Entity && strcmp(ItemTest.File, ItemSample.File, false) == 0)
		{
			g_aSample.Erase(i);
			break;
		}
	}
}

void PlaySample(int iClient, class_Sample ItemSample)
{
	if(IsClientInGame(iClient))
	{
		float fSampleVolume = ItemSample.Volume;
		if(fSampleVolume < 0.1) fSampleVolume = ItemSample.InitVolume;
		float fPlayVolume = (fSampleVolume*float(g_iVolume[iClient])) / 1000.0;
		if(FloatCompare(fPlayVolume,0.5)>0) fPlayVolume=0.25+(fPlayVolume-0.5)*1.5;
			else fPlayVolume*=0.5;
		int iFlags = GetEntProp(EntRefToEntIndex(ItemSample.Entity), Prop_Data, "m_spawnflags");
		if(iFlags & 1)
		{
			if(!ItemSample.Common)
				EmitSoundToClient(iClient, ItemSample.File, SOUND_FROM_PLAYER, SNDCHAN_STATIC,
						 SNDLEVEL_NONE, SND_CHANGEVOL, fPlayVolume, SNDPITCH_NORMAL, -1,
						 _, _, true);
			else
				EmitSoundToClient(iClient, ItemSample.File, SOUND_FROM_PLAYER, SNDCHAN_STATIC,
						 SNDLEVEL_NONE, SND_NOFLAGS, fPlayVolume, SNDPITCH_NORMAL, -1,
						 _, _, true);
		}
		else
		{
			EmitSoundToClient(iClient, ItemSample.File, ItemSample.EntSource, SNDCHAN_STATIC,
					SNDLEVEL_NORMAL, SND_CHANGEVOL, fPlayVolume, SNDPITCH_NORMAL, -1,
					_, _, true);
		}
	}
}

void PlaySampleAll(class_Sample ItemSample)
{
	for(int i = 1; i <= MaxClients; i++) if(!g_bDisabled[i]) PlaySample(i, ItemSample);
}

stock void StopSoundEx(int iClient, const char[] sSample, bool bForAll = true, int iSourceEntity = -1)
{
	if(iClient == ALL_CLIENTS)
	{
		for(int i = 1; i<= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(bForAll) StopSound(i, SNDCHAN_STATIC, sSample);
				else EmitSoundToClient(i, sSample, iSourceEntity, SNDCHAN_STATIC,
						 SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.0, SNDPITCH_NORMAL, -1,
						 _, _, true);
			}
		}
	}else if(IsClientInGame(iClient))
	{
		if(bForAll) StopSound(iClient, SNDCHAN_STATIC, sSample);
		else EmitSoundToClient(iClient, sSample, iSourceEntity, SNDCHAN_STATIC,
					 SNDLEVEL_NORMAL, SND_CHANGEVOL, 0.0, SNDPITCH_NORMAL, -1,
					 _, _, true);
	}
}

public Action Timer_OnSoundEnd(Handle timer, DataPack pack)
{
	pack.Reset();
	int iEntity = pack.ReadCell();
	char sSoundFile[PLATFORM_MAX_PATH];
	pack.ReadString(sSoundFile, PLATFORM_MAX_PATH);
	int iRoundNum = pack.ReadCell();
	if(iRoundNum == g_iRoundNum)
	{
		float iCurrentTime = GetGameTime();
		
		for(int i = 0; i<g_aSample.Length; i++)
		{
			class_Sample ItemTest;
			g_aSample.GetArray(i, ItemTest, sizeof(ItemTest));
			if(ItemTest.Entity == iEntity && strcmp(ItemTest.File, sSoundFile, false) == 0)
			{
				if(ItemTest.Playing && ItemTest.TimeShtamp <= iCurrentTime)
				{
					//for(int j = 1; j <= MaxClients; j++)
					//	if(IsClientInGame(j)) PrintToConsole(j, "[Ambient: %f] StopMusic. Sample: %s, Stamp: %f, CurrentTime: %f", GetEngineTime(), ItemTest.File, ItemTest.TimeShtamp, iCurrentTime);
					ItemTest.Playing = false;
					g_aSample.SetArray(i, ItemTest, sizeof(ItemTest));
				}
				break;
			}
		}
	}
}

stock void Client_UpdateMusics(int iClient)
{
	for(int i = 0; i<g_aSample.Length; i++)
	{
		class_Sample ItemTest;
		g_aSample.GetArray(i, ItemTest, sizeof(ItemTest));
		if(IsValidEntity(EntRefToEntIndex(ItemTest.Entity)) && ItemTest.Playing) PlaySample(iClient, ItemTest);
	}
}

stock void Client_StopSound(int iClient)
{
	ClientCommand(iClient, "playgamesound Music.StopAllExceptMusic");
	ClientCommand(iClient, "playgamesound Music.StopAllMusic");
}

public Action Command_StopMusic(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		if(g_bDisabled[iClient])
		{
			Client_UpdateMusics(iClient);
			g_bDisabled[iClient] = false;
			CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Enable");
			SetClientCookie(iClient, g_hCookie_Disable, "0");
		} else
		{
			CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Disable");
			SetClientCookie(iClient, g_hCookie_Disable, "1");
			Client_StopSound(iClient);
			g_bDisabled[iClient] = true;
		}
	}
	return Plugin_Handled;
}

public Action Command_StartMusic(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		if(g_bDisabled[iClient]) Client_UpdateMusics(iClient);
		g_bDisabled[iClient] = false;
		CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Enable");
		SetClientCookie(iClient, g_hCookie_Disable, "0");
	}
	return Plugin_Handled;
}

public Action Command_Music(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		if(iArgs >= 1)
		{
			char sArg[6];
			GetCmdArg(1, sArg, sizeof(sArg));
			int iVolume = StringToInt(sArg);
			if(StrEqual(sArg, "disallow", false) || StrEqual(sArg, "off", false) || iVolume <= 0)
			{
				g_bDisabled[iClient] = true;
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Disable");
				SetClientCookie(iClient, g_hCookie_Disable, "1");
				Client_StopSound(iClient);
				return Plugin_Handled;
			}else if(StrEqual(sArg, "allow", false) || StrEqual(sArg, "on", false))
			{
				if(g_bDisabled[iClient]) Client_UpdateMusics(iClient);
				g_bDisabled[iClient] = false;
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Enable");
				SetClientCookie(iClient, g_hCookie_Disable, "0");
				return Plugin_Handled;
			}else
			{
				if(iVolume > 100) iVolume = 100;
				g_bDisabled[iClient] = false;
				SetClientCookie(iClient, g_hCookie_Disable, "0");
				g_iVolume[iClient] = iVolume;
				CPrintToChat(iClient, "%t %t", "MM Tag", "MM Text Volume", g_iVolume[iClient]);
				char sVolume[8];
				IntToString(g_iVolume[iClient], sVolume, sizeof(sVolume));
				SetClientCookie(iClient, g_hCookie_Volume, sVolume);
				Client_UpdateMusics(iClient);
				return Plugin_Handled;
			}
		}

		MapMusicMenu(iClient);
	}
	return Plugin_Handled;
}
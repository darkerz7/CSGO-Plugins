#pragma semicolon 1
#pragma dynamic 131072

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <clientprefs>
#include <csgocolors>
#include <soundlib2_windows>

#define PLUGIN_NAME 	"Map Music Control with Dynamic Volume Control"
#define PLUGIN_VERSION 	"4.3f_win"

//#define Debug

#define ALL_CLIENTS		-1

float g_fCmdTime[MAXPLAYERS+1];

Handle cDisableSounds = INVALID_HANDLE;
Handle cDisableSoundVolume = INVALID_HANDLE;

bool disabled[MAXPLAYERS + 1] = {false, ...};
int clientvolume[MAXPLAYERS + 1] = {100, ...};

ConVar sm_stopmusic_music_length = null;
float f_stopmusic_music_length;

Handle hAcceptInput;

bool bLateLoad = false;

float fNextAllowedTime = 0.0;

StringMap smSampleVolume;
StringMap smSampleTimerArray;
StringMap smEntitySample;

int iRoundNum;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "Mitch + SHUFEN from POSSESSION.tokyo + Multi lang by Yuna + DarkerZ [RUS]",
	description = "Allows clients to adjust ambient sounds played by the map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/ + https://possession.tokyo"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("mapmusic");

	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar("sm_mapmusic_version", PLUGIN_VERSION, "Stop Map Music", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegConsoleCmd("sm_mapmusic", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_music", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_volume", Command_Music, "Brings up the music menu");
	RegConsoleCmd("sm_stopmusic", Command_StopMusic, "Toggles map music");
	RegConsoleCmd("sm_startmusic", Command_StartMusic, "Toggles map music");
	RegConsoleCmd("sm_playmusic", Command_StartMusic, "Toggles map music");

	LoadTranslations("mapmusic.phrases");

	sm_stopmusic_music_length = CreateConVar("sm_stopmusic_music_length", "10.0", "How long required length for it will be music files.", _, true, 0.0);
	f_stopmusic_music_length = sm_stopmusic_music_length.FloatValue;
	sm_stopmusic_music_length.AddChangeHook(OnConVarChanged);

	Handle temp = LoadGameConfigFile("mapmusic.games");
	if(temp == INVALID_HANDLE) {
		SetFailState("Why you no has gamedata?");
		return;
	}

	int offset = GameConfGetOffset(temp, "AcceptInput");
	if(offset == -1) {
		SetFailState("Couldn't prepare DHooks: AcceptInput!");
		return;
	}

	hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	DHookAddParam(hAcceptInput, HookParamType_CharPtr);
	DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(hAcceptInput, HookParamType_Object, 20);
	DHookAddParam(hAcceptInput, HookParamType_Int);

	cDisableSounds = RegClientCookie("cookie_map_music", "Disable Map Music", CookieAccess_Private);
	cDisableSoundVolume = RegClientCookie("cookie_map_music_volume", "Disable Map Music Volume", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, "Map Music");

	AddAmbientSoundHook(view_as<AmbientSHook>(SoundHook));

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);

	smSampleVolume = new StringMap();
	smSampleTimerArray = new StringMap();
	smEntitySample = new StringMap();

	if(bLateLoad) {
		fNextAllowedTime = 0.0;

		for(int i = 1; i <= MaxClients; i++) {
			disabled[i] = false;
			clientvolume[i] = 100;
			if(IsClientInGame(i) && AreClientCookiesCached(i)) {
				OnClientCookiesCached(i);
			}
		}

		int entity = INVALID_ENT_REFERENCE;
		while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE) {
			if(IsValidEntity(entity)) {
				//SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags")|32);
				DHookEntity(hAcceptInput, false, entity);
			}
		}
	}
}

public void OnMapStart() {
	iRoundNum = 0;
}

public void OnMapEnd() {
	fNextAllowedTime = 0.0;

	smSampleVolume.Clear();
	smSampleTimerArray.Clear();
	smEntitySample.Clear();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(convar == sm_stopmusic_music_length)
		f_stopmusic_music_length = convar.FloatValue;
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen){
	if (actions == CookieMenuAction_DisplayOption) {
		Format(buffer, maxlen, "%T", "Cookie_Menu", client);
	}

	if (actions == CookieMenuAction_SelectOption) {
		DisplaySettingsMenu(client);
	}
}

public int PrefMenuHandler(Menu prefmenu, MenuAction actions, int client, int item){
	if (actions == MenuAction_Select) {
		char preference[8];
		
		GetMenuItem(prefmenu, item, preference, sizeof(preference));
		
		if(StrEqual(preference, "disable")) {
			disabled[client] = true;
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicDisable");
			SetClientCookie(client, cDisableSounds, "1");
			Client_StopSound(client);
		} else if(StrEqual(preference, "enable")) {
			if(disabled[client])
				Client_UpdateMusics(client);
			disabled[client] = false;
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicEnable");
			SetClientCookie(client, cDisableSounds, "0");
		}
		
		if(StrContains(preference, "vol") >= 0) {
			disabled[client] = false;
			SetClientCookie(client, cDisableSounds, "0");
			clientvolume[client] = StringToInt(preference[4]);
			SetClientCookie(client, cDisableSoundVolume, preference[4]);
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicVolume", clientvolume[client]);
			Client_UpdateMusics(client);
		}
		DisplaySettingsMenu(client);
	}
	else if(actions == MenuAction_Cancel)
	{
		if(item == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (actions == MenuAction_End) {
		CloseHandle(prefmenu);
	}
}

void DisplaySettingsMenu(int client) {
	Menu prefmenu = CreateMenu(PrefMenuHandler, MENU_ACTIONS_DEFAULT);

	char szMenuTitle[64];
	Format(szMenuTitle, sizeof(szMenuTitle), "%T", "Menu_Title", client);
	prefmenu.SetTitle(szMenuTitle);
	
	char szEnable[256];
	
	FormatEx(szEnable, sizeof(szEnable), "%T \n%T", "Menu_Music", client, disabled[client] ? "Disabled" : "Enabled", client, "Menu_AdjustDesc", client);

	prefmenu.AddItem(disabled[client] ? "enable" : "disable", szEnable);
	
	//char sBuffer[256];
	//FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_AdjustDesc", client);
	//prefmenu.AddItem("info", sBuffer, 1);

	char szItem[64];

	Format(szItem, sizeof(szItem), "%T", "Menu_Vol", client, clientvolume[client]);

	switch(clientvolume[client]) {
		case 100: {
			prefmenu.AddItem("vol_90", szItem);
		}
		case 90: {
			prefmenu.AddItem("vol_80", szItem);
		}
		case 80: {
			prefmenu.AddItem("vol_70", szItem);
		}
		case 70: {
			prefmenu.AddItem("vol_60", szItem);
		}
		case 60: {
			prefmenu.AddItem("vol_50", szItem);
		}
		case 50: {
			prefmenu.AddItem("vol_40", szItem);
		}
		case 40: {
			prefmenu.AddItem("vol_30", szItem);
		}
		case 30: {
			prefmenu.AddItem("vol_20", szItem);
		}
		case 20: {
			prefmenu.AddItem("vol_10", szItem);
		}
		case 10: {
			prefmenu.AddItem("vol_5", szItem);
		}
		case 5: {
			prefmenu.AddItem("vol_100", szItem);
		}
		default: {
			prefmenu.AddItem("vol_100", szItem);
		}
	}
	
	prefmenu.ExitBackButton = true;

	prefmenu.Display(client, MENU_TIME_FOREVER);
}

public void OnClientCookiesCached(int client) {
	char sValue[8];
	GetClientCookie(client, cDisableSounds, sValue, sizeof(sValue));
	disabled[client] = view_as<bool>(StringToInt(sValue));
	GetClientCookie(client, cDisableSoundVolume, sValue, sizeof(sValue));
	if (sValue[0] == '\0') {
		SetClientCookie(client, cDisableSoundVolume, "100");
		strcopy(sValue, sizeof(sValue), "100");
	}
	clientvolume[client] = StringToInt(sValue);
}

public void OnClientDisconnect_Post(int client) {
	g_fCmdTime[client] = 0.0;
	disabled[client] = false;
	clientvolume[client] = 100;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	smSampleVolume.Clear();
	smSampleTimerArray.Clear();
	smEntitySample.Clear();

	iRoundNum++;

	fNextAllowedTime = FloatAdd(GetTickedTime(), 1.0);
}

public void OnEntityCreated(int entity, const char[] classname) {
	if(StrEqual(classname, "ambient_generic", false)){
		//SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags")|32);
		DHookEntity(hAcceptInput, false, entity);
	}
}

public MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams) {
	char command[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, command, sizeof(command));
	if(IsValidEntity(pThis)) {
		char sample[PLATFORM_MAX_PATH];
		GetEntPropString(pThis, Prop_Data, "m_iszSound", sample, sizeof(sample));

		float fSoundLen = 0.0;
		char sPath[PLATFORM_MAX_PATH],sPathFull[PLATFORM_MAX_PATH];
		if(sample[0]=='#') strcopy(sPath, sizeof(sPath), sample[1]); else FormatEx(sPath, sizeof sPath, "%s", sample);
		FormatEx(sPathFull, sizeof sPathFull, "sound/%s", sPath);
		Handle hFile = OpenSoundFile(sPathFull, true);
		if(hFile == INVALID_HANDLE) return MRES_Ignored;
		fSoundLen = float(GetSoundLength(hFile));
		delete hFile;

		if(fSoundLen < f_stopmusic_music_length)
			return MRES_Ignored;

		
		// * Inputs: PlaySound, StopSound, ToggleSound, FadeIn, FadeOut, Volume, Pitch, Kill
		
		
		if(StrEqual(command, "FadeOut", false)) {
			char sString[128];
			DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, sString, sizeof(sString));

			int iTimerStatus[2];
			if(!smSampleTimerArray.GetArray(sample, iTimerStatus, sizeof(iTimerStatus))) {
				for(int i = 0; i < sizeof(iTimerStatus); i++)
					iTimerStatus[i] = 0;
			}
			iTimerStatus[0] = 1;
			smSampleTimerArray.SetArray(sample, iTimerStatus, sizeof(iTimerStatus), true);

			DataPack pack = new DataPack();
			CreateDataTimer(StringToFloat(sString), Timer_FadeOut_StopSound, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteString(sample);
		}

		else if(StrEqual(command, "PlaySound", false) || StrEqual(command, "ToggleSound", false) || StrEqual(command, "FadeIn", false)) {
			int iTimerStatus[2];
			if(smSampleTimerArray.GetArray(sample, iTimerStatus, sizeof(iTimerStatus)))
				if(iTimerStatus[0] == 1) {
					iTimerStatus[0] = 0;
					smSampleTimerArray.SetArray(sample, iTimerStatus, sizeof(iTimerStatus), true);
				}
		}

		else if(StrEqual(command, "StopSound", false)) {
			StopSoundEx(ALL_CLIENTS, sample);
			smSampleVolume.Remove(sample);
		}

		else if(StrEqual(command, "Kill", false)) {
			StopSoundEx(ALL_CLIENTS, sample);
			smSampleVolume.Remove(sample);
			char sRef[32];
			IntToString(EntIndexToEntRef(pThis), sRef, sizeof(sRef));
			smEntitySample.Remove(sRef);
		}
	}
	return MRES_Ignored;
}

public Action Timer_FadeOut_StopSound(Handle timer, DataPack pack) {
	pack.Reset();
	char sample[PLATFORM_MAX_PATH];
	pack.ReadString(sample, sizeof(sample));

	int iTimerStatus[2];
	if(!smSampleTimerArray.GetArray(sample, iTimerStatus, sizeof(iTimerStatus))) {
		KillTimer(timer);
		return Plugin_Stop;
	}
	if(iTimerStatus[0] == 0) {
		KillTimer(timer);
		return Plugin_Stop;
	}
	iTimerStatus[0] = 0;
	smSampleTimerArray.SetArray(sample, iTimerStatus, sizeof(iTimerStatus), true);
	
	StopSoundEx(ALL_CLIENTS, sample);
	smSampleVolume.Remove(sample);
	KillTimer(timer);
	return Plugin_Stop;
}

public Action SoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay) {
	if(flags == SND_SPAWNING)
		return Plugin_Continue;
	
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	char sClassname[64];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	if(!StrEqual(sClassname, "ambient_generic", false)) {
		return Plugin_Continue;
	}

	float fSoundLen = 0.0;
	char sPath[PLATFORM_MAX_PATH],sPathFull[PLATFORM_MAX_PATH];
	if(sample[0]=='#') strcopy(sPath, sizeof(sPath), sample[1]); else FormatEx(sPath, sizeof sPath, "%s", sample);
	FormatEx(sPathFull, sizeof sPathFull, "sound/%s", sPath);
	Handle hFile = OpenSoundFile(sPathFull, true);
	if(hFile == INVALID_HANDLE) return Plugin_Continue;
	fSoundLen = float(GetSoundLength(hFile));
	delete hFile;

	#if defined Debug
		char sTargetname[64];
		GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				PrintToConsole(i, "[Ambient: %f] Length: %.1f, sample: %s, name: %s, entity: %i, volume: %.8f, level: %i, pitch: %i, pos: {%.1f, %.1f, %.1f}, flags: %i, delay: %.1f", GetEngineTime(), fSoundLen, sample, sTargetname, entity, volume, level, pitch, pos[0], pos[1], pos[2], flags, delay);
	#endif

	if(fSoundLen < f_stopmusic_music_length)
		return Plugin_Continue;

	char recentsample[PLATFORM_MAX_PATH];
	char sRef[32];
	IntToString(EntIndexToEntRef(entity), sRef, sizeof(sRef));
	if(smEntitySample.GetString(sRef, recentsample, sizeof(recentsample))) {
		if(!StrEqual(recentsample, sample, false)) {
			StopSoundEx(ALL_CLIENTS, recentsample);
			smSampleVolume.Remove(recentsample);
		}
	}
	smEntitySample.SetString(sRef, sample, true);

	float fDelay = 0.0;
	float fCurrentTime = GetTickedTime();
	if(FloatCompare(fNextAllowedTime, fCurrentTime) > 0) {
		fDelay = FloatSub(fNextAllowedTime, fCurrentTime);
	}

	if(flags == SND_NOFLAGS || flags == SND_CHANGEVOL || flags == SND_CHANGEPITCH) {
		if(FloatCompare(volume, 0.019) > 0) {
			if(fDelay) {
				DataPack pack = new DataPack();
				CreateDataTimer(fDelay, Timer_LatePlaySound, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteString(sample);
				pack.WriteFloat(volume);
				pack.WriteCell(pitch);
				pack.WriteCell(flags);
				pack.WriteFloat(fSoundLen);
				pack.WriteCell(entity);
				pack.WriteCell(false);
			} else {
				PlayAdjustedSound(sample, volume, pitch, flags, fSoundLen, entity);
			}
		} else {
			StopSoundEx(ALL_CLIENTS, sample);
			smSampleVolume.Remove(sample);
		}
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_LatePlaySound(Handle timer, DataPack pack) {
	pack.Reset();
	char sample[PLATFORM_MAX_PATH];
	pack.ReadString(sample, sizeof(sample));
	float volume = pack.ReadFloat();
	int pitch = pack.ReadCell();
	int flags = pack.ReadCell();
	float fSoundLen = pack.ReadFloat();
	int entity = pack.ReadCell();
	bool retry = pack.ReadCell();

	PlayAdjustedSound(sample, volume, pitch, flags, fSoundLen, entity, retry);
	KillTimer(timer);
	return Plugin_Stop;
}

void PlayAdjustedSound(char[] sample, float &volume, int &pitch, int flags, float fSoundLen, int &entity, bool retry = false) {
	float currentvolume = 0.0;
	bool playing = smSampleVolume.GetValue(sample, currentvolume);

	if(playing && flags == SND_NOFLAGS) return;
	if(retry && (!playing || FloatCompare(currentvolume, 0.019) <= 0)) return;

	if(!playing) {
		int iTimerStatus[2];
		if(!smSampleTimerArray.GetArray(sample, iTimerStatus, sizeof(iTimerStatus))) {
			for(int i = 0; i < sizeof(iTimerStatus); i++)
				iTimerStatus[i] = 0;
		}
		iTimerStatus[1]++;
		smSampleTimerArray.SetArray(sample, iTimerStatus, sizeof(iTimerStatus), true);

		DataPack pack = new DataPack();
		CreateDataTimer(fSoundLen, Timer_OnAmbientSoundEnd, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteString(sample);
		pack.WriteCell(iRoundNum);
		pack.WriteCell(iTimerStatus[1]);
	}

	smSampleVolume.SetValue(sample, volume, true);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			if(disabled[i]) continue;

			float play_volume = FloatDiv(FloatMul(volume, float(clientvolume[i])), 100.0);
			if(FloatCompare(play_volume,0.5)>0)
			{
				play_volume=0.25+(play_volume-0.5)*1.5;
			}else
			{
				play_volume*=0.5;
			}
			if(FloatCompare(volume, 0.019) > 0 && FloatCompare(play_volume, 0.02) <= 0) {
				#if defined Debug
					if(IsClientInGame(i))
						PrintToConsole(i, "[Override To Playable Volume] old play_volume: %.4f -> 0.029", play_volume);
				#endif
				play_volume = 0.03;
			}
			int iFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			if(iFlags & 1)
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC,
							 SNDLEVEL_NONE, flags, play_volume, pitch, -1,
							 NULL_VECTOR, NULL_VECTOR, true);
			else
			EmitSoundToClient(i, sample, entity, SNDCHAN_STATIC,
							 SNDLEVEL_NORMAL, flags, play_volume, pitch, -1,
							 NULL_VECTOR, NULL_VECTOR, true);

			#if defined Debug
				if(IsClientInGame(i))
					PrintToConsole(i, "[EmitSound] sample: %s, play_volume: %.4f, pitch: %i, flags: %i", sample, play_volume, pitch, flags);
			#endif
		}
	}

	if(!retry) {
		DataPack pack = new DataPack();
		CreateDataTimer(0.2, Timer_LatePlaySound, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteString(sample);
		pack.WriteFloat(volume);
		pack.WriteCell(pitch);
		pack.WriteCell(SND_CHANGEVOL);
		pack.WriteFloat(fSoundLen);
		pack.WriteCell(entity);
		pack.WriteCell(true);
	}
}

public Action Timer_OnAmbientSoundEnd(Handle timer, DataPack pack) {
	pack.Reset();
	char sample[PLATFORM_MAX_PATH];
	pack.ReadString(sample, sizeof(sample));
	int iTimerRoundNum = pack.ReadCell();
	int iCurrentTimer = pack.ReadCell();
	
	if(iTimerRoundNum != iRoundNum) {
		KillTimer(timer);
		return Plugin_Stop;
	}

	int iTimerStatus[2];
	if(!smSampleTimerArray.GetArray(sample, iTimerStatus, sizeof(iTimerStatus))) {
		KillTimer(timer);
		return Plugin_Stop;
	}
	if(iTimerStatus[1] != iCurrentTimer) {
		KillTimer(timer);
		return Plugin_Stop;
	}

	smSampleVolume.Remove(sample);
	KillTimer(timer);
	return Plugin_Stop;
}

public Action Command_StopMusic(int client, int args) {
	// Prevent this command from being spammed.
	if (!client || g_fCmdTime[client] > GetGameTime())
		return Plugin_Handled;
	g_fCmdTime[client] = GetGameTime() + 2.0;

	if(disabled[client]){
		Client_UpdateMusics(client);
		disabled[client] = false;
		CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicEnable");
		return Plugin_Handled;
	}

	CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicDisable");
	SetClientCookie(client, cDisableSounds, (!disabled[client]) ? "1" : "0");
	Client_StopSound(client);
	disabled[client] = true;
	return Plugin_Handled;
}

public Action Command_StartMusic(int client, int args) {
	// Prevent this command from being spammed.
	if (!client || g_fCmdTime[client] > GetGameTime())
		return Plugin_Handled;
	g_fCmdTime[client] = GetGameTime() + 2.0;

	if(disabled[client])
		Client_UpdateMusics(client);
	disabled[client] = false;
	CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicEnable");
	return Plugin_Handled;
}

public Action Command_Music(int client, int args) {
	// Prevent this command from being spammed.
	if (!client || g_fCmdTime[client] > GetGameTime())
		return Plugin_Handled;
	g_fCmdTime[client] = GetGameTime() + 2.0;

	if(args >= 1) {
		char arg1[6];
		GetCmdArg(1, arg1, sizeof(arg1));
		int ivolume = StringToInt(arg1);
		if(StrEqual(arg1, "disallow", false) || StrEqual(arg1, "off", false) || ivolume <= 0) { //Disallow map music
			disabled[client] = true;
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicDisable");
			SetClientCookie(client, cDisableSounds, "1");
			Client_StopSound(client);
			return Plugin_Handled;
		} else if(StrEqual(arg1, "allow", false) || StrEqual(arg1, "on", false)) { //Allow map music
			if(disabled[client])
				Client_UpdateMusics(client);
			disabled[client] = false;
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicEnable");
			SetClientCookie(client, cDisableSounds, "0");
			return Plugin_Handled;
		} else {
			if(ivolume > 100) ivolume = 100;
			disabled[client] = false;
			SetClientCookie(client, cDisableSounds, "0");
			clientvolume[client] = ivolume;
			CPrintToChat(client, "\x04[MapMusic] \x01%t", "Text_MapMusicVolume", clientvolume[client]);
			char svolume[8];
			IntToString(clientvolume[client], svolume, sizeof(svolume));
			SetClientCookie(client, cDisableSoundVolume, svolume);
		}
		Client_UpdateMusics(client);
		return Plugin_Handled;
	}

	DisplaySettingsMenu(client);
	return Plugin_Handled;
}

stock void Client_StopSound(int client) {
	ClientCommand(client, "playgamesound Music.StopAllExceptMusic");
	ClientCommand(client, "playgamesound Music.StopAllMusic");
}

stock void Client_UpdateMusics(int client) {
	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "ambient_generic")) != INVALID_ENT_REFERENCE) {
		if(!IsValidEntity(entity))
			continue;
		
		char sample[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_iszSound", sample, sizeof(sample));

		float currentvolume = 0.0;
		smSampleVolume.GetValue(sample, currentvolume);

		if(FloatCompare(currentvolume, 0.019) <= 0)
			continue;

		float fSoundLen = 0.0;
		char sPath[PLATFORM_MAX_PATH],sPathFull[PLATFORM_MAX_PATH];
		if(sample[0]=='#') strcopy(sPath, sizeof(sPath), sample[1]); else FormatEx(sPath, sizeof sPath, "%s", sample);
		FormatEx(sPathFull, sizeof sPathFull, "sound/%s", sPath);
		Handle hFile = OpenSoundFile(sPathFull, true);
		if(hFile == INVALID_HANDLE) continue;
		fSoundLen = float(GetSoundLength(hFile));
		delete hFile;

		if(fSoundLen < f_stopmusic_music_length)
			continue;

		//float play_volume = FloatDiv(float(clientvolume[client]), 100.0);
		float play_volume = FloatDiv(FloatMul(currentvolume, float(clientvolume[client])), 100.0);
		if(FloatCompare(play_volume,0.5)>0)
		{
			play_volume=0.25+(play_volume-0.5)*1.5;
		}else
		{
			play_volume*=0.5;
		}
		if(FloatCompare(currentvolume, 0.019) > 0 && FloatCompare(play_volume, 0.02) <= 0) {
			#if defined Debug
				if(IsClientInGame(client))
					PrintToConsole(client, "[Override To Playable Volume] old play_volume: %.4f -> 0.029", play_volume);
			#endif
			play_volume = 0.03;
		}
		int iFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
		if(iFlags & 1)
		EmitSoundToClient(client, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC,
						 SNDLEVEL_NONE, SND_CHANGEVOL, play_volume, SNDPITCH_NORMAL, -1,
						 NULL_VECTOR, NULL_VECTOR, true);
		else
		EmitSoundToClient(client, sample, entity, SNDCHAN_STATIC,
						 SNDLEVEL_NORMAL, SND_CHANGEVOL, play_volume, SNDPITCH_NORMAL, -1,
						 NULL_VECTOR, NULL_VECTOR, true);
	}
}

stock void StopSoundEx(int client, const char[] sample) {
	#if defined Debug
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				PrintToConsole(i, "[StopSound] sample: %s", sample);
	#endif

	if(client == ALL_CLIENTS) {
		//EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
		for(new i = 1; i<= MaxClients; i++)
		{
			if(IsClientInGame(i))
				StopSound(i, SNDCHAN_STATIC, sample);
		}
		return;
	}

	//EmitSoundToClient(client, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0, SNDPITCH_NORMAL, _, _, _, true);
	if(IsClientInGame(client))
		StopSound(client, SNDCHAN_STATIC, sample);
}
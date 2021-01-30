//-------------------------------------------------------
// Purpose: Global Function Variables
//-------------------------------------------------------
float g_fGameTime;
int g_iOutValueOffset = -1;

enum struct class_ItemConfig
{
	char		Name[32];
	char		ShortName[32];
	char		Color[16];
	char		ButtonClass[32];
	char		FilterName[32];
	bool		BlockPickup;
	bool		AllowTransfer;
	bool		ForceDrop;
	bool		Chat;
	bool		Chat_Uses;
	bool		Hud;
	int			HammerID;
	int 		EnergyID;
	int			Mode;
	int			MaxUses;
	int			CoolDown;
	int			ButtonID;
	int			GlowColor[4];
	int			Trigger;
	char		Spawner[64];
	bool		PhysBox;
}

enum struct class_ItemList
{
	char		Name[32];
	char		ShortName[32];
	char		Color[16];
	char		ButtonClass[32];
	char		FilterName[32];
	bool		BlockPickup;
	bool		AllowTransfer;
	bool		ForceDrop;
	bool		Chat;
	bool		Chat_Uses;
	bool		Hud;
	int			HammerID;
	int 		EnergyID;
	int 		MathID;
	int 		MathValue;
	int 		MathValueMax;
	int			Mode;
	int			Uses;
	int			MaxUses;
	int			CoolDown;
	int			ButtonID;
	int			WeaponID;
	ArrayList	ButtonsArray;
	int			OwnerID;
	float		CoolDownTime;
	float		Delay;
	int			GlowEnt;
	int			GlowColor[4];
	bool		PhysBox;
	
	//Purpose: Update cached GameTime
	void UpdateTime()
	{
		g_fGameTime = GetGameTime();
	}
	//Purpose: Base cooldowns on GameTime rather than Timer
	void SetCoolDown(int time)
	{
		this.CoolDownTime = g_fGameTime + time;
	}
	float CheckCoolDown()
	{
		return this.CoolDownTime - g_fGameTime;
	}
	int RoundCoolDown()
	{
		return RoundToCeil(this.CoolDownTime - g_fGameTime);
	}
	void SetDelay(int time)
	{
		if(time<1) time = 1;
		this.Delay = g_fGameTime + time;
	}
	float CheckDelay()
	{
		return this.Delay - g_fGameTime;
	}
	int RoundDelay()
	{
		return RoundToCeil(this.Delay - g_fGameTime);
	}
}

enum struct class_Scheme
{
	char		Color_Tag[16];
	char		Color_Name[16];
	char		Color_SteamID[16];
	char		Color_Use[16];
	char		Color_Pickup[16];
	char		Color_Drop[16];
	char		Color_Disconnect[16];
	char		Color_Death[16];
	char		Color_Warning[16];
	char		Color_Enabled[16];
	char		Color_Disabled[16];
	char		Server_Name[64];
	int			Color_HUD[4];
	float		Pos_HUD_X;
	float		Pos_HUD_Y;
}

enum struct class_ClientSettings_Hud
{
	bool		Display;
	int			Color[4];
	float		Pos_X;
	float		Pos_Y;
	bool		Name;
}

enum struct class_ClientSettings_EBan
{
	bool		Banned;
	char		Admin_Name[32];
	char		Admin_SteamID[64];
	int			Duration;
	int			TimeStamp_Issued;
	char		Reason[64];
}

enum struct class_Physbox
{
	int		Entity;
	int		Team;
	int		WeaponID;
}

enum struct class_Offline_Eban
{
	int		UserID;
	char	PlayerName[32];
	char	Player_SteamID[64];
	int		TimeStamp;
	int		TimeStamp_Start;
	char	LastItem[32];
}

stock bool IsValidClient(int iClient) 
{ 
	if (iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient)) return true; 
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

stock int GetCounterValue(int counter) {
    char szType[64];
    GetEntityClassname(counter, szType, sizeof(szType));

    if(!StrEqual(szType, "math_counter", false)) {
        return -1;
    }

    if(g_iOutValueOffset == -1)
        g_iOutValueOffset = FindDataMapInfo(counter, "m_OutValue");
    
    return RoundFloat(GetEntDataFloat(counter, g_iOutValueOffset));
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
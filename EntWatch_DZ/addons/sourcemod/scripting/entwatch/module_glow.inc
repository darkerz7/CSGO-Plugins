#define EW_MODULE_GLOW

//-------------------------------------------------------
// Purpose: Plugin settings
//-------------------------------------------------------
ConVar	g_hCvar_Glow,
		g_hCvar_Glow_Spawn,
		g_hCvar_Glow_Spawn_Type,
		g_hCvar_Glow_Drop_Type;

//-------------------------------------------------------
// Purpose: Plugin Local settings
//-------------------------------------------------------
bool	g_bGlow = true,
		g_bGlow_Spawn = true;

int		g_iGlow_Spawn_Type = 0,
		g_iGlow_Drop_Type = 0;

stock void EWM_Glow_OnPluginStart()
{
	g_hCvar_Glow              = CreateConVar("entwatch_glow", "1", "Enable/Disable the glow Global.", _, true, 0.0, true, 1.0);
	g_hCvar_Glow_Spawn        = CreateConVar("entwatch_glow_spawn", "1", "Enable/Disable the glow after Spawn Items.", _, true, 0.0, true, 1.0);
	g_hCvar_Glow_Spawn_Type   = CreateConVar("entwatch_glow_spawn_type", "0", "Glow Type after Spawn Items.", _, true, 0.0, true, 3.0);
	g_hCvar_Glow_Drop_Type    = CreateConVar("entwatch_glow_drop_type", "0", "Glow Type after Drop Items.", _, true, 0.0, true, 3.0);

	HookConVarChange(g_hCvar_Glow, Cvar_GLOW_Changed);
	HookConVarChange(g_hCvar_Glow_Spawn, Cvar_GLOW_Changed);
	HookConVarChange(g_hCvar_Glow_Spawn_Type, Cvar_GLOW_Changed);
	HookConVarChange(g_hCvar_Glow_Drop_Type, Cvar_GLOW_Changed);
}

public void Cvar_GLOW_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==g_hCvar_Glow)
		g_bGlow = GetConVarBool(convar);
	else if(convar==g_hCvar_Glow_Spawn)
		g_bGlow_Spawn = GetConVarBool(convar);
	else if(convar==g_hCvar_Glow_Spawn_Type)
		g_iGlow_Spawn_Type = GetConVarInt(convar);
	else if(convar==g_hCvar_Glow_Drop_Type)
		g_iGlow_Drop_Type = GetConVarInt(convar);
	
	if(!g_bGlow && g_bConfigLoaded)
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			if(ItemTest.GlowEnt != INVALID_ENT_REFERENCE && IsValidEdict(ItemTest.GlowEnt))
			{
				AcceptEntityInput(ItemTest.GlowEnt, "Kill");
				ItemTest.GlowEnt = INVALID_ENT_REFERENCE;
				g_ItemList.SetArray(i, ItemTest, sizeof(ItemTest));
			}
		}
}

//----------------------------------------------------------------------------------------------------
// Purpose: init Glow weapon on Drop weapons
//----------------------------------------------------------------------------------------------------
stock void EWM_Glow_GlowWeapon(class_ItemList ItemTest, int index, bool bSpawn)
{
	if(g_bGlow)
	{
		if(ItemTest.GlowEnt == INVALID_ENT_REFERENCE || !IsValidEdict(ItemTest.GlowEnt))
		{
			char sModelPath[PLATFORM_MAX_PATH];
			// Get the original model path
			GetEntPropString(ItemTest.WeaponID, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
			ReplaceString(sModelPath, sizeof(sModelPath), "_dropped", "", false);
			
			// Find the location of the weapon
			float fWOrigin[3], fWAngle[3];
			float fForward[3], fRight[3], fUp[3];
			float fOffset[3] = {0.0, -5.0, 0.0};
			
			GetEntPropVector(ItemTest.WeaponID, Prop_Send, "m_vecOrigin", fWOrigin);
			GetEntPropVector(ItemTest.WeaponID, Prop_Send, "m_angRotation", fWAngle);
			GetAngleVectors(fWAngle, fForward, fRight, fUp);
			
			fWOrigin[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
			fWOrigin[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
			fWOrigin[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
			
			// Create & set dynamic glow entity and give properties
			ItemTest.GlowEnt = CreateEntityByName("prop_dynamic");
			
			DispatchKeyValue(ItemTest.GlowEnt, "model", sModelPath);
			DispatchKeyValue(ItemTest.GlowEnt, "disablereceiveshadows", "1");
			DispatchKeyValue(ItemTest.GlowEnt, "disableshadows", "1");
			DispatchKeyValue(ItemTest.GlowEnt, "solid", "0");
			DispatchKeyValue(ItemTest.GlowEnt, "spawnflags", "256");
			SetEntProp(ItemTest.GlowEnt, Prop_Send, "m_CollisionGroup", 11);
			
			// Spawn and teleport the entity
			DispatchSpawn(ItemTest.GlowEnt);
			TeleportEntity(ItemTest.GlowEnt, fWOrigin, fWAngle, NULL_VECTOR);
			
			// Give glowing effect to the entity
			SetEntProp(ItemTest.GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
			SetEntPropFloat(ItemTest.GlowEnt, Prop_Send, "m_flGlowMaxDist", 10000000.0);
			if(bSpawn)
				SetEntProp(ItemTest.GlowEnt, Prop_Send, "m_nGlowStyle", g_iGlow_Spawn_Type);
			else SetEntProp(ItemTest.GlowEnt, Prop_Send, "m_nGlowStyle", g_iGlow_Drop_Type);
			
			SetVariantColor(ItemTest.GlowColor);
			AcceptEntityInput(ItemTest.GlowEnt, "SetGlowColor");
			
			// Set the activator and group the entity
			SetVariantString("!activator");
			AcceptEntityInput(ItemTest.GlowEnt, "SetParent", ItemTest.WeaponID);

			AcceptEntityInput(ItemTest.GlowEnt, "TurnOn");
			AcceptEntityInput(ItemTest.GlowEnt, "SetGlowEnabled");
			// Save ItemTest
			g_ItemList.SetArray(index, ItemTest, sizeof(ItemTest));
		} else 
		{
			if(g_bGlow_Spawn) SetEntProp(ItemTest.GlowEnt, Prop_Send, "m_nGlowStyle", g_iGlow_Drop_Type);
			AcceptEntityInput(ItemTest.GlowEnt, "TurnOn");
			AcceptEntityInput(ItemTest.GlowEnt, "SetGlowEnabled");
		}
	}
}
//----------------------------------------------------------------------------------------------------
// Purpose: Disable glow
//----------------------------------------------------------------------------------------------------
stock void EWM_Glow_DisableGlow(class_ItemList ItemTest)
{
	if(g_bGlow)
	{
		if (ItemTest.GlowEnt != INVALID_ENT_REFERENCE && IsValidEdict(ItemTest.GlowEnt))
		{
			AcceptEntityInput(ItemTest.GlowEnt, "SetGlowDisabled");
			AcceptEntityInput(ItemTest.GlowEnt, "TurnOff");
		}
	}
}
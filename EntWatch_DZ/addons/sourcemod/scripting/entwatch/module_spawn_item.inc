#define EW_MODULE_SPAWN

stock void EWM_Spawn_OnPluginStart()
{
	RegAdminCmd("sm_espawnitem", EWM_Spawn_Command_Spawn, ADMFLAG_BAN);
}

public void EWM_Spawn_Spawn(int iAdmin, int iUserID, int iIndexConfig, bool bStrip)
{
	bool bAdminFound = false;
	if(IsValidClient(iAdmin) && IsClientConnected(iAdmin)) bAdminFound = true;
	int iTarget = GetClientOfUserId(iUserID);
	if(IsValidClient(iTarget) && IsClientConnected(iTarget))
	{
		if(GetClientTeam(iTarget) == 2 || GetClientTeam(iTarget) == 3)
		{
			class_ItemConfig ItemTest;
			g_ItemConfig.GetArray(iIndexConfig, ItemTest, sizeof(ItemTest));
			
			if(!StrEqual(ItemTest.Spawner, ""))
			{
				int iEntity = -1;
				bool bPTFound = false;
				char sPTName[64];
				while ((iEntity = FindEntityByClassname(iEntity, "point_template")) != -1)
				{
					GetEntPropString(iEntity, Prop_Data, "m_iName", sPTName, sizeof(sPTName));
					if(strcmp(sPTName, ItemTest.Spawner) == 0)
					{
						bPTFound = true;
						break;
					}
				}
				if(bPTFound)
				{
					if(bStrip)
						for(int j = 0; j < 5; j++)
						{
							int iWeaponSlot = -1;
							while ((iWeaponSlot = GetPlayerWeaponSlot(iTarget, j)) != -1)
							{
								if(IsValidEntity(iWeaponSlot) && IsValidEdict(iWeaponSlot))
								{
									RemovePlayerItem(iTarget, iWeaponSlot);
									AcceptEntityInput(iWeaponSlot, "Kill");
								}
							}
						}
					
					float fWOrigin[3];
					
					GetClientAbsOrigin(iTarget, fWOrigin);
					
					fWOrigin[2] += 20.0;
					
					int iMaker = CreateEntityByName("env_entity_maker");
					
					DispatchKeyValue(iMaker, "EntityTemplate", ItemTest.Spawner);
					DispatchKeyValue(iMaker, "spawnflags", "0");
					
					DispatchSpawn(iMaker);
					TeleportEntity(iMaker, fWOrigin, NULL_VECTOR, NULL_VECTOR);
					
					AcceptEntityInput(iMaker, "ForceSpawn");
					AcceptEntityInput(iMaker, "Kill");
					
					LogAction(iAdmin, iTarget, "\"%L\" spawn item %s on player \"%L\"", iAdmin, ItemTest.Name, iTarget);
					CPrintToChatAll("%s%t %s%t %s%N %s%t %s%s %s%t %s%N", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Admin", g_SchemeConfig.Color_Name, iAdmin, g_SchemeConfig.Color_Warning, "Spawn Item", ItemTest.Color, ItemTest.Name, g_SchemeConfig.Color_Warning, "On Player", g_SchemeConfig.Color_Name, iTarget);
				}
				else if(bAdminFound) CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "PT configuration Error");
			}
			else if(bAdminFound) CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "PT configuration not found");
		}
		else if(bAdminFound) CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "The player must be in one of the teams");
	}
	else if(bAdminFound) CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
}

public Action EWM_Spawn_Command_Spawn(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)) && g_bConfigLoaded)
	{
		if (GetCmdArgs() < 2)
		{
			CReplyToCommand(iClient, "%s%t %s%t: sm_espawnitem <receiver> <itemname> [<strip 0/1>]", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage");
			return Plugin_Handled;
		}

		int iValue = -1;
		char sStrip[20];
		
		bool bStrip = false;
		
		if(GetCmdArgs() >= 3)
		{
			GetCmdArg(3, sStrip, sizeof(sStrip));
			
			if(StringToIntEx(sStrip, iValue) == 0)
			{
				CReplyToCommand(iClient, "%s%t %s%t: sm_espawnitem <receiver> <itemname> [<strip 0/1>]", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage");
				return Plugin_Handled;
			}
			
			if(iValue == 1) bStrip = true;
		}
		
		int iTarget = -1;
		char sTarget[64], sItemName[32];
		
		GetCmdArg(1, sTarget, sizeof(sTarget));
		GetCmdArg(2, sItemName, sizeof(sItemName));
		
		if((iTarget = FindTarget(iClient, sTarget, true)) == -1) return Plugin_Handled;
		
		#if defined EW_MODULE_EBAN
		if(g_EbanClients[iTarget].Banned)
		{
			CPrintToChat(iClient, "%s%t %s%N %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iTarget, g_SchemeConfig.Color_Disabled, "Has a Restrict");
			return Plugin_Handled;
		}
		#endif
		
		int iUserID = GetClientUserId(iTarget);
		
		int iWeaponCount = 0,
		iItemIndex = -1;
		for(int i = 0; i<g_ItemConfig.Length; i++)
		{
			class_ItemConfig ItemTest;
			g_ItemConfig.GetArray(i, ItemTest, sizeof(ItemTest));
			if(StrContains(ItemTest.Name, sItemName, false) != -1 || StrContains(ItemTest.ShortName, sItemName, false) != -1)
			{
				iWeaponCount++;
				iItemIndex = i;
			}
		}
		if(iWeaponCount <= 0)
		{
			//Not Found
			CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Invalid item name");
		} else if(iWeaponCount == 1)
		{
			//Only 1 weapon
			EWM_Spawn_Spawn(iClient, iUserID, iItemIndex, bStrip);
		} else
		{
			//More 1 weapon
			Menu hEdictMenu = CreateMenu(EWM_Spawn_EdictMenu_Handler);
			char sMenuTemp[64], sIndexTemp[32];
			FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T %T:", "EW_Tag", iClient, "Item to Spawn", iClient);
			hEdictMenu.SetTitle(sMenuTemp);
			for(int i = 0; i<g_ItemConfig.Length; i++)
			{
				class_ItemConfig ItemTest;
				g_ItemConfig.GetArray(i, ItemTest, sizeof(ItemTest));
				if(StrContains(ItemTest.Name, sItemName, false) != -1 || StrContains(ItemTest.ShortName, sItemName, false) != -1)
				{
					int iStrip = 0;
					if(bStrip) iStrip = 1;
					FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%i", iUserID, i, iStrip);
					hEdictMenu.AddItem(sIndexTemp, ItemTest.Name, ITEMDRAW_DEFAULT);
				}
			}
			hEdictMenu.Display(iClient, MENU_TIME_FOREVER);
		}
	}
	return Plugin_Handled;
}

public int EWM_Spawn_EdictMenu_Handler(Menu hEdictMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_End:delete hEdictMenu;
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[3][64];
			GetMenuItem(hEdictMenu, iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 3, 64);
			int iUserID = StringToInt(Explode_sParam[0]);
			int iTarget = GetClientOfUserId(iUserID);
			int iItemIndex = StringToInt(Explode_sParam[1]);
			int iStrip = StringToInt(Explode_sParam[2]);
			bool bStrip = false;
			if(iStrip == 1) bStrip = true;
			if(!IsValidClient(iTarget))
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Receiver is not valid anymore");
				return 0;
			}
			EWM_Spawn_Spawn(iClient, iUserID, iItemIndex, bStrip);
		}
	}
	return 0;
}
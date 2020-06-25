#define EW_MODULE_PHYSBOX

#include <collisionhook>

enum struct class_Physbox
{
	int		Entity;
	int		Team;
	int		WeaponID;
}

ArrayList g_PhysboxArray;

stock void EWM_Physbox_OnPluginStart()
{
	g_PhysboxArray = new ArrayList(512);
}

stock void EWM_Physbox_Event_RoundEnd()
{
	g_PhysboxArray.Clear();
}

stock void EWM_Physbox_OnEntityDestroyed(int iEntity)
{
	for(int i = 0; i < g_PhysboxArray.Length; i++)
	{
		class_Physbox PhysBoxTest;
		g_PhysboxArray.GetArray(i, PhysBoxTest, sizeof(PhysBoxTest));
		if(PhysBoxTest.Entity == iEntity)
		{
			g_PhysboxArray.Erase(i);
			return;
		}
	}
}

stock void EWM_Physbox_Pickedup(int iClient, int iWeapon)
{
	for(int i = 0; i < g_PhysboxArray.Length; i++)
	{
		class_Physbox PhysBoxTest;
		g_PhysboxArray.GetArray(i, PhysBoxTest, sizeof(PhysBoxTest));
		if(PhysBoxTest.WeaponID == iWeapon)
		{
			PhysBoxTest.Team = GetClientTeam(iClient);
			g_PhysboxArray.SetArray(i, PhysBoxTest, sizeof(PhysBoxTest));
		}
	}
}

public bool RegisterPhysbox(class_ItemList ItemInstance, int iEntity)
{
	if(IsValidEntity(ItemInstance.WeaponID) && ItemInstance.PhysBox)
	{
		char Item_Weapon_Targetname[32], Item_Weapon_Parent[32];
		Entity_GetTargetName(ItemInstance.WeaponID, Item_Weapon_Targetname, sizeof(Item_Weapon_Targetname));
		Entity_GetParentName(iEntity, Item_Weapon_Parent, sizeof(Item_Weapon_Parent));
		if (!StrEqual(Item_Weapon_Targetname,"") && StrEqual(Item_Weapon_Targetname, Item_Weapon_Parent))
		{
			class_Physbox NewPhysbox;
			NewPhysbox.Entity = iEntity;
			NewPhysbox.Team = -1;
			NewPhysbox.WeaponID = ItemInstance.WeaponID;
			g_PhysboxArray.PushArray(NewPhysbox, sizeof(NewPhysbox));
			return true;
		}
	}
	return false;
}

public void OnPhysboxSpawned(int iEntity)
{
	if(!IsValidEntity(iEntity) || !g_bConfigLoaded) return;
	
	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		if(RegisterPhysbox(ItemTest,iEntity)) return;
	}
}

public Action CH_PassFilter(int iEntBP, int iAttacker, bool &bResult)
{
	char sClassName[64];
	GetEntityClassname(iAttacker,sClassName,sizeof(sClassName));
	bool bDetectNade = false;
	if(StrContains(sClassName, "_projectile") != -1) bDetectNade = true;
	if (bDetectNade || 1 <= iAttacker <= MaxClients && IsClientInGame(iAttacker) && IsPlayerAlive(iAttacker))
	{
		for(int i = 0; i < g_PhysboxArray.Length; i++)
		{
			class_Physbox PhysBoxTest;
			g_PhysboxArray.GetArray(i, PhysBoxTest, sizeof(PhysBoxTest));
			if(PhysBoxTest.Entity == iEntBP)
			{
				if(bDetectNade)
				{
					bResult = false;
					return Plugin_Handled;
				}else
				{
					if(PhysBoxTest.Team == GetClientTeam(iAttacker))
					{
						bResult = false;
						return Plugin_Handled;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}
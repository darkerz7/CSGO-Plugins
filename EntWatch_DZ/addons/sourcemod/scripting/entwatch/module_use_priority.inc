#define EW_MODULE_USE_PRIORITY

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float[3] aVel, float[3] aAngles, int &iWeapon)
{
	if(iButtons & IN_USE)
	{
		if (g_bConfigLoaded)
		{
			int iCountButtons = 0, iCurCountButton = 0, iMode = 0;
			int iButton = INVALID_ENT_REFERENCE;
			for(int i = 0; i<g_ItemList.Length; i++)
			{
				class_ItemList ItemTest;
				g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
				if(ItemTest.OwnerID == iClient)
				{
					iCurCountButton = ItemTest.ButtonsArray.Length;
					iCountButtons+=iCurCountButton;
					if(iCountButtons > 1) break;
					if(iCountButtons == 1 && iCurCountButton == 1)
					{
						int iBtnBuff = ItemTest.ButtonsArray.Get(0);
						if(IsValidEdict(iBtnBuff) && ItemTest.ButtonID == Entity_GetHammerID(iBtnBuff)) 
						{
							iButton = iBtnBuff;
							iMode = ItemTest.Mode;
						}
					}
				}
			}
			if(iCountButtons == 1 && iMode!=1 && iMode!=6 && iMode!=7 && IsValidEdict(iButton)) AcceptEntityInput(iButton, "Use", iClient, iClient); 
		}
	}
	return Plugin_Continue;
}
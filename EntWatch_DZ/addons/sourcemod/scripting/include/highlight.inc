#if defined _outlinehighlight_included
 #endinput
#endif
#define _outlinehighlight_included

stock void Highlight_Color(int iEntity, int iRed, int iGreen, int iBlue)
{
	SetEntProp(iEntity, Prop_Send, "m_nHighlightColorR", iRed);
	SetEntProp(iEntity, Prop_Send, "m_nHighlightColorG", iGreen);
	SetEntProp(iEntity, Prop_Send, "m_nHighlightColorB", iBlue);
}

stock void Highlight_Set(int iEntity, const int[] iClients, int iNum)
{
	Protobuf pb = view_as<Protobuf>(StartMessage("EntityOutlineHighlight", iClients, iNum, USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", false);
		EndMessage();
	}
}

stock void Highlight_Remove(int iEntity, const int[] iClients, int iNum)
{
	Protobuf pb = view_as<Protobuf>(StartMessage("EntityOutlineHighlight", iClients, iNum, USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", true);
		EndMessage();
	}
}

stock void Highlight_SetOne(int iEntity, int iClient)
{
	Protobuf pb = view_as<Protobuf>(StartMessageOne("EntityOutlineHighlight", iClient, USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", false);
		EndMessage();
	}
}

stock void Highlight_RemoveOne(int iEntity, int iClient)
{
	Protobuf pb = view_as<Protobuf>(StartMessageOne("EntityOutlineHighlight", iClient, USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", true);
		EndMessage();
	}
}

stock void Highlight_SetAll(int iEntity)
{
	Protobuf pb = view_as<Protobuf>(StartMessageAll("EntityOutlineHighlight", USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", false);
		EndMessage();
	}
}

stock void Highlight_RemoveAll(int iEntity)
{
	Protobuf pb = view_as<Protobuf>(StartMessageAll("EntityOutlineHighlight", USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("entidx", iEntity);
		pb.SetBool("removehighlight", true);
		EndMessage();
	}
}
//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock char[] Entity_GetTargetName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock char[] Entity_GetParentName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iParent", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock int Entity_GetHammerID(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock bool Entity_GetClassName(int entity, char[] buffer, int size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);

	if (buffer[0] == '\0') {
		return false;
	}

	return true;
}
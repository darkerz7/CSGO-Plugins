#if defined _entWatch_include
  #endinput
#endif
#define _entWatch_include

/**
 * Checks if a client is currently banned, if an integer variable is referenced the time of unban will be assigned to it.
 *
 * @param client		Client index to check for ban
 * @param iTimeStamp	Pass an integer variable by reference and it will contain the UNIX timestamp when the player will be unbanned
 * @return				True if user is banned, false otherwise
 *
 * On error/errors:		Invalid client index/client is not in game or client cookies are not yet loaded
 */
native bool:entWatch_IsClientBanned(client, &iTimeStamp);

/**
 * Bans a client from using special items.
 *
 * @param client		Client index to ban
 * @param IsTemporary	If the ban should be temporary pass true here
 * @param iLength		Length of ban in minutes, pass 0 here for a permanent ban
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index/client is not in game or client cookies are not yet loaded
 */
native bool:entWatch_BanClient(client, bool:bIsTemporary=false, iLength=0);

/**
 * Unbans a previously ebanned Client.
 *
 * @param client		Client index to unban
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index/client is not in game or client cookies are not yet loaded
 */
native bool:entWatch_UnbanClient(client);

/**
 * Checks if an entity is a special item.
 *
 * @param entity		Entity index to check
 * @return				True if entity is a special item, false otherwsie
 */
native bool:entWatch_IsSpecialItem(entity);

/**
 * Checks if a client has a special item.
 *
 * @param client		Client index to check
 * @return				True if client has a special item, false otherwsie
 */
native bool:entWatch_HasSpecialItem(client);

/**
 * Called when a client is e-banned by any means
 *
 * @param admin			Admin index that issued the ban
 * @param iLength		Length of the ban in UNIX time
 * @param client		Client index that was banned
 *
 * @return				None
 */
forward entWatch_OnClientBanned(admin, iLenght, client);

/**
 * Called when a client is e-unbanned by any means
 *
 * @param admin			Admin index that removed the ban
 * @param client		Client index that was unbanned
 * @return				None
 */
forward entWatch_OnClientUnbanned(admin, client);

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetParentName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iParent", buffer, size);
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetHammerID(entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetClassName(entity, String:buffer[], size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);

	if (buffer[0] == '\0') {
		return false;
	}

	return true;
}

//----------------------------------------------------------------------------------------------------
// Purpose: SMLib
//----------------------------------------------------------------------------------------------------
stock Entity_GetEntityFromHammerID(hammerID)
{
	for (new i = 0; i < 4096; i++)
	{
		if (IsValidEntity(i) && Entity_GetHammerID(i) == hammerID)
		{
			if (IsValidEntity(i))
				return i;
		}
	}

	return -1;
}

public SharedPlugin:__pl_entWatch =
{
	name = "entWatch",
	file = "entWatch.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_entWatch_SetNTVOptional()
{
	MarkNativeAsOptional("entWatch_IsClientBanned");
	MarkNativeAsOptional("entWatch_BanClient");
	MarkNativeAsOptional("entWatch_UnbanClient");
	MarkNativeAsOptional("entWatch_IsSpecialItem");
	MarkNativeAsOptional("entWatch_HasSpecialItem");
}
#endif

#if defined _EntWatch_include
  #endinput
#endif
#define _EntWatch_include

/**
 * Checks if a client is currently banned, if an integer variable is referenced the time of unban will be assigned to it.
 *
 * @param iClient		Client index to check for ban
 * @param iTimeStamp	Pass an integer variable by reference and it will contain the UNIX timestamp when the player will be unbanned/ when a player was banned if ban = Permamently/Temporary
 * @param iDuration		Duration of the ban -1 - Temporary, 0 - Permamently, Positive value - time in minutes
 * @param sReason		The reason why the player was banned
 * @return				True if user is banned, false otherwise
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_IsClientBanned(int iClient, int &iTimeStamp, int &iDuration, char[] sReason);

/**
 * Bans a client from using special items.
 *
 * @param iClient		Client index to ban
 * @param iAdmin		Admin index which ban (if IsValidClient - Client, else Console)
 * @param iDuration		Duration of the ban -1 - Temporary, 0 - Permamently, Positive value - time in minutes
 * @param sReason		The reason why the player will be banned
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_BanClient(int iClient, int iAdmin = 0, int iDuration = 0, const char[] sReason = "No Reason");

/**
 * Unbans a previously ebanned Client.
 *
 * @param iClient		Client index to unban
 * @param iAdmin		Admin index which ban (if IsValidClient - Client, else Console)
 * @param sReason		The reason why the player will be unbanned
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_UnbanClient(int iClient, int iAdmin = 0, const char[] sReason = "No Reason");

/**
 * Checks if an entity is a special item.
 *
 * @param iEntity		Entity index to check
 * @return				True if entity is a special item, false otherwsie
 */
native bool EntWatch_IsSpecialItem(int iEntity);

/**
 * Checks if a client has a special item.
 *
 * @param iClient		Client index to check
 * @return				True if client has a special item, false otherwsie
 */
native bool EntWatch_HasSpecialItem(int iClient);

/**
 * Called when a client is e-banned by any means
 *
 * @param iAdmin		Admin index that issued the ban
 * @param iDuration		Duration of the ban
 * @param iClient		Client index that was banned
 * @param sReason		The reason why the player was banned
 *
 * @return				None
 */
forward void EntWatch_OnClientBanned(int iAdmin, int iDuration, int iClient, const char[] sReason);

/**
 * Called when a client is e-unbanned by any means
 *
 * @param iAdmin		Admin index that removed the ban
 * @param iClient		Client index that was unbanned
 * @param sReason		The reason why the player was unbanned
 * @return				None
 */
forward void EntWatch_OnClientUnbanned(int iAdmin, int iClient, const char[] sReason);

public SharedPlugin __pl_EntWatch =
{
	name = "EntWatch",
	file = "entwatch_csgo_dz.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_entWatch_SetNTVOptional()
{
	MarkNativeAsOptional("EntWatch_IsClientBanned");
	MarkNativeAsOptional("EntWatch_BanClient");
	MarkNativeAsOptional("EntWatch_UnbanClient");
	MarkNativeAsOptional("EntWatch_IsSpecialItem");
	MarkNativeAsOptional("EntWatch_HasSpecialItem");
}
#endif

#if defined _EntWatch_include
  #endinput
#endif
#define _EntWatch_include

enum struct class_NativeClientSettings_Hud
{
	bool		Display;
	int			Color[4];
	float		Pos_X;
	float		Pos_Y;
	bool		Name;
}

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
 * Gets client HUD settings
 *
 * @param iClient		Client index to get
 * @param cSettings		An instance of the class in which the information will be saved

 * @return				True and client settings on success, false and default settings otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_GetHudSettings(int iClient, any cSettings[sizeof(class_NativeClientSettings_Hud)]);

/**
 * Gets default HUD settings
 *
 * @param cDefailt		An instance of the class in which the information will be saved

 * @return				True
 */
native bool EntWatch_GetHudDefault(any cDefailt[sizeof(class_NativeClientSettings_Hud)]);

/**
 * Sets client HUD Display
 *
 * @param iClient		Client index to set
 * @param iDisplay		Parameter to Display. 0 - Disable, otherwsie - Enable

 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index/Client cookies are not yet loaded
 */
native bool EntWatch_SetHudDisplay(int iClient, int iDisplay);

/**
 * Sets client HUD Name Display
 *
 * @param iClient		Client index to set
 * @param iName			Parameter to Name Display. 0 - Disable, otherwsie - Enable

 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index/Client cookies are not yet loaded
 */
native bool EntWatch_SetHudName(int iClient, int iName);

/**
 * Sets client HUD Position
 *
 * @param iClient		Client index to set
 * @param fPosX			Parameter to position X
 * @param fPosY			Parameter to position Y

 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid Position [0.0-1.0|0.0-1.0]/Invalid client index/Client cookies are not yet loaded
 */
native bool EntWatch_SetHudPosition(int iClient, float fPosX, float fPosY);

/**
 * Sets client HUD Colors
 *
 * @param iClient		Client index to set
 * @param aColors		Parameter to colors[4] - Red, Green, Blue, Alpha

 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid Colors [0-255|0-255|0-255|0-255]/Invalid Colors Array[4]/Invalid client index/Client cookies are not yet loaded
 */
native bool EntWatch_SetHudColors(int iClient, int[] aColors);

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
 * Sets the HighLighting Weapons privilege for an array of clients.
 *
 * @param iCount		Count of clients in the array
 * @param iClients		Array of clients for which to set the HighLighting Weapons privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_SetHLWeapon(int iCount, int[] iClients);

/**
 * Sets the HighLighting Players privilege for an array of clients.
 *
 * @param iCount		Count of clients in the array
 * @param iClients		Array of clients for which to set the HighLighting Players privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_SetHLPlayer(int iCount, int[] iClients);

/**
 * Sets the HighLighting Weapons privilege for client.
 *
 * @param iClient		Client for which to set the HighLighting Weapons privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_SetHLWeaponOne(int iClient);

/**
 * Sets the HighLighting Players privilege for client.
 *
 * @param iClient		Client for which to set the HighLighting Players privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_SetHLPlayerOne(int iClient);

/**
 * Remove the HighLighting Weapons privilege for client.
 *
 * @param iClient		Client for which to remove the HighLighting Weapons privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_RemoveHLWeaponOne(int iClient);

/**
 * Remove the HighLighting Players privilege for client.
 *
 * @param iClient		Client for which to remove the HighLighting Players privilege
 *
 * @return				True on success, false otherwsie
 *
 * On error/errors:		Invalid client index
 */
native bool EntWatch_RemoveHLPlayerOne(int iClient);

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

/**
 * Сalled when the EntWatch is ready to accept requests for privileges for HighLight Weapon
 *
 * @return				None
 */
forward void EntWatch_OnHLWeaponReady();

/**
 * Сalled when the EntWatch is ready to accept requests for privileges for HighLight Player
 *
 * @return				None
 */
forward void EntWatch_OnHLPlayerReady();

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
public __pl_EntWatch_SetNTVOptional()
{
	MarkNativeAsOptional("EntWatch_IsClientBanned");
	MarkNativeAsOptional("EntWatch_BanClient");
	MarkNativeAsOptional("EntWatch_UnbanClient");
	MarkNativeAsOptional("EntWatch_IsSpecialItem");
	MarkNativeAsOptional("EntWatch_HasSpecialItem");
}
#endif

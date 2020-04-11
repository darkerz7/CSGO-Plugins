#if defined _leader_included_
  #endinput
#endif
#define _leader_included_

/**
 * Returns current leader
 *
 * @return int    Client index of the leader (-1 = null)
 */
native Leader_CurrentLeader();
/**
 * Sets the leader
 *
 * @param client    Client index to be set as leader
 */
native Leader_SetLeader(client);

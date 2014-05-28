#if defined _boss_spawns_included
  #endinput
#endif
#define _boss_spawns_included

/**
 * Spawns a Hatman on the map. (Horsemann)
 *
 * @param client		Client spawning the boss. (0 = N/A)
 * @param X		Float value for X parameter of spawn location.
 * @param Y		Float value for Y parameter of spawn location.
 * @param Z		Float value for Z parameter of spawn location.
 * @param spew		True if to log, reply & show activity, false otherwise.
 * @param scale		Float value for the scale of the boss. (Default is 1.0)
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnHatman(client, Float:X, Float:Y, Float:Z, bool:spew = true, Float:scale = 1.0);

/**
 * Spawns an Eyeboss on the map. (Monoculus)
 *
 * @param client		Client spawning the boss. (0 = N/A)
 * @param X		Float value for X parameter of spawn location.
 * @param Y		Float value for Y parameter of spawn location.
 * @param Z		Float value for Z parameter of spawn location.
 * @param spew		True if to log, reply & show activity, false otherwise.
 * @param scale		Float value for the scale of the boss. (Default is 1.0)
 * @param type		0 = Normal, 1 = Red, 2 = Blue
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnEyeboss(client, Float:X, Float:Y, Float:Z, bool:spew = true, Float:scale = 1.0, type = 0);

/**
 * Spawns Merasmus on the map.
 *
 * @param client		Client spawning the boss. (0 = N/A)
 * @param X		Float value for X parameter of spawn location.
 * @param Y		Float value for Y parameter of spawn location.
 * @param Z		Float value for Z parameter of spawn location.
 * @param spew		True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnMerasmus(client, Float:X, Float:Y, Float:Z, bool:spew = true);

/**
 * Spawns a Skeleton on the map.
 *
 * @param client		Client spawning the boss. (0 = N/A)
 * @param X		Float value for X parameter of spawn location.
 * @param Y		Float value for Y parameter of spawn location.
 * @param Z		Float value for Z parameter of spawn location.
 * @param spew		True if to log, reply & show activity, false otherwise.
 * @param scale		Float value for the scale of the boss. (Default is 1.0)
 * @param type		0 = Green, 1 = Red, 2 = Blue
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnSkeleton(client, Float:X, Float:Y, Float:Z, bool:spew = true, Float:scale = 1.0, type = 0);

/**
 * Spawns the Skeleton King on the map.
 *
 * @param client		Client spawning the boss. (0 = N/A)
 * @param X		Float value for X parameter of spawn location.
 * @param Y		Float value for Y parameter of spawn location.
 * @param Z		Float value for Z parameter of spawn location.
 * @param spew		True if to log, reply & show activity, false otherwise.
 *
 * @return				True if spawned successfully, false otherwise.
 * @error				Invalid client or fields.
 */
native bool:TF2_SpawnSkeletonKing(client, Float:X, Float:Y, Float:Z, bool:spew = true);

public SharedPlugin:__pl_boss_spawns = 
{
	name = "BossSpawns",
	file = "BossSpawns.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_boss_spawns_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_SpawnHatman");
	MarkNativeAsOptional("TF2_SpawnEyeboss");
	MarkNativeAsOptional("TF2_SpawnMerasmus");
	MarkNativeAsOptional("TF2_SpawnSkeleton");
	MarkNativeAsOptional("TF2_SpawnSkeletonKing");
}
#endif

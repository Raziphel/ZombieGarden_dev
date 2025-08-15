// Zombies_Config.as
#include "CTF_Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"

// NOTE: ZombiesCore is defined in Zombies_Core.as (included before this file by Zombies_Main.as)

void Config(ZombiesCore@ this)
{
	string configstr = "../Mods/" + sv_gamemode + "/Rules/zombies_vars.cfg";
	if (getRules().exists("Zombiesconfig"))
	{
		configstr = getRules().get_string("Zombiesconfig");
	}
	ConfigFile cfg = ConfigFile(configstr);

	// no timer
	this.gameDuration = 0;
	getRules().set_bool("no timer", true);

	// ---------- caps from cfg ----------
	const s32 max_zombies      = cfg.read_s32("max_zombies",      125);
	const s32 max_pzombies     = cfg.read_s32("max_pzombies",      25);
	const s32 max_migrantbots  = cfg.read_s32("max_migrantbots",    5);
	const s32 max_wraiths      = cfg.read_s32("max_wraiths",        9);
	const s32 max_gregs        = cfg.read_s32("max_gregs",          6);
	const s32 max_imol         = cfg.read_s32("max_imol",           8);  // NEW

	getRules().set_s32("max_zombies",      max_zombies);
	getRules().set_s32("max_pzombies",     max_pzombies);
	getRules().set_s32("max_migrantbots",  max_migrantbots);
	getRules().set_s32("max_wraiths",      max_wraiths);
	getRules().set_s32("max_gregs",        max_gregs);
	getRules().set_s32("max_imol",         max_imol);               // NEW

	// ---------- misc tunables ----------
	getRules().set_bool("grave_spawn",     cfg.read_bool("grave_spawn", true));
	getRules().set_bool("zombify",         cfg.read_bool("zombify",     false));
	getRules().set_s32 ("days_to_survive", cfg.read_s32("days_to_survive", 100));
	getRules().set_s32 ("curse_day",       cfg.read_s32("curse_day",       75));
	getRules().set_s32 ("hardmode_day",       cfg.read_s32("hardmode_day",       50));
	getRules().set_s32 ("days_offset",     0);

	// respawn time (seconds -> ticks)
	this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 10));
}

/**
 * Centralized, lightweight counter refresh.
 * Call this on a cadence (the core does it every 150 ticks).
 * Writes *all* counts into rules so no “live” counting is needed elsewhere.
 */
void RefreshMobCountsToRules()
{
	CBlob@[] a;

	// by tag (bulk species)
	getBlobsByTag("zombie",     @a); getRules().set_s32("num_zombies",     a.length); a.clear();
	getBlobsByTag("pzombie",    @a); getRules().set_s32("num_pzombies",    a.length); a.clear();
	getBlobsByTag("migrantbot", @a); getRules().set_s32("num_migrantbots", a.length); a.clear();
	getBlobsByTag("wraiths",    @a); getRules().set_s32("num_wraiths",     a.length); a.clear();
	getBlobsByTag("gregs",      @a); getRules().set_s32("num_gregs",       a.length); a.clear();
	getBlobsByTag("ruinstorch", @a); getRules().set_s32("num_ruinstorch",  a.length); a.clear();
	getBlobsByTag("ZP",         @a); getRules().set_s32("num_zombiePortals", a.length); a.clear();

	// by exact blob name (bossy/specials we sometimes check directly)
	getBlobsByName("horror",       @a); getRules().set_s32("num_horror", a.length); a.clear();
	getBlobsByName("abomination",  @a); getRules().set_s32("num_abom",   a.length); a.clear();
	getBlobsByName("immolator",    @a); getRules().set_s32("num_immol",  a.length); a.clear();

	// players by tag (already used elsewhere)
	getBlobsByTag("survivorplayer", @a); getRules().set_s32("num_survivors", a.length); a.clear();
	getBlobsByTag("undeadplayer",   @a); getRules().set_s32("num_undead",    a.length); a.clear();
}

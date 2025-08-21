// Zombies_Config.as
// Central place to configure zombie survival values without external .cfg

#include "Zombies_Core.as"

void Config(ZombiesCore@ this)
{
	// ============================
	// Tunables
	// ============================

    // How long a dead player waits before they can respawn (seconds)
    this.spawnTime = 60;

    // round-specific bookkeeping so values don't persist between rounds
    this.rules.set_f32("difficulty_bonus", 0.0f);
    this.rules.set_s32("last_wipe_day", -1);
    this.rules.set_s32("days_offset", 0);
    this.rules.set_f32("difficulty", 0.0f);

    // ----------------------------
    // Mob limits (hard caps)
	// New waves will not spawn if the active count for that mob is >= its cap
	// ----------------------------
	this.rules.set_s32("max_zombies",     250);   // standard zombies
	this.rules.set_s32("max_pzombies",    25);    // portal-spawned zombies
	this.rules.set_s32("max_migrantbots", 4);     // migrants
    this.rules.set_s32("max_wraiths",     20);
    this.rules.set_s32("max_gregs",       10);
    this.rules.set_s32("max_imol",        5);
    this.rules.set_s32("max_digger",      5);
    this.rules.set_s32("max_bison",       8);
    this.rules.set_s32("max_banshees",    6);
    this.rules.set_s32("max_horror",      8);
    this.rules.set_s32("max_gasbags",     10);

	// ----------------------------
	// Win/Loss pacing
	// ----------------------------
	this.rules.set_s32("days_to_survive", 0);           // <= 0 means endless
    this.rules.set_s32("curse_day",        250);        // night(s) from which survivors can auto-zombify
    this.rules.set_s32("hardmode_day",     100);        // the day zombies can spawn during the day
    this.rules.set_bool("ruins_portal_active", false);  // ruins become portals once a pillar falls
    this.rules.Sync("ruins_portal_active", false);      // If ruins have spawned portals or not.

	// ----------------------------
	// Flavor toggles
	// ----------------------------
	this.rules.set_bool("grave_spawn", true);  // spawn graves with loot at markers
	this.rules.set_bool("zombify",     true);  // allow players to zombify after death

	// ----------------------------
	// Debug logging (optional)
	// ----------------------------
	print("Zombies_Config :: Loaded static config");
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
	getBlobsByTag("zombie",     @a); getRules().set_s32("num_zombies",       a.length); a.clear();
	getBlobsByTag("pzombie",    @a); getRules().set_s32("num_pzombies",      a.length); a.clear();
	getBlobsByTag("migrantbot", @a); getRules().set_s32("num_migrantbots",   a.length); a.clear();
	getBlobsByTag("wraiths",    @a); getRules().set_s32("num_wraiths",       a.length); a.clear();
	getBlobsByTag("gregs",      @a); getRules().set_s32("num_gregs",         a.length); a.clear();
	getBlobsByTag("bisons",     @a); getRules().set_s32("num_bisons",        a.length); a.clear();
    getBlobsByTag("ruinstorch", @a); getRules().set_s32("num_ruinstorch",    a.length); a.clear();


    // by exact blob name (bossy/specials we sometimes check directly)
    getBlobsByName("zombieportal", @a); getRules().set_s32("num_zombiePortals", a.length); a.clear();
    getBlobsByName("horror",       @a); getRules().set_s32("num_horror",        a.length); a.clear();
    getBlobsByName("pbanshee",     @a); getRules().set_s32("num_banshees",      a.length); a.clear();
    getBlobsByName("gasbag",       @a); getRules().set_s32("num_gasbags",       a.length); a.clear();
    getBlobsByName("abomination",  @a); getRules().set_s32("num_abom",          a.length); a.clear();
    getBlobsByName("immolator",    @a); getRules().set_s32("num_immol",         a.length); a.clear();
    getBlobsByName("digger",       @a); getRules().set_s32("num_digger",        a.length); a.clear();
    getBlobsByName("zombiealter",  @a); getRules().set_s32("num_alters",        a.length); getRules().set_s32("zombiealter", a.length); a.clear();

	// players by tag (already used elsewhere)
	getBlobsByTag("survivorplayer", @a); getRules().set_s32("num_survivors", a.length); a.clear();
	getBlobsByTag("undeadplayer",   @a); getRules().set_s32("num_undead",    a.length); a.clear();
}

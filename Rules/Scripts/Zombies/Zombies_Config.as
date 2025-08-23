// Zombies_Config.as
// Central place to configure zombie survival values without external .cfg

#include "Zombies_Core.as"

void Config(ZombiesCore @ this)
{
	// ============================
	// Tunables
	// ============================

	// How long a dead player waits before they can respawn (seconds)
	this.spawnTime = 0.2f;
	this.rules.set_f32("spawn_time", this.spawnTime);
	this.rules.Sync("spawn_time", true);

	// round-specific bookkeeping so values don't persist between rounds
	this.rules.set_f32("difficulty_bonus", 0.0f);
	this.rules.set_s32("last_wipe_day", -1);
	this.rules.set_s32("days_offset", 0);
	this.rules.set_f32("difficulty", 0.1f);

	this.rules.Sync("difficulty_bonus", true);
	this.rules.Sync("last_wipe_day", true);
	this.rules.Sync("days_offset", true);
	this.rules.Sync("difficulty", true);

	// ----------------------------
	// Mob limits (hard caps)
	// New waves will not spawn if the active count for that mob is >= its cap
	// ----------------------------
	this.rules.set_s32("max_zombies", 250);	  // standard zombies
	this.rules.set_s32("max_pzombies", 25);	  // portal-spawned zombies
	this.rules.set_s32("max_migrantbots", 4); // migrants
	this.rules.set_s32("max_wraiths", 20);
	this.rules.set_s32("max_gregs", 10);
	this.rules.set_s32("max_imol", 5);
	this.rules.set_s32("max_digger", 5);
	this.rules.set_s32("max_bison", 8);
	this.rules.set_s32("max_banshees", 6);
	this.rules.set_s32("max_horror", 8);
	this.rules.set_s32("max_gasbags", 10);

	this.rules.Sync("max_zombies", true);
	this.rules.Sync("max_pzombies", true);
	this.rules.Sync("max_migrantbots", true);
	this.rules.Sync("max_wraiths", true);
	this.rules.Sync("max_gregs", true);
	this.rules.Sync("max_imol", true);
	this.rules.Sync("max_digger", true);
	this.rules.Sync("max_bison", true);
	this.rules.Sync("max_banshees", true);
	this.rules.Sync("max_horror", true);
	this.rules.Sync("max_gasbags", true);

	// ----------------------------
	// Win/Loss pacing
	// ----------------------------
	this.rules.set_s32("days_to_survive", 0);		   // <= 0 means endless
	this.rules.set_s32("curse_day", 250);			   // night(s) from which survivors can auto-zombify
	this.rules.set_s32("hardmode_day", 100);		   // the day zombies can spawn during the day
	this.rules.set_bool("ruins_portal_active", false); // ruins become portals once a pillar falls
	this.rules.Sync("days_to_survive", true);
	this.rules.Sync("curse_day", true);
	this.rules.Sync("hardmode_day", true);
	this.rules.Sync("ruins_portal_active", true); // If ruins have spawned portals or not.

	// ----------------------------
	// Flavor toggles
	// ----------------------------
	this.rules.set_bool("grave_spawn", true); // spawn graves with loot at markers
	this.rules.set_bool("zombify", true);	  // allow players to zombify after death
	this.rules.Sync("grave_spawn", true);
	this.rules.Sync("zombify", true);

	// ----------------------------
	// Debug logging (optional)
	// ----------------------------
	// Removed runtime print to reduce log overhead
}

/**
 * Centralized, lightweight counter refresh.
 * Call this on a cadence (the core does it every 150 ticks).
 * Writes *all* counts into rules so no “live” counting is needed elsewhere.
 */
void RefreshMobCountsToRules()
{
	CRules @rules = getRules();

	s32 num_zombies = 0;
	s32 num_pzombies = 0;
	s32 num_migrantbots = 0;
	s32 num_wraiths = 0;
	s32 num_gregs = 0;
	s32 num_bisons = 0;
	s32 num_ruinstorch = 0;
	s32 num_zombiePortals = 0;
	s32 num_horror = 0;
	s32 num_banshees = 0;
	s32 num_gasbags = 0;
	s32 num_abom = 0;
	s32 num_immol = 0;
	s32 num_digger = 0;
	s32 num_alters = 0;
	s32 num_survivors = 0;
	s32 num_undead = 0;

	CBlob @[] all;
	getBlobs(@all);
	for (uint i = 0; i < all.length; ++i)
	{
		CBlob @b = all[i];
		const string name = b.getName();

		if (b.hasTag("zombie"))
			num_zombies++;
		if (b.hasTag("pzombie"))
			num_pzombies++;
		if (b.hasTag("migrantbot"))
			num_migrantbots++;
		if (b.hasTag("wraiths"))
			num_wraiths++;
		if (b.hasTag("gregs"))
			num_gregs++;
		if (b.hasTag("bisons"))
			num_bisons++;
		if (b.hasTag("ruinstorch"))
			num_ruinstorch++;
		if (b.hasTag("survivorplayer"))
			num_survivors++;
		if (b.hasTag("undeadplayer"))
			num_undead++;

		if (name == "zombieportal")
			num_zombiePortals++;
		else if (name == "horror")
			num_horror++;
		else if (name == "pbanshee")
			num_banshees++;
		else if (name == "gasbag")
			num_gasbags++;
		else if (name == "abomination")
			num_abom++;
		else if (name == "immolator")
			num_immol++;
		else if (name == "digger")
			num_digger++;
		else if (name == "zombiealter")
			num_alters++;
	}

	rules.set_s32("num_zombies", num_zombies);
	rules.set_s32("num_pzombies", num_pzombies);
	rules.set_s32("num_migrantbots", num_migrantbots);
	rules.set_s32("num_wraiths", num_wraiths);
	rules.set_s32("num_gregs", num_gregs);
	rules.set_s32("num_bisons", num_bisons);
	rules.set_s32("num_ruinstorch", num_ruinstorch);
	rules.set_s32("num_zombiePortals", num_zombiePortals);
	rules.set_s32("num_horror", num_horror);
	rules.set_s32("num_banshees", num_banshees);
	rules.set_s32("num_gasbags", num_gasbags);
	rules.set_s32("num_abom", num_abom);
	rules.set_s32("num_immol", num_immol);
	rules.set_s32("num_digger", num_digger);
	rules.set_s32("num_alters", num_alters);
	rules.set_s32("zombiealter", num_alters);
	rules.set_s32("num_survivors", num_survivors);
	rules.set_s32("num_undead", num_undead);

	const string[] props = {
		"num_zombies", "num_pzombies", "num_migrantbots", "num_wraiths", "num_gregs", "num_bisons", "num_ruinstorch", "num_zombiePortals", "num_horror", "num_banshees", "num_gasbags", "num_abom", "num_immol", "num_digger", "num_alters", "zombiealter", "num_survivors", "num_undead"};
	for (uint i = 0; i < props.length; ++i)
		rules.Sync(props[i], true);
}

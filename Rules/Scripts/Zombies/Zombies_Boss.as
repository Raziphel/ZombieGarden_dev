// ===== Zombies_Boss.as — Boss/Mini/Cataclysm wave system =================
#include "GlobalPopup.as"
#include "Zombies_HordePriority.as"

// ---------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------

enum WaveKind
{
	WAVE_NONE = 0,
	WAVE_MINI,
	WAVE_BOSS,
	WAVE_CATACLYSM
}

// Fallback edge spawn if no markers provided
Vec2f
GetFallbackBossSpawn()
{
	CMap @map = getMap();
	if (map is null)
		return Vec2f(0, 0);

	const f32 w = map.tilemapwidth * map.tilesize;
	const f32 h = map.tilemapheight * map.tilesize;

	const bool left = (XORRandom(2) == 0);
	const f32 x = left ? 32.0f : (w - 32.0f);
	Vec2f pos(x, 32.0f);

	// Use the terrain's actual surface for fallback spawns. The old
	// random height + 24-step walk could leave a boss buried in terrain
	// or hovering in the air on tall or deeply excavated maps.
	const s32 column = s32(x / map.tilesize);
	const f32 groundY = map.getLandYAtX(column) * map.tilesize - 16.0f;
	pos.y = Maths::Clamp(groundY, 16.0f, Maths::Max(16.0f, h - 16.0f));
	return pos;
}

// Spread large milestone waves across several updates rather than creating
// dozens of physics bodies, sprites and brains in the same server tick.
const int BOSS_SPAWN_BATCH_SIZE = 3;
const u32 BOSS_SPAWN_BATCH_TICKS = 5;
// Milestone enemies may temporarily exceed the ordinary horde cap, but
// cannot grow it without bound during a long or heavily populated round.
const int BOSS_SPAWN_EXTRA_HEADROOM = 24;
const u32 BOSS_SPAWN_QUEUE_TIMEOUT = 180 * 30;

string[] zg_boss_pending_names;
int[] zg_boss_pending_counts;
Vec2f[] zg_boss_pending_positions;
u32 zg_boss_next_batch_tick = 0;
u32 zg_boss_queue_started_tick = 0;
int zg_boss_failed_attempts = 0;

void ResetBossSpawnQueue()
{
	zg_boss_pending_names.clear();
	zg_boss_pending_counts.clear();
	zg_boss_pending_positions.clear();
	zg_boss_next_batch_tick = 0;
	zg_boss_queue_started_tick = 0;
	zg_boss_failed_attempts = 0;
}

void QueueBossSpawns(const string&in blobName, int count, const Vec2f&in pos)
{
	if (blobName.length == 0 || count <= 0)
		return;

	if (zg_boss_pending_names.length == 0)
		zg_boss_queue_started_tick = getGameTime();

	zg_boss_pending_names.push_back(blobName);
	zg_boss_pending_counts.push_back(count);
	zg_boss_pending_positions.push_back(pos);
}

void ProcessBossSpawnQueue()
{
	if (!isServer() || zg_boss_pending_names.length == 0 ||
		getGameTime() < zg_boss_next_batch_tick)
		return;

	CRules @rules = getRules();
	CMap @map = getMap();
	if (rules is null || map is null || !rules.isMatchRunning() ||
		getPlayersCount() == 0)
		return;

	// A stalemate must not leave hundreds of delayed spawns in memory
	// forever. The remaining portion of this encounter is abandoned if
	// players have not made room after three minutes.
	if (getGameTime() - zg_boss_queue_started_tick > BOSS_SPAWN_QUEUE_TIMEOUT)
	{
		warn("Zombie Garden: boss reinforcements timed out at population cap.");
		ResetBossSpawnQueue();
		return;
	}

	// Ordinary spawns stop at max_zombies. A milestone encounter gets 24
	// extra slots, not an unbounded exemption from the performance limit.
	CBlob @[] currentZombies;
	getBlobsByTag("zombie", @currentZombies);
	int livingZombies = 0;
	for (uint i = 0; i < currentZombies.length; ++i)
	{
		CBlob @zombie = currentZombies[i];
		if (zombie !is null && !zombie.hasTag("dead"))
			livingZombies++;
	}
	const int bossPopulationLimit =
		Maths::Max(0, rules.get_s32("max_zombies")) + BOSS_SPAWN_EXTRA_HEADROOM;

	for (int i = 0; i < BOSS_SPAWN_BATCH_SIZE &&
		zg_boss_pending_names.length > 0; ++i)
	{
		CBlob @weak;
		if (livingZombies >= Maths::Max(0, rules.get_s32("max_zombies")))
		{
			// Prefer a genuine weak-to-strong replacement at the normal cap.
			// The old 24 extra milestone slots are a fallback when no safe
			// distant victim exists, not an excuse to inflate every horde.
			if (ZGCanReplaceHordeMob(rules, true))
				@weak = ZGFindWeakHordeMob(zg_boss_pending_names[0]);
			if (weak is null && livingZombies >= bossPopulationLimit)
				break;
		}

		Vec2f spawnPos = zg_boss_pending_positions[0];
		spawnPos.x += (int(XORRandom(3)) - 1) * 8.0f;
		CBlob @spawned = server_CreateBlob(zg_boss_pending_names[0], -1, spawnPos);
		if (spawned is null)
		{
			// Retry transient failures, then skip a permanently unavailable
			// entity rather than blocking the remaining boss encounter.
			zg_boss_failed_attempts++;
			if (zg_boss_failed_attempts < 3)
				break;
			warn("Zombie Garden: skipped a boss reinforcement that failed to spawn.");
			zg_boss_failed_attempts = 0;
		}
		else
		{
			zg_boss_failed_attempts = 0;
			// A naturally weak class may also appear in a themed wave.
			// Never make that milestone unit a retirement candidate.
			spawned.Tag("zg_boss_spawn");
			if (weak !is null)
				ZGRetireHordeMob(rules, weak);
			else
				livingZombies++;
		}

		zg_boss_pending_counts[0]--;
		if (zg_boss_pending_counts[0] <= 0)
		{
			zg_boss_pending_names.erase(0);
			zg_boss_pending_counts.erase(0);
			zg_boss_pending_positions.erase(0);
		}
	}
	zg_boss_next_batch_tick = getGameTime() + BOSS_SPAWN_BATCH_TICKS;
}

// Pick wave kind from the day number.
// - 25/50/75/100... => "Cataclysm" (special milestone) — highest priority
// - ends with 0 => Boss wave
// - ends with 5 => Mini-boss wave
WaveKind GetWaveKindForDay(const int dayNumber)
{
	// Day zero is used during round setup, but must never trigger an
	// immediate Cataclysm because 0 % 25 is also zero.
	if (dayNumber <= 0)
		return WAVE_NONE;

	if (dayNumber % 25 == 0)
		return WAVE_CATACLYSM; // highest priority & exclusive

	const int lastDigit = dayNumber % 10;

	if (lastDigit == 0 && (dayNumber % 25 != 0))
		return WAVE_BOSS;
	if (lastDigit == 5 && (dayNumber % 25 != 0))
		return WAVE_MINI;

	return WAVE_NONE;
}

// ---------------------------------------------------------------------
// Table-driven definitions
// ---------------------------------------------------------------------

class BossEntry
{
	// Weighted random selection within a wave kind
	int weight;

	// What to spawn
	array<string> names;
	array<int> counts;

	// UI + SFX
	string popup;
	SColor color;
	u32 popupTicks;
	string sound;
}

// Balanced, lightweight encounters
array<BossEntry @>
BuildMiniTable()
{
	array<BossEntry @> t;

	{
		BossEntry b;
		b.weight = 3;
		b.names.push_back("horror");
		b.counts.push_back(2);
		b.popup = "MINI-WAVE\n\n2x Horrors\n16 Hearts • Spawns 3 zombies on death";
		b.color = SColor(255, 255, 200, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 3;
		b.names.push_back("pbanshee");
		b.counts.push_back(3);
		b.popup = "MINI-WAVE\n\n3x Banshee\nExplosive + Stunning Scream";
		b.color = SColor(255, 255, 200, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("writher");
		b.counts.push_back(1);
		b.popup = "MINI-WAVE\n\n1x Writher\nExploding Rot Clouds • Spawns 3x Wraiths on death";
		b.color = SColor(255, 255, 200, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("zbison");
		b.names.push_back("zbison2");
		b.counts.push_back(4);
		b.counts.push_back(4);
		b.popup = "MINI-WAVE\n\n8x Bisons\nTough and charges";
		b.color = SColor(255, 255, 200, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("immolator");
		b.counts.push_back(8);
		b.popup = "MINI-WAVE\n\n8x Immolator\nCharging explosion\nSpawns Rot clouds on death";
		b.color = SColor(255, 255, 200, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}

	return t;
}

// Heavy encounters (old “boss”)
array<BossEntry @> BuildBossTable()
{
	array<BossEntry @> t;

	{
		BossEntry b;
		b.weight = 3;
		b.names.push_back("abomination");
		b.counts.push_back(1);
		b.popup = "BOSS WAVE\n\n1x Abominations\n60 Hearts • 4 DMG";
		b.color = SColor(255, 255, 0, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("horror");
		b.counts.push_back(5);
		b.popup = "BOSS WAVE\n\n5x Horror\n16 Hearts • Spawns 3 zombies on death";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("writher");
		b.counts.push_back(2);
		b.popup = "BOSS WAVE\n\n2x Writhers\nExploding Rot Clouds • Spawns 3x Wraiths on death";
		b.color = SColor(255, 255, 0, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("immolator");
		b.counts.push_back(16);
		b.popup = "BOSS WAVE\n\n16x Immolator\nCharging explosion\nSpawns Rot clouds on death";
		b.color = SColor(255, 255, 0, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 1;
		b.names.push_back("greg");
		b.names.push_back("greg2");
		b.counts.push_back(8);
		b.counts.push_back(8);
		b.popup = "BOSS WAVE\n\n16x Gregs\nGrabs players and drops them from the sky\nCan carry zombies to your base";
		b.color = SColor(255, 255, 0, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 1;
		b.names.push_back("digger");
		b.counts.push_back(3);
		b.popup = "BOSS WAVE\n\n3x Diggers\nFlying blades that rip through walls";
		b.color = SColor(255, 255, 0, 0);
		b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg";
		t.push_back(b);
	}

	return t;
}

// Milestone “special boss waves” (rename: **Cataclysm Waves**)
// Triggered at 25/50/75/100…
array<BossEntry @> BuildCataclysmTable(const int dayNumber)
{
	array<BossEntry @> t;

	// You can branch by milestone here if you want different themes
	// Example themes: 25=“Onslaught”, 50=“Cataclysm”, 75=“Rapture”,
	// 100=“Apocalypse”
	const int milestone = (dayNumber % 100 == 0 ? 100 : dayNumber % 75 == 0 ? 75 : dayNumber % 50 == 0		? 50 : 25);

	string banner = "CATACLYSM WAVE\n\n";

	{
		BossEntry b;
		b.weight = 3;
		b.names.push_back("abomination");
		b.counts.push_back(3);
		b.popup = banner + "3x Abomination\n60 Hearts • 4 DMG";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 3;
		b.names.push_back("writher");
		b.counts.push_back(5);
		b.popup = banner + "5x Writher\nExploding Rot Clouds • Spawns 3x Wraiths on death";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("immolator");
		b.counts.push_back(32);
		b.popup = banner + "32x Immolator\nCharging explosion\nSpawns Rot clouds on death";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 2;
		b.names.push_back("horror");
		b.counts.push_back(6);
		b.popup = banner + "6x Horror\n16 Hearts • Spawns 3 zombies on death";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}
	{
		BossEntry b;
		b.weight = 1;
		b.names.push_back("digger");
		b.counts.push_back(7);
		b.popup = banner + "7x Diggers\nFlying blades that rip through walls";
		b.color = SColor(255, 255, 80, 40);
		b.popupTicks = 12 * getTicksASecond();
		b.sound = "/FanfareLose.ogg";
		t.push_back(b);
	}

	return t;
}

// Keep the original weighted odds, but don't pick the exact same
// composition two milestone waves in a row. Other kinds have their
// own history, so mini-bosses never suppress regular bosses.
uint PickWeightedIndex(const array<BossEntry @> @tbl, const int previous)
{
	const bool skipPrevious =
		tbl.length > 1 && previous >= 0 && previous < int(tbl.length);
	int total = 0;
	for (uint i = 0; i < tbl.length; ++i)
	{
		if (!skipPrevious || int(i) != previous)
			total += Maths::Max(1, tbl[i].weight);
	}
	int pick = XORRandom(Maths::Max(1, total));
	for (uint i = 0; i < tbl.length; ++i)
	{
		if (skipPrevious && int(i) == previous)
			continue;
		pick -= Maths::Max(1, tbl[i].weight);
		if (pick < 0)
			return i;
	}
	for (uint i = 0; i < tbl.length; ++i)
	{
		if (!skipPrevious || int(i) != previous)
			return i;
	}
	return 0;
}

// ---------------------------------------------------------------------
// Main entry
// ---------------------------------------------------------------------
int RunBossWave(const int dayNumber, const float difficulty,
				Vec2f[] @zombiePlaces, const int transition_in)
{
	int transition = transition_in;
	CRules @rules = getRules();

	// Only fire once per eligible day when armed
	if (transition != 1)
		return transition;

	// Prevent double boss waves within the same day
	const int lastSpawnDay =
		rules.exists("boss_spawned_day") ? rules.get_s32("boss_spawned_day") : -1;
	if (lastSpawnDay == dayNumber)
		return 0; // a finished wave is no longer armed this day

	const WaveKind kind = GetWaveKindForDay(dayNumber);
	if (kind == WAVE_NONE)
		return transition;

	// Pick a spawn position (prefer markers, fallback to edge)
	Vec2f sp;
	if (zombiePlaces !is null && zombiePlaces.length > 0)
		sp = zombiePlaces[XORRandom(zombiePlaces.length)];
	else
		sp = GetFallbackBossSpawn();

	// Build the right table for this day
	array<BossEntry @> table;
	if (kind == WAVE_MINI)
		table = BuildMiniTable();
	else if (kind == WAVE_BOSS)
		table = BuildBossTable();
	else
		table = BuildCataclysmTable(dayNumber);

	if (table.length == 0)
		return transition;

	const string encounterKey = kind == WAVE_MINI ? "zg_last_mini_encounter" :
		(kind == WAVE_BOSS ? "zg_last_boss_encounter" : "zg_last_cataclysm_encounter");
	const int previousEncounter = rules.exists(encounterKey) ?
		rules.get_s32(encounterKey) : -1;
	const uint idx = PickWeightedIndex(@table, previousEncounter);
	BossEntry @e = table[idx];
	if (e is null || e.names.length == 0)
		return transition;

	// Lock the transition only after we have a valid encounter to queue.
	transition = 0;

	// Server: queue spawns + popup
	if (isServer())
	{
		for (uint k = 0; k < e.names.length; k++)
		{
			const int count = (k < e.counts.length ? e.counts[k] : 1);
			QueueBossSpawns(e.names[k], count, sp);
		}
		Server_GlobalPopup(rules, e.popup, e.color, e.popupTicks);
		// Zombies_Main.as is SERVER_ONLY. Send the selected sound to
		// Zombies_Interface.as, which actually runs on players' clients.
		rules.set_string("boss_wave_sound", e.sound);
		rules.Sync("boss_wave_sound", true);
		rules.set_s32("boss_spawned_day", dayNumber);
		rules.Sync("boss_spawned_day", true);
		rules.set_s32(encounterKey, int(idx));
	}

	return transition;
}

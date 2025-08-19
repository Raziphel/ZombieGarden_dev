// ===== Zombies_Boss.as — Boss/Mini/Cataclysm wave system =================
#include "GlobalPopup.as"

// ---------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------

enum WaveKind { WAVE_NONE = 0, WAVE_MINI, WAVE_BOSS, WAVE_CATACLYSM }

// Fallback edge spawn if no markers provided
Vec2f GetFallbackBossSpawn()
{
	CMap@ map = getMap();
	if (map is null) return Vec2f(0, 0);

	const f32 w = map.tilemapwidth  * map.tilesize;
	const f32 h = map.tilemapheight * map.tilesize;

	const bool left = (XORRandom(2) == 0);
	const f32  x    = left ? 32.0f : (w - 32.0f);
	      f32  y    = 32.0f + XORRandom(Maths::Max(32, int(h - 64)));

	Vec2f pos(x, y);

	// settle roughly to ground
	for (int i = 0; i < 24; i++)
	{
		if (map.isTileSolid(pos + Vec2f(0, 8))) break;
		pos.y += 8;
	}
	return pos;
}

// Spawn N of blob @ position
void SpawnMany(const string &in blobName, int count, const Vec2f &in pos)
{
	for (int i = 0; i < count; i++)
	{
		server_CreateBlob(blobName, -1, pos);
	}
}

// Pick wave kind from the day number.
// - 25/50/75/100... => "Cataclysm" (special milestone) — highest priority
// - ends with 0 => Boss wave
// - ends with 5 => Mini-boss wave
WaveKind GetWaveKindForDay(const int dayNumber)
{
    if (dayNumber % 25 == 0) return WAVE_CATACLYSM; // highest priority & exclusive

    const int lastDigit = dayNumber % 10;

    if (lastDigit == 0 && (dayNumber % 25 != 0)) return WAVE_BOSS;
    if (lastDigit == 5 && (dayNumber % 25 != 0)) return WAVE_MINI;

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
	array<int>    counts;

	// UI + SFX
	string popup;
	SColor color;
	u32    popupTicks;
	string sound;
}

// Balanced, lightweight encounters
array<BossEntry@> BuildMiniTable()
{
	array<BossEntry@> t;

	{
		BossEntry b; b.weight = 3;
		b.names = {"horror"}; b.counts = {3};
		b.popup = "MINI-WAVE\n\n3x Horrors\n16 Hearts • Spawns specials";
		b.color = SColor(255,255,200,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 3;
		b.names = {"pbanshee"}; b.counts = {2};
		b.popup = "MINI-WAVE\n\n2x Banshee\nBlast + Stunning Scream";
		b.color = SColor(255,255,200,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"writher"}; b.counts = {1};
		b.popup = "MINI-WAVE\n\n1x Writher\nExplodes • Spawns Wraiths on death";
		b.color = SColor(255,255,200,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"zbison","zbison2"}; b.counts = {4,4};
		b.popup = "MINI-WAVE\n\nBison Horde\n8 total (4 of each)";
		b.color = SColor(255,255,200,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"immolator"}; b.counts = {8};
		b.popup = "MINI-WAVE\n\n8x Immolator\nChain booms — keep distance";
		b.color = SColor(255,255,200,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}

	return t;
}

// Heavy encounters (old “boss”)
array<BossEntry@> BuildBossTable()
{
	array<BossEntry@> t;

	{
		BossEntry b; b.weight = 3;
		b.names = {"abomination"}; b.counts = {2};
		b.popup = "BOSS WAVE\n\n2x Abominations\n60 Hearts • 4 DMG";
		b.color = SColor(255,255,0,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"writher"}; b.counts = {3};
		b.popup = "BOSS WAVE\n\n3x Writhers\nExplodes • Spawns Wraiths";
		b.color = SColor(255,255,0,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"immolator"}; b.counts = {16};
		b.popup = "BOSS WAVE\n\n16x Immolator\nWide-area blast pressure";
		b.color = SColor(255,255,0,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 1;
		b.names = {"zbison","zbison2"}; b.counts = {8,8};
		b.popup = "BOSS WAVE\n\nStampede\n16 total";
		b.color = SColor(255,255,0,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 1;
		b.names = {"digger"}; b.counts = {3};
		b.popup = "BOSS WAVE\n\n3x Diggers\nFlying blades that rip through walls";
		b.color = SColor(255,255,0,0); b.popupTicks = 10 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}

	return t;
}

// Milestone “special boss waves” (rename: **Cataclysm Waves**)
// Triggered at 25/50/75/100…
array<BossEntry@> BuildCataclysmTable(const int dayNumber)
{
	array<BossEntry@> t;

	// You can branch by milestone here if you want different themes
	// Example themes: 25=“Onslaught”, 50=“Cataclysm”, 75=“Rapture”, 100=“Apocalypse”
	const int milestone = (dayNumber % 100 == 0 ? 100 :
	                       dayNumber % 75  == 0 ? 75  :
	                       dayNumber % 50  == 0 ? 50  : 25);

	string banner = "CATACLYSM WAVE\n\n";

	{
		BossEntry b; b.weight = 3;
		b.names = {"abomination","writher"}; b.counts = {3,3};
		b.popup = banner + "3x Abomination + 3x Writher\nTank + burst combo";
		b.color = SColor(255,255,80,40); b.popupTicks = 12 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 3;
		b.names = {"pbanshee","wraith"}; b.counts = {3,6};
		b.popup = banner + "3x Banshee + 6x Wraith\nControl + chasers";
		b.color = SColor(255,255,80,40); b.popupTicks = 12 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"immolator","writher"}; b.counts = {8,4,4};
		b.popup = banner + "16x Immolator + 4x Writher\nChain detonation hazard";
		b.color = SColor(255,255,80,40); b.popupTicks = 12 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 2;
		b.names = {"zbison","zbison2","horror"}; b.counts = {8,8,4};
		b.popup = banner + "Bison stampede + 4x Horror\nCrowd + elites";
		b.color = SColor(255,255,80,40); b.popupTicks = 12 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}
	{
		BossEntry b; b.weight = 1;
		b.names = {"digger"}; b.counts = {7};
		b.popup = banner + "7x Diggers\nExcavation Team";
		b.color = SColor(255,255,80,40); b.popupTicks = 12 * getTicksASecond();
		b.sound = "/dontyoudare.ogg"; t.push_back(b);
	}

	return t;
}

// Weighted pick helper
uint PickWeightedIndex(const array<BossEntry@>@ tbl)
{
	int total = 0;
	for (uint i = 0; i < tbl.length; i++) total += Maths::Max(1, tbl[i].weight);
	int pick = XORRandom(Maths::Max(1, total));
	for (uint i = 0; i < tbl.length; i++)
	{
		pick -= Maths::Max(1, tbl[i].weight);
		if (pick < 0) return i;
	}
	return tbl.length - 1;
}

// ---------------------------------------------------------------------
// Main entry
// ---------------------------------------------------------------------
int RunBossWave(const int dayNumber,
                const float difficulty,
                Vec2f[]@ zombiePlaces,
                const int transition_in)
{
	int transition = transition_in;

	// Only fire once per eligible day when armed
	if (transition != 1) return transition;

	const WaveKind kind = GetWaveKindForDay(dayNumber);
	if (kind == WAVE_NONE) return transition;

	// Pick a spawn position (prefer markers, fallback to edge)
	Vec2f sp;
	if (zombiePlaces !is null && zombiePlaces.length > 0)
		sp = zombiePlaces[XORRandom(zombiePlaces.length)];
	else
		sp = GetFallbackBossSpawn();

	// Lock the transition so we don't double-spawn this day
	transition = 0;

	// Build the right table for this day
	array<BossEntry@> table;
	if (kind == WAVE_MINI)        table = BuildMiniTable();
	else if (kind == WAVE_BOSS)   table = BuildBossTable();
	else                          table = BuildCataclysmTable(dayNumber);

	const uint idx = PickWeightedIndex(@table);
	BossEntry@ e = table[idx];

	// Server: spawn + popup
	if (isServer())
	{
		for (uint k = 0; k < e.names.length; k++)
		{
			const int count = (k < e.counts.length ? e.counts[k] : 1);
			SpawnMany(e.names[k], count, sp);
		}
		Server_GlobalPopup(getRules(), e.popup, e.color, e.popupTicks);
	}

	// Client: play the stinger (per-entry customizable)
	if (isClient() && e.sound.length > 0)
	{
		Sound::Play(e.sound);
	}

	return transition;
}

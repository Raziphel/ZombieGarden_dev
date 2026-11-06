// Zombies_Core.as
#include "Structs.as"
#include "GlobalPopup.as"
#include "RespawnSystem.as"
#include "RulesCore.as"
#include "Zombies_Boss.as"
#include "Zombies_Utils.as"

class ZombiesCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	f32 spawnTime;

	ZombiesSpawns @Zombies_spawns;
	// Fallback ground positions are map-dependent, not horde-dependent.
	Vec2f[] fallbackSpawnPlaces;
	bool fallbackSpawnPlacesReady;
	u32 fallbackSpawnRefreshTick;

	ZombiesCore()
	{}
	ZombiesCore(CRules @_rules, RespawnSystem @_respawns)
	{
		super(_rules, _respawns);
	}

	void Setup(CRules @_rules = null, RespawnSystem @_respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		@Zombies_spawns = cast<ZombiesSpawns @>(_respawns);
		fallbackSpawnPlaces.clear();
		fallbackSpawnPlacesReady = false;
		fallbackSpawnRefreshTick = 0;

		server_CreateBlob("music", 0, Vec2f(0, 0));

		const int gamestart = getGameTime();
		rules.set_s32("gamestart", gamestart);
		rules.Sync("gamestart", true);
		rules.SetCurrentState(WARMUP);
		rules.Untag("night"); // a new map must never inherit a previous night's flag
		ResetBossSpawnQueue();

		// Arm the boss transition for the first cycle
		rules.set_s32("transition", 1);
		rules.set_s32("last_boss_day", 0);
		rules.set_s32("boss_spawned_day", 0);
		rules.Sync("boss_spawned_day", true);
		rules.set_s32("zg_last_mini_encounter", -1);
		rules.set_s32("zg_last_boss_encounter", -1);
		rules.set_s32("zg_last_cataclysm_encounter", -1);
		rules.set_string("boss_wave_sound", "");
		rules.Sync("boss_wave_sound", true);

		// reset kill counter for new record tracking
		rules.set_u32("undead_kills", 0);
		rules.Sync("undead_kills", true);

		// seed counters once (single source of truth)
		RefreshMobCountsToRules();

		// seed initial difficulty value
		rules.set_f32("difficulty", 0.1f);
		rules.Sync("difficulty", true);
	}

	// Dawn's Respite: a modest reward for players who actually survived
	// the previous night. No payout for spectators, fallen players,
	// skipped days or cheat-adjusted rounds.
	void AwardDawnRespite(const int previousDay)
	{
		if (!rules.isMatchRunning() || !rules.get_bool("dawn_respite") ||
			rules.get_bool("dayCheated") || previousDay <= 0)
			return;

		const bool milestoneNight = GetWaveKindForDay(previousDay) != WAVE_NONE &&
			rules.get_s32("boss_spawned_day") == previousDay;
		const int coinReward = milestoneNight ? 85 : 25;
		const f32 healthRecovery = milestoneNight ? 1.0f : 0.5f;
		int survivorsRewarded = 0;

		for (int i = 0; i < getPlayersCount(); ++i)
		{
			CPlayer @player = getPlayer(i);
			if (player is null || player.getTeamNum() != 0)
				continue;

			CBlob @defender = player.getBlob();
			if (defender is null || defender.hasTag("dead") ||
				!defender.hasTag("survivorplayer"))
				continue;

			player.server_setCoins(player.getCoins() + coinReward);
			const f32 recoveredHealth = Maths::Min(
				defender.getInitialHealth(), defender.getHealth() + healthRecovery);
			if (recoveredHealth > defender.getHealth())
			{
				defender.server_SetHealth(recoveredHealth);
				// Use the existing short-lived Priest animation as immediate
				// feedback that the defender survived until sunrise.
				server_CreateBlob("healanimation", defender.getTeamNum(),
					defender.getPosition());
			}
			survivorsRewarded++;
		}

		if (survivorsRewarded > 0)
		{
			const string header = milestoneNight ?
				"MILESTONE NIGHT SURVIVED" : "DAWN'S RESPITE";
			Server_GlobalPopup(rules,
				header + "\nThe living defenders held the ruins.\n+" +
				coinReward + " coins and some healing.",
				SColor(255, 235, 210, 120), 5 * getTicksASecond());
		}
	}

	void Update()
	{
		if (rules.isGameOver())
		{
			ResetBossSpawnQueue();
			return;
		}

		ProcessBossSpawnQueue();

		// Refresh counts early so difficulty sees newly spawned altars
		if (getGameTime() < 30 || getGameTime() % 150 == 0)
		{
			RefreshMobCountsToRules(); // <— single source of truth
		}

		const int day_cycle = Maths::Max(1, int(rules.daycycle_speed * 60));
		int transition = rules.get_s32("transition");
		const int gamestart = rules.get_s32("gamestart");

		// easy reads (all counts come from rules now)
		const int max_zombies = rules.get_s32("max_zombies");
		const int num_zombies = rules.get_s32("num_zombies");
		const int max_pzombies = rules.get_s32("max_pzombies");
		const int num_pzombies = rules.get_s32("num_pzombies");
		const int max_migrantbots = rules.get_s32("max_migrantbots");
		const int num_migrantbots = rules.get_s32("num_migrantbots");
		const int max_wraiths = rules.get_s32("max_wraiths");
		const int num_wraiths = rules.get_s32("num_wraiths");
		const int max_gregs = rules.get_s32("max_gregs");
		const int num_gregs = rules.get_s32("num_gregs");
		const int max_imol = rules.get_s32("max_imol");
		const int num_immol = rules.get_s32("num_immol");
		const int max_banshees = rules.get_s32("max_banshees");
		const int num_banshees = rules.get_s32("num_banshees");
		const int max_horror = rules.get_s32("max_horror");
		const int num_horror = rules.get_s32("num_horror");
		const int max_gasbags = rules.get_s32("max_gasbags");
		const int num_gasbags = rules.get_s32("num_gasbags");
		const int num_alters = rules.get_s32("num_alters");

		// recompute simple derived values
		const int hardmode_day = rules.get_s32("hardmode_day");
		const int curse_day = rules.get_s32("curse_day");
		const int days_offset = rules.get_s32("days_offset");
		const bool ruins_portal_active = rules.get_bool("ruins_portal_active");
		const int dayNumber =
			days_offset +
			((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;

		const int timeElapsed = getGameTime() - gamestart;
		const bool hardmode = (dayNumber >= hardmode_day);

		// quick player team pass (used for max_undead)
		int num_survivors_p = 0;
		int num_living_survivors_p = 0;
		int num_undead_p = 0;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer @pl = getPlayer(i);
			if (pl is null)
				continue;
			if (pl.getTeamNum() == 0)
			{
				num_survivors_p++;
				CBlob @character = pl.getBlob();
				if (character !is null && character.hasTag("survivorplayer") &&
					!character.hasTag("dead"))
					num_living_survivors_p++;
			}
			else if (pl.getTeamNum() == 1)
				num_undead_p++;
		}
		const int max_undead = (num_survivors_p / 3);
		rules.set_s32("max_undead", max_undead);

		// expose the current day to the HUD for snappier rendering
		if (!rules.exists("hud_dayNumber") || rules.get_s32("hud_dayNumber") != dayNumber)
		{
			rules.set_s32("hud_dayNumber", dayNumber);
			rules.Sync("hud_dayNumber", true);
		}

		// transition from warmup to game
		if (rules.isWarmup() && timeElapsed > getTicksASecond() * 30)
		{
			rules.SetCurrentState(GAME);
		}

		// ------------------------------
		// Difficulty calculation + wipe bonus (once per day)
		// ------------------------------
		const int pillars = rules.get_s32("num_ruinstorch");
		const int altars = rules.get_s32("num_alters");
		const int survivors = rules.get_s32("num_survivors");
		const int undead = rules.get_s32("num_undead");

		// persistent bonus from wipes (defaults to 0 if missing)
		float wipeBonus = rules.exists("difficulty_bonus") ? rules.get_f32("difficulty_bonus") : 0.0f;

		// --- Guard: don't let first-day / warmup wipes count ---
		const bool isLive = rules.isMatchRunning();
		const bool pastGrace =
			(timeElapsed > (getTicksASecond() * 45)); // small post-GAME grace
		const bool allowWipeCheck = isLive && pastGrace && (dayNumber > 1);

		// A wipe is a transition from at least one living player to none.
		// Never penalize empty servers, spectators, or an unattended round
		// repeatedly on subsequent days.
		const bool hadLivingSurvivor = rules.get_bool("had_live_survivor");
		if (num_living_survivors_p > 0)
		{
			if (!hadLivingSurvivor)
				rules.set_bool("had_live_survivor", true);
		}
		else if (hadLivingSurvivor)
		{
			rules.set_bool("had_live_survivor", false);

			const int last_wipe_day = rules.get_s32("last_wipe_day");
			if (allowWipeCheck && last_wipe_day != dayNumber)
			{
				wipeBonus += 0.5f;
				rules.set_f32("difficulty_bonus", wipeBonus);
				rules.Sync("difficulty_bonus", true);
				rules.set_s32("last_wipe_day", dayNumber);

				Server_GlobalPopup(
					rules,
					"All survivors have fallen!\n\n+0.5 Difficulty",
					SColor(255, 255, 0, 0),
					6 * getTicksASecond());
			}
		}

		// final difficulty (apply cap after any bonus change)
		// baseline grows by 0.1 every day so altars can't stall scaling
		const float baseDifficulty = dayNumber * 0.25f;
		float difficulty = dayNumber * 0.65f;
		difficulty += pillars * 0.3f;	   // pillars add pressure
		difficulty -= altars * 0.2f;	   // altars ease the round
		difficulty += survivors * 0.05f;   // more survivors harden the waves
		difficulty += undead * 0.2f;	   // undead players make it tougher
		difficulty += days_offset * 0.05f; // manual day skips ups difficulty
		difficulty += wipeBonus;
		if (difficulty < baseDifficulty)
			difficulty = baseDifficulty;
		if (difficulty > 50.0f)
			difficulty = 50.0f; // expanded cap
		// The value is stable between wave/day updates; avoid a network sync every tick.
		if (!rules.exists("difficulty") || rules.get_f32("difficulty") != difficulty)
		{
			rules.set_f32("difficulty", difficulty);
			rules.Sync("difficulty", true);
		}

		int spawnRate = 200 - int(difficulty * 3.3);
		if (spawnRate < 15)
			spawnRate = 15;

		// === day/night detection ===
		CMap @map = getMap();
		bool isNight = false;
		if (map !is null)
		{
			isNight = (map.getDayTime() > 0.8f || map.getDayTime() < 0.1f);
			if (isNight)
			{
				if (!rules.hasTag("night"))
				{
					rules.Tag("night");
					transition = 1; // allow boss trigger when night begins
					rules.set_s32("transition", transition);
				}
			}
			else
			{
				// Reward the actual transition from night to daylight, rather
				// than midnight (where the numeric day advances but danger remains).
				// Record the processed night even if no defender qualifies so
				// respawning after sunrise cannot grant an unearned payout.
				if (rules.hasTag("night") && dayNumber > 1 &&
					rules.get_s32("last_dawn_respite_day") != dayNumber - 1)
				{
					rules.set_s32("last_dawn_respite_day", dayNumber - 1);
					AwardDawnRespite(dayNumber - 1);
				}
				rules.Untag("night");
			}
		}

		// A short, once-per-day warning gives builders time to prepare
		// before the night wave. Use the same day-based boss table as the
		// actual encounter director so the warning cannot name the wrong wave.
		if (map !is null && rules.isMatchRunning() &&
			rules.get_bool("dusk_warning") && getPlayersCount() > 0)
		{
			const f32 daylight = map.getDayTime();
			if (daylight >= 0.70f && daylight < 0.80f &&
				rules.get_s32("last_dusk_warning_day") != dayNumber)
			{
				rules.set_s32("last_dusk_warning_day", dayNumber);
				string warning = "Dusk approaches. The undead are gathering!";
				const WaveKind wave = GetWaveKindForDay(dayNumber);
				if (wave == WAVE_MINI)
					warning = "Dusk approaches. A mini-boss wave is coming!";
				else if (wave == WAVE_BOSS)
					warning = "Dusk approaches. A boss wave is coming!";
				else if (wave == WAVE_CATACLYSM)
					warning = "Dusk approaches. A CATACLYSM is coming!";

				Server_GlobalPopup(rules, warning,
					SColor(255, 255, 190, 95), 5 * getTicksASecond());
			}
		}

		// === periodic maintenance: curse logic (throttled) ===
		if (getGameTime() % 150 == 0)
		{
			if (map !is null && rules.get_bool("zombify") &&
				dayNumber >= curse_day && num_undead_p < max_undead)
			{
				// Curse is advertised as affecting fallen survivors. Do not
				// randomly turn an actively defending player into an undead.
				CPlayer @[] fallen;
				for (uint i = 0; i < getPlayersCount(); ++i)
				{
					CPlayer @candidate = getPlayer(i);
					if (candidate is null || candidate.getTeamNum() != 0 ||
						candidate.getDeaths() == 0)
						continue;

					CBlob @body = candidate.getBlob();
					if (body is null || body.hasTag("dead"))
						fallen.push_back(candidate);
				}

				if (fallen.length > 0 && Zombify(fallen[XORRandom(fallen.length)]))
					server_CreateBlob("cursemessage");
			}
		}

		// === Day change bookkeeping to re-arm boss trigger on non-boss days ===
		{
			const int prevDay = rules.get_s32("last_boss_day");
			if (dayNumber != prevDay)
			{
				rules.set_s32("last_boss_day", dayNumber);

				// Re-arm outside boss days so %5 ticks can fire once
				if ((dayNumber % 5) != 0)
				{
					if (transition != 1)
					{
						transition = 1;
					}
				}
			}
		}

		// === spawning system ===
		if (getGameTime() % spawnRate == 0)
		{
			if (map !is null)
			{
				// gather portals and (later) ruins; fallback to edges
				Vec2f[] zombiePlaces;

				CBlob @[] portals;
				getBlobsByName("zombieportal", @portals);
				for (uint i = 0; i < portals.length; i++)
				{
					if (portals[i] !is null)
						zombiePlaces.push_back(portals[i].getPosition());
				}

				if (ruins_portal_active)
				{
					CBlob @[] ruins;
					getBlobsByName("zombieruins", @ruins);
					for (uint i = 0; i < ruins.length; i++)
					{
						if (ruins[i] !is null)
							zombiePlaces.push_back(ruins[i].getPosition());
					}
				}

				if (zombiePlaces.length <= 0)
				{
					// With no portals, the old code performed 16 terrain
					// raycasts on every spawn attempt. Cache the ground
					// positions for this map and reset them at Setup().
					if (!fallbackSpawnPlacesReady ||
						getGameTime() >= fallbackSpawnRefreshTick)
					{
						fallbackSpawnPlaces.clear();
						for (int zp = 8; zp < 16; ++zp)
						{
							Vec2f col;
							if (map.rayCastSolid(Vec2f(zp * 8, 0.0f),
								Vec2f(zp * 8, map.tilemapheight * 8), col))
							{
								col.y -= 16.0f;
								fallbackSpawnPlaces.push_back(col);
							}
							if (map.rayCastSolid(
								Vec2f((map.tilemapwidth - zp) * 8, 0.0f),
								Vec2f((map.tilemapwidth - zp) * 8, map.tilemapheight * 8), col))
							{
								col.y -= 16.0f;
								fallbackSpawnPlaces.push_back(col);
							}
						}
						// The map is destructible. Recheck periodically so
						// tunnels and rebuilt ground are reflected in spawns.
						fallbackSpawnPlacesReady = fallbackSpawnPlaces.length > 0;
						fallbackSpawnRefreshTick = getGameTime() + 30 * getTicksASecond();
					}
					for (uint i = 0; i < fallbackSpawnPlaces.length; ++i)
						zombiePlaces.push_back(fallbackSpawnPlaces[i]);
				}

				// If still empty somehow, bail this tick safely
				if (zombiePlaces.length == 0)
				{
					RulesCore::Update();
					CheckTeamWon();
					return;
				}

				Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];

				// read current caps/counters from rules (already refreshed)
				// Update live special-mob counters from the SAME scan used
				// for the total horde cap. Replicated HUD counts are refreshed
				// every 150 ticks and can overshoot small special caps.
				int _num_wr = 0;
				const int _max_wr = rules.get_s32("max_wraiths");
				int _num_gr = 0;
				const int _max_gr = rules.get_s32("max_gregs");
				int _num_im = 0;
				const int _max_im = rules.get_s32("max_imol");
				int _num_di = 0;
				const int _max_di = rules.get_s32("max_digger");
				int _num_bi = 0;
				const int _max_bi = rules.get_s32("max_bisons");
				int _num_ba = 0;
				const int _max_ba = rules.get_s32("max_banshees");
				int _num_ho = 0;
				const int _max_ho = rules.get_s32("max_horror");
				int _num_ga = 0;
				const int _max_ga = rules.get_s32("max_gasbags");

				// The replicated population is updated every 150 ticks, so
				// checking only that cached count can overshoot the hard cap.
				// Check the live zombie set immediately before creating one.
				bool canSpawnNow = (hardmode || isNight);
				if (canSpawnNow)
				{
					CBlob @[] currentZombies;
					getBlobsByTag("zombie", @currentZombies);
					int livingZombies = 0;
					for (uint i = 0; i < currentZombies.length; ++i)
					{
						CBlob @zombie = currentZombies[i];
						if (zombie is null || zombie.hasTag("dead"))
							continue;

						livingZombies++;
						if (zombie.hasTag("wraiths"))
							_num_wr++;
						if (zombie.hasTag("gregs"))
							_num_gr++;
						if (zombie.hasTag("bisons"))
							_num_bi++;

						const string name = zombie.getName();
						if (name == "immolator")
							_num_im++;
						else if (name == "digger")
							_num_di++;
						else if (name == "pbanshee")
							_num_ba++;
						else if (name == "horror")
							_num_ho++;
						else if (name == "gasbag")
							_num_ga++;
					}
					canSpawnNow = livingZombies < max_zombies;
				}

				if (canSpawnNow)
				{
					float rmin =
						difficulty * 0.1f; // difficulty directly biases the minimum roll
					const float r =
						rmin +
						XORRandom(Maths::Max(1, int((difficulty - rmin) * 10))) / 10.0f;

					if (r >= 47.0f && _num_di < _max_di)
						server_CreateBlob("digger", -1, sp);
					else if (r >= 40.0f && _num_wr < _max_wr)
						server_CreateBlob("writher", -1, sp);
					else if (r >= 35.5f && _num_ho < _max_ho)
						server_CreateBlob("horror", -1, sp);
					else if (r >= 25.0f && _num_ba < _max_ba)
						server_CreateBlob("pbanshee", -1, sp);
					else if (r >= 20.0f && _num_bi < _max_bi)
					{
						const u8 v = XORRandom(2);
						server_CreateBlob((v == 0 ? "zbison" : "zbison2"), -1, sp);
					}
					else if (r >= 17.0f && _num_wr < _max_wr)
					{
						const u8 v = XORRandom(2);
						server_CreateBlob((v == 0 ? "wraith" : "wraith2"), -1, sp);
					}
					else if (r >= 15.0f && _num_gr < _max_gr)
					{
						const u8 v = XORRandom(2);
						server_CreateBlob((v == 0 ? "greg" : "greg2"), -1, sp);
					}
					else if (r >= 12.5f && _num_im < _max_im)
						server_CreateBlob("immolator", -1, sp);
					else if (r >= 7.0f && _num_ga < _max_ga)
						server_CreateBlob("gasbag", -1, sp);
					else if (r >= 5.5f)
						server_CreateBlob("zombieknight", -1, sp);
					else if (r >= 2.5f)
					{
						const u8 v = XORRandom(3);
						server_CreateBlob(v == 0 ? "evilzombie" : (v == 1 ? "bloodzombie" : "plantzombie"), -1, sp);
					}
					else if (r >= 1.0f)
					{
						const u8 v = XORRandom(2);
						server_CreateBlob((v == 0 ? "zombie" : "zombie2"), -1, sp);
					}
					else if (r >= 0.5f)
					{
						const u8 v = XORRandom(2);
						server_CreateBlob((v == 0 ? "skeleton" : "skeleton2"), -1, sp);
					}
					else if (r >= 0.2f)
						server_CreateBlob("catto", -1, sp);
					else
					{
						server_CreateBlob("zchicken", -1, sp);
					}

				}

				// Boss waves are milestones, not ordinary spawns. They must still
				// happen when the regular zombie population has reached its cap.
				if (hardmode || isNight)
				{
					int newTransition =
						RunBossWave(dayNumber, difficulty, zombiePlaces, transition);
					if (newTransition != transition)
					{
						transition = newTransition;
						rules.set_s32("transition", transition);
					}
				}
			}
		}

		RulesCore::Update();
		CheckTeamWon();
	}

	// --- team & win checks (unchanged behavior) ---
	void AddTeam(CTeam @team)
	{
		CTFTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer @player, u8 team, string default_config = "")
	{
		team = player.getTeamNum();
		CTFPlayerInfo p(player.getUsername(), team, "builder");
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
		warn("sync");
	}

	void onPlayerDie(CPlayer @victim, CPlayer @killer, u8 customData)
	{
		RulesCore::onPlayerDie(victim, killer, customData);

		if (victim !is null)
		{
			Zombies_spawns.AddPlayerToSpawn(victim);
		}

		if (!rules.isMatchRunning())
			return;

		if (victim !is null && killer !is null &&
			killer.getTeamNum() != victim.getTeamNum())
		{
			addKill(killer.getTeamNum());
		}
	}

	bool Zombify(CPlayer @player)
	{
		if (player is null || player.getTeamNum() != 0 ||
			player.getDeaths() == 0)
			return false;

		CBlob @body = player.getBlob();
		if (body !is null && !body.hasTag("dead"))
			return false;

		PlayerInfo @pInfo = getInfoFromName(player.getUsername());
		if (pInfo is null)
			return false;

		ChangePlayerTeam(player, 1);
		Server_GlobalPopup(
			rules,
			"The Curse has started\n\nA fallen survivor joined the Undead Team.",
			SColor(255, 255, 0, 0),
			10 * getTicksASecond());
		return true;
	}

	void CheckTeamWon()
	{
		// Checking for destroyed pillars requires a world blob lookup.
		// Twice per second is responsive without repeating that lookup
		// on every simulation tick during a large horde.
		if (!rules.isMatchRunning() || getGameTime() % 15 != 0)
			return;

		const int gamestart = rules.get_s32("gamestart");
		const int day_cycle = Maths::Max(1, int(rules.daycycle_speed * 60));
		const int dayNumber =
			((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
		const int days_offset = rules.get_s32("days_offset");

		CBlob @[] bases;
		getBlobsByName(base_name(), @bases);

		// Game over if pillars are gone
		if (bases.length == 0)
		{
			// announce before changing state so the message has time to sync
			Server_GlobalPopup(rules,
							   "Gameover!\nThe Pillars Have Been destroyed\nOn day " +
								   (dayNumber + days_offset) + ".",
							   SColor(255, 255, 0, 0),
							   10 * getTicksASecond());

			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
			return;
		}

		// Optional finite survival mode: win after completing the configured
		// number of full days. An unset/non-positive limit remains endless.
		const int survivalDays = rules.get_s32("days_to_survive");
		if (survivalDays > 0 && dayNumber + days_offset > survivalDays)
		{
			Server_GlobalPopup(rules,
							   "Victory!\nThe Survivors held the Pillars for " +
								   survivalDays + " days.",
							   SColor(255, 140, 255, 140),
							   10 * getTicksASecond());

			rules.SetTeamWon(0);
			rules.SetCurrentState(GAME_OVER);
			return;
		}
	}

	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			CTFTeamInfo @team_info = cast<CTFTeamInfo @>(teams[team]);
			// (score bookkeeping if needed)
		}
	}
}

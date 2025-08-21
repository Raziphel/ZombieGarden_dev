// Zombies_Core.as
#include "Core/Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"
#include "Zombies_Boss.as"
#include "Zombies_Utils.as"
#include "GlobalPopup.as"

class ZombiesCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;

	ZombiesSpawns@ Zombies_spawns;

	ZombiesCore() {}
	ZombiesCore(CRules@ _rules, RespawnSystem@ _respawns) { super(_rules, _respawns); }

	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		@Zombies_spawns = cast<ZombiesSpawns@>(_respawns);

		server_CreateBlob("music", 0, Vec2f(0, 0));

		const int gamestart = getGameTime();
		rules.set_s32("gamestart", gamestart);
		rules.SetCurrentState(WARMUP);

        // Arm the boss transition for the first cycle
        rules.set_s32("transition", 1);
        rules.set_s32("last_boss_day", 0);
        rules.set_s32("boss_spawned_day", 0);

        // reset kill counter for new record tracking
        rules.set_u32("undead_kills", 0);
        rules.Sync("undead_kills", true);

        // seed counters once (single source of truth)
        RefreshMobCountsToRules();

        // cache starting world state so difficulty begins at zero
        float baseWorldMod = -0.3f;
        baseWorldMod += rules.get_s32("num_ruinstorch") * 0.3f;
        baseWorldMod -= rules.get_s32("num_alters") * 0.5f;
        baseWorldMod += rules.get_s32("num_survivors") * 0.05f;
        baseWorldMod -= rules.get_s32("num_undead") * 0.2f;
        baseWorldMod += rules.get_s32("days_offset") * 0.1f;
        rules.set_f32("base_world_mod", baseWorldMod);
    }

	void Update()
	{
		if (rules.isGameOver()) return;

		const int day_cycle  = getRules().daycycle_speed * 60;
		int transition       = rules.get_s32("transition");
		const int gamestart  = rules.get_s32("gamestart");

		// easy reads (all counts come from rules now)
		const int max_zombies       = rules.get_s32("max_zombies");
		const int num_zombies       = rules.get_s32("num_zombies");
		const int max_pzombies      = rules.get_s32("max_pzombies");
		const int num_pzombies      = rules.get_s32("num_pzombies");
		const int max_migrantbots   = rules.get_s32("max_migrantbots");
		const int num_migrantbots   = rules.get_s32("num_migrantbots");
		const int max_wraiths       = rules.get_s32("max_wraiths");
		const int num_wraiths       = rules.get_s32("num_wraiths");
        const int max_gregs         = rules.get_s32("max_gregs");
        const int num_gregs         = rules.get_s32("num_gregs");
        const int max_imol          = rules.get_s32("max_imol");
        const int num_immol         = rules.get_s32("num_immol");
        const int num_alters        = rules.get_s32("num_alters");

		// recompute simple derived values
        const int hardmode_day      = rules.get_s32("hardmode_day");
        const int curse_day         = rules.get_s32("curse_day");
        const int days_offset       = rules.get_s32("days_offset");
        const bool ruins_portal_active = rules.get_bool("ruins_portal_active");
        const int dayNumber         = days_offset + ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;

        const int timeElapsed  = getGameTime() - gamestart;
        const int ignore_light = (hardmode_day - ((days_offset / 14) * 10));

		// quick player team pass (used for max_undead)
		int num_survivors_p = 0;
		int num_undead_p    = 0;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ pl = getPlayer(i);
			if (pl is null) continue;
			if (pl.getTeamNum() == 0) num_survivors_p++;
			else if (pl.getTeamNum() == 1) num_undead_p++;
		}
		const int max_undead = (num_survivors_p / 3);
		rules.set_s32("max_undead", max_undead);

        // expose the current day to the HUD for snappier rendering
        rules.set_s32("hud_dayNumber", dayNumber);

		// transition from warmup to game
		if (rules.isWarmup() && timeElapsed > getTicksASecond() * 30)
		{
			rules.SetCurrentState(GAME);
		}

        // ------------------------------
        // Difficulty calculation + wipe bonus (once per day)
        // ------------------------------
        const int pillars    = rules.get_s32("num_ruinstorch");
        const int altars     = rules.get_s32("num_alters");
        const int survivors  = rules.get_s32("num_survivors");
        const int undead     = rules.get_s32("num_undead");

        float baseDifficulty = dayNumber * 0.16f;

        // adjustments based on world state
        float modified = 0.2f;
        modified += pillars     * 0.3f;                   // more pillars ease the round
        modified -= altars      * 0.5f;                   // intact altars reduce difficulty
        modified += survivors   * 0.05f;                  // more survivors hardens the waves
        modified -= undead      * 0.2f;                   // undead players make it tougher
        modified += days_offset * 0.1f;                 // manual day skips ups difficulty
        if (rules.exists("base_world_mod"))
        {
            modified -= rules.get_f32("base_world_mod");   // normalize to starting state
        }

        // persistent bonus from wipes (defaults to 0 if missing)
        float wipeBonus = rules.exists("difficulty_bonus") ? rules.get_f32("difficulty_bonus") : 0.0f;

        // --- Guard: don't let first-day / warmup wipes count ---
        const bool isLive = rules.isMatchRunning();
        const bool pastGrace = (timeElapsed > (getTicksASecond() * 45)); // small post-GAME grace
        const bool allowWipeCheck = isLive && pastGrace && (dayNumber > 1);

        // Wipe bonus: if all survivors are dead, add +1 once per day
        if (allowWipeCheck)
        {
            const int live_survivors = rules.get_s32("num_survivors");
            const int num_hands      = rules.get_s32("num_ruinstorch");
            const int last_wipe_day  = rules.exists("last_wipe_day") ? rules.get_s32("last_wipe_day") : -1;

            // Only once per dayNumber, only when truly wiped
        	if ((live_survivors - num_hands) <= 0 && last_wipe_day != dayNumber)
        	{
    	        wipeBonus += 0.5f;
	            rules.set_f32("difficulty_bonus", wipeBonus);
            	rules.set_s32("last_wipe_day", dayNumber);

        	    const float previewDifficulty = Maths::Min(20.0f, baseDifficulty + modified + wipeBonus);

    	        Server_GlobalPopup(rules,
	                "All survivors have fallen!\n\n+0.5 Difficulty (now " + previewDifficulty + ")",
            	    SColor(255, 255, 0, 0), 6 * getTicksASecond());
        	}
        }

        // final difficulty (apply cap after any bonus change)
        float finalDifficulty = baseDifficulty + modified + wipeBonus;
        if (finalDifficulty < 0.0f) finalDifficulty = 0.0f;
        if (finalDifficulty > 20.0f) finalDifficulty = 20.0f; // expanded cap
        rules.set_f32("difficulty", finalDifficulty);

        int spawnRate = 90 - int(finalDifficulty * 3);
        if (spawnRate < 15) spawnRate = 15;

		// === periodic maintenance: refresh *all* counts into rules ===
		if (getGameTime() % 150 == 0)
		{
            RefreshMobCountsToRules(); // <— single source of truth

			// night transition + curse logic
			CMap@ map = getMap();
			if (map !is null)
			{
				// day/night tag + re-arm transition on first night tick
				if (map.getDayTime() > 0.65f || map.getDayTime() < 0.15f) //+ This is the time zombies will spawn between
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
					rules.Untag("night");
				}

				// Curse logic
				if (dayNumber >= curse_day && rules.get_s32("num_undead") < max_undead)
				{
					const u8 pCount = getPlayersCount();
					if (pCount > 0)
					{
						CPlayer@ player = getPlayer(XORRandom(pCount));
						if (player !is null && player.getTeamNum() == 0)
						{
							Zombify(player);
							server_CreateBlob("cursemessage");
						}
					}
				}
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
						rules.set_s32("transition", transition);
					}
				}
			}
		}

		// === spawning system ===
		if (getGameTime() % spawnRate == 0)
		{
			CMap@ map = getMap();
			if (map !is null)
			{
            	// gather portals and (later) ruins; fallback to edges
                Vec2f[] zombiePlaces;

                CBlob@[] portals;
                getBlobsByName("zombieportal", @portals);
                for (uint i = 0; i < portals.length; i++)
                {
                    zombiePlaces.push_back(portals[i].getPosition());
                }

                if (ruins_portal_active)
                {
                    CBlob@[] ruins;
                    getBlobsByName("zombieruins", @ruins);
                    for (uint i = 0; i < ruins.length; i++)
                    {
                        zombiePlaces.push_back(ruins[i].getPosition());
                    }
                }

                if (zombiePlaces.length <= 0)
                {
                    // build simple edge fallback list
                    for (int zp = 8; zp < 16; zp++)
                    {
                        Vec2f col;
                        map.rayCastSolid(Vec2f(zp * 8, 0.0f), Vec2f(zp * 8, map.tilemapheight * 8), col);
                        col.y -= 16.0f; zombiePlaces.push_back(col);
                        map.rayCastSolid(Vec2f((map.tilemapwidth - zp) * 8, 0.0f), Vec2f((map.tilemapwidth - zp) * 8, map.tilemapheight * 8), col);
                        col.y -= 16.0f; zombiePlaces.push_back(col);
                    }
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
				const int _num_z  = rules.get_s32("num_zombies");
				const int _num_wr = rules.get_s32("num_wraiths");
				const int _max_wr = rules.get_s32("max_wraiths");
				const int _num_gr = rules.get_s32("num_gregs");
				const int _max_gr = rules.get_s32("max_gregs");
				const int _num_im = rules.get_s32("num_immol");
				const int _max_im = rules.get_s32("max_imol");
				const int _num_di = rules.get_s32("num_digger");
				const int _max_di = rules.get_s32("max_digger");

				const bool canSpawnNow =
					   (dayNumber >= ignore_light && _num_z < max_zombies)
					|| (rules.hasTag("night")     && _num_z < max_zombies);

				if (canSpawnNow)
				{
                    float rmin = finalDifficulty * 0.1f; // difficulty directly biases the minimum roll
                    const float r = rmin + XORRandom(Maths::Max(1, int((finalDifficulty - rmin) * 10))) / 10.0f;

					if      (r >=  19.0f && _num_di < _max_di)                               server_CreateBlob("digger", -1, sp);
					else if (r >=  16.0f && (_num_gr + _num_wr) < (_max_gr + _max_wr))       server_CreateBlob("writher", -1, sp);
					else if (r >=  13.0f)                                                    server_CreateBlob("pbanshee", -1, sp);
					else if (r >=  11.0f)                                                    { const u8 v = XORRandom(2); server_CreateBlob((v == 0 ? "zbison" : "zbison2"), -1, sp); }
					else if (r >=  9.5f)                                                     server_CreateBlob("horror", -1, sp);
					else if (r >=  9.0f && _num_wr < _max_wr)                                { const u8 v = XORRandom(2); server_CreateBlob((v == 0 ? "wraith" : "wraith2"), -1, sp); }
					else if (r >=  8.0f && _num_gr < _max_gr)                                { const u8 v = XORRandom(2); server_CreateBlob((v == 0 ? "greg" : "greg2"), -1, sp); }
					else if (r >=  6.5f && _num_im < _max_im)                                server_CreateBlob("immolator", -1, sp);
					else if (r >=  5.0f)                                                     server_CreateBlob("gasbag", -1, sp);
					else if (r >=  3.5f)                                                     server_CreateBlob("zombieknight", -1, sp);
                    else if (r >=  2.0f)                                                     { const u8 v = XORRandom(3); server_CreateBlob(v == 0 ? "evilzombie" : (v == 1 ? "bloodzombie" : "plantzombie"), -1, sp); }
                    else if (r >=  1.0f)                                                     { const u8 v = XORRandom(2); server_CreateBlob((v == 0 ? "zombie" : "zombie2"), -1, sp); }
                    else if (r >=  0.5f)                                                     { const u8 v = XORRandom(2); server_CreateBlob((v == 0 ? "skeleton" : "skeleton2"), -1, sp); }
                    else if (r >=  0.2f)                                                     server_CreateBlob("catto", -1, sp);
                    else                                                                     { server_CreateBlob("zchicken", -1, sp); }

					// === boss waves ===
                    int newTransition = RunBossWave(dayNumber, finalDifficulty, zombiePlaces, transition);
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
	void AddTeam(CTeam@ team)
	{
		CTFTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team, string default_config = "")
	{
		team = player.getTeamNum();
		CTFPlayerInfo p(player.getUsername(), team, "builder");
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
		warn("sync");
	}

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		RulesCore::onPlayerDie(victim, killer, customData);

		if (victim !is null)
		{
			Zombies_spawns.AddPlayerToSpawn(victim);
		}

		if (!rules.isMatchRunning()) return;

		if (victim !is null && killer !is null && killer.getTeamNum() != victim.getTeamNum())
		{
			addKill(killer.getTeamNum());
		}
	}

	void Zombify(CPlayer@ player)
	{
		PlayerInfo@ pInfo = getInfoFromName(player.getUsername());
		print(":::ZOMBIFYING: " + pInfo.username);
		ChangePlayerTeam(player, 1);
		Server_GlobalPopup(rules,
			"The Curse has started\n\nA player has now joined the Undead Team.",
			SColor(255, 255, 0, 0), 10 * getTicksASecond());
	}

	void CheckTeamWon()
	{
		if (!rules.isMatchRunning()) return;

		const int gamestart   = rules.get_s32("gamestart");
		const int day_cycle   = getRules().daycycle_speed * 60;
		const int dayNumber   = ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
		const int days_offset = rules.get_s32("days_offset");

		CBlob@[] bases; getBlobsByName(base_name(), @bases);

		// Game over if pillars are gone
		if (bases.length == 0)
		{
			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
			Server_GlobalPopup(rules,
				"Gameover!\nThe Pillars Have Been destroyed\nOn day " + (dayNumber + days_offset) + ".",
				SColor(255, 255, 0, 0), 10 * getTicksASecond());
			return;
		}
	}

	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			CTFTeamInfo@ team_info = cast<CTFTeamInfo@>(teams[team]);
			// (score bookkeeping if needed)
		}
	}
}

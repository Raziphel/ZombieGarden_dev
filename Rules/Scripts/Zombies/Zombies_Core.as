// Zombies_Core.as
#include "Core/Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"
#include "Zombies_Boss.as"
#include "Zombies_Utils.as"

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

		// seed counters once
		RefreshMobCountsToRules();
	}

	void Update()
	{
		if (rules.isGameOver()) return;

		const int day_cycle  = getRules().daycycle_speed * 60;
		int       transition = rules.get_s32("transition");
		const int gamestart  = rules.get_s32("gamestart");

		// easy reads (all counts come from rules now)
		const int max_zombies      = rules.get_s32("max_zombies");
		const int num_zombies      = rules.get_s32("num_zombies");
		const int max_pzombies     = rules.get_s32("max_pzombies");
		const int num_pzombies     = rules.get_s32("num_pzombies");
		const int max_migrantbots  = rules.get_s32("max_migrantbots");
		const int num_migrantbots  = rules.get_s32("num_migrantbots");
		const int max_wraiths      = rules.get_s32("max_wraiths");
		const int num_wraiths      = rules.get_s32("num_wraiths");
		const int max_gregs        = rules.get_s32("max_gregs");
		const int num_gregs        = rules.get_s32("num_gregs");
		const int max_imol         = rules.get_s32("max_imol");
		const int num_immol        = rules.get_s32("num_immol");
		const int num_zombiePortals= rules.get_s32("num_zombiePortals");

		// recompute simple derived values
		const int hardmode_day = rules.get_s32("hardmode_day");
		const int curse_day    = rules.get_s32("curse_day");
		const int days_offset  = rules.get_s32("days_offset");
		const int dayNumber    = days_offset + ((getGameTime()-gamestart)/getTicksASecond()/day_cycle) + 1;

		const int timeElapsed = getGameTime() - gamestart;
		float difficulty = dayNumber*0.1 + (days_offset/7);
		float zombdiff   = dayNumber*1.25 + (days_offset/7);
		if (zombdiff > 100) zombdiff = 100;

		const int ignore_light = (hardmode_day - (days_offset));

		// quick player team pass (used for max_undead & HUD)
		int num_survivors_p = 0;
		int num_undead_p    = 0;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			if (getPlayer(i).getTeamNum() == 0) num_survivors_p++;
			else if (getPlayer(i).getTeamNum() == 1) num_undead_p++;
		}
		const int max_undead = (num_survivors_p/3);
		rules.set_s32("max_undead", max_undead);

		// old center message: clear it so nothing shows in the middle
		rules.SetGlobalMessage("");

		// also stash a couple values for the HUD renderer
		rules.set_s32("hud_dayNumber", dayNumber);
		rules.set_s32("hud_ignore_light", ignore_light);

		if (rules.isWarmup() && timeElapsed > getTicksASecond()*30)
			rules.SetCurrentState(GAME);

		rules.set_f32("difficulty", difficulty);
		int spawnRate = 100 - zombdiff;
		if (spawnRate < 20) spawnRate = 20;

		// === periodic maintenance: refresh *all* counts into rules ===
		if (getGameTime() % 150 == 0)
		{
			RefreshMobCountsToRules(); // <— single source of truth

			// night transition + curse logic (unchanged)
			CMap@ map = getMap();
			if (map !is null)
			{
				if (map.getDayTime() > 0.8 || map.getDayTime() < 0.2)
				{
					if (!rules.hasTag("night")) { rules.Tag("night"); transition = 1; }
				}
				else { rules.Untag("night"); }

				if (dayNumber >= curse_day && rules.get_s32("num_undead") < max_undead &&
				    (map.getDayTime() > 0.7 || map.getDayTime() < 0.2))
				{
					const u8 pCount = getPlayersCount();
					CPlayer@ player = getPlayer(XORRandom(pCount));
					if (player.getTeamNum() == 0)
					{
						Zombify(player);
						server_CreateBlob("cursemessage");
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
				// spawn markers / fallback edges
				Vec2f[] zombiePlaces;
				getMap().getMarkers("zombie spawn", zombiePlaces);
				if (zombiePlaces.length <= 0)
				{
					for (int zp = 8; zp < 16; zp++)
					{
						Vec2f col;
						getMap().rayCastSolid(Vec2f(zp*8, 0.0f), Vec2f(zp*8, map.tilemapheight*8), col);
						col.y -= 16.0; zombiePlaces.push_back(col);
						getMap().rayCastSolid(Vec2f((map.tilemapwidth-zp)*8, 0.0f), Vec2f((map.tilemapwidth-zp)*8, map.tilemapheight*8), col);
						col.y -= 16.0; zombiePlaces.push_back(col);
					}
				}
				Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];

				// read current caps/counters from rules (already refreshed)
				const int _num_z  = rules.get_s32("num_zombies");
				const int _num_pz = rules.get_s32("num_pzombies");
				const int _num_wr = rules.get_s32("num_wraiths");
				const int _max_wr = rules.get_s32("max_wraiths");
				const int _num_gr = rules.get_s32("num_gregs");
				const int _max_gr = rules.get_s32("max_gregs");
				const int _num_im = rules.get_s32("num_immol");
				const int _max_im = rules.get_s32("max_imol");

				const bool canSpawnNow =
					( dayNumber > ignore_light && _num_z < max_zombies )
				 || ( rules.hasTag("night")   && _num_z < max_zombies );

				if (zombdiff >= 120)
				{
					zombdiff = 120;
				}

				if (canSpawnNow)
				{
					const int r = XORRandom(zombdiff + 5);

					if      (r >= 94 && (_num_gr + _num_wr) < (_max_gr + _max_wr)) server_CreateBlob("writher", -1, sp);
					else if (r >= 82)                                              server_CreateBlob("pbanshee", -1, sp);
					else if (r >= 79)                                              server_CreateBlob("zbison", -1, sp);
					else if (r >= 76)                                              server_CreateBlob("horror", -1, sp);
					else if (r >= 66 && _num_wr < _max_wr)                         server_CreateBlob("wraith", -1, sp);
					else if (r >= 60 && _num_gr < _max_gr)                         server_CreateBlob("greg", -1, sp);
					else if (r >= 53 && _num_im < _max_im)                         server_CreateBlob("immolator", -1, sp);
					else if (r >= 45)                                              server_CreateBlob("gasbag", -1, sp);
					else if (r >= 30)                                              server_CreateBlob("zombieknight", -1, sp);
					else if (r >= 26)                                              server_CreateBlob("evilzombie", -1, sp);
					else if (r >= 22)                                              server_CreateBlob("bloodzombie", -1, sp);
					else if (r >= 16)                                              server_CreateBlob("plantzombie", -1, sp);
					else if (r >= 9)                                               server_CreateBlob("zombie", -1, sp);
					else if (r >= 5)                                               server_CreateBlob("skeleton", -1, sp);
					else if (r >= 2)                                               server_CreateBlob("catto", -1, sp);
					else                                                           server_CreateBlob("zchicken", -1, sp);

					// boss waves (unchanged; wrapped helper returns updated transition)
					int newTransition = RunBossWave(dayNumber, zombdiff, zombiePlaces, transition);
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
		if (!rules.isMatchRunning()) return;
		if (victim !is null && killer !is null && killer.getTeamNum() != victim.getTeamNum())
			addKill(killer.getTeamNum());
	}
	void Zombify(CPlayer@ player)
	{
		PlayerInfo@ pInfo = getInfoFromName(player.getUsername());
		print(":::ZOMBIFYING: " + pInfo.username);
		ChangePlayerTeam(player, 1);
	}
	void CheckTeamWon()
	{
		if (!rules.isMatchRunning()) return;
		const int gamestart = rules.get_s32("gamestart");

		const int day_cycle   = getRules().daycycle_speed*60;
		const int dayNumber   = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;
		const int days_offset = rules.get_s32("days_offset");

		CBlob@[] bases; getBlobsByName(base_name(), @bases);
		const int num_survivors = rules.get_s32("num_survivors");

		if (bases.length == 0)
		{
			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("Gameover!\nThe Pillars Have Been destroyed\nOn day " + (dayNumber + days_offset) + ".");
		}
	}
	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			CTFTeamInfo@ team_info = cast<CTFTeamInfo@>(teams[team]);
		}
	}
}

// =========================
//  HUD: Top-right status
// =========================

void onRender(CRules@ rules)
{
	if (g_videorecording) return;
	CPlayer@ lp = getLocalPlayer();
	if (lp is null) return;
	if (!rules.isMatchRunning() && !rules.isWarmup()) return;

	DrawZombiesHUDTopRight(rules);
}

void DrawZombiesHUDTopRight(CRules@ rules)
{
	if (g_videorecording) return;

	GUI::SetFont("menu"); // try "hud" if you want smaller text

	// layout
	const float margin   = 24.0f;   // distance from screen edges
	const float padX     = 10.0f;   // inner padding
	const float padY     = 8.0f;
	const float lineH    = 18.0f;
	const float titleH   = 20.0f;   // approximate title height without measuring
	const float titleGap = 6.0f;

	// compute basics
	const int gamestart   = rules.get_s32("gamestart");
	const int day_cycle   = getRules().daycycle_speed * 60;
	const int days_offset = rules.get_s32("days_offset");
	const int hardmode_day= rules.get_s32("hardmode_day");
	const int curse_day   = rules.get_s32("curse_day");
	const int dayNumber   = days_offset + ((getGameTime()-gamestart)/getTicksASecond()/day_cycle) + 1;
	const int ignore_light= (hardmode_day - (days_offset));

	// counters
	const int num_zombies      = rules.get_s32("num_zombies");
	const int max_zombies      = rules.get_s32("max_zombies");
	const int num_pzombies     = rules.get_s32("num_pzombies");
	const int num_hands        = rules.get_s32("num_ruinstorch");
	const int num_zombiePortals= rules.get_s32("num_zombiePortals");
	const int num_survivors_p  = CountTeamPlayers(0);
	const int num_undead       = rules.get_s32("num_undead");
	const int difficulty_i     = int(rules.get_f32("difficulty") + 0.5f);

	// content
	const string title = "ROUND STATUS";

	array<string> lines;
	lines.insertLast("Day: " + dayNumber);
	lines.insertLast("Pillars: " + num_hands);
	lines.insertLast("Survivors: " + num_survivors_p);
	lines.insertLast("Undead: " + num_undead);
	lines.insertLast("Difficulty: " + difficulty_i);
	lines.insertLast("Zombies: " + (num_zombies + num_pzombies) + "/" + max_zombies);
	lines.insertLast("Hard Starts: " + (hardmode_day-days_offset));
	lines.insertLast("Curse Starts: " + curse_day);
	lines.insertLast("Altars Remaining: " + num_zombiePortals);

	// fixed width panel (tweak to taste)
	const float boxW = 260.0f;
	const float boxH = padY*2.0f + titleH + titleGap + (lines.length() * lineH);

	// top-right anchored rect
	Vec2f screen = getDriver().getScreenDimensions();
	Vec2f br(screen.x - margin, margin + boxH);
	Vec2f tl(br.x - boxW, br.y - boxH);

	// background + thin border
	GUI::DrawRectangle(tl, br, SColor(140, 0, 0, 0));
	GUI::DrawRectangle(tl, Vec2f(br.x, tl.y + 1), SColor(80, 255, 255, 255));
	GUI::DrawRectangle(Vec2f(tl.x, br.y - 1), br, SColor(80, 255, 255, 255));
	GUI::DrawRectangle(tl, Vec2f(tl.x + 1, br.y), SColor(80, 255, 255, 255));
	GUI::DrawRectangle(Vec2f(br.x - 1, tl.y), br, SColor(80, 255, 255, 255));

	// draw (left-aligned inside panel)
	Vec2f cursor = Vec2f(tl.x + padX, tl.y + padY);

	GUI::DrawText(title, cursor, SColor(255, 255, 220, 90));
	cursor.y += titleH + titleGap;

	for (uint i = 0; i < lines.length(); i++)
	{
		SColor col = SColor(255, 230, 230, 230);

		if (lines[i].findFirst("Zombies: ") == 0)       
			col = SColor(255, 255, 165, 0);        // Orange
		else if (lines[i].findFirst("Survivors: ") == 0)
			col = SColor(255, 0, 120, 255);        // Blue
		else if (lines[i].findFirst("Undead: ") == 0)   
			col = SColor(255, 255, 0, 0);          // Red
		else if (lines[i].findFirst("Difficulty: ") == 0) 
			col = SColor(255, 255, 255, 0);        // Yellow
		else if (lines[i].findFirst("Pillars: ") == 0)    
			col = SColor(255, 100, 200, 255);      // Light Blue

		GUI::DrawText(lines[i], cursor, col);
		cursor.y += lineH;
	}
}


// small helper for live player count by team
int CountTeamPlayers(const int teamNum)
{
	int c = 0;
	for (int i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p !is null && p.getTeamNum() == teamNum) c++;
	}
	return c;
}

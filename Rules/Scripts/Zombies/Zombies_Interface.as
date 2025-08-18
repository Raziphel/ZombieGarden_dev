#include "Core/Structs.as"
#include "GlobalPopup.as"

// -------------------------------------
//  Interface / HUD rendering
//  - Draws global popup
//  - Draws Zombies HUD (top-right)
//  - Draws revival timer when dead
// -------------------------------------

void onInit(CRules@ this)
{
	// nothing needed here (kept for symmetry)
}

void onRender(CRules@ this)
{
	if (g_videorecording) return;

	// Always show popups
	DrawGlobalPopup(this);

	CPlayer@ lp = getLocalPlayer();
	if (lp is null) return;

	// HUD can still be gated by state if you want
	if (!this.isMatchRunning() && !this.isWarmup())
	{
		return; // popup already shown above
	}

	DrawZombiesHUDTopRight(this);
	DrawRevivalTimer(this, lp);
}


// ------------------------------
// Revival timer centered on top
// ------------------------------
void DrawRevivalTimer(CRules@ this, CPlayer@ p)
{
	if (p is null) return;
	if (p.isMyPlayer() && p.getBlob() is null)
	{
		const string propname = "Zombies spawn time " + p.getUsername();
		if (this.exists(propname))
		{
			u8 spawn = this.get_u8(propname);
			if (spawn != 255)
			{
				GUI::SetFont("menu");
				Vec2f pos(getScreenWidth()/2 - 70, getScreenHeight()/3 + Maths::Sin(getGameTime() / 3.0f) * 5.0f);
				GUI::DrawText("Revival in: " + spawn, pos, SColor(255, 255, 255, 55));
			}
		}
	}
}

// ------------------------------
// HUD: Top-right status panel
// ------------------------------
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
	const int num_zombies       = rules.get_s32("num_zombies");
	const int max_zombies       = rules.get_s32("max_zombies");
	const int num_pzombies      = rules.get_s32("num_pzombies");
	const int num_hands         = rules.get_s32("num_ruinstorch");
	const int num_zombiePortals = rules.get_s32("num_zombiePortals");
	const int num_survivors_p   = CountTeamPlayers(0);
	const int num_undead        = rules.get_s32("num_undead");
	const int difficulty      = rules.get_f32("difficulty");
	const int difficulty_bonus      = rules.get_f32("difficulty_bonus");

	// content
	const string title = "ROUND STATUS";

	array<string> lines;
	lines.insertLast("Day: " + dayNumber);
	lines.insertLast("Pillars: " + num_hands);
	lines.insertLast("Survivors: " + num_survivors_p);
	lines.insertLast("Undead: " + num_undead);
	lines.insertLast("Difficulty: " + (difficulty+difficulty_bonus));
	lines.insertLast("Zombies: " + (num_zombies + num_pzombies) + "/" + max_zombies);
	lines.insertLast("Hard Starts: " + (hardmode_day - ((days_offset/14)*10)));
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

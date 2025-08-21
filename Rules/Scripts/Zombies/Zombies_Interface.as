#include "Core/Structs.as"
#include "GlobalPopup.as"

// -------------------------------------
//  Interface / HUD rendering
//  - Draws global popup
//  - Draws record / round / mode panels (stacked top-right)
//  - Draws revival timer when dead (top-center)
// -------------------------------------

// ---------- Shared palette ----------
const SColor COL_TEXT      = SColor(255, 230, 230, 230);
const SColor COL_TITLE     = SColor(255, 255, 230, 120);
const SColor COL_BORDER    = SColor(80,  255, 255, 255);
const SColor COL_BG        = SColor(140, 0,   0,   0);   // translucent black

// Accents (used sparingly)
const SColor COL_GOOD      = SColor(255, 160, 255, 160); // soft green
const SColor COL_WARN      = SColor(255, 255, 165, 0);   // amber
const SColor COL_BAD       = SColor(255, 255, 80,  80);  // soft red
const SColor COL_INFO      = SColor(255, 120, 180, 255); // blue-ish

// ---------- Helpers ----------
int GetCurrentDay(CRules@ rules)
{
	// Prefer HUD-provided day if present (snappier)
    if (rules.exists("hud_dayNumber"))
    {
	// hud_dayNumber already includes any day offset; avoid double counting
	const int d = rules.get_s32("hud_dayNumber");
	return Maths::Max(1, d);
    }

	// Fallback: compute from time
	const int gamestart = rules.get_s32("gamestart");
	const int day_cycle = getRules().daycycle_speed * 60;
	const int d = ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
	return Maths::Max(1, d + (rules.exists("days_offset") ? rules.get_s32("days_offset") : 0));
}

// Consistent panel with soft border
void DrawPanel(Vec2f tl, Vec2f br)
{
	GUI::DrawRectangle(tl, br, COL_BG);
	GUI::DrawRectangle(tl, Vec2f(br.x, tl.y + 1), COL_BORDER);
	GUI::DrawRectangle(Vec2f(tl.x, br.y - 1), br, COL_BORDER);
	GUI::DrawRectangle(tl, Vec2f(tl.x + 1, br.y), COL_BORDER);
	GUI::DrawRectangle(Vec2f(br.x - 1, tl.y), br, COL_BORDER);
}

// Helper to draw bold, centered titles
void DrawTextCenteredBold(const string &in text, Vec2f pos, SColor color)
{
	GUI::DrawTextCentered(text, pos + Vec2f(-1, 0), color);
	GUI::DrawTextCentered(text, pos + Vec2f(1, 0), color);
	GUI::DrawTextCentered(text, pos + Vec2f(0, -1), color);
	GUI::DrawTextCentered(text, pos + Vec2f(0, 1), color);
	GUI::DrawTextCentered(text, pos, color);
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

// -------------------------------------
// Lifecycle
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

	GUI::SetFont("menu");

	// Stack the three panels top-right, respecting each other's height
	float offset = DrawRecordStatus(this);
	offset = DrawZombiesHUDTopRight(this, offset);
	offset = DrawModeStatus(this, offset);

	// Dead players: show top-center revival timer
	DrawRevivalTimer(this, lp);
}

// ------------------------------
// Revival timer centered on top
// ------------------------------
// Safely read "Zombies spawn time <username>".
// Returns: (true, seconds>=0) when present & valid; otherwise (false, 0).
//
// The property is consistently stored as u16. Previous code attempted to read
// both u16 and u8 which triggered noisy "Type mismatch" warnings from the
// engine.  Reading it only as u16 avoids the log spam while keeping existing
// behaviour.
bool SafeGetSpawnSeconds(CRules@ rules, const string &in propname, u16 &out seconds)
{
	seconds = 0;
	if (!rules.exists(propname)) return false;

	u16 candidate = rules.get_u16(propname);

	// Filter sentinels/garbage commonly used by scripts
	// 255 is a common "not set" sentinel when stored as u8.
	if (candidate == 255 || candidate == 65535) return false;

	// Guard against nonsense (negative via wrap or way too large)
	if (candidate > 3600) // 1h+ is unrealistic for revival seconds
	        return false;

	seconds = candidate;
	return true;
}


void DrawRevivalTimer(CRules@ rules, CPlayer@ p)
{
	if (p is null) return;

	// Only when I'm dead (no blob) and in an active round/warmup UI context
	if (!p.isMyPlayer()) return;
	CBlob@ myBlob = p.getBlob();
	if (myBlob !is null) return;

	const string propname = "Zombies spawn time " + p.getUsername();

	u16 spawnSec = 0;
	if (!SafeGetSpawnSeconds(rules, propname, spawnSec)) return;

	// Hide if we're effectively done or bogus
	if (spawnSec == 0) return;

	// Nicely centered, with a subtle float
	GUI::SetFont("menu");
	const f32 wobble = Maths::Sin(getGameTime() / 3.0f) * 5.0f;

	// Center of screen, slightly above mid‑top so it doesn’t clash with your stacked panels
	const Vec2f screen = getDriver().getScreenDimensions();
	const Vec2f center = Vec2f(screen.x * 0.5f, screen.y * (1.0f / 3.0f) + wobble);

	// Use your bold centered helper for consistent look; keep colors subtle so it doesn’t scream
	const string msg = "Revival in: " + spawnSec + "s";
	DrawTextCenteredBold(msg, center, SColor(255, 255, 240, 180));
}


// ------------------------------
// HUD: Record status box (top-right)
// ------------------------------
float DrawRecordStatus(CRules@ rules)
{
	if (g_videorecording) return 0.0f;

	const float margin=24, padX=10, padY=8, lineH=18, titleH=20, titleGap=6;
	const string title = "RECORD STATUS";

	const int  days          = GetCurrentDay(rules);
	const u16  mapRecord     = rules.get_u16("map_record");
	const u16  globalRecord  = rules.get_u16("global_record");
	const u32  undeadKills   = rules.get_u32("undead_kills");
	const u32  mapKillRecord = rules.get_u32("map_kill_record");
	const u32  globalKillRec = rules.get_u32("global_kill_record");
	const bool cheated       = rules.get_bool("dayCheated");

	array<string> lines;
	array<SColor> cols;

	// Neutral by default; highlight only when meaningful
	lines.insertLast("Days Survived: " + days);               cols.push_back(COL_TEXT);
	lines.insertLast("Map Record: " + mapRecord);             cols.push_back(days > mapRecord ? COL_GOOD : COL_TEXT);
	lines.insertLast("Global Record: " + globalRecord);       cols.push_back(days > globalRecord ? COL_GOOD : COL_TEXT);
	lines.insertLast("Undead Killed: " + undeadKills);        cols.push_back(COL_TEXT);
	lines.insertLast("Map Kill Record: " + mapKillRecord);    cols.push_back(undeadKills > mapKillRecord ? COL_GOOD : COL_TEXT);
	lines.insertLast("Global Kill Record: " + globalKillRec); cols.push_back(undeadKills > globalKillRec ? COL_GOOD : COL_TEXT);

	if (cheated)
	{
		lines.insertLast("Record Disqualified (Cheated)");
		cols.push_back(COL_BAD);
	}

	const float boxW = 260.0f;
	const float boxH = padY*2 + titleH + titleGap + (lines.length() * lineH);

	Vec2f screen = getDriver().getScreenDimensions();
	Vec2f br(screen.x - margin, margin + boxH);
	Vec2f tl(br.x - boxW, br.y - boxH);

	DrawPanel(tl, br);

	DrawTextCenteredBold(title, Vec2f((tl.x + br.x) * 0.5f, tl.y + padY), COL_TITLE);
	Vec2f cur = Vec2f(tl.x + padX, tl.y + padY + titleH + titleGap);

	for (uint i = 0; i < lines.length(); ++i)
	{
		GUI::DrawText(lines[i], cur, cols[i]);
		cur.y += lineH;
	}

	return boxH + margin;
}

// ------------------------------
// HUD: Top-right round status panel
// ------------------------------
float DrawZombiesHUDTopRight(CRules@ rules, const float topOffset = 0.0f)
{
	if (g_videorecording) return 0.0f;

	const float margin=24, padX=10, padY=8, lineH=18, titleH=20, titleGap=6;
	const string title = "ROUND STATUS";

	// counters
	const int   num_zombies    = rules.get_s32("num_zombies");
	const int   max_zombies    = rules.get_s32("max_zombies");
	const int   num_pzombies   = rules.get_s32("num_pzombies");
	const int   num_hands      = rules.get_s32("num_ruinstorch");
	const int   num_altars     = rules.get_s32("zombiealter");
	const int   survivors      = CountTeamPlayers(0);
	const int   undead         = rules.get_s32("num_undead");
        const float difficulty = rules.get_f32("difficulty");

	array<string> lines;
	lines.insertLast("Pillars: " + num_hands);
	lines.insertLast("Survivors: " + survivors);
	lines.insertLast("Undead: " + undead);
        lines.insertLast("Difficulty: " + formatFloat(difficulty, "", 0, 1));
	lines.insertLast("Zombies: " + (num_zombies + num_pzombies) + "/" + max_zombies);
	lines.insertLast("Altars Remaining: " + num_altars);

	const float boxW = 260.0f;
	const float boxH = padY*2 + titleH + titleGap + (lines.length() * lineH);

	Vec2f screen = getDriver().getScreenDimensions();
	Vec2f br(screen.x - margin, margin + boxH + topOffset);
	Vec2f tl(br.x - boxW, br.y - boxH);

	DrawPanel(tl, br);

    DrawTextCenteredBold(title, Vec2f((tl.x + br.x) * 0.5f, tl.y + padY), COL_TITLE);
    Vec2f cur = Vec2f(tl.x + padX, tl.y + padY + titleH + titleGap);

	for (uint i = 0; i < lines.length(); i++)
	{
		SColor col = COL_TEXT;
		if      (lines[i].findFirst("Zombies: ") == 0)         col = COL_WARN;               // amber
		else if (lines[i].findFirst("Survivors: ") == 0)       col = COL_INFO;               // blue
		else if (lines[i].findFirst("Undead: ") == 0)          col = COL_BAD;                // red
		else if (lines[i].findFirst("Difficulty: ") == 0)      col = SColor(255,255,255,0);  // yellow
		else if (lines[i].findFirst("Pillars: ") == 0)         col = SColor(255,100,200,255);// light blue
		else if (lines[i].findFirst("Altars Remaining: ")==0)  col = SColor(255,160,0,255);  // purple-ish

		GUI::DrawText(lines[i], cur, col);
		cur.y += lineH;
	}

	return boxH + margin + topOffset;
}

// ------------------------------
// HUD: Mode status (countdowns + ACTIVE)
// ------------------------------
float DrawModeStatus(CRules@ rules, const float topOffset = 0.0f)
{
	if (g_videorecording) return 0.0f;

	const float margin = 24, padX = 10, padY = 8, lineH = 18, titleH = 20, titleGap = 6;
	const string title = "MODE STATUS";

	const int curDay   = GetCurrentDay(rules);
	const int hardDay  = rules.get_s32("hardmode_day");
	const int curseDay = rules.get_s32("curse_day");

	const int hardRemain  = hardDay  - curDay;
	const int curseRemain = curseDay - curDay;

	string hardLine;
	SColor hardCol = COL_TEXT;
	if (hardRemain <= 0)
	{
		hardLine = "Hardmode: ACTIVE";
		hardCol = COL_BAD;
	}
	else
	{
		hardLine = "Hardmode in: " + hardRemain + (hardRemain == 1 ? " day" : " days");
		if (hardRemain <= 20) hardCol = COL_WARN;
		else { hardCol = COL_GOOD; }
	}

	string curseLine;
	SColor curseCol = COL_TEXT;
	if (curseRemain <= 0)
	{
		curseLine = "Curse: ACTIVE";
		curseCol = COL_BAD;
	}
	else
	{
		curseLine = "Curse in: " + curseRemain + (curseRemain == 1 ? " day" : " days");
		if (curseRemain <= 20) curseCol = COL_WARN;
		else { curseCol = COL_GOOD; }
	}

	const bool ruinsActive = rules.get_bool("ruins_portal_active");
	const string ruinsLine = ruinsActive ? "Ruin Portals: ACTIVE" : "Ruin Portals: INACTIVE";
	const SColor ruinsCol  = ruinsActive ? COL_BAD : COL_GOOD;

	// --- box sizing ---
	const int numLines = 3; // hard + curse + ruins (always drawn)
	const float boxW = 260.0f;
	const float boxH = padY*2 + titleH + titleGap + (numLines * lineH);

	// --- corners ---
	Vec2f screen = getDriver().getScreenDimensions();
	Vec2f br(screen.x - margin, margin + boxH + topOffset);
	Vec2f tl(br.x - boxW, br.y - boxH);

	// --- panel + title ---
	DrawPanel(tl, br);
	DrawTextCenteredBold(title, Vec2f((tl.x + br.x) * 0.5f, tl.y + padY), COL_TITLE);

	// --- lines ---
	Vec2f cur = Vec2f(tl.x + padX, tl.y + padY + titleH + titleGap);
	GUI::DrawText(hardLine,  cur, hardCol);  cur.y += lineH;
	GUI::DrawText(curseLine, cur, curseCol); cur.y += lineH;
	GUI::DrawText(ruinsLine, cur, ruinsCol); cur.y += lineH;

	return boxH + margin + topOffset;
}

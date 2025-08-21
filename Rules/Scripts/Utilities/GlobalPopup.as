#ifndef GLOBAL_POPUP_INCLUDED
#define GLOBAL_POPUP_INCLUDED

// GlobalPopup.as — reusable server->client popup for centered announcements
// Safe: single definition, public syncs, no fancy deps.

const string POP_MSG_KEY = "popup_msg";
const string POP_START_KEY = "popup_start";
const string POP_DURATION_KEY = "popup_duration";
const string POP_KIND_KEY = "popup_kind";			  // 0 = normal, 1 = boss
const string POP_COLOR_HEAD_KEY = "popup_color_head"; // u32 ARGB (headline)
const string POP_COLOR_BODY_KEY = "popup_color_body"; // u32 ARGB (body)

// 10 seconds default
const u16 POP_DEFAULT_DURATION = 10 * getTicksASecond();
const SColor POP_DEFAULT_COLOR(255, 255, 240, 0); // warm yellow

// Pack ARGB -> u32
u32 PackColor(const SColor&in c)
{
	return (u32(c.getAlpha()) << 24) | (u32(c.getRed()) << 16) |
		   (u32(c.getGreen()) << 8) | u32(c.getBlue());
}

// Unpack u32 -> ARGB
SColor UnpackColor(const u32 packed)
{
	return SColor(
		(packed >> 24) & 0xFF,
		(packed >> 16) & 0xFF,
		(packed >> 8) & 0xFF,
		(packed) & 0xFF);
}

// ---------------------
// SERVER: Normal popup
// ---------------------
void Server_GlobalPopup(CRules @rules,
						const string&in msg,
						SColor bodyCol = POP_DEFAULT_COLOR,
						u16 duration_ticks = POP_DEFAULT_DURATION)
{
	if (!isServer() || rules is null)
		return;

	rules.set_string(POP_MSG_KEY, msg);
	rules.set_u32(POP_START_KEY, getGameTime());
	rules.set_u32(POP_DURATION_KEY, duration_ticks);
	rules.set_u32(POP_KIND_KEY, 0);						   // normal
	rules.set_u32(POP_COLOR_HEAD_KEY, PackColor(bodyCol)); // same as body for normal
	rules.set_u32(POP_COLOR_BODY_KEY, PackColor(bodyCol));

	// Broadcast to all clients (public sync = false)
	rules.Sync(POP_MSG_KEY, false);
	rules.Sync(POP_START_KEY, false);
	rules.Sync(POP_DURATION_KEY, false);
	rules.Sync(POP_KIND_KEY, false);
	rules.Sync(POP_COLOR_HEAD_KEY, false);
	rules.Sync(POP_COLOR_BODY_KEY, false);
}

// ----------------------------------
// SERVER: Boss popup (headline/body)
// ----------------------------------
void Server_BossPopup(CRules @rules,
					  const string&in headline,
					  const string&in detail,
					  u16 duration_ticks = 8 * getTicksASecond(),
					  SColor headlineCol = SColor(255, 255, 60, 60), // red
					  SColor bodyCol = SColor(255, 255, 220, 90))	 // gold
{
	if (!isServer() || rules is null)
		return;

	// Encode as "headline\nbody" so clients only need one renderer
	rules.set_string(POP_MSG_KEY, headline + "\n" + detail);
	rules.set_u32(POP_START_KEY, getGameTime());
	rules.set_u32(POP_DURATION_KEY, duration_ticks);
	rules.set_u32(POP_KIND_KEY, 1); // boss
	rules.set_u32(POP_COLOR_HEAD_KEY, PackColor(headlineCol));
	rules.set_u32(POP_COLOR_BODY_KEY, PackColor(bodyCol));

	rules.Sync(POP_MSG_KEY, false);
	rules.Sync(POP_START_KEY, false);
	rules.Sync(POP_DURATION_KEY, false);
	rules.Sync(POP_KIND_KEY, false);
	rules.Sync(POP_COLOR_HEAD_KEY, false);
	rules.Sync(POP_COLOR_BODY_KEY, false);
}

// Optional compatibility shim
#ifndef HAS_SERVER_SENDGLOBALMESSAGE
	#define HAS_SERVER_SENDGLOBALMESSAGE
void server_SendGlobalMessage(const string&in msg)
{
	CRules @r = getRules();
	if (r is null)
		return;
	Server_GlobalPopup(r, msg);
}
#endif // HAS_SERVER_SENDGLOBALMESSAGE

// -------------------------------------------------
// CLIENT: Draw helper (call from your onRender())
// -------------------------------------------------
void DrawGlobalPopup(CRules @ this)
{
	const string msg = this.get_string(POP_MSG_KEY);
	if (msg == "")
		return;

	const u32 start = this.get_u32(POP_START_KEY);
	const u32 duration = this.get_u32(POP_DURATION_KEY);
	if (duration == 0)
		return;

	const u32 now = getGameTime();
	if (now < start || now > start + duration)
		return;

	// Fade ~0.2s at in/out edges
	const f32 t = f32(now - start) / f32(duration); // 0..1
	const f32 fadeEdge = 6.0f / f32(getTicksASecond());
	f32 alphaMul = 1.0f;
	if (t < fadeEdge)
		alphaMul = t / fadeEdge;
	else if (t > (1.0f - fadeEdge))
		alphaMul = (1.0f - t) / fadeEdge;

	const u32 kind = this.get_u32(POP_KIND_KEY);
	SColor headCol = UnpackColor(this.get_u32(POP_COLOR_HEAD_KEY));
	SColor bodyCol = UnpackColor(this.get_u32(POP_COLOR_BODY_KEY));

	// Split lines; first line is headline if boss
	string[] lines = msg.split("\n");
	if (lines.length == 0)
		return;

	// Measure width and total height line-by-line
	GUI::SetFont("menu");
	f32 widest = 0.0f;
	f32 totalH = 0.0f;
	const f32 lineGap = 4.0f;
	for (uint i = 0; i < lines.length(); i++)
	{
		Vec2f sz;
		GUI::GetTextDimensions(lines[i], sz);
		widest = Maths::Max(widest, sz.x);
		totalH += sz.y + (i + 1 < lines.length() ? lineGap : 0.0f);
	}

	// Layout: upper-center (20% down), generous padding + extra bottom
	const Vec2f pad(16, 14); // slightly larger box
	const f32 extraBottom = 10.0f;

	Vec2f center(getScreenWidth() * 0.5f, getScreenHeight() * 0.20f);
	Vec2f tl = center - Vec2f(widest * 0.5f, totalH * 0.5f) - pad;
	Vec2f br = center + Vec2f(widest * 0.5f, totalH * 0.5f) + pad + Vec2f(0, extraBottom);

	// Background: black, semi-transparent (like Round Stats)
	const u8 bgA = u8(140 * alphaMul);
	GUI::DrawRectangle(tl, br, SColor(bgA, 0, 0, 0));

	// Border: thin; red if boss, gold otherwise
	SColor bdCol = (kind == 1 ? SColor(u8(220 * alphaMul), 255, 0, 0) : SColor(u8(220 * alphaMul), 255, 255, 0));
	GUI::DrawRectangle(tl, Vec2f(br.x, tl.y + 1), bdCol);
	GUI::DrawRectangle(Vec2f(tl.x, br.y - 1), br, bdCol);
	GUI::DrawRectangle(tl, Vec2f(tl.x + 1, br.y), bdCol);
	GUI::DrawRectangle(Vec2f(br.x - 1, tl.y), br, bdCol);

	// Draw text: headline centered at top; body lines below, centered
	f32 y = tl.y + 12.0f;
	for (uint i = 0; i < lines.length(); i++)
	{
		const bool isHead = (kind == 1 && i == 0);
		SColor col = isHead ? headCol : bodyCol;

		// apply fade
		col.setAlpha(u8(col.getAlpha() * alphaMul));

		Vec2f lineSize;
		GUI::GetTextDimensions(lines[i], lineSize);

		Vec2f pos((tl.x + br.x) * 0.5f, y);
		GUI::DrawTextCentered(lines[i], pos, col);

		y += lineSize.y + lineGap;
	}
}

#endif // GLOBAL_POPUP_INCLUDED

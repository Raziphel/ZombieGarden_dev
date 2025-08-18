// GlobalPopup.as
// Reusable server->client popup system for centered on-screen announcements.

const string POP_MSG_KEY      = "popup_msg";
const string POP_START_KEY    = "popup_start";
const string POP_COLOR_KEY    = "popup_color";
const string POP_DURATION_KEY = "popup_duration";

// Default popup duration in ticks (10 seconds)
const u16    POP_DEFAULT_DURATION = 10 * getTicksASecond();
const SColor POP_DEFAULT_COLOR(255, 255, 240, 0);          // warm yellow

// ---- SERVER API ----
// Broadcast a popup to everyone, with optional color + duration (ticks)
void Server_GlobalPopup(CRules@ rules, const string &in msg,
                        SColor col = POP_DEFAULT_COLOR,
                        u16 duration_ticks = POP_DEFAULT_DURATION)
{
	if (!isServer() || rules is null) return;

	rules.set_string(POP_MSG_KEY, msg);
	rules.set_u32(POP_START_KEY, getGameTime());
	rules.set_u32(POP_DURATION_KEY, duration_ticks);

	// Pack color (ARGB) into u32 for syncing
	u32 packed = (u32(col.getAlpha()) << 24) | (u32(col.getRed()) << 16) |
	             (u32(col.getGreen()) << 8)  |  u32(col.getBlue());
	rules.set_u32(POP_COLOR_KEY, packed);

	// Sync to clients
	rules.Sync(POP_MSG_KEY, true);
	rules.Sync(POP_START_KEY, true);
	rules.Sync(POP_DURATION_KEY, true);
	rules.Sync(POP_COLOR_KEY, true);
}

// Compatibility shim: redirect old chat-broadcasts into the popup.
void server_SendGlobalMessage(const string &in msg)
{
	CRules@ rules = getRules();
	if (rules is null) return;
	Server_GlobalPopup(rules, msg);
}

// ---- CLIENT RENDER ----
void onRender(CRules@ this)
{
	const string msg = this.get_string(POP_MSG_KEY);
	if (msg == "") return;

	const u32 start    = this.get_u32(POP_START_KEY);
	const u32 duration = this.get_u32(POP_DURATION_KEY);
	const u32 now      = getGameTime();

	if (now <= start || now > start + duration) return;

	// Unpack color (ARGB)
	const u32 packed = this.get_u32(POP_COLOR_KEY);
	SColor col(
		(packed >> 24) & 0xFF,
		(packed >> 16) & 0xFF,
		(packed >> 8)  & 0xFF,
		(packed)       & 0xFF
	);

	// Fade in/out ~0.2s each end
	const f32 t        = f32(now - start) / f32(duration);
	const f32 fadeEdge = duration > 0 ? 6.0f / f32(getTicksASecond()) : 0.0f;
	f32 alphaMul       = 1.0f;
	if (t < fadeEdge)               alphaMul = t / fadeEdge;             // in
	else if (t > (1.0f - fadeEdge)) alphaMul = (1.0f - t) / fadeEdge;    // out

	GUI::SetFont("menu");

	// Position: upper-center (20% down)
	Vec2f center(getScreenWidth() * 0.5f, getScreenHeight() * 0.20f);

	// Handle multi-line sizing
	Vec2f textSize;
	GUI::GetTextDimensions(msg, textSize);

	// Panel geometry
	const Vec2f pad = Vec2f(14, 10);
	Vec2f tl = center - textSize * 0.5f - pad;
	Vec2f br = center + textSize * 0.5f + pad;

	// Background
	const u8 bgA = u8(165 * alphaMul);
	GUI::DrawPane(tl, br, SColor(bgA, 10, 10, 10));

	// Border
	const u8 bdA = u8(220 * alphaMul);
	GUI::DrawRectangle(tl - Vec2f(2,2), br + Vec2f(2,2), SColor(bdA, 255, 255, 0));

	// Text (alpha-multiplied)
	SColor textCol = col;
	textCol.setAlpha(u8(textCol.getAlpha() * alphaMul));
	GUI::DrawTextCentered(msg, center, textCol);
}

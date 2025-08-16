// ZombieDigCont.as
// Tweaked for better downward digging: focused below, circular mask, only solid tiles,
// and light FX throttling. AngelScript Vec2f has no LengthSquared(), so we use manual dsq.

//#include "Hitters.as";

void onInit(CBlob@ this)
{
	// Faster reaction so they don't stall on soil
	this.getCurrentScript().tickFrequency = 40;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
	if (!getNet().isServer())
		return;

	CMap@ map = getMap();
	if (map is null)
		return;

	const Vec2f pos = this.getPosition();
	const f32 step = map.tilesize;                          // tile size in pixels
	const f32 radius_px = this.get_f32("dig radius") * step;// radius in pixels
	const f32 radius_sq = radius_px * radius_px;
	const f32 dmg = this.get_f32("dig damage");

	// Only target tiles below the blob's feet to bias "digging down"
	// Nudge start a half-tile down so we don't chew our own headspace
	const f32 start_y = pos.y + step * 0.5f;

	// Convert radius to tile units for iteration bounds
	const int r_tiles = Maths::Ceil(radius_px / step);

	bool did_dig = false;

	for (int tx = -r_tiles; tx <= r_tiles; ++tx)
	{
		for (int ty = 0; ty <= r_tiles; ++ty) // only below (0..r_tiles)
		{
			Vec2f tpos = Vec2f(pos.x + tx * step, start_y + ty * step);

			// Circular mask using manual squared distance (AngelScript lacks LengthSquared())
			const Vec2f delta = tpos - pos;
			const f32 dsq = delta.x * delta.x + delta.y * delta.y;
			if (dsq > radius_sq)
				continue;

			TileType tt = map.getTile(tpos).type;

			// Skip bedrock and non-solid tiles (air/background/etc.)
			if (map.isTileBedrock(tt) || !map.isTileSolid(tt))
				continue;

			// Crunch it
			map.server_DestroyTile(tpos, dmg, this);
			did_dig = true;
		}
	}

	// Let the sprite know whether we actually dug something
	this.set_bool("is_digging", did_dig);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	// Only play effects if we’re actually digging, and not every tick
	const bool digging = blob.get_bool("is_digging");
	if (!digging) return;

	const u32 now = getGameTime();
	const string fx_key = "dig_fx_next";
	const u32 next = blob.get_u32(fx_key);

	if (now >= next)
	{
		// Tiny puff & scrape
		ParticleAnimated("/ToxicPush.png", blob.getPosition(), Vec2f_zero, 0.0f, 1.0f, 2, -0.1f, false);
		blob.getSprite().PlaySound("ExtinguishFire.ogg");

		// every ~6 ticks while actively digging
		blob.set_u32(fx_key, now + 6);
	}
}

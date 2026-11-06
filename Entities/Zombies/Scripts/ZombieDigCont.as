// ZombieDigCont.as
// Tweaked for better downward digging: focused below, circular mask, only solid tiles,
// light FX throttling and a target-check so zombies don't dig without a reason.
// AngelScript Vec2f has no LengthSquared(), so we use manual dsq.

// #include "Hitters.as";

void onInit(CBlob @ this)
{
	// Faster reaction so they don't stall on soil
	this.getCurrentScript().tickFrequency = 40;
	this.getCurrentScript().removeIfTag = "dead";
}

void SetZombieDigging(CBlob @blob, bool digging)
{
	if (blob.get_bool("is_digging") != digging)
	{
		blob.set_bool("is_digging", digging);
		blob.Sync("is_digging", true);
	}
}

void onTick(CBlob @ this)
{
	if (!getNet().isServer())
		return;

	CMap @map = this.getMap();
	if (map is null)
	{
		SetZombieDigging(this, false);
		return;
	}

	const Vec2f pos = this.getPosition();
	const f32 step = map.tilesize;							 // tile size in pixels
	const f32 radius_px = Maths::Clamp(this.get_f32("dig radius"), 0.0f, 6.0f) * step;
	const f32 radius_sq = radius_px * radius_px;
	const f32 dmg = this.get_f32("dig damage");
	if (radius_px < step || dmg <= 0.0f)
	{
		SetZombieDigging(this, false);
		return;
	}

	// Only dig while pursuing a living target. Downward digging preserves
	// the existing burrowing behaviour; forward digging is allowed only if
	// solid ground immediately blocks progress toward that target.
	CBrain @brain = this.getBrain();
	CBlob @target = brain is null ? null : brain.getTarget();
	if (target is null || target.hasTag("dead"))
	{
		SetZombieDigging(this, false);
		return;
	}

	const Vec2f goal = target.getPosition();
	const bool targetBelow = goal.y > pos.y + step;
	const bool toRight = goal.x > pos.x + step;
	const bool toLeft = goal.x < pos.x - step;
	bool wallAhead = false;
	if (!targetBelow && (toRight || toLeft))
	{
		const f32 direction = toRight ? 1.0f : -1.0f;
		Vec2f hit;
		wallAhead = map.rayCastSolid(pos,
			pos + Vec2f(direction * (radius_px + step), 0.0f), hit);
	}

	if (!targetBelow && !wallAhead)
	{
		SetZombieDigging(this, false);
		return;
	}

	const f32 start_y = targetBelow ? pos.y + step * 0.5f : pos.y;
	const int r_tiles = Maths::Ceil(radius_px / step);

	bool did_dig = false;

	for (int tx = -r_tiles; tx <= r_tiles; ++tx)
	{
		// When blocked horizontally, mine only the narrow front face of
		// the wall, not an entire circular area around the zombie.
		if (!targetBelow && (tx == 0 || (toRight && tx < 0) ||
			(toLeft && tx > 0)))
			continue;

		const int minY = targetBelow ? 0 : -1;
		const int maxY = targetBelow ? r_tiles : 1;
		for (int ty = minY; ty <= maxY; ++ty)
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

	// Replicate only transitions so the client can reliably play and stop
	// the dust effect without a full network update every 40 ticks.
	SetZombieDigging(this, did_dig);
}

void onTick(CSprite @ this)
{
	CBlob @blob = this.getBlob();
	if (blob is null)
		return;

	// Only play effects if we’re actually digging, and not every tick
	const bool digging = blob.get_bool("is_digging");
	if (!digging)
		return;

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

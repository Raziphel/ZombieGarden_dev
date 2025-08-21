#define SERVER_ONLY

const string migrant_name = "migrantbot";

void onTick(CRules @ this)
{
	// run ~every half second
	if (getGameTime() % 29 != 0)
		return;

	CMap @map = getMap();
	if (map is null || map.tilemapwidth < 2)
		return;

	// how many are allowed at once (fallback to 3 if unset)
	const int max_migrantbots = Maths::Max(1, this.get_s32("max_migrantbots"));

	// count current migrants
	CBlob @[] migrants;
	getBlobsByTag(migrant_name, @migrants);

	// only spawn around midday window
	const f32 t = map.getDayTime(); // 0.0..1.0
	if (migrants.length >= max_migrantbots || t <= 0.40f || t >= 0.60f)
		return;

	// pick a base spot: prefer a zombieruins, otherwise map center
	Vec2f basePos;
	CBlob @[] ruins;
	getBlobsByName("zombieruins", @ruins);
	if (ruins.length > 0)
	{
		basePos = ruins[XORRandom(ruins.length)].getPosition();
	}
	else
	{
		basePos = Vec2f(map.tilemapwidth * 0.5f * map.tilesize, 16.0f);
	}

	// drop a ray to find ground near basePos
	Vec2f groundPos = basePos;
	if (map.rayCastSolid(basePos, basePos + Vec2f(0, 128), groundPos))
	{
		groundPos.y -= 4.0f; // nudge above ground
	}

	// try a few offsets upward to avoid spawning inside blocks
	for (u8 i = 0; i < 6; i++)
	{
		Vec2f tryPos = groundPos + Vec2f(0, -i * map.tilesize);
		// if you want to avoid water entirely, uncomment the next check:
		// if (map.isInWater(tryPos)) continue;

		// simple solidity check; adjust if you need more robust clearance
		if (!map.isTileSolid(tryPos))
		{
			server_CreateBlob(migrant_name, 0, tryPos);
			// Sound::Play("MigrantSayHello.ogg", tryPos, 1.0f, 1.5f);
			break;
		}
	}
}

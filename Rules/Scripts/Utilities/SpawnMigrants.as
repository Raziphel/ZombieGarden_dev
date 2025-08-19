#define SERVER_ONLY

const string migrant_name = "migrantbot";

void onTick(CRules@ this)
{
	if (getGameTime() %29 != 0) return;
	//if (XORRandom(512) < 256) return; //50% chance of actually doing anything

	CMap@ map = getMap();
	if (map is null || map.tilemapwidth < 2) return; //failed to load map?

	CBlob@[] migrant;
	int max_migrantbots = this.get_s32("max_migrantbots");
	getBlobsByTag("migrantbot", @migrant );
	
	if (migrant.length < max_migrantbots && map.getDayTime()>0.4 && map.getDayTime()<0.6)
	{
		CBlob@[] spawns0;
		getBlobsByName("zombieruins", @spawns0);
		if (spawns0.length > 0)
		{
			Vec2f pos = spawns0[XORRandom(spawns0.length)].getPosition();
		}

		while (i ++ < 3)
		{
			Vec2f pos = Vec2f(x, y - i * map.tilesize);
			//if (!map.isInWater(pos))
			{
				server_CreateBlob("migrantbot", 0, pos);
				// Sound::Play("MigrantSayHello.ogg", pos, 1.0f, 1.5f);
				break;
			}
		}
	}
}

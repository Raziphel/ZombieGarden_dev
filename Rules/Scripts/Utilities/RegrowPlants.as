#define SERVER_ONLY

// should stone turn into mossy stone
const bool moss_stone = false;

// random_growth is randomly set from 0 to 1.0
// don't set values lower than 0.0001
// if you want to prevent a thing from growing at all, set it's chance to -1 rather than 0
const f32 grass_grow_chance   = 0.015f;
const f32 bush_grow_chance    = 0.003f;
const f32 flower_grow_chance  = 0.0005f;
const f32 grain_grow_chance   = flower_grow_chance + 0.0005f; // add flower chance to prevent them from overriding each other

// Animals (grown like plants… chickens are plants don’t @ me)
const f32 chicken_grow_chance = 0.001f;
const f32 piglet_grow_chance  = 0.0006f;
const f32 bunny_grow_chance   = 0.0006f;
const f32 birb_grow_chance    = 0.0004f;
const f32 bison_grow_chance   = 0.00015f;

const u8  chicken_limit = 6;
const u8  piglet_limit  = 5;
const u8  bunny_limit   = 5;
const u8  birb_limit    = 8;
const u8  bison_limit   = 1;

// local anti-clump radii (prevent spamming same animal on one screen)
const f32 critter_radius_small = 64.0f;  // chicken, piglet, bunny, birb
const f32 critter_radius_bison = 96.0f;  // big lad

const f32 moss_stone_chance = 0.002f;

// how many ticks has to pass before stone starts becoming mossy, 20 minutes = 30 * 60 * 20
const u32 moss_time = 30 * 60 * 20;

// which tiles should turn into moss
// tile from castle_stuff will turn into a corresponding tile from castle_moss_stuff
const u16[] castle_stuff      = {CMap::tile_castle, CMap::tile_castle_back};
const u16[] castle_moss_stuff = {CMap::tile_castle_moss, CMap::tile_castle_back_moss};
const string[] plants_stuff   = {"bush", "flowers", "grain_plant"};

const u16 min_random_time = 200; // minimal time between growth checks
const u16 max_random_inc  = 60; // maximum random increase to time between growth checks

u32 next_check_time = min_random_time;

TileInfo@[] dirt_tiles;
TileInfo@[] castle_tiles;

class TileInfo
{
	Vec2f coords;
	u32 place_time;
	Tile tile;

	TileInfo() {};

	TileInfo(Vec2f _coords, u32 _place_time, Tile _tile)
	{
		coords = _coords;
		place_time = _place_time;
		tile = _tile;
	};

	bool mossTime()
	{
		return (getGameTime() - place_time > moss_time); // has enough time passed since this tile was placed?
	}

	bool hasMossAdjacent()
	{
		CMap@ map = getMap();

		Vec2f[] adjacentTilePos = {
			Vec2f(map.tilesize, 0),   // left
			Vec2f(-map.tilesize, 0),  // right
			Vec2f(0, map.tilesize),   // up
			Vec2f(0, -map.tilesize)   // down
		};

		for (u8 i = 0; i < adjacentTilePos.size(); i++)
		{
			Tile tile = map.getTile(coords - adjacentTilePos[i]);
			u32 index = findTileByCoords(castle_tiles, coords - adjacentTilePos[i]);

			bool mossyCastle = castle_moss_stuff.find(tile.type) != -1;

			// to ignore min time restriction if tile is close to moss, otherwise you can prevent moss from spreading very very easily
			if (mossyCastle)
			{
				TileInfo tinfo = castle_tiles[index];

				if (tinfo.place_time != 0) // prevent moss that was on the map since the beginning from spreading
				{
					return true;
				}
			}
		}

		return false;
	}

	f32 grassLuck()
	{
		f32 luck = 0;
		CMap@ map = getMap();

		Tile tile_left  = map.getTile(coords - Vec2f(map.tilesize, map.tilesize));
		Tile tile_right = map.getTile(coords - Vec2f(-map.tilesize, map.tilesize));

		// increase chance that grass will grow on this tile if there's grass around it
		if (map.isTileGrass(tile_left.type))
		{
			luck += 0.15f;
		}

		if (map.isTileGrass(tile_right.type))
		{
			luck += 0.15f;
		}

		return luck;
	}

	f32 mossLuck()
	{
		f32 luck = 0;
		CMap@ map = getMap();

		Vec2f[] adjacentTilePos = {
			Vec2f(map.tilesize, 0),   // left
			Vec2f(-map.tilesize, 0),  // right
			Vec2f(0, map.tilesize),   // up
			Vec2f(0, -map.tilesize)   // down
		};

		for (u8 i = 0; i < adjacentTilePos.size(); i++)
		{
			Tile tile = map.getTile(coords - adjacentTilePos[i]);
			bool ground = map.isTileGround(tile.type);
			bool bedrock = map.isTileBedrock(tile.type);
			bool mossyCastle = castle_moss_stuff.find(tile.type) != -1;

			// increase chance that this tile will mossify if there's dirt, bedrock, or other mossy tiles around it
			if (ground || bedrock || mossyCastle)
			{
				luck += 0.002f;
			}
		}

		return luck;
	}
};

void onInit(CRules@ this)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		// add fake tiles to the start of TileInfo arrays so if findTileByCoords returns 0 it doesn't refer to a tile we should've updated
		dirt_tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));
		castle_tiles.insertLast(TileInfo(Vec2f(-1,-1), 0, map.getTile(Vec2f(0,0))));
		for (u32 x = 0; x < map.tilemapwidth; x++)
		{
			for (u32 y = 0; y < map.tilemapheight; y++)
			{
				Vec2f coords(x * map.tilesize, y * map.tilesize);

				Tile tile = map.getTile(coords);
				Tile tile_above = map.getTile(coords - Vec2f(0, map.tilesize));

				// add tile if tile above it is empty or it's a castle/wood wall so grass grows after it's destroyed
				bool valid_back = (tile_above.type == CMap::tile_empty || (map.isTileBackground(tile_above) && tile_above.type != CMap::tile_ground_back));

				if (map.isTileGround(tile.type) && valid_back)
				{
					dirt_tiles.insertLast(TileInfo(coords, 0, tile));
				}

				// add stuff from castle_stuff into its own array
				if (castle_stuff.find(tile.type) != -1) 
				{
					castle_tiles.insertLast(TileInfo(coords, 0, tile));
				}
			}
		}

		if (!map.hasScript("RegrowPlants.as")) map.AddScript("RegrowPlants.as"); // adding map scripts from CRules is much more convenient than adding it to every map in mapcycle.cfg
	}

}

void onRestart(CRules@ this)
{
	next_check_time = min_random_time;
	// refill TileInfo arrays with info for the newly loaded map
	dirt_tiles.clear();
	castle_tiles.clear();
	onInit(this);
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	u32 x = index % this.tilemapwidth;
	u32 y = index / this.tilemapwidth;
	Vec2f coords(x * this.tilesize, y * this.tilesize);
	u32 tindex_dirt = findTileByCoords(dirt_tiles, coords);
	u32 tindex_stone = findTileByCoords(castle_tiles, coords);

	// dirt leaves dirt background after it's destroyed, so no need to check for dirt tiles below it
	// onSetTile runs when a tile is damaged, so check if new tile is just more damaged dirt
	if (this.isTileGround(oldtile) && !this.isTileGround(newtile) && tindex_dirt != 0 && dirt_tiles.size() > 0)
	{
		dirt_tiles.removeAt(tindex_dirt);
	}
	// castle tile got destroyed/damaged/mossified, remove from array
	// don't check if new tile is just a damaged castle, because we don't mossify damaged stone (only full hp stone has moss variants)
	if (castle_stuff.find(oldtile) != -1 && tindex_stone != 0 && castle_tiles.size() > 0)
	{
		castle_tiles.removeAt(tindex_stone);
	}
	// castle tile was built, add to array
	if (castle_stuff.find(newtile) != -1 && tindex_stone == 0)
	{
		castle_tiles.insertLast(TileInfo(coords, getGameTime(), this.getTile(coords)));
	}
}

u32 findTileByCoords(const TileInfo@[] &in tiles, Vec2f coords)
{
	for (u32 i = 1; i < tiles.size(); i++)
	{
		if (tiles[i].coords == coords)
		{
			return i;
		}
	}

	return 0;
}

// --------- Helpers for critter spawning ---------

bool underOpenSkyOrGrass(CMap@ map, Vec2f worldPos)
{
	const f32 ts = map.tilesize;
	Tile above = map.getTile(worldPos - Vec2f(0, ts));
	return (above.type == CMap::tile_empty || map.isTileGrass(above.type));
}

u32 countBlobsByName(const string &in name)
{
	CBlob@[] found;
	getBlobsByName(name, @found);
	return found.length;
}

bool hasBlobNearby(const string &in name, Vec2f pos, f32 radius)
{
	CBlob@[] nearby;
	if (getMap().getBlobsInRadius(pos, radius, nearby))
	{
		for (u16 i = 0; i < nearby.length; i++)
		{
			if (nearby[i] !is null && nearby[i].getName() == name)
				return true;
		}
	}
	return false;
}

void trySpawnCritter(const string &in name, f32 chance, u8 global_cap, Vec2f groundPos, f32 radius)
{
	if (chance < 0) return;

	// random draw
	f32 r = XORRandom(10000) * 0.0001f; // 0..1
	if (r > chance) return;

	// global cap
	if (countBlobsByName(name) >= global_cap) return;

	// anti-clump
	if (hasBlobNearby(name, groundPos, radius)) return;

	server_CreateBlob(name, -1, groundPos);
}

void onTick(CRules@ this)
{
	if (getGameTime() >= next_check_time)
	{
		CMap@ map = getMap();
		f32 tilesize = map.tilesize;

		for (int i = 1; i < dirt_tiles.size(); i++)
		{
			TileInfo tinfo = dirt_tiles[i];
			if (tinfo is null) return;
			Vec2f pos_above = tinfo.coords - Vec2f(0, tilesize);
			Tile tile_above = map.getTile(pos_above);

			if (tile_above.type == CMap::tile_empty || map.isTileGrass(tile_above.type))
			{
				// ---- Grass spread
				f32 random_grow = XORRandom(10000) * 0.0001f;

				if (random_grow - tinfo.grassLuck() <= grass_grow_chance && !map.isTileGrass(tile_above.type))
				{
					map.server_SetTile(pos_above, CMap::tile_grass + XORRandom(3));
				}

				// ---- Plants (bush / flowers / grain)
				random_grow = XORRandom(10000) * 0.0001f; // re-roll each check

				s16 plant = -1;
				if (random_grow <= bush_grow_chance)  plant = 0;
				if (random_grow <= grain_grow_chance) plant = 2;
				if (random_grow <= flower_grow_chance) plant = 1; // do checks out of order so flower overrides grain growth

				if (plant != -1)
				{
					CBlob@[] blobs;
					bool near_plant = false;

					if (map.getBlobsInRadius(tinfo.coords, 8.0f, blobs))
					{
						for (int a = 0; a < blobs.size(); a++)
						{
							CBlob@ blob = blobs[a];
							if (blob is null) continue;
							if (plants_stuff.find(blob.getName()) != -1) // don't double plant
							{
								near_plant = true; 
								break;
							}
						}
					}

					if (!near_plant)
					{
						server_CreateBlob(plants_stuff[plant], -1, pos_above);
					}
				}

				// ---- Critters (spawn over ground with sky/grass above)
				// safety: ensure the spawn location is reasonable
				if (underOpenSkyOrGrass(map, tinfo.coords))
				{
					// small animals
					trySpawnCritter("chicken", chicken_grow_chance, chicken_limit, pos_above, critter_radius_small);
					trySpawnCritter("piglet",  piglet_grow_chance,  piglet_limit,  pos_above, critter_radius_small);
					trySpawnCritter("bunny",   bunny_grow_chance,   bunny_limit,   pos_above, critter_radius_small);
					trySpawnCritter("birb",    birb_grow_chance,    birb_limit,    pos_above, critter_radius_small);

					// big animal
					trySpawnCritter("bison",   bison_grow_chance,   bison_limit,   pos_above, critter_radius_bison);
				}
			}
		}

		if (moss_stone)
		{
			for (int i = 1; i < castle_tiles.size(); i++)
			{
				TileInfo tinfo = castle_tiles[i];
				f32 random_grow = XORRandom(10000) * 0.0001f;
				u32 ttype = castle_stuff.find(tinfo.tile.type);
				f32 luck = tinfo.mossLuck();
				
				if (ttype != -1)
				{
					// check for luck being non-zero so stone structures get mossified starting from ground level
					if (luck > 0 && random_grow - luck <= moss_stone_chance && (tinfo.mossTime() || tinfo.hasMossAdjacent()))
					{
						map.server_SetTile(tinfo.coords, castle_moss_stuff[ttype]);
					}
				}
			}
		}

		// make timing for growth checks semi-random so they're not too monotonous
		next_check_time = getGameTime() + min_random_time + XORRandom(max_random_inc);
	}
}

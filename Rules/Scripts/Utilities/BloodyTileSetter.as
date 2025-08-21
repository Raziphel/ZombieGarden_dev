
#include "CustomBlocks.as";
#include "Hitters.as"


void BloodTiles(CParticle @p)
{
	CRules @rules = getRules();
	CMap @map = getMap();
	Vec2f tilepos = p.position;

	CBitStream params;
	params.write_Vec2f(tilepos);
	rules.SendCommand(rules.getCommandID("SetBloodTiles"), params);
}

void onInit(CRules @ this)
{
	this.addCommandID("SetBloodTiles");
}

void onCommand(CRules @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("SetBloodTiles"))
	{
		CMap @map = getMap();
		Vec2f pos = params.read_Vec2f();

		Vec2f tilespace = map.getTileSpacePosition(pos);
		int offset = map.getTileOffsetFromTileSpace(tilespace);
		TileType tile = map.getTile(offset).type;
		TileType tilebelow = map.getTile(offset + map.tilemapwidth).type;

		if ((tile >= CMap::tile_grass && tile <= CMap::tile_grass + 3) || (tile >= CMap::tile_littlebloodgrass && tile <= CMap::tile_heapsbloodgrassground_d0))
		{
			switch (tile)
			{
				case CMap::tile_grass:
					map.server_SetTile(pos, CMap::tile_littlebloodgrass);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_littlebloodgrassground);
					break;
				case CMap::tile_grass + 1:
					map.server_SetTile(pos, CMap::tile_littlebloodgrass + 1);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_littlebloodgrassground_d0);
					break;
				case CMap::tile_grass + 2:
					map.server_SetTile(pos, CMap::tile_littlebloodgrass + 2);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_littlebloodgrassground);
					break;
				case CMap::tile_grass + 3:
					map.server_SetTile(pos, CMap::tile_littlebloodgrass + 3);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_littlebloodgrassground_d0);
					break;

				case CMap::tile_littlebloodgrass:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrass);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_mediumbloodgrassground);
					break;
				case CMap::tile_littlebloodgrass + 1:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrass + 1);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_mediumbloodgrassground_d0);
					break;
				case CMap::tile_littlebloodgrass + 2:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrass + 2);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_mediumbloodgrassground);
					break;
				case CMap::tile_littlebloodgrass + 3:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrass + 3);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_mediumbloodgrassground_d0);
					break;

				case CMap::tile_mediumbloodgrass:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrass);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_heapsbloodgrassground);
					break;
				case CMap::tile_mediumbloodgrass + 1:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrass + 1);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_heapsbloodgrassground_d0);
					break;
				case CMap::tile_mediumbloodgrass + 2:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrass + 2);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_heapsbloodgrassground);
					break;
				case CMap::tile_mediumbloodgrass + 3:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrass + 3);
					map.server_SetTile(pos + Vec2f(0, 8), CMap::tile_heapsbloodgrassground_d0);
					break;
			}
		}
		else if (map.isTileGround(tilebelow) || (tilebelow >= CMap::tile_littlebloodground && tilebelow < CMap::tile_mediumbloodground_d3))
		{
			const Vec2f offset(0, 8);

			pos += offset;

			switch (tilebelow)
			{
				case CMap::tile_ground:
					map.server_SetTile(pos, CMap::tile_littlebloodground);
					break;
				case CMap::tile_ground + 1:
					map.server_SetTile(pos, CMap::tile_littlebloodground_d0);
					break;
				case CMap::tile_ground + 2:
					map.server_SetTile(pos, CMap::tile_littlebloodground);
					break;
				case CMap::tile_ground + 3:
					map.server_SetTile(pos, CMap::tile_littlebloodground_d0);
					break;
				case CMap::tile_ground + 4:
					map.server_SetTile(pos, CMap::tile_littlebloodground);
					break;
				case CMap::tile_ground + 5:
					map.server_SetTile(pos, CMap::tile_littlebloodground_d0);
					break;
				case CMap::tile_ground + 6:
					map.server_SetTile(pos, CMap::tile_littlebloodground);
					break;

				case CMap::tile_ground + 7:
					map.server_SetTile(pos, CMap::tile_littlebloodgrassground);
					break;
				case CMap::tile_ground + 8:
					map.server_SetTile(pos, CMap::tile_littlebloodgrassground_d0);
					break;

				case CMap::tile_littlebloodground:
					map.server_SetTile(pos, CMap::tile_mediumbloodground);
					break;
				case CMap::tile_littlebloodground_d0:
					map.server_SetTile(pos, CMap::tile_mediumbloodground_d0);
					break;
				case CMap::tile_littlebloodground_d1:
					map.server_SetTile(pos, CMap::tile_mediumbloodground_d1);
					break;
				case CMap::tile_littlebloodground_d2:
					map.server_SetTile(pos, CMap::tile_mediumbloodground_d2);
					break;
				case CMap::tile_littlebloodground_d3:
					map.server_SetTile(pos, CMap::tile_mediumbloodground_d3);
					break;

				case CMap::tile_mediumbloodground:
					map.server_SetTile(pos, CMap::tile_heapsbloodground);
					break;
				case CMap::tile_mediumbloodground_d0:
					map.server_SetTile(pos, CMap::tile_heapsbloodground_d0);
					break;
				case CMap::tile_mediumbloodground_d1:
					map.server_SetTile(pos, CMap::tile_heapsbloodground_d1);
					break;
				case CMap::tile_mediumbloodground_d2:
					map.server_SetTile(pos, CMap::tile_heapsbloodground_d2);
					break;
				case CMap::tile_mediumbloodground_d3:
					map.server_SetTile(pos, CMap::tile_heapsbloodground_d3);
					break;

				case CMap::tile_littlebloodgrassground:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrassground);
					break;
				case CMap::tile_littlebloodgrassground_d0:
					map.server_SetTile(pos, CMap::tile_mediumbloodgrassground_d0);
					break;

				case CMap::tile_mediumbloodgrassground:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrassground);
					break;
				case CMap::tile_mediumbloodgrassground_d0:
					map.server_SetTile(pos, CMap::tile_heapsbloodgrassground_d0);
					break;
			}
		}
	}
}

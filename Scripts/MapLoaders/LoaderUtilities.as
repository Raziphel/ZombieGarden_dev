// LoaderUtilities.as

#include "DummyCommon.as";
#include "ParticleSparks.as";
#include "BasePNGLoader.as";
#include "CustomBlocks.as";

bool onMapTileCollapse(CMap@ map, u32 offset)
{
	if(isDummyTile(map.getTile(offset).type))
	{
		CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
		if(blob !is null)
		{
			blob.server_Die();
		}
	}
	if((map.getTile(offset).type > 260 && map.getTile(offset).type < 267) || (map.getTile(offset).type > 276 && map.getTile(offset).type < 400))
	{
		return false;
	}
	return true;
}

TileType server_onTileHit(CMap@ map, f32 damage, u32 index, TileType oldTileType)
{
	if(map.getTile(index).type > 255)
	{
		switch(oldTileType)
		{	
			case CMap::tile_grass_fullbackground1:    { return CMap::tile_grass_fullbackground1_d1;}		
			case CMap::tile_grass_fullbackground1_d1: { return CMap::tile_grass_fullbackground1_d2;}
			case CMap::tile_grass_fullbackground1_d2: { return CMap::tile_grass_fullbackground1_d3;}
			case CMap::tile_grass_fullbackground1_d3: { return CMap::tile_ground_back; }

			case CMap::tile_grass_fullbackground2:    { return CMap::tile_grass_fullbackground2_d1;}		
			case CMap::tile_grass_fullbackground2_d1: { return CMap::tile_grass_fullbackground2_d2;}
			case CMap::tile_grass_fullbackground2_d2: { return CMap::tile_grass_fullbackground2_d3;}
			case CMap::tile_grass_fullbackground2_d3: { return CMap::tile_ground_back; }

			case CMap::tile_grass_cornerbackground:    { return CMap::tile_grass_cornerbackground_d1;}		
			case CMap::tile_grass_cornerbackground_d1: { return CMap::tile_grass_cornerbackground_d2;}
			case CMap::tile_grass_cornerbackground_d2: { return CMap::tile_grass_cornerbackground_d3;}
			case CMap::tile_grass_cornerbackground_d3: { return CMap::tile_ground_back; }	

			case CMap::tile_grass_3sidesbackground:
			case CMap::tile_grass_3sidesbackground_d1:
			case CMap::tile_grass_3sidesbackground_d2: { return oldTileType + 1;}
			case CMap::tile_grass_3sidesbackground_d3: { return CMap::tile_ground_back; } 

			case CMap::tile_grass_onesidebackground:
			case CMap::tile_grass_onesidebackground_d1:
			case CMap::tile_grass_onesidebackground_d2: { return oldTileType + 1;}
			case CMap::tile_grass_onesidebackground_d3: { return CMap::tile_ground_back; }

			//GOLDEN BRICK
			case CMap::tile_goldenbrick:   {OnGoldTileHit(map, index); return CMap::tile_goldenbrick_d0;}		
			case CMap::tile_goldenbrick_d0:
			case CMap::tile_goldenbrick_d1:
			case CMap::tile_goldenbrick_d2:
			case CMap::tile_goldenbrick_d3:
			case CMap::tile_goldenbrick_d4:
			case CMap::tile_goldenbrick_d5:
			case CMap::tile_goldenbrick_d6: {OnGoldTileHit(map, index); return oldTileType + 1;}		
			case CMap::tile_goldenbrick_d7: {OnGoldTileDestroyed(map, index); return CMap::tile_empty;}

			//STEEL BRICK
			case CMap::tile_steelbrick: {OnSteelTileHit(map, index); return CMap::tile_steelbrick_d0;}		
			case CMap::tile_steelbrick_d0:
			case CMap::tile_steelbrick_d1:
			case CMap::tile_steelbrick_d2:
			case CMap::tile_steelbrick_d3:
			case CMap::tile_steelbrick_d4:
			case CMap::tile_steelbrick_d5:
			case CMap::tile_steelbrick_d6:
			case CMap::tile_steelbrick_d7:
			case CMap::tile_steelbrick_d8:
			case CMap::tile_steelbrick_d9:
			case CMap::tile_steelbrick_d10: {OnSteelTileHit(map, index); return oldTileType + 1;}		
			case CMap::tile_steelbrick_d11: { OnSteelTileDestroyed(map, index); return CMap::tile_empty;}	

			//STEEL BRICK
			case CMap::tile_steelore: {OnSteelTileHit(map, index); return CMap::tile_steelore_d0;}	
			case CMap::tile_steelore_d0:
			case CMap::tile_steelore_d1:
			case CMap::tile_steelore_d2:
			case CMap::tile_steelore_d3:
			case CMap::tile_steelore_d4:{OnSteelTileHit(map, index); return oldTileType + 1;}		
			case CMap::tile_steelore_d5: { OnSteelTileDestroyed(map, index); return CMap::tile_empty;}		

			//BLOOD DIRT
			case CMap::tile_littlebloodground:    { return CMap::tile_littlebloodground_d1;}		
			case CMap::tile_littlebloodground_d0:
			case CMap::tile_littlebloodground_d1:
			case CMap::tile_littlebloodground_d2: { return oldTileType + 1; }		
			case CMap::tile_littlebloodground_d3: { return CMap::tile_empty; }	

			case CMap::tile_mediumbloodground: 	  { return CMap::tile_mediumbloodground_d1;}		
			case CMap::tile_mediumbloodground_d0:
			case CMap::tile_mediumbloodground_d1:
			case CMap::tile_mediumbloodground_d2: { return oldTileType + 1; }		
			case CMap::tile_mediumbloodground_d3: { return CMap::tile_empty; }

			case CMap::tile_heapsbloodground: 	 { return CMap::tile_heapsbloodground_d1;}		
			case CMap::tile_heapsbloodground_d0:
			case CMap::tile_heapsbloodground_d1:
			case CMap::tile_heapsbloodground_d2: { return oldTileType + 1; }		
			case CMap::tile_heapsbloodground_d3: { return CMap::tile_empty; }
			
			case CMap::tile_littlebloodgrass: { return CMap::tile_littlebloodgrass_d0;}
			case CMap::tile_littlebloodgrass_d0: { return CMap::tile_littlebloodground_d1;}

			case CMap::tile_mediumbloodgrass: { return CMap::tile_mediumbloodgrass_d0;}
			case CMap::tile_mediumbloodgrass_d0: { return CMap::tile_mediumbloodground_d1;}	

			case CMap::tile_heapsbloodgrass: { return CMap::tile_heapsbloodgrass_d0;}
			case CMap::tile_heapsbloodgrass_d0: { return CMap::tile_heapsbloodground_d1;}
		}
	}
	return map.getTile(index).type;
}

void onSetTile(CMap@ map, u32 index, TileType tile_new, TileType tile_old)
{
	//switch(tile_new)
	//{
	//	case CMap::tile_empty:
	//	map.RemoveTileFlag(index, Tile::SOLID | Tile::COLLISION);
	//	break;
	//}

	if (map.getTile(index).type == 23 || map.getTile(index).type == 24) //grassy ground not updating properly
	{
		map.SetTileSupport(index, 10);
		{
			map.RemoveTileFlag( index, Tile::BACKGROUND | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
			map.AddTileFlag( index, Tile::SOLID | Tile::COLLISION );
			
			if(XORRandom(2) == 0)
			map.AddTileFlag( index, Tile::MIRROR );
		}
	}

	if (map.getTile(index).type > 255) //custom solids
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			
			//grass on dirt backwall
			case CMap::tile_grass_fullbackground1:    
			case CMap::tile_grass_fullbackground1_d1: 
			case CMap::tile_grass_fullbackground1_d2: 
			case CMap::tile_grass_fullbackground1_d3:
			case CMap::tile_grass_fullbackground2:
			case CMap::tile_grass_fullbackground2_d1:
			case CMap::tile_grass_fullbackground2_d2: 
			case CMap::tile_grass_fullbackground2_d3:
			case CMap::tile_grass_cornerbackground:   
			case CMap::tile_grass_cornerbackground_d1:
			case CMap::tile_grass_cornerbackground_d2:
			case CMap::tile_grass_cornerbackground_d3:
			case CMap::tile_grass_3sidesbackground:
			case CMap::tile_grass_3sidesbackground_d1:
			case CMap::tile_grass_3sidesbackground_d2:
			case CMap::tile_grass_3sidesbackground_d3:
			case CMap::tile_grass_onesidebackground:
			case CMap::tile_grass_onesidebackground_d1:
			case CMap::tile_grass_onesidebackground_d2: 
			case CMap::tile_grass_onesidebackground_d3: 
			// bloody grass
			case CMap::tile_littlebloodgrass:
			case CMap::tile_littlebloodgrass_d0:
			case CMap::tile_littlebloodgrass_d1:
			case CMap::tile_littlebloodgrass_d2:
			case CMap::tile_mediumbloodgrass:
			case CMap::tile_mediumbloodgrass_d0:
			case CMap::tile_mediumbloodgrass_d1:
			case CMap::tile_mediumbloodgrass_d2:
			case CMap::tile_heapsbloodgrass:
			case CMap::tile_heapsbloodgrass_d0:
			case CMap::tile_heapsbloodgrass_d1:
			case CMap::tile_heapsbloodgrass_d2:
			{
				map.RemoveTileFlag( index, Tile::SOLID | Tile::COLLISION );
				map.AddTileFlag( index, Tile::BACKGROUND | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES );
				break;
			}
			
			// golden brick
			case CMap::tile_goldenbrick:
			{
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES |Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				if (getNet().isClient()) Sound::Play("build_wall.ogg", map.getTileWorldPosition(index), 1.0f, 0.6f);
				break;
			}
			case CMap::tile_goldenbrick_d0:
			case CMap::tile_goldenbrick_d1:
			case CMap::tile_goldenbrick_d2:
			case CMap::tile_goldenbrick_d3:
			case CMap::tile_goldenbrick_d4:
			case CMap::tile_goldenbrick_d5:
			case CMap::tile_goldenbrick_d6:
			case CMap::tile_goldenbrick_d7:
			{
				OnGoldTileHit(map, index);
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES |Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			}

			// steel brick
			case CMap::tile_steelbrick:
			{
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES |Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				if (getNet().isClient()) Sound::Play("build_wall2.ogg", map.getTileWorldPosition(index), 1.0f, 1.0f);
				break;
			}
			case CMap::tile_steelbrick_d0:
			case CMap::tile_steelbrick_d1:
			case CMap::tile_steelbrick_d2:
			case CMap::tile_steelbrick_d3:
			case CMap::tile_steelbrick_d4:
			case CMap::tile_steelbrick_d5:
			case CMap::tile_steelbrick_d6:
			case CMap::tile_steelbrick_d7:
			case CMap::tile_steelbrick_d8:
			case CMap::tile_steelbrick_d9:
			case CMap::tile_steelbrick_d10:
			{
				OnGoldTileHit(map, index);
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES |Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			}

			case CMap::tile_steelore_d0:
			case CMap::tile_steelore_d1:
			case CMap::tile_steelore_d2:
			case CMap::tile_steelore_d3:
			case CMap::tile_steelore_d4:
			case CMap::tile_steelore_d5:
			{
				OnSteelTileHit(map, index);
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES |Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			}

			// blood ground
			case CMap::tile_littlebloodground:
			case CMap::tile_littlebloodground_d0:
			case CMap::tile_littlebloodground_d1:
			case CMap::tile_littlebloodground_d2:
			case CMap::tile_littlebloodground_d3:
			case CMap::tile_littlebloodgrassground:
			case CMap::tile_littlebloodgrassground_d0:

			case CMap::tile_mediumbloodground:
			case CMap::tile_mediumbloodground_d0:
			case CMap::tile_mediumbloodground_d1:
			case CMap::tile_mediumbloodground_d2:
			case CMap::tile_mediumbloodground_d3:
			case CMap::tile_mediumbloodgrassground:
			case CMap::tile_mediumbloodgrassground_d0:

			case CMap::tile_heapsbloodground:
			case CMap::tile_heapsbloodground_d0:
			case CMap::tile_heapsbloodground_d1:
			case CMap::tile_heapsbloodground_d2:
			case CMap::tile_heapsbloodground_d3:
			case CMap::tile_heapsbloodgrassground:
			case CMap::tile_heapsbloodgrassground_d0:
			{
				map.RemoveTileFlag( index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE );
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			}

			
		}
	}
	
	if(isDummyTile(tile_new))
	{
		map.SetTileSupport(index, 10);

		switch(tile_new)
		{
			case Dummy::SOLID:
			case Dummy::OBSTRUCTOR:
				map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
				break;
			case Dummy::BACKGROUND:
			case Dummy::OBSTRUCTOR_BACKGROUND:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
				break;
			case Dummy::LADDER:
				map.AddTileFlag(index, Tile::BACKGROUND | Tile::LIGHT_PASSES | Tile::LADDER | Tile::WATER_PASSES);
				break;
			case Dummy::PLATFORM:
				map.AddTileFlag(index, Tile::PLATFORM);
				break;
		}
	}
}

void OnGoldTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag( index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::BACKGROUND );
	
	if (getNet().isClient())
	{ 
		Vec2f pos = map.getTileWorldPosition(index);
		goldtilesparks(pos, -180+XORRandom(180), 1.0f);
	
		Sound::Play("HitSolidMetal.ogg", pos, 0.5f, 0.5f+(XORRandom(10)*0.002));
	}
}

void OnGoldTileDestroyed(CMap@ map, u32 index)
{
	if (getNet().isClient())
	{ 
		Vec2f pos = map.getTileWorldPosition(index);
	
		Sound::Play("HitSolidMetal.ogg", pos, 0.5f, 0.5f+(XORRandom(10)*0.002));
	}
}

void OnSteelTileHit(CMap@ map, u32 index)
{
	map.AddTileFlag(index, Tile::SOLID | Tile::COLLISION);
	map.RemoveTileFlag( index, Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::BACKGROUND );
	
	if (getNet().isClient())
	{ 
		Vec2f pos = map.getTileWorldPosition(index);
		steeltilesparks(pos, -180+XORRandom(180), 1.0f);
	
		Sound::Play("dig_metal"+ (XORRandom(3) + 1)+".ogg", pos, 0.5f, 1.0f);
	}
}

void OnSteelTileDestroyed(CMap@ map, u32 index)
{
	if (getNet().isClient())
	{ 
		Vec2f pos = map.getTileWorldPosition(index);
	
		Sound::Play("dig_metal"+ (XORRandom(3) + 1)+".ogg", pos, 0.5f, 1.0f);
	}
}
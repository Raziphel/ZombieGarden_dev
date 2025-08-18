#include "CustomBlocks.as";

void GrowGrass(CParticle@ p)
{
    Vec2f tilepos = p.position + Vec2f(0,-4);
    Vec2f belowtilepos = p.position + Vec2f(0,4);
    CMap@ map = getMap();
    TileType tileatpos = map.getTile( tilepos ).type;
    TileType tilebelow = map.getTile( belowtilepos ).type;

    if (XORRandom(20) == 0)
    {
         if (map.isTileGround(tilebelow))
        {
            Vec2f tilespace = map.getTileSpacePosition(belowtilepos);
            int offset = map.getTileOffsetFromTileSpace(tilespace);

            map.server_SetTile(belowtilepos, CMap::tile_ground+7+XORRandom(2));           
            //map.RemoveTileFlag( offset, Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
            //map.AddTileFlag( offset, Tile::SOLID | Tile::COLLISION );
        }
        else if (tilebelow == CMap::tile_ground+7 || tilebelow == CMap::tile_ground+8) // grassy ground below
        {            
            Vec2f tilespace = map.getTileSpacePosition(tilepos);
            int offset = map.getTileOffsetFromTileSpace(tilespace);

            switch(tileatpos)
            {
                case CMap::tile_ground_back:    
                case CMap::tile_ground_back+1: 
                case CMap::tile_ground_back+2:
                case CMap::tile_ground_back+3:
                case CMap::tile_ground_back+4:
                case CMap::tile_ground_back+5:
                { map.server_SetTile(tilepos, CMap::tile_grass_fullbackground1_d3 + XORRandom(2)); break; }

                case CMap::tile_grass_fullbackground1_d3:    
                case CMap::tile_grass_fullbackground2_d3:
                { map.server_SetTile(tilepos, CMap::tile_grass_fullbackground1_d2 + XORRandom(2)); break; }

                case CMap::tile_grass_fullbackground1_d2:    
                case CMap::tile_grass_fullbackground2_d2:
                { map.server_SetTile(tilepos, CMap::tile_grass_fullbackground1_d1 + XORRandom(2)); break; }

                case CMap::tile_grass_fullbackground1_d1:    
                case CMap::tile_grass_fullbackground2_d1:
                { map.server_SetTile(tilepos, CMap::tile_grass_fullbackground1 + XORRandom(2)); break; }                

                case  CMap::tile_empty: { map.server_SetTile(tilepos, CMap::tile_grass+3); break;} 
                case  CMap::tile_grass+3: { map.server_SetTile(tilepos, CMap::tile_grass+2); break;}   
                case  CMap::tile_grass+2: { map.server_SetTile(tilepos, CMap::tile_grass+1); break;}
                case  CMap::tile_grass+1: { map.server_SetTile(tilepos, CMap::tile_grass); break;}         
            }

            //map.RemoveTileFlag( offset, Tile::SOLID | Tile::COLLISION );
            //map.AddTileFlag( offset, Tile::BACKGROUND | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES | Tile::WATER_PASSES );
        }
    }   
}

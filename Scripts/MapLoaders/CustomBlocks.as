#include "LoaderUtilities.as";

namespace custom_colors
{
	enum color
	{
		// color_goldenbrick = 0xfffea01e, //(255, 254, 160, 30)
		color_ironore = 0xff64483a,
		color_coalore = 0xff151716,
		color_copperore = 0xffd57d03,
		color_bloodground = 0xffb73333,
		color_bloodgrass = 0xff647814,
	}
};

namespace CMap
{
	enum CustomTiles
	{
		// backgounds //
		tile_grass_fullbackground1 = 401,
		tile_grass_fullbackground2 = 402,
		tile_grass_fullbackground1_d1 = 403,
		tile_grass_fullbackground2_d1 = 404,
		tile_grass_fullbackground1_d2 = 405,
		tile_grass_fullbackground2_d2 = 406,
		tile_grass_fullbackground1_d3 = 407,
		tile_grass_fullbackground2_d3 = 408,

		tile_grass_cornerbackground = 409,
		tile_grass_cornerbackground_d1 = 410,
		tile_grass_cornerbackground_d2 = 411,
		tile_grass_cornerbackground_d3 = 412,

		tile_grass_3sidesbackground = 413,
		tile_grass_3sidesbackground_d1 = 414,
		tile_grass_3sidesbackground_d2 = 415,
		tile_grass_3sidesbackground_d3 = 416,

		tile_grass_onesidebackground = 396,
		tile_grass_onesidebackground_d1 = 397,
		tile_grass_onesidebackground_d2 = 398,
		tile_grass_onesidebackground_d3 = 399,

		tile_littlebloodgrass = 384,
		tile_littlebloodgrass_d0 = 385,
		tile_littlebloodgrass_d1 = 386,
		tile_littlebloodgrass_d2 = 387,

		tile_mediumbloodgrass = 388,
		tile_mediumbloodgrass_d0 = 389,
		tile_mediumbloodgrass_d1 = 390,
		tile_mediumbloodgrass_d2 = 391,

		tile_heapsbloodgrass = 392,
		tile_heapsbloodgrass_d0 = 393,
		tile_heapsbloodgrass_d1 = 394,
		tile_heapsbloodgrass_d2 = 395,

		tile_goldbackwall = 416,
		tile_goldbackwall_d0 = 417,
		tile_goldbackwall_d1 = 418,
		tile_goldbackwall_d2 = 419,
		tile_goldbackwall_d3 = 420,
		tile_goldbackwall_d4 = 421,
		tile_goldbackwall_d5 = 422,
		tile_goldbackwall_d6 = 423,

		tile_ironbackwall = 424,
		tile_ironbackwall_d0 = 425,
		tile_ironbackwall_d1 = 426,
		tile_ironbackwall_d2 = 427,
		tile_ironbackwall_d3 = 428,
		tile_ironbackwall_d4 = 429,
		tile_ironbackwall_d5 = 430,
		tile_ironbackwall_d6 = 431,

		// solids //
		tile_littlebloodground = 432,
		tile_littlebloodground_d0 = 433,
		tile_littlebloodground_d1 = 434,
		tile_littlebloodground_d2 = 435,
		tile_littlebloodground_d3 = 436,

		tile_mediumbloodground = 437,
		tile_mediumbloodground_d0 = 438,
		tile_mediumbloodground_d1 = 439,
		tile_mediumbloodground_d2 = 440,
		tile_mediumbloodground_d3 = 441,

		tile_heapsbloodground = 442,
		tile_heapsbloodground_d0 = 443,
		tile_heapsbloodground_d1 = 444,
		tile_heapsbloodground_d2 = 445,
		tile_heapsbloodground_d3 = 446,

		tile_goldenbrick = 448,
		tile_goldenbrick_d0 = 449,
		tile_goldenbrick_d1 = 450,
		tile_goldenbrick_d2 = 451,
		tile_goldenbrick_d3 = 452,
		tile_goldenbrick_d4 = 453,
		tile_goldenbrick_d5 = 454,
		tile_goldenbrick_d6 = 455,
		tile_goldenbrick_d7 = 456,

		tile_littlebloodgrassground = 457,
		tile_littlebloodgrassground_d0 = 458,
		tile_mediumbloodgrassground = 459,
		tile_mediumbloodgrassground_d0 = 460,
		tile_heapsbloodgrassground = 461,
		tile_heapsbloodgrassground_d0 = 462,

		tile_ironbrick = 464,
		tile_ironbrick_d0 = 465,
		tile_ironbrick_d1 = 466,
		tile_ironbrick_d2 = 467,
		tile_ironbrick_d3 = 468,
		tile_ironbrick_d4 = 469,
		tile_ironbrick_d5 = 470,
		tile_ironbrick_d6 = 471,
		tile_ironbrick_d7 = 472,
		tile_ironbrick_d8 = 473,
		tile_ironbrick_d9 = 474,
		tile_ironbrick_d10 = 475,
		tile_ironbrick_d11 = 476,

		tile_ironore = 480,
		tile_ironore_d0 = 481,
		tile_ironore_d1 = 482,
		tile_ironore_d2 = 483,
		tile_ironore_d3 = 484,
		tile_ironore_d4 = 485,
		tile_ironore_d5 = 486,
		tile_ironore_d6 = 487,
		tile_ironore_d7 = 488,
		tile_ironore_d8 = 489,

		tile_copperore = 490,
		tile_copperore_d0 = 491,
		tile_copperore_d1 = 492,
		tile_copperore_d2 = 493,
		tile_copperore_d3 = 494,
		tile_copperore_d4 = 495,
		tile_copperore_d5 = 496,
		tile_copperore_d6 = 497,

		tile_coalore = 498,
		tile_coalore_d0 = 499,
		tile_coalore_d1 = 500,
		tile_coalore_d2 = 501,
		tile_coalore_d3 = 502,
		tile_coalore_d4 = 503,
		tile_coalore_d5 = 504,
		tile_coalore_d6 = 505,
	};
};

void HandleCustomTile(CMap @map, int offset, SColor pixel)
{
	switch (pixel.color)
	{
		case custom_colors::color_ironore:
			map.SetTile(offset, CMap::tile_ironore + XORRandom(1));
			map.RemoveTileFlag(offset, Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
			map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION);
			break;

		case custom_colors::color_copperore:
			map.SetTile(offset, CMap::tile_copperore + XORRandom(1));
			map.RemoveTileFlag(offset, Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
			map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION);
			break;

		case custom_colors::color_coalore:
			map.SetTile(offset, CMap::tile_coalore + XORRandom(1));
			map.RemoveTileFlag(offset, Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
			map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION);
			break;

		case custom_colors::color_bloodground:
			map.SetTile(offset, CMap::tile_mediumbloodground);
			map.RemoveTileFlag(offset, Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES);
			map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION);
			break;

		case custom_colors::color_bloodgrass:
			map.SetTile(offset, CMap::tile_mediumbloodgrass);
			map.RemoveTileFlag(offset, Tile::SOLID | Tile::COLLISION);
			map.AddTileFlag(offset, Tile::BACKGROUND | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
			break;
	}
}
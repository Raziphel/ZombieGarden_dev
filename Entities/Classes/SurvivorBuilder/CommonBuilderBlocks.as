// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array, 
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2) 
// Add a new string to PAGE_NAME in 
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);

#include "BuildBlock.as";
#include "Requirements.as";
#include "CustomBlocks.as";


const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks(BuildBlock[][]@ blocks)
{
	CRules@ rules = getRules();
	const bool CTF = rules.gamemode_name == "CTF";
	const bool TTH = rules.gamemode_name == "TTH";
	const bool SBX = rules.gamemode_name == "Sandbox";

	//main blocks
	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block\nBasic building block");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall\nExtra support");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", "$stone_door$", "Stone Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 40);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block\nCheap block\nwatch out for fire!");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall\nCheap extra support");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 1);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", "$wooden_door$", "Wooden Door\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "trap_block", "$trap_block$", "Trap Block\nOnly enemies can pass. Also good for wheeled vehicles.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 15);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "team_bridge", "$team_bridge$", "Trap Bridge\nEnemies fall through this.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
		blocks[0].push_back(b);
	}	
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder\nAnyone can climb it");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform\nOne way platform");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[0].push_back(b);
	}	
	{
		BuildBlock b(0, "spikes", "$spikes$", "Spikes\nPlace on Stone Block\nfor Retracting Trap");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "fire_trap_block", "$fire_trap_block$", "Fire Trap\nStay away from it.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		AddRequirement(b.reqs, "blob", "mat_gold", "Gold", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b( 0, "woodtriangle", "$woodtriangle$", "Wooden Triangle" );
		AddRequirement( b.reqs, "blob", "mat_wood", "Wood", 30 );
		blocks[0].push_back(b);
	}
	{
		BuildBlock b( 0, "stonetriangle", "$stonetriangle$", "Stone Triangle" );
		AddRequirement( b.reqs, "blob", "mat_stone", "Stone", 20 );
		blocks[0].push_back(b);
	}
	{
		BuildBlock b( 0, "goldtriangle", "$goldtriangle$", "Gold Triangle" );
		AddRequirement( b.reqs, "blob", "mat_gold", "Gold", 25 );
		blocks[0].push_back(b);
	}
	{
		BuildBlock b( 0, "irontriangle", "$irontriangle$", "Iron Triangle" );
		AddRequirement( b.reqs, "blob", "mat_ironbar", "Iron Bars", 25 );
		blocks[0].push_back(b);
	}
	{
		AddIconToken( "$IronBrick$", "Sprites/World.png", Vec2f(8,8), CMap::tile_ironbrick);
		BuildBlock b(CMap::tile_ironbrick, "IronBrick", "$IronBrick$", "Iron Block\nStrong Building Block");
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bars", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_door", "$iron_door$", "Iron Door\nVery Strong");
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bars", 40);
		blocks[0].push_back(b);
	}
	{
		AddIconToken( "$GoldBrick$", "Sprites/World.png", Vec2f(8,8), CMap::tile_goldenbrick);
		BuildBlock b(CMap::tile_goldenbrick, "GoldBrick", "$GoldBrick$", "Gold Block\nRich Building Block\nNot Stronger Than Iron");
		AddRequirement(b.reqs, "blob", "mat_gold", "Gold", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "gold_door", "$gold_door$", "Gold Door\nRich Building Block");
		AddRequirement(b.reqs, "blob", "mat_gold", "Gold", 40);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "building", "$building$", "Workshop\nStand in an open space\nand tap this button.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 50);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "altarrevival", "$altarrevival$", "Altar of Revival\nObtain a crystal from a portal\nand tap this button.");
		AddRequirement(b.reqs, "blob", "lifeforce", "Life Force Crystal", 1);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 500);
		AddRequirement(b.reqs, "blob", "mat_gold", "Gold", 100);
		b.buildOnGround = true;
		b.size.Set(64, 64);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "fireplace", "$fireplace$", "fireplace\nOnly gives light!.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 75);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 75);
		b.buildOnGround = true;
		blocks[0].push_back(b);
	}
		
	// devices
	BuildBlock[] page_1;
	blocks.push_back(page_1);
	{
		BuildBlock b(0, "wire", "$wire$", "Wire");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 5);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 2);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "tee", "$tee$", "Tee");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 12);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 8);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 3);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "elbow", "$elbow$", "Elbow");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 12);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 8);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 3);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "junction", "$junction$", "Junction");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 4);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 1);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "diode", "$diode$", "Diode");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 15);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 3);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "resistor", "$resistor$", "Resistor");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 15);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 2);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "inverter", "$inverter$", "Inverter");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 4);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "oscillator", "$oscillator$", "Oscillator");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 35);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 6);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 2);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "transistor", "$transistor$", "Transistor");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 15);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 10);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 3);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 1);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "toggle", "$toggle$", "Toggle");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 4);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "randomizer", "$randomizer$", "Randomizer");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 5);
		blocks[1].push_back(b);
	}

	BuildBlock[] page_2;
	blocks.push_back(page_2);
	{
		BuildBlock b(0, "lever", "$lever$", "Lever");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 20);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 2);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "push_button", "$push_button$", "Button");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 12);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 2);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "coin_slot", "$coin_slot$", "Coin Slot");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 12);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 25);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 2);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 1);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "pressure_plate", "$pressure_plate$", "Pressure Plate");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 2);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "sensor", "$sensor$", "Motion Sensor");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 15);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 4);
		blocks[2].push_back(b);
	}

	BuildBlock[] page_3;
	blocks.push_back(page_3);
	{
		BuildBlock b(0, "lamp", "$lamp$", "Lamp");
		AddRequirement(b.reqs, "blob", "mat_wood",      "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 15);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 1);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "emitter", "$emitter$", "Emitter");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 35);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 6);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 2);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "receiver", "$receiver$", "Receiver");
		AddRequirement(b.reqs, "blob", "mat_stone",     "Stone", 35);
		AddRequirement(b.reqs, "blob", "mat_copperbar", "Copper Bar", 6);
		AddRequirement(b.reqs, "blob", "mat_ironbar",   "Iron Bar", 2);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "magazine", "$magazine$", "Magazine");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 30);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 4);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "bolter", "$bolter$", "Bolter");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 20);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 6);
		AddRequirement(b.reqs, "blob", "mat_copperbar","Copper Bar", 2);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "dispenser", "$dispenser$", "Dispenser");
		AddRequirement(b.reqs, "blob", "mat_wood",     "Wood", 20);
		AddRequirement(b.reqs, "blob", "mat_stone",    "Stone", 30);
		AddRequirement(b.reqs, "blob", "mat_ironbar",  "Iron Bar", 4);
		AddRequirement(b.reqs, "blob", "mat_copperbar","Copper Bar", 3);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "obstructor", "$obstructor$", "Obstructor");
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 50);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 8);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "spiker", "$spiker$", "Spiker");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 25);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 40);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 6);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "flamer", "$flamer$", "Flamer");
		AddRequirement(b.reqs, "blob", "mat_wood",     "Wood", 20);
		AddRequirement(b.reqs, "blob", "mat_stone",    "Stone", 35);
		AddRequirement(b.reqs, "blob", "mat_ironbar",  "Iron Bar", 6);
		AddRequirement(b.reqs, "blob", "mat_copperbar","Copper Bar", 4);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "booster", "$booster$", "Bouncer");
		AddRequirement(b.reqs, "blob", "mat_wood",     "Wood", 10);
		AddRequirement(b.reqs, "blob", "mat_stone",    "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_copperbar","Copper Bar", 3);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "conveyor", "$conveyor$", "Conveyor");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 12);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 20);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 5);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "conveyortriangle", "$conveyortriangle$", "Conveyor Triangle");
		AddRequirement(b.reqs, "blob", "mat_wood",    "Wood", 6);
		AddRequirement(b.reqs, "blob", "mat_stone",   "Stone", 12);
		AddRequirement(b.reqs, "blob", "mat_ironbar", "Iron Bar", 2);
		blocks[3].push_back(b);
	}
}
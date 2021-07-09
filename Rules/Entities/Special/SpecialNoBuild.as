// this was for falling dirt tiles
#include "AddTilesBySector.as";

#define SERVER_ONLY

// set this.set_TileType("background tile", CMap::tile_castle_back);

//use back flag to indicate no background

const string counter = "nobuild counter";
const string back = "background tile";
const string nobuild_extend = "nobuild extend";
const int CHECK_FREQ = 35;

void onInit(CBlob@ this)
{
	this.set_u8(counter, 1);
	this.getCurrentScript().tickFrequency = 5;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (this.getCurrentScript().tickFrequency != CHECK_FREQ)
	{
		u8 c = this.get_u8(counter);
		if (c > 0)
		{
			c--;
			this.set_u8(counter, c);
			return;
		}

		Vec2f ul, lr;
		Vec2f extend;
		if (this.exists(nobuild_extend))
		{
			extend = this.get_Vec2f(nobuild_extend);
		}

		this.getShape().getBoundingRect(ul, lr);
		ul.x += 6.0f;
		ul.y += 6.0f;

		lr += extend;
		this.getMap().server_AddSector(ul, lr, "no build", "", this.getNetworkID());
		lr -= extend;

		if (this.exists(back))
		{
			AddTilesBySector(ul, lr, "no build", this.get_TileType(back), CMap::tile_castle_back);
		}
		else
		{
			this.getCurrentScript().runFlags |= Script::remove_after_this;
		}

		this.getCurrentScript().tickFrequency = CHECK_FREQ;
	}
}


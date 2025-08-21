#include "PlacementCommon.as"

void onInit(CBlob @ this)
{
	BlockCursor @cursor;
	this.get("blockCursor", @cursor);
	if (cursor is null)
	{
		BlockCursor tempCursor;
		this.set("blockCursor", @tempCursor);
	}
}

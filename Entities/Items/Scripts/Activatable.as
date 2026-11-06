// Compatibility bridge for older Zombie Garden items.
// Modern KAG activates carried items through the "activate handle" callback.
#include "ActivationThrowCommon.as";

void onInit(CBlob @ this)
{
	this.Tag("activatable");
	this.addCommandID("activate");

	Activate @callback = @ZGActivateLegacyItem;
	this.set("activate handle", @callback);
}

// Forward the authoritative activation to the item's existing onCommand
// handler, keeping Lantern, Satchel, and other older item behavior intact.
void ZGActivateLegacyItem(CBitStream @params)
{
	if (!isServer() || params is null)
		return;

	u16 itemID;
	if (!params.saferead_u16(itemID))
		return;

	CBlob @item = getBlobByNetworkID(itemID);
	if (item is null || !item.hasTag("activatable"))
		return;

	CBitStream commandParams;
	item.SendCommand(item.getCommandID("activate"), commandParams);
}

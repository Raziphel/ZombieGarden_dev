// Storage

const Vec2f STORAGE_SIZE(20, 6);
string LAST_LABEL;

void onInit(CBlob @ this)
{
	this.addCommandID("storage in");
	this.addCommandID("storage out");
	this.addCommandID("shipment");
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("storage out"))
	{
		if (!isServer() || params is null)
			return;

		// The client supplies a selected item, not the identity of the buyer.
		// Resolve the authenticated sender and their current player blob.
		CPlayer @player = getNet().getActiveCommandPlayer();
		if (player is null)
			return;
		CBlob @caller = player.getBlob();
		if (!canAccessStorage(this, caller))
			return;

		u16 claimedCaller;
		u16 itemID;
		if (!params.saferead_netid(claimedCaller) ||
			!params.saferead_netid(itemID) ||
			claimedCaller != caller.getNetworkID())
			return;

		CBlob @item = getBlobByNetworkID(itemID);
		if (item is null || !item.isInInventory())
			return;

		// A linked menu includes items from other allied chests. Transfer
		// from the *actual* item owner, never an unrelated terminal.
		CBlob @source = item.getInventoryBlob();
		if (source is null || source.getName() != "storage" ||
			source.getTeamNum() != this.getTeamNum() ||
			source.getInventory() is null)
			return;

		source.server_PutOutInventory(item);
		item.setPosition(caller.getPosition());
		if (!caller.server_PutInInventory(item))
			caller.server_Pickup(item);
	}
	else if (cmd == this.getCommandID("shipment") && isClient())
	{
		CBlob @localBlob = getLocalPlayerBlob();
		if (localBlob !is null && localBlob.getTeamNum() == this.getTeamNum())
			client_AddToChat("Supplies will drop at your storage.");
	}
}

bool canAccessStorage(CBlob @ this, CBlob @caller)
{
	return this !is null && caller !is null &&
		!caller.hasTag("dead") &&
		caller.getTeamNum() == this.getTeamNum() &&
		(this.getPosition() - caller.getPosition()).Length() < 18.0f;
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (canAccessStorage(this, caller))
		BuildSharedInventory(this, caller);
}

CGridButton @addItem(CGridMenu @menu, CBlob @caller, CBlob @item, u8 cmdID)
{
	CBitStream params;
	params.write_netid(caller.getNetworkID());
	params.write_netid(item !is null ? item.getNetworkID() : 0);
	return menu.AddItemButton(item, cmdID, params);
}

void BuildSharedInventory(CBlob @ this, CBlob @caller, CBlob @justAddedBlob = null)
{
	if (caller !is null && caller.isMyPlayer())
	{
		// caller.ClearMenus();

		CBlob @[] storages;
		getBlobsByName("storage", @storages);
		uint count = 0;
		for (uint step = 0; step < storages.length; ++step)
		{
			CBlob @storage = storages[step];
			if (storage !is null && storage.getTeamNum() == this.getTeamNum())
				count++;
		}

		if (count <= 1)
		{
			LAST_LABEL = "Storage";
		}
		else
		{
			LAST_LABEL = "Shared items from " + count + " storages";
		}

		CGridMenu @menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, 180.0f), this, STORAGE_SIZE, LAST_LABEL);
		if (menu !is null)
		{
			menu.deleteAfterClick = false;

			// add all storages items

			for (uint step = 0; step < storages.length; ++step)
			{
				CBlob @storage = storages[step];
				if (storage is null || storage.getTeamNum() != this.getTeamNum())
					continue;

				CInventory @inv = storage.getInventory();
				if (inv is null)
					continue;

				for (int i = 0; i < inv.getItemsCount(); ++i)
				{
					CBlob @item = inv.getItem(i);
					if (item !is null)
						addItem(menu, caller, item, this.getCommandID("storage out"));
				}
			}

			if (justAddedBlob !is null)
			{
				addItem(menu, caller, justAddedBlob, this.getCommandID("storage out"));
			}

			// click anywhere = put item or close t
			// this is done in engine somehow :/

			// CBlob@ carried = caller.getCarriedBlob();
			////( menu, caller, carried, this.getCommandID("storage in") );
		}
	}
}

void onAddToInventory(CBlob @ this, CBlob @blob)
{
	CBlob @localBlob = getLocalPlayerBlob();

	CGridMenu @menu = getGridMenuByName(LAST_LABEL);
	if (menu !is null && canAccessStorage(this, localBlob))
	{
		BuildSharedInventory(this, localBlob, blob);
	}

	this.getSprite().PlaySound("/StoreSound");
}

void onRemoveFromInventory(CBlob @ this, CBlob @blob)
{
	CGridMenu @menu = getGridMenuByName(LAST_LABEL);
	if (menu !is null)
	{
		BuildSharedInventory(this, getLocalPlayerBlob());
	}
}

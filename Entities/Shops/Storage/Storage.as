// Storage.as

void onInit(CSprite @ this)
{
	// Building
	this.SetZ(-60); //-60 instead of -50 so sprite layers are behind ladders

	// Stone
	CSpriteLayer @stone = this.addSpriteLayer("mat_stone", "StorageLayers.png", 24, 16);
	if (stone !is null)
	{
		{
			stone.addAnimation("default", 0, false);
			int[] frames = {0, 5, 10};
			stone.animation.AddFrames(frames);
		}
		stone.SetOffset(Vec2f(10.0f, -3.0f));
		stone.SetRelativeZ(1);
		stone.SetVisible(false);
	}

	// Wood
	CSpriteLayer @wood = this.addSpriteLayer("mat_wood", "StorageLayers.png", 24, 16);
	if (wood !is null)
	{
		{
			wood.addAnimation("default", 0, false);
			int[] frames = {1, 6, 11};
			wood.animation.AddFrames(frames);
		}
		wood.SetOffset(Vec2f(-7.0f, -2.0f));
		wood.SetRelativeZ(1);
		wood.SetVisible(false);
	}

	// Gold
	CSpriteLayer @gold = this.addSpriteLayer("mat_gold", "StorageLayers.png", 24, 16);
	if (gold !is null)
	{
		{
			gold.addAnimation("default", 0, false);
			int[] frames = {2, 7, 12};
			gold.animation.AddFrames(frames);
		}
		gold.SetOffset(Vec2f(-7.0f, -10.0f));
		gold.SetRelativeZ(1);
		gold.SetVisible(false);
	}

	// Bombs
	CSpriteLayer @bombs = this.addSpriteLayer("mat_bombs", "StorageLayers.png", 24, 16);
	if (bombs !is null)
	{
		{
			bombs.addAnimation("default", 0, false);
			int[] frames = {3, 8};
			bombs.animation.AddFrames(frames);
		}
		bombs.SetOffset(Vec2f(-7.0f, 5.0f));
		bombs.SetRelativeZ(2);
		bombs.SetVisible(false);
	}

	// Rope
	CSpriteLayer @rope = this.addSpriteLayer("rope", "StorageLayers.png", 24, 16);
	if (rope !is null)
	{
		{
			rope.addAnimation("default", 0, false);
			int[] frames = {4};
			rope.animation.AddFrames(frames);
		}
		rope.SetOffset(Vec2f(5.0f, -8.0f));
		rope.SetRelativeZ(2);
	}
}

void onInit(CBlob @ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	AddIconToken("$store_inventory$", "InteractionIcons.png", Vec2f(32, 32), 28);
	this.inventoryButtonPos = Vec2f(12, 0);
	this.addCommandID("store inventory");
	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBlob @ this)
{
	PickupOverlap(this);
}

void PickupOverlap(CBlob @ this)
{
	if (isServer())
	{
		CShape @shape = this.getShape();
		CMap @map = this.getMap();
		if (shape is null || map is null)
			return;

		Vec2f tl, br;
		shape.getBoundingRect(tl, br);
		CBlob @[] blobs;
		map.getBlobsInBox(tl, br, @blobs);
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob @blob = blobs[i];
			if (blob !is null && !blob.isAttached() && blob.isOnGround() && blob.hasTag("material") && blob.getName() != "mat_arrows")
			{
				this.server_PutInInventory(blob);
			}
		}
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (caller is null)
		return;

	u8 kek = caller.getTeamNum();
	if (kek == 0)
	{
		if (caller.getTeamNum() == this.getTeamNum() && caller.isOverlapping(this))
		{
			CInventory @inv = caller.getInventory();
			if (inv is null)
				return;

			if (inv.getItemsCount() > 0)
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				caller.CreateGenericButton("$store_inventory$", Vec2f(-6, 0), this, this.getCommandID("store inventory"), "Store", params);
			}
		}
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (!isServer() || cmd != this.getCommandID("store inventory"))
		return;

	// Command payloads are client-controlled. Resolve the authenticated
	// sender on the server, and verify actual proximity and team access.
	CPlayer @player = getNet().getActiveCommandPlayer();
	if (player is null || this.getHealth() <= 0.0f)
		return;

	CBlob @caller = player.getBlob();
	if (caller is null || caller.hasTag("dead") ||
		caller.getTeamNum() != this.getTeamNum() || !caller.isOverlapping(this))
		return;

	CInventory @inv = caller.getInventory();
	CInventory @storageInv = this.getInventory();
	if (inv is null || storageInv is null)
		return;

	// The builder's temporary placement preview must never enter storage.
	// Preserve this anti-duplication cleanup, but only after verifying the
	// actual command sender owns the nearby character.
	if (caller.getConfig() == "builder")
	{
		CBlob @carried = caller.getCarriedBlob();
		if (carried !is null && carried.hasTag("temp blob"))
			carried.server_Die();
	}

	// A single request may only process the items present when it began,
	// preventing infinite loops if a transfer cannot complete.
	const int initialCount = inv.getItemsCount();
	for (int i = 0; i < initialCount && inv.getItemsCount() > 0; ++i)
	{
		CBlob @item = inv.getItem(0);
		if (item is null)
			break;

		// Never destroy a carried building preview as a side effect of
		// storing unrelated materials.
		caller.server_PutOutInventory(item);
		if (!this.server_PutInInventory(item))
		{
			// Full storage: put the item back. Do not silently eat it.
			if (!caller.server_PutInInventory(item))
				item.setPosition(caller.getPosition());
			break;
		}
	}
}

void onAddToInventory(CBlob @ this, CBlob @blob)
{
	updateLayers(this, blob);
}

void onRemoveFromInventory(CBlob @ this, CBlob @blob)
{
	updateLayers(this, blob);
}

void updateLayers(CBlob @ this, CBlob @blob)
{
	if (this is null || blob is null)
		return;

	const string blobName = blob.getName();
	if (!checkName(blobName))
	{
		return;
	}
	CSprite @sprite = this.getSprite();
	CInventory @inv = this.getInventory();
	if (inv is null)
		return;
	if (sprite is null && blobName != "lantern" && blobName != "bluelantern")
		return;

	int blobCount = inv.getCount(blobName);
	if (blobName == "mat_stone")
	{
		CSpriteLayer @stone = sprite.getSpriteLayer("mat_stone");
		if (stone is null)
			return;
		if (blobCount > 0)
		{
			if (blobCount >= 200)
			{
				stone.SetFrameIndex(2);
			}
			else if (blobCount >= 100)
			{
				stone.SetFrameIndex(1);
			}
			else
			{
				stone.SetFrameIndex(0);
			}
			stone.SetVisible(true);
		}
		else
		{
			stone.SetVisible(false);
		}
	}
	else if (blobName == "mat_wood")
	{
		CSpriteLayer @wood = sprite.getSpriteLayer("mat_wood");
		if (wood is null)
			return;
		if (blobCount > 0)
		{
			if (blobCount >= 200)
			{
				wood.SetFrameIndex(2);
			}
			else if (blobCount >= 100)
			{
				wood.SetFrameIndex(1);
			}
			else
			{
				wood.SetFrameIndex(0);
			}
			wood.SetVisible(true);
		}
		else
		{
			wood.SetVisible(false);
		}
	}
	else if (blobName == "mat_gold")
	{
		CSpriteLayer @gold = sprite.getSpriteLayer("mat_gold");
		if (gold is null)
			return;
		if (blobCount > 0)
		{
			if (blobCount >= 200)
			{
				gold.SetFrameIndex(2);
			}
			else if (blobCount >= 100)
			{
				gold.SetFrameIndex(1);
			}
			else
			{
				gold.SetFrameIndex(0);
			}
			gold.SetVisible(true);
		}
		else
		{
			gold.SetVisible(false);
		}
	}
	else if (blobName == "mat_bombs")
	{
		CSpriteLayer @bombs = sprite.getSpriteLayer("mat_bombs");
		if (bombs is null)
			return;
		if (blobCount > 0)
		{
			if (blobCount >= 2)
			{
				bombs.SetFrameIndex(1);
			}
			else
			{
				bombs.SetFrameIndex(0);
			}
			bombs.SetVisible(true);
		}
		else
		{
			bombs.SetVisible(false);
		}
	}
	else if (blobName == "lantern")
	{
		if (blobCount > 0)
		{
			CAttachment @attachments = this.getAttachments();
			AttachmentPoint @point = attachments is null ? null :
				attachments.getAttachmentPointByName("LANTERN");
			if (isServer() && point !is null && point.getOccupied() is null)
			{
				CBlob @lantern = server_CreateBlob("lantern");
				if (lantern !is null)
				{
					lantern.server_setTeamNum(this.getTeamNum());
					lantern.getShape().getConsts().collidable = false;
					this.server_AttachTo(lantern, "LANTERN");
					this.set_u16("lantern id", lantern.getNetworkID());
					Sound::Play("SparkleShort.ogg", lantern.getPosition());
				}
			}
		}
		else
		{
			if (isServer() && this.get_u16("lantern id") != 0)
			{
				CBlob @lantern = getBlobByNetworkID(this.get_u16("lantern id"));
				if (lantern !is null)
					lantern.server_Die();
				this.set_u16("lantern id", 0);
			}
		}
	}
	else if (blobName == "bluelantern")
	{
		if (blobCount > 0)
		{
			CAttachment @attachments = this.getAttachments();
			AttachmentPoint @point = attachments is null ? null :
				attachments.getAttachmentPointByName("LANTERN");
			if (isServer() && point !is null && point.getOccupied() is null)
			{
				CBlob @lantern = server_CreateBlob("bluelantern");
				if (lantern !is null)
				{
					lantern.server_setTeamNum(this.getTeamNum());
					lantern.getShape().getConsts().collidable = false;
					this.server_AttachTo(lantern, "LANTERN");
					this.set_u16("lantern id2", lantern.getNetworkID());
					Sound::Play("SparkleShort.ogg", lantern.getPosition());
				}
			}
		}
		else
		{
			if (isServer() && this.get_u16("lantern id2") != 0)
			{
				CBlob @lantern = getBlobByNetworkID(this.get_u16("lantern id2"));
				if (lantern !is null)
					lantern.server_Die();
				this.set_u16("lantern id2", 0);
			}
		}
	}
}

void onDie(CBlob @ this)
{
	if (!isServer())
		return;

	// Attached lights belong to this chest, not the item that first
	// created them. Clear both even if the chest is destroyed while full.
	const u16 lanternID = this.get_u16("lantern id");
	const u16 blueID = this.get_u16("lantern id2");
	if (lanternID != 0)
	{
		CBlob @lantern = getBlobByNetworkID(lanternID);
		if (lantern !is null)
			lantern.server_Die();
	}
	if (blueID != 0 && blueID != lanternID)
	{
		CBlob @lantern = getBlobByNetworkID(blueID);
		if (lantern !is null)
			lantern.server_Die();
	}
}

bool checkName(string blobName)
{
	return (blobName == "mat_stone" || blobName == "mat_wood" || blobName == "mat_gold" || blobName == "mat_bombs" || blobName == "lantern" || blobName == "bluelantern");
}

bool isInventoryAccessible(CBlob @ this, CBlob @forBlob)
{
	return (forBlob !is null && forBlob.getTeamNum() == this.getTeamNum() &&
		!forBlob.hasTag("dead") && forBlob.isOverlapping(this));
}
void MakeMat(CBlob @ this, Vec2f worldPoint, const string& in name, int quantity)
{
	if (!isServer() || this is null || quantity <= 0)
		return;

	// decide whether to fly it or put directly in inv
	bool putInInv = true;
	int added = 0;

	CInventory @inv = this.getInventory();
	if (inv is null)		   // we dont have an inventory to put it into
	{
		putInInv = false;
		if (this.isAttached()) // do we have a holder?
		{
			CAttachment @attachments = this.getAttachments();
			AttachmentPoint @point = attachments is null ? null :
				attachments.getAttachmentPointByName("PICKUP");
			CBlob @holder = point is null ? null : point.getOccupied();

			if (holder !is null && holder !is this) // we have something holding us, make the mat for it instead
			{
				MakeMat(holder, worldPoint, name, quantity);
				return;
			}
		}
	}
	else
	{
		// find if a mat is already in inv which we can fill in

		for (int i = 0; i < inv.getItemsCount(); i++)
		{
			CBlob @invblob = inv.getItem(i);

			if (invblob !is null && invblob !is this && invblob.getName() == name)
			{
				int spaceLeft = invblob.maxQuantity - invblob.getQuantity();
				if (spaceLeft > 0)
				{
					// Use the unfilled portion, not the original quantity:
					// otherwise several partial stacks duplicate materials.
					int toAdd = Maths::Min(spaceLeft, quantity - added);
					invblob.server_SetQuantity(invblob.getQuantity() + toAdd);
					added += toAdd;
				}
			}

			if (added >= quantity) // we're done
			{
				return;
			}
		}
	}

	quantity -= added;
	if (quantity <= 0) // safety
		return;

	// New stacks must also honour their max quantity. Without splitting,
	// large resource rewards can create oversized stacks or silently lose
	// items when the engine clamps a blob's quantity.
	while (quantity > 0)
	{
		CBlob @mat = server_CreateBlob(name, this.getTeamNum(), worldPoint);
		if (mat is null)
			return;

		const int stackSize = Maths::Min(quantity, Maths::Max(1, int(mat.maxQuantity)));
		mat.server_SetQuantity(stackSize);
		quantity -= stackSize;

		if (!putInInv || !this.server_PutInInventory(mat))
		{
			mat.setPosition(this.getPosition());
			const f32 dir = this.isFacingLeft() ? 1.0f : -1.0f;
			mat.setVelocity(Vec2f(dir, -1.0f) * 0.5f);
		}
	}
}

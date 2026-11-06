const u32 VANISH_BODY_SECS = 10;

void onInit(CBlob @ this)
{
	this.set_f32("hit dmg modifier", 0.0f);
	this.getCurrentScript().tickFrequency = 0; // make it not run ticks until dead
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	// make dead state
	// make sure this script is at the end of onHit scripts for it gets the final health
	if (this.getHealth() <= 0.0f && !this.hasTag("dead"))
	{
		this.Tag("dead");
		this.set_u32("death time", getGameTime());

		// add pickup attachment so we can pickup body
		CAttachment @a = this.getAttachments();

		if (a !is null)
		{
			AttachmentPoint @ap = a.AddAttachmentPoint("PICKUP", false);
		}

		this.getCurrentScript().tickFrequency = 30;

		this.set_f32("hit dmg modifier", 0.5f);

		// Corpses may be destroyed while their physics body is unloading.
		CShape @shape = this.getShape();
		if (shape !is null)
		{
			shape.setFriction(0.75f);
			shape.setElasticity(0.2f);
			shape.getVars().isladder = false;
			shape.getVars().onladder = false;
			shape.checkCollisionsAgain = true;
			shape.SetGravityScale(1.0f);
		}

		// fall out of attachments/seats // drop all held things
		this.server_DetachAll();
	}

	else if (this.hasTag("dead"))
	{
		// Hitting a corpse gives it another moment before vanishing.
		this.set_u32("death time", getGameTime());
	}

	return damage;
}

// Keep the original return-from-the-dead mechanic, but never spawn an
// unlimited chain of revivals or bypass the current living horde cap.
bool TryReviveCorpse(CBlob @corpse)
{
	if (corpse is null || corpse.hasTag("zg_horde_retired"))
		return false;

	CRules @rules = getRules();
	if (rules is null || !rules.isMatchRunning())
		return false;

	const int priorRevives = corpse.get_u8("zg_revive_count");
	const int revivalLimit = Maths::Max(0, rules.get_s32("max_zombie_revivals"));
	if (priorRevives >= revivalLimit)
		return false;

	const string type = corpse.getName();
	// Only creatures that already revived in the old script qualify.
	const bool resurrects =
		type == "zombie" || type == "zombieknight" ||
		type == "zbison" || type == "pzombieknight" ||
		type == "abomination" || type == "rabiddog" ||
		type == "pbrute" || type == "pcrawler" ||
		type == "catto" || type == "zbison2" ||
		type == "zombie2";
	if (!resurrects)
		return false;

	CBlob @[] horde;
	getBlobsByTag("zombie", @horde);
	int living = 0;
	for (uint i = 0; i < horde.length; ++i)
	{
		CBlob @member = horde[i];
		if (member !is null && !member.hasTag("dead"))
			living++;
	}
	if (living >= Maths::Max(0, rules.get_s32("max_zombies")))
		return false;

	const int team = (type == "zbison2" || type == "zombie2") ? 1 : -1;
	CBlob @revived = server_CreateBlob(type, team, corpse.getPosition());
	if (revived is null)
		return false;

	revived.set_u8("zg_revive_count", u8(priorRevives + 1));
	return true;
}

// erase all items before vanishing
void onTick(CBlob @this)
{
	if (!isServer() || this is null || !this.hasTag("dead"))
		return;

	if (this.get_u32("death time") + VANISH_BODY_SECS * getTicksASecond() >= getGameTime())
		return;

	CInventory @inv = this.getInventory();
	if (inv !is null)
	{
		// Inventory entries shift as they are removed. Walk backwards.
		for (int i = inv.getItemsCount() - 1; i >= 0; --i)
		{
			CBlob @item = inv.getItem(i);
			if (item !is null)
				item.server_Die();
		}
	}

	if (this.getName() == "fshark")
	{
		// Original sea-creature transformation, unrelated to zombie revivals.
		server_CreateBlob("shark", 1, this.getPosition());
	}
	else
	{
		TryReviveCorpse(this);
	}
	this.server_Die();
}

// reset vanish counter on pickup

void onAttach(CBlob @ this, CBlob @attached, AttachmentPoint @attachedPoint)
{
	this.set_u32("death time", getGameTime());
}

bool isInventoryAccessible(CBlob @ this, CBlob @forBlob)
{
	if (!this.hasTag("dead") || forBlob is null)
		return false;

	CInventory @inv = this.getInventory();
	return inv !is null && inv.getItemsCount() > 0;
}
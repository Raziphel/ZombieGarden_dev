bool doesCollideWithBlob(CBlob @ this, CBlob @blob)
{
	if (this is null || blob is null || blob is this)
		return false;

	// A corpse collides with static world structures, not living actors.
	if (this.hasTag("dead"))
	{
		CShape @shape = this.getShape();
		CShape @other = blob.getShape();
		if (shape is null || other is null)
			return false;

		const bool moving = shape.vellen >= 1.5f;
		return other.isStatic() &&
			(other.getConsts().collidable ||
			 (moving && !blob.hasTag("player")));
	}

	// Hostile creatures collide with opposing units and defenses; allied
	// undead players may pass through the horde as before.
	return ((this.getTeamNum() != blob.getTeamNum() &&
		!blob.hasTag("undeadplayer")) ||
		blob.hasTag("zombie") ||
		blob.hasTag("door") ||
		blob.hasTag("undeaddoor") ||
		blob.getName() == "wooden_platform");
}

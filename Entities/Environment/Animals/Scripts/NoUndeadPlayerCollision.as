
bool doesCollideWithBlob(CBlob @ this, CBlob @blob)
{
	return ((blob.getControls() is null || !blob.hasTag("undeadplayer")));
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	if (hitterBlob.getTeamNum() == this.getTeamNum())
	{
		return 0;
	}

	return damage;
}
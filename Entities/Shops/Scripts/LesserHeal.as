// Passive building healing runs on the authoritative server only.
void onInit(CBlob @this)
{
	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBlob @this)
{
	if (!isServer() || this is null || this.hasTag("dead"))
		return;

	CMap @map = this.getMap();
	if (map is null)
		return;

	CBlob @[] nearby;
	if (!map.getBlobsInRadius(this.getPosition(), this.getRadius(), @nearby))
		return;

	const u8 team = this.getTeamNum();
	for (uint i = 0; i < nearby.length; ++i)
	{
		CBlob @target = nearby[i];
		if (target is null || target is this || target.hasTag("dead") ||
			target.getTeamNum() != team || !(b.hasTag("survivorplayer") || b.hasTag("undeadplayer")))
			continue;

		const f32 missing = target.getInitialHealth() - target.getHealth();
		if (missing > 0.0f)
		{
			// Never let passive building healing grant overheal.
			target.server_Heal(Maths::Min(missing, 0.5f));
			// Do not call sprite.PlaySound here: this hook only runs on
			// the dedicated server, which may have no sprite.
		}
	}
}

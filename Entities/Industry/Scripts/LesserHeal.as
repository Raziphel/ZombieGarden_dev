void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 45;
}

void onTick(CBlob@ this)
{
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), this.getRadius(), @blobsInRadius))
	{
		const u8 teamNum = this.getTeamNum();
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (this.getTeamNum() == teamNum && b.getHealth() < b.getInitialHealth() && b.hasTag("survivorplayer") && !b.hasTag("dead"))
			{
				b.server_Heal(0.5f);
				b.getSprite().PlaySound("/Heart.ogg");
			}
		}
	}
}

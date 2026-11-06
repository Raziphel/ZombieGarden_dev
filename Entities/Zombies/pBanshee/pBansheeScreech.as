// Aphelion \\

#include "KnockedCommon.as";

u32 SCREECH_INTERVAL = 15 * 30;
f32 SCREECH_DISTANCE = 256.0f;

void Screech(CBlob @ this)
{
	if (this is null)
		return;

	// The sound is local; the knockback is authoritative. Applying the
	// stun in every client's simulation caused unnecessary duplicate work.
	if (isClient())
	{
		CSprite @sprite = this.getSprite();
		if (sprite !is null)
			sprite.PlaySound("/BansheeScreech", 3.0f);
	}

	if (!isServer())
		return;

	CMap @map = this.getMap();
	if (map is null)
		return;

	CBlob @[] nearby;
	map.getBlobsInRadius(this.getPosition(), SCREECH_DISTANCE, @nearby);
	for (uint i = 0; i < nearby.length; ++i)
	{
		CBlob @survivor = nearby[i];
		if (survivor !is null && !survivor.hasTag("dead") &&
			survivor.hasTag("survivorplayer"))
		{
			setKnocked(survivor, 15 + XORRandom(30));
		}
	}
}

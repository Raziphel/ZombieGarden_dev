// Aphelion \\

#include "KnockedCommon.as";

u32 SCREECH_INTERVAL = 30 * 30;
f32 SCREECH_DISTANCE = 60.0f;

void Screech( CBlob@ this )
{
	CBlob@[] nearBlobs;
	this.getMap().getBlobsInRadius( this.getPosition(), SCREECH_DISTANCE, @nearBlobs );
	
	// play annoying sound at three times the volume
	this.getSprite().PlaySound("/BansheeScreech", 3.0f);
	
	for(int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob@ recipent = nearBlobs[step]; // :)
		if    (recipent !is null &&! recipent.hasTag("dead") && recipent.hasTag("survivorplayer"))
		{
            // that was loud!
			setKnocked( recipent, 15 + XORRandom(30) );
		}
	}
}
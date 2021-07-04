// Aphelion \\

#include "FireParticle.as";


void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if    (blob.hasTag("enraged"))
	{
		if (!this.isAnimation("attack"))
			this.SetAnimation("attack");
	
		makeFireParticle(blob.getPosition() + getRandomVelocity(90.0f, 3.0f, 90.0f));
		blob.SetLight(true);
		blob.SetLightRadius(64.0f);
		blob.SetLightColor(SColor(255, 120, 50, 140));
	}
	else if(!blob.isOnGround() && !blob.isOnLadder()) 
	{
		if (!this.isAnimation("fly"))
			this.SetAnimation("fly");
	}
	else if (!this.isAnimation("walk"))
			 this.SetAnimation("walk");
}


// Flesh hit

#include "Hitters.as";

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Damage(damage, hitterBlob);
	// Gib if health below gibHealth
	f32 gibHealth = getGibHealth(this);
	
	//receive more damage from arrows while dead
	switch (customData)
	{
		case Hitters::arrow:
		if (this.getHealth() <= 0.0f && this.hasTag("dead"))
		{
			this.Damage(damage *= 2.0f, hitterBlob);
		}
	}

	//printf("ON HIT " + damage + " he " + this.getHealth() + " g " + gibHealth );
	// blob server_Die()() and then gib


	//printf("gibHealth " + gibHealth + " health " + this.getHealth() );
	if (this.getHealth() <= gibHealth)
	{
	    server_DropCoins(this.getPosition() + Vec2f(0, -3.0f), this.get_u16("coins on death"));

		this.getSprite().Gib();
		this.server_Die();
	}

	return 0.0f; //done, we've used all the damage
}

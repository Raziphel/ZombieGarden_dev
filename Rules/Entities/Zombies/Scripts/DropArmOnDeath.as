#include "CreatureDeath.as";

const f32 probability = 0.25f; //between 0 and 1

void dropArm(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	
	if (!this.hasTag("dropped arm")) //double check
	{
		this.Tag("dropped arm");

		if ((XORRandom(1024) / 1024.0f) < probability)
		{
			CBlob@ zombiearm = server_CreateBlob("zombiearm", -1, this.getPosition());

			if (zombiearm !is null)
			{
				Vec2f vel(XORRandom(2) == 0 ? -2.0 : 2.0f, -5.0f);
				zombiearm.setVelocity(vel);
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.get_u32( "death time" ) + VANISH_BODY_SECS * getTicksASecond() > getGameTime() ) //we want hands dropping only if the body is killed, not when it revives naturally
	{
		dropArm(this);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

#include "CreatureDeath.as";

void dropZombies(CBlob@ this)
{
	if (!getNet().isServer())
		return;
	
	if (!this.hasTag("dropped zombies")) //double check
	{
		this.Tag("dropped zombies");
		server_CreateBlob("bloodzombie", -1, this.getPosition());
		server_CreateBlob("evilzombie", -1, this.getPosition());
		server_CreateBlob("plantzombie", -1, this.getPosition());
	}
}

void onDie(CBlob@ this)
{
	if (this.get_u32( "death time" ) + VANISH_BODY_SECS * getTicksASecond() > getGameTime() ) //we want hands dropping only if the body is killed, not when it revives naturally
	{
		dropZombies(this);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

//SummonZombie
//modified to literally summon zombies
#include "UndeadNecromancerCommon.as";

void onInit( CBlob@ this )
{
	this.set_u32("last teleport", 0 );
	this.set_bool("teleport ready", true );
}


void onTick( CBlob@ this ) 
{	
	bool ready = this.get_bool("teleport ready");
	const u32 gametime = getGameTime();
	
	if(ready) {
		if(this.isKeyJustPressed( key_action2 )) {
			Vec2f delta = this.getPosition() - this.getAimPos();
			if(delta.Length() < TELEPORT_DISTANCE){
				this.set_u32("last teleport", gametime);
				this.set_bool("teleport ready", false );
				SummonZombie(this, this.getAimPos());
			} else if(this.isMyPlayer()) {
				Sound::Play("option.ogg");
			}
		}
	} else {		
		u32 lastTeleport = this.get_u32("last teleport");
		int diff = gametime - (lastTeleport + TELEPORT_FREQUENCY);
		
		if(this.isKeyJustPressed( key_action2 ) && this.isMyPlayer()){
			Sound::Play("Entities/Characters/Sounds/NoAmmo.ogg");
		}

		if (diff > 0)
		{
			this.set_bool("teleport ready", true );
			this.getSprite().PlaySound("/Cooldown1.ogg"); 
		}
	}
}

void SummonZombie( CBlob@ blob, Vec2f aimpos)	
{	
	if (!getNet().isServer())
		return;
	
	int r = XORRandom(5);
	if (r == 0)
	{
		server_CreateBlob( "skeleton2", 1, aimpos );
	}
	else if (r == 1)
	{
		server_CreateBlob( "zombie2", 1, aimpos );
	}
	else if (r == 2)
	{
		server_CreateBlob( "wraith2", 1, aimpos );
	}
	else if (r == 3)
	{
		server_CreateBlob( "zbison2", 1, aimpos );
	}
	else if (r == 4)
	{
		server_CreateBlob( "greg2", 1, aimpos );
	}
	ParticleZombieLightning( aimpos );           
    blob.getSprite().PlaySound("/Respawn.ogg");
}

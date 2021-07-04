#include "Knocked.as";

f32 SCREECH_DISTANCE = 256.0f;
const int TELEPORT_FREQUENCY = 15 * 30; //15 secs
const int TELEPORT_DISTANCE = 120;//getMap().tilesize;

void onInit( CBlob@ this )
{
	this.set_u32("last teleport", 0 );
	this.set_bool("teleport ready", true );
	this.set_u32("invisible", 0);
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
				Stalk(this, this.getAimPos());
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

void Stalk( CBlob@ this, Vec2f aimpos) //check the anim and logic files too	
{	
	//turn ourselves invisible
	ParticleAnimated( "LargeSmoke.png", this.getPosition(), Vec2f(0,0), 0.0f, 1.0f, 1.5, -0.1f, false );
	this.set_u32("invisible", 5*30); //5 secs
	
	//*teleports behind you* nothing personel kid
	this.setPosition( aimpos );
    this.setVelocity( Vec2f_zero );
    ParticleAnimated( "LargeSmoke.png", this.getPosition(), Vec2f(0,0), 0.0f, 1.0f, 1.5, -0.1f, false );           
    this.getSprite().PlaySound("/Respawn.ogg");
	
	//screech and stun nearby enemies
	CBlob@[] nearBlobs;
	this.getMap().getBlobsInRadius( this.getPosition(), SCREECH_DISTANCE, @nearBlobs );
	this.getSprite().PlaySound("/BansheeScreech", 3.0f);
	
	for(int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob@ recipent = nearBlobs[step]; // :)
		if    (recipent !is null &&! recipent.hasTag("dead") && recipent.hasTag("survivorplayer"))
		{
            // that was loud!
			SetKnocked( recipent, 60 + XORRandom(60) );
		}
	}
}

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

void onGib(CSprite@ this)
{
    if (g_kidssafe)
        return;
	
    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
    CParticle@ Body     = makeGibParticle( "Entities/Creatures/Sprites/UndeadGibs2.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm1     = makeGibParticle( "Entities/Creatures/Sprites/UndeadGibs2.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm2     = makeGibParticle( "Entities/Creatures/Sprites/UndeadGibs2.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Shield   = makeGibParticle( "Entities/Creatures/Sprites/UndeadGibs2.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 3, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
    CParticle@ Sword    = makeGibParticle( "Entities/Creatures/Sprites/UndeadGibs2.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ),   1, 4, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
}


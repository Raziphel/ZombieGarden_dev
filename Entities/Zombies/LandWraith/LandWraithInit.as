// Olimarrex \\

#include "CreatureCommon.as"

void onInit( CMovement@ this )
{
    CreatureMoveVars moveVars;

    //walking vars
    moveVars.walkSpeed = 0.7f;
    moveVars.walkFactor = 1.0f;
    moveVars.walkLadderSpeed.Set( 0.15f, 0.6f );

    //climbing vars
    moveVars.climbingEnabled = true;

    //jumping vars
    moveVars.jumpMaxVel = 2.9f;
    moveVars.jumpStart = 1.0f;
    moveVars.jumpMid = 0.55f;
    moveVars.jumpEnd = 0.4f;
    moveVars.jumpFactor = 1.0f;
    moveVars.jumpCount = 0;
    
    //stopping forces
    moveVars.stoppingForce = 0.80f; //function of mass
    moveVars.stoppingForceAir = 0.60f; //function of mass
    moveVars.stoppingFactor = 1.0f;

	//set
    this.getBlob().set( "moveVars", moveVars );
    this.getBlob().getShape().getVars().waterDragScale = 30.0f;
	this.getBlob().getShape().getConsts().collideWhenAttached = true;
}

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 255, 240, 171));
	
	// explosiveness
	this.set_f32("explosive_radius", 25.0f);
	this.set_f32("explosive_damage", 3.0f);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 15.0f);
	this.set_f32("map_damage_ratio", 0.25f);
	this.set_bool("map_damage_raycast", true);
	this.set_bool("explosive_teamkill", true);
	
	this.Tag("exploding");
}
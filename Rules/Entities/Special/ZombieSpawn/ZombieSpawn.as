#include "Hitters.as";
#include "RespawnCommandCommon.as"
#include "StandardRespawnCommand.as"
void onInit( CBlob@ this )
{
	this.addCommandID( "ZombieSpawn" );
	this.Tag("invincible");
	this.SetLight(true);
	this.SetLightRadius(124.0f);
	this.SetLightColor(SColor(255, 25, 94, 157));
}

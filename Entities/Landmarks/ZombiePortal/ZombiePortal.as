#include "Hitters.as";
// #include "RespawnCommandCommon.as"
#include "StandardRespawnCommand.as"
void onInit(CBlob @ this)
{
	this.addCommandID("ZombiePortal");
	this.Tag("invincible");
	this.Tag("ZP");
	this.SetLight(true);
	this.SetLightRadius(124.0f);
	this.SetLightColor(SColor(255, 25, 94, 157));
}

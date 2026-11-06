#include "TeamColour.as";

void onInit(CBlob @ this)
{
	this.SetLight(true);
	this.SetLightRadius(32.0f);
	this.SetLightColor(getTeamColor(this.getTeamNum()));

	CShape @shape = this.getShape();
	if (shape !is null)
		shape.SetStatic(true);

	if (isServer())
		this.server_SetTimeToDie(1.0f);

	if (isClient())
	{
		CSprite @sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.PlaySound("/HealSound.ogg");
			sprite.SetZ(100);
		}
	}
}

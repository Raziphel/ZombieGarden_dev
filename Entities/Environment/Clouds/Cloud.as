
void onInit(CBlob @ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.SetFacingLeft(XORRandom(2) == 0);
	// this.getCurrentScript().tickFrequency = 3;
}

void onInit(CSprite @ this)
{
	this.SetZ(5.0f);
	this.setRenderStyle(RenderStyle::light);
	this.SetLighting(false);
}

void onTick(CBlob @ this)
{
	bool MakeItRain = true; // getRules().get_bool("raining");
	if (MakeItRain)
	{
		Vec2f thispos = this.getPosition();
		Vec2f pos = Vec2f(thispos.x - 64, thispos.y) + Vec2f(XORRandom(128), 32);

		MakeParticle(pos);
	}
}

void MakeParticle(Vec2f pos)
{
	CParticle @raindrop = ParticlePixel(pos, Vec2f(0, 0), SColor(255, 50, 100, 155 + XORRandom(100)), false);
	if (raindrop is null)
		return;

	raindrop.Z = -100 + XORRandom(400);
	raindrop.timeout = 30 + XORRandom(50);
	raindrop.scale = 1.0f + (XORRandom(15) * 0.1f);
	raindrop.damping = 0.97f; // less is more, more or less
	raindrop.fadeout = true;
	raindrop.bounce = 0.2f + (XORRandom(6) * 0.1);

	// raindrop.stretches = true; //hardcore lag

	// raindrop.windaffect = 0.5f;
	// raindrop.Z = 0;
	// raindrop.gravity *= 0.3f;
	// raindrop.growth = 0.02f;
}

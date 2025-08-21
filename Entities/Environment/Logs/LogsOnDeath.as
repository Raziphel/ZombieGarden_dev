// tree making logs on death script

#include "TreeCommon.as"

void onDie(CBlob @ this)
{
	Vec2f pos = this.getPosition();
	f32 fall_angle = 0.0f;

	if (this.exists("tree_fall_angle"))
	{
		fall_angle = this.get_f32("tree_fall_angle");
	}

	TreeSegment[] @segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
		return;

	if (getNet().isServer())
	{
		CBlob @log = null;

		switch (segments.length)
		{
			// case 0; break;
			case 1:
				@log = server_CreateBlob("log", this.getTeamNum(), pos);
				break;

			case 2:
				@log = server_CreateBlob("m_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 3:
				@log = server_CreateBlob("l_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 4:
				@log = server_CreateBlob("xl_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 5:
				@log = server_CreateBlob("xxl_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 6:
				@log = server_CreateBlob("xxxl_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 7:
				@log = server_CreateBlob("xxxxl_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
			case 8:
				@log = server_CreateBlob("xxxxxl_log", this.getTeamNum(), pos + segments[segments.length / 2].start_pos);
				break;
		};
		if (log !is null)
		{
			log.setAngleDegrees(fall_angle);
			// log.setAngularVelocity(this.getAngularVelocity());
		}
	}

	// TODO LEAVES PARTICLES
	// ParticleAnimated( "Entities/Effects/leaves", pos, Vec2f(0,-0.5f), 0.0f, 1.0f, 2+XORRandom(4), 0.2f, false );
	// for (int i = 0; i < this.getSprite().getSpriteLayerCount(); i++) { // crashes
	//     ParticlesFromSprite( this.getSprite().getSpriteLayer(i) );
	// }
	//  effects
	Sound::Play("Sounds/branches" + (XORRandom(2) + 1) + ".ogg", this.getPosition());
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	TreeSegment[] @segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
		return damage;

	f32 fall_angle = 0.0f;

	if (this.exists("tree_fall_angle"))
	{
		fall_angle = this.get_f32("tree_fall_angle");
	}

	Vec2f pos = this.getPosition();

	SColor leafCol;
	switch (XORRandom(3))
	{
		case 0:
			leafCol = SColor(0xff649b0d);
			break;
		case 1:
			leafCol = SColor(0xff9dca22);
			break;
		case 2:
			leafCol = SColor(0xff33660d);
			break;
			// case 3: leafCol = SColor(0xff0d290d); break; //too dark
	}

	for (int i = 0; i < segments.length; i++)
	{
		if (i > 1)
		{
			Vec2f segpos = pos + segments[i].start_pos + Vec2f(-8 + XORRandom(16), 4).RotateBy(fall_angle);
			for (int l = 0; l < XORRandom(3); l++)
			{
				CParticle @leaf = ParticlePixel(segpos, getRandomVelocity(0, (32 + XORRandom(40)) * 0.1f, 360), leafCol, false);
				if (leaf !is null)
				{
					// leaf.Z = -1+XORRandom(1000);
					leaf.gravity = Vec2f(XORRandom(16) * 0.03f, 0.15f);
					leaf.diesoncollide = true;
					leaf.timeout = 64 + XORRandom(50);
					leaf.damping = 0.3f; // less is more, more or less
					leaf.fadeout = true;
				}
			}
		}
	}
	return damage;
}
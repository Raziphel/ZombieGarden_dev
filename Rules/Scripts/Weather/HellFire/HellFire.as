#include "CustomBlocks.as";
#include "Explosion.as";
#include "FireParticle.as";
#include "Hitters.as";
#include "MakeDustParticle.as";
#include "MakeSeed.as";
#include "canGrow.as";

const int spritesize = 128;
f32 uvs;
Vertex[] HellFire_vs;
Vertex[] Fog_vs;

f32 windTarget = 0;
f32 wind = 0;
u32 nextWindShift = 0;

f32 fog = 0;
f32 fogTarget = 0;

f32 modifier = 1;
f32 modifierTarget = 1;

f32 fogHeightModifier = 0;
f32 fogDarkness = 0;

Vec2f hellfirepos = Vec2f(0, 0);
f32 uvMove = 0;

void onInit(CBlob @ this)
{
	this.getShape().SetStatic(true);
	this.getCurrentScript().tickFrequency = 1;
	this.getShape().SetRotationsAllowed(true);

	getMap().CreateSkyGradient("skygradient.png");

	if (isServer())
	{
		this.server_SetTimeToDie(300);
	}

	if (isClient())
	{
		Render::addBlobScript(Render::layer_postworld, this, "HellFire.as", "RenderHellFire");
		if (!Texture::exists("HELLFIRE"))
			Texture::createFromFile("HELLFIRE", "HellFire.png");
		if (!Texture::exists("FOG"))
			Texture::createFromFile("FOG", "pixel.png");
	}

	getRules().set_bool("raining", true);
	client_AddToChat("Hell fire rains from the sky! Random blazes will ignite the world.", SColor(255, 255, 0, 0));
}

void onInit(CSprite @ this)
{
	this.getConsts().accurateLighting = false;
	Setup(this);
}

void onReload(CBlob @ this)
{
	Setup(this.getSprite());
}

void Setup(CSprite @ this)
{
	if (isClient())
	{
		this.SetEmitSound("HellFire_Loop.ogg");
		this.SetEmitSoundPaused(false);
		CMap @map = getMap();
		uvs = 2048.0f / f32(spritesize);

		Vertex[] BigQuad =
			{
				Vertex(-1024, -1024, -800, 0, 0, 0x90ff0000),
				Vertex(1024, -1024, -800, uvs, 0, 0x90ff0000),
				Vertex(1024, 1024, -800, uvs, uvs, 0x90ff0000),
				Vertex(-1024, 1024, -800, 0, uvs, 0x90ff0000)};

		HellFire_vs = BigQuad;
		BigQuad[0].z = BigQuad[1].z = BigQuad[2].z = BigQuad[3].z = 1500;
		Fog_vs = BigQuad;
	}
}

void onTick(CBlob @ this)
{
	CMap @map = getMap();
	if (getGameTime() >= nextWindShift)
	{
		windTarget = 50 + XORRandom(200);
		nextWindShift = getGameTime() + 30 + XORRandom(300);

		fogTarget = 50 + XORRandom(150);
	}

	wind = Lerp(wind, windTarget, 0.02f);
	fog = Lerp(fog, fogTarget, 0.01f);

	Vec2f dir = Vec2f(0, 1).RotateBy(70);

	CBlob @[] vehicles;
	getBlobsByTag("aerial", @vehicles);
	for (u32 i = 0; i < vehicles.length; i++)
	{
		CBlob @blob = vehicles[i];
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			if (map.rayCastSolidNoBlobs(Vec2f(pos.x, 0), pos))
				continue;

			blob.AddForce(dir * blob.getRadius() * wind * 0.01f);
		}
	}

	if (isServer() && XORRandom(50) == 0)
	{
		f32 x = XORRandom(map.tilemapwidth);
		Vec2f pos = Vec2f(x, map.getLandYAtX(x)) * map.tilesize;
		map.server_setFireWorldspace(pos, true);
	}

	if (isClient())
	{
		CCamera @cam = getCamera();
		fogHeightModifier = 0.00f;

		if (cam !is null && uvs > 0)
		{
			Vec2f cam_pos = cam.getPosition();
			hellfirepos = Vec2f(int(cam_pos.x / spritesize) * spritesize + (spritesize / 2),
								int(cam_pos.y / spritesize) * spritesize + (spritesize / 2));
			this.setPosition(cam_pos);
			uvMove = (uvMove - 0.09f) % uvs;

			Vec2f hit;
			if (getMap().rayCastSolidNoBlobs(Vec2f(cam_pos.x, 0), cam_pos, hit))
			{
				f32 depth = Maths::Abs(cam_pos.y - hit.y) / 8.0f;
				modifierTarget = 1.0f - Maths::Clamp(depth / 8.0f, 0.00f, 1);
			}
			else
			{
				modifierTarget = 1;
			}

			modifier = Lerp(modifier, modifierTarget, 0.10f);
			fogHeightModifier = 1.00f - (cam_pos.y / (map.tilemapheight * map.tilesize));

			if (getGameTime() % 5 == 0)
				ShakeScreen(Maths::Abs(wind) * 0.03f * modifier, 90, cam_pos);

			this.getSprite().SetEmitSoundSpeed(0.5f + modifier * 0.5f);
			this.getSprite().SetEmitSoundVolume(0.30f + 0.10f * modifier);
		}

		fogDarkness = Maths::Clamp(130 + (fog * 0.10f), 0, 255);
	}
}

void RenderHellFire(CBlob @ this, int id)
{
	if (HellFire_vs.size() > 0)
	{
		Render::SetTransformWorldspace();
		Render::SetAlphaBlend(true);
		HellFire_vs[0].v = HellFire_vs[1].v = uvMove;
		HellFire_vs[2].v = HellFire_vs[3].v = uvMove + uvs;
		float[] model;
		Matrix::MakeIdentity(model);
		Matrix::SetRotationDegrees(model, 0.00f, 0.00f, 70.0f);
		Matrix::SetTranslation(model, hellfirepos.x, hellfirepos.y, 0.00f);
		Render::SetModelTransform(model);
		Render::RawQuads("HELLFIRE", HellFire_vs);
		f32 alpha = Maths::Clamp(Maths::Max(fog, 255 * fogHeightModifier * 1.20f) * modifier, 0, 190);
		Fog_vs[0].col = Fog_vs[1].col = Fog_vs[2].col = Fog_vs[3].col = SColor(alpha, fogDarkness, 0, 0);
		Render::RawQuads("FOG", Fog_vs);
	}
}

f32 Lerp(f32 v0, f32 v1, f32 t)
{
	return v0 + t * (v1 - v0);
}

void onDie(CBlob @ this)
{
	getRules().set_bool("raining", false);
	getMap().CreateSkyGradient("skygradient.png");
}

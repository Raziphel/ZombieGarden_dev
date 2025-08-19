// RuinsTorchLogic.as
// Cube + rings render without ZTest/ZWrite (not available in your build)

#include "StandardRespawnCommand.as"
#include "TeamColour.as"

const string cube_texture_name  = "GUI/Pixel.png";  // known-good texture
const string rings_texture_name = "GUI/Pixel.png";  // known-good texture

// 4x4 model matrices (must be 16 floats)
float[] cube_model;
float[] rings_model;

// index buffers
u16[]   cube_v_i;
u16[]   rings_v_i;

Vertex[] v_cube_raw = {
	Vertex( 24, -24, -24,  0, 0,  SColor(0xffffffff)),
	Vertex( 24, -24,  24,  1, 0,  SColor(0xffffffff)),
	Vertex(-24, -24,  24,  1, 1,  SColor(0xffffffff)),
	Vertex(-24, -24, -24,  0, 1,  SColor(0xffffffff)),
	Vertex( 24,  24, -24,  0, 1,  SColor(0xffffffff)),
	Vertex( 24,  24,  24,  0, 0,  SColor(0xffffffff)),
	Vertex(-24,  24,  24,  1, 0,  SColor(0xffffffff)),
	Vertex(-24,  24, -24,  1, 1,  SColor(0xffffffff))
};

u16[] cube_quad_faces = {
	0, 1, 2, 3,   // bottom
	4, 7, 6, 5,   // top
	0, 4, 5, 1,   // +X
	1, 5, 6, 2,   // +Z
	2, 6, 7, 3,   // -X
	4, 0, 3, 7    // -Z
};

Vertex[] v_rings_raw = {
	Vertex( 48, -48,   0,  0, 0,  SColor(0xa1ffffff)),
	Vertex( 48,  48,   0,  1, 0,  SColor(0xa1ffffff)),
	Vertex(-48,  48,   0,  1, 1,  SColor(0xa1ffffff)),
	Vertex(-48, -48,   0,  0, 1,  SColor(0xa1ffffff)),

	Vertex( 0,   48, -48,  0, 0,  SColor(0xa1ffffff)),
	Vertex( 0,   48,  48,  1, 0,  SColor(0xa1ffffff)),
	Vertex( 0,  -48,  48,  1, 1,  SColor(0xa1ffffff)),
	Vertex( 0,  -48, -48,  0, 1,  SColor(0xa1ffffff))
};

u16[] rings_quad_faces = {
	0, 1, 2, 3,   // XY billboard
	4, 7, 6, 5    // YZ billboard
};

Random _r(0xca7a);
u8 msgtimer;
Vec2f g_lastPos;

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50.0f);

	this.CreateRespawnPoint("ruinstorch", Vec2f(0.0f, -4.0f));
	InitClasses(this);
	this.Tag("change class drop inventory");

	this.getShape().getConsts().mapCollisions = false;
	this.set_TileType("background tile", CMap::tile_empty);

	this.Tag("respawn");
	this.Tag("building");
	this.Tag("blocks sword");
	this.Tag("ruinstorch");

	this.getCurrentScript().removeIfTag = "dead";

	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));

	this.SetLight(true);
	this.SetLightRadius(64.0f);

	// Register render callback ABOVE world
	int cb_id = Render::addScript(Render::layer_postworld, "RuinsTorchLogic.as", "RenderFunction", 0.0f);
	this.set_u16("renderID", cb_id);

	CreateMeshes(this);
}

void CreateMeshes(CBlob@ this)
{
	Vec2f thispos = this.getPosition() + Vec2f(3, -8);
	g_lastPos = thispos;

	// allocate storage for 4x4 matrices
	cube_model.resize(16);
	rings_model.resize(16);

	Matrix::MakeIdentity(cube_model);
	Matrix::SetTranslation(cube_model, thispos.x, thispos.y, 6);

	cube_v_i.clear();
	for (u16 i = 0; i < cube_quad_faces.length; i += 4)
	{
		u16 a = cube_quad_faces[i+0];
		u16 b = cube_quad_faces[i+1];
		u16 c = cube_quad_faces[i+2];
		u16 d = cube_quad_faces[i+3];
		cube_v_i.push_back(a); cube_v_i.push_back(b); cube_v_i.push_back(d);
		cube_v_i.push_back(b); cube_v_i.push_back(c); cube_v_i.push_back(d);
	}

	Matrix::MakeIdentity(rings_model);
	Matrix::SetTranslation(rings_model, thispos.x, thispos.y, 5);

	rings_v_i.clear();
	for (u16 i = 0; i < rings_quad_faces.length; i += 4)
	{
		u16 a = rings_quad_faces[i+0];
		u16 b = rings_quad_faces[i+1];
		u16 c = rings_quad_faces[i+2];
		u16 d = rings_quad_faces[i+3];
		rings_v_i.push_back(a); rings_v_i.push_back(b); rings_v_i.push_back(d);
		rings_v_i.push_back(b); rings_v_i.push_back(c); rings_v_i.push_back(d);
	}
}

void RenderFunction(int id)
{
	// simple debug overlay so you know the callback is firing
	if (isClient())
	{
		if ((getGameTime() % 120) == 0)
			printf("[RuinsTorch] Render tick. cube_idx=" + cube_v_i.length + " rings_idx=" + rings_v_i.length);
		Vec2f screen = getDriver().getScreenPosFromWorldPos(g_lastPos);
		GUI::DrawRectangle(screen + Vec2f(-5, -5), screen + Vec2f(5, 5), SColor(0xffff22aa));
	}

	// State: draw opaque first (no alpha blend), then enable alpha for rings
	Render::SetBackfaceCull(false);

	Render::SetAlphaBlend(false);
	Render::SetModelTransform(cube_model);
	Render::RawTrianglesIndexed(cube_texture_name, v_cube_raw, cube_v_i);

	Render::SetAlphaBlend(true);
	Render::SetModelTransform(rings_model);
	Render::RawTrianglesIndexed(rings_texture_name, v_rings_raw, rings_v_i);
}

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health")) return this.get_f32("gib health");
	return 0.0f;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Tag("dmgmsg");
	msgtimer = 150;

	if (isClient() && damage != 0)
	{
		const int sparkCount = 5 + XORRandom(4);
		for (int i = 0; i < sparkCount; ++i)
		{
			Vec2f vel = getRandomVelocity(0, 5 + XORRandom(6), 360);
			CParticle@ p = ParticleSpark(worldPoint, vel, SColor(255, 252, 152, 3));
			if (p !is null)
			{
				p.gravity = Vec2f(0, 0.5f);
				p.timeout = 15 + XORRandom(10);
			}
		}
		this.getSprite().PlaySound("MetalClang1.ogg", 1.0f, 1.0f);
	}
	return damage;
}

void onTick(CBlob@ this)
{
	if (msgtimer > 0) msgtimer--;
	else this.Untag("dmgmsg");

	g_lastPos = this.getPosition() + Vec2f(3, -8);

	float t = float(getGameTime());
	f32 health = this.getHealth();

	Matrix::SetRotationDegrees(
		cube_model,
		(t * 1.3f) * (21.0f - health),
		(t * 1.2f) * (21.0f - health),
		(t * 1.6f) * (21.0f - health)
	);
	Matrix::SetRotationDegrees(
		rings_model,
		(t * 1.8f) * (21.0f - health),
		(t * 1.3f) * (21.0f - health),
		(t * 2.6f) * (21.0f - health)
	);

	// pulse color
	SColor first(0xff00ffff);
	SColor second(0xffff0000);
	f32 wave = Maths::Sin(getGameTime() / 120.0f);
	SColor interpolated = first.getInterpolated(second, wave);
	this.SetLightColor(interpolated);

	for (uint i = 0; i < v_cube_raw.length; i++)
		v_cube_raw[i].col = interpolated;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (canChangeClass(this, caller) && caller.getTeamNum() == this.getTeamNum())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton("$change_class$", Vec2f(0, 0), this, buildSpawnMenu, getTranslatedString("Swap Class"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

void onDie(CBlob@ this)
{
    CRules@ rules = getRules();
    rules.set_bool("everyones_dead", true);

    if (!rules.get_bool("ruins_portal_active"))
    {
        rules.set_bool("ruins_portal_active", true);
        rules.Sync("ruins_portal_active", true);
		
		CBlob@[] ruins;
        getBlobsByName("zombieruins", @ruins);
        for (uint i = 0; i < ruins.length; i++)
        {
            CBlob@ ruin = ruins[i];
            if (ruin !is null)
			{
				server_CreateBlob("zombieportal", -1, ruin.getPosition());
			}
		}
    }

        Render::RemoveScript(this.get_u16("renderID"));
}

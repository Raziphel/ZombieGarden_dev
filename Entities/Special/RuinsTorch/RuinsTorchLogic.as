// Tent logic

#include "StandardRespawnCommand.as"
#include "TeamColour.as"

const string cube_texture_name = "stoneblock";
const string rings_texture_name = "lightring";

float[] cube_model;
u16[] cube_v_i;

Vertex[] v_cube_raw = {
Vertex( 4, -4, -4,  0, 0, 	SColor(0xffffffff)),
Vertex( 4, -4,  4,  1, 0,	SColor(0xffffffff)),
Vertex(-4, -4,  4,  1, 1,	SColor(0xffffffff)),
Vertex(-4, -4, -4,  0, 1, 	SColor(0xffffffff)),
Vertex( 4,  4, -4,  0, 1, 	SColor(0xffffffff)),
Vertex( 4,  4,  4,  0, 0,	SColor(0xffffffff)),
Vertex(-4,  4,  4,  1, 0,	SColor(0xffffffff)),
Vertex(-4,  4, -4,  1, 1, 	SColor(0xffffffff))
};

float[] cube_quad_faces = {
	0, 1, 2, 3,
	4, 7, 6, 5,
	0, 4, 5, 1,
	1, 5, 6, 2,
	2, 6, 7, 3,
	4, 0, 3, 7,
};

float[] rings_model;
u16[] rings_v_i;

Vertex[] v_rings_raw = {
Vertex( 16, -16,   0,  0, 0, 	SColor(0xa1ffffff)),
Vertex( 16,  16,   0,  1, 0,	SColor(0xa1ffffff)),
Vertex(-16,  16,   0,  1, 1,	SColor(0xa1ffffff)),
Vertex(-16, -16,   0,  0, 1, 	SColor(0xa1ffffff)),
Vertex( 0,   16, -16,  0, 0, 	SColor(0xa1ffffff)),
Vertex( 0,   16,  16,  1, 0,	SColor(0xa1ffffff)),
Vertex( 0,  -16,  16,  1, 1,	SColor(0xa1ffffff)),
Vertex( 0,  -16, -16,  0, 1, 	SColor(0xa1ffffff))
};

float[] rings_quad_faces = {
	0, 1, 2, 3,
	4, 7, 6, 5,
};

Random _r(0xca7a);
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

	this.getCurrentScript().removeIfTag = "dead";

	// minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));

	this.SetLight(true);
	this.SetLightRadius(64.0f);

	if (isClient())
	{
		if (!Texture::exists(cube_texture_name))
		{
			Texture::createFromFile(cube_texture_name, cube_texture_name);
			Texture::createFromFile(rings_texture_name, rings_texture_name); // safe to assume this isnt created as well;
		}
	}

	int cb_id = Render::addScript(Render::layer_objects, "RuinsTorchLogic.as", "RenderFunction", 0.0f);

	this.set_u16("renderID", cb_id);
	
	CreateMeshes(this);
}

void CreateMeshes(CBlob@ this)
{
	Vec2f thispos = this.getPosition()+Vec2f(3,-8);

	Matrix::MakeIdentity(cube_model);
	Matrix::SetTranslation(cube_model, thispos.x, thispos.y, -20);
	cube_v_i.clear();
	for(int i = 0; i < cube_quad_faces.length; i += 4)
	{
		int id_0 = cube_quad_faces[i+0];
		int id_1 = cube_quad_faces[i+1];
		int id_2 = cube_quad_faces[i+2];
		int id_3 = cube_quad_faces[i+3];

		cube_v_i.push_back(id_0); cube_v_i.push_back(id_1); cube_v_i.push_back(id_3);
		cube_v_i.push_back(id_1); cube_v_i.push_back(id_2); cube_v_i.push_back(id_3);
	}

	Matrix::MakeIdentity(rings_model);
	Matrix::SetTranslation(rings_model, thispos.x, thispos.y, -20);
	rings_v_i.clear();
	for(int i = 0; i < rings_quad_faces.length; i += 4)
	{
		int id_0 = rings_quad_faces[i+0];
		int id_1 = rings_quad_faces[i+1];
		int id_2 = rings_quad_faces[i+2];
		int id_3 = rings_quad_faces[i+3];

		rings_v_i.push_back(id_0); rings_v_i.push_back(id_1); rings_v_i.push_back(id_3);
		rings_v_i.push_back(id_1); rings_v_i.push_back(id_2); rings_v_i.push_back(id_3);
	}
}

void RenderFunction(int id)
{		
	//Render::SetAlphaBlend(true);
	//Render::SetBackfaceCull(true);
	Render::SetModelTransform(cube_model);	
	Render::RawTrianglesIndexed(cube_texture_name, v_cube_raw, cube_v_i);

	Render::SetAlphaBlend(true);

	Render::SetModelTransform(rings_model);	
	Render::RawTrianglesIndexed(rings_texture_name, v_rings_raw, rings_v_i);
}

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Tag("dmgmsg");
	msgtimer = 150;

	if (isClient() && damage != 0)
	{
		CParticle@ p = ParticleSpark(this.getPosition(), getRandomVelocity(0, 10, 360), SColor(255, 252, 152, 3));
		if (p !is null)
		{
			p.gravity = Vec2f(0, 1);
		}
	}


	return damage; //done, we've used all the damage
}

u8 msgtimer;
void onTick(CBlob@ this)
{
	if (msgtimer > 0)	
	{
		msgtimer--;
	}
	else
	{
		this.Untag("dmgmsg");
	}

	CMap@ map = getMap();	
	float t = getGameTime();
	f32 health = this.getHealth();

	Matrix::SetRotationDegrees(cube_model, (t*1.3)*(21.0-health), (t*1.2)*(21.0-health), (t*1.6)*(21.0-health) );
	Matrix::SetRotationDegrees(rings_model, (t*1.8)*(21.0-health), (t*1.3)*(21.0-health), (t*2.6)*(21.0-health) );

	SColor first(0xff00ffff);
	SColor second(0xffff0000);	
	SColor third(0xff00ff00);

	f32 wave = Maths::Sin(getGameTime() / 120.0f);

	SColor interpolated = first.getInterpolated(second, wave);


	this.SetLightColor(interpolated);

	for(int i = 0; i < v_cube_raw.size(); i++)
	{				
		SColor col = interpolated;
		v_cube_raw[i].col = col;

		//v_cube_raw[i].x *= 1.002;
		//v_cube_raw[i].y *= 1.002;
		//v_cube_raw[i].z *= 1.002;	
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	// button for runner
	// create menu for class change
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
	getRules().set_bool("everyones_dead",true);
 	Render::RemoveScript(this.get_u16("renderID"));
}
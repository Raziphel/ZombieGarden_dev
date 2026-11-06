// RuinsTorchLogic.as
// Cube + rings render without ZTest/ZWrite (not available in your build)

#include "StandardRespawnCommand.as"
#include "TeamColour.as"

void onInit(CBlob @ this)
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
	this.SetLightRadius(128.0f);

	// The torch is rendered by its own sprite and light. The former
	// Render::addScript callback referenced a nonexistent RenderFunction,
	// producing repeated errors whenever torches were initialized.
}

f32 onHit(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitterBlob, u8 customData)
{
	this.Tag("dmgmsg");

	if (isClient() && damage != 0)
	{
		const int sparkCount = 5 + XORRandom(4);
		for (int i = 0; i < sparkCount; ++i)
		{
			Vec2f vel = getRandomVelocity(0, 5 + XORRandom(6), 360);
			CParticle @p = ParticleSpark(worldPoint, vel, SColor(255, 252, 152, 3));
			if (p !is null)
			{
				p.gravity = Vec2f(0, 0.5f);
				p.timeout = 15 + XORRandom(10);
			}
		}
		this.getSprite().PlaySound("HitSolidMetal.ogg", 1.0f, 1.0f);
	}
	return damage;
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	if (caller !is null && caller.getTeamNum() == this.getTeamNum() &&
		canChangeClass(this, caller))
		caller.CreateGenericButton("$change_class$", Vec2f(0, 0),
			this, buildSpawnMenu, getTranslatedString("Swap Class"));
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}

void onDie(CBlob @ this)
{
	// Changing round rules and creating undead portals must be authoritative.
	if (!isServer())
		return;

	CRules @rules = getRules();
	if (rules is null || rules.get_bool("ruins_portal_active"))
		return;

	// Dying torches can still appear in a world query. Count only living
	// survivors, excluding the torch whose onDie hook is running.
	CBlob @[] torches;
	getBlobsByName("ruinstorch", @torches);
	int remaining = 0;
	for (uint i = 0; i < torches.length; ++i)
	{
		CBlob @torch = torches[i];
		if (torch !is null && torch !is this && !torch.hasTag("dead"))
			remaining++;
	}

	if (remaining > 3)
		return;

	rules.set_bool("ruins_portal_active", true);
	rules.Sync("ruins_portal_active", true);

	CBlob @[] ruins;
	getBlobsByName("zombieruins", @ruins);
	for (uint i = 0; i < ruins.length; ++i)
	{
		CBlob @ruin = ruins[i];
		if (ruin is null || ruin.hasTag("dead"))
			continue;

		Vec2f pos = ruin.getPosition();
		pos.x += 1.0f;
		pos.y += 16.0f;
		server_CreateBlob("zombieportal", -1, pos);
	}
}

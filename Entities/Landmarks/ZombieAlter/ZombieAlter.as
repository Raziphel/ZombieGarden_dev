// Zombie Alter

// #include "Requirements.as"
// #include "ShopCommon.as";
// #include "Descriptions.as";
// #include "WARCosts.as";
// #include "CheckSpam.as";

void onInit(CBlob @ this)
{
	// this.set_TileType("background tile", CMap::tile_wood_back);
	// this.getSprite().getConsts().accurateLighting = true;

	this.Tag("ZP");
	this.Tag("builder always hit");
	this.getSprite().SetZ(-50); // background

	CSpriteLayer @portal = this.getSprite().addSpriteLayer("portal", "ZombieAlter.png", 64, 64);
	Animation @anim = portal.addAnimation("default", 0, false);
	anim.AddFrame(1);
	portal.SetRelativeZ(-60);

	CSpriteLayer @lightning = this.getSprite().addSpriteLayer("lightning", "EvilLightning.png", 32, 32, -1, -1);
	Animation @lanim = lightning.addAnimation("default", 4, false);
	for (int i = 0; i < 7; i++)
		lanim.AddFrame(i * 4);
	Animation @lanim2 = lightning.addAnimation("default2", 4, false);
	for (int i = 0; i < 7; i++)
		lanim2.AddFrame(i * 4 + 1);

	//	portal.SetOffset(Vec2f(0,-24));
	//	lightning.SetOffset(Vec2f(0,-24));

	this.getShape().getConsts().mapCollisions = false;
	this.set_bool("portalbreach", false);
	this.set_bool("portalplaybreach", false);

	this.SetLight(false);
	this.SetLightRadius(64.0f);
}

void onTick(CBlob @ this)
{
	// Damaged altars become more aggressive, but the modulo must
	// always have a positive divisor even during their death tick.
	const int spawnRate = Maths::Max(30, int(60.0f +
		190.0f * Maths::Max(0.0f, this.getHealth()) / 44.0f));

	if (getGameTime() % spawnRate == 0 && this.get_bool("portalbreach"))
	{
		this.getSprite().PlaySound("Thunder");
		CSpriteLayer @lightning = this.getSprite().getSpriteLayer("lightning");
		if (lightning !is null)
		{
			if (XORRandom(4) > 2)
				lightning.SetAnimation("default");
			else
				lightning.SetAnimation("default2");
		}
		// lightning.SetFrame(0);
	}

	if (this.get_bool("portalplaybreach"))
	{
		this.getSprite().PlaySound("PortalBreach");
		this.set_bool("portalplaybreach", false);
		this.SetLight(true);
		this.SetLightRadius(128.0f);
	}

	if (!getNet().isServer())
		return;

	CRules @rules = getRules();
	const int max_pzombies = rules.get_s32("max_pzombies");

	if (this.get_bool("portalbreach"))
	{
		if (getGameTime() % spawnRate == 0)
		{
			// Read the shared count at spawn time. Updating it immediately
			// also prevents several altars on the same tick from exceeding
			// the portal population cap between scheduled world scans.
			const int num_pzombies = rules.get_s32("num_pzombies");
			if (max_pzombies <= 0 || num_pzombies >= max_pzombies)
				return;

			const int r = XORRandom(7);
			const int rr = XORRandom(7);
			string spawnName = "pcrawler";
			if (r == 4 && rr == 0)
				spawnName = "pbanshee";
			else if (r == 3 && rr == 0)
				spawnName = "pgreg";
			else if (r == 2)
				spawnName = "phellknight";
			else if (r == 1)
				spawnName = "pankou";
			else if (r == 6)
				spawnName = "zombie";
			else if (r >= 3)
				spawnName = "pbrute";

			CBlob @spawned = server_CreateBlob(spawnName, -1, this.getPosition());
			if (spawned !is null)
			{
				// The ordinary zombie variant also consumes a portal slot.
				spawned.Tag("pzombie");
				rules.set_s32("num_pzombies", num_pzombies + 1);
				rules.Sync("num_pzombies", true);
			}
		}
	}

	else
	{
		if (getGameTime() % 300 == 0)
		{
			Vec2f sp = this.getPosition();

			CBlob @[] blobs;
			this.getMap().getBlobsInRadius(sp, 50, @blobs);
			for (uint step = 0; step < blobs.length; ++step)
			{
				CBlob @other = blobs[step];
				if (other !is null && other.hasTag("survivorplayer") &&
					!other.hasTag("dead"))
				{
					this.set_bool("portalbreach", true);
					this.set_bool("portalplaybreach", true);
					this.Sync("portalplaybreach", true);
					this.Sync("portalbreach", true);
					break;
				}
			}
		}
	}
}

void onDie(CBlob @ this)
{
	if (!isServer())
		return;

	server_DropCoins(this.getPosition() + Vec2f(0, -32.0f), 1000);
	server_CreateBlob("chest", this.getTeamNum(), this.getPosition());
}

// Auto-elevating elevator ;)

const string working_prop = "working";
const string unique_prop = "unique";

void onInit(CSprite @ this)
{
	CSpriteLayer @cogsleft = this.addSpriteLayer("cogsleft", "Elevator.png", 16, 16);
	if (cogsleft !is null)
	{
		// default anim
		{
			Animation @anim = cogsleft.addAnimation("default", 0, false);
			int[] frames = {70, 71, 72, 73};
			anim.AddFrames(frames);
		}
		cogsleft.SetOffset(Vec2f(12.0f, 2.0f));
		cogsleft.SetRelativeZ(1);
		cogsleft.SetVisible(true);
	}

	//	for (uint i = 0; i < 6; i++)
	//	{
	//		CSpriteLayer@ ropes = this.addSpriteLayer("ropes"+i, "Elevator.png", 32, 64);
	//		if (ropes !is null)
	//		{
	//			//default anim
	//			{
	//				Animation@ anim = ropes.addAnimation("default", 0, false);
	//				anim.AddFrame(3);
	//				anim.AddFrame(4);
	//				anim.AddFrame(8);
	//				anim.AddFrame(9);
	//			}
	//			ropes.SetOffset(Vec2f(0.0f, 44 + 64.0f*i));
	//			ropes.SetRelativeZ(-1);
	//			ropes.SetVisible(true);
	//			//ropes.SetLighting(false);
	//		}
	//	}
}

void onInit(CBlob @ this)
{
	// building properties
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50);
	this.getShape().getConsts().mapCollisions = false;
	this.Tag("invincible");

	this.set_bool(working_prop, false);

	this.set_u8("Building Level", 1);

	// create and attach moving platform
	if (getNet().isServer())
	{
		CBlob @platform = server_CreateBlob("elevatorplatform", this.getTeamNum(), this.getPosition() + Vec2f(0, 8));
		if (platform !is null)
		{
			this.set_u16("childID", platform.getNetworkID());
			platform.set_u16("ownerID", this.getNetworkID());
			platform.getShape().SetStatic(true);
		}
	}

	Render::addScript(Render::layer_tiles, "Elevator.as", "RenderRopes", 0.0f);
	CreateRopesMesh(this);
}

u16[] rope_IDs;
Vertex[] rope_Vertexes;

void CreateRopesMesh(CBlob @ this)
{
	CMap @map = getMap();
	Vec2f p = this.getPosition();
	p.y += 8;
	for (uint i = 0; i < 6; i++)
	{
		rope_Vertexes.push_back(Vertex(p.x - 16, p.y + (32 * i), 0, 0, 0, color_white));
		rope_Vertexes.push_back(Vertex(p.x - 16, p.y + (32 * (i + 1)), 0, 0, 0.25, color_white));
		rope_Vertexes.push_back(Vertex(p.x + 16, p.y + (32 * (i + 1)), 0, 1, 0.25, color_white));
		rope_Vertexes.push_back(Vertex(p.x + 16, p.y + (32 * i), 0, 1, 0, color_white));
	}

	Render::SetTransformWorldspace();
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);
}

void RenderRopes(int id)
{
	Render::RawQuads("Ropes.png", rope_Vertexes);
}

void onTick(CBlob @ this)
{
	animateBelt(this, this.get_bool(working_prop));

	if (getNet().isServer())
	{
		this.Sync(working_prop, true);
	}

	CMap @map = getMap();
	for (int i = 0; i < rope_Vertexes.size(); i++)
	{
		SColor light = map.getColorLight(Vec2f(rope_Vertexes[i].x, rope_Vertexes[i].y));
		rope_Vertexes[i].col = light;
	}
}

void animateBelt(CBlob @ this, bool isActive)
{
	// safely fetch the animation to modify
	CSprite @sprite = this.getSprite();
	if (sprite is null)
		return;
	CSpriteLayer @cogs = sprite.getSpriteLayer("cogsleft");
	if (cogs is null)
		return;
	Animation @cogsleftanim = cogs.getAnimation("default");
	if (cogsleftanim is null)
		return;
	CBlob @platform = getBlobByNetworkID(this.get_u16("childID"));
	if (platform is null)
		return;

	if (isActive)
	{
		int frame = cogsleftanim.frame;
		if (getGameTime() % 2 == 0)
		{
			bool goingdown = !platform.hasTag("down last");

			if (goingdown)
			{
				if (frame < 3)
					frame++;
				else
					frame = 0;
			}
			else
			{
				if (frame > 0)
					frame--;
				else
					frame = 3;
			}

			cogsleftanim.SetFrameIndex(frame);

			for (int i = 0; i < rope_Vertexes.size(); i++)
			{
				if (goingdown)
				{
					if (frame == 0)
					{
						if (rope_Vertexes[i].v < 0.99)
							rope_Vertexes[i].v = 0;
						else
							rope_Vertexes[i].v = 0.25;
					}
					else
					{
						rope_Vertexes[i].v += (0.25);
					}
				}
				else
				{
					if (frame == 3)
					{
						if (rope_Vertexes[i].v > 0.01)
							rope_Vertexes[i].v = 1.0;
						else
							rope_Vertexes[i].v = 0.75;
					}
					else
					{
						rope_Vertexes[i].v -= (0.25);
					}
				}
			}
		}
	}
}

// void GetButtonsFor(CBlob@ this, CBlob@ caller)
//{
//	CBitStream params;
//	params.write_u16(caller.getNetworkID());
//
//	CButton@ button = caller.CreateGenericButton("$mat_wood$", Vec2f(-4.0f, 0.0f), this, this.getCommandID("Activate"), getTranslatedString("Activate"), params);
//	if (button !is null)
//	{
//		button.deleteAfterClick = false;
//		button.SetEnabled(true);
//	}
// }
//
// void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
//{
//	if (cmd == this.getCommandID("Activate"))
//	{
//		CBlob@ caller = getBlobByNetworkID(params.read_u16());
//		if(caller is null) return;
//
//		this.set_bool(working_prop, true);
//
//	}
// }

const string working_prop = "working";

void onInit(CSprite @ this)
{
	this.SetZ(1000.0f);
	this.SetEmitSound("/Elevator_wood.ogg");
	this.SetEmitSoundPaused(true);
}
void onInit(CBlob @ this)
{
	this.getShape().getConsts().collideWhenAttached = true;
	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().transports = true;
	this.getShape().getConsts().bullet = true;
	this.getShape().SetRotationsAllowed(false);
	this.getShape().SetOffset(Vec2f(0, 6));
	this.Tag("heavy weight");
	this.Tag("invincible");

	this.getCurrentScript().tickFrequency = 0;

	// this.set_bool("down last", false);
	this.addCommandID("Activate");
}

f32 speed;
void onTick(CBlob @ this)
{
	if (getNet().isServer())
	{
		CMap @map = this.getMap();
		Vec2f pos = this.getPosition();
		const u16 ownerID = this.get_u16("ownerID");
		CBlob @OwnerBuilding = getBlobByNetworkID(ownerID);
		if (OwnerBuilding !is null)
		{
			Vec2f end;
			if ((this.hasTag("down last") && map.rayCastSolidNoBlobs(pos + Vec2f(-8, 4), pos + Vec2f(8, 4), end)) || (!this.hasTag("down last") && pos.y <= OwnerBuilding.getPosition().y + 8.0f))
			{
				this.setVelocity(Vec2f_zero);
				this.getShape().SetStatic(true);

				this.set_bool(working_prop, false);
				OwnerBuilding.set_bool(working_prop, false);

				this.getCurrentScript().tickFrequency = 0;
				// OwnerBuilding.getCurrentScript().tickFrequency = 1;
			}
			else if (this.get_bool(working_prop) && this.getTickSinceCreated() > 10)
			{
				this.getShape().SetStatic(false);

				if (this.hasTag("down last"))
				{
					if (map.rayCastSolidNoBlobs(pos, pos + Vec2f(0, 76)))
					{
						if (speed > 0.2f)
							speed -= 0.11f;
					}
					else
					{
						speed = 4.0f;
					}
				}
				else
				{
					if (map.rayCastSolidNoBlobs(pos, pos + Vec2f(0, -76)) || (pos.y - OwnerBuilding.getPosition().y) <= 80.0f)
					{
						if (speed < -0.2f)
							speed += 0.11f;
					}
					else
					{
						speed = -4.0f;
					}
				}
				// print("speed "+speed);
				this.setVelocity(Vec2f(0, speed));

				this.set_bool(working_prop, true);
				OwnerBuilding.set_bool(working_prop, true);
			}
			this.Sync(working_prop, true);
		}
		else
		{
			// unstatic, fall down and die
		}
	}

	CSprite @sprite = this.getSprite();

	if (sprite.getEmitSoundPaused())
	{
		if (this.get_bool(working_prop))
		{
			sprite.SetEmitSoundPaused(false);
		}
	}
	else if (!this.get_bool(working_prop))
	{
		sprite.SetEmitSoundPaused(true);
	}

	if (!sprite.getEmitSoundPaused())
	{
		print("" + this.getVelocity().y);
		sprite.SetEmitSoundSpeed(Maths::Max(0.7, Maths::Min(1.0, Maths::Abs(this.getVelocity().y / 2.0f))));
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CButton @button = caller.CreateGenericButton("$lever$", Vec2f(0.0f, -4.0f), this, this.getCommandID("Activate"), getTranslatedString("Activate"), params);
	if (button !is null)
	{
		button.deleteAfterClick = false;
		button.SetEnabled(true);
	}
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("Activate"))
	{
		CBlob @caller = getBlobByNetworkID(params.read_u16());
		if (caller is null)
			return;

		if (this.get_bool("down last"))
		{
			this.Untag("down last");
		}
		else
		{
			this.Tag("down last");
		}

		this.set_bool(working_prop, true);
		this.getCurrentScript().tickFrequency = 1;

		CBlob @OwnerBuilding = getBlobByNetworkID(this.get_u16("ownerID"));
		if (OwnerBuilding !is null)
		{
			OwnerBuilding.set_bool(working_prop, true);
			OwnerBuilding.Sync(working_prop, true);
		}
	}
}

#include "PriestCommon.as";

void onInit(CBlob @ this)
{
	this.set_u32("last teleport", 0);
	this.set_bool("teleport ready", true);
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob @ this)
{
	if (this.hasTag("dead"))
		return;

	bool ready = this.get_bool("teleport ready");
	const u32 gametime = getGameTime();

	if (ready)
	{
		if (this.isKeyJustPressed(key_action2))
		{
			Vec2f delta = this.getPosition() - this.getAimPos();
			if (delta.Length() < TELEPORT_DISTANCE)
			{
				this.set_u32("last teleport", gametime);
				this.set_bool("teleport ready", false);
				Heal(this, this.getAimPos());
			}
			else if (this.isMyPlayer())
			{
				Sound::Play("option.ogg");
			}
		}
	}
	else
	{
		u32 lastTeleport = this.get_u32("last teleport");
		const bool finished = gametime >= lastTeleport + TELEPORT_FREQUENCY;

		if (this.isKeyJustPressed(key_action2) && this.isMyPlayer())
		{
			Sound::Play("Entities/Classes/Sounds/NoAmmo.ogg");
		}

		if (finished)
		{
			this.set_bool("teleport ready", true);
			if (isClient())
			{
				CSprite @sprite = this.getSprite();
				if (sprite !is null)
					sprite.PlaySound("/Cooldown2.ogg");
			}
		}
	}
}

void Heal(CBlob @blob, Vec2f pos)
{
	if (!isServer() || blob is null || blob.hasTag("dead"))
		return;

	CMap @map = blob.getMap();
	if (map is null)
		return;
	CBlob @[] blobsInRadius;
	if (map.getBlobsInRadius(pos, blob.getRadius() * 1.0f, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b !is null && !b.hasTag("dead") &&
				blob.getTeamNum() == b.getTeamNum() && b.hasTag("player"))
			{
				// Retain the Priest's +1 overheal, but only restore two hearts
				// per cast instead of instantly setting every target above full.
				const f32 healthCap = b.getInitialHealth() + 1.0f;
				const f32 restored = Maths::Min(healthCap, b.getHealth() + 2.0f);
				if (restored > b.getHealth())
				{
					b.server_SetHealth(restored);
					server_CreateBlob("healanimation", b.getTeamNum(), b.getPosition());
				}
				break;
			}
		}
	}
}

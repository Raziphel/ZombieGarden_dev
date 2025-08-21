#include "Hitters.as"

const bool dangerous_logs = false;

void onInit(CSprite @ this)
{
	this.animation.frame = XORRandom(4);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}

const string[] types =
	{
		"log",
		"m_log",
		"l_log",
		"xl_log",
		"xxl_log",
		"xxxl_log",
		"xxxxl_log",
		"xxxxxl_log"};

void onInit(CBlob @ this)
{
	if (getNet().isServer())
	{
		this.server_SetTimeToDie(240 + XORRandom(60));
		this.server_setTeamNum(-1);
		// dictionary harvest;
		// harvest.set('mat_wood', 10);
		// this.set('harvest', harvest);
	}
}

void onDie(CBlob @ this)
{
	if (getNet().isServer() && !this.isAttached())
	{
		string name;
		string name2;
		switch (types.find(this.getName()))
		{
			case 1:
				name = "log";
				name2 = "log";
				break;
			case 2:
				name = "m_log";
				name2 = "log";
				break;
			case 3:
				name = "m_log";
				name2 = "m_log";
				break;
			case 4:
				name = "l_log";
				name2 = "log";
				break;
			case 5:
				name = "l_log";
				name2 = "m_log";
				break;
			case 6:
				name = "xl_log";
				name2 = "l_log";
				break;
			case 7:
				name = "xl_log";
				name2 = "xl_log";
				break;
		};

		CBlob @newBlob = server_CreateBlob(name, -1, this.getPosition() + Vec2f(0, (this.getHeight() / 4) + 2).RotateBy(this.getAngleDegrees()));
		if (newBlob !is null)
		{
			newBlob.setAngleDegrees(this.getAngleDegrees());
		}

		CBlob @newBlob2 = server_CreateBlob(name, -1, this.getPosition() + Vec2f(0, (-this.getHeight() / 4) - 2).RotateBy(this.getAngleDegrees()));
		if (newBlob2 !is null)
		{
			newBlob2.setAngleDegrees(this.getAngleDegrees());
		}
	}
}

// collide with vehicles and structures	- hit stuff if thrown

bool doesCollideWithBlob(CBlob @ this, CBlob @blob)
{
	bool thrown = false;
	CPlayer @p = this.getDamageOwnerPlayer();
	CPlayer @bp = blob.getPlayer();
	if (p !is null && bp !is null && p.getTeamNum() != bp.getTeamNum())
	{
		thrown = true;
	}
	return (blob.getShape().isStatic() || (blob.isInWater() && blob.hasTag("vehicle")) ||
			(dangerous_logs && this.hasTag("thrown") && blob.hasTag("flesh") && thrown)); // boat
}

void onDetach(CBlob @ this, CBlob @detached, AttachmentPoint @attachedPoint)
{
	if (dangerous_logs)
	{
		this.Tag("thrown");
		this.SetDamageOwnerPlayer(detached.getPlayer());
		//	printf("thrown");
	}
}

void onCollision(CBlob @ this, CBlob @blob, bool solid)
{
	if (dangerous_logs && this.hasTag("thrown"))
	{
		if (blob is null || !blob.hasTag("flesh"))
		{
			return;
		}

		CPlayer @player = this.getDamageOwnerPlayer();
		if (player !is null && player.getTeamNum() != blob.getTeamNum())
		{
			const f32 dmg = this.getShape().vellen * 0.25f;
			if (dmg > 1.5f)
			{
				//	printf("un thrown " + dmg);
				this.server_Hit(blob, this.getPosition(), this.getVelocity(), dmg, Hitters::flying, false); // server_Hit() is server-side only
			}
			this.Untag("thrown");
		}
	}
}

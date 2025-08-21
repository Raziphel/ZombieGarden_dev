// scroll script that makes enemies insta gib within some radius

#include "Hitters.as";

void onInit(CBlob @ this)
{
	this.addCommandID("2weeks");
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("2weeks"), "Use this to skip 2 weeks in to the future (has consequences)", params);
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("2weeks"))
	{
		ParticleZombieLightning(this.getPosition());

		bool hit = false;
		CBlob @caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (getNet().isServer())
			{
				getRules().add_s32("days_offset", 14);
				getMap().SetDayTime(0.5);
				hit = true;
			}
		}

		if (hit)
		{
			this.server_Die();
			Sound::Play("2weeks.ogg");
		}
	}
}
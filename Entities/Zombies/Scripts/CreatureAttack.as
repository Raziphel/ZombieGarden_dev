// Aphelion \\

#include "Hitters.as";

void onInit(CBlob @ this)
{
	if (!this.exists("attack frequency"))
		this.set_u8("attack frequency", 30);

	if (!this.exists("attack distance"))
		this.set_f32("attack distance", 0.5f);

	if (!this.exists("attack damage"))
		this.set_f32("attack damage", 1.0f);

	if (!this.exists("attack hitter"))
		this.set_u8("attack hitter", Hitters::bite);

	if (!this.exists("attack sound"))
		this.set_string("attack sound", "ZombieBite");

	// The obstruction detector uses this to distinguish attacking a wall
	// from simply having no route to the target.
	this.set_u32("last_hit_time", getGameTime());

	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob @ this)
{
	// Server alone performs hit detection and damage. Duplicating arc
	// searches on clients wastes work for every member of a large horde.
	if (!isServer())
		return;

	CBrain @brain = this.getBrain();
	if (brain is null)
		return;

	CBlob @target = brain.getTarget();
	if (target !is null && !target.hasTag("dead"))
	{
		if (getGameTime() >= this.get_u32("next_attack"))
		{
			CMap @map = this.getMap();
			if (map is null)
				return;

			Vec2f pos = this.getPosition();

			const f32 radius = this.getRadius();
			const f32 attack_distance = radius + this.get_f32("attack distance");

			Vec2f vec = this.getAimPos() - pos;
			f32 angle = vec.Angle();

			HitInfo @[] hitInfos;

			if (map.getHitInfosFromArc(this.getPosition(), -angle, 90.0f, radius + attack_distance, this, @hitInfos))
			{
				for (uint i = 0; i < hitInfos.length; i++)
				{
					HitInfo @hi = hitInfos[i];
					if (hi is null)
						continue;

					CBlob @b = hi.blob;

					if (b !is null && b is target && !b.hasTag("dead"))
					{
						HitTarget(this, b);
						break;
					}
				}
			}
		}
	}
}

void HitTarget(CBlob @ this, CBlob @target)
{
	if (!isServer() || this is null || target is null || target.hasTag("dead"))
		return;

	Vec2f hitvel = Vec2f(this.isFacingLeft() ? -1.0 : 1.0, 0.0f);

	this.server_Hit(target, target.getPosition(), hitvel, this.get_f32("attack damage"), this.get_u8("attack hitter"), true);
	this.set_u32("last_hit_time", getGameTime());
	this.set_u32("next_attack", getGameTime() + this.get_u8("attack frequency"));
}

void onHitBlob(CBlob @ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob @hitBlob, u8 customData)
{
	if (!isClient() || damage <= 0.0f)
		return;

	CSprite @sprite = this.getSprite();
	if (sprite !is null)
		sprite.PlayRandomSound(this.get_string("attack sound"));
}
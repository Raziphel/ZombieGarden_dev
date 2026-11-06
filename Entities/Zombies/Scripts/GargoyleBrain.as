// Aphelion \\

#define SERVER_ONLY

#include "BrainCommon.as";
#include "CreatureCommon.as";
#include "PressOldKeys.as";


string[] names_to_taxi =
	{
		"abomination",
		"horror",
		"phellknight",
		"zbison",
		"pankou",
		"pbrute",
		"pcrawler",
		"zombieknight"};

void onInit(CBrain @ this)
{
	InitBrain(this);

	CBlob @blob = this.getBlob();
	if (blob is null)
		return;
	blob.set_u8(delay_property, 5 + XORRandom(5));

	if (!blob.exists(target_searchrad_property))
		blob.set_f32(target_searchrad_property, 512.0f);

	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain @ this)
{
	CBlob @blob = this.getBlob();
	if (blob is null)
		return;
	CBlob @target = this.getTarget();

	u8 delay = blob.get_u8(delay_property);
	if (delay > 0)
		delay--;

	if (delay == 0)
	{
		delay = 5 + XORRandom(10);

		// do we have a target?
		if (target !is null)
		{
			CBlob @carriedBlob = blob.getCarriedBlob();

			if (carriedBlob !is null && carriedBlob is target)
			{
				bool friendly = !carriedBlob.hasTag("survivorplayer");
				if (friendly)
				{
					// take 'em where they need to go
					CBrain @passengerBrain = carriedBlob.getBrain();
					CBlob @passengerTarget = passengerBrain is null ? null : passengerBrain.getTarget();
					if (passengerTarget !is null)
					{
						Vec2f mypos = blob.getPosition();
						Vec2f targetPos = passengerTarget.getPosition();

						if (getXBetween(targetPos, mypos) < 64.0f)
						{
							RemoveTarget(this);
						}
						else
						{
							// aim at the destination
							blob.setAimPos(targetPos);

							// fly to our destination
							FlyTo(blob, Vec2f(targetPos.x, getFlyHeight(targetPos.x)));

							// stay away from anything any nearby obstructions such as a tower
							DetectForwardObstructions(blob);

							// stay above the ground
							StayAboveGroundLevel(blob);
						}
					}

					// nope
					else
					{
						RemoveTarget(this);
					}
				}
				else
				{
					Vec2f pos = blob.getPosition();
					if (pos.y < 30)
					{
						// bye bye!
						carriedBlob.Tag("about to be dead");

						RemoveTarget(this);
					}
					else
					{
						FlyTo(blob, Vec2f(blob.getPosition().x, 10));
					}
				}
			}

			// need to pick the target up
			else
			{
				if (ShouldLoseTarget(blob, target))
				{
					RemoveTarget(this);
					return;
				}

				// chase target
				FlyTo(blob, target.getPosition());

				// aim at the target
				blob.setAimPos(target.getPosition());

				// stay away from anything any nearby obstructions such as a tower
				DetectForwardObstructions(blob);
			}
		}
		else
		{
			FlyAround(this, blob); // just fly around looking for a target
		}
	}
	else
	{
		PressOldKeys(blob);
	}

	blob.set_u8(delay_property, delay);
}

bool ShouldLoseTarget(CBlob @blob, CBlob @target)
{
	if (target.hasTag("dead"))
		return true;
	else if (target.isAttached())
		return true;
	else if (target.getDistanceTo(blob) > blob.get_f32(target_searchrad_property))
		return true;
	else
		return !isTargetVisible(blob, target);
}

void FlyAround(CBrain @ this, CBlob @blob)
{
	// look for a target along the way :)
	FindTarget(this, blob, blob.get_f32(target_searchrad_property));

	// get our destination
	Vec2f destination = blob.get_Vec2f(destination_property);

	if (!blob.exists(destination_property) || (destination - blob.getPosition()).Length() < 128 || XORRandom(30) == 0)
	{
		NewDestination(blob);
		return;
	}

	// aim at the destination
	blob.setAimPos(destination);

	// fly to our destination
	FlyTo(blob, destination);

	// stay away from anything any nearby obstructions such as a tower
	DetectForwardObstructions(blob);

	// stay above the ground
	StayAboveGroundLevel(blob);
}

void FindTarget(CBrain @ this, CBlob @blob, f32 radius, const bool taxiFriendly = false)
{
	CBlob @[] nearBlobs;
	CMap @map = blob.getMap();
	if (map is null || radius <= 0.0f)
		return;
	map.getBlobsInRadius(blob.getPosition(), radius, @nearBlobs);

	CBlob @closest_candidate;
	f32 closest_dist = 999999.9f;
	for (int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob @candidate = nearBlobs[step];
		if (candidate is null)
			continue;

		f32 dist = candidate.getDistanceTo(blob);
		if (dist < closest_dist && !candidate.isAttached() && !candidate.hasTag("dead") && !candidate.hasTag("about to be dead"))
		{
			bool target = false;

			if (taxiFriendly)
			{
				for (int i = 0; i < names_to_taxi.length; i++)
				{
					if (candidate.getName() == names_to_taxi[i])
					{
						target = isFriendlyInNeedOfService(candidate);
						break;
					}
				}
			}
			else
			{
				target = candidate.hasTag("survivorplayer");
			}

			if (target && isTargetVisible(blob, candidate))
			{
				@closest_candidate = candidate;
				closest_dist = dist;
			}
		}
	}

	// success?
	if (closest_candidate !is null)
	{
		this.SetTarget(closest_candidate);
		return;
	}

	// no players? well that's ok, we can taxi a friendly
	if (!taxiFriendly && XORRandom(30) == 0)
	{
		FindTarget(this, blob, radius, true);
	}
}

bool isFriendlyInNeedOfService(CBlob @friendly)
{
	if (friendly is null)
		return false;
	CBrain @brain = friendly.getBrain();
	CMap @map = friendly.getMap();
	if (brain is null || map is null)
		return false;
	CBlob @target = brain.getTarget();
	if (target is null || target.hasTag("dead"))
		return false;
	return getXBetween(target.getPosition(), friendly.getPosition()) > 256 ||
		map.rayCastSolid(friendly.getPosition(), target.getPosition());
}

void FlyTo(CBlob @blob, Vec2f destination)
{
	if (blob is null)
		return;

	const Vec2f pos = blob.getPosition();
	const f32 radius = blob.getRadius();
	CMap @map = blob.getMap();

	// Clear the opposite direction when turning. Previously both left
	// and right could remain pressed after the target changed sides.
	blob.setKeyPressed(key_left, destination.x < pos.x - 4.0f);
	blob.setKeyPressed(key_right, destination.x > pos.x + 4.0f);

	bool rise = destination.y < pos.y - 8.0f;
	if (map !is null && (blob.isKeyPressed(key_right) ||
		blob.isKeyPressed(key_left)))
	{
		const f32 side = blob.isKeyPressed(key_right) ? 1.0f : -1.0f;
		rise = rise || map.isTileSolid(pos + Vec2f(side * 1.3f * radius, radius));
	}
	blob.setKeyPressed(key_up, rise);
}

void DetectForwardObstructions(CBlob @blob)
{
	if (blob is null)
		return;
	CMap @map = blob.getMap();
	if (map is null)
		return;

	const Vec2f pos = blob.getPosition();
	const bool right = blob.isKeyPressed(key_right);
	const bool left = blob.isKeyPressed(key_left);
	if (!right && !left)
		return;

	const f32 direction = right ? 1.0f : -1.0f;
	// Trace from the actual creature, not the default world origin.
	if (map.rayCastSolid(pos, pos + Vec2f(direction * 96.0f, 0.0f)))
		blob.setKeyPressed(key_up, true);
}

void StayAboveGroundLevel(CBlob @blob)
{
	if (blob is null)
		return;
	if (getFlyHeight(blob.getPosition().x) < blob.getPosition().y)
		blob.setKeyPressed(key_up, true);
}

void NewDestination(CBlob @blob)
{
	CMap @map = getMap();
	if (map !is null)
	{
		f32 x = XORRandom(2) == 0 ? (map.tilemapwidth / 2 + XORRandom(map.tilemapwidth / 2)) * map.tilesize :
									(map.tilemapwidth / 2 - XORRandom(map.tilemapwidth / 2)) * map.tilesize;
		x = Maths::Min(s32(map.tilemapwidth * map.tilesize - 32), Maths::Max(32, s32(x)));

		// set destination
		blob.set_Vec2f(destination_property, Vec2f(x, getFlyHeight(x)));
	}
}

f32 getFlyHeight(int x)
{
	CMap @map = getMap();
	if (map !is null)
	{
		return Maths::Max(0.0f, map.getLandYAtX(s32(x / map.tilesize)) * map.tilesize - 128.0f);
	}
	return 0.0f;
}
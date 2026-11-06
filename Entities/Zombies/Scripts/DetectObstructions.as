// Aphelion \\

#define SERVER_ONLY

#include "CreatureCommon.as";
#include "RunnerCommon.as";

u16 OBSTRUCTION_THRESHOLD = 90; // 30 = 1 second
const string stuck_tag = "is_stuck";

// Give blocked zombies a nearby, attackable structure to work on instead of
// endlessly trying to path through the survivor's wall.
CBlob @FindBlockingFortification(CBlob @blob)
{
	CMap @map = blob.getMap();
	if (map is null)
		return null;

	CBlob @[] nearby;
	map.getBlobsInRadius(blob.getPosition(), 80.0f, @nearby);

	CBlob @best;
	f32 bestDist = 80.0f;
	for (uint i = 0; i < nearby.length; ++i)
	{
		CBlob @other = nearby[i];
		if (other is null || other is blob || other.hasTag("dead") ||
			other.getTeamNum() == blob.getTeamNum())
			continue;

		const string name = other.getName();
		if (name != "wooden_door" && name != "stone_door" &&
			!other.hasTag("survivorbuilding") && !other.hasTag("ruinstorch"))
			continue;

		if (!isTarget(blob, other) || !isTargetVisible(blob, other))
			continue;

		const f32 dist = other.getDistanceTo(blob);
		if (dist < bestDist)
		{
			@best = other;
			bestDist = dist;
		}
	}
	return best;
}

void HandleZombieObstruction(CBrain @brain, CBlob @blob)
{
	// Do not repeatedly clear navigation every tick when a wall cannot be
	// broken immediately. The attack script refreshes last_hit_time on hits.
	if (getGameTime() < blob.get_u32("zg_obstruction_retry"))
		return;
	blob.set_u32("zg_obstruction_retry", getGameTime() + OBSTRUCTION_THRESHOLD);

	CBlob @barrier = FindBlockingFortification(blob);
	brain.EndPath();
	ResetDestination(blob);

	if (barrier !is null)
	{
		brain.SetTarget(barrier);
		blob.Untag(stuck_tag);
		return;
	}

	RemoveTarget(brain);
	blob.Tag(stuck_tag);

	// Wraith-style enemies can react to being truly trapped, but do not
	// continuously broadcast the same enraged state.
	if (!blob.hasTag("enraged"))
	{
		blob.Tag("enraged");
		blob.Sync("enraged", true);
	}
}

void onInit(CBrain @ this)
{
	CBlob @blob = this.getBlob();
	if (blob is null)
		return;

	blob.set_u16(obstruction_threshold, 0);
	blob.set_u32("last_hit_time", getGameTime());

	this.getCurrentScript().removeIfTag = "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain @ this)
{
	CBlob @blob = this.getBlob();
	if (blob !is null)
		DetectObstructions(this, blob);
}

void DetectObstructions(CBrain @brain, CBlob @blob)
{
	if (blob is null || blob.hasTag("dead") || blob.hasTag("ignore_obstructions"))
		return;

	CMap @map = blob.getMap();
	if (map is null)
		return;

	u16 threshold = blob.get_u16(obstruction_threshold);
	Vec2f pos = blob.getPosition();
	const f32 radius = blob.getRadius();

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);

	const bool upwardWall = up &&
		map.isTileSolid(pos - Vec2f(0.0f, 1.3f * radius));
	const bool sideWall = ((left && !right &&
		map.isTileSolid(pos - Vec2f(1.1f * radius, 0.0f))) ||
		(right && !left &&
		map.isTileSolid(pos + Vec2f(1.1f * radius, 0.0f)))) &&
		Maths::Abs(blob.getVelocity().x) < 0.3f;

	if (upwardWall || sideWall)
	{
		if (threshold < OBSTRUCTION_THRESHOLD)
			threshold++;
	}
	else if (threshold > 0)
	{
		threshold--;
	}

	if (threshold >= OBSTRUCTION_THRESHOLD)
	{
		HandleZombieObstruction(brain, blob);
		threshold = 0;
	}
	else
	{
		// "Stuck" should be a transient state, not a permanent label.
		if (threshold == 0 && blob.hasTag(stuck_tag))
			blob.Untag(stuck_tag);

		RunnerMoveVars @moveVars;
		if (blob.get("moveVars", @moveVars) && moveVars !is null &&
			blob.hasTag("chomping") &&
			blob.getVelocity().Length() < moveVars.walkSpeed / 2 &&
			getGameTime() > blob.get_u32("last_hit_time") + OBSTRUCTION_THRESHOLD)
		{
			HandleZombieObstruction(brain, blob);
		}
	}

	blob.set_u16(obstruction_threshold, threshold);
}

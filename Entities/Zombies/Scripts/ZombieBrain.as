// Aphelion \\
// Improved by Vamist

#define SERVER_ONLY

#include "CreatureCommon.as";
#include "CreatureTargeting.as";
#include "BrainCommon.as";
#include "PressOldKeys.as";

const string VAR_TARGET_SEARCH = "next_target_time";
const string VAR_SEARCH_TIME   = "next_search_time";
const string VAR_RNG_SEARCH    = "rng_search_time";
const string VAR_RNG_COUNT     = "rng_path_count";
const string VAR_LAST_POS      = "last_known_pos";

void onInit( CBrain@ this )
{
	InitBrain( this );

	CBlob@ blob = this.getBlob();

	if (!blob.exists(target_searchrad_property))
		 blob.set_f32(target_searchrad_property, 512.0f);
	
	//this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	blob.set_Vec2f("destination_property", blob.getPosition());
	blob.set_u32(VAR_SEARCH_TIME,          getGameTime());
	blob.set_Vec2f(VAR_LAST_POS,           Vec2f_zero);
	blob.set_u16(VAR_RNG_COUNT,            0);

	this.failtime_end = 99999;
}

void onTick(CBrain@ this)
{
	CBlob@ target = this.getTarget();
	CBlob@ blob = this.getBlob();

	if (this.getState() == 4 && !blob.hasTag(VAR_OPT_OUT_STUCK))
	{
		blob.add_u16(VAR_RNG_SEARCH, 1);
	}

	// Damage if we're stuck or afk searching
	if (getRules().hasTag("night") && blob.get_u16(VAR_RNG_COUNT) > 50)
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f_zero, 1.0f, 0);
		blob.set_u32(VAR_RNG_COUNT, 0);
	}

	if (target !is null)
	{
		ChaseTarget(this, blob, target);
	}
	else
	{
		if (goToLastKnownPos(this, blob))
		{
			WalkAnywhereAndEverywhere(this, blob);
		}

		if (blob.get_u32(VAR_SEARCH_TIME) < getGameTime())
		{
			blob.set_u32(VAR_SEARCH_TIME, getGameTime() + 10);
			if (FindTarget(this, blob, blob.get_f32(target_searchrad_property)))
			{
				PathFindToTarget(this, blob, this.getTarget());
				FollowEnginePath(this);
			}
		}
	}
}

void ChaseTarget(CBrain@ brain, CBlob@ blob, CBlob@ target)
{
	// Reset the rng path count since we are now chasing a target
	blob.set_u16(VAR_RNG_COUNT, 0);

	if (!isTargetVisible(blob, target))
	{
		//print("not visible!");
		// If target dead or out of reach, lets untarget but continue in their general direction
		if (isTargetTooFar(blob, target) || isTargetDead(target))
		{
			brain.SetTarget(null);

			if (FindTarget(brain, blob, blob.get_f32(target_searchrad_property)))
			{
				PathFindToTarget(brain, blob, brain.getTarget());
				FollowEnginePath(brain);
			}
			else
			{
				WalkAnywhereAndEverywhere(brain, blob);
			}
			return;
		}
		else if (blob.get_u32(VAR_SEARCH_TIME) < getGameTime())
		{	
			if (XORRandom(101) < 31 && FindTarget(brain, blob, blob.get_f32(target_searchrad_property)))
			{
				PathFindToTarget(brain, blob, brain.getTarget());
				FollowEnginePath(brain);
			}
			else
				PathFindToTarget(brain, blob, target);
		}

		FollowEnginePath(brain);
	}
	else
	{
		if (brain.getPathSize() > 0)
			FollowEnginePath(brain);
		else
			WalkTowards(blob, target.getPosition());

		blob.set_Vec2f(VAR_LAST_POS, target.getPosition());
	}
}

void PathFindToTarget(CBrain@ brain, CBlob@ blob, CBlob@ target)
{
	brain.SetPathTo(target.getPosition(), false);

	blob.set_u32(VAR_SEARCH_TIME, getGameTime() + 60);
}

bool isTargetTooFar( CBlob@ blob, CBlob@ target )
{
	return getDistanceBetween(target.getPosition(), blob.getPosition()) > blob.get_f32(target_searchrad_property);
}

bool isTargetDead( CBlob@ target )
{
	return target.hasTag("dead");
}

void FollowEnginePath(CBrain@ brain)
{
	CBlob@ blob = brain.getBlob();
	CBlob@ target = brain.getTarget();

	if (target !is null && isTargetVisible(blob, target))
	{
		WalkTowards(blob, target.getPosition());
		return;
	}

	// Get the path we should be walking to
	Vec2f direction = brain.getPathPosition();

	// ENGINE BUG >:(((
	if (direction == Vec2f_zero)
	{
		if (target is null)
		{
			brain.EndPath();
			PressOldKeys(blob);
			return;
		}
		else
		{
			PathFindToTarget(brain, blob, target);
			direction = brain.getPathPosition();
		}
	}
	
	if (direction == brain.getNextPathPosition())
	{
		direction = brain.getClosestNodeAtPosition(direction);
	}

	WalkTowards(blob, direction);
}

void WalkTowards(CBlob@ blob, Vec2f pos)
{	
	if (pos == Vec2f_zero)
	{
		PressOldKeys(blob);
		return;
	}

	blob.setAimPos(pos);

	Vec2f dir = pos - blob.getPosition();
	//print(dir + '');
	blob.setKeyPressed(key_left, dir.x < -0.0f);
	blob.setKeyPressed(key_right, dir.x > 0.0f);
	blob.setKeyPressed(key_up, dir.y < -0.0f);
	blob.setKeyPressed(key_down, dir.y > 0.0f);
}

// Go to the last known position our target was at
// Returns true if we're at or dont have one
// Returns false if we are currently trying
bool goToLastKnownPos(CBrain@ brain, CBlob@ blob)
{
	Vec2f lastKnownPos = blob.get_Vec2f(VAR_LAST_POS);
	int pSize = brain.getPathSize();

	if (lastKnownPos == Vec2f_zero && pSize == 0)
		return true;

	if (pSize > 0)
		FollowEnginePath(brain);
	else
	{
		brain.SetPathTo(lastKnownPos, false);
		FollowEnginePath(brain);
		
		blob.set_Vec2f(VAR_LAST_POS, lastKnownPos);
	}

	return false;
}

bool FindTarget( CBrain@ this, CBlob@ blob, f32 radius )
{
	this.SetTarget(GetBestTarget(this, blob, radius));
	return this.getTarget() !is null;
}

void WalkAnywhereAndEverywhere(CBrain@ brain, CBlob@ blob)
{
	Vec2f dir = blob.get_Vec2f(destination_property);
	
	int len = (blob.getPosition() - dir).Length();

	// Start a new rng path
	if (len > 0 && len < 20.0f)
	{
		blob.set_u32(VAR_RNG_SEARCH, 0);
	}

	if (blob.get_u32(VAR_RNG_SEARCH) < getGameTime())
	{
		blob.set_u32(VAR_RNG_SEARCH, getGameTime() + 60);

		if (!blob.hasTag(VAR_OPT_OUT_STUCK))
			blob.add_u16(VAR_RNG_COUNT, 1);

		dir = blob.getPosition() + getRandomVelocity(0, 100, 360);

		getMap().rayCastSolidNoBlobs(blob.getPosition(), dir, dir);
		blob.set_Vec2f(destination_property, dir);
	}

	WalkTowards(blob, dir);
}
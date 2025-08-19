// Aphelion \\
// Improved by Vamist (light-touch cleanup & bugfix pass + awareness)

#define SERVER_ONLY

#include "CreatureCommon.as";
#include "CreatureTargeting.as";
#include "BrainCommon.as";
#include "PressOldKeys.as";

const string VAR_TARGET_SEARCH = "next_target_time";
const string VAR_SEARCH_TIME   = "next_search_time";
const string VAR_RNG_SEARCH    = "rng_search_time";   // used as u32 timer
const string VAR_RNG_COUNT     = "rng_path_count";    // u16 counter
const string VAR_LAST_POS      = "last_known_pos";

// NEW: wide awareness ping timer
const string VAR_LONGSCAN_TIME = "30";

const u32 FIND_COOLDOWN_TICKS  = 10;    // small throttle for target scans
const u32 PATH_COOLDOWN_TICKS  = 60;    // debounce path requests
const f32 LASTPOS_REACH_DIST   = 12.0f; // distance considered "arrived"
const u16 STUCK_PUNISH_LIMIT   = 50;    // how many rng steps before damage

// NEW: awareness tuning (can be overridden per-blob if you want)
const f32 DEFAULT_AWARENESS_MULT = 2.5f;  // how far “scent” reaches vs normal
const u32 LONGSCAN_COOLDOWN_TICKS = 45;   // ~1.5s at 30 tps

void onInit(CBrain@ this)
{
	InitBrain(this);

	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (!blob.exists(target_searchrad_property))
		blob.set_f32(target_searchrad_property, 1024.0f);

	// Allow optional per-blob override
	if (!blob.exists("awareness_mult"))
		blob.set_f32("awareness_mult", DEFAULT_AWARENESS_MULT);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	blob.set_Vec2f("destination_property", blob.getPosition());
	blob.set_u32(VAR_SEARCH_TIME,  getGameTime());
	blob.set_Vec2f(VAR_LAST_POS,   Vec2f_zero);
	blob.set_u16(VAR_RNG_COUNT,    0);
	blob.set_u32(VAR_RNG_SEARCH,   getGameTime());     // initialize timer
	blob.set_u32(VAR_LONGSCAN_TIME, getGameTime());    // initialize timer

	this.failtime_end = 99999;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	CBlob@ target = this.getTarget();

	// Only count rng search steps when brain reports "searching" and not opted out
	if (this.getState() == 4 && !blob.hasTag(VAR_OPT_OUT_STUCK))
	{
		blob.add_u32(VAR_RNG_SEARCH, 1);
	}

	// Small self-damage if stuck/idle-searching too long at night
	if (getRules().hasTag("night") && blob.get_u16(VAR_RNG_COUNT) > STUCK_PUNISH_LIMIT)
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f_zero, 1.0f, 0);
		blob.set_u16(VAR_RNG_COUNT, 0);
	}

	if (target !is null)
	{
		ChaseTarget(this, blob, target);
		return;
	}

	// No target yet: wide "awareness" scan to bias direction
	doLongRangeAwarenessScan(this, blob);

	// Go to last known pos, or wander + periodic scans
	if (goToLastKnownPos(this, blob))
	{
		WalkAnywhereAndEverywhere(this, blob);
	}

	if (blob.get_u32(VAR_SEARCH_TIME) < getGameTime())
	{
		blob.set_u32(VAR_SEARCH_TIME, getGameTime() + FIND_COOLDOWN_TICKS);
		if (FindTarget(this, blob, blob.get_f32(target_searchrad_property)))
		{
			PathFindToTarget(this, blob, this.getTarget());
			FollowEnginePath(this);
		}
	}
}

void ChaseTarget(CBrain@ brain, CBlob@ blob, CBlob@ target)
{
	blob.set_u16(VAR_RNG_COUNT, 0);

	if (!isTargetVisible(blob, target))
	{
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

		if (blob.get_u32(VAR_SEARCH_TIME) < getGameTime())
		{
			blob.set_u32(VAR_SEARCH_TIME, getGameTime() + FIND_COOLDOWN_TICKS);

			if (XORRandom(101) < 31 && FindTarget(brain, blob, blob.get_f32(target_searchrad_property)))
			{
				PathFindToTarget(brain, blob, brain.getTarget());
				FollowEnginePath(brain);
			}
			else
			{
				PathFindToTarget(brain, blob, target);
			}
		}

		FollowEnginePath(brain);
		return;
	}

	if (brain.getPathSize() > 0)
		FollowEnginePath(brain);
	else
		WalkTowards(blob, target.getPosition());

	blob.set_Vec2f(VAR_LAST_POS, target.getPosition());
}

void PathFindToTarget(CBrain@ brain, CBlob@ blob, CBlob@ target)
{
	if (target is null) return;

	brain.SetPathTo(target.getPosition(), false);
	blob.set_u32(VAR_SEARCH_TIME, getGameTime() + PATH_COOLDOWN_TICKS);
}

bool isTargetTooFar(CBlob@ blob, CBlob@ target)
{
	return getDistanceBetween(target.getPosition(), blob.getPosition()) > blob.get_f32(target_searchrad_property);
}

bool isTargetDead(CBlob@ target)
{
	return target.hasTag("dead");
}

void FollowEnginePath(CBrain@ brain)
{
	CBlob@ blob = brain.getBlob();
	if (blob is null) return;

	CBlob@ target = brain.getTarget();
	if (target !is null && isTargetVisible(blob, target))
	{
		WalkTowards(blob, target.getPosition());
		return;
	}

	Vec2f direction = brain.getPathPosition();

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
	if (blob is null || pos == Vec2f_zero)
	{
		PressOldKeys(blob);
		return;
	}

	blob.setAimPos(pos);

	Vec2f dir = pos - blob.getPosition();
	blob.setKeyPressed(key_left,  dir.x <  0.0f);
	blob.setKeyPressed(key_right, dir.x >  0.0f);
	blob.setKeyPressed(key_up,    dir.y <  0.0f);
	blob.setKeyPressed(key_down,  dir.y >  0.0f);
}

// Go to the last known position our target was at.
// Returns true if we have no last-pos or we've arrived; false if we're en route.
bool goToLastKnownPos(CBrain@ brain, CBlob@ blob)
{
	Vec2f lastKnownPos = blob.get_Vec2f(VAR_LAST_POS);
	const int pSize = brain.getPathSize();

	if (lastKnownPos == Vec2f_zero && pSize == 0)
		return true;

	if (lastKnownPos != Vec2f_zero && (blob.getPosition() - lastKnownPos).Length() <= LASTPOS_REACH_DIST)
	{
		blob.set_Vec2f(VAR_LAST_POS, Vec2f_zero);
		return true;
	}

	if (pSize > 0)
	{
		FollowEnginePath(brain);
	}
	else
	{
		brain.SetPathTo(lastKnownPos, false);
		FollowEnginePath(brain);
	}

	return false;
}

bool FindTarget(CBrain@ this, CBlob@ blob, f32 radius)
{
	this.SetTarget(GetBestTarget(this, blob, radius));
	return this.getTarget() !is null;
}

// ---------- NEW: awareness scan + wander bias ----------

// Occasionally do a much wider scan to get a "hint" direction.
// Doesn’t set a hard target; just updates VAR_LAST_POS and nudges pathing.
void doLongRangeAwarenessScan(CBrain@ brain, CBlob@ blob)
{
	const u32 now = getGameTime();
	if (blob.get_u32(VAR_LONGSCAN_TIME) > now) return;

	blob.set_u32(VAR_LONGSCAN_TIME, now + LONGSCAN_COOLDOWN_TICKS);

	const f32 baseR = blob.get_f32(target_searchrad_property);
	const f32 mult  = blob.get_f32("awareness_mult"); // can override per-blob
	const f32 wideR = baseR * (mult > 0.1f ? mult : DEFAULT_AWARENESS_MULT);

	// Use the same “best target” logic, just with a bigger circle.
	CBlob@ distant = GetBestTarget(brain, blob, wideR);
	if (distant is null) return;

	// Store hint and request a short path burst in that general direction
	blob.set_Vec2f(VAR_LAST_POS, distant.getPosition());

	// Light path nudge (don’t spam, just a step toward the hint)
	brain.SetPathTo(distant.getPosition(), false);
}

// Wander, but gently bias toward our last-known/hint when we have one.
void WalkAnywhereAndEverywhere(CBrain@ brain, CBlob@ blob)
{
	Vec2f dir = blob.get_Vec2f(destination_property);
	const f32 dist = (blob.getPosition() - dir).Length();

	if (dist > 0.0f && dist < 20.0f)
	{
		blob.set_u32(VAR_RNG_SEARCH, 0);
	}

	if (blob.get_u32(VAR_RNG_SEARCH) < getGameTime())
	{
		blob.set_u32(VAR_RNG_SEARCH, getGameTime() + PATH_COOLDOWN_TICKS);

		if (!blob.hasTag(VAR_OPT_OUT_STUCK))
			blob.add_u16(VAR_RNG_COUNT, 1);

		Vec2f pos = blob.getPosition();

		// Base random wander
		Vec2f rnd = getRandomVelocity(0, 100, 360);

		// Bias toward last known / awareness hint if we have one
		Vec2f hint = blob.get_Vec2f(VAR_LAST_POS);
		if (hint != Vec2f_zero)
		{
			Vec2f bias = (hint - pos);
			if (bias.LengthSquared() > 1.0f)
			{
				bias.Normalize();
				// Mix: 70% random, 30% bias for a gentle pull
				rnd = rnd * 0.7f + bias * 120.0f * 0.3f;
			}
		}

		Vec2f goal = pos + rnd;

		CMap@ map = getMap();
		if (map !is null)
		{
			map.rayCastSolidNoBlobs(pos, goal, goal);
		}

		blob.set_Vec2f(destination_property, goal);
	}

	WalkTowards(blob, blob.get_Vec2f(destination_property));
}

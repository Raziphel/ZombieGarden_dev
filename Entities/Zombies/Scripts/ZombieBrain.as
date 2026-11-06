// Aphelion \\
// Improved by Vamist (light-touch cleanup & bugfix pass + awareness)

#define SERVER_ONLY

#include "BrainCommon.as";
#include "CreatureCommon.as";
#include "CreatureTargeting.as";
#include "PressOldKeys.as";


const string VAR_TARGET_SEARCH = "next_target_time";
const string VAR_SEARCH_TIME = "next_search_time";
const string VAR_RNG_SEARCH = "rng_search_time"; // used as u32 timer
const string VAR_RNG_COUNT = "rng_path_count";	 // u16 counter
const string VAR_LAST_POS = "last_known_pos";

// NEW: wide awareness ping timer
const string VAR_LONGSCAN_TIME = "zg_longscan_time";
const string VAR_PATH_RETRY_TIME = "zg_next_path_retry";
const string VAR_LAST_PATH_GOAL = "zg_last_path_goal";

const u32 FIND_COOLDOWN_TICKS = 10;	  // small throttle for target scans
const u32 PATH_COOLDOWN_TICKS = 60;	  // debounce path requests
const f32 LASTPOS_REACH_DIST = 12.0f; // distance considered "arrived"
const u16 STUCK_PUNISH_LIMIT = 50;	  // how many rng steps before damage

// NEW: awareness tuning (can be overridden per-blob if you want)
const f32 DEFAULT_AWARENESS_MULT = 2.5f; // how far “scent” reaches vs normal
const u32 LONGSCAN_COOLDOWN_TICKS = 90;	 // ~3s at 30 tps; fewer expensive wide scans

void onInit(CBrain @ this)
{
	InitBrain(this);

	CBlob @blob = this.getBlob();
	if (blob is null)
		return;

	if (!blob.exists(target_searchrad_property))
		blob.set_f32(target_searchrad_property, 1024.0f);

	// Allow optional per-blob override
	if (!blob.exists("awareness_mult"))
		blob.set_f32("awareness_mult", DEFAULT_AWARENESS_MULT);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	blob.set_Vec2f("destination_property", blob.getPosition());
	// Spread scans from freshly spawned hordes across server ticks.
	blob.set_u32(VAR_SEARCH_TIME, getGameTime() + XORRandom(FIND_COOLDOWN_TICKS));
	blob.set_Vec2f(VAR_LAST_POS, Vec2f_zero);
	blob.set_u16(VAR_RNG_COUNT, 0);
	blob.set_u32(VAR_RNG_SEARCH, getGameTime());	// initialize timer
	blob.set_u32(VAR_PATH_RETRY_TIME, 0);
	blob.set_Vec2f(VAR_LAST_PATH_GOAL, Vec2f_zero);
	blob.set_u32(VAR_LONGSCAN_TIME,
		getGameTime() + XORRandom(LONGSCAN_COOLDOWN_TICKS));

	this.failtime_end = 99999;
}

void onTick(CBrain @ this)
{
	CBlob @blob = this.getBlob();
	if (blob is null)
		return;

	CBlob @target = this.getTarget();
	if (target !is null && (target.hasTag("dead") || !isTarget(blob, target)))
	{
		this.SetTarget(null);
		@target = null;
	}

	// VAR_RNG_SEARCH is an absolute tick deadline, not a counter.
	// Wander steps are already counted with VAR_RNG_COUNT when paths renew.

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

void ChaseTarget(CBrain @brain, CBlob @blob, CBlob @target)
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

void PathFindToTarget(CBrain @brain, CBlob @blob, CBlob @target)
{
	if (target is null || blob is null)
		return;

	const u32 now = getGameTime();
	const Vec2f goal = target.getPosition();
	const Vec2f previousGoal = blob.get_Vec2f(VAR_LAST_PATH_GOAL);
	const Vec2f pathDelta = goal - previousGoal;
	const f32 pathDeltaSq = pathDelta.x * pathDelta.x + pathDelta.y * pathDelta.y;

	// A blocked doorway can otherwise cause a full path request on every
	// single tick. Retry periodically, unless the target actually moved.
	if (now < blob.get_u32(VAR_PATH_RETRY_TIME) &&
		pathDeltaSq < 32.0f * 32.0f)
		return;

	brain.SetPathTo(goal, false);
	blob.set_Vec2f(VAR_LAST_PATH_GOAL, goal);
	blob.set_u32(VAR_PATH_RETRY_TIME, now + PATH_COOLDOWN_TICKS);
	blob.set_u32(VAR_SEARCH_TIME, now + PATH_COOLDOWN_TICKS);
}

bool isTargetTooFar(CBlob @blob, CBlob @target)
{
	return getDistanceBetween(target.getPosition(), blob.getPosition()) > blob.get_f32(target_searchrad_property);
}

bool isTargetDead(CBlob @target)
{
	return target.hasTag("dead");
}

void FollowEnginePath(CBrain @brain)
{
	CBlob @blob = brain.getBlob();
	if (blob is null)
		return;

	CBlob @target = brain.getTarget();
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
			if (direction == Vec2f_zero)
			{
				// No route yet. Keep pressing toward the obstacle while the
				// throttled pathfinder looks for another opening.
				WalkTowards(blob, target.getPosition());
				return;
			}
		}
	}

	if (direction == brain.getNextPathPosition())
	{
		direction = brain.getClosestNodeAtPosition(direction);
	}

	WalkTowards(blob, direction);
}

void WalkTowards(CBlob @blob, Vec2f pos)
{
	if (blob is null)
		return;

	if (pos == Vec2f_zero)
	{
		PressOldKeys(blob);
		return;
	}

	blob.setAimPos(pos);

	Vec2f dir = pos - blob.getPosition();
	blob.setKeyPressed(key_left, dir.x < 0.0f);
	blob.setKeyPressed(key_right, dir.x > 0.0f);
	blob.setKeyPressed(key_up, dir.y < 0.0f);
	blob.setKeyPressed(key_down, dir.y > 0.0f);
}

// Go to the last known position our target was at.
// Returns true if we have no last-pos or we've arrived; false if we're en route.
bool goToLastKnownPos(CBrain @brain, CBlob @blob)
{
	Vec2f lastKnownPos = blob.get_Vec2f(VAR_LAST_POS);
	const int pSize = brain.getPathSize();

	if (lastKnownPos == Vec2f_zero)
	{
		// Follow any already scheduled path without requesting a bogus
		// path to world coordinate (0, 0).
		if (pSize > 0)
		{
			FollowEnginePath(brain);
			return false;
		}
		return true;
	}

	if ((blob.getPosition() - lastKnownPos).Length() <= LASTPOS_REACH_DIST)
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

bool FindTarget(CBrain @ this, CBlob @blob, f32 radius)
{
	this.SetTarget(GetBestTarget(this, blob, radius));
	return this.getTarget() !is null;
}

// ---------- NEW: awareness scan + wander bias ----------

// Occasionally do a much wider scan to get a "hint" direction.
// Doesn’t set a hard target; just updates VAR_LAST_POS and nudges pathing.
void doLongRangeAwarenessScan(CBrain @brain, CBlob @blob)
{
	const u32 now = getGameTime();
	if (blob.get_u32(VAR_LONGSCAN_TIME) > now)
		return;

	blob.set_u32(VAR_LONGSCAN_TIME, now + LONGSCAN_COOLDOWN_TICKS);

	const f32 baseR = blob.get_f32(target_searchrad_property);
	const f32 mult = blob.get_f32("awareness_mult"); // can override per-blob
	const f32 wideR = baseR * (mult > 0.1f ? mult : DEFAULT_AWARENESS_MULT);

	// Use the same “best target” logic, just with a bigger circle.
	CBlob @distant = GetBestTarget(brain, blob, wideR);
	if (distant is null)
		return;

	// Do not request the same expensive path again while the previous
	// hint is still being followed. Keep scanning as the horde moves.
	const Vec2f hint = distant.getPosition();
	const Vec2f hintDelta = blob.get_Vec2f(VAR_LAST_POS) - hint;
	const f32 hintDeltaSq = hintDelta.x * hintDelta.x + hintDelta.y * hintDelta.y;
	if (hintDeltaSq < 48.0f * 48.0f && brain.getPathSize() > 0)
		return;

	blob.set_Vec2f(VAR_LAST_POS, hint);
	brain.SetPathTo(hint, false);
}

// Wander, but gently bias toward our last-known/hint when we have one.
void WalkAnywhereAndEverywhere(CBrain @brain, CBlob @blob)
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
			if (bias.x * bias.x + bias.y * bias.y > 1.0f)
			{
				bias.Normalize();
				// Mix: 70% random, 30% bias for a gentle pull
				rnd = rnd * 0.7f + bias * 120.0f * 0.3f;
			}
		}

		Vec2f goal = pos + rnd;

		CMap @map = getMap();
		if (map !is null)
		{
			map.rayCastSolidNoBlobs(pos, goal, goal);
		}

		blob.set_Vec2f(destination_property, goal);
	}

	WalkTowards(blob, blob.get_Vec2f(destination_property));
}

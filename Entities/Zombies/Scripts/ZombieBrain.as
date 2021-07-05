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

	if (target !is null)
	{
		//print("chasing target " + target.getName());
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

	// No target in sight? damage!
	if (blob.get_u16(VAR_RNG_COUNT) > 50)
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f_zero, 1.0f, 0);
		blob.set_u16(VAR_RNG_COUNT, 0);
	}

	if (blob.get_u32(VAR_RNG_SEARCH) < getGameTime())
	{
		blob.set_u32(VAR_RNG_SEARCH, getGameTime() + 60);
		blob.add_u16(VAR_RNG_COUNT, 1);

		dir = blob.getPosition() + getRandomVelocity(0, 100, 360);

		getMap().rayCastSolidNoBlobs(blob.getPosition(), dir, dir);
		blob.set_Vec2f(destination_property, dir);
	}

	WalkTowards(blob, dir);
}

/*

void onTick( CBrain@ this )
{
	CBlob@ blob = this.getBlob();
	CBlob@ target = this.getTarget();

	u8 delay = blob.get_u8(delay_property);
	delay--;

	if (delay == 0)
	{
		delay = 5 + XORRandom(10);

		// do we have a target?
		if (target !is null)
		{
			blob.set_u16("rng_count", 0);

			bool icu = isTargetVisible(blob, target);
			// Target not visible, let's try use some path finding to get to it
			if (!icu)
			{
				if (getGameTime() > blob.get_u32("lowlevel_research_time"))
				{
					// Mostly low level, with some high level when useful
					this.SetPathTo(target.getPosition(), false);

					// Tell the bot to use low level path suggestions
					blob.set_bool("lowlevel_search", true);
					blob.set_u32("lowlevel_research_time", getGameTime() + 60);
				}

				if (isTargetTooFar(blob, target))
				{
					print("target is too far, removing");
					this.SetTarget(null);
					return;
				}
			}
			else
			{	
				// Zombie will go to the targets last known pos after its lost the target
				blob.set_Vec2f("last_search_pos", target.getPosition());
			}

			if (isTargetDead(target))
			{
				print("target has died!");
				this.SetTarget(null);
				return;
			}

			// aim always at enemy
			blob.setAimPos( target.getPosition() );

			PathTo( blob, target.getPosition() );

			// destroy any attackable obstructions such as doors
			//DestroyAttackableObstructions( this, blob );
		}
		else
		{
			print("hi ..?");

			if (blob.hasTag("is_stuck"))
				blob.Untag("is_stuck");

			GoSomewhere(this, blob); // just walk around looking for a target
		}
	}
	else
	{
		Vec2f destination = blob.get_Vec2f(destination_property);
		if (destination != Vec2f_zero)
			PathTo( blob, destination );
		else
			PressOldKeys(blob);
	}

	blob.set_u8(delay_property, delay);
}

bool FindTarget( CBrain@ this, CBlob@ blob, f32 radius )
{
	*//*if (blob.hasTag("search_through_walls") || blob.hasTag("is_stuck"))
		this.SetTarget(GetBestTarget(this, blob, radius));
	else
		this.SetTarget(GetClosestVisibleTarget(this, blob, radius));*//*

	this.SetTarget(GetBestTarget(this, blob, radius));

	return this.getTarget() !is null;
}

void GoSomewhere( CBrain@ this, CBlob@ blob )
{
	Vec2f lastKnownPos = blob.get_Vec2f("last_search_pos");
	//bool hasTarget = GoSomewhere(this, blob);

	if (this.getTarget() !is null && lastKnownPos != Vec2f_zero)
	{
		print("doing dumb-ish");
		int len = (blob.getPosition() - lastKnownPos).Length();

		if (len > 0 && len < 20.0f)
		{
			blob.set_Vec2f("last_search_pos", Vec2f_zero);
		}
		
		blob.set_Vec2f(destination_property, lastKnownPos);

		// Mostly low level, with some high level when useful
		this.SetPathTo(lastKnownPos, false);

		// Tell the bot to use low level path suggestions
		blob.set_bool("lowlevel_search", true);
		blob.set_u32("lowlevel_research_time", getGameTime() + 1);
	}
	else if (FindTarget(this, blob, blob.get_f32(target_searchrad_property)))
	{
		print("doing smart");

		this.SetPathTo(this.getTarget().getPosition(), false);

		blob.set_bool("lowlevel_search", true);
		blob.set_u32("lowlevel_research_time", getGameTime() + 1);

		PathTo(blob, Vec2f(1,1));
		return;
	} 
	else
	{
		print("doing dumb");
		int len = (blob.getPosition() - blob.get_Vec2f(destination_property)).Length();

		// Start a new rng path
		if (len > 0 && len < 20.0f)
		{
			blob.set_u32("next_rng_search", 0);
		}

		// Stuck with no target more then 100 times..?
		if (blob.get_u16("rng_count") > 50)
		{
			blob.server_Hit(blob, blob.getPosition(), Vec2f_zero, 1.0f, 0);
			blob.set_u16("rng_count", 0);
		}

		if (blob.get_u32("next_rng_search") < getGameTime())
		{
			blob.set_u32("next_rng_search", getGameTime() + 60);
			blob.add_u16("rng_count", 1);

			Vec2f hitPos = blob.getPosition() + getRandomVelocity(0, 100, 360);

			getMap().rayCastSolidNoBlobs(blob.getPosition(), hitPos, hitPos);
			blob.set_Vec2f(destination_property, hitPos);
		}
	}

	// get our destination
	Vec2f destination = blob.get_Vec2f(destination_property);

	PathTo( blob, destination );
				
	// scale walls and jump over small blocks
	//ScaleObstacles( blob, destination );
			
	// destroy any attackable obstructions such as doors
	DestroyAttackableObstructions( this, blob );
}


void PathTo( CBlob@ blob, Vec2f destination )
{
	CBrain@ brain = blob.getBrain();
	CBlob@ target = brain.getTarget();

	if (blob.get_bool("lowlevel_search"))
	{
		bool was_zero = false;
		destination = brain.getPathPosition();

		// ENGINE BUG >:(((
		if (destination == Vec2f_zero)
		{
			destination == brain.getNextPathPosition();
			was_zero = true;
		}

		// Happens if we are extremely close
		if (destination != blob.get_Vec2f(destination_property) && destination == blob.getPosition() && target !is null)
		{
			print("close");
			destination = target.getPosition();
		}

		int len = (blob.getPosition() - destination).Length();
		//print(len + '');

		blob.set_u8(delay_property, 1);

		if (len > 0 && len < 10.0f ) // && (target is null || isTargetVisible(blob, target)))
		{
			if (brain.getNextPathPosition() == destination && !was_zero)
			{
				print("end");
				//brain.EndPath();
				blob.set_bool("lowlevel_search", false);
				onTick(brain);
				return;
			}
		}


		if (was_zero)
			return;
	}

	blob.setAimPos(destination);

	Vec2f dir = destination - blob.getPosition();

	print(destination + '');

	blob.setKeyPressed(key_left, dir.x < -0.0f);
	blob.setKeyPressed(key_right, dir.x > 0.0f);
	blob.setKeyPressed(key_up, dir.y < -0.0f);
	blob.setKeyPressed(key_down, dir.y > 0.0f);

	//print(destination + '');
}

void ScaleObstacles( CBlob@ blob, Vec2f destination )
{
	Vec2f mypos = blob.getPosition();

	const f32 radius = blob.getRadius();
	// check if possibly touching other zombies
	bool touchingOther = !blob.isOnGround() && blob.getTouchingCount() > 0;
	// if we're touching someone, check if it's a zombie
	if (touchingOther)
	{
		touchingOther = false;
		const uint count = blob.getTouchingCount();
		for (uint step = 0; step < count; ++step)
		{
			CBlob@ _blob = blob.getTouchingByIndex(step);
			if (_blob.hasTag("zombie"))
			{
				touchingOther = true;
				break;
			}
		}
	}

	if (blob.isOnLadder() || (blob.isInWater() && !blob.hasTag("is_stuck")))
	{	
		blob.setKeyPressed(destination.y < mypos.y ? key_up : key_down, true);
	}
	else if (touchingOther || blob.isOnWall() || (blob.hasTag("is_stuck") && blob.isInWater()))
	{
		blob.setKeyPressed(key_up, true);
	}
	else
	{
		if ((blob.isKeyPressed(key_right)  && (getMap().isTileSolid( mypos + Vec2f( 1.3f * radius, radius) * 1.0f ) || blob.getShape().vellen < 0.1f)) ||
			(blob.isKeyPressed(key_left )  && (getMap().isTileSolid( mypos + Vec2f(-1.3f * radius, radius) * 1.0f ) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}

void DestroyAttackableObstructions( CBrain@ this, CBlob@ blob )
{
	Vec2f col;

	if (getMap().rayCastSolid(blob.getPosition(), blob.getAimPos(), col))
	{
		CBlob@ obstruction = getMap().getBlobAtPosition(col);

		if (isTarget(blob, obstruction))
		{
			print("changing target!");
			this.SetTarget(obstruction);
		}
	}
}

void NewDestination( CBlob@ blob )
{
	CMap@ map = getMap();

	if (map !is null)
	{
		Vec2f destination = Vec2f_zero;

		// go somewhere near the center of the map if we have just spawned
		if(!blob.exists(destination_property))
		{
			f32 x = XORRandom(2) == 0 ? map.tilemapwidth / 2 + XORRandom(map.tilemapwidth / 4) :
										map.tilemapwidth / 2 - XORRandom(map.tilemapwidth / 4);
			
			x *= map.tilesize;
			x = Maths::Min(s32(map.tilemapwidth * map.tilesize - 32), Maths::Max(32, s32(x)));

			destination = Vec2f(x, map.getLandYAtX(s32(x / map.tilesize)) * map.tilesize);
		}

		// somewhere near
		else
		{
			int rand = XORRandom(4);
			f32 x = rand == 0 ? map.tilemapwidth / 2 + XORRandom(map.tilemapwidth / 2) :
					rand == 1 ?	map.tilemapwidth / 2 - XORRandom(map.tilemapwidth / 2) :
					rand == 2 ? blob.getPosition().x + XORRandom(map.tilemapwidth / 4) :
								blob.getPosition().x - XORRandom(map.tilemapwidth / 4);
			
			x *= map.tilesize;
			x = Maths::Min(s32(map.tilemapwidth * map.tilesize - 32), Maths::Max(32, s32(x)));
			
			destination = Vec2f(x, map.getLandYAtX(s32(x / map.tilesize)) * map.tilesize);
		}
		
		// aim at destination
		blob.setAimPos(destination);

		// set destination
		blob.set_Vec2f(destination_property, destination);
	}
}*/
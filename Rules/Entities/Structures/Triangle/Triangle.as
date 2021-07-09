
#include "Hitters.as"
#include "MapFlags.as"

const string state_prop = "state";

enum tri_state {
	normal = 0,
	falling
};

void onInit(CBlob@ this)
{
    this.getSprite().getConsts().accurateLighting = true;
    this.getSprite().SetZ(100);
   //this.set_TileType("background tile", CMap::tile_castle_back);
    
    f32 angle = this.getAngleDegrees();
    f32 offset = 1.0f;    
    this.getShape().SetOffset(Vec2f(-offset,offset));

	this.getCurrentScript().tickFrequency = 10;

    this.Tag("place ignore facing");
	this.Tag("blocks sword");
	//this.Tag("blocks water");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;		 
}

class CheckParameters {
	bool onSurface;
};

void tileCheck( CBlob@ this, CMap@ map, Vec2f pos, CheckParameters@ params )
{
	TileType t = map.getTile(pos).type;	
	if(map.isTileSolid(t))
	{
		params.onSurface = true;
	}
}

void onTick(CBlob@ this)
{
    CMap@ map = getMap();
    Vec2f pos = this.getPosition();
    const f32 tilesize = map.tilesize;

	//get prop

	tri_state state = tri_state( this.get_u8(state_prop) );
	
	//check support/placement status 
	bool onSurface;
	
	if(state != falling)
	{
		CheckParameters temp;
		temp.onSurface = false;

		f32 angle = this.getAngleDegrees();
	    if (angle == 0)
	    {		
			tileCheck( this, map, pos + Vec2f(-tilesize, 0.0f), temp ); //left
			tileCheck( this, map, pos + Vec2f(0.0f, tilesize),  temp ); //down
		}
		else if (angle == 90)
		{
			tileCheck( this, map, pos + Vec2f(-tilesize, 0.0f),temp ); //left
			tileCheck( this, map, pos + Vec2f(0.0f, -tilesize),  temp ); //up
		}
		else if (angle == 180)
		{			
			tileCheck( this, map, pos + Vec2f(tilesize, 0.0f), temp ); //right
			tileCheck( this, map, pos + Vec2f(0.0f, -tilesize),  temp ); //up
		}
		else if (angle == 270)
		{
			tileCheck( this, map, pos + Vec2f(tilesize, 0.0f), temp ); //right
			tileCheck( this, map, pos + Vec2f(0.0f, tilesize),  temp ); //down
		}
		
		onSurface = temp.onSurface;
	}
	
	if(!onSurface)
	{
		this.getCurrentScript().tickFrequency = 0;
		this.getShape().SetStatic(false);
		this.server_SetTimeToDie(3);		
		state = falling;
	}

	if(state == falling)
	{
		this.set_u8(state_prop, state);
		return;
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	tri_state state = tri_state( this.get_u8(state_prop) );
	if(state == falling)
	{
		return (!blob.hasTag("flesh"));
	}

	return true;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point )
{
    if (!getNet().isServer() || this.isAttached()) { // map collision? not server?
        return;
    }  
    if (solid)
	{
		if (blob !is null && blob.getTeamNum() != this.getTeamNum() && !blob.hasTag("flesh"))
			this.server_Die();
	}   
}


bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
	f32 dmg = damage;
	switch(customData)
	{
	case Hitters::builder:
		dmg *= 2.9f;
		break;
			
	case Hitters::bomb:
		dmg = 1.2f;
		break;

	case Hitters::keg:
		dmg = 10.0f;
		break;
	case Hitters::arrow:
		dmg = 0.0f;
		break;

	case Hitters::cata_stones:
		dmg = 2.0f;
		break;
		
	case Hitters::sword:
		dmg *= 0.0f;
		break;
	default:
		dmg *= 1.0f;
		break;
	}		
	return dmg;
}


void onDie(CBlob@ this)
{
	// Gib if health below 0.0f
	if (this.getSprite() !is null && this.getHealth() <= 0.0f)
	{
		this.getSprite().Gib();
	}
}


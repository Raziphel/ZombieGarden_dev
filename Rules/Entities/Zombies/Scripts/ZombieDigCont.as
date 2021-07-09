//Don't know who made this script originally, I tweaked it a bit to make it work with more zombies

//#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 40; //how often is the script executed
	this.getCurrentScript().removeIfTag	= "dead";
}

void onTick(CBlob@ this)
{
    if (!getNet().isServer()) {
        return;
    }

    Vec2f pos = this.getPosition();
    CMap@ map = this.getMap();
    float step = map.tilesize;
    float radius = step * this.get_f32("dig radius"); //radius of destruction

    for (float x = pos.x - radius; x < pos.x + radius; x += step)
    {
        for (float y = pos.y - radius; y < pos.y + radius; y += step)
        {
            Vec2f tpos = Vec2f(x, y);
            TileType tile = map.getTile(tpos).type; 
			
			//we don't want to destroy bedrock
            if (map.isTileBedrock(tile)) 
			{
                continue;
            }
			
			//how strong will the damage on tiles be
            map.server_DestroyTile(tpos, this.get_f32("dig damage"), this);		
        }
    }
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	
	ParticleAnimated( "/ToxicPush.png", blob.getPosition(), Vec2f(0,0), 0.0f, 1.0f, 1.5f, -0.1f, false ); 
	blob.getSprite().PlaySound( "ExtinguishFire.ogg" );	
}
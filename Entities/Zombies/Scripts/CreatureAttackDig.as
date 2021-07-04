//original script by XeonFaux

#include "Hitters.as";

void onInit(CBlob@ this)
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

	this.getCurrentScript().removeIfTag	= "dead";
}

void onTick(CBlob@ this)
{
	if (!getNet().isServer())
		return;

	if (getGameTime() >= this.get_u32("next_attack"))
	{
		Vec2f pos = this.getPosition();

		f32 radius = this.getRadius();
		f32 attack_distance = radius + this.get_f32("attack distance");

		CMap@ map = this.getMap();

		f32 aimangle = (this.getAimPos() - pos).Angle();

		if (getGameTime() >= this.get_u32("next_attack"))
		{
			HitInfo@[] hitInfos;

			if (map.getHitInfosFromArc(pos, aimangle, 90.0f, radius + attack_distance, this, @hitInfos))
			{
				for (uint i = 0; i < hitInfos.length; i++)
				{
					HitInfo@ hi = hitInfos[i];
					CBlob@ blob = hi.blob;
					if (blob !is null && blob.getTeamNum() != this.getTeamNum())
					{
						Vec2f hitvel = Vec2f(this.isFacingLeft() ? -1.0 : 1.0, 0.0f);
						
						this.server_Hit(blob, blob.getPosition(), hitvel, this.get_f32("attack damage"), this.get_u8("attack hitter"), true);
					}
					else
					{
						TileType tile = hi.tile;
						if (tile != CMap::tile_bedrock)
						{
							Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
							Vec2f offset = (tpos - pos);
							f32 tileangle = offset.Angle();
							f32 dif = Maths::Abs(aimangle - tileangle);
							if (dif > 180)
								dif -= 360;
							if (dif < -180)
								dif += 360;

							dif = Maths::Abs(dif);

							if (dif < 20.0f)
							{
								int check_x = -(offset.x > 0 ? -1 : 1);
								int check_y = -(offset.y > 0 ? -1 : 1);
								if (map.isTileSolid(hi.hitpos - Vec2f(map.tilesize * check_x, 0)) &&
										map.isTileSolid(hi.hitpos - Vec2f(0, map.tilesize * check_y)))
									continue;

								map.server_DestroyTile(hi.hitpos, this.get_f32("attack damage") * 3.0, this); //default 0.1
							}
						}
					}
				}
			}

			if (aimangle >= 0.0f && aimangle <= 180.0f)
			{
				f32 tilesize = map.tilesize;
				int steps = Maths::Ceil(2 * radius / tilesize);
				int sign = this.isFacingLeft() ? -1 : 1;

				for (int y = 0; y < steps; y++)
				{
					for (int x = 0; x < steps; x++)
					{
						Vec2f tilepos = pos + Vec2f(x * tilesize * sign, y * tilesize);
						TileType tile = map.getTile(tilepos).type;

						if (map.isTileStone(tile) || map.isTileThickStone(tile) || map.isTileGold(tile) || map.isTileGrass(tile) || map.isTileSand(tile) || map.isTileGroundStuff(tile))
						{
							map.server_DestroyTile(tilepos, this.get_f32("attack damage") * 0.3, this); //default 0.3
						}
					}
				}
			}
		}

		this.set_u32("next_attack", getGameTime() + this.get_u8("attack frequency"));
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{		 
	if (damage > 0.0f)
	{
		this.getSprite().PlayRandomSound(this.get_string("attack sound"));
	}
}
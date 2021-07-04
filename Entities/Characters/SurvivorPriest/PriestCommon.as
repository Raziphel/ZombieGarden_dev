const int TELEPORT_FREQUENCY = 4 * 30; //4 secs
const int TELEPORT_DISTANCE = 160;//getMap().tilesize;

const int FIRE_FREQUENCY = 30;
const f32 ORB_SPEED = 4.0f;
const u8 ORB_LIMIT = 5;
const u32 ORB_BURST_COOLDOWN = 6 * 30; //6 secs
const float ORB_TIME_TO_DIE = 5.0f;


namespace OrbType
{
enum type
{
    normal = 0,
    fire,
	bomb,
	water,
	count
};
}

namespace PriestVars
{
const ::s32 resheath_time = 5;

const ::s32 orb_power = 15;
const ::s32 orb_power2 = 38;
const ::s32 slash_charge_limit = orb_power2+orb_power+10;
}

shared class PriestInfo
{
	bool has_orb;
	u8 orb_type;

	PriestInfo()
	{
		has_orb = false;
		orb_type = OrbType::normal;
	}
};

const string[] orbTypeNames = { "mat_orbs",
                                  "mat_fireorbs",
								  "mat_bomborbs",
								  "mat_waterorbs"
                                };
const string[] orbNames = { "Regular Orb",
                              "Fire Orb",
							  "Bomb Orb",
							  "Water Orb"
                            };

const string[] orbIcons = { "$Orb$",
							  "$FireOrb$",
							  "$BombOrb$",
							  "$WaterOrb$"
};

u8 getOrbType( CBlob@ this )
{
	PriestInfo@ priest;
	if (!this.get( "priestInfo", @priest )) {
		return 0;

	}						 
	return priest.orb_type;
}
void SetOrbType( CBlob@ this, const u8 type )
{
	PriestInfo@ priest;
	if (!this.get( "priestInfo", @priest )) {
		return;

	}		  	
	priest.orb_type = type;
}

bool hasOrbs( CBlob@ this )
{
	PriestInfo@ priest;
	if (!this.get( "priestInfo", @priest )) {
		return false;

	}
	if (priest.orb_type >= 0 && priest.orb_type < orbTypeNames.length) {
		return this.getBlobCount( orbTypeNames[priest.orb_type] ) > 0;
	}

	return false;
}
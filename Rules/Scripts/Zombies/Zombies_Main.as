// Zombies_Main.as
#define SERVER_ONLY

#include "Structs.as"
#include "RespawnSystem.as"
#include "RulesCore.as"

// Include order matters: Core defines ZombiesCore, Spawns defines
// ZombiesSpawns, Config uses ZombiesCore in its function signature.
#include "Zombies_Boss.as"
#include "Zombies_Config.as" // uses ZombiesCore in function signature
#include "Zombies_Core.as"	 // defines class ZombiesCore and uses ZombiesSpawns
#include "Zombies_Spawns.as" // defines class ZombiesSpawns
#include "Zombies_Utils.as"

// Entry hooks
void onInit(CRules @ this)
{
	Reset(this);
}
void onRestart(CRules @ this)
{
	Reset(this);
}

void Reset(CRules @ this)
{
	printf("Restarting rules script: " + getCurrentScriptName());

	ZombiesSpawns spawns();
	ZombiesCore core(this, spawns);
	Config(core);

	// spawn initial portals/graves from map markers
	Vec2f[] zombiePlaces;
	getMap().getMarkers("zombie alter", zombiePlaces);
	for (int i = 0; i < zombiePlaces.length; i++)
		spawnPortal(zombiePlaces[i]);

	Vec2f[] gravePlaces;
	getMap().getMarkers("grave", gravePlaces);
	for (int i = 0; i < gravePlaces.length; i++)
		spawnGraves(gravePlaces[i]);

	// all players start as survivors with clean stats and spawn instantly
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer @p = getPlayer(i);
		if (p !is null)
		{
			p.server_setTeamNum(0);
			// wipe round-specific stats so nothing carries over
			p.setKills(0);
			p.setDeaths(0);
			p.setAssists(0);
			p.setScore(0);
			p.set_u8("killstreak", 0);

			// clear any leftover respawn timer from the previous round
			// so everyone spawns instantly on the new map
			// Track each player's respawn countdown using a unique
			// property name.  The previous implementation used
			// "Zombies spawn time" which clashed with scripts that
			// accessed the property as a u8 and spammed the console
			// with type‑mismatch warnings.  Using a mod‑specific
			// prefix avoids the conflict.
			const string propname = "zg spawn time " + p.getUsername();
			this.set_u16(propname, 0);
			this.SyncToPlayer(propname, p);
		}
	}

	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time",
				 getGameTime() + core.gameDuration); // TimeToEnd.as
}

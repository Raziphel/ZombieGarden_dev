// Zombies_Main.as
#define SERVER_ONLY

#include "CTF_Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"

// Include order matters: Core defines ZombiesCore, Spawns defines ZombiesSpawns,
// Config uses ZombiesCore in its function signature.
#include "Zombies_Spawns.as"   // defines class ZombiesSpawns
#include "Zombies_Core.as"    // defines class ZombiesCore and uses ZombiesSpawns
#include "Zombies_Config.as"  // uses ZombiesCore in function signature
#include "Zombies_Utils.as"
#include "Zombies_Boss.as"


// Entry hooks
void onInit(CRules@ this)    { Reset(this); }
void onRestart(CRules@ this) { Reset(this); }

void Reset(CRules@ this)
{
	printf("Restarting rules script: " + getCurrentScriptName());

	ZombiesSpawns spawns();
	ZombiesCore   core(this, spawns);
	Config(core);

	// spawn initial portals/graves from map markers
	Vec2f[] zombiePlaces; getMap().getMarkers("zombie portal", zombiePlaces);
	for (int i = 0; i < zombiePlaces.length; i++) spawnPortal(zombiePlaces[i]);

	Vec2f[] gravePlaces; getMap().getMarkers("grave", gravePlaces);
	for (int i = 0; i < gravePlaces.length; i++) spawnGraves(gravePlaces[i]);

	// all players start as survivors
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p !is null) p.server_setTeamNum(0);
	}

	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration); // TimeToEnd.as
}

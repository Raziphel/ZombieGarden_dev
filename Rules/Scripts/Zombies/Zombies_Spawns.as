// Zombies_Spawns.as
#include "Core/Structs.as"
#include "RulesCore.as"
#include "RespawnSystem.as"

// Forward so this file can refer to the type name
//class ZombiesCore;

const s32 spawnspam_limit_time = 10;

class ZombiesSpawns : RespawnSystem
{
	ZombiesCore@ Zombies_core;

	bool force;
	s32 limit;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@Zombies_core = cast<ZombiesCore@>(core);

		limit = spawnspam_limit_time;
		getRules().set_bool("everyones_dead", false);
	}

	void Update()
	{
		int everyone_dead = 0;
		int total_count = Zombies_core.players.length;
		for (uint team_num = 0; team_num < Zombies_core.teams.length; ++team_num)
		{
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[team_num]);

			for (uint i = 0; i < team.spawns.length; i++)
			{
				CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(team.spawns[i]);

				UpdateSpawnTime(info, i);
				if (info !is null)
				{
					if (info.can_spawn_time > 0) everyone_dead++;
				}

				DoSpawnPlayer(info);
			}
		}

		if (getRules().isMatchRunning())
		{
			if (everyone_dead == total_count && total_count != 0) getRules().set_bool("everyones_dead", true);
		}
	}

        void UpdateSpawnTime(CTFPlayerInfo@ info, int i)
        {
            if (info !is null)
            {
                u8 spawn_property = 255;

                // can_spawn_time is an absolute game time. Convert it into a
                // remaining second countdown for the HUD.
                if (info.can_spawn_time > getGameTime())
                {
                    const s32 diff = info.can_spawn_time - getGameTime();
                    spawn_property = u8(Maths::Min(200, diff / getTicksASecond()));
                }
                else if (info.can_spawn_time > 0)
                {
                    // ensure it doesn't stay positive once the timer has elapsed
                    info.can_spawn_time = 0;
                }

                string propname = "Zombies spawn time " + info.username;

                Zombies_core.rules.set_u8(propname, spawn_property);
                Zombies_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
            }
        }

	bool SetMaterials(CBlob@ blob, const string &in name, const int quantity)
	{
		CInventory@ inv = blob.getInventory();

		if (inv.isInInventory(name, quantity))
			return false;

		inv.server_RemoveItems(name, quantity);

		CBlob@ mat = server_CreateBlob(name);
		if (mat !is null)
		{
			mat.Tag("do not set materials");
			mat.server_SetQuantity(quantity);
			if (!blob.server_PutInInventory(mat))
			{
				mat.setPosition(blob.getPosition());
			}
		}

		return true;
	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		if (canSpawnPlayer(p_info))
		{
			if (limit > 0) { limit--; return; }
			else { limit = spawnspam_limit_time; }

			CPlayer@ player = getPlayerByUsername(p_info.username);

			if (player is null)
			{
				RemovePlayerFromSpawn(p_info);
				return;
			}

			// remove previous blob
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer(null);
				blob.server_Die();
			}

			u8 undead = player.getTeamNum();

			if (undead == 0)      p_info.blob_name = "builder";
			else if (undead == 1) p_info.blob_name = "undeadbuilder";

			CBlob@ playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info), p_info);

			if (playerBlob !is null)
			{
				p_info.spawnsCount++;
				RemovePlayerFromSpawn(player);
				u8 blobfix = player.getTeamNum();

				if (playerBlob.getTeamNum() != blobfix)
				{
					playerBlob.server_setTeamNum(blobfix);
					warn("Team " + blobfix);
				}
			}
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(p_info);

		if (info is null)
		{
			warn("Zombies LOGIC: Couldn't get player info ( in bool canSpawnPlayer(PlayerInfo@ p_info) ) ");
			return false;
		}

                // can_spawn_time stores the absolute tick when spawning is allowed
                return info.can_spawn_time <= getGameTime();
        }

	Vec2f getSpawnLocation(PlayerInfo@ p_info)
	{
		// null & map guard
		if (p_info is null)
		{
			CMap@ m0 = getMap();
			if (m0 is null) return Vec2f(0, 0);
			f32 x0 = (XORRandom(2) == 0 ? 32.0f : m0.tilemapwidth * m0.tilesize - 32.0f);
			return Vec2f(x0, m0.getLandYAtX(s32(x0 / m0.tilesize)) * m0.tilesize - 16.0f);
		}

		CMap@ map = getMap();
		if (map is null) return Vec2f(0, 0);

		// prefer team from PlayerInfo; fallback to live player if needed
		u8 teamNum = p_info.team;
		if (teamNum > 1)
		{
			// try to read from actual player if in an unexpected team
			CPlayer@ player = getPlayerByUsername(p_info.username);
			if (player !is null) teamNum = player.getTeamNum();
		}

		if (teamNum == 0)
		{
			// --- team 0: try "altarrevival" first ---
			CBlob@[] dorms;
			getBlobsByName("altarrevival", @dorms);
			for (uint i = 0; i < dorms.length; i++)
			{
				if (dorms[i] !is null)
				{
					return dorms[i].getPosition();
				}
			}

			// fallback: random "zombieruins" spawn
			CBlob@[] spawns0;
			getBlobsByName("zombieruins", @spawns0);
			if (spawns0.length > 0)
			{
				return spawns0[XORRandom(spawns0.length)].getPosition();
			}
		}
		else if (teamNum == 1)
		{
			// --- team 1: try "undeadstatue" first ---
			CBlob@[] undeadstatues;
			getBlobsByName("undeadstatue", @undeadstatues);
			for (uint i = 0; i < undeadstatues.length; i++)
			{
				if (undeadstatues[i] !is null)
				{
					// particles are client-side; guard to avoid server-only contexts breaking
					if (isClient())
					{
						ParticleZombieLightning(undeadstatues[i].getPosition());
					}
					return undeadstatues[i].getPosition();
				}
			}

			// fallback: random "zombieruins" spawn
			CBlob@[] spawns1;
			getBlobsByName("zombieruins", @spawns1);
			if (spawns1.length > 0)
			{
				return spawns1[XORRandom(spawns1.length)].getPosition();
			}
		}

		// ultimate fallback: map edge ground
		f32 x = (XORRandom(2) == 0 ? 32.0f : map.tilemapwidth * map.tilesize - 32.0f);
		return Vec2f(x, map.getLandYAtX(s32(x / map.tilesize)) * map.tilesize - 16.0f);
	}


	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
	}

	void RemovePlayerFromSpawn(PlayerInfo@ p_info)
	{
		CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(p_info);

		if (info is null) { warn("Zombies LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

		string propname = "Zombies spawn time " + info.username;

		for (uint i = 0; i < Zombies_core.teams.length; i++)
		{
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				team.spawns.erase(pos);
				break;
			}
		}

		Zombies_core.rules.set_u8(propname, 255);
		Zombies_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));

		info.can_spawn_time = 0;
	}

void AddPlayerToSpawn(CPlayer@ player)
{
	getRules().Sync("gold_structures", true);

	s32 tickspawndelay = 0;

	// optional: base spawn time from rules (seconds) -> ticks
	s32 base_spawn_secs = getRules().exists("spawn_time") ? getRules().get_s32("spawn_time") : 0;
	if (base_spawn_secs < 0) base_spawn_secs = 0;

	if (player.getDeaths() != 0)
	{
		int gamestart   = getRules().get_s32("gamestart");
		int day_cycle   = getRules().daycycle_speed * 60; // seconds in a full KAG day
		int timeElapsed = ((getGameTime() - gamestart) / getTicksASecond()) % day_cycle;
		int half_day    = day_cycle / 2;

		int seconds_to_midday = (timeElapsed <= half_day)
		                      ? (half_day - timeElapsed)
		                      : (day_cycle - timeElapsed + half_day);

		// cap at 30s, then add base spawn time
		int final_secs = Maths::Min(60 * 30, seconds_to_midday) + base_spawn_secs;
		if (final_secs < 0) final_secs = 0;

		tickspawndelay = final_secs * getTicksASecond();
	}
	else
	{
		// first life; just use base spawn time if any
		if (base_spawn_secs > 0)
			tickspawndelay = base_spawn_secs * getTicksASecond();
	}

	CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(core.getInfoFromPlayer(player));
	if (info is null)
	{
		warn("Zombies LOGIC: Couldn't get player info (in AddPlayerToSpawn)"); 
		return;
	}

	RemovePlayerFromSpawn(player);
	if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
		return;

	if (info.team < Zombies_core.teams.length)
	{
		CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[info.team]);

		// IMPORTANT: can_spawn_time is absolute, not a delay.
		info.can_spawn_time = getGameTime() + tickspawndelay;

		info.spawn_point = player.getSpawnPoint();
		team.spawns.push_back(info);

		// Seed the client HUD timer (u8 seconds, 255 = ready)
		const string hudKey = "Zombies spawn time " + player.getUsername();
		u8 hudSecs = 255;
		if (tickspawndelay > 0)
		{
			int s = tickspawndelay / getTicksASecond();
			hudSecs = u8(Maths::Clamp(s, 0, 254));
		}
		getRules().set_u8(hudKey, hudSecs);
		getRules().Sync(hudKey, true);
	}
	else
	{
		error("PLAYER TEAM NOT SET CORRECTLY!");
	}
}


	bool isSpawning(CPlayer@ player)
	{
		CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(core.getInfoFromPlayer(player));
		for (uint i = 0; i < Zombies_core.teams.length; i++)
		{
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				return true;
			}
		}
		return false;
	}
}

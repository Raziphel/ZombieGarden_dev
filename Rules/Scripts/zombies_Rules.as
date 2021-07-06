//Zombies gamemode logic script
//Modded by Eanmig (Edited by Frikman)
//Updated by RB-RaZeR and Frikman 

#define SERVER_ONLY

#include "CTF_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";

//simple config function - edit the variables below to change the basics

void Config(ZombiesCore@ this)
{

    string configstr = "../Mods/" + sv_gamemode + "/Rules/zombies_vars.cfg";
	if (getRules().exists("Zombiesconfig")) 
	{
	   configstr = getRules().get_string("Zombiesconfig");
	}
	ConfigFile cfg = ConfigFile( configstr );
	
	
	// remove game time limit
	this.gameDuration = 0;
	getRules().set_bool("no timer", true);
	
	bool grave_spawn = cfg.read_bool("grave_spawn",true);
	s32 max_zombies = cfg.read_s32("max_zombies",90);
	s32 max_pzombies = cfg.read_s32("max_pzombies",30);
	s32 max_migrantbots = cfg.read_s32("max_migrantbots",2);
	s32 max_wraiths = cfg.read_s32("max_wraiths",9);
	s32 max_gregs = cfg.read_s32("max_gregs",6);
	
	getRules().set_s32("max_zombies", max_zombies);
	getRules().set_s32("max_pzombies", max_pzombies);
	getRules().set_s32("max_migrantbots", max_migrantbots);
	getRules().set_s32("max_wraiths", max_wraiths);
	getRules().set_s32("max_gregs", max_gregs);
	
	getRules().set_bool("grave_spawn", true);
	getRules().set_bool("zombify", cfg.read_bool("zombify", false));
	getRules().set_s32("days_to_survive", cfg.read_s32("days_to_survive", 100));
	getRules().set_s32("curse_day", cfg.read_s32("curse_day", 30));
	
    //spawn after death time 
    this.spawnTime = (getTicksASecond() * cfg.read_s32("spawn_time", 30));
	
}

//Zombies spawn system

const s32 spawnspam_limit_time = 10;
shared string base_name() { return "ruinstorch"; }



shared class ZombiesSpawns : RespawnSystem
{
    ZombiesCore@ Zombies_core;

    bool force;
    s32 limit;
	
	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@Zombies_core = cast<ZombiesCore@>(core);
		
		limit = spawnspam_limit_time;
		getRules().set_bool("everyones_dead",false);
	}

    void Update()
    {
		int everyone_dead=0;
		int total_count=Zombies_core.players.length;
        for (uint team_num = 0; team_num < Zombies_core.teams.length; ++team_num )
        {
            CTFTeamInfo@ team = cast<CTFTeamInfo@>( Zombies_core.teams[team_num] );

            for (uint i = 0; i < team.spawns.length; i++)
            {
                CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(team.spawns[i]);
                
                UpdateSpawnTime(info, i);
				if ( info !is null )
				{
					if (info.can_spawn_time>0) everyone_dead++;
					//total_count++;
				}
				
                DoSpawnPlayer( info );
            }
        }
		
		if (getRules().isMatchRunning())
		{
			if (everyone_dead == total_count && total_count!=0) getRules().set_bool("everyones_dead",true); 
			// if (getGameTime() % (10*getTicksASecond()) == 0) warn("ED:"+everyone_dead+" TC:"+total_count);
		}
    }
    
    void UpdateSpawnTime(CTFPlayerInfo@ info, int i)
    {
		if ( info !is null )
		{
			u8 spawn_property = 255;
			
			if(info.can_spawn_time > 0) 
			{
				info.can_spawn_time--;
				spawn_property = u8(Maths::Min(200,(info.can_spawn_time / 30)));
			}
			
			string propname = "Zombies spawn time "+info.username;
			
			Zombies_core.rules.set_u8( propname, spawn_property );
			Zombies_core.rules.SyncToPlayer( propname, getPlayerByUsername(info.username) );
		}
	}

	bool SetMaterials( CBlob@ blob,  const string &in name, const int quantity )
	{
		CInventory@ inv = blob.getInventory();

		//already got them?
		if(inv.isInInventory(name, quantity))
			return false;

		//otherwise...
		inv.server_RemoveItems(name, quantity); //shred any old ones

		CBlob@ mat = server_CreateBlob( name );
		if (mat !is null)
		{
			mat.Tag("do not set materials");
			mat.server_SetQuantity(quantity);
			if (!blob.server_PutInInventory(mat))
			{
				mat.setPosition( blob.getPosition() );
			}
		}

		return true;
	}

    void DoSpawnPlayer( PlayerInfo@ p_info )
    {
        if (canSpawnPlayer(p_info))
        {
			//limit how many spawn per second
			if(limit > 0)
			{
				limit--;
				return;
			}
			
			else
			{
				limit = spawnspam_limit_time;
			}	
			
            CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

            if (player is null)
            {
				RemovePlayerFromSpawn(p_info);
                return;
            }
            /*if (player.getTeamNum() != int(p_info.team)) //this forced players to respawn always on blue
            {
				player.server_setTeamNum(p_info.team);
				warn("team"+p_info.team);
			}*/			

			// remove previous players blob	  			
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer( null );
				blob.server_Die();					
			}
			
			u8 undead = player.getTeamNum();
			
			if (undead == 0)
			{
				p_info.blob_name = "builder"; //hard-set the survivors respawn blob
			}
			
			else if (undead == 1)
			{
				p_info.blob_name = "undeadbuilder"; //hard-set the undead respawn blob
			}
			
            CBlob@ playerBlob = SpawnPlayerIntoWorld( getSpawnLocation(p_info), p_info);

            if (playerBlob !is null)
            {
                p_info.spawnsCount++;
                RemovePlayerFromSpawn(player);
				u8 blobfix = player.getTeamNum(); //hacky solution for player blobs not being the team color
				
				if (playerBlob.getTeamNum()!=blobfix)
				{
					playerBlob.server_setTeamNum(blobfix);
					warn("Team "+blobfix);
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

		//return true;
        //if (force) { return true; }

        return info.can_spawn_time <= 0;
    }

    Vec2f getSpawnLocation(PlayerInfo@ p_info)
    {
        CTFPlayerInfo@ c_info = cast<CTFPlayerInfo@>(p_info);
		if(c_info !is null)
        {
			CMap@ map = getMap();
			if(map !is null)
			{
				CPlayer@ player = getPlayerByUsername(p_info.username);
				u8 lemo = player.getTeamNum();
				
				if (lemo == 0) //survivors spawn point
				{
					CBlob@[] dorms;
					getBlobsByName("altarrevival", @dorms);
					for (int n = 0; n < dorms.length; n++)
					if(dorms[n] !is null) //check if we still have dorms and spawn us there
					{
						return Vec2f(dorms[n].getPosition()); 
					}	
				}
				
				else if (lemo == 1) //undead spawn point
				{
					CBlob@[] undeadstatues;
					getBlobsByName("undeadstatue", @undeadstatues);
					for (int n = 0; n < undeadstatues.length; n++)
					if(undeadstatues[n] !is null) //check if we still have undeadstatues and spawn us there
					{
						ParticleZombieLightning(undeadstatues[n].getPosition());
						return Vec2f(undeadstatues[n].getPosition()); 
					}										
				}
			}

        }

		CBlob@[] zombie_ruins;
		getBlobsByName("zombie_ruins", @zombie_ruins);
		int n = XORRandom(zombie_ruins.length);
		if(zombie_ruins[n] !is null) //check if we still have zombie_ruins and spawn us there		
			{
				ParticleZombieLightning(zombie_ruins[n].getPosition());
				return Vec2f(zombie_ruins[n].getPosition()); 
			}

		CMap@ map = getMap();
		f32 x = XORRandom(2) == 0 ? 32.0f : map.tilemapwidth * map.tilesize - 32.0f;
		return Vec2f(x, map.getLandYAtX(s32(x/map.tilesize))*map.tilesize - 16.0f);	//in case undeadstatues/dorms are missing spawn us at the edge of the map

    }

    void RemovePlayerFromSpawn(CPlayer@ player)
    {
        RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
    }
    
    void RemovePlayerFromSpawn(PlayerInfo@ p_info)
    {
        CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(p_info);
        
        if (info is null) { warn("Zombies LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

        string propname = "Zombies spawn time "+info.username;
        
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
		
		Zombies_core.rules.set_u8( propname, 255 ); //not respawning
		Zombies_core.rules.SyncToPlayer( propname, getPlayerByUsername(info.username) ); 
		
		info.can_spawn_time = 0;
	}

    void AddPlayerToSpawn( CPlayer@ player )
    {
		getRules().Sync("gold_structures",true);
		s32 tickspawndelay = 0;
		if (player.getDeaths() != 0)
		{
			int gamestart = getRules().get_s32("gamestart");
			int day_cycle = getRules().daycycle_speed*60;
			int timeElapsed = ((getGameTime()-gamestart)/getTicksASecond()) % day_cycle;
			int spawnlimit = (((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1)*300; //could be used to increase the maximum spawn time each day
			tickspawndelay = Maths::Min((60 * 30),((day_cycle - timeElapsed)*getTicksASecond()));//(day_cycle - timeElapsed)*getTicksASecond();
			if (timeElapsed<30) tickspawndelay=0;
		}
		
        CTFPlayerInfo@ info = cast<CTFPlayerInfo@>(core.getInfoFromPlayer(player));

        if (info is null) 
		{ 
			warn("Zombies LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; 
		}

		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;
			
		if (info.team < Zombies_core.teams.length)
		{
			CTFTeamInfo@ team = cast<CTFTeamInfo@>(Zombies_core.teams[info.team]);
			
			info.can_spawn_time = tickspawndelay;
			
			info.spawn_point = player.getSpawnPoint();
			team.spawns.push_back(info);
		}
		
		else
		{
			error("PLAYER TEAM NOT SET CORRECTLY!");
		}
    }

	bool isSpawning( CPlayer@ player )
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

};

shared class ZombiesCore : RulesCore
{
    s32 warmUpTime;
    s32 gameDuration;
    s32 spawnTime;

    ZombiesSpawns@ Zombies_spawns;

    ZombiesCore() {}

    ZombiesCore(CRules@ _rules, RespawnSystem@ _respawns )
    {
        super(_rules, _respawns );
    }
    
    void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
    {
        RulesCore::Setup(_rules, _respawns);
        @Zombies_spawns = cast<ZombiesSpawns@>(_respawns);
        server_CreateBlob("music", 0, Vec2f(0, 0));
		int gamestart = getGameTime();
		rules.set_s32("gamestart",gamestart);
		rules.SetCurrentState(WARMUP);
    }

    void Update()
    {
		if (rules.isGameOver()) 
		{ 
			return; 
		}
		
		//day cycle and transition
		int day_cycle = getRules().daycycle_speed * 60;
		int transition = rules.get_s32("transition");
		
		//current and max values for zombies, migrants, etc
		int max_zombies = rules.get_s32("max_zombies");
		int num_zombies = rules.get_s32("num_zombies");
		int max_pzombies = rules.get_s32("max_pzombies");
		int num_pzombies = rules.get_s32("num_pzombies");
		int max_migrantbots = rules.get_s32("max_migrantbots");
		int num_migrantbots = rules.get_s32("num_migrantbots");
		int max_wraiths = rules.get_s32("max_wraiths");
		int num_wraiths = rules.get_s32("num_wraiths");
		int max_gregs = rules.get_s32("max_gregs");
		int num_gregs = rules.get_s32("num_gregs");

		
		//game start
		int gamestart = rules.get_s32("gamestart");

		// update zombie portal, undead player and survivor player count
		CBlob@[] zombiePortal_blobs;
		getBlobsByTag("ZP", @zombiePortal_blobs );
		rules.set_s32("num_zombiePortals", zombiePortal_blobs.length);
		int num_zombiePortals = rules.get_s32("num_zombiePortals");

		CBlob@[] survivors_blobs;
		getBlobsByTag("survivorplayer", @survivors_blobs );
		rules.set_s32("num_survivors", survivors_blobs.length);
		int num_survivors = rules.get_s32("num_survivors");
		
		/*
		CBlob@[] undead_blobs;
		getBlobsByTag("undeadplayer", @undead_blobs );
		rules.set_s32("num_undead", undead_blobs.length);
		int num_undead = rules.get_s32("num_undead");
		*/
		
		int num_survivors_p = 0;
		int num_undead = 0;

		//on-screen message.
		int dayNumber = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;
		rules.SetGlobalMessage("❧ Day: " + dayNumber + "\n❧ Alters: " + num_zombiePortals  + "\n❧ Zombies: " + (num_zombies+num_pzombies) + "/120");

		//Difficulty settings
		int timeElapsed = getGameTime()-gamestart;
		float difficulty = dayNumber*0.5; //default 50% of the days
		float zombdiff = dayNumber*1.5; //default equal to the days x 1.5


		//we count teams
		for(int i = 0; i < getPlayersCount(); i++)
		{
			if(getPlayer(i).getTeamNum() == 0)
			{
				num_survivors_p++;
			}
			
			else if(getPlayer(i).getTeamNum() == 1)
			{
				num_undead++;
			}
		} 
		
		//get the maximum number of undeads per game, by default 1/4 rounded down
		int max_undead = (num_survivors_p/3);
		rules.set_s32("max_undead", max_undead);

		//we tweak difficulty after we reach the top of zombdiff
		if (zombdiff>100) //default zombdiff>50
		{ 
			zombdiff=100;
		} 
		

		//we cap the difficulty each day until a months up.
		if (difficulty>zombdiff && dayNumber<31) 
		{ 
			difficulty=zombdiff; 
		}
		
		if (rules.isWarmup() && timeElapsed>getTicksASecond()*30) 
		{ 
			rules.SetCurrentState(GAME); 
		}
		
		//the lower the spawnRate, the more zombies we get
		rules.set_f32("difficulty",difficulty); 
		int spawnRate = 200-(dayNumber*5); //default 200
		if (spawnRate<20) spawnRate=25;

		//Automatic undead switching and update active mobs count
		if (getGameTime() % 150 == 0) //5 secs
        {		
			// normal zombies
			CBlob@[] zombie_blobs;
			getBlobsByTag("zombie", @zombie_blobs );
			num_zombies = zombie_blobs.length;
			rules.set_s32("num_zombies",num_zombies);

			// zombies spawned from portals
			CBlob@[] pzombie_blobs;
			getBlobsByTag("pzombie", @pzombie_blobs );
			num_pzombies = pzombie_blobs.length;
			rules.set_s32("num_pzombies",num_pzombies);

			// migrant bots
			CBlob@[] migrantbot_blobs;
			getBlobsByTag("migrantbot", @migrantbot_blobs );
			num_migrantbots = migrantbot_blobs.length;
			rules.set_s32("num_migrantbots",num_migrantbots);

			printf("Day: " + dayNumber + ", Zombies: " + num_zombies + ", Portal Zombies: " + num_pzombies + ", Migrants: " + num_migrantbots + ", zombdiff: " + zombdiff + ", difficulty: " + difficulty + ", spawnRate: " + spawnRate + ", num_undead: " + num_undead + ", max_undead: " + max_undead);
		
			CMap@ map = getMap();
			if (map !is null)
			{
				if (!rules.hasTag("night") && (map.getDayTime() > 0.8 || map.getDayTime() < 0.2))
				{
					rules.Tag("night");
				} 
				else
				{
					rules.Untag("night");
				}

				//stuff to automatically zombify players past certain day
				
				//check the day at which we get cursed
				int curse_day = rules.get_s32("curse_day");

				//check the day at which the game ends
				int days_to_survive = rules.get_s32("days_to_survive");
			
				//check the day, that the number of undeads is lower than the maximum undeads allowed, and that it's night
				//could also use dayNumber>=Maths::Floor(days_to_survive * 0.7) if so desired
				if (dayNumber>=curse_day && num_undead<max_undead && rules.hasTag("night")) //we change at the end of the night
				{
					u8 pCount = getPlayersCount(); //we get the max number of players
							
					CPlayer@ player = getPlayer(XORRandom(pCount)); //pick a random one
					
					//only change them and send a message if the player is on the survivor's team
					if (player.getTeamNum() == 0)
					{
						Zombify(player); //switcheroo
						server_CreateBlob("cursemessage"); //TO DO: find a solution akin to this (that doesn't rely on creating a blob) //Sound::Play("/dontyoudare.ogg"); client_AddToChat("The curse is spreading, what a horrible night to go hollow...", SColor(255, 255, 0, 0));
					}
				}
			}
		}

	    //Spawning system
		if (getGameTime() % (spawnRate) == 0) //zombies spawn more often as days pass by, up to 1 sec
        {
			CMap@ map = getMap();
			if (map !is null)
			{
				Vec2f[] zombiePlaces;			
				
				getMap().getMarkers("zombie spawn", zombiePlaces );
				
				if (zombiePlaces.length<=0)
				{				
					for (int zp=8; zp<16; zp++)
					{
						Vec2f col;
						getMap().rayCastSolid( Vec2f(zp*8, 0.0f), Vec2f(zp*8, map.tilemapheight*8), col );
						col.y-=16.0;
						zombiePlaces.push_back(col);
						
						getMap().rayCastSolid( Vec2f((map.tilemapwidth-zp)*8, 0.0f), Vec2f((map.tilemapwidth-zp)*8, map.tilemapheight*8), col );
						col.y-=16.0;
						zombiePlaces.push_back(col);
					}
				}

				//zombies spawn point
				Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
				
				//check the horror blobs
				CBlob@[] horror_blobs;
				getBlobsByName("horror", @horror_blobs ); 
				u8 num_horror = horror_blobs.length;
				
				//check the abomination blobs
				CBlob@[] abomination_blobs;
				getBlobsByName("abomination", @abomination_blobs ); 
				u8 num_abom = abomination_blobs.length;
				
				//check the immolator blobs
				CBlob@[] immolator_blobs;
				getBlobsByName("immolator", @immolator_blobs ); 
				u8 num_immol = immolator_blobs.length;
				
				// wraiths
				CBlob@[] wraiths_blobs;
				getBlobsByTag("wraiths", @wraiths_blobs );
				num_wraiths = wraiths_blobs.length;
				rules.set_s32("num_wraiths",num_wraiths);
				
				// gregs
				CBlob@[] gregs_blobs;
				getBlobsByTag("gregs", @gregs_blobs );
				num_gregs = gregs_blobs.length;
				rules.set_s32("num_gregs",num_gregs);
				
				
				
				//Regular zombie spawns, we make sure to not spawn more zombies if we're past the limit. On later days it may still spawn some past the limit once due to spawn rate
				if ((dayNumber>=33 && num_zombies<max_zombies) || ((rules.hasTag("night")) && num_zombies<max_zombies))
                {
					
                    int r = XORRandom(zombdiff+5);

					if (r>=94 && num_gregs+num_wraiths<max_gregs+max_wraiths) //hardcap writhers 
                    server_CreateBlob( "writher", -1, sp);

                    else if (r>=90) 
                    server_CreateBlob( "horror", -1, sp);

                    else if (r>=82) 
                    server_CreateBlob( "pbanshee", -1, sp);

					else if (r>=75 && num_wraiths<max_wraiths) //hardcap for wraiths
                    server_CreateBlob( "wraith", -1, sp);
					
                    else if (r>=69 && num_gregs<max_gregs) //hardcap for gregs 
                    server_CreateBlob( "greg", -1, sp);
					
					else if (r>=53 && num_immol<8) //hardcap for immolators
                    server_CreateBlob( "immolator", -1, sp);
					
					else if (r>=45)
                    server_CreateBlob( "gasbag", -1, sp); 

					else if (r>=30)
                    server_CreateBlob( "zombieknight", -1, sp);
					
					else if (r>=26)
                    server_CreateBlob( "evilzombie", -1, sp);
					
					else if (r>=22)
                    server_CreateBlob( "bloodzombie", -1, sp);
					
					else if (r>=16)
                    server_CreateBlob( "plantzombie", -1, sp);
					
                    else if (r>=9)
                    server_CreateBlob( "zombie", -1, sp);
					
					else if (r<=9)
					server_CreateBlob( "skeleton", -1, sp);
					
					else if (r==3)
					server_CreateBlob( "zbison", -1, sp);
					
					else if (r==2)
					server_CreateBlob( "catto", -1, sp);
					
					else if (r==1)
					server_CreateBlob( "zchicken", -1, sp);
					
					

					// Boss spawn waves
					if (transition == 1 && (dayNumber % 10) == 0) //Every 10 days!
					{
						transition=0;
						rules.set_s32("transition",0);
						Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
						int boss = XORRandom(zombdiff);
						if (boss <= 30) 
						{
							server_CreateBlob( "abomination", -1, sp);
							
							getNet().server_SendMsg("1x Abominations\nAka the bringer of pain."); 
							server_CreateBlob("bossmessage");
						}
						else if (boss <= 50)
						{
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							getNet().server_SendMsg("8x Writher\nThe sound of explosions will be heard."); 
							server_CreateBlob("bossmessage");
						}
					}	
					
					else if (transition == 1 && (dayNumber % 5) == 0) //Every 5 days!
					{
						transition=0;
						rules.set_s32("transition",0);
						Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
						int boss = XORRandom(zombdiff);
						if (boss <= 20)
						{
							server_CreateBlob( "horror", -1, sp);
							server_CreateBlob( "horror", -1, sp);
							server_CreateBlob( "horror", -1, sp);

							getNet().server_SendMsg("3x Horrors\nDon't be scared."); 
							server_CreateBlob("minibossmessage");
						}
						else if (boss <= 50)
						{
							server_CreateBlob( "pbanshee", -1, sp);
							server_CreateBlob( "pbanshee", -1, sp);
							server_CreateBlob( "pbanshee", -1, sp);
							
							getNet().server_SendMsg("3x Banshee\nIt's almost not even fair."); 
							server_CreateBlob("minimessage");
						}
						else if (boss <= 100)
						{
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							server_CreateBlob( "writher", -1, sp);
							
							getNet().server_SendMsg("3x Writhers\n Kaboom."); 
							server_CreateBlob("minimessage");
						}
					}	


					
				}
				
				else
				{
					if (transition == 0)
					{	
						rules.set_s32("transition",1);
					}
				}
			}
		}
		
        RulesCore::Update(); //update respawns
        CheckTeamWon();

    }
	

	
    //team stuff

    void AddTeam(CTeam@ team)
    {
        CTFTeamInfo t(teams.length, team.getName());
        teams.push_back(t);
    }

    void AddPlayer(CPlayer@ player, u8 team, string default_config = "")
    {
        team = player.getTeamNum();
		CTFPlayerInfo p(player.getUsername(), team, "builder" ); 
        players.push_back(p);
        ChangeTeamPlayerCount(p.team, 1);
		warn("sync");
    }

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		if (!rules.isMatchRunning()) { return; }

		if (victim !is null )
		{
			if (killer !is null && killer.getTeamNum() != victim.getTeamNum())
			{
				addKill(killer.getTeamNum());
				Zombify( victim );
			}
		}
	}
	
	void Zombify( CPlayer@ player)
	{
		PlayerInfo@ pInfo = getInfoFromName( player.getUsername() );
		print( ":::ZOMBIFYING: " + pInfo.username );
		ChangePlayerTeam( player, 1 );
	}
	
	
    //checks
    void CheckTeamWon( )
    {
        if(!rules.isMatchRunning()) { return; }
        int gamestart = rules.get_s32("gamestart");	
		
        int num_zombiePortals = rules.get_s32("num_zombiePortals");
		int num_survivors = rules.get_s32("num_survivors");
		int days_to_survive = rules.get_s32("days_to_survive");
		
		int day_cycle = getRules().daycycle_speed*60;			
		int dayNumber = ((getGameTime()-gamestart)/getTicksASecond()/day_cycle)+1;
		
		/*if(getRules().get_bool("everyones_dead")) //Old win-lose condition check
		{
            rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
            rules.SetGlobalMessage( "You died on day "+ dayNumber+"." );		
			getRules().set_bool("everyones_dead",false); 
		}*/
		
		CBlob@[] bases;
		getBlobsByName(base_name(), @bases);

		if (bases.length == 0)
		{
			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
            rules.SetGlobalMessage( "Gameover!\nThe Pillars Have Been destroyed\nOn day "+ dayNumber +".");
		}
		
		else if((num_survivors-bases.length) <= 0) //Seems to be more eficient
		{
			rules.SetTeamWon(1);
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("All humans were dead on day "+ dayNumber+".");
		}
		
		/*else if(days_to_survive > 0 && dayNumber >= days_to_survive + 1)
		{
			rules.SetTeamWon(0);
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("The survivors have lasted 100 days! Fantastic Job!");
		}	
		
		else if(num_zombiePortals == 0) //check if you want to win by destroying all Zombie Portals
		{
			rules.SetTeamWon(0);
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("All Zombie Portals destroyed!");
		}*/
    }

    void addKill(int team)
    {
        if (team >= 0 && team < int(teams.length))
        {
            CTFTeamInfo@ team_info = cast<CTFTeamInfo@>( teams[team] );
        }
    }

};

//pass stuff to the core from each of the hooks

void spawnPortal(Vec2f pos)
{
	server_CreateBlob("zombieportal",-1,pos+Vec2f(0,-24.0));
}


void spawnGraves(Vec2f pos)
{
		int r = XORRandom(8);
		if (r == 0)
			server_CreateBlob("casket2",-1,pos+Vec2f(0,-16.0));
		else if (r == 1)
			server_CreateBlob("grave1",-1,pos+Vec2f(0,-16.0));
		else if (r == 2)
			server_CreateBlob("grave2",-1,pos+Vec2f(0,-16.0));
		else if (r == 3)
			server_CreateBlob("grave3",-1,pos+Vec2f(0,-16.0));
		else if (r == 4)
			server_CreateBlob("grave4",-1,pos+Vec2f(0,-16.0));
		else if (r == 5)
			server_CreateBlob("grave5",-1,pos+Vec2f(0,-16.0));
		else if (r == 6)
			server_CreateBlob("grave6",-1,pos+Vec2f(0,-16.0));
		else if (r == 7)
			server_CreateBlob("casket1",-1,pos+Vec2f(0,-16.0));		
}

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
    printf("Restarting rules script: " + getCurrentScriptName() );
    ZombiesSpawns spawns();
    ZombiesCore core(this, spawns);
    Config(core);
	Vec2f[] zombiePlaces;
	getMap().getMarkers("zombie portal", zombiePlaces );
	if (zombiePlaces.length>0)
	{
		for (int i=0; i<zombiePlaces.length; i++)
		{
			spawnPortal(zombiePlaces[i]);
		}
	}
	Vec2f[] gravePlaces;
	getMap().getMarkers("grave", gravePlaces );
	if (gravePlaces.length>0)
	{
		for (int i=0; i<gravePlaces.length; i++)
		{
			spawnGraves(gravePlaces[i]);
		}
	}
	
	//switching all players to survivors on game start
	for(u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if(p !is null)
		{
			p.server_setTeamNum(0);
		}
	}	

    //this.SetCurrentState(GAME);
    
    this.set("core", @core);
    this.set("start_gametime", getGameTime() + core.warmUpTime);
    this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as
}


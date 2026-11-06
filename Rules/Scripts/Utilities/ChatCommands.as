// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out

#include "MakeCrate.as";
#include "MakeScroll.as";
#include "MakeSeed.as";

// #include "RPC_War.as";
#include "Structs.as";
#include "RulesCore.as";
#include "WeatherSystem.as";

bool onServerProcessChat(CRules @ this, const string& in text_in, string& out text_out, CPlayer @player)
{
	if (player is null)
		return true;
	// Debug and admin commands require a live staff permission, never a username allowlist.
	const bool isStaff = player.isMod();
	const bool canSpawn = isStaff;

	if (text_in == "!bot" && isStaff)
	{
		AddBot("[Bot]");
		text_out = "";
		return false;
	}

	// spawning things
	CBlob @blob = player.getBlob();
	if (blob is null && isStaff && text_in == "!spawnme")
	{
		RulesCore @core;
		getRules().get("core", @core);
		if (core !is null)
		{
			CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(player));
			if (info !is null)
				info.can_spawn_time = 0;
		}
		text_out = "";
		return false;
	}

	if (text_in.substr(0, 1) == "!")
	{
		// check if we have tokens
		string[] @tokens = text_in.split(" ");

		if (tokens.length > 1)
		{
			if (tokens[0] == "!spawn" && isStaff)
			{
				string user = tokens[1];
				CPlayer @target_player = getPlayerByUsername(user);
				if (target_player !is null)
				{
					RulesCore @core;
					getRules().get("core", @core);
					if (core !is null)
					{
						CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(target_player));
						if (info !is null)
							info.can_spawn_time = 0;
					}
				}
				text_out = "";
				return false;
			}
			else if (tokens[0] == "!nospawn" && isStaff)
			{
				string user = tokens[1];
				CPlayer @target_player = getPlayerByUsername(user);
				if (target_player !is null)
				{
					RulesCore @core;
					getRules().get("core", @core);
					if (core !is null)
					{
						CTFPlayerInfo @info = cast<CTFPlayerInfo @>(core.getInfoFromPlayer(target_player));
						if (info !is null)
							info.can_spawn_time = getGameTime() + getTicksASecond() * 60 * 60;
					}
				}
				text_out = "";
				return false;
			}
			else if (tokens[0] == "!die" && isStaff)
			{
				string user = tokens[1];
				CPlayer @target_player = getPlayerByUsername(user);
				if (target_player !is null)
				{
					CBlob @target_blob = target_player.getBlob();
					if (target_blob !is null)
					{
						Vec2f vel(0, 0);
						target_blob.server_Hit(target_blob, target_blob.getPosition(), vel, 1000.0, 0);
					}
				}
				return false;
			}
			else if (tokens[0] == "!ban" && isStaff)
			{
				string user = tokens[1];
				CPlayer @target_player = getPlayerByUsername(user);
				if (target_player !is null)
				{
					BanPlayer(target_player, 60);
				}
				text_out = "";
				return false;
			}
			else if (tokens[0] == "!settime" && isStaff)
			{
				CMap @map = getMap();
				if (map !is null)
					map.SetDayTime(Maths::Clamp(parseFloat(tokens[1]), 0.0f, 1.0f));
				text_out = "";
				return false;
			}
			else if ((tokens[0] == "!day" || tokens[0] == "!days") && isStaff)
			{
				// Change the visible round day without rewriting the match start
				// timestamp or passing a day number to SetDayTime(0..1).
				const int targetDay = parseInt(tokens[1]);
				const int day_cycle = int(this.daycycle_speed * 60);
				if (targetDay >= 1 && targetDay <= 10000 && day_cycle > 0)
				{
					const int elapsed = (getGameTime() - this.get_s32("gamestart")) / getTicksASecond();
					const int naturalDay = elapsed / day_cycle + 1;
					this.set_s32("days_offset", targetDay - naturalDay);
					this.Sync("days_offset", true);
					this.set_bool("dayCheated", true);
					this.Sync("dayCheated", true);
				}
				text_out = "";
				return false;
			}
		}
	}

	if (blob is null)
	{
		return true;
	}
	if (text_in == "!targets" && canSpawn)
	{
		return true;
	}
	if (text_in == "!coins" && canSpawn)
	{
		server_DropCoins(blob.getPosition() + Vec2f(0, -16.0f), 500);
		return false;
	}
	else if (text_in == "!tree" && canSpawn)
	{
		server_MakeSeed(blob.getPosition(), "tree_pine", 600, 1, 16);
	}
	else if (text_in == "!btree" && canSpawn)
	{
		server_MakeSeed(blob.getPosition(), "tree_bushy", 400, 2, 16);
	}
	else if (text_in == "!flowers" && canSpawn)
	{
		server_CreateBlob("Entities/Environment/Flowers/Flowers.cfg", blob.getTeamNum(), blob.getPosition());
	}
	else if (text_in == "!catapult" && canSpawn)
	{
		server_CreateBlob("Entities/Vehicles/Catapult/Catapult.cfg", blob.getTeamNum(), blob.getPosition());
	}
	else if (text_in == "!zombie" && canSpawn)
	{
		server_CreateBlob("zombie", -1, blob.getPosition());
	}
	else if (text_in == "!skeleton" && canSpawn)
	{
		server_CreateBlob("skeleton", -1, blob.getPosition());
	}
	else if (text_in == "!bison" && canSpawn)
	{
		server_CreateBlob("Entities/Environment/Animals/Bison/Bison.cfg", blob.getTeamNum(), blob.getPosition());
	}
	else if (text_in == "!piranha" && canSpawn)
	{
		server_CreateBlob("piranha", blob.getTeamNum(), blob.getPosition());
	}
	else if (text_in == "!stones" && canSpawn)
	{
		CBlob @b = server_CreateBlob("Entities/Resources/MaterialStone.cfg", blob.getTeamNum(), blob.getPosition());

		if (b !is null)
		{
			b.server_SetQuantity(320);
		}
	}
	else if (text_in == "!arrows" && canSpawn)
	{
		for (int i = 0; i < 3; i++)
		{
			CBlob @b = server_CreateBlob("Entities/Resources/MaterialArrows.cfg", blob.getTeamNum(), blob.getPosition());

			if (b !is null)
			{
				b.server_SetQuantity(30);
			}
		}
	}
	else if (text_in == "!bombs" && canSpawn)
	{
		//  for (int i = 0; i < 3; i++)
		CBlob @b = server_CreateBlob("Entities/Resources/MaterialBombs.cfg", blob.getTeamNum(), blob.getPosition());

		if (b !is null)
		{
			b.server_SetQuantity(30);
		}
	}
	else if (text_in == "!spawnwater" && canSpawn)
	{
		getMap().server_setFloodWaterWorldspace(blob.getPosition(), true);
	}
	else if (text_in == "!seed")
	{
		// crash prevention
	}
	else if (text_in == "!killme")
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 4.0f, 0);
	}
	else if (text_in == "!crate" && canSpawn)
	{
		client_AddToChat("usage: !crate BLOBNAME [DESCRIPTION]", SColor(255, 255, 0, 0));
		server_MakeCrate("", "", 0, blob.getTeamNum(), Vec2f(blob.getPosition().x, blob.getPosition().y - 30.0f));
	}
	else if (text_in == "!debug" && player.isMod())
	{
		// print all blobs
		CBlob @[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob @blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
		}
	}
	else if (text_in == "!nokeg" && isStaff)
	{
		CBlob @[] blobs;
		getBlobsByName("keg", @blobs);

		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob @hit_blob = blobs[i];
			printf("Name:" + hit_blob.getName());
			if (hit_blob.getName() == "keg")
			{
				hit_blob.server_Die();
			}
		}
		return false;
	}
	else if (text_in == "!killruins" && isStaff)
	{
		// Destroy all ruinstorch blobs to force the round to end
		CBlob @[] torches;
		getBlobsByName("ruinstorch", @torches);

		for (uint i = 0; i < torches.length; i++)
		{
			CBlob @torch = torches[i];
			if (torch !is null)
			{
				torch.server_Die();
			}
		}
		return false;
	}
	else if (text_in.substr(0, 1) == "!")
	{
		// check if we have tokens
		string[] @tokens = text_in.split(" ");

		if (tokens.length > 1)
		{
			if (tokens[0] == "!crate" && canSpawn)
			{
				int frame = tokens[1] == "catapult" ? 1 : 0;
				string description = tokens.length > 2 ? tokens[2] : tokens[1];
				server_MakeCrate(tokens[1], description, frame, -1, Vec2f(blob.getPosition().x, blob.getPosition().y));
			}
			else if (tokens[0] == "!team" && canSpawn)
			{
				int team = parseInt(tokens[1]);
				blob.server_setTeamNum(team);
			}
			else if (tokens[0] == "!scroll" && canSpawn)
			{
				string s = tokens[1];
				for (uint i = 2; i < tokens.length; i++)
					s += " " + tokens[i];
				server_MakePredefinedScroll(blob.getPosition(), s);
				return false;
			}

			return true;
		}

		// try to spawn an actor with this name !actor
		string name = text_in.substr(1, text_in.size());

		if (canSpawn)
		{
			if (server_CreateBlob(name, -1, blob.getPosition()) is null)
				client_AddToChat("blob " + text_in + " not found", SColor(255, 255, 0, 0));
			text_out = "";
			return false;
		}
	}

	return true;
}

bool onClientProcessChat(CRules @ this, const string& in text_in, string& out text_out, CPlayer @player)
{

	if (text_in == "!targets" && !getNet().isServer())
	{
		getRules().set_bool("target lines", !getRules().get_bool("target lines"));
		print("target lines: " + getRules().get_bool("target lines"));
	}
	if (text_in == "!debug" && !getNet().isServer())
	{
		// print all blobs
		CBlob @[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob @blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob @[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob @overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}

// Zombies_Boss.as
#include "GlobalPopup.as"
int RunBossWave(const int dayNumber,
                const float zombdiff,
                Vec2f[]@ zombiePlaces,
                const int transition_in)
{
	int transition = transition_in;

	if (transition == 1 && (dayNumber % 5) == 0 && zombiePlaces.length > 0)
	{
		transition = 0;
		Vec2f sp = zombiePlaces[XORRandom(zombiePlaces.length)];
		int boss = XORRandom(90+zombdiff);

		if (boss <= 10)
		{
			server_CreateBlob("horror", -1, sp);
			server_CreateBlob("horror", -1, sp);
			server_CreateBlob("horror", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A mini boss has spawned!\n3x Horrors\n16 Hearts, Spawns 3 Special Zombies.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 20)
		{
			server_CreateBlob("pbanshee", -1, sp);
			server_CreateBlob("pbanshee", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A mini boss has spawned!\n2x Banshee\n10 Explosion Blast\n30 Block Stunning scream.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 30)
		{
			server_CreateBlob("writher", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A mini boss has spawned!\n1x Writhers\n20 Explosion Blast\nSpawns 2 Wraiths on death.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 40)
		{
			server_CreateBlob("zbison", -1, sp);
			server_CreateBlob("zbison2", -1, sp);
			server_CreateBlob("zbison", -1, sp);
			server_CreateBlob("zbison2", -1, sp);
			server_CreateBlob("zbison", -1, sp);
			server_CreateBlob("zbison2", -1, sp);
			server_CreateBlob("zbison", -1, sp);
			server_CreateBlob("zbison2", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A mini boss has spawned!\nA Horde of Bison\n10 Hearts, 1 Dmg.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 50)
		{
			for (int i = 0; i < 16; i++) server_CreateBlob("immolator", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A mini boss has spawned!\n16x immolator\n7 Explosion Blast.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 60)
		{
			server_CreateBlob("abomination", -1, sp);
			server_CreateBlob("abomination", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A Boss has spawned!\n2x Abominations\n60 Hearts, 4 Dmg.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
		else if (boss <= 120)
		{
			server_CreateBlob("writher", -1, sp);
			server_CreateBlob("writher", -1, sp);
			server_CreateBlob("writher", -1, sp);
			Sound::Play("/dontyoudare.ogg");
                        Server_GlobalPopup(getRules(),
                                           "A Boss has spawned!\n3x Writhers\n20 Explosion Blast\nSpawns 2 Wraiths on death.",
                                           SColor(255, 255, 0, 0), 10 * getTicksASecond());
		}
	}

	return transition;
}

// Game Music

#define CLIENT_ONLY

enum GameMusicTags
{
	background_jam,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}
		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/darkworld.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/caenua.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/balladofgoddess.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/songofstorms.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/ocarinaoftime.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/fairyfountain.ogg", background_jam);
	mixer.AddTrack("../Mods/RaziZombies/Sounds/Music/peacefulwaters.ogg", background_jam);
}

uint timer = 0;

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if(mixer.getPlayingCount()==0) {
		mixer.FadeInRandom(background_jam , 0.0f);
	}
}

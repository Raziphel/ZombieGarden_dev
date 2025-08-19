#define SERVER_ONLY

// WeatherSystem.as
// Randomly triggers either rain or blizzard with a cooldown.
// No map-type checks. Keeps a simple "raining" flag while active.

u32 g_next_weather = 1000;
const u8 BLIZZARD_PERCENT = 50; // 0–100 chance; set lower if you want blizzards to be rarer

void onInit(CRules@ this)
{
	this.set_bool("raining", false);
	this.set_u32("rain_end_at", 0);

	const u32 time = getGameTime();
	g_next_weather = time + 2500 + XORRandom(40000);
}

void onRestart(CRules@ this)
{
	this.set_bool("raining", false);
	this.set_u32("rain_end_at", 0);

	const u32 time = getGameTime();
	g_next_weather = time + 2500 + XORRandom(40000);
}

void onTick(CRules@ this)
{
	if (!isServer()) return;

	const u32 time = getGameTime();

	// Auto-clear the raining flag when the effect should be over
	if (this.get_bool("raining"))
	{
		const u32 rain_end_at = this.get_u32("rain_end_at");
		if (time >= rain_end_at)
		{
			this.set_bool("raining", false);
			this.set_u32("rain_end_at", 0);
		}
	}

	// Not time yet for the next roll
	if (time < g_next_weather) return;

	// Duration: 1–6 minutes (at 30 ticks/sec)
	const u32 length_ticks = (30 * 60 * 1) + XORRandom(30 * 60 * 5);

	// Only start new weather if nothing is active
	if (!this.get_bool("raining"))
	{
		const bool do_blizzard = (XORRandom(100) < BLIZZARD_PERCENT);
		const string blobname = do_blizzard ? "blizzard" : "rain";

		CBlob@ weather = server_CreateBlob(blobname, 255, Vec2f(0, 0));
		if (weather !is null)
		{
			weather.server_SetTimeToDie(length_ticks / 30.0f); // convert ticks to seconds
			this.set_bool("raining", true);
			this.set_u32("rain_end_at", time + length_ticks);
		}
	}

	// Schedule the next chance window after this weather plus a cooldown
	g_next_weather = time + length_ticks + 10000 + XORRandom(75000);
}

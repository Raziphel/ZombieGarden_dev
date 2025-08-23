#define SERVER_ONLY

// Store records in the game's Cache folder.  Writing directly to the mod
// directory is disallowed by the engine's security checks and results in
// "Cannot save files in a different directory than Cache" errors.  Using an
// explicit path inside Cache ensures the records persist between runs
// without triggering those errors.
const string records_file_name = "ZombieRecords.cfg";
const string records_file_path = "../Cache/" + records_file_name;

u16 getDaysSurvived(CRules @rules)
{
	const int gamestart = rules.get_s32("gamestart");
	const int day_cycle = rules.daycycle_speed * 60;
	const int days_offset = rules.get_s32("days_offset");
	return days_offset +
		   ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
}

void onInit(CRules @ this)
{
	this.set_bool("dayCheated", false);
	this.set_bool("records_saved", false);
	this.set_bool("records_loaded", false);
	this.Sync("dayCheated", true);
}

void onRestart(CRules @ this)
{
	this.set_bool("dayCheated", false);
	this.set_bool("records_saved", false);
	this.set_bool("records_loaded", false);
	this.Sync("dayCheated", true);
}

void LoadRecords(CRules @ this)
{
	ConfigFile cfg;
	if (!cfg.loadFile(records_file_path))
	{
		cfg.saveFile(records_file_name);
	}
	string map = this.get_string("map_name");
	if (map == "" && getMap() !is null)
	{
		map = getMap().getMapName();
		this.set_string("map_name", map);
	}
	this.set_u16("map_record",
				 cfg.exists("map_" + map) ? cfg.read_u16("map_" + map) : 0);
	this.set_u16("global_record",
				 cfg.exists("global") ? cfg.read_u16("global") : 0);
	this.set_u32("map_kill_record", cfg.exists("map_kills_" + map) ? cfg.read_u32("map_kills_" + map) : 0);
	this.set_u32("global_kill_record",
				 cfg.exists("global_kills") ? cfg.read_u32("global_kills") : 0);
	this.Sync("map_record", true);
	this.Sync("global_record", true);
	this.Sync("map_kill_record", true);
	this.Sync("global_kill_record", true);
}

void SaveRecords(CRules @ this)
{
	ConfigFile cfg;
	if (!cfg.loadFile(records_file_path))
	{
		cfg.saveFile(records_file_name);
	}
	string map = this.get_string("map_name");
	if (map == "" && getMap() !is null)
	{
		map = getMap().getMapName();
		this.set_string("map_name", map);
	}
	cfg.add_u16("map_" + map, this.get_u16("map_record"));
	cfg.add_u16("global", this.get_u16("global_record"));
	cfg.add_u32("map_kills_" + map, this.get_u32("map_kill_record"));
	cfg.add_u32("global_kills", this.get_u32("global_kill_record"));
	cfg.saveFile(records_file_name);
}

void onTick(CRules @ this)
{
	if (!this.get_bool("records_loaded"))
	{
		string map = this.get_string("map_name");
		if (map != "")
		{
			LoadRecords(this);
			this.set_bool("records_loaded", true);
		}
	}

	const u16 days = getDaysSurvived(this);
	this.set_u16("day_number", days);

	// update the stored record as soon as a new day is survived
	if (!this.get_bool("dayCheated"))
	{
		bool newRecord = false;
		if (days > this.get_u16("map_record"))
		{
			this.set_u16("map_record", days);
			newRecord = true;
		}
		if (days > this.get_u16("global_record"))
		{
			this.set_u16("global_record", days);
			newRecord = true;
		}
		if (newRecord)
		{
			SaveRecords(this);
			this.Sync("map_record", true);
			this.Sync("global_record", true);
			if (days > 1)
				getNet().server_SendMsg("New survival record: " + days + " day(s)");
		}
	}
}

void onStateChange(CRules @ this, const u8 oldState)
{
	if (this.isGameOver())
	{
		if (!this.get_bool("records_saved"))
		{
			this.set_bool("records_saved", true);
			const u32 kills = this.get_u32("undead_kills");
			if (!this.get_bool("dayCheated"))
			{
				u32 mapKillRec = this.get_u32("map_kill_record");
				u32 globKillRec = this.get_u32("global_kill_record");
				bool newKillRecord = false;

				if (kills > mapKillRec)
				{
					this.set_u32("map_kill_record", kills);
					newKillRecord = true;
				}
				if (kills > globKillRec)
				{
					this.set_u32("global_kill_record", kills);
					newKillRecord = true;
				}

				SaveRecords(this);
				this.Sync("map_record", true);
				this.Sync("global_record", true);
				this.Sync("map_kill_record", true);
				this.Sync("global_kill_record", true);

				if (newKillRecord)
					getNet().server_SendMsg("New kill record: " + kills);
			}
		}
	}
	else
	{
		this.set_bool("records_saved", false);
	}
}

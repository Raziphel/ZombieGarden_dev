#define SERVER_ONLY

const string records_file = "../Cache/ZombieRecords.cfg";

u16 getDaysSurvived(CRules@ rules)
{
    const int gamestart = rules.get_s32("gamestart");
    const int day_cycle = rules.daycycle_speed * 60;
    const int days_offset = rules.get_s32("days_offset");
    return days_offset + ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
}

void onInit(CRules@ this)
{
    this.set_bool("dayCheated", false);
    LoadRecords(this);
}

void onRestart(CRules@ this)
{
    onInit(this);
}

void LoadRecords(CRules@ this)
{
    ConfigFile cfg;
    if (!cfg.loadFile(records_file))
    {
        // no file yet, defaults remain
    }
    string map = this.get_string("map_name");
    this.set_u16("map_record", cfg.exists("map_" + map) ? cfg.read_u16("map_" + map) : 0);
    this.set_u16("global_record", cfg.exists("global") ? cfg.read_u16("global") : 0);
}

void SaveRecords(CRules@ this)
{
    ConfigFile cfg;
    cfg.loadFile(records_file);
    string map = this.get_string("map_name");
    cfg.add_u16("map_" + map, this.get_u16("map_record"));
    cfg.add_u16("global", this.get_u16("global_record"));
    cfg.saveFile(records_file);
}

void onTick(CRules@ this)
{
    this.set_u16("day_number", getDaysSurvived(this));

    if (this.isGameOver() && !this.get_bool("records_saved"))
    {
        this.set_bool("records_saved", true);
        const u16 days = getDaysSurvived(this);
        if (!this.get_bool("dayCheated"))
        {
            u16 mapRec = this.get_u16("map_record");
            u16 globRec = this.get_u16("global_record");
            if (days > mapRec)
                this.set_u16("map_record", days);
            if (days > globRec)
                this.set_u16("global_record", days);
            SaveRecords(this);
        }
    }
}

void onStateChange(CRules@ this, const u8 oldState)
{
    if (!this.isGameOver())
    {
        this.set_bool("records_saved", false);
    }
}

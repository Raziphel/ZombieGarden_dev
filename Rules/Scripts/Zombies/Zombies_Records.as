#define SERVER_ONLY

const string records_file = "Cache/ZombieRecords.cfg";

u16 getDaysSurvived(CRules @rules) {
  const int gamestart = rules.get_s32("gamestart");
  const int day_cycle = rules.daycycle_speed * 60;
  const int days_offset = rules.get_s32("days_offset");
  return days_offset +
         ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
}

void onInit(CRules @ this) {
  this.set_bool("dayCheated", false);
  this.set_bool("records_saved", false);
  this.set_bool("records_loaded", false);
}

void onRestart(CRules @ this) {
  this.set_bool("dayCheated", false);
  this.set_bool("records_saved", false);
  this.set_bool("records_loaded", false);
}

void LoadRecords(CRules @ this) {
  ConfigFile cfg;
  if (!cfg.loadFile(records_file)) {
    cfg.saveFile(records_file);
  }
  string map = this.get_string("map_name");
  if (map == "" && getMap() !is null) {
    map = getMap().getMapName();
    this.set_string("map_name", map);
  }
  this.set_u16("map_record",
               cfg.exists("map_" + map) ? cfg.read_u16("map_" + map) : 0);
  this.set_u16("global_record",
               cfg.exists("global") ? cfg.read_u16("global") : 0);
  this.set_u32("map_kill_record", cfg.exists("map_kills_" + map)
                                      ? cfg.read_u32("map_kills_" + map)
                                      : 0);
  this.set_u32("global_kill_record",
               cfg.exists("global_kills") ? cfg.read_u32("global_kills") : 0);
  this.Sync("map_record", true);
  this.Sync("global_record", true);
  this.Sync("map_kill_record", true);
  this.Sync("global_kill_record", true);
}

void SaveRecords(CRules @ this) {
  ConfigFile cfg;
  if (!cfg.loadFile(records_file)) {
    cfg.saveFile(records_file);
  }
  string map = this.get_string("map_name");
  if (map == "" && getMap() !is null) {
    map = getMap().getMapName();
    this.set_string("map_name", map);
  }
  cfg.add_u16("map_" + map, this.get_u16("map_record"));
  cfg.add_u16("global", this.get_u16("global_record"));
  cfg.add_u32("map_kills_" + map, this.get_u32("map_kill_record"));
  cfg.add_u32("global_kills", this.get_u32("global_kill_record"));
  cfg.saveFile(records_file);
}

void onTick(CRules @ this) {
  if (!this.get_bool("records_loaded")) {
    string map = this.get_string("map_name");
    if (map != "") {
      LoadRecords(this);
      this.set_bool("records_loaded", true);
    }
  }

  this.set_u16("day_number", getDaysSurvived(this));
}

void onStateChange(CRules @ this, const u8 oldState) {
  if (this.isGameOver()) {
    if (!this.get_bool("records_saved")) {
      this.set_bool("records_saved", true);
      const u16 days = getDaysSurvived(this);
      const u32 kills = this.get_u32("undead_kills");
      if (!this.get_bool("dayCheated")) {
        u16 mapRec = this.get_u16("map_record");
        u16 globRec = this.get_u16("global_record");
        u32 mapKillRec = this.get_u32("map_kill_record");
        u32 globKillRec = this.get_u32("global_kill_record");

        if (days > mapRec)
          this.set_u16("map_record", days);
        if (days > globRec)
          this.set_u16("global_record", days);
        if (kills > mapKillRec)
          this.set_u32("map_kill_record", kills);
        if (kills > globKillRec)
          this.set_u32("global_kill_record", kills);

        SaveRecords(this);
        this.Sync("map_record", true);
        this.Sync("global_record", true);
        this.Sync("map_kill_record", true);
        this.Sync("global_kill_record", true);
      }
    }
  } else {
    this.set_bool("records_saved", false);
  }
}

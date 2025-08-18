#define CLIENT_ONLY

bool mousePress = false;

int getDaysSurvived()
{
    CRules@ rules = getRules();
    const int gamestart = rules.get_s32("gamestart");
    const int day_cycle = rules.daycycle_speed * 60;
    const int days_offset = rules.get_s32("days_offset");
    return days_offset + ((getGameTime() - gamestart) / getTicksASecond() / day_cycle) + 1;
}

void onRenderScoreboard(CRules@ this)
{
    GUI::SetFont("menu");

    const int days = getDaysSurvived();
    const u16 mapRecord = this.get_u16("map_record");
    const bool beatMapRecord = days > mapRecord;
    const u16 globalRecord = this.get_u16("global_record");
    const bool beatGlobalRecord = days > globalRecord;
    const bool cheated = this.get_bool("dayCheated");

    SColor goodColor = SColor(255, 0, 255, 0);
    SColor normalColor = SColor(255, 255, 255, 255);

    int x = getDriver().getScreenWidth() - 450;
    int y = -3;
    GUI::DrawText("Days Survived: " + days, Vec2f(x, y += 15), normalColor);
    if(beatMapRecord)
        GUI::DrawText("Map Record Beat!", Vec2f(x, y += 15), goodColor);
    else
        GUI::DrawText("Map Record: " + mapRecord, Vec2f(x, y += 15), normalColor);
    if(beatGlobalRecord)
        GUI::DrawText("Global Record Beat!", Vec2f(x, y += 15), goodColor);
    else
        GUI::DrawText("Global Record: " + globalRecord, Vec2f(x, y += 15), normalColor);
    if(cheated)
        GUI::DrawText("Record Disqualified (!day)", Vec2f(x, y += 15), SColor(255,255,0,0));

    CControls@ controls = getControls();
    Vec2f mousePos = controls.getMouseScreenPos();
    makeWebsiteLink(Vec2f(getDriver().getScreenWidth() - 150, 60), "Discord", "https://discord.gg/razi", controls, mousePos);
    mousePress = controls.mousePressed1;
}

void makeWebsiteLink(Vec2f pos, const string &in text, const string &in website, CControls@ controls, Vec2f &in mousePos)
{
    GUI::SetFont("menu");
    Vec2f dim;
    GUI::GetTextDimensions(text, dim);

    const float width = dim.x + 20;
    const float height = 40;
    Vec2f tl = pos;
    Vec2f br = Vec2f(width + pos.x, pos.y + height);

    const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
    if (hover)
    {
        GUI::DrawButton(tl, br);
        if (controls.mousePressed1 && !mousePress)
        {
            Sound::Play("option");
            OpenWebsite(website);
        }
    }
    else
    {
        GUI::DrawPane(tl, br, 0xffcfcfcf);
    }

    GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
}

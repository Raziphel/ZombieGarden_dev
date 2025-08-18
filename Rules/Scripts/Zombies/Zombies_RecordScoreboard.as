#define CLIENT_ONLY

bool mousePress = false;

void onRenderScoreboard(CRules@ this)
{
    GUI::SetFont("menu");

    // keep external link but move record details to the HUD
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

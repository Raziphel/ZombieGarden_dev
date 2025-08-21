// TDM Ruins logic

#include "ClassSelectMenu.as"
#include "StandardRespawnCommand.as"

void onInit(CBlob @ this)
{
	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(16, 18));
	this.Tag("invincible");

	this.Tag("change class drop inventory");

	this.getSprite().SetZ(-50.0f); // push to background
}

void onCommand(CBlob @ this, u8 cmd, CBitStream @params)
{
	{
		onRespawnCommand(this, cmd, params);
	}
}

void GetButtonsFor(CBlob @ this, CBlob @caller)
{
	// warning: if we don't have this button just spawn menu here we run into that infinite menus game freeze bug
}

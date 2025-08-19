#include "CreatureCommon.as";

void onInit( CBlob@ this )
{
        this.Tag("zombie");
        this.Tag("enemy");
        this.Tag("medium_zombie");
        SetupTargets(this);
        if (!this.hasScript("ZombieDigCont.as"))
        {
                this.AddScript("ZombieDigCont.as");
        }
}

void SetupTargets( CBlob@ this )
{
        TargetInfo[] infos;
        addTargetInfo(infos, "survivorplayer", 1.0f, true, true);
        addTargetInfo(infos, "ruinstorch", 1.0f, true, true);
        addTargetInfo(infos, "stone_door", 0.9f);
        addTargetInfo(infos, "wooden_door", 0.9f);
        addTargetInfo(infos, "survivorbuilding", 0.6f, true);
        addTargetInfo(infos, "migrantbot", 1.0f, true);
        addTargetInfo(infos, "ally", 0.9f, true);
        addTargetInfo(infos, "mounted_bow", 0.4f);
        addTargetInfo(infos, "mounted_bazooka", 0.4f);
        addTargetInfo(infos, "wooden_platform", 0.4f);
        addTargetInfo(infos, "pet", 0.2f, true);
        addTargetInfo(infos, "lantern", 0.2f);
        addTargetInfo(infos, "lesser_zombie", 0.2f);

	this.set("target infos", infos);

	//for EatOthers
	string[] tags = {"dead"};
	this.set("tags to eat", tags);
}
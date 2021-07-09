#include "CreatureCommon.as";

void onInit( CBlob@ this )
{
	this.Tag("zombie");
	this.Tag("enemy");
	this.Tag("lesser_zombie");
	SetupTargets(this);
}

void SetupTargets( CBlob@ this )
{
	TargetInfo[] infos;

	{
		TargetInfo i("survivorplayer", 1.0f, true, true);
		infos.push_back(i);
	}
	{
		TargetInfo i("migrantbot", 1.0f, true);
		infos.push_back(i);
	}	
	{
		TargetInfo i("ally", 0.9f, true);
		infos.push_back(i);
	}	
	{
		TargetInfo i("survivorbuilding", 0.8f, true);
		infos.push_back(i);
	}
	{
		TargetInfo i("mounted_bow", 0.4f);
		infos.push_back(i);
	}
	{
		TargetInfo i("mounted_bazooka", 0.4f);
		infos.push_back(i);
	}
	{
		TargetInfo i("wooden_door", 0.4f);
		infos.push_back(i);
	}
	{
		TargetInfo i("wooden_platform", 0.4f);
		infos.push_back(i);
	}
	{
		TargetInfo i("pet", 0.2f, true);
		infos.push_back(i);
	}
	{
		TargetInfo i("lantern", 0.2f);
		infos.push_back(i);
	}

	this.set("target infos", infos);
	
	//for EatOthers
	string[] tags = {"dead"};
	this.set("tags to eat", tags);
}
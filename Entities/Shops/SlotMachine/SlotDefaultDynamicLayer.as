
void setupReel(CSprite@ this, s8 num)
{
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ reel = this.addSpriteLayer("reel"+num, "reelsymbols.png" , 16, 16, blob.getTeamNum(), blob.getSkinNum());
	reel.TranslateBy(Vec2f(-21+(num-1)*21,-11));
	reel.SetRelativeZ(1);
	
	CSpriteLayer@ reeln = this.addSpriteLayer("reeln"+num, "reelsymbols.png" , 16, 16, blob.getTeamNum(), blob.getSkinNum());
	reeln.TranslateBy(Vec2f(-21+(num-1)*21,-11 - 16));
	reeln.SetRelativeZ(1);
	blob.set_u8("csymbol", 0);
	blob.set_u8("nsymbol", 0);
}

void onInit(CSprite@ this)
{
	this.SetZ(-50); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename() , 72, 48, blob.getTeamNum(), blob.getSkinNum());
	//front.SetOffset(Vec2f(72,0));
	front.TranslateBy(Vec2f(0,-12));
	front.SetRelativeZ(2);
	blob.set_u8("dist", 0);
	
	setupReel(this,1);
	setupReel(this,2);
	setupReel(this,3);

	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		anim.AddFrame(0);
		anim.AddFrame(1);
		anim.AddFrame(2);		
		anim.AddFrame(3);
	}
	
}

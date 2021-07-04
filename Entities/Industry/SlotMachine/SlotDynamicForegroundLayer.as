void onInit(CSprite@ this)
{
	this.getCurrentScript().tickFrequency = 1;
}

u32 NextUInt(u32 x)
{
	return u32((x*16807+13) & 2147483647);
}
  
void translateReel(CSprite@ this, s8 reelNum)
{
	CSpriteLayer@ reel = this.getSpriteLayer("reel"+reelNum);
	CSpriteLayer@ reeln = this.getSpriteLayer("reeln"+reelNum);
	if (reel !is null) {
		CBlob@ blob = this.getBlob();
		s8 dist = blob.get_s8("dist"+reelNum);
		reel.TranslateBy(Vec2f(0,2));
		reeln.TranslateBy(Vec2f(0,2));
		dist++;
		if (dist > 7) {
			dist = 0;
			reeln.TranslateBy(Vec2f(0,-16));
			reel.TranslateBy(Vec2f(0,-16));

			u8 next = blob.get_u8("nsymbol"+reelNum);
			reel.SetFrameIndex(next);
			blob.set_u8("csymbol"+reelNum, next);
			u32 spinRand = blob.get_u32("spinRand");
			u32 symbol = NextUInt(spinRand);
			printf("rand:"+symbol);
			blob.set_u32("spinRand",symbol);
			symbol = symbol & 65535;
			symbol = (symbol * 8) / 65535;
			if (symbol == 8) symbol = 7;
			reeln.SetFrameIndex(symbol);
			blob.set_u8("nsymbol"+reelNum, symbol);
		}
		blob.set_s8("dist"+reelNum,dist);
	}
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ front = this.getSpriteLayer("front layer");
	CBlob@ blob = this.getBlob();
	s8 frame = blob.get_s8("frame");
	front.SetFrameIndex(1);	
	frame++;
	if (frame > 3) {
	frame = 0;
	}
	blob.set_s8("frame",frame);
	bool spinning = blob.get_bool("spinning");
	bool spin = blob.get_bool("spin");
	if (spin) {
		blob.set_bool("spin", false);
		blob.set_bool("spinning", true);
		blob.set_s8("spinCount", 64);
		spinning = true;
	}
	if (spinning) { 
		s8 spinCount = blob.get_s8("spinCount");
		if (spinCount > 16)	translateReel(this, 1);
		if (spinCount > 8) translateReel(this, 2);
		translateReel(this, 3);
		spinCount--;
		blob.set_s8("spinCount", spinCount);
		u8 r1 = blob.get_u8("csymbol"+1);
		u8 r2 = blob.get_u8("csymbol"+2);
		u8 r3 = blob.get_u8("csymbol"+3);
		
		if (spinCount == 0) {
			blob.set_bool("spinning", false);
			if ((r1 == r2 && r2 == r3) || (r1 == 0) ||
				(r1 == 6 && r2 == r3) || 
				(r2 == 6 && r1 == r3) ||
				(r3 == 6 && r1 == r2) ||
				(r2 == 6 && r3 == 6) ||
				(r1 == 6 && r2 == 6) ||
				(r1 == 6 && r3 == 6)
				)
				{
				CPlayer@ p = getLocalPlayer();
				CBlob@ local = p.getBlob();
				if (local !is null) {
					u16 callid = blob.get_u16("callid");
					if (local.getNetworkID() == callid) {
						CBitStream params;
						
						CBlob@ caller = getBlobByNetworkID(callid);
						params.write_netid(caller.getNetworkID());
						params.write_u8(r1);
						params.write_u8(r2);
						params.write_u8(r3);
						blob.SendCommand(blob.getCommandID("win"), params);
					}
				}
			}
		}
	}
//	translateReel(this, 3);
/*	if (front !is null)
	{
		front.SetVisible(false);

		bool visible = front.isVisible();
		int frame = front.getFrameIndex();

		CBlob@ blob = this.getBlob();

		bool anim = blob.hasTag("animated front");

		CPlayer@ p = getLocalPlayer();
		if (p !is null)
		{
			CBlob@ local = p.getBlob();
			if (local !is null)
			{
				f32 length = (local.getPosition() - blob.getPosition()).Length();
				f32 popdistance = visible ? 24 : 32;
				if (visible)
				{
					if (length < popdistance)
					{
						if (anim)
							frame = 1;
						else
							visible = false;
					}
				}
				else
				{
					if (length > popdistance)
					{
						if (anim)
							frame = 0;
						else
							visible = true;
					}
				}
			}
			else
			{
				visible	= true;
			}
		}
		else
		{
			visible	= true;
		}

		front.SetVisible(visible);

		if (anim)
			front.SetFrameIndex(frame);
		else
			front.animation.setFrameFromRatio(1.0f - (blob.getHealth() / blob.getInitialHealth()));
	}*/
}

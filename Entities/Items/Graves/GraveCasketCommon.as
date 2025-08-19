shared class Loot
{
	string name;
	int rarity;
	int quantity;
};

f32  openHealth   = 0.0f;   // health of wooden chest threshold (0.5f = 1 heart)
int  itemVelocity = 1;      // how far items fly from chest on open
bool button       = false;  // open via button (hold E) or by hit

// -------------------------------------
// Helper: push a loot entry onto the chest
// -------------------------------------
void addLoot(CBlob@ this, string NAME, int RARITY, int QUANTITY)
{
	if (!this.exists("loot"))
	{
		Loot[] loot;
		this.set("loot", loot);
	}

	Loot l;
	l.name     = NAME;
	l.rarity   = RARITY;
	l.quantity = QUANTITY;

	this.push("loot", l);
}

// -------------------------------------
// Helper: pick 1 random item from a pool (names + rarities aligned)
// - Softly buffs drop chance by reducing rarity by 1 (min 0)
// - Optional chance to add an extra item from the same pool
// -------------------------------------
void addRandomFromPool(CBlob@ this, const string[] &in names, const u8[] &in rarities, u8 extraChancePct, int qty = 1)
{
	if (names.length == 0 || names.length != rarities.length) return;

	const u32 pick = XORRandom(names.length);
	const int softenedRarity = Maths::Max(0, int(rarities[pick]) - 1); // slight buff

	addLoot(this, names[pick], softenedRarity, qty);

	// small chance for a bonus item from the same tier
	if (XORRandom(100) < extraChancePct)
	{
		const u32 bonus = XORRandom(names.length);
		const int softenedRarity2 = Maths::Max(0, int(rarities[bonus]) - 1);
		addLoot(this, names[bonus], softenedRarity2, qty);
	}
}

// -------------------------------------
// Configure chest contents
// Notes:
// - Coins slightly increased overall
// - Each tier gets a tiny chance to roll one extra item
// - Rarity softened by -1 on pick to make drops "slightly more likely"
// -------------------------------------
void InitLoot(CBlob@ this)
{
	/*
		If you want a random quantity:
			addLoot(this, item_name, item_rarity, XORRandom(max_qty)+1);

		If you want to add coins:
			addLoot(this, "coins", coin_rarity, coin_quantity);

		If you want an item to always drop:
			set quantity to 0 in whatever consumes this table
			(or add multiple entries / lower rarity).
	*/

	// Coins (buffed floor & range)
	addLoot(this, "coins", 0, XORRandom(20) + 20);

	// Tier A - mixed utility/scroll-ish items
	string[] tA_names = {
		"carnage","drought","sfshark","selemental","2weeks",
		"vodka","sreinforce","midas","sgreg","shorde",
		"sshark","sskeleton","szombie"
	};
	u8[] tA_rarities = { 1,1,1,1,1,1,1,1,1,1, 2,1,1 };
	addRandomFromPool(this, tA_names, tA_rarities, 12 /* 12% bonus roll */);

	// Tier B - stronger summons/consumables
	string[] tB_names = { "sarsonist","sbunny","sgargoyle","snecromancer","sslayer","sstalker" };
	u8[] tB_rarities = { 2,2,2,2,2,2 };
	addRandomFromPool(this, tB_names, tB_rarities, 10 /* 10% */);

	// Tier C - classic mobs + lifeforce
	string[] tC_names = { "skeleton","zombie","pcrawler","pankou","zombieknight","lifeforce" };
	u8[] tC_rarities = { 3,3,3,3,3,3 };
	addRandomFromPool(this, tC_names, tC_rarities, 8 /* 8% */);

	// Gentle global sweetener (~15% chance for an extra treat)
	if (XORRandom(100) < 15)
	{
		addLoot(this, "2weeks", 2, 1);
	}
}

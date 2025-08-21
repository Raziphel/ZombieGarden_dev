
shared class Loot
{
	string name;
	int rarity;
	int quantity;
};

f32 openHealth = 0.0f;	 // health of wooden chest when it will be opened     0.5f = 1 heart
int itemVelocity = 0.5f; // how far item will fly from from the chest on open
bool button = false;	 // open chest by button (hold E) or by hit

void InitLoot(CBlob @ this)
{
	/*if you want a random quantity then write "addLoot(this, item name, item rarity, XORRandom(item quantity));"
	  if you want to add coins then write "addLoot(this, "coins", item rarity, item quantity);"
	  if you want to make item drop always set "item quantity" as "0"
	*/

	// addLoot(this, item name, item rarity, item quantity)
	addLoot(this, "coins", 0, XORRandom(39) + 1); // chest will drop coins with quantity 1 - 30

	int rs = XORRandom(13);

	if (rs == 0)
		addLoot(this, "scrollcarnage", 1, 1);
	else if (rs == 1)
		addLoot(this, "scrolldrought", 1, 1);
	else if (rs == 2)
		addLoot(this, "scrollfshark", 1, 1);
	else if (rs == 3)
		addLoot(this, "scrollselemental", 1, 1);
	else if (rs == 4)
		addLoot(this, "scroll2weeks", 1, 1);
	else if (rs == 5)
		addLoot(this, "vodka", 1, 1);
	else if (rs == 6)
		addLoot(this, "scrollreinforce", 1, 1);
	else if (rs == 7)
		addLoot(this, "scrollmidas", 1, 1);
	else if (rs == 8)
		addLoot(this, "scrollgreg", 1, 1);
	else if (rs == 9)
		addLoot(this, "scrollhorde", 1, 1);
	else if (rs == 10)
		addLoot(this, "scrollshark", 2, 1);
	else if (rs == 11)
		addLoot(this, "scrollskeleton", 1, 1);
	else if (rs == 12)
		addLoot(this, "scrollzombie", 1, 1);

	int ruc = XORRandom(3);

	if (ruc == 0)
		addLoot(this, "soulshard", 2, 1);

	int rz = XORRandom(6);

	if (rz == 0)
		addLoot(this, "skeleton", 3, 1);
	else if (rz == 1)
		addLoot(this, "zombie", 3, 1);
	else if (rz == 2)
		addLoot(this, "pcrawler", 3, 1);
	else if (rz == 3)
		addLoot(this, "pankou", 3, 1);
	else if (rz == 4)
		addLoot(this, "zombieknight", 3, 1);
	else if (rz == 5)
		addLoot(this, "lifeforce", 3, 1);
}

void addLoot(CBlob @ this, string NAME, int RARITY, int QUANTITY)
{
	if (!this.exists("loot"))
	{
		Loot[] loot;
		this.set("loot", loot);
	}

	Loot l;
	l.name = NAME;
	l.rarity = RARITY;
	l.quantity = QUANTITY;

	this.push("loot", l);
}

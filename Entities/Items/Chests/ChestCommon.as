
shared class Loot
{
    string name; 
    int rarity;
    int quantity;
};

f32 openHealth = 1.0f; //health of wooden chest when it will be opened     0.5f = 1 heart
int itemVelocity = 2.0f; //how far item will fly from from the chest on open
bool button = true; //open chest by button (hold E) or by hit

void InitLoot( CBlob@ this )
{
    /*if you want a random quantity then write "addLoot(this, item name, item rarity, XORRandom(item quantity));"
      if you want to add coins then write "addLoot(this, "coins", item rarity, item quantity);" 
      if you want to make item drop always set "item quantity" as "0"
    */

	addLoot(this, "coins", 0, XORRandom(100) + 1); //chest will drop coins with quantity 1 - 30
	
	// scroll
	int rs1 = XORRandom(8);
	
	if (rs1==0)
		addLoot(this, "carnage", 0, 1);
	else if (rs1==1)
		addLoot(this, "drought", 0, 1);
	else if (rs1==2)
		addLoot(this, "sfshark", 0, 1);
	else if (rc1==7)
		addLoot(this, "2weeks", 0, 1);
	else if (rs1==3)
		addLoot(this, "selemental", 0, 1);
	//else if (rs1==4)
	//	addLoot(this, "smeteor", 0, 1);
	//else if (rs1==4)
	//	addLoot(this, "sreturn", 0, 1);
	else if (rs1==4)
		addLoot(this, "sreinforce", 0, 1);
	else if (rs1==5)
		addLoot(this, "midas", 0, 1);
	else if (rs1==6)
		addLoot(this, "lifeforce", 0, 1);


	// soul
	int rc1 = XORRandom(6);
	
	if (rc1==0)
		addLoot(this, "lifeforce", 0, 1);
	else if (rc1==1)
		addLoot(this, "chickenhead", 0, 1);
	else if (rc1==2)
		addLoot(this, "dragoonwings", 0, 1);
	else if (rc1==3)
		addLoot(this, "wizardstaff", 0, 1);
	else if (rc1==4)
		addLoot(this, "crossbow_item", 0, 1);
	else if (rc1==5)
		addLoot(this, "assassinknife", 0, 1);

	//second soul
	int rc2 = XORRandom(6);
	
	if (rc2==0)
		addLoot(this, "lifeforce", 0, 1);
	else if (rc2==1)
		addLoot(this, "chickenhead", 0, 1);
	else if (rc2==2)
		addLoot(this, "dragoonwings", 0, 1);
	else if (rc2==3)
		addLoot(this, "wizardstaff", 0, 1);
	else if (rc2==4)
		addLoot(this, "crossbow_item", 0, 1);
	else if (rc2==5)
		addLoot(this, "assassinknife", 0, 1);
		
	//third soul
	int rc3 = XORRandom(6);
	
	if (rc3==0)
		addLoot(this, "lifeforce", 0, 1);
	else if (rc3==1)
		addLoot(this, "chickenhead", 0, 1);
	else if (rc3==2)
		addLoot(this, "dragoonwings", 0, 1);
	else if (rc3==3)
		addLoot(this, "wizardstaff", 0, 1);
	else if (rc3==4)
		addLoot(this, "crossbow_item", 0, 1);
	else if (rc3==5)
		addLoot(this, "assassinknife", 0, 1);

	
	// item
	int ri1 = XORRandom(15);
	
	if (ri1==0)
		addLoot(this, "blesseddrill", 0, 1);
	else if (ri1==1)
		addLoot(this, "rocketlauncher", 0, 1);
	else if (ri1==2)
		addLoot(this, "megasaw", 0, 1);


}



void addLoot(CBlob@ this, string NAME, int RARITY, int QUANTITY)
{    
    if (!this.exists("loot"))
    {
        Loot[] loot;
        this.set( "loot", loot );
    }

    Loot l;
    l.name = NAME;
    l.rarity = RARITY;
    l.quantity = QUANTITY;

    this.push("loot", l);
}
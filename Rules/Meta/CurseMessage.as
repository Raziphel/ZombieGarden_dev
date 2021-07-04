// Message

void onInit(CBlob@ this)
{
	Sound::Play("/survive.ogg");
	client_AddToChat("The curse is spreading, what a horrible night to go hollow...", SColor(255, 255, 0, 0));
	this.server_Die();	
}
// Message

void onInit(CBlob@ this)
{
	Sound::Play("/dontyoudare.ogg");
	client_AddToChat("A mini boss has spawned!", SColor(255, 0, 0, 0));
	this.server_Die();	
}
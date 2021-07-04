// Message

void onInit(CBlob@ this)
{
	Sound::Play("/dontyoudare.ogg");
	client_AddToChat("A Boss has spawned!", SColor(255, 0, 0, 0));
	this.server_Die();	
}
// Aphelion (edited by Frikman) \\

void onInit(CBlob @ this)
{
	this.Tag("survivorplayer");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
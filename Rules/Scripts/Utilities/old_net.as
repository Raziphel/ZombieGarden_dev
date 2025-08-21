void onInit(CRules @ this)
{
	// Enable legacy networking for now
	// Migrating to the newer net setup would take a lot of work
	getNet().legacy_cmd = true;
}
// set kills, deaths and assists

#include "AssistCommon.as";

void addKillAndRescore(CPlayer@ p)
{
	if (p is null) return;
	p.setKills(p.getKills() + 1);
	// temporary until we have a proper score system
	p.setScore(100 * (f32(p.getKills()) / f32(p.getDeaths() + 1)));
}

void rescoreOnly(CPlayer@ p)
{
	if (p is null) return;
	p.setScore(100 * (f32(p.getKills()) / f32(p.getDeaths() + 1)));
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	// Only count kills, deaths and assists when the game is running
	if (this.isGameOver() || this.isWarmup() || blob is null) return;

	CPlayer@ killer = blob.getPlayerOfRecentDamage(); // player who dealt the most recent damage
	CPlayer@ victim = blob.getPlayer();               // player who died (may be null for zombies etc.)
	CPlayer@ helper = getAssistPlayer(victim, killer);

	// Assists
	if (helper !is null)
	{
		helper.setAssists(helper.getAssists() + 1);
	}

	// Deaths + victim rescore (only if there is a player)
	if (victim !is null)
	{
		victim.setDeaths(victim.getDeaths() + 1);
		rescoreOnly(victim);
	}

	// Kills per custom rules
	if (killer is null) return; // environment death or no killer -> nothing to do

	const u8 killerTeam = killer.getTeamNum();
	const u8 victimTeam = blob.getTeamNum();
        const bool victimIsZombie = blob.hasTag("zombie");

        // Rule 1: Team 0 killing a blob tagged "zombie" gets a kill
        if (killerTeam == 0 && victimIsZombie)
        {
                addKillAndRescore(killer);
                // track total undead killed for record status
                this.add_u32("undead_kills", 1);
                this.Sync("undead_kills", true);
                return;
        }

	// Rule 2: Team 1 killing anyone on team 0 gets a kill
	if (killerTeam == 1 && victimTeam == 0)
	{
		addKillAndRescore(killer);
		return;
	}

	// Fallback: standard different-team kill logic
	if (killerTeam != victimTeam)
	{
		addKillAndRescore(killer);
	}
}

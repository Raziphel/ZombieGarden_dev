// Dash v1.0 by Strathos (edited by Frikman)
// Keep the original directional burst while giving it a real cooldown.

#include "MakeDustParticle.as";

const u32 DASH_COOLDOWN_TICKS = 45;
const u32 DASH_ACTIVE_TICKS = 15;
const f32 DASH_FORCE = 440.0f;

void onInit(CBlob @ this)
{
	this.set_u32("zg_next_dash_time", 0);
	this.set_u32("zg_dash_end_time", 0);
	this.set_bool("dashing", false);
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob @ this)
{
	if (this.hasTag("dead"))
		return;

	const u32 now = getGameTime();
	const bool active = this.get_bool("dashing");
	if (active && now >= this.get_u32("zg_dash_end_time"))
		this.set_bool("dashing", false);

	// A held taunt key used to retrigger the dash every few seconds.
	// Require a fresh press so one input produces exactly one burst.
	if (now < this.get_u32("zg_next_dash_time") ||
		!this.isKeyJustPressed(key_taunts))
		return;

	const bool left = this.isKeyPressed(key_left);
	const bool right = this.isKeyPressed(key_right);
	if (left == right || !(this.isOnGround() || this.isOnLadder()))
		return;

	Vec2f vel = this.getVelocity();
	if (vel.Length() >= 3.0f)
		return;

	this.set_u32("zg_next_dash_time", now + DASH_COOLDOWN_TICKS);
	this.set_u32("zg_dash_end_time", now + DASH_ACTIVE_TICKS);
	this.set_bool("dashing", true);

	MakeDustParticle(this.getPosition() + Vec2f(0.0f, 9.0f), "/DustSmall.png");
	CSprite @sprite = this.getSprite();
	if (sprite !is null)
		sprite.PlaySound("/StoneJump");

	const f32 xCompensate = left
		? 50.0f * (vel.x > 0.0f ? vel.x : vel.x * 1.5f)
		: 50.0f * (vel.x < 0.0f ? vel.x : vel.x * 1.5f);
	this.AddForce(Vec2f(left ? -DASH_FORCE : DASH_FORCE, 10.0f) -
		Vec2f(xCompensate, 0.0f));
}

#include "RunnerCommon.as"
#include "KnockedCommon.as"

void onInit(CSprite@ this)
{
    // Prevent running while blob is in fire to match standard behaviour
    this.getCurrentScript().runFlags |= Script::tick_not_infire;
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null)
    {
        return; // safety check
    }

    if (blob.hasTag("dead"))
    {
        if (!this.isAnimation("dead"))
        {
            this.SetAnimation("dead");
        }

        // ensure the head shows the correct dead frame
        blob.Tag("dead head");
        blob.Untag("attack head");
        return;
    }

    bool knocked = isKnocked(blob);
    const bool action1 = blob.isKeyPressed(key_action1);
    const bool left = blob.isKeyPressed(key_left);
    const bool right = blob.isKeyPressed(key_right);
    const bool up = blob.isKeyPressed(key_up);
    const bool down = blob.isKeyPressed(key_down);
    const bool inair = (!blob.isOnGround() && !blob.isOnLadder());

    if (blob.hasTag("seated"))
    {
        this.SetAnimation("crouch");
    }
    else if (action1 || (this.isAnimation("build") && !this.isAnimationEnded()))
    {
        this.SetAnimation("build");
    }
    else if (inair)
    {
        this.SetAnimation("fall");
    }
    else if ((left || right) || (blob.isOnLadder() && (up || down)))
    {
        this.SetAnimation("run");
    }
    else
    {
        this.SetAnimation("default");
    }

    // handle head animation tags
    if (knocked)
    {
        blob.Tag("dead head");
        blob.Untag("attack head");
    }
    else if (action1)
    {
        blob.Tag("attack head");
        blob.Untag("dead head");
    }
    else
    {
        blob.Untag("attack head");
        blob.Untag("dead head");
    }
}

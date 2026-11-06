/* Targeting */

CBlob @GetClosestVisibleTarget(CBrain @ this, CBlob @blob, f32 radius)
{
	CBlob @[] nearBlobs;
	blob.getMap().getBlobsInRadius(blob.getPosition(), radius, @nearBlobs);

	CBlob @best_candidate;
	f32 closest_dist = 999999.9f;
	for (int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob @candidate = nearBlobs[step];
		if (candidate is null || candidate is blob)
			continue;

		if (!candidate.hasTag("dead"))
		{
			if (isTarget(blob, candidate))
			{
				const bool is_visible = isTargetVisible(blob, candidate);
				const f32 dist = getDistanceBetween(candidate.getPosition(), blob.getPosition());
				// Keep the nearest visible target; the old ternary expression
				// accidentally ignored distance because of operator precedence.
				if (is_visible && dist < closest_dist)
				{
					// if(!is_visible && XORRandom(30) > 3)
					// continue;

					@best_candidate = candidate;
					closest_dist = dist;
				}
			}
		}
	}

	return best_candidate;
}

CBlob @GetBestTarget(CBrain @ this, CBlob @blob, f32 radius)
{
	// if (blob.hasTag("is_stuck"))
	// return GetClosestVisibleTarget(this, blob, radius);

	CBlob @[] nearBlobs;
	blob.getMap().getBlobsInRadius(blob.getPosition(), radius, @nearBlobs);

	CBlob @best_candidate;
	f32 highest_priority = 0.0f;
	f32 closest_dist = 999999.9f;

	for (int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob @candidate = nearBlobs[step];
		if (candidate is null || candidate is blob)
			continue;

		if (candidate.getBrain() !is null)
		{
			CBlob @otherTarget = candidate.getBrain().getTarget();
			if (otherTarget !is null && otherTarget.getPlayer() !is null &&
				!otherTarget.hasTag("dead") && isTarget(blob, otherTarget))
			{
				this.SetTarget(otherTarget);
				return otherTarget;
			}
		}

		f32 priority = getTargetPriority(blob, candidate);
		if (priority >= highest_priority && !candidate.hasTag("dead"))
		{
			if (isTarget(blob, candidate))
			{
				f32 dist = getDistanceBetween(candidate.getPosition(), blob.getPosition());
				if (dist < closest_dist)
				{
					@best_candidate = candidate;
					highest_priority = priority;
					closest_dist = dist;

					// High enough lets chase!
					if (highest_priority > 0.55)
						break;
					// break;
				}
			}
		}
	}

	return best_candidate;
}
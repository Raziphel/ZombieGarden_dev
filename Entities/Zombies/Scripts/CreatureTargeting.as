/* Targeting */

CBlob @GetClosestVisibleTarget(CBrain @ this, CBlob @blob, f32 radius)
{
	CBlob @[] nearBlobs;
	CMap @map = blob.getMap();
	if (map is null || radius <= 0.0f)
		return null;
	map.getBlobsInRadius(blob.getPosition(), radius, @nearBlobs);

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
				const f32 dist = getDistanceBetween(candidate.getPosition(), blob.getPosition());
				// Raycasts are expensive when a horde sees many nearby blobs.
				// A farther candidate cannot beat the current closest target,
				// so test distance before tracing line of sight.
				if (dist < closest_dist && isTargetVisible(blob, candidate))
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
	CMap @map = blob.getMap();
	if (map is null || radius <= 0.0f)
		return null;
	map.getBlobsInRadius(blob.getPosition(), radius, @nearBlobs);

	CBlob @best_candidate;
	f32 highest_priority = 0.0f;
	f32 closest_dist = 999999.9f;

	for (int step = 0; step < nearBlobs.length; ++step)
	{
		CBlob @candidate = nearBlobs[step];
		if (candidate is null || candidate is blob)
			continue;

		// Borrow an ally's player target only if that player is still
		// inside our search radius. This helper must not change brain state:
		// the broad awareness scan uses it to request a hint only.
		if (candidate.getTeamNum() == blob.getTeamNum() &&
			candidate.getBrain() !is null)
		{
			CBlob @otherTarget = candidate.getBrain().getTarget();
			if (otherTarget !is null && otherTarget.getPlayer() !is null &&
				!otherTarget.hasTag("dead") && isTarget(blob, otherTarget) &&
				getDistanceBetween(otherTarget.getPosition(), blob.getPosition()) <= radius)
			{
				return otherTarget;
			}
		}

		if (candidate.hasTag("dead") || !isTarget(blob, candidate))
			continue;

		const f32 priority = getTargetPriority(blob, candidate);
		const f32 dist = getDistanceBetween(candidate.getPosition(), blob.getPosition());
		// Prefer the most important target, then the nearest target at
		// roughly the same priority. Do not stop at the first strong target.
		if (best_candidate is null || priority > highest_priority + 0.001f ||
			(Maths::Abs(priority - highest_priority) <= 0.001f && dist < closest_dist))
		{
			@best_candidate = candidate;
			highest_priority = priority;
			closest_dist = dist;
		}
	}

	return best_candidate;
}
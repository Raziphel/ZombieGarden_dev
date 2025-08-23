void sparks(Vec2f at, f32 angle, f32 damage)
{
	int amount = damage * 5 + XORRandom(5);

	for (int i = 0; i < amount; i++)
	{
		Vec2f vel = getRandomVelocity(angle, damage * 3.0f, 180.0f);
		vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
		ParticlePixel(at, vel, SColor(255, 255, 255, 0), true);
	}
}
void goldtilesparks(Vec2f at, f32 angle, f32 damage)
{
	int amount = damage * 5 + XORRandom(5);

	for (int i = 0; i < amount / 6; i++)
	{
		Vec2f vel = getRandomVelocity(angle, damage * 5.0f, 180.0f);
		vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;
		ParticlePixel(at, vel, SColor(255, 255, 150 + XORRandom(105), 0), true);
	}
}

void irontilesparks(Vec2f at, f32 angle, f32 damage)
{
	int amount = damage * 5 + XORRandom(5);

	for (int i = 0; i < amount / 6; i++)
	{
		Vec2f vel = getRandomVelocity(angle, damage * 5.0f, 180.0f);
		vel.y = -Maths::Abs(vel.y) + Maths::Abs(vel.x) / 3.0f - 2.0f - float(XORRandom(100)) / 100.0f;

		SColor col = XORRandom(2) == 0 ? SColor(255, 222, 150 + XORRandom(105), 0) : SColor(255, 222, 150 + XORRandom(105), 228);

		ParticlePixel(at, vel, col, true);
	}
}

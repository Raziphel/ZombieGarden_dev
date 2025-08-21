// Zombies_Utils.as
shared string base_name() { return "ruinstorch"; }

void spawnPortal(Vec2f pos) {
  server_CreateBlob("zombiealter", -1, pos + Vec2f(0, -24.0));
}

void spawnGraves(Vec2f pos) {
  int r = XORRandom(8);
  if (r == 0)
    server_CreateBlob("casket2", -1, pos + Vec2f(0, -16.0));
  else if (r == 1)
    server_CreateBlob("grave1", -1, pos + Vec2f(0, -16.0));
  else if (r == 2)
    server_CreateBlob("grave2", -1, pos + Vec2f(0, -16.0));
  else if (r == 3)
    server_CreateBlob("grave3", -1, pos + Vec2f(0, -16.0));
  else if (r == 4)
    server_CreateBlob("grave4", -1, pos + Vec2f(0, -16.0));
  else if (r == 5)
    server_CreateBlob("grave5", -1, pos + Vec2f(0, -16.0));
  else if (r == 6)
    server_CreateBlob("grave6", -1, pos + Vec2f(0, -16.0));
  else
    server_CreateBlob("casket1", -1, pos + Vec2f(0, -16.0));
}

#!/usr/bin/env python3
"""Quick source-level regression checks for Zombie Garden.

Run from anywhere: python3 tools/verify_zombie_garden.py
This is not an AngelScript compiler or a replacement for a KAG boot test.
"""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def content(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"Missing required file: {relative}")
    return path.read_text(encoding="utf-8-sig")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def check() -> None:
    rules = "Rules/Scripts/Zombies/"
    priority = content(rules + "Zombies_HordePriority.as")
    boss = content(rules + "Zombies_Boss.as")
    core = content(rules + "Zombies_Core.as")
    config = content(rules + "Zombies_Config.as")
    corpse = content("Entities/Zombies/Scripts/CreatureDeath.as")
    scores = content(rules + "Zombies_Scoreboard.as")
    records = content(rules + "Zombies_Records.as")

    require((ROOT / "Rules/ZombieGarden/gamemode.cfg").is_file(),
            "Canonical game-mode config missing")
    require((ROOT / "Rules/ZombieGarden/mapcycle.cfg").is_file(),
            "Canonical map cycle missing")
    for filename in ("gamemode.cfg", "mapcycle.cfg"):
        require(not (ROOT / "Rules/Config" / filename).exists(),
                f"Duplicate old rules file returned: {filename}")

    require('#include "Zombies_HordePriority.as"' in boss,
            "Boss queue is no longer using the priority helper")
    require('ZGFindWeakHordeMob(nextEnemy)' in core,
            "Ordinary waves no longer replace weaker zombies at cap")
    require('power >= incomingPower' in priority,
            "Weak enemies must never replace stronger ones")
    require('ZG_HORDE_SAFE_REPLACEMENT_DISTANCE' in priority,
            "Horde replacement no longer protects nearby players")
    require('getPlayersCount()' in priority,
            "Player-distance protection was removed")
    require('blob.getPlayer() !is null' in priority,
            "Player-controlled undead must not be retired")
    require('blob.hasTag("necromancer_zombie")' in priority,
            "Necromancer-controlled summons must not be retired")
    require('blob.hasTag("zg_boss_spawn")' in priority,
            "Milestone units must not be retired")
    require('inv.getItemsCount() > 0' in priority,
            "Horde retirement must not delete carried inventory")
    require('victim.Tag("zg_horde_retired")' in priority,
            "Retired blobs must be tagged before deletion")
    require('blob.hasTag("zg_horde_retired")' in scores,
            "Retired zombies must not award kill credit")

    for enemy in (
        "zchicken", "catto", "skeleton", "skeleton2", "zombie", "zombie2",
        "plantzombie", "bloodzombie", "evilzombie", "zombieknight",
        "gasbag", "immolator", "greg", "wraith", "zbison", "pbanshee",
        "horror", "writher", "digger",
    ):
        require(f'name == "{enemy}"' in priority,
                f"No horde priority configured for {enemy}")

    require('set_s32("max_zombie_revivals", 2)' in config,
            "Configured resurrection cap missing")
    require('zg_revive_count' in corpse and 'TryReviveCorpse(this)' in corpse,
            "Corpse resurrection is no longer bounded per creature")
    require('getBlobsByTag("zombie"' in corpse,
            "Zombie revivals must respect the living horde cap")
    require('hasLivingDefender' in records,
            "Survival records require at least one living defender")

    for relative in ("Entities/Shops/Scripts/Heal.as",
                     "Entities/Shops/Scripts/LesserHeal.as"):
        heal = content(relative)
        require('if (target is null' in heal,
                f"Healing script no longer guards absent targets: {relative}")
        require('target.getInitialHealth() - target.getHealth()' in heal,
                f"Healing script lost maximum-health clamp: {relative}")
        require('.PlaySound(' not in heal,
                f"Dedicated-server healing script uses sprite audio: {relative}")

    modified_scripts = [
        priority, boss, core, config, corpse, scores, records,
        content("Entities/Shops/Scripts/Heal.as"),
        content("Entities/Shops/Scripts/LesserHeal.as"),
    ]
    for index, script in enumerate(modified_scripts):
        require(script.count("{") == script.count("}"),
                f"Unbalanced braces in checked script index {index}")
        require("<<<<<<< " not in script and ">>>>>>> " not in script,
                f"Conflict marker in checked script index {index}")


if __name__ == "__main__":
    try:
        check()
    except (AssertionError, OSError) as error:
        print(f"Zombie Garden source check FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
    print("Zombie Garden source checks passed (not an engine compilation test).")

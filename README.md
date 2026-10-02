# RICOCHET

**ARENA, but you only have one bullet: it ricochets, gets stronger with every bounce, and once it has bounced it burns you.**

A single-screen top-down survival shooter built in **Odin + Raylib** for CSCI 4160U's Mini Game Jam (SQ2). Starts from ARENA; the twist is the one hot, bouncing bullet.

> The original course brief is preserved in [`HANDOUT.md`](HANDOUT.md).

## Build & run

Needs the [Odin compiler](https://odin-lang.org/) (ships with `vendor:raylib`). From a clean clone, one command:

```
odin run . -out:ricochet.exe
```

On Windows, if `odin` isn't on your `PATH`, call it by full path (e.g. `C:\odin\dist\odin.exe run . -out:ricochet.exe`).

## Controls

| Input | Action |
|---|---|
| `WASD` / arrows | Move |
| Left click | Throw the bullet toward the mouse |
| Right click | Recall the bullet (safe to catch, but resets its power to 1) |

While the bullet is out of your hand you're unarmed — you can only run. When it slows to a stop it drops **cold** to the floor; walk over it to pick it up. **Kills pierce:** one throw can clear a whole line, and each kill in the same throw scores more.

## The twist

- **One bullet.** Throw it with left click; while it's out, you're unarmed.
- **It ricochets.** Bounces off the arena walls.
- **Bounces make it stronger.** +1 power per bounce (up to 6), and a bit faster.
- **Once bounced, it's hot.** If it touches *you*, you take damage.
- **Friction.** It slows over time, then drops cold for you to retrieve.

## Enemies

- **Green grunt** — 1 HP, fast. The classic ARENA chaser.
- **Purple brute** — 3 HP, slow, from ~20s. Needs a power-3 (twice-bounced) hit to one-shot. HP pips show how many hits are left.
- **Orange charger** — 2 HP, from ~40s. Winds up, flashes a red aim line, then dashes along it. Step aside, then punish it while it's dazed.

## Status

- **Pass 1** — movement, the one-bullet throw/ricochet/bounce-power/hot/pick-up loop, green grunts, health, score, game over + replay.
- **Pass 2** — **recall** (right click) and **pierce combos** (rising score per kill in one throw).
- **Pass 3** — **purple brutes** and **orange chargers**, plus a per-enemy hit debounce so one bullet pass deals `power` once (makes brute HP meaningful).
- **Pass 4** — **survive 2:00 to win** (countdown HUD, win/lose screens) and **juice**: screen shake, red hurt-flash, enemy hit-flash, and procedurally generated sound (no external audio assets).
- **Pass 5** — spawn-director balance: total enemy cap, per-type caps (2 chargers / 4 brutes), a charger cooldown, and rarity weighting (green common, purple occasional, orange rare) so difficulty ramps by unlocking harder types, not by flooding the screen.

## Credits

Solo project. No external art/audio assets yet — everything is drawn with raylib primitives. See [`ATTRIBUTION.md`](ATTRIBUTION.md).

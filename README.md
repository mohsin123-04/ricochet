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

While the bullet is out of your hand you're unarmed — you can only run. When it slows to a stop it drops **cold** to the floor; walk over it to pick it up.

## The twist

- **One bullet.** Throw it with left click; while it's out, you're unarmed.
- **It ricochets.** Bounces off the arena walls.
- **Bounces make it stronger.** +1 power per bounce (up to 6), and a bit faster.
- **Once bounced, it's hot.** If it touches *you*, you take damage.
- **Friction.** It slows over time, then drops cold for you to retrieve.

## Status

Pass 1 (vertical slice): movement, the one-bullet throw/ricochet/bounce-power/hot/pick-up loop, green grunts, health, score, game over + replay.

Planned next: **recall** (right click), **pierce combos** (one throw clears a line, each kill scores more), **purple brutes** (3 HP, need a twice-bounced bullet), **orange chargers** (telegraph + dash).

## Credits

Solo project. No external art/audio assets yet — everything is drawn with raylib primitives. See [`ATTRIBUTION.md`](ATTRIBUTION.md).

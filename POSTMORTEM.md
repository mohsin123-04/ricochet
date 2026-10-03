---
# ---- Fill every field. Use `unavailable` (with a reason in tokens_source) rather than guessing. ----
game_title: RICOCHET
twist_one_liner: "ARENA, but you only have one bullet: it ricochets, gets stronger with every bounce, and once it has bounced it burns you."
twist_category: rule-bender      # rule-bender | enemies | player-progression | world | other
twist_from_ideas_list: adapted     # yes | adapted | no  (IDEAS.md lists a bouncing bullet; the one-bullet limit, power-per-bounce, hot bullet and recall were added on top)
how_far_from_arena: substantial  # small-twist | substantial | barely-recognizable

# Tools and models (lists; exact names as the tool shows them)
tools: [claude-code]
models: [claude-opus-4-8]
primary_model: claude-opus-4-8
plan: paid-personal
agent_instructions_file: no        # no committed CLAUDE.md/AGENTS.md

# Totals (must match jam-log.csv)
sessions: 1
total_minutes: 75
total_prompts: 9                   # messages sent this sitting
total_tokens_in: 13104985          # input + cache create + cache read, from ccusage
total_tokens_out: 82207
tokens_source: ccusage incl. cache

# Your estimate of who wrote the code in the final build (should add to 100)
code_share_llm_pct: 90             # accepted from the LLM with little/no change
code_share_mixed_pct: 10           # LLM-generated then changed on my direction (mostly balance numbers)
code_share_hand_pct: 0             # typed by hand

# Before this jam
odin_experience_before: none
llm_coding_before: occasional
gamedev_experience_before: none

transcripts_shared: no             # yes | no  (optional, ungraded)
---

# Postmortem — RICOCHET

Your own words. Grammar and spelling help from a tool is fine; the argument and
the evidence are yours. Aim for 1-2 pages plus the table.

## 1. The game

RICOCHET is a single-screen top-down survival shooter. You move with WASD and
throw your one and only bullet toward the mouse with left click. The bullet
ricochets off the arena walls, and every bounce raises its power by 1 (up to 6)
and speeds it up a little. The catch is that once it has bounced it is hot, so if
it touches you it burns you too. Right click recalls it instantly, which is safe
to catch but resets its power to 1. When it slows down it drops cold to the floor
and you walk over it to pick it up. Kills pierce, so one throw can clear a whole
line of enemies, and each kill in the same throw scores more. Survive two minutes
to win; run out of health and you die. There are three enemies: green grunts
(1 HP, fast), purple brutes (3 HP, slow, from about 20s), and orange chargers
(2 HP, from about 40s, which telegraph a red line and then dash along it).

Compared with ARENA:

- Kept: the bounded arena, enemies pouring in and chasing, health, score, and the survive-and-replay loop.
- Changed: shooting. ARENA lets you fire freely; RICOCHET gives you a single physical bullet you have to manage.
- Removed: unlimited ammo, and with it the "circle and hold fire" strategy.
- Added: the ricochet and power-per-bounce rule, the hot bullet, recall, pierce combos, the three enemy types, and the two-minute win condition.

Where is the depth?

The decision: every throw is a gamble about angle and about when to let the
bullet keep bouncing. Do you throw straight for a safe cold shot, let it bounce
to build power and risk it hitting you, or recall and reset?

The trade-off: bouncing is the only way to get the power a brute needs and to line
up big combos, but while the bullet is out you are unarmed and it can burn you.
Recall removes the risk but throws the power away.

The mastery: a skilled player leads the enemies so they line up, then throws one
bullet to hit the whole line, which maximizes each shot and gains more points. A
beginner just throws at whatever circle is closest.

## 2. Your setup

I used Claude Code with the claude-opus-4-8 model as an agent. It read and wrote
main.odin and ran the Odin compiler directly. I used Claude because I am already
familiar with it.

I did not commit a project instruction file (CLAUDE.md or AGENTS.md). For honesty,
Claude Code carries memory between sessions, so it already knew my course context,
that this is an Odin and raylib jam, and my preference for commit style, and I did
not paste the raylib binding or docs in by hand this sitting. The build uses only
the Odin standard library and the vendor:raylib binding that ships with the
compiler.

## 3. Feature by feature

In the table below, "who" is llm, mixed or me; "first try?" is whether the first
answer from the LLM compiled and worked without my changes; and "help" is 1 (got
in the way) to 5 (did it well).

| feature | who | prompts | first try? | minutes | help 1-5 | note |
|---|---|--:|---|--:|:--:|---|
| window, loop, game states, restart | llm | 1 | yes | ~8 | 5 | title/playing/over + replay, pass 1 |
| player movement | llm | 1 | yes | ~3 | 5 | WASD, clamped to arena |
| the one bullet (throw/ricochet/power/hot/pickup) | llm | 1 | yes | ~15 | 5 | the core twist, pass 1 (b27379a) |
| recall + pierce combos | llm | 1 | yes | ~8 | 4 | right-click return, rising score, pass 2 (7340d7f) |
| enemies and spawning | llm | 1 | yes | ~12 | 4 | grunt/brute/charger + charger state machine, pass 3 (3178e78) |
| health, damage, hit feedback | llm | 1 | yes | ~5 | 5 | i-frames, hurt flash |
| difficulty over time | mixed | 2 | no | ~10 | 4 | spawn caps + rarity; needed my balance direction, pass 5 (02f2ea9) |
| HUD | llm | 1 | yes | ~4 | 5 | health bar, score, countdown, bullet state |
| win condition + juice (shake/flash/sound) | llm | 1 | yes | ~12 | 4 | 2:00 survive, procedural audio, pass 4 (195e409) |

## 4. Where the LLM sped you up

The whole core loop (window, states, movement, and the one-bullet system of throw,
ricochet, power, hot and pickup) came up working in the first pass (b27379a). By
hand, the ricochet physics and the one-bullet state machine would have taken me a
couple of days at most.

Procedural sound (pass 4, 195e409) was another one. Generating a raylib Wave from a
decaying tone in code is fiddly to get right the first time, and the agent wrote it
so I needed no sound files or an audio editor.

The charger state machine (chase, telegraph, dash, dazed) also landed in one pass
with readable telegraphing.

## 5. Where it did not help

The main thing the LLM did not help with was the spawn rates. Claude was not able
to realize it would be hard for a player to fight that many enemies that quickly.
The first version flooded the screen and I died at 71s. It only came together after
I played it myself and told it to slow the spawns down.

## 6. One LLM-introduced bug: found, fixed, verified

The bug: in the first enemy pass the bullet applied its damage on every frame it
overlapped an enemy, not once per pass. A bullet sitting on an enemy for 2 to 3
frames drained 2 to 3 times its power, so a weak power-1 bullet could kill a 3-HP
purple brute instantly. That defeats the whole "you need a twice-bounced bullet to
one-shot a brute" design.

How I noticed: I reasoned about it while adding brutes, since a 3-HP enemy that
dies to a power-1 hit makes brute HP meaningless. It would have been invisible with
grunts (1 HP) because they die in a single hit either way.

The fix (pass 3, commit 3178e78) was a per-enemy hit cooldown, so one pass deals
power exactly once.

Before (hit every frame):

    if b.state == .Flying && dist(b.pos, e.pos) < BULLET_RADIUS + e.radius {
        e.hp -= b.power          // runs again next frame while still overlapping
    }

After (debounced):

    if e.hit_cd > 0 do e.hit_cd -= dt
    if b.state == .Flying && e.hit_cd <= 0 && dist(b.pos, e.pos) < BULLET_RADIUS + e.radius {
        e.hp -= b.power
        e.hit_cd = HIT_CD        // can't be hit again for HIT_CD seconds
    }

How I know it is fixed: the brute now shows HP pips (small dots above it) and a
white flash the instant it is struck. A power-1 bullet visibly knocks off one pip
per pass and the brute survives; only a power-3 (twice-bounced) bullet clears all
three pips in one pass. That on-screen pip count is the verification.

## 7. Pitch vs. delivered

Wednesday pitch: "bullets bounce off the walls and keep hitting enemies, for mass
kills." Added on top during the build were the one-bullet limit, power per bounce,
the hot bullet, and recall, which are the costs that make bouncing a decision.

Delivered: nothing from the pitch was cut. On top of it I added the three enemy
types (the pitch did not specify enemies), the two-minute survival win (the pitch
had no end state), and the spawn balancing.

## 8. Improving the pipeline

Next time I would prompt better from the start. For example, I would tell Claude up
front to make the enemy spawn rates slower, instead of fixing the balance only
after I had played it and died to a wall of enemies.

## 9. Anything else

Optional: what surprised you, what you learned about Odin, Raylib or game
development, what you would tell next year's class.

# Twist ideas

Use these as a starting point. The strongest twists **combine** two ideas or
**bend** one until it is yours, and **add depth**: a new decision with a real
trade-off, not just more stuff. The enemy and progression ideas are the
easiest to make shallow. A new enemy adds depth only if it asks for a
*different* response (a Charger makes you watch for telegraphs), and upgrade
cards add depth only if picking one means giving something up. Sizes are rough, for a first-time Odin
programmer with an LLM: **S** = an evening, **M** = a weekend day, **L** = the
whole weekend and most of your nerves.

You can go as far as you like, from one clever rule to a different genre.
The last section has ideas for going all the way.

---

## Rule-benders: change what the game *is*

Usually the most memorable twists. Each is one sentence and changes every decision.

| idea | size | the sentence |
|---|:--:|---|
| **Pacifist** | M | You cannot shoot. Enemies die when they collide with each other, or with hazards you lure them into. |
| **Time moves when you move** | M | Enemies and bullets only advance while the player is moving (see *SUPERHOT*). |
| **Health is ammo** | S | Every shot costs HP. Killing enemies drops HP back. |
| **Ricochet** | S | Bullets bounce off walls and can hit you. |
| **Swap** | M | Right-click swaps your position with the nearest enemy. |
| **Magnet** | M | You have no gun. Pull or push enemies with the mouse buttons and smash them into walls. |
| **One bullet** | S | You have one bullet. Walk over it to pick it back up. |
| **Shrinking arena** | S | The walls close in over the round; kills push them back out. |
| **Reverse** | L | You play the spawner: place enemies to kill an AI-controlled player before the timer ends. |
| **Echo** | L | Every 15 s a ghost replays your last 15 s of movement and shooting, fighting beside you (or against you). |
| **Rhythm** | M | Shots fired on the beat do triple damage; off-beat shots do nothing. |
| **Darkness** | M | The arena is dark; you see only a small circle of light around you, and your shots light up briefly. |

## Enemies: change what you fight

| idea | size | notes |
|---|:--:|---|
| **Charger** | S | Stops, telegraphs (flash, 0.5 s), then dashes in a straight line. Teaches the player to read warnings. |
| **Shooter** | S | Keeps its distance and fires slow bullets at you. |
| **Splitter** | S | Splits into two smaller, faster enemies when shot. |
| **Shielded** | M | Can only be hit from behind. |
| **Swarm** | M | Flocking enemies (separation, alignment, cohesion) instead of a straight chase. Preview of Chapter 14. |
| **Boss at 60 s** | M/L | One big enemy with 2-3 attack patterns and a health bar. |
| **Enemy that learns** | M | The more you use one tactic (say, circling), the more the spawner counters it. |

## Player and progression: change how you grow

| idea | size | notes |
|---|:--:|---|
| **Dash** | S | Short burst of speed with a cooldown; invulnerable during the dash. |
| **Level-up cards** | M | Enemies drop XP. Every level pauses the game and offers 3 random upgrades (fire rate, spread shot, piercing, speed, max HP...). The *Vampire Survivors* loop. |
| **Weapon pickups** | S/M | Shotgun, laser, orbiting blades — each on the floor for a limited time. |
| **Combo multiplier** | S | Kills in quick succession multiply the score; getting hit resets it. |
| **Risk / reward** | S | Standing near enemies charges a meter that powers a screen-clearing bomb. |
| **Shop between waves** | M | Split the round into three waves; spend score between waves. |
| **Two-player co-op** | M | Second player on the same keyboard, or on a gamepad. |

## World: change the space

| idea | size | notes |
|---|:--:|---|
| **Obstacles** | S | Pillars that block bullets and movement. |
| **Destructible cover** | M | Crates that absorb bullets and break. |
| **Hazards** | S | Spike tiles, lava, a moving laser sweep. Hurt enemies too. |
| **Random layouts** | M | Each round generates a new obstacle layout, with a check that every spot is reachable. Preview of Chapter 16 / SQ4. |
| **Portals** | M | Two linked portals that teleport the player, enemies *and* bullets. |
| **Weather / events** | S | Every 20 s a random event: fog, ice floor (slippery movement), double speed, bullet rain. |

## Feel and presentation: welcome, but not a twist on their own

Pair any of these with a real twist above; they make any game better.

- **Hit-stop**: freeze for 40-80 ms on a kill.
- **Screen shake** on damage, scaled to how bad it is.
- **Particles** on death, on bullet impact, on dash.
- **Knockback** on enemies you hit.
- **Sound** for every action (jsfxr takes 30 seconds per effect).
- **Sprites** instead of rectangles, and animated ones if you're keen (art is optional).
- **High score** saved to a file between runs.

---

## Go further: ARENA becomes another game

The rules allow it, and the rubric rewards it. Some directions:

| idea | size | *it started as ARENA, now it's...* |
|---|:--:|---|
| **Tower defence** | L | ...a game where you can't move. You place turrets between waves and the enemies path around them. |
| **Roguelike rooms** | L | ...a run through connected arenas, each cleared room opens the next, with pickups along the way. |
| **Sports** | M | ...a match where enemies are balls you shoot into goals, and the other team wants them too. |
| **Stealth** | M | ...a game where enemies patrol instead of chase, and being seen is what hurts you. |
| **Puzzle** | M | ...a set of hand-made levels, a limited number of bullets each, and ricochets to plan. |
| **Herding** | M | ...a game where you shoot *near* creatures to scare them into a pen before time runs out. |
| **Rhythm** | M/L | ...a game where enemies arrive on the beat, and you only move and shoot on it. |

## Combine two, get a game

- *Pacifist* + *Hazards* = a trap-setting game.
- *Ricochet* + *Shrinking arena* = gets more dangerous to shoot the longer you live.
- *Time moves when you move* + *Charger* = a puzzle about reading telegraphs.
- *Darkness* + *Echo* = your ghost is the only light you have.
- *Level-up cards* + *Health is ammo* = every upgrade is a gamble.

## Before you commit to a twist, ask

1. Can I say it in **one sentence**?
2. Does it change **what the player decides**, second to second?
3. Does it add **depth**? Every choice has a cost, no option is always best,
   and an expert would play it differently from a beginner.
4. Can I have **something playable for the Monday showcase** and finish by Sun Oct 4?
5. What is the **smallest version** that is still the twist? Build that first.

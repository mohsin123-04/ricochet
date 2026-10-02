# Mini Game Jam — ARENA + your twist

CSCI 4160U - Game Development · Stage 3 (Chapters 5 and 6) · **Side Quest SQ2, 5 pts**

Everyone starts from the same small game, **ARENA**, and then makes it their
own: change, add, remove or replace whatever you like. You may use any tool,
**including LLM assistants and coding agents**. How you use them is part of
what we are studying.

| When | What |
|---|---|
| **Wed Sep 23** (Chapter 5) | ARENA presented, twist pitched in class, build starts |
| Thu Sep 24 - Sun Sep 27 | Build on your own time. Aim for **something playable** by Monday. |
| **Mon Sep 28** (Chapter 6) | **Showcase** of your game *as it stands*. Classmates play it; you get feedback. |
| Mon Sep 28 - Sun Oct 4 | Keep going, using what you learned at the showcase. |
| **Sun Oct 4, 23:59** | **Everything due:** game tagged `jam-final`, `POSTMORTEM.md`, `jam-log.csv`, all pushed. |

Files in this folder:

- `README.md`: this brief (the game, the rules, the stack, resources)
- `IDEAS.md`: twist ideas, if you need a starting point
- `RUBRIC.md`: how the 5 points are awarded
- `POSTMORTEM.md`: the template you fill in (due Oct 4)
- `jam-log.csv`: the session log you keep **while** you work
- `ATTRIBUTION.md`: credit every asset you did not make (if you use any)

---

## The rules

1. **Solo.** Your game, your repo. Helping each other debug is fine and encouraged.
2. **Odin + Raylib** (`vendor:raylib`). 2D.
3. **Any tool is allowed**: Claude Code, Codex, Cursor, Copilot, Gemini, ChatGPT, a
   local model, or none at all. "None" is a valid data point too.
4. **Log every working session** in `jam-log.csv` (see *The data*, below).
5. **You can explain any line you submit.** Spot-checks happen in class and in the lab.
6. **Art is optional.** Rectangles and circles are completely fine. If you do
   use assets (downloaded or generated), credit each one in `ATTRIBUTION.md`
   (source, author, licence, or tool + prompt if AI-generated).
7. **Keep it playable.** A small game that works beats an ambitious one that doesn't.

---

## The starting point: ARENA

ARENA is a single-screen, top-down survival shooter. You move around a
bounded arena while enemies pour in from the edges and chase you. You shoot
them to stay alive and to score points; every hit you take costs health, and
the longer you last, the harder it gets. The round ends when you survive long
enough or run out of health, and then you play again. Think of the first
minute of *Vampire Survivors* or *Brotato*, or any arcade twin-stick shooter.

**That's all there is.** No spec, no required features, no numbers, no fixed
controls. ARENA is a shared starting point, so that on Monday we can all see
how far each game travelled from it.

---

## Your twist: make it yours

**Change ARENA as much as you want.** Modify, add, remove or replace any
part of it. A clever rule on top of ARENA is fine. Turning it into something
barely recognizable is better, as long as it is still a finished game. You
should still be able to describe it in one sentence: *"ARENA, but your
bullets bounce and can hit you"*, or *"it started as ARENA, now it's a
tower defence where you are the tower."*

We ask for two things:

- **A complete game.** You can start it, play it, reach an end, and play
  again. It doesn't crash.
- **Depth.** ARENA has one strategy: circle and shoot. Your version should
  create choices with real trade-offs, so there is more than one way to play
  and a skilled player plays differently from a new one.

Polish and "juice" (screen shake, particles, sound) are welcome, but they
don't count as the twist on their own.

**Depth is not complexity.** *Ricochet* is one rule, and every shot becomes a
risk calculation about angles and where you stand. Ten guns that differ only
in damage numbers are more complex, but you still make the same decision.
Test your game with three questions:

1. **The decision.** What choice does the player make, second to second or
   run to run?
2. **The trade-off.** What does each option cost? If one option is always
   best, it is not a real choice.
3. **The mastery.** What does an expert do that a beginner doesn't? Which
   strategies appear that you did not program directly?

Stuck? See `IDEAS.md`. Taking an idea from the list is fine. Making it your
own (combining two, bending it, pushing it somewhere unexpected) scores higher.

You pitch your twist in class on **Wed Sep 23** (on Canvas, in one sentence). You
can change it later; the postmortem asks what changed and why.

---

## The stack

- **Odin** — <https://odin-lang.org/docs/overview/>
- **Raylib via `vendor:raylib`** — <https://pkg.odin-lang.org/vendor/raylib/>
- **Raylib cheatsheet** (C names; Odin drops the prefix and uses `rl.`) —
  <https://www.raylib.com/cheatsheet/cheatsheet.html>
- **Raylib examples** (C, but they translate line by line) — <https://www.raylib.com/examples.html>
- **Odin's official examples**, including raylib ones — <https://github.com/odin-lang/examples>
- **The Raylib binding itself**, the exact API as Odin sees it: run `odin root`, then
  open `<that path>/vendor/raylib/raylib.odin`.
- Optional, for the ambitious: Karl Zylinski's
  [hot-reload template](https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template)
  (change code while the game runs) and [web template](https://github.com/karl-zylinski/odin-raylib-web)
  (put your game on itch.io). Both authored by the author of
  [*Understanding the Odin Programming Language*](https://odinbook.com).

### Free LLMs you can use

You do **not** need to pay for anything. Free tiers change often and have
daily or monthly limits; check them before you rely on one. Free tiers may
also use your prompts for training, so never paste passwords or keys.

**Agents** (they read and edit your files and run commands; best for this jam):

| tool | how it's free |
|---|---|
| **GitHub Copilot** (VS Code, agent mode) | Copilot Free for everyone; **Copilot Pro free for verified students** through the [GitHub Student Developer Pack](https://education.github.com/pack) |
| **Gemini CLI** | free with a personal Google account (daily request limit) |
| **Aider**, **OpenCode**, **Cline** (open source) | the agent is free; connect it to a free model: a [Google AI Studio](https://aistudio.google.com) key, an [OpenRouter](https://openrouter.ai) model marked `:free`, or a local model |
| **Cursor**, **Windsurf** | free (Hobby) tiers with limited requests; look for student offers |

**Chat** (you copy and paste code in and out): ChatGPT, Claude.ai, Gemini,
Google AI Studio, Mistral Le Chat, DeepSeek, Qwen Chat, Microsoft Copilot:
all have free tiers.

**Local** (no account, no limits, needs a decent GPU or 16+ GB RAM):
[Ollama](https://ollama.com) or [LM Studio](https://lmstudio.ai) with a coding
model such as Qwen-Coder, Devstral or gpt-oss. Small local models struggle with
Odin, which is itself a useful data point.

**Paid** tools like Claude Code, Codex CLI or paid ChatGPT/Claude/Cursor plans
are fine if you already have them. Just log which one you used.

---

## Art and audio (optional)

Rectangles are fine and are never penalized. If you have time left at the
end and want your game to look or sound better, these help.

**Pixel art (free, check each licence).**

- **Kenney** (CC0, no attribution required but still list it) — <https://kenney.nl/assets>.
  Good fits for ARENA: [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon),
  [1-Bit Pack](https://kenney.nl/assets/1-bit-pack),
  [Pixel Shmup](https://kenney.nl/assets/pixel-shmup),
  [Tiny Town](https://kenney.nl/assets/tiny-town).
- **0x72 — DungeonTileset II** (CC0) — <https://0x72.itch.io/dungeontileset-ii>
- **itch.io free pixel-art assets** — <https://itch.io/game-assets/free/tag-pixel-art>
- **OpenGameArt** — <https://opengameart.org> (licences vary; CC-BY means you *must* credit).
- **Palettes** — <https://lospec.com/palette-list>

**Making your own.** [Piskel](https://www.piskelapp.com) (browser),
[LibreSprite](https://libresprite.github.io) (free),
[Pixelorama](https://orama-interactive.itch.io/pixelorama) (free),
[Aseprite](https://www.aseprite.org) (paid, or build it from source).

**Sound.** [jsfxr](https://sfxr.me) and [ChipTone](https://sfbgames.itch.io/chiptone)
generate retro effects in seconds; Kenney has CC0 audio packs;
[freesound.org](https://freesound.org) (licences vary).

**AI-generated assets** are allowed. List the tool and the prompt in
`ATTRIBUTION.md`, and expect to clean them up by hand: generated "pixel art" is
rarely on a real pixel grid.

---

## The data

This jam is also a **measurement** of how people build games with LLMs. That
is why the logging is part of the grade. **You are graded on how complete and
honest your logs are, never on the values.** Using a free model, using no
model, or burning a million tokens all score the same.

### `jam-log.csv` — one row per session

A **session** is one sitting of work: it ends when you take a break of more
than 30 minutes. Fill the row **at the end of the sitting**, not on Sunday
night from memory. The file ships with one example row; replace it with yours.

| column | what goes in it |
|---|---|
| `session` | 1, 2, 3, ... |
| `date` | `2026-09-24` |
| `minutes` | wall-clock minutes of work in the sitting |
| `tool` | `claude-code`, `codex-cli`, `cursor`, `copilot`, `gemini-cli`, `chatgpt-web`, `claude-web`, `ollama`, `none`, ... (semicolon-separate if several) |
| `model` | the exact model name the tool shows, e.g. `claude-sonnet-5`, `gpt-5-mini` (semicolon-separate if several) |
| `tokens_in` / `tokens_out` | from the tool (table below); blank if unavailable |
| `tokens_source` | `ccusage`, `cost-command`, `dashboard`, `cli-summary`, `estimated`, `unavailable` |
| `prompts` | how many prompts or messages you sent (count roughly if you must) |
| `features` | short names of what you worked on, semicolon-separated: `movement;shooting`, `ricochet` |
| `llm_helpfulness` | 1 (got in the way) - 5 (did most of the work well), for this sitting |
| `notes` | one line: the best and the worst moment of the sitting |

### Getting token counts

| tool | where the numbers are |
|---|---|
| Claude Code | `npx ccusage@latest session` reads Claude Code's local logs and prints tokens per session. `/cost` also shows them on API billing. |
| Codex CLI | token usage is printed when the session ends; `/status` during it. |
| Gemini CLI | `/stats` |
| Cursor | Dashboard -> Usage (per request) |
| GitHub Copilot, ChatGPT / Claude web | no per-user token counts: write `unavailable`, and fill `prompts` carefully |
| Ollama / local | `--verbose` prints prompt and eval token counts |

If your tool reports **cache** tokens separately, add them to `tokens_in` and
note that in `tokens_source` (e.g. `ccusage incl. cache`).

### Optional: share your transcripts

If you are willing, put your raw agent transcripts in `transcripts/` (Claude
Code keeps them as `.jsonl` files under `~/.claude/projects/`; other tools can
export chats). **This is optional and ungraded.** Check them for personal
information (names, paths, keys) before committing.

> **Research use.** <!-- INSTRUCTOR: replace with the REB-approved wording before release. -->
> Anonymized, aggregated data from these logs and postmortems may be used in
> research on teaching game development with LLMs, **only for students who
> consent through a separate form**. Consenting or not has no effect on your grade.

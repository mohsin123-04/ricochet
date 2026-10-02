# SQ2 rubric — Mini Game Jam (5 points)

Everything is due **Sun Oct 4, 23:59**, pushed to your repo: the game (tagged
`jam-final`), `POSTMORTEM.md` and `jam-log.csv`. Two parts, following the
course's Side Quest split (about 70% apply + extend, about 30% analysis):

- **The game (3.5 pts)**: graded at the `jam-final` tag.
- **The postmortem and data (1.5 pts)**.

Late policy is the course's: 10% of the Side Quest's value per day or part-day,
up to 72 hours, judged by the time the tag and files were pushed.

**Never graded:** which tool or model you used, how many tokens, how many
sessions, how much of the code the LLM wrote. Using no LLM at all is fine.
**Always graded:** that your logs are complete and honest, and that you can
explain any line you submitted.

---

## A. The game — 3.5 pts

### A1. A complete game (1.0)

| pts | |
|:--:|---|
| 1.0 | You can start it, play it, reach an end (win, lose, or both) and play again without relaunching. No crashes or blocking bugs in a 3-minute play session. |
| 0.5 | Playable, but something is missing or broken: no ending, no replay, or a crash or blocking bug in normal play. |
| 0.0 | Does not run, or cannot be played. |

### A2. How far it travelled from ARENA (1.0)

| pts | |
|:--:|---|
| 1.0 | **Substantial** changes to ARENA (new, changed or removed mechanics, not just added content), and they work. |
| 0.5 | Small changes (one extra enemy, one power-up), or bigger ones that only partly work. |
| 0.0 | Plain ARENA, or the changes don't work. |

### A3. Depth and creativity (1.0)

| pts | |
|:--:|---|
| 1.0 | The game **has depth**: choices with real trade-offs, more than one viable way to play, room for skill. Its changes fit together and can be summed up in one sentence. Original, or an idea from `IDEAS.md` genuinely made your own. |
| 0.5 | Complexity without depth (more stuff, options with no trade-off, one dominant strategy), or a list idea taken unchanged. |
| 0.0 | Cosmetic only (art, sound, juice), or still ARENA's single strategy. |

### A4. Shipping (0.5)

| pts | |
|:--:|---|
| 0.5 | Builds from a clean clone with one command written in your repo's README; `ATTRIBUTION.md` complete if you used any assets; a playable build **shown at the Chapter 6 showcase** on Mon Sep 28 (or, with an excused absence, a 60-second gameplay video in the repo). |
| 0.25 | One of the above missing. |
| 0.0 | Two or more missing. |

---

## B. Postmortem and data — 1.5 pts

### B1. Data (0.5) — completeness, not values

| pts | |
|:--:|---|
| 0.5 | `jam-log.csv` has one row per session, every column filled (or `unavailable` with a reason in `tokens_source`); the front matter of `POSTMORTEM.md` is complete and consistent with the log. |
| 0.25 | Gaps: missing sessions, blank columns, totals that do not match the log. |
| 0.0 | Missing, or clearly reconstructed after the fact with no effort (every row identical, etc.). |

### B2. Analysis (1.0) — your words, with evidence

Every section in `POSTMORTEM.md` is answered. The five that carry the grade:

1. **Where the LLM sped you up**: specific features, with the session or commit they happened in.
2. **Where it did not help**: the hard parts, what you tried, how you got out.
3. **One LLM-introduced bug** you found, fixed and **verified**: before, after, and *how you know* it's fixed (debug draw, printed value, a test, a before/after recording). "It seemed fine after" is not verification.
4. **Pitch vs. delivered**: what changed from your Wednesday pitch, and why.
5. **Pipeline improvements**: what you would change about your workflow, tools, prompts or setup next time, concretely.

| pts | |
|:--:|---|
| 1.0 | All five present, **specific** (features, commits, error messages, numbers), and in your own voice. Honest in both directions, including where the LLM helped. |
| 0.5 | All present but generic ("it was good at boilerplate") or one missing. |
| 0.0 | Two or more missing, or generic throughout. |

---

## Summary

| | pts |
|---|:--:|
| A1 A complete game | 1.0 |
| A2 How far from ARENA | 1.0 |
| A3 Depth and creativity | 1.0 |
| A4 Shipping | 0.5 |
| B1 Data | 0.5 |
| B2 Analysis | 1.0 |
| **Total** | **5.0** |

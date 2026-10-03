# Attribution

No external art or audio assets were used. Everything on screen is drawn with
Raylib primitives (circles, rectangles, lines), and every sound is generated
procedurally in code (the make_sound procedure in main.odin builds a Raylib Wave
from a decaying sine or square tone). There are no asset files to credit.

| asset (file) | source (URL) | author | licence | changes you made |
|---|---|---|---|---|
| none | | | | |

## AI-generated assets

None. The code was written with an LLM (see POSTMORTEM.md and jam-log.csv for that
disclosure), but no images, audio, or other media assets were generated.

| asset (file) | tool + model | prompt (short) | hand edits |
|---|---|---|---|
| none | | | |

## Code

- The Odin standard library and the vendor:raylib binding that ship with the Odin compiler (used via import, not copied into the repo).
- No code was copied or adapted from tutorials, examples, or templates.

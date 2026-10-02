package ricochet

// RICOCHET -- "ARENA, but you only have one bullet: it ricochets, gets stronger
// with every bounce, and once it has bounced it burns you."
//
// Vertical slice (pass 1): player movement, the one bullet (throw / ricochet /
// bounce-power / hot / pick-up), green grunts, health, score, game over + replay.
// Later passes add: recall, pierce combos, purple brutes, orange chargers.

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_W :: 1000
WINDOW_H :: 700
WALL     :: 24.0 // arena inset from the window edge

PLAYER_RADIUS :: 14.0
PLAYER_SPEED  :: 300.0
PLAYER_MAX_HP :: 100

BULLET_RADIUS  :: 9.0
THROW_SPEED    :: 540.0
BOUNCE_SPEEDUP :: 1.08
FRICTION       :: 150.0 // px/s^2 the bullet sheds while flying
MIN_SPEED      :: 90.0  // below this it drops cold to the floor
MAX_POWER      :: 6
RECALL_SPEED   :: 720.0 // right-click: straight back to the hand
COMBO_BASE     :: 100   // first kill in a throw; each further kill is worth more

HOT_DAMAGE   :: 15 // your own bullet burns you
TOUCH_DAMAGE :: 10 // an enemy touches you
IFRAMES      :: 0.8
TOUCH_CD     :: 0.6

GRUNT_RADIUS :: 12.0
GRUNT_SPEED  :: 140.0
GRUNT_HP     :: 1

// arena bounds for the bullet CENTRE (walls inset, minus the bullet radius)
AX0 :: WALL + BULLET_RADIUS
AY0 :: WALL + BULLET_RADIUS
AX1 :: WINDOW_W - WALL - BULLET_RADIUS
AY1 :: WINDOW_H - WALL - BULLET_RADIUS

BulletState :: enum { Held, Flying, Resting, Returning }

Bullet :: struct {
	state:   BulletState,
	pos:     rl.Vector2,
	vel:     rl.Vector2,
	bounces: int,
	power:   int,
	hot:     bool,
	kills:   int, // kills in the current throw -> rising combo value
}

Enemy :: struct {
	pos:   rl.Vector2,
	hp:    int,
	alive: bool,
}

Mode :: enum { Title, Playing, GameOver }

Game :: struct {
	mode:        Mode,
	player:      rl.Vector2,
	hp:          int,
	iframes:     f32, // after a hot-bullet burn
	touch_cd:    f32, // after an enemy touch
	bullet:      Bullet,
	enemies:     [dynamic]Enemy,
	score:       int,
	time:        f32,
	spawn_timer: f32,
}

safe_normalize :: proc(v: rl.Vector2) -> rl.Vector2 {
	if v.x == 0 && v.y == 0 do return {0, 0}
	return linalg.normalize(v)
}

reset :: proc(g: ^Game) {
	clear(&g.enemies)
	g.player = {WINDOW_W / 2, WINDOW_H / 2}
	g.hp = PLAYER_MAX_HP
	g.iframes = 0
	g.touch_cd = 0
	g.score = 0
	g.time = 0
	g.spawn_timer = 1.0
	g.bullet = Bullet {
		state = .Held,
		power = 1,
		pos   = g.player,
	}
}

spawn_grunt :: proc(g: ^Game) {
	pos: rl.Vector2
	switch int(rand.float32() * 4) {
	case 0: pos = {AX0, rand.float32() * (AY1 - AY0) + AY0} // left
	case 1: pos = {AX1, rand.float32() * (AY1 - AY0) + AY0} // right
	case 2: pos = {rand.float32() * (AX1 - AX0) + AX0, AY0} // top
	case:   pos = {rand.float32() * (AX1 - AX0) + AX0, AY1} // bottom
	}
	append(&g.enemies, Enemy{pos = pos, hp = GRUNT_HP, alive = true})
}

update :: proc(g: ^Game, dt: f32) {
	#partial switch g.mode {
	case .Title:
		if rl.IsKeyPressed(.ENTER) || rl.IsMouseButtonPressed(.LEFT) {
			reset(g)
			g.mode = .Playing
		}
		return
	case .GameOver:
		if rl.IsKeyPressed(.R) {
			reset(g)
			g.mode = .Playing
		}
		if rl.IsKeyPressed(.ENTER) do g.mode = .Title
		return
	}

	g.time += dt
	if g.iframes > 0 do g.iframes -= dt
	if g.touch_cd > 0 do g.touch_cd -= dt

	// --- player movement ---
	move: rl.Vector2
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)    do move.y -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)  do move.y += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)  do move.x -= 1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do move.x += 1
	g.player += safe_normalize(move) * PLAYER_SPEED * dt
	g.player.x = clamp(g.player.x, WALL + PLAYER_RADIUS, WINDOW_W - WALL - PLAYER_RADIUS)
	g.player.y = clamp(g.player.y, WALL + PLAYER_RADIUS, WINDOW_H - WALL - PLAYER_RADIUS)

	// right click recalls the bullet straight back to your hand (safe, but you
	// throw away whatever power it had built up)
	b := &g.bullet
	if rl.IsMouseButtonPressed(.RIGHT) && (b.state == .Flying || b.state == .Resting) {
		b.state = .Returning
		b.hot = false
	}

	// --- the bullet ---
	switch b.state {
	case .Held:
		b.pos = g.player
		if rl.IsMouseButtonPressed(.LEFT) {
			dir := safe_normalize(rl.GetMousePosition() - g.player)
			if dir != {0, 0} {
				b.state = .Flying
				b.vel = dir * THROW_SPEED
				b.bounces = 0
				b.power = 1
				b.hot = false
				b.kills = 0
				b.pos = g.player + dir * (PLAYER_RADIUS + BULLET_RADIUS + 2)
			}
		}

	case .Returning:
		// flies straight home, cold and harmless to everyone
		dir := safe_normalize(g.player - b.pos)
		b.pos += dir * RECALL_SPEED * dt
		if linalg.distance(b.pos, g.player) < PLAYER_RADIUS + BULLET_RADIUS {
			b.state = .Held
			b.power = 1
			b.hot = false
			b.kills = 0
		}

	case .Flying:
		b.pos += b.vel * dt

		// ricochet off the four walls; every bounce = +1 power (cap 6), hotter, faster
		bounced := false
		if b.pos.x < AX0 { b.pos.x = AX0; b.vel.x = -b.vel.x; bounced = true }
		if b.pos.x > AX1 { b.pos.x = AX1; b.vel.x = -b.vel.x; bounced = true }
		if b.pos.y < AY0 { b.pos.y = AY0; b.vel.y = -b.vel.y; bounced = true }
		if b.pos.y > AY1 { b.pos.y = AY1; b.vel.y = -b.vel.y; bounced = true }
		if bounced {
			b.bounces += 1
			b.power = min(1 + b.bounces, MAX_POWER)
			b.vel *= BOUNCE_SPEEDUP
			b.hot = true
		}

		// friction: shed speed, and drop cold once slow enough
		speed := linalg.length(b.vel)
		speed -= FRICTION * dt
		if speed <= MIN_SPEED {
			b.state = .Resting
			b.hot = false
			b.vel = {0, 0}
		} else {
			b.vel = safe_normalize(b.vel) * speed
		}

		// a hot bullet burns the player it touches (it keeps flying)
		if b.hot && g.iframes <= 0 &&
		   linalg.distance(b.pos, g.player) < PLAYER_RADIUS + BULLET_RADIUS {
			g.hp -= HOT_DAMAGE
			g.iframes = IFRAMES
		}

	case .Resting:
		// walk over the cold bullet to pick it up; power resets to 1
		if linalg.distance(b.pos, g.player) < PLAYER_RADIUS + BULLET_RADIUS + 4 {
			b.state = .Held
			b.power = 1
			b.hot = false
			b.kills = 0
		}
	}

	// --- enemies ---
	for &e in g.enemies {
		if !e.alive do continue
		e.pos += safe_normalize(g.player - e.pos) * GRUNT_SPEED * dt

		// bullet (flying) hits grunts and pierces through; each kill in the same
		// throw is worth progressively more (combo)
		if b.state == .Flying &&
		   linalg.distance(b.pos, e.pos) < BULLET_RADIUS + GRUNT_RADIUS {
			e.hp -= b.power
			if e.hp <= 0 {
				e.alive = false
				b.kills += 1
				g.score += COMBO_BASE * b.kills
			}
		}

		// enemy touch hurts the player
		if e.alive && g.touch_cd <= 0 &&
		   linalg.distance(e.pos, g.player) < PLAYER_RADIUS + GRUNT_RADIUS {
			g.hp -= TOUCH_DAMAGE
			g.touch_cd = TOUCH_CD
		}
	}

	// sweep out the dead
	for i := len(g.enemies) - 1; i >= 0; i -= 1 {
		if !g.enemies[i].alive do unordered_remove(&g.enemies, i)
	}

	// spawn grunts, a little faster over time
	g.spawn_timer -= dt
	if g.spawn_timer <= 0 {
		spawn_grunt(g)
		g.spawn_timer = max(0.35, 1.5 - g.time * 0.01)
	}

	if g.hp <= 0 {
		g.hp = 0
		g.mode = .GameOver
	}
}

draw :: proc(g: ^Game) {
	rl.ClearBackground(rl.Color{18, 18, 24, 255})

	// arena floor + walls
	rl.DrawRectangle(WALL, WALL, WINDOW_W - 2 * WALL, WINDOW_H - 2 * WALL, rl.Color{30, 30, 40, 255})
	rl.DrawRectangleLinesEx(
		rl.Rectangle{WALL, WALL, WINDOW_W - 2 * WALL, WINDOW_H - 2 * WALL},
		3, rl.Color{70, 70, 95, 255},
	)

	if g.mode == .Title {
		center_text("RICOCHET", 72, WINDOW_H / 2 - 120, rl.RAYWHITE)
		center_text("ARENA, but you only have one bullet.", 22, WINDOW_H / 2 - 30, rl.LIGHTGRAY)
		center_text("WASD move   -   Left click throw   -   Right click recall", 20, WINDOW_H / 2 + 10, rl.GRAY)
		center_text("It bounces off walls: +1 power each bounce. Once bounced, it burns YOU.", 20, WINDOW_H / 2 + 40, rl.GRAY)
		center_text("Each kill in one throw scores more. Recall is safe but resets power.", 20, WINDOW_H / 2 + 70, rl.GRAY)
		center_text("When it stops, walk over it to pick it up.", 20, WINDOW_H / 2 + 100, rl.GRAY)
		center_text("Press ENTER or click to start", 24, WINDOW_H / 2 + 130, rl.YELLOW)
		return
	}

	// enemies (green grunts)
	for e in g.enemies {
		if e.alive do rl.DrawCircleV(e.pos, GRUNT_RADIUS, rl.Color{70, 200, 90, 255})
	}

	// player (flashes while burned)
	pcol := rl.Color{90, 160, 255, 255}
	if g.iframes > 0 && int(g.time * 20) % 2 == 0 do pcol = rl.Color{255, 255, 255, 255}
	rl.DrawCircleV(g.player, PLAYER_RADIUS, pcol)

	// bullet
	b := g.bullet
	switch b.state {
	case .Held:
		rl.DrawCircleV(b.pos, BULLET_RADIUS, rl.Color{200, 200, 210, 255})
	case .Flying:
		col := b.hot ? hot_color(b.power) : rl.Color{240, 230, 120, 255}
		rl.DrawCircleV(b.pos, BULLET_RADIUS, col)
		if b.kills > 0 {
			center_text_at(fmt.ctprintf("x%d", b.kills), 22, i32(b.pos.x), i32(b.pos.y) - 30, rl.YELLOW)
		}
	case .Returning:
		// a tether back to the hand so the recall reads clearly
		rl.DrawLineEx(b.pos, g.player, 2, rl.Color{90, 200, 230, 120})
		rl.DrawCircleV(b.pos, BULLET_RADIUS, rl.Color{90, 210, 240, 255})
	case .Resting:
		rl.DrawCircleV(b.pos, BULLET_RADIUS, rl.Color{120, 120, 130, 255})
		rl.DrawCircleLinesV(b.pos, BULLET_RADIUS + 3, rl.Color{90, 90, 100, 255})
	}

	draw_hud(g)

	if g.mode == .GameOver {
		rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, rl.Color{0, 0, 0, 170})
		center_text("YOU DIED", 64, WINDOW_H / 2 - 90, rl.Color{255, 90, 90, 255})
		center_text(fmt.ctprintf("Score: %d    Survived: %.0fs", g.score, g.time), 28, WINDOW_H / 2, rl.RAYWHITE)
		center_text("Press R to play again   -   ENTER for title", 22, WINDOW_H / 2 + 60, rl.YELLOW)
	}
}

draw_hud :: proc(g: ^Game) {
	// health bar
	rl.DrawRectangle(WALL + 6, WALL + 6, 204, 22, rl.Color{50, 20, 20, 255})
	w := i32(200.0 * f32(g.hp) / f32(PLAYER_MAX_HP))
	rl.DrawRectangle(WALL + 8, WALL + 8, w, 18, rl.Color{220, 70, 70, 255})
	rl.DrawText(fmt.ctprintf("HP %d", g.hp), WALL + 14, WALL + 9, 16, rl.RAYWHITE)

	rl.DrawText(fmt.ctprintf("SCORE %d", g.score), WINDOW_W / 2 - 60, WALL + 8, 22, rl.RAYWHITE)
	rl.DrawText(fmt.ctprintf("%.0fs", g.time), WINDOW_W - WALL - 70, WALL + 8, 22, rl.LIGHTGRAY)

	// bullet readout
	b := g.bullet
	label: cstring
	col: rl.Color
	switch b.state {
	case .Held:      label = "BULLET: in hand";   col = rl.Color{200, 200, 210, 255}
	case .Flying:    label = b.hot ? fmt.ctprintf("BULLET: HOT  power %d", b.power) : "BULLET: flying (cold)"; col = b.hot ? rl.Color{255, 140, 60, 255} : rl.Color{240, 230, 120, 255}
	case .Returning: label = "BULLET: returning"; col = rl.Color{90, 210, 240, 255}
	case .Resting:   label = "BULLET: on the floor (walk over it)"; col = rl.Color{150, 150, 160, 255}
	}
	rl.DrawText(label, WALL + 8, WINDOW_H - WALL - 26, 20, col)
}

hot_color :: proc(power: int) -> rl.Color {
	// yellow-orange at low power to red-hot at max
	t := f32(power - 1) / f32(MAX_POWER - 1)
	return rl.Color{255, u8(200 - 140 * t), u8(60 - 60 * t), 255}
}

center_text :: proc(text: cstring, size, y: i32, col: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, WINDOW_W / 2 - w / 2, y, size, col)
}

center_text_at :: proc(text: cstring, size, cx, y: i32, col: rl.Color) {
	w := rl.MeasureText(text, size)
	rl.DrawText(text, cx - w / 2, y, size, col)
}

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "RICOCHET")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	g: Game
	g.enemies = make([dynamic]Enemy)
	defer delete(g.enemies)
	g.mode = .Title

	for !rl.WindowShouldClose() {
		update(&g, rl.GetFrameTime())
		rl.BeginDrawing()
		draw(&g)
		rl.EndDrawing()
		free_all(context.temp_allocator) // ctprintf strings live here
	}
}

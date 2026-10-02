package ricochet

// RICOCHET -- "ARENA, but you only have one bullet: it ricochets, gets stronger
// with every bounce, and once it has bounced it burns you."
//
// Full game: the one-bullet throw/ricochet/bounce-power/hot/recall/pick-up loop,
// rising pierce combos, three enemy kinds (grunt / brute / charger), a 2-minute
// survival win, lose + replay, and juice (screen shake, hit flash, procedural sound).

import "core:fmt"
import "core:math"
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

HOT_DAMAGE :: 15  // your own bullet burns you
IFRAMES    :: 0.8 // invulnerability window after any hit (see touch_damage for per-enemy touch damage)

GRUNT_RADIUS :: 12.0
GRUNT_SPEED  :: 140.0
GRUNT_HP     :: 1

// purple brute: slow and tanky, arrives ~20s. Needs a power-3 (twice-bounced) hit to one-shot.
BRUTE_RADIUS :: 18.0
BRUTE_SPEED  :: 70.0
BRUTE_HP     :: 3
BRUTE_AFTER  :: 20.0

// orange charger: arrives ~40s. Winds up, flashes a red line, then dashes along it.
CHARGER_RADIUS :: 14.0
CHARGER_SPEED  :: 120.0 // normal chase
CHARGER_HP     :: 2
CHARGER_AFTER  :: 40.0
DASH_SPEED     :: 760.0
TELEGRAPH_TIME :: 0.9
DASH_TIME      :: 0.35
DAZED_TIME     :: 1.2
CHASE_TIME     :: 1.6 // max chase before it commits to a dash

HIT_CD :: 0.18 // per-enemy debounce so one bullet pass = one hit of `power`

WIN_TIME    :: 120.0 // survive two minutes to win
SHAKE_DECAY :: 42.0  // px/s the screen shake bleeds off
SHAKE_MAX   :: 14.0
FLASH_TIME  :: 0.45  // red hurt-flash fade

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

EnemyKind    :: enum { Grunt, Brute, Charger }
ChargerState :: enum { Chase, Telegraph, Dash, Dazed }

Enemy :: struct {
	kind:   EnemyKind,
	pos:    rl.Vector2,
	hp:     int,
	radius: f32,
	speed:  f32,
	alive:  bool,
	hit_cd: f32, // debounce for bullet damage
	// charger only
	cstate:   ChargerState,
	timer:    f32,
	dash_dir: rl.Vector2,
}

Mode :: enum { Title, Playing, GameOver, Win }

Sounds :: struct {
	throw, bounce, kill, hurt, pickup, win, lose: rl.Sound,
}

Game :: struct {
	mode:        Mode,
	player:      rl.Vector2,
	hp:          int,
	iframes:     f32, // invulnerability window after any hit
	shake:       f32, // current screen-shake intensity (px)
	flash:       f32, // red hurt-flash timer
	snd:         Sounds,
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

// build a short sound from scratch (no external assets): a decaying sine or
// square tone. raylib copies the samples, so the temp buffer is freed after.
make_sound :: proc(freq, dur, vol: f32, square: bool) -> rl.Sound {
	SR :: 22050
	n := int(f32(SR) * dur)
	samples := make([]i16, n)
	defer delete(samples)
	for i in 0 ..< n {
		t := f32(i) / f32(SR)
		env := 1.0 - t / dur // linear fade to silence
		phase := freq * t
		s: f32
		if square {
			s = math.mod(phase, 1.0) < 0.5 ? 1.0 : -1.0
		} else {
			s = math.sin(phase * 2 * math.PI)
		}
		samples[i] = i16(s * env * vol * 32767)
	}
	w := rl.Wave {
		frameCount = u32(n),
		sampleRate = SR,
		sampleSize = 16,
		channels   = 1,
		data       = rawptr(raw_data(samples)),
	}
	return rl.LoadSoundFromWave(w)
}

add_shake :: proc(g: ^Game, amount: f32) {
	g.shake = min(SHAKE_MAX, g.shake + amount)
}

// one place for "the player got hit": damage + i-frames + flash + shake + sound
hurt_player :: proc(g: ^Game, dmg: int) {
	if g.iframes > 0 do return
	g.hp -= dmg
	g.iframes = IFRAMES
	g.flash = FLASH_TIME
	add_shake(g, 9)
	rl.PlaySound(g.snd.hurt)
}

reset :: proc(g: ^Game) {
	clear(&g.enemies)
	g.player = {WINDOW_W / 2, WINDOW_H / 2}
	g.hp = PLAYER_MAX_HP
	g.iframes = 0
	g.shake = 0
	g.flash = 0
	g.score = 0
	g.time = 0
	g.spawn_timer = 1.0
	g.bullet = Bullet {
		state = .Held,
		power = 1,
		pos   = g.player,
	}
}

edge_spawn_pos :: proc() -> rl.Vector2 {
	switch int(rand.float32() * 4) {
	case 0: return {AX0, rand.float32() * (AY1 - AY0) + AY0} // left
	case 1: return {AX1, rand.float32() * (AY1 - AY0) + AY0} // right
	case 2: return {rand.float32() * (AX1 - AX0) + AX0, AY0} // top
	case:   return {rand.float32() * (AX1 - AX0) + AX0, AY1} // bottom
	}
}

spawn_enemy :: proc(g: ^Game) {
	// pick a kind based on how long the run has lasted
	kind := EnemyKind.Grunt
	r := rand.float32()
	if g.time >= CHARGER_AFTER && r < 0.22 {
		kind = .Charger
	} else if g.time >= BRUTE_AFTER && r < 0.5 {
		kind = .Brute
	}

	e := Enemy{kind = kind, pos = edge_spawn_pos(), alive = true}
	switch kind {
	case .Grunt:
		e.hp = GRUNT_HP;   e.radius = GRUNT_RADIUS;   e.speed = GRUNT_SPEED
	case .Brute:
		e.hp = BRUTE_HP;   e.radius = BRUTE_RADIUS;   e.speed = BRUTE_SPEED
	case .Charger:
		e.hp = CHARGER_HP; e.radius = CHARGER_RADIUS; e.speed = CHARGER_SPEED
		e.cstate = .Chase; e.timer = CHASE_TIME
	}
	append(&g.enemies, e)
}

touch_damage :: proc(e: Enemy) -> int {
	switch e.kind {
	case .Grunt:   return 10
	case .Brute:   return 14
	case .Charger: return e.cstate == .Dash ? 20 : 10
	}
	return 10
}

// per-kind movement / AI for one enemy
update_enemy_move :: proc(g: ^Game, e: ^Enemy, dt: f32) {
	switch e.kind {
	case .Grunt, .Brute:
		e.pos += safe_normalize(g.player - e.pos) * e.speed * dt

	case .Charger:
		switch e.cstate {
		case .Chase:
			e.pos += safe_normalize(g.player - e.pos) * e.speed * dt
			e.timer -= dt
			// commit to a dash once close enough or after chasing a while
			if linalg.distance(e.pos, g.player) < 300 || e.timer <= 0 {
				e.cstate = .Telegraph
				e.timer = TELEGRAPH_TIME
				e.dash_dir = safe_normalize(g.player - e.pos) // lock the aim now
			}
		case .Telegraph:
			// stands still, winding up; the red line is drawn in draw()
			e.timer -= dt
			if e.timer <= 0 {
				e.cstate = .Dash
				e.timer = DASH_TIME
			}
		case .Dash:
			e.pos += e.dash_dir * DASH_SPEED * dt
			// keep it inside the arena
			e.pos.x = clamp(e.pos.x, WALL + e.radius, WINDOW_W - WALL - e.radius)
			e.pos.y = clamp(e.pos.y, WALL + e.radius, WINDOW_H - WALL - e.radius)
			e.timer -= dt
			if e.timer <= 0 {
				e.cstate = .Dazed
				e.timer = DAZED_TIME
			}
		case .Dazed:
			// stands still, wide open to a hit
			e.timer -= dt
			if e.timer <= 0 {
				e.cstate = .Chase
				e.timer = CHASE_TIME
			}
		}
	}
}

update :: proc(g: ^Game, dt: f32) {
	#partial switch g.mode {
	case .Title:
		if rl.IsKeyPressed(.ENTER) || rl.IsMouseButtonPressed(.LEFT) {
			reset(g)
			g.mode = .Playing
		}
		return
	case .GameOver, .Win:
		if rl.IsKeyPressed(.R) {
			reset(g)
			g.mode = .Playing
		}
		if rl.IsKeyPressed(.ENTER) do g.mode = .Title
		return
	}

	g.time += dt
	if g.iframes > 0 do g.iframes -= dt
	if g.flash > 0 do g.flash -= dt
	if g.shake > 0 do g.shake = max(0, g.shake - SHAKE_DECAY * dt)

	// survive the clock to win
	if g.time >= WIN_TIME {
		g.mode = .Win
		rl.PlaySound(g.snd.win)
		return
	}

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
				rl.PlaySound(g.snd.throw)
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
			rl.PlaySound(g.snd.pickup)
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
			rl.SetSoundPitch(g.snd.bounce, 1.0 + f32(b.bounces) * 0.12)
			rl.PlaySound(g.snd.bounce)
			add_shake(g, 1.5 + f32(b.power))
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
			hurt_player(g, HOT_DAMAGE)
		}

	case .Resting:
		// walk over the cold bullet to pick it up; power resets to 1
		if linalg.distance(b.pos, g.player) < PLAYER_RADIUS + BULLET_RADIUS + 4 {
			b.state = .Held
			b.power = 1
			b.hot = false
			b.kills = 0
			rl.PlaySound(g.snd.pickup)
		}
	}

	// --- enemies ---
	for &e in g.enemies {
		if !e.alive do continue
		if e.hit_cd > 0 do e.hit_cd -= dt

		update_enemy_move(g, &e, dt)

		// bullet (flying) hits enemies and pierces through. The per-enemy debounce
		// means one pass applies `power` once, so a brute (3 HP) needs a power-3
		// (twice-bounced) hit to die in a single pass. Each kill in the throw scores more.
		if b.state == .Flying && e.hit_cd <= 0 &&
		   linalg.distance(b.pos, e.pos) < BULLET_RADIUS + e.radius {
			e.hp -= b.power
			e.hit_cd = HIT_CD
			if e.hp <= 0 {
				e.alive = false
				b.kills += 1
				g.score += COMBO_BASE * b.kills
				rl.SetSoundPitch(g.snd.kill, 1.0 + f32(b.kills) * 0.08)
				rl.PlaySound(g.snd.kill)
				add_shake(g, 3)
			}
		}

		// enemy touch hurts the player (a charger's dash hits harder)
		if e.alive && g.iframes <= 0 &&
		   linalg.distance(e.pos, g.player) < PLAYER_RADIUS + e.radius {
			hurt_player(g, touch_damage(e))
		}
	}

	// sweep out the dead
	for i := len(g.enemies) - 1; i >= 0; i -= 1 {
		if !g.enemies[i].alive do unordered_remove(&g.enemies, i)
	}

	// spawn grunts, a little faster over time
	g.spawn_timer -= dt
	if g.spawn_timer <= 0 {
		spawn_enemy(g)
		g.spawn_timer = max(0.35, 1.5 - g.time * 0.01)
	}

	if g.hp <= 0 {
		g.hp = 0
		g.mode = .GameOver
		add_shake(g, SHAKE_MAX)
		rl.PlaySound(g.snd.lose)
	}
}

draw :: proc(g: ^Game) {
	rl.ClearBackground(rl.Color{18, 18, 24, 255})

	if g.mode == .Title {
		draw_arena()
		center_text("RICOCHET", 72, WINDOW_H / 2 - 120, rl.RAYWHITE)
		center_text("ARENA, but you only have one bullet.", 22, WINDOW_H / 2 - 30, rl.LIGHTGRAY)
		center_text("WASD move   -   Left click throw   -   Right click recall", 20, WINDOW_H / 2 + 10, rl.GRAY)
		center_text("It bounces off walls: +1 power each bounce. Once bounced, it burns YOU.", 20, WINDOW_H / 2 + 40, rl.GRAY)
		center_text("Each kill in one throw scores more. Recall is safe but resets power.", 20, WINDOW_H / 2 + 70, rl.GRAY)
		center_text("Survive 2 minutes to win.", 20, WINDOW_H / 2 + 100, rl.GRAY)
		center_text("Press ENTER or click to start", 24, WINDOW_H / 2 + 135, rl.YELLOW)
		return
	}

	// --- world, drawn through a shaking camera ---
	cam := rl.Camera2D{zoom = 1}
	if g.shake > 0 {
		cam.offset = {(rand.float32() * 2 - 1) * g.shake, (rand.float32() * 2 - 1) * g.shake}
	}
	rl.BeginMode2D(cam)
	draw_arena()

	for e in g.enemies {
		if e.alive do draw_enemy(g, e)
	}

	// player (flashes white during i-frames)
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
	rl.EndMode2D()

	// red flash when the player is hurt (screen space, over the world)
	if g.flash > 0 {
		a := u8(130 * g.flash / FLASH_TIME)
		rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, rl.Color{200, 30, 30, a})
	}

	draw_hud(g)

	if g.mode == .GameOver {
		rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, rl.Color{0, 0, 0, 170})
		center_text("YOU DIED", 64, WINDOW_H / 2 - 90, rl.Color{255, 90, 90, 255})
		center_text(fmt.ctprintf("Score: %d    Survived: %.0fs", g.score, g.time), 28, WINDOW_H / 2, rl.RAYWHITE)
		center_text("Press R to play again   -   ENTER for title", 22, WINDOW_H / 2 + 60, rl.YELLOW)
	}
	if g.mode == .Win {
		rl.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, rl.Color{0, 0, 0, 170})
		center_text("YOU SURVIVED", 64, WINDOW_H / 2 - 90, rl.Color{120, 230, 140, 255})
		center_text(fmt.ctprintf("Final score: %d", g.score), 28, WINDOW_H / 2, rl.RAYWHITE)
		center_text("Press R to play again   -   ENTER for title", 22, WINDOW_H / 2 + 60, rl.YELLOW)
	}
}

draw_arena :: proc() {
	rl.DrawRectangle(WALL, WALL, WINDOW_W - 2 * WALL, WINDOW_H - 2 * WALL, rl.Color{30, 30, 40, 255})
	rl.DrawRectangleLinesEx(
		rl.Rectangle{WALL, WALL, WINDOW_W - 2 * WALL, WINDOW_H - 2 * WALL},
		3, rl.Color{70, 70, 95, 255},
	)
}

draw_enemy :: proc(g: ^Game, e: Enemy) {
	switch e.kind {
	case .Grunt:
		rl.DrawCircleV(e.pos, e.radius, rl.Color{70, 200, 90, 255})

	case .Brute:
		rl.DrawCircleV(e.pos, e.radius, rl.Color{170, 90, 220, 255})
		// hp pips so the player can read how many hits are left
		for i in 0 ..< e.hp {
			rl.DrawCircleV({e.pos.x - 10 + f32(i) * 10, e.pos.y - e.radius - 8}, 3, rl.RAYWHITE)
		}

	case .Charger:
		col := rl.Color{240, 150, 40, 255}
		switch e.cstate {
		case .Telegraph:
			// flash + a red aim line showing where it will dash
			if int(g.time * 16) % 2 == 0 do col = rl.RAYWHITE
			end := e.pos + e.dash_dir * 900
			rl.DrawLineEx(e.pos, end, 3, rl.Color{255, 60, 60, 200})
		case .Dash:
			col = rl.Color{255, 200, 90, 255}
		case .Dazed:
			col = rl.Color{150, 110, 70, 255} // dimmed: wide open
		case .Chase:
		}
		rl.DrawCircleV(e.pos, e.radius, col)
		if e.cstate == .Dazed {
			rl.DrawCircleLinesV(e.pos, e.radius + 4, rl.Color{255, 255, 255, 120})
		}
	}

	// white flash the instant it's struck (brute survivors read as "I hit it")
	if e.hit_cd > HIT_CD * 0.55 {
		rl.DrawCircleV(e.pos, e.radius, rl.Color{255, 255, 255, 150})
	}
}

draw_hud :: proc(g: ^Game) {
	// health bar
	rl.DrawRectangle(WALL + 6, WALL + 6, 204, 22, rl.Color{50, 20, 20, 255})
	w := i32(200.0 * f32(g.hp) / f32(PLAYER_MAX_HP))
	rl.DrawRectangle(WALL + 8, WALL + 8, w, 18, rl.Color{220, 70, 70, 255})
	rl.DrawText(fmt.ctprintf("HP %d", g.hp), WALL + 14, WALL + 9, 16, rl.RAYWHITE)

	rl.DrawText(fmt.ctprintf("SCORE %d", g.score), WINDOW_W / 2 - 60, WALL + 8, 22, rl.RAYWHITE)

	// countdown to the survival win (mm:ss), turns red in the final 10s
	left := max(0, WIN_TIME - g.time)
	tcol := left <= 10 ? rl.Color{255, 90, 90, 255} : rl.LIGHTGRAY
	rl.DrawText(fmt.ctprintf("%d:%02d", int(left) / 60, int(left) % 60), WINDOW_W - WALL - 76, WALL + 8, 22, tcol)

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

load_sounds :: proc() -> Sounds {
	s: Sounds
	s.throw  = make_sound(440, 0.10, 0.4, true)  // quick blip
	s.bounce = make_sound(600, 0.07, 0.35, true) // click (pitch-shifted per bounce)
	s.kill   = make_sound(320, 0.12, 0.45, true) // pop
	s.hurt   = make_sound(110, 0.22, 0.5, false) // low buzz
	s.pickup = make_sound(760, 0.09, 0.3, false) // soft chime
	s.win    = make_sound(680, 0.55, 0.4, false) // bright tone
	s.lose   = make_sound(90, 0.55, 0.5, false)  // low tone
	return s
}

unload_sounds :: proc(s: Sounds) {
	rl.UnloadSound(s.throw);  rl.UnloadSound(s.bounce); rl.UnloadSound(s.kill)
	rl.UnloadSound(s.hurt);   rl.UnloadSound(s.pickup); rl.UnloadSound(s.win)
	rl.UnloadSound(s.lose)
}

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "RICOCHET")
	defer rl.CloseWindow()
	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()
	rl.SetTargetFPS(60)

	g: Game
	g.enemies = make([dynamic]Enemy)
	defer delete(g.enemies)
	g.snd = load_sounds()
	defer unload_sounds(g.snd)
	g.mode = .Title

	for !rl.WindowShouldClose() {
		update(&g, rl.GetFrameTime())
		rl.BeginDrawing()
		draw(&g)
		rl.EndDrawing()
		free_all(context.temp_allocator) // ctprintf strings live here
	}
}

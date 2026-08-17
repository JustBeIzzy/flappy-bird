extends Node

@export var pipe_scene : PackedScene
@export var coin_scene : PackedScene
@export var powerup_scene : PackedScene
@export var bubble_scene : PackedScene
@export var wasp_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll
var score
var coins : int
var lives : int
var scroll_speed : float
#speed tiers as % of 10 px/frame: 20%, 25%, 40%, 65%, 80%, one step every 25 pipes passed
const SPEED_TIERS := [2.0, 2.5, 4.0, 6.5, 8.0]
const SPEED_TIER_PIPES : int = 25
const PIPE_SPACING_PX : float = 320.0
var screen_size : Vector2i
var ground_height : int
var pipes : Array
var powerups : Array
var bubbles : Array
var wasps : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200
const POWERUP_X_OFFSET : int = 300
const MAX_LIVES : int = 3
var level : int
var pipes_moving : bool
const DIGIT_SCALE : float = 2.0

#gameplay difficulty stage (1/2/3), separate from the day/night visual "level" above
var stage : int
const STAGE2_SCORE : int = 25
const STAGE3_SCORE : int = 50
#tighter pipe spacing as stage rises (denser obstacle fields)
const STAGE_SPACING_FACTOR := {1: 1.0, 2: 0.7, 3: 0.5}
const BUBBLE_EVERY : int = 8
const WASP_CHANCE : float = 0.5

var bird_trapped : bool = false
var trapped_bubble : Node = null
var bubble_taps_remaining : int = 0
const BUBBLE_TAPS : int = 3
const TRAP_FLOAT_SPEED : float = 3.0
const TRAP_FLOAT_AMPLITUDE : float = 8.0
var trap_base_bird_y : float
var trap_base_bubble_y : float

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$BgMusic.finished.connect($BgMusic.play)
	AudioManager.register_music_player($BgMusic)
	update_mute_button()
	new_game()

func update_mute_button():
	$MuteButton.text = "Unmute" if AudioManager.is_music_muted() else "Mute"

func _on_mute_button_pressed():
	AudioManager.toggle_music_mute()
	update_mute_button()

func new_game():
	#reset variables
	game_running = false
	game_over = false
	score = 0
	coins = 0
	lives = MAX_LIVES
	scroll = 0
	level = 1
	stage = 1
	pipes_moving = false
	bird_trapped = false
	trapped_bubble = null
	bubble_taps_remaining = 0
	update_speed()
	$Background.modulate = Color.WHITE
	update_score_display()
	$CoinLabel.text = "COINS: " + str(coins)
	$GameOver.hide()
	$PauseMenu.hide()
	$GetReadyLabel.modulate.a = 1.0
	$GetReadyLabel.show()
	$TapIndicator.modulate.a = 1.0
	$TapIndicator.show()
	$LevelLabel.hide()
	get_tree().paused = false
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	get_tree().call_group("powerups", "queue_free")
	powerups.clear()
	get_tree().call_group("bubbles", "queue_free")
	bubbles.clear()
	get_tree().call_group("wasps", "queue_free")
	wasps.clear()
	#generate starting pipes
	generate_pipes()
	$Bird.reset()
	update_hearts()
	$BgMusic.play()

func _unhandled_input(event):
	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				elif bird_trapped:
					pop_bubble_tap()
				else:
					if $Bird.flying:
						$Bird.flap()
						check_top()

const TAP_HINT_FADE_TIME : float = 1.0

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	#start pipe timer
	$PipeTimer.start()
	show_level_label(stage)
	#fade out the "get ready" / "tap" hint together, then hide it
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property($GetReadyLabel, "modulate:a", 0.0, TAP_HINT_FADE_TIME)
	tween.tween_property($TapIndicator, "modulate:a", 0.0, TAP_HINT_FADE_TIME)
	tween.chain().tween_callback(func():
		$GetReadyLabel.hide()
		$TapIndicator.hide()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#ground keeps scrolling before the first tap too, freezes on game over or while bubble-trapped
	if not game_over and not bird_trapped:
		scroll += scroll_speed
		#reset scroll
		if scroll >= screen_size.x:
			scroll = 0
		#move ground node
		$Ground.position.x = -scroll
	if game_running and not bird_trapped:
		#move pipes
		for pipe in pipes:
			pipe.position.x -= scroll_speed
		#move power-ups (float on their own, x-scroll owned here)
		for powerup in powerups:
			powerup.position.x -= scroll_speed
		for bubble in bubbles:
			bubble.position.x -= scroll_speed
		cleanup_offscreen()
	if bird_trapped and trapped_bubble:
		#gentle synced bob so the trapped bird+bubble reads as floating, not frozen
		var offset = sin(Time.get_ticks_msec() / 1000.0 * TRAP_FLOAT_SPEED) * TRAP_FLOAT_AMPLITUDE
		$Bird.position.y = trap_base_bird_y + offset
		trapped_bubble.position.y = trap_base_bubble_y + offset


#pipes/powerups/bubbles never got freed once they scrolled off-screen, so a
#long endless-run session kept piling up nodes (each still running its own
#bob/spin _process) forever. Sweep anything that's fully off the left edge.
const OFFSCREEN_X : float = -150.0

func cleanup_offscreen():
	for pipe in pipes.duplicate():
		if pipe.position.x < OFFSCREEN_X:
			pipes.erase(pipe)
			pipe.queue_free()
	for powerup in powerups.duplicate():
		if powerup.position.x < OFFSCREEN_X:
			powerups.erase(powerup)
			powerup.queue_free()
	for bubble in bubbles.duplicate():
		if bubble.position.x < OFFSCREEN_X:
			bubbles.erase(bubble)
			bubble.queue_free()

func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) / 2  + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.moving = pipes_moving
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)

	#coin floats in the middle of the gap
	var coin = coin_scene.instantiate()
	coin.collected.connect(coin_collected)
	pipe.add_child(coin)

	#stage 3: wasp sometimes crosses through the gap, then chases the bird down
	if stage >= 3 and randf() < WASP_CHANCE:
		spawn_wasp(pipe.position)

func spawn_wasp(from_position: Vector2):
	var wasp = wasp_scene.instantiate()
	wasp.position = from_position + Vector2(0, randf_range(-50, 50))
	wasp.target = $Bird
	wasp.hit.connect(bird_hit)
	add_child(wasp)
	wasps.append(wasp)

func spawn_bubble():
	var bubble = bubble_scene.instantiate()
	bubble.position.x = screen_size.x + PIPE_DELAY
	var margin = 150
	bubble.position.y = randi_range(margin, screen_size.y - ground_height - margin)
	bubble.target = $Bird
	bubble.trapped.connect(bubble_trapped)
	add_child(bubble)
	bubbles.append(bubble)

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	powerup.position.x = screen_size.x + PIPE_DELAY + POWERUP_X_OFFSET
	#anchor to the most recent pipe's actual gap center, so it always lands
	#in open air the bird can reach instead of a random (possibly blocked) height
	if pipes.size() > 0:
		powerup.position.y = pipes[-1].position.y
	else:
		powerup.position.y = (screen_size.y - ground_height) / 2
	powerup.collected.connect(powerup_collected)
	add_child(powerup)
	powerups.append(powerup)

func scored():
	score += 1
	update_score_display()
	update_level()
	update_stage()
	update_speed()
	#shrink power-up unlocks every 10 pipes passed
	if score % 10 == 0:
		spawn_powerup()
	#pipes start bobbing vertically after 15 pipes passed (applies to newly spawned pipes)
	if score >= 15:
		pipes_moving = true
	#bubble obstacle unlocks from stage 2 onward
	if stage >= 2 and score % BUBBLE_EVERY == 0:
		spawn_bubble()

func update_stage():
	#gameplay difficulty: 1 (warmup) -> 2 (bubble trap) -> 25 more pipes -> 3 (endless run)
	var new_stage = 1
	if score >= STAGE3_SCORE:
		new_stage = 3
	elif score >= STAGE2_SCORE:
		new_stage = 2
	if new_stage == stage:
		return
	stage = new_stage
	show_level_label(stage)

const LEVEL_LABEL_HOLD_TIME : float = 1.5
const LEVEL_LABEL_FADE_TIME : float = 1.0

func show_level_label(n: int):
	$LevelLabel.text = "Level %d" % n
	$LevelLabel.modulate.a = 1.0
	$LevelLabel.show()
	var tween := create_tween()
	tween.tween_interval(LEVEL_LABEL_HOLD_TIME)
	tween.tween_property($LevelLabel, "modulate:a", 0.0, LEVEL_LABEL_FADE_TIME)
	tween.tween_callback($LevelLabel.hide)

#floor so jitter/stage factors can never shrink spacing below pipe width,
#which was spawning overlapping, unpassable pipe columns at stage 3
const MIN_PIPE_SPACING_PX : float = 200.0

func update_speed():
	var tier = mini(score / SPEED_TIER_PIPES, SPEED_TIERS.size() - 1)
	scroll_speed = SPEED_TIERS[tier]
	#keep pixel gap between pipes constant regardless of current speed, denser at higher stages
	var spacing = PIPE_SPACING_PX * STAGE_SPACING_FACTOR.get(stage, 1.0)
	if stage == 3:
		#randomized jitter reads as clustered 3-5 pipe runs instead of a fixed grid
		spacing *= randf_range(0.6, 1.15)
	spacing = max(spacing, MIN_PIPE_SPACING_PX)
	$PipeTimer.wait_time = spacing / (scroll_speed * 60.0)

func update_score_display():
	for child in $ScoreDisplay.get_children():
		child.queue_free()
	for digit in str(score):
		var tex := load("res://assets/num_%s.png" % digit)
		var tex_rect := TextureRect.new()
		tex_rect.texture = tex
		#size each digit from its own native size so narrower glyphs (e.g. "1")
		#don't get stretched to match the others
		tex_rect.custom_minimum_size = tex.get_size() * DIGIT_SCALE
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		$ScoreDisplay.add_child(tex_rect)

func coin_collected():
	$SfxPoint.play()
	coins += 1
	$CoinLabel.text = "COINS: " + str(coins)

func powerup_collected(powerup):
	powerups.erase(powerup)
	$SfxShrink.play()
	$Bird.shrink()

func bubble_trapped(bubble):
	if bird_trapped or game_over:
		return
	bird_trapped = true
	trapped_bubble = bubble
	bubble_taps_remaining = BUBBLE_TAPS
	bubble.show_trapped($Bird.color)
	trap_base_bird_y = $Bird.position.y
	trap_base_bubble_y = bubble.position.y
	$Bird.trap()

func pop_bubble_tap():
	bubble_taps_remaining -= 1
	$Bird.struggle()
	if trapped_bubble:
		trapped_bubble.shake()
	if bubble_taps_remaining <= 0:
		release_bubble()

func release_bubble():
	bubbles.erase(trapped_bubble)
	if trapped_bubble:
		trapped_bubble.pop()
	trapped_bubble = null
	bird_trapped = false
	$Bird.untrap()
	$Bird.start_invulnerability()

const LEVEL_FADE_TIME : float = 2.0
const LEVEL_PIPES : int = 15

func update_level():
	#cycles day -> sunset -> night -> day ..., one step every 15 pipes passed
	var new_level = (score / LEVEL_PIPES) % 3 + 1
	if new_level == level:
		return
	level = new_level
	var target_color := Color.WHITE
	match level:
		1:
			target_color = Color.WHITE
		2:
			target_color = Color(1.0, 0.7, 0.5) # sunset tint
		3:
			target_color = Color(0.25, 0.28, 0.45) # night tint
	var tween := create_tween()
	tween.tween_property($Background, "modulate", target_color, LEVEL_FADE_TIME)

func check_top():
	if $Bird.position.y < 0:
		$SfxDie.play()
		$Bird.falling = true
		stop_game()

func stop_game():
	$PipeTimer.stop()
	$BgMusic.stop()
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	if $Bird.invulnerable or game_over or bird_trapped:
		return
	$SfxHit.play()
	$Bird.cancel_shrink()
	lives -= 1
	update_hearts()
	if lives <= 0:
		$SfxDie.play()
		$Bird.falling = true
		stop_game()
	else:
		$Bird.start_invulnerability()

func update_hearts():
	var heart_tex = load("res://assets/%s_bird2.png" % $Bird.color)
	for i in range(MAX_LIVES):
		var heart = $Hearts.get_child(i)
		heart.texture = heart_tex
		heart.visible = i < lives

func _on_ground_hit():
	#already landed and showing game over - ignore any repeat ground signals
	if $GameOver.visible:
		return
	$Bird.falling = false
	if not game_over:
		stop_game()
	$GameOver.show_game_over()

func _on_game_over_restart():
	new_game()

func _on_pause_button_pressed():
	if game_running and not game_over:
		get_tree().paused = true
		$PauseMenu.show()

func _on_resume_button_pressed():
	get_tree().paused = false
	$PauseMenu.hide()

func _on_pause_menu_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

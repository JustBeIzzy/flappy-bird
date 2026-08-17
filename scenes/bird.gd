extends CharacterBody2D

const GRAVITY : int = 1000
const MAX_VEL : int = 600
const FLAP_SPEED : int = -500
var flying : bool = false
var falling : bool = false
const START_POS = Vector2(100, 400)

var invulnerable : bool = false
const INVULN_TIME := 1.5
const SHRINK_SCALE := 0.7
const SHRINK_TIME := 15.0
const COLORS := ["red", "blue"]
var color := ""
var trapped : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()

func reset():
	falling = false
	flying = false
	invulnerable = false
	trapped = false
	show()
	position = START_POS
	set_rotation(0)
	scale = Vector2.ONE
	modulate = Color.WHITE
	color = COLORS.pick_random()
	$AnimatedSprite2D.animation = color

	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if trapped:
		return
	if invulnerable:
		# blink while invulnerable so the hit is readable
		modulate.a = 0.4 if int(Time.get_ticks_msec() / 100) % 2 == 0 else 1.0
	if flying or falling:
		velocity.y += GRAVITY * delta
		#terminal velocity
		if velocity.y > MAX_VEL:
			velocity.y = MAX_VEL
		if flying:
			set_rotation(deg_to_rad(velocity.y * 0.05))
			$AnimatedSprite2D.play()
		elif falling:
			set_rotation(PI/2)
			$AnimatedSprite2D.stop()
		move_and_collide(velocity * delta)
	else:
		$AnimatedSprite2D.stop()

func flap():
	$WingSound.play()
	velocity.y = FLAP_SPEED

func trap():
	trapped = true
	velocity = Vector2.ZERO
	hide()

func untrap():
	trapped = false
	show()

func struggle():
	$WingSound.play()

func start_invulnerability():
	invulnerable = true
	get_tree().create_timer(INVULN_TIME).timeout.connect(_end_invulnerability)

func _end_invulnerability():
	invulnerable = false
	modulate.a = 1.0

func shrink():
	scale = Vector2(SHRINK_SCALE, SHRINK_SCALE)
	get_tree().create_timer(SHRINK_TIME).timeout.connect(_end_shrink)

func _end_shrink():
	scale = Vector2.ONE

func cancel_shrink():
	scale = Vector2.ONE

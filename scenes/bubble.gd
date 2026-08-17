extends Area2D

signal trapped

const FLOAT_SPEED := 30.0
const FLOAT_RANGE := 40.0
const HOMING_SPEED := 18.0
const SHAKE_AMOUNT := 10.0
const SHAKE_TIME := 0.07

var target : Node = null
var base_y : float
var float_dir : int = 1
var was_hit : bool = false

func _ready():
	base_y = position.y

func _process(delta):
	if was_hit:
		return
	#drift the bob-center toward the bird's current height, so the bubble
	#slowly homes in on the bird while it keeps floating up and down
	if target:
		base_y = move_toward(base_y, target.position.y, HOMING_SPEED * delta)
	position.y += FLOAT_SPEED * float_dir * delta
	if position.y > base_y + FLOAT_RANGE:
		float_dir = -1
	elif position.y < base_y - FLOAT_RANGE:
		float_dir = 1

func _on_body_entered(_body):
	if was_hit:
		return
	was_hit = true
	trapped.emit(self)

func show_trapped(bird_color: String):
	$Sprite2D.texture = load("res://assets/%s_bird_bubble.png" % bird_color)

func shake():
	var sprite := $Sprite2D
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", -SHAKE_AMOUNT, SHAKE_TIME)
	tween.tween_property(sprite, "position:x", SHAKE_AMOUNT, SHAKE_TIME)
	tween.tween_property(sprite, "position:x", 0.0, SHAKE_TIME)

func pop():
	queue_free()

extends Area2D

signal hit
signal scored

const V_SPEED := 40.0
const V_RANGE := 60.0

var moving : bool = false
var base_y : float
var v_dir : int = 1
var was_hit : bool = false

func _ready():
	base_y = position.y

func _process(delta):
	# ping-pong vertical bob, horizontal scroll stays owned by main.gd
	if not moving:
		return
	position.y += V_SPEED * v_dir * delta
	if position.y > base_y + V_RANGE:
		v_dir = -1
	elif position.y < base_y - V_RANGE:
		v_dir = 1

func _on_body_entered(body):
	#pipe has 4 separate collision shapes; only signal the first touch
	if was_hit:
		return
	was_hit = true
	hit.emit()

func _on_score_area_body_entered(body):
	if was_hit:
		return
	scored.emit()

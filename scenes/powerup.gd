extends Area2D

signal collected

const FLOAT_SPEED := 30.0
const FLOAT_RANGE := 40.0

var base_y : float
var float_dir : int = 1

func _ready():
	base_y = position.y

func _process(delta):
	position.y += FLOAT_SPEED * float_dir * delta
	if position.y > base_y + FLOAT_RANGE:
		float_dir = -1
	elif position.y < base_y - FLOAT_RANGE:
		float_dir = 1

func _on_body_entered(_body):
	collected.emit(self)
	queue_free()

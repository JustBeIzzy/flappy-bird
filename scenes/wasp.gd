extends Area2D

signal hit

#medium chase speed - noticeably faster than the bubble's lazy drift,
#but slower than top pipe scroll speed so it stays dodgeable
const HOMING_SPEED := 160.0

var target : Node = null
var was_hit : bool = false

func _process(delta):
	if was_hit or target == null:
		return
	position = position.move_toward(target.position, HOMING_SPEED * delta)

func _on_body_entered(_body):
	if was_hit:
		return
	was_hit = true
	hit.emit()
	queue_free()

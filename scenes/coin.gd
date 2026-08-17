extends Area2D

signal collected

func _on_body_entered(_body):
	collected.emit()
	queue_free()

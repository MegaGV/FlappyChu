extends Node2D

class_name Pipe

var speed := 200.0
var entered := false

func _process(delta):
    position.x -= speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()

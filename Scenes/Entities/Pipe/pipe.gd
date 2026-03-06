extends Node2D

var speed = 200

func _process(delta):
    position.x -= speed * delta
    
    # 当管道完全离开屏幕后删除
    if position.x < -100:
        queue_free()

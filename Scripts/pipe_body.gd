extends StaticBody2D

# 获取管道体的高度
func get_height():
    return $Sprite2D.texture.get_height() * $Sprite2D.scale.y

# 获取管道体的宽度
func get_width():
    return $Sprite2D.texture.get_width() * $Sprite2D.scale.x

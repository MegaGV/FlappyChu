extends StaticBody2D

# 是否为顶部管道的标志
var is_top = false

func _ready():
    # 如果是顶部管道，翻转精灵
    if is_top:
        $Sprite2D.flip_v = true

# 获取管道顶部的高度
func get_height():
    return $Sprite2D.texture.get_height() * $Sprite2D.scale.y

# 获取管道顶部的宽度
func get_width():
    return $Sprite2D.texture.get_width() * $Sprite2D.scale.x

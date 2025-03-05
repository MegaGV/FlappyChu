# Ground.gd
extends Node2D

var speed = 200
var ground_width
var screen_width

func _ready():
    screen_width = get_viewport_rect().size.x
    ground_width = $Sprite2D.texture.get_width()
    
    # 创建足够多的地面精灵以覆盖屏幕
    var num_sprites = ceil(screen_width / ground_width) + 1
    for i in range(1, num_sprites):
        var new_sprite = $Sprite2D.duplicate()
        new_sprite.position.x = ground_width * i
        add_child(new_sprite)
    
func _process(delta):
    # 移动所有地面精灵
    for sprite in get_children():
        if sprite is  Sprite2D:
            sprite.position.x -= speed * delta
            
            # 如果地面精灵完全移出屏幕左侧，则移到最右侧
            if sprite.position.x < -ground_width:
                # 找到最右边的精灵
                var rightmost_x = -INF
                for s in get_children():
                    rightmost_x = max(rightmost_x, s.position.x)
                sprite.position.x = rightmost_x + ground_width

# Bird.gd
extends CharacterBody2D

signal game_over

var gravity = 1000
var jump_force = -400
var rotation_speed = 3
var is_game_started = false
var is_game_over = false

func _ready():
    velocity = Vector2.ZERO
    
func _physics_process(delta):
    if not is_game_started:
        return
        
    # 应用重力 (即使游戏结束也继续应用重力)
    velocity.y += gravity * delta
    
    # 根据速度调整旋转
    rotation = move_toward(rotation, velocity.y * 0.0005, rotation_speed * delta)
    
    # 移动角色 (即使游戏结束也继续移动)
    move_and_slide()
    
    # 只在游戏未结束时检测碰撞
    if not is_game_over:
        for i in get_slide_collision_count():
            var collision = get_slide_collision(i)
            if collision:
                emit_signal("game_over")
                is_game_over = true
                # 游戏结束后增加下落速度，让鸟更快地掉落
                velocity.y = 300
                $CollisionShape2D.disabled = true
                break

func jump():
    if is_game_over:
        return
        
    if not is_game_started:
        is_game_started = true
        
    velocity.y = jump_force
    rotation = -0.5  # 向上旋转

func _input(event):
    # 处理鼠标点击
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            jump()
    # 处理触摸屏幕
    elif event is InputEventScreenTouch:
        if event.pressed:
            jump()

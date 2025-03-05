extends Node2D

var speed = 200

@onready var bottom_pipe: StaticBody2D = $BottomPipe
@onready var top_pipe: StaticBody2D = $TopPipe

var setComplete = false

func _ready():
    pass

func _process(delta):
    position.x -= speed * delta
    
    # 当管道完全离开屏幕后删除
    if position.x < -100:
        queue_free()

func setup(gap_y, gap_height, screen_height):
    if setComplete:
        return
    
    var top_cap = top_pipe.get_node("Cap")
    var bottom_cap = bottom_pipe.get_node("Cap")
    
    # 设置管道位置
    var gap_top = gap_y - gap_height/2
    var gap_bottom = gap_y + gap_height/2
    
    top_pipe.position.y = gap_top
    bottom_pipe.position.y = gap_bottom
    
    # 处理顶部管道体 - 使用多个精灵而不是拉伸
    create_pipe_body(top_pipe, top_cap, true, screen_height)
    
    # 处理底部管道体 - 使用多个精灵而不是拉伸
    create_pipe_body(bottom_pipe, bottom_cap, false, screen_height)
    
    # 设置碰撞形状
    update_collision_shape(top_pipe, true, screen_height)
    update_collision_shape(bottom_pipe, false, screen_height)
    
    setComplete = true

# 创建管道体 - 使用多个精灵
func create_pipe_body(pipe, cap, is_top, screen_height):
    # 首先清除任何现有的管道体精灵（除了初始的一个）
    var initial_body = pipe.get_node("Body")
    
    # 删除任何之前创建的额外管道体
    for child in pipe.get_children():
        if child.name.begins_with("Body_") and child is Sprite2D:
            child.queue_free()
    
    # 获取管道体精灵的尺寸
    var body_height = initial_body.texture.get_height()
    var body_width = initial_body.texture.get_width()
    
    # 计算需要多少个管道体精灵
    var pipe_length
    if is_top:
        # 顶部管道：从管道顶部到屏幕顶部的距离
        pipe_length = pipe.position.y
    else:
        # 底部管道：从管道顶部到屏幕底部的距离
        pipe_length = screen_height - pipe.position.y - cap.texture.get_height()
    
    # 如果长度为负或太小，不创建管道体
    if pipe_length <= 0:
        initial_body.visible = false
        return
    
    # 计算需要的管道体数量
    var num_bodies = ceil(pipe_length / body_height)
    
    # 设置初始管道体的位置
    if is_top:
        # 顶部管道：第一个管道体紧贴管道顶部的顶部
        initial_body.position.y = -cap.texture.get_height() - body_height/2
    else:
        # 底部管道：第一个管道体紧贴管道顶部的底部
        initial_body.position.y = cap.texture.get_height() + body_height/2
    
    initial_body.visible = true
    
    # 创建额外的管道体精灵
    for i in range(1, num_bodies):
        var new_body = initial_body.duplicate()
        new_body.name = "Body_" + str(i)
        
        if is_top:
            # 顶部管道：向上堆叠
            new_body.position.y = initial_body.position.y - body_height * i
        else:
            # 底部管道：向下堆叠
            new_body.position.y = initial_body.position.y + body_height * i
        
        pipe.add_child(new_body)

# 更新碰撞形状
func update_collision_shape(pipe, is_top, screen_height):
    var collision = pipe.get_node("CollisionShape2D")
    var cap = pipe.get_node("Cap")
    
    if collision.shape is RectangleShape2D:
        var pipe_length
        var collision_center_y
        
        if is_top:
            # 顶部管道：从管道顶部到屏幕顶部的距离
            pipe_length = pipe.position.y
            # 碰撞区域中心位置：管道顶部上方一半距离
            collision_center_y = -pipe_length/2
        else:
            # 底部管道：从管道顶部到屏幕底部的距离
            pipe_length = screen_height - pipe.position.y - cap.texture.get_height()
            # 碰撞区域中心位置：管道顶部下方一半距离
            collision_center_y = cap.texture.get_height() + pipe_length/2
        
        # 设置碰撞区域大小和位置
        var total_height = pipe_length + cap.texture.get_height()
        collision.shape.extents = Vector2(cap.texture.get_width()/2, total_height/2)
        collision.position.y = collision_center_y

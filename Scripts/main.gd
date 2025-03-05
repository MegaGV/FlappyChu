extends Node2D

var pipe_scene = preload("res://Scenes/Pipe.tscn")
var pipe_cap_scene = preload("res://Scenes/PipeCap.tscn")
var pipe_body_scene = preload("res://Scenes/PipeBody.tscn")

var pipe_spawn_time = 1.5
var pipe_timer = 0
var score = 0
var game_started = false
var game_over = false

@onready var bird: CharacterBody2D = $Bird
@onready var game_over_screen: Control = $GameOverScreen


func _ready():
    bird.game_over.connect(_on_game_over)
    game_over_screen.visible = false
    $ScoreLabel.text = "Score: 0"

func _process(delta):
    if not game_started:
        if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            start_game()
        return
        
    if game_over:
        return
        
    # 生成管道
    pipe_timer += delta
    if pipe_timer >= pipe_spawn_time:
        spawn_pipe()
        pipe_timer = 0
        
func start_game():
    game_started = true
    bird.is_game_started = true
    $StartLabel.visible = false
    $AudioStreamPlayer2D.play()
    
func spawn_pipe():
    var pipe = pipe_scene.instantiate()
    var screen_size = get_viewport_rect().size
    
    # 确定间隙位置和大小
    var gap_y = randf_range(screen_size.y * 0.3, screen_size.y * 0.7)
    var gap_height = 200  # 调整空隙大小
    
    # 设置管道初始位置
    pipe.position.x = screen_size.x + 100
    
    # 先将管道添加到场景树
    $Pipes.add_child(pipe)
    
    # 创建顶部管道
    create_top_pipe(pipe, gap_y - gap_height/2, screen_size)
    
    # 创建底部管道
    create_bottom_pipe(pipe, gap_y + gap_height/2, screen_size)
    
    # 添加分数区域
    add_score_area(pipe, screen_size.y)

# 创建顶部管道
func create_top_pipe(pipe, gap_top, screen_size):
    var top_pipes = pipe.get_node("TopPipes")
    
    var body_height = 16  # 假设管道体高度为32像素，根据实际资源调整
    
    # 创建管道顶部
    var cap = pipe_cap_scene.instantiate()
    cap.is_top = true  # 设置为顶部管道
    cap.position.y = gap_top - body_height / 2
    top_pipes.add_child(cap)
    
    # 计算需要多少个管道体来填充到屏幕顶部
    var distance_to_top = gap_top
    var num_bodies = ceil(distance_to_top / body_height)
    
    # 创建管道体
    for i in range(num_bodies):
        var body = pipe_body_scene.instantiate()
        body.position.y = gap_top - cap.get_height() - body_height * (i + 0.5)
        top_pipes.add_child(body)

# 创建底部管道
func create_bottom_pipe(pipe, gap_bottom, screen_size):
    var bottom_pipes = pipe.get_node("BottomPipes")
    
    var body_height = 16  # 假设管道体高度为32像素，根据实际资源调整
    
    # 创建管道顶部
    var cap = pipe_cap_scene.instantiate()
    cap.position.y = gap_bottom + body_height / 2
    bottom_pipes.add_child(cap)
    
    # 计算需要多少个管道体来填充到屏幕底部
    var distance_to_bottom = screen_size.y - gap_bottom - cap.get_height()
    var num_bodies = ceil(distance_to_bottom / body_height)
    
    # 创建管道体
    for i in range(num_bodies):
        var body = pipe_body_scene.instantiate()
        body.position.y = gap_bottom + cap.get_height() + body_height * (i + 0.5)
        bottom_pipes.add_child(body)

# 添加分数区域
func add_score_area(pipe, screen_height):
    var score_area = Area2D.new()
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    
    shape.extents = Vector2(2, screen_height)
    collision.shape = shape
    score_area.add_child(collision)
    score_area.position.x = 50  # 放在管道前面一点
    score_area.body_entered.connect(_on_score_area_body_entered)
    pipe.add_child(score_area)

func _on_score_area_body_entered(body):
    if body.name == "Bird" and not game_over:
        score += 1
        $ScoreLabel.text = "Score: " + str(score)
        
func _on_game_over():
    game_over = true
    game_over_screen.visible = true
    game_over_screen.get_node("ScoreValue").text = "Your Score is: " + str(score)
    $AudioStreamPlayer2D/AnimationPlayer.play("fade_out")
    
func _on_restart_button_pressed():
    # 重新加载场景
    get_tree().reload_current_scene()

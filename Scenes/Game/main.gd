extends Node2D

var pipe_scene = preload("res://Scenes/Entities/Pipe/Pipe.tscn")
var pipe_cap_scene = preload("res://Scenes/Entities/Pipe/PipeCap.tscn")
var pipe_body_scene = preload("res://Scenes/Entities/Pipe/PipeBody.tscn")


var pipe_timer = 0
var current_score = 0
var current_level := 0
var game_started = false
var game_over = false
var high_score = 0
const SAVE_FILE_PATH = "user://highscore.save"

# 基础难度参数
var base_spawn_time := 1.5
var base_gap_height := 200.0
var base_speed := 200.0

# 当前难度参数
var pipe_spawn_time = 1.5
var gap_height = 200
var speed = 200

# 难度曲线参数（可调整）
var score_thresholds := [5, 15, 30, 50]  # 分数里程碑
var spawn_time_reductions := [0.2, 0.15, 0.1, 0.05]  # 每次减少的秒数
var gap_height_reductions := [15, 10, 8, 5]  # 每次减少的像素
var speed_increases := [20, 15, 10, 5]  # 每次增加的速度

# 最低限制（确保游戏有解）
const MIN_SPAWN_TIME := 0.8
const MIN_GAP_HEIGHT := 120.0  # 30(玩家) * 3 + 余量
const MAX_SPEED := 300.0

@onready var bird: CharacterBody2D = $Bird
@onready var game_over_screen: Control = $GameOverScreen
@onready var difficulty_label: Label = $DifficultyLabel


func _ready():
    load_high_score()
    bird.game_over.connect(_on_game_over)
    game_over_screen.visible = false
    $ScoreLabel.text = "Score: 0"

func load_high_score():
    if FileAccess.file_exists(SAVE_FILE_PATH):
        var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
        high_score = file.get_32()
        file.close()

func save_high_score():
    var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
    file.store_32(high_score)
    file.close()

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
    
    # 设置管道初始位置
    pipe.position.x = screen_size.x + 100
    
    # 设置管道速度
    pipe.speed = speed
    
    # 先将管道添加到场景树
    $Pipes.add_child(pipe)
    
    # 创建顶部管道
    create_pipe_segment(pipe, gap_y - gap_height/2, screen_size, true)
    
    # 创建底部管道
    create_pipe_segment(pipe, gap_y + gap_height/2, screen_size, false)
    
    # 添加分数区域
    add_score_area(pipe, screen_size.y)

# 创建管道
func create_pipe_segment(pipe, gap_position: float, screen_size: Vector2, is_top: bool):
    var pipes_node = pipe.get_node("TopPipes") if is_top else pipe.get_node("BottomPipes")
    var body_height = 16  # 管道体高度
    
    # 创建管道帽
    var cap = pipe_cap_scene.instantiate()
    if is_top:
        cap.is_top = true  # 顶部管道特有属性
        cap.position.y = gap_position - body_height / 2
    else:
        cap.position.y = gap_position + body_height / 2
    pipes_node.add_child(cap)
    
    # 计算需要的管道体数量
    var distance: float
    if is_top:
        distance = gap_position  # 到屏幕顶部的距离
    else:
        distance = screen_size.y - gap_position - cap.get_height()  # 到屏幕底部的距离
    
    var num_bodies = ceil(distance / body_height)
    
    # 创建管道体
    for i in range(num_bodies):
        var body = pipe_body_scene.instantiate()
        if is_top:
            body.position.y = gap_position - cap.get_height() - body_height * (i + 0.5)
        else:
            body.position.y = gap_position + cap.get_height() + body_height * (i + 0.5)
        pipes_node.add_child(body)

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
        current_score += 1
        $ScoreLabel.text = "Score: " + str(current_score)
        update_difficulty()
        
func _on_game_over():
    game_over = true
    
    # 更新并保存最高分
    if current_score > high_score:
        high_score = current_score
        save_high_score()
        
    game_over_screen.visible = true
    game_over_screen.get_node("ScoreValue").text = "Your Score is: " + str(current_score)
    game_over_screen.get_node("HighScoreValue").text = "High Score: " + str(high_score)
    $AudioStreamPlayer2D/AnimationPlayer.play("fade_out")
    
func _on_restart_button_pressed():
    # 重新加载场景
    get_tree().reload_current_scene()

func update_difficulty():
    # 检查是否达到新的难度等级
    var new_level = 0
    for threshold in score_thresholds:
        if current_score >= threshold:
            new_level += 1
    
    if new_level != current_level:
        current_level = new_level
        _apply_difficulty()

func _apply_difficulty():
    # 计算新参数（确保不低于最小值）
    var new_spawn_time = base_spawn_time
    var new_gap_height = base_gap_height
    var new_speed = base_speed
    
    for i in range(current_level):
        new_spawn_time -= spawn_time_reductions[i] if i < spawn_time_reductions.size() else 0
        new_gap_height -= gap_height_reductions[i] if i < gap_height_reductions.size() else 0
        new_speed += speed_increases[i] if i < speed_increases.size() else 0
    
    # 应用限制
    pipe_spawn_time = max(new_spawn_time, MIN_SPAWN_TIME)
    gap_height = max(new_gap_height, MIN_GAP_HEIGHT)
    speed = min(new_speed, MAX_SPEED)
    
    for pipe in $Pipes.get_children():
        pipe.speed = speed
    
    $Ground.speed = speed
    $Ground2.speed = speed
    
    print("当前分数 ", current_score,
          " 难度提升至Lv", current_level+1, 
          " 参数: 间隔", pipe_spawn_time, 
          "s 间隙", gap_height, 
          "px 速度", speed)
          
    show_difficulty_up_effect()

func show_difficulty_up_effect():
    difficulty_label.text = "LEVEL UP!\nSpeed: " + str(speed)
    
    # 创建Tween动画
    var tween = create_tween()
    
    # 初始状态
    difficulty_label.modulate.a = 0
    difficulty_label.scale = Vector2(0.5, 0.5)
    difficulty_label.position.y = 200
    
    # 动画序列
    tween.set_parallel(true)
    tween.tween_property(difficulty_label, "modulate:a", 1.0, 0.3)
    tween.tween_property(difficulty_label, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BOUNCE)
    tween.tween_property(difficulty_label, "position:y", 150.0, 0.5).set_ease(Tween.EASE_OUT)
    
    tween.chain().tween_property(difficulty_label, "scale", Vector2(1.0, 1.0), 0.2)
    
    # 停留一会后淡出
    tween.chain().tween_interval(1.0)
    tween.chain().tween_property(difficulty_label, "modulate:a", 0.0, 0.5)

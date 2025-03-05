# Main.gd
extends Node2D

var pipe_scene = preload("res://Scenes/Pipe.tscn")
var pipe_spawn_time = 1.5
var pipe_timer = 0
var score = 0
var game_started = false
var game_over = false

func _ready():
    $Bird.game_over.connect(_on_game_over)
    $GameOver.visible = false
    
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
    $StartLabel.visible = false
    $Bird.is_game_started = true
    

func spawn_pipe():
    var pipe = pipe_scene.instantiate()
    var screen_height = get_viewport_rect().size.y
    var gap_y = randf_range(screen_height * 0.3, screen_height * 0.7)
    var gap_height = 200  # 调整空隙大小
    
    pipe.position.x = get_viewport_rect().size.x + 100
    
    # 先将管道添加到场景树
    $Pipes.add_child(pipe)
    
    # 然后再调用setup方法
    pipe.setup(gap_y, gap_height, screen_height)
    
    # 添加分数区域
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
    $ScoreLabel.visible = false
    $GameOver.visible = true
    $GameOver/ScoreValue.text = "Your Score is : " + str(score)
    
func _on_restart_button_pressed():
    # 重新加载场景
    get_tree().reload_current_scene()

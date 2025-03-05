# GameOver.gd
extends Control

func _ready():
    $RestartButton.pressed.connect(_on_restart_button_pressed)
    
func _on_restart_button_pressed():
    # 发送信号给Main场景
    get_parent()._on_restart_button_pressed()

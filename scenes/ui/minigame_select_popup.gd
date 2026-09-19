extends Control

@onready var block_blast_button: Button = $Panel/VBoxContainer/BlockBlastButton
@onready var brick_breaker_button: Button = $Panel/VBoxContainer/BrickBreakerButton
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton


func _ready() -> void:
	block_blast_button.pressed.connect(_on_block_blast)
	brick_breaker_button.pressed.connect(_on_brick_breaker)
	cancel_button.pressed.connect(queue_free)


func _on_block_blast() -> void:
	GameManager.launch_minigame("block_blast")
	queue_free()


func _on_brick_breaker() -> void:
	GameManager.launch_minigame("brick_breaker")
	queue_free()

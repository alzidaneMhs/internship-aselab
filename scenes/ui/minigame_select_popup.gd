extends Control

## "BTG" - pick a minigame to free the defeated boss from human manipulation.
## Difficulty follows the player's reputation.

signal selected(kind: String)
signal cancelled

@onready var mode_label: Label = $Panel/VBoxContainer/ModeLabel
@onready var block_blast_button: Button = $Panel/VBoxContainer/BlockBlastButton
@onready var snake_button: Button = $Panel/VBoxContainer/SnakeButton
@onready var brick_breaker_button: Button = $Panel/VBoxContainer/BrickBreakerButton
@onready var cancel_button: Button = $Panel/VBoxContainer/CancelButton


func _ready() -> void:
	var mode_text := {
		"kind": "Mode: Baik Hati (mudah)",
		"normal": "Mode: Seimbang (normal)",
		"hardcore": "Mode: Genosida (hardcore)",
	}
	mode_label.text = "%s  |  Reputasi %d  (makin banyak membunuh, makin sulit)" % [mode_text[GameState.get_minigame_difficulty()], GameState.reputation]
	block_blast_button.pressed.connect(_pick.bind("block_blast"))
	snake_button.pressed.connect(_pick.bind("snake"))
	brick_breaker_button.pressed.connect(_pick.bind("brick_breaker"))
	cancel_button.pressed.connect(_cancel)
	block_blast_button.grab_focus()


func _pick(kind: String) -> void:
	selected.emit(kind)
	queue_free()


func _cancel() -> void:
	cancelled.emit()
	queue_free()

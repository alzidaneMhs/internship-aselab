extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/HBoxContainer/HPBar
@onready var points_label: Label = $MarginContainer/HBoxContainer/PointsLabel


func _ready() -> void:
	GameState.points_changed.connect(_on_points_changed)
	_on_points_changed(GameState.points)

	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var health: Node = player.get_node("Health")
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)


func _on_points_changed(total: int) -> void:
	points_label.text = "Points: %d" % total


func _on_health_changed(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current

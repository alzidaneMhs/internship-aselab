extends CanvasLayer

# Untyped: these panels are custom scripts with their own methods.
@onready var player_panel = $PlayerPanel
@onready var boss_bar = $BossBar
@onready var toast_label: Label = $ToastLabel

var _boss: Node
var _player: Node2D
var _toast_queue: Array[String] = []
var _toast_busy := false


func _ready() -> void:
	GameState.points_changed.connect(_on_points_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.items_changed.connect(_on_items_changed)
	GameState.toast_requested.connect(_on_toast)
	_on_points_changed(GameState.points)
	_on_reputation_changed(GameState.reputation)
	_on_items_changed()
	toast_label.modulate.a = 0.0

	_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		var health: Node = _player.get_node("Health")
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)

	boss_bar.modulate.a = 0.0
	boss_bar.visible = false
	_boss = get_tree().get_first_node_in_group("boss")
	if _boss != null:
		boss_bar.set("boss_name", str(_boss.get("boss_name")))


func _process(delta: float) -> void:
	var show_bar := false
	if _boss != null and is_instance_valid(_boss) and _player != null:
		var in_range: bool = _boss.global_position.distance_to(_player.global_position) < float(_boss.get("detection_range"))
		show_bar = in_range and not bool(_boss.get("_defeated")) and not bool(_boss.get("dormant"))
		if show_bar:
			var boss_health: Node = _boss.get_node("Health")
			boss_bar.update_state(
				boss_health.current_health, boss_health.max_health,
				float(_boss.get("shield")), float(_boss.get("shield_max")),
				float(_boss.get("stun_remaining")), float(_boss.get("stun_duration")))
	var target_alpha := 1.0 if show_bar else 0.0
	boss_bar.modulate.a = move_toward(boss_bar.modulate.a, target_alpha, delta * 3.0)
	boss_bar.visible = boss_bar.modulate.a > 0.01


func _on_points_changed(total: int) -> void:
	player_panel.set_vonic(total)


func _on_reputation_changed(value: int) -> void:
	player_panel.set_reputation(value, GameState.get_reputation_title(), GameState.get_minigame_difficulty())


func _on_items_changed() -> void:
	player_panel.set_items(GameState.items)


func _on_health_changed(current: float, max_hp: float) -> void:
	player_panel.set_health(current, max_hp)


func _on_toast(message: String) -> void:
	_toast_queue.append(message)
	if not _toast_busy:
		_run_toasts()


func _run_toasts() -> void:
	_toast_busy = true
	while not _toast_queue.is_empty():
		toast_label.text = _toast_queue.pop_front()
		toast_label.modulate.a = 0.0
		toast_label.position.y += 12.0
		var tw_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
		tw_in.tween_property(toast_label, "modulate:a", 1.0, 0.2)
		tw_in.tween_property(toast_label, "position:y", toast_label.position.y - 12.0, 0.2)
		await get_tree().create_timer(2.6, true).timeout
		if not is_inside_tree():
			return
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)
		await tw.finished
		if not is_inside_tree():
			return
	_toast_busy = false

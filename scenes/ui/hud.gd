extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPRow/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPRow/HPLabel
@onready var vonic_label: Label = $MarginContainer/VBoxContainer/StatRow/VonicLabel
@onready var rep_label: Label = $MarginContainer/VBoxContainer/StatRow/RepLabel
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/VBoxContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $BossPanel/VBoxContainer/BossHPBar
@onready var boss_shield_bar: ProgressBar = $BossPanel/VBoxContainer/BossShieldBar
@onready var toast_label: Label = $ToastLabel

var _boss: Node
var _player: Node2D
var _toast_queue: Array[String] = []
var _toast_busy := false


func _ready() -> void:
	GameState.points_changed.connect(_on_points_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.toast_requested.connect(_on_toast)
	_on_points_changed(GameState.points)
	_on_reputation_changed(GameState.reputation)
	toast_label.modulate.a = 0.0

	_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		var health: Node = _player.get_node("Health")
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)

	boss_panel.visible = false
	_boss = get_tree().get_first_node_in_group("boss")
	if _boss != null:
		boss_name_label.text = str(_boss.get("boss_name"))
		var boss_health: Node = _boss.get_node("Health")
		boss_health.health_changed.connect(_on_boss_health_changed)
		_on_boss_health_changed(boss_health.current_health, boss_health.max_health)
		_boss.connect("shield_changed", _on_boss_shield_changed)
		boss_shield_bar.visible = _boss.has_method("modify_incoming_damage")


func _process(_delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss) or _player == null:
		boss_panel.visible = false
		return
	var in_range: bool = _boss.global_position.distance_to(_player.global_position) < float(_boss.get("detection_range"))
	boss_panel.visible = in_range and not bool(_boss.get("_defeated"))


func _on_points_changed(total: int) -> void:
	vonic_label.text = "Vonic: %d" % total


func _on_reputation_changed(value: int) -> void:
	rep_label.text = "Reputasi: %d (%s)" % [value, GameState.get_reputation_title()]


func _on_health_changed(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = "%d / %d" % [roundi(current), roundi(max_hp)]


func _on_boss_health_changed(current: float, max_hp: float) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = current


func _on_boss_shield_changed(current: float, max_value: float) -> void:
	boss_shield_bar.max_value = max_value
	boss_shield_bar.value = current


func _on_toast(message: String) -> void:
	_toast_queue.append(message)
	if not _toast_busy:
		_run_toasts()


func _run_toasts() -> void:
	_toast_busy = true
	while not _toast_queue.is_empty():
		toast_label.text = _toast_queue.pop_front()
		toast_label.modulate.a = 1.0
		await get_tree().create_timer(2.4, true).timeout
		if not is_inside_tree():
			return
		var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)
		await tw.finished
		if not is_inside_tree():
			return
	_toast_busy = false

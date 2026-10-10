extends "res://scenes/enemies/enemy_base.gd"

## Shared boss flow: fight -> defeated (drops Vonic + item choice) -> player
## interacts to play a "BTG" minigame -> freed (+1 reputation) -> safe zone unlocks.

signal defeated
signal freed
signal shield_changed(current: float, max_value: float)

const ITEM_CHOICE_UI := preload("res://scenes/ui/item_choice_ui.tscn")
const MINIGAME_POPUP := preload("res://scenes/ui/minigame_select_popup.tscn")

@export var boss_id: String = ""
@export var boss_name: String = "Boss"
@export var drop_vonic: int = 27
@export var arena_left: float = -100000.0
@export var arena_right: float = 100000.0

@onready var prompt: Label = $Prompt
@onready var interact_area: Area2D = $InteractArea

var _defeated := false
var _freeable := false
var _freed := false
var _busy := false
var _player_near := false


func _init() -> void:
	add_to_group("boss")


func _ready() -> void:
	super._ready()
	prompt.text = "Tekan E untuk membebaskan %s" % boss_name
	prompt.visible = false
	interact_area.body_entered.connect(_on_interact_body_entered)
	interact_area.body_exited.connect(_on_interact_body_exited)
	if GameState.is_boss_freed(boss_id):
		queue_free()
		return
	if GameState.is_boss_defeated(boss_id):
		# Player died after beating the boss but before freeing it: no second drop.
		_enter_defeated()
		_freeable = true


func _physics_process(delta: float) -> void:
	if _defeated:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0.0
		move_and_slide()
		return
	super._physics_process(delta)
	global_position.x = clampf(global_position.x, arena_left, arena_right)


func _on_died() -> void:
	if _defeated:
		return
	GameState.mark_boss_defeated(boss_id)
	GameState.add_points(drop_vonic)
	GameState.toast("%s dikalahkan! +%d Vonic" % [boss_name, drop_vonic])
	_enter_defeated()
	await get_tree().create_timer(1.2).timeout
	_offer_item_choice()


## Hook for subclasses: stop timers/attacks.
func _on_defeated_state() -> void:
	pass


func _enter_defeated() -> void:
	_defeated = true
	velocity = Vector2.ZERO
	hurtbox.set_deferred("monitorable", false)
	sprite.modulate = Color(0.55, 0.55, 0.62)
	_on_defeated_state()
	defeated.emit()
	_refresh_prompt()


func _offer_item_choice() -> void:
	var choices := GameState.get_random_item_choices(3)
	if choices.is_empty():
		_freeable = true
		_refresh_prompt()
		return
	var ui: Control = ITEM_CHOICE_UI.instantiate()
	ui.call("setup", choices)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(ui)
	get_tree().current_scene.add_child(layer)
	ui.connect("chosen", _on_item_chosen.bind(layer))
	get_tree().paused = true


func _on_item_chosen(id: String, layer: CanvasLayer) -> void:
	GameState.acquire_item(id)
	get_tree().paused = false
	layer.queue_free()
	_freeable = true
	_refresh_prompt()


func _refresh_prompt() -> void:
	prompt.visible = _defeated and _freeable and not _freed and _player_near and not _busy


func _on_interact_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_refresh_prompt()


func _on_interact_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _defeated and _freeable and not _freed and _player_near and not _busy \
			and event.is_action_pressed("interact"):
		_open_minigame_select()


func _open_minigame_select() -> void:
	_busy = true
	_refresh_prompt()
	var popup: Control = MINIGAME_POPUP.instantiate()
	var layer := CanvasLayer.new()
	layer.add_child(popup)
	get_tree().current_scene.add_child(layer)
	popup.connect("selected", _on_minigame_selected)
	popup.connect("cancelled", _on_minigame_cancelled)
	popup.tree_exited.connect(layer.queue_free)


func _on_minigame_cancelled() -> void:
	_busy = false
	_refresh_prompt()


func _on_minigame_selected(kind: String) -> void:
	GameManager.minigame_finished.connect(_on_minigame_result, CONNECT_ONE_SHOT)
	GameManager.launch_minigame(kind)


func _on_minigame_result(won: bool) -> void:
	_busy = false
	if not won:
		GameState.toast("Gagal membebaskan %s. Coba lagi!" % boss_name)
		_refresh_prompt()
		return
	_freed = true
	GameState.mark_boss_freed(boss_id)
	GameState.add_reputation(1)
	GameState.toast("%s bebas dari manipulasi manusia! +1 Reputasi" % boss_name)
	prompt.visible = false
	sprite.modulate = Color.WHITE
	freed.emit()
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.5)
	tw.tween_callback(queue_free)

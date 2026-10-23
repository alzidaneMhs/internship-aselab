extends "res://scenes/enemies/enemy_base.gd"

signal defeated
signal freed
signal shield_changed(current: float, max_value: float)

const ITEM_CHOICE_UI := preload("res://scenes/ui/item_choice_ui.tscn")
const MINIGAME_POPUP := preload("res://scenes/ui/minigame_select_popup.tscn")
const STUN_FX := preload("res://scenes/enemies/stun_fx.gd")

@export var boss_id: String = ""
@export var boss_name: String = "Boss"
@export var drop_vonic: int = 27
@export var arena_left: float = -100000.0
@export var arena_right: float = 100000.0

@export_group("Shield & Stun")
@export var shield_max: float = 0.0
@export var stun_duration: float = 5.0
@export var stun_damage_multiplier: float = 1.5
@export var shield_regen_after_stun: bool = false
@export var stun_fx_height: float = 230.0

@onready var prompt: Label = $Prompt
@onready var interact_area: Area2D = $InteractArea

var dormant := true
var _revealed := true
var _defeated := false
var _freeable := false
var _freed := false
var _busy := false
var _player_near := false

var shield: float = 0.0
var stun_remaining: float = 0.0
var _shield_fx
var _stun_fx
var _was_stunned := false


func _init() -> void:
	add_to_group("boss")


func _ready() -> void:
	super._ready()
	shield = shield_max
	_shield_fx = get_node_or_null("ShieldFX")
	if _shield_fx != null:
		_shield_fx.ratio = 1.0 if shield_max > 0.0 else 0.0
	_stun_fx = Node2D.new()
	_stun_fx.set_script(STUN_FX)
	_stun_fx.position = Vector2(0.0, -stun_fx_height)
	add_child(_stun_fx)
	shield_changed.emit(shield, shield_max)
	prompt.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_refresh_prompt_text()
	Settings.prompts_changed.connect(_refresh_prompt_text)
	prompt.visible = false
	interact_area.body_entered.connect(_on_interact_body_entered)
	interact_area.body_exited.connect(_on_interact_body_exited)
	if GameState.is_boss_freed(boss_id):
		queue_free()
		return
	if GameState.is_boss_defeated(boss_id):
		_enter_defeated()
		_freeable = true


func _refresh_prompt_text() -> void:
	prompt.text = Settings.fill(tr("Tekan {interact} untuk membebaskan %s")) % boss_name


func _player_in_range() -> bool:
	return not dormant and super._player_in_range()


func hide_for_intro() -> void:
	_revealed = false
	visible = false
	hurtbox.set_deferred("monitorable", false)


func reveal(fade: float = 0.0) -> void:
	_revealed = true
	visible = true
	hurtbox.set_deferred("monitorable", true)
	if fade > 0.0:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, fade)


func ensure_revealed() -> void:
	if not _revealed:
		reveal(0.5)


func _physics_process(delta: float) -> void:
	if Cutscene.active:
		velocity = Vector2.ZERO
		return
	if _defeated:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0.0
		move_and_slide()
		return
	if stun_remaining > 0.0:
		stun_remaining -= delta
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0.0
		move_and_slide()
		if stun_remaining <= 0.0:
			_end_stun()
		return
	super._physics_process(delta)
	global_position.x = clampf(global_position.x, arena_left, arena_right)


func _on_died() -> void:
	if _defeated:
		return
	GameState.mark_boss_defeated(boss_id)
	GameState.add_points(drop_vonic)
	GameState.toast(tr("%s dikalahkan! +%d Vonic") % [boss_name, drop_vonic])
	_play_defeat_explosions()
	AudioManager.play_sfx("boss_defeat")
	GameManager.hit_stop(0.4, 0.12)
	get_tree().call_group("main_camera", "shake", 14.0)
	_enter_defeated()
	await get_tree().create_timer(1.2).timeout
	_offer_item_choice()


func modify_incoming_damage(amount: float) -> float:
	if _defeated:
		return amount
	if stun_remaining > 0.0:
		return amount * stun_damage_multiplier
	if shield <= 0.0:
		return amount
	shield = maxf(shield - amount, 0.0)
	shield_changed.emit(shield, shield_max)
	if _shield_fx != null:
		_shield_fx.ratio = shield / shield_max
		_shield_fx.hit_flash()
	if shield <= 0.0:
		_on_shield_broken()
	return 0.0


func _play_defeat_explosions() -> void:
	var tw := create_tween()
	for i in 8:
		tw.tween_callback(func():
			if is_inside_tree():
				var offset := Vector2(randf_range(-70.0, 70.0), -randf_range(40.0, 230.0))
				FX.spawn_death_burst(get_parent(), global_position + offset, burst_color, 1.7)
				AudioManager.play_sfx("explosion", -8.0, 0.15)
		)
		tw.tween_interval(0.11)


func _on_shield_broken() -> void:
	GameManager.hit_stop(0.16, 0.08)
	stun_remaining = stun_duration
	GameState.toast(tr("Shield %s hancur! Ia pingsan %d detik, serang sekarang!") % [boss_name, roundi(stun_duration)])
	AudioManager.play_sfx("shield_break")
	if _shield_fx != null:
		_shield_fx.break_burst()
	_stun_fx.active = true
	_was_stunned = true
	get_tree().call_group("main_camera", "shake", 10.0)
	_on_stun_start()


func _end_stun() -> void:
	stun_remaining = 0.0
	_stun_fx.active = false
	if shield_regen_after_stun and shield_max > 0.0:
		shield = shield_max
		shield_changed.emit(shield, shield_max)
		if _shield_fx != null:
			_shield_fx.ratio = 1.0
			_shield_fx.hit_flash()
		GameState.toast(tr("Shield %s pulih!") % boss_name)
		AudioManager.play_sfx("shield_restore", -2.0)
	_on_stun_end()


func _on_stun_start() -> void:
	pass


func _on_stun_end() -> void:
	pass


func _process(_delta: float) -> void:
	if _stun_fx != null and stun_remaining > 0.0:
		_stun_fx.progress = stun_remaining / stun_duration
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
		sprite.self_modulate = Color(0.7 + 0.3 * pulse, 0.85 + 0.2 * pulse, 1.5)
	elif _was_stunned:
		_was_stunned = false
		sprite.self_modulate = Color.WHITE


func _on_defeated_state() -> void:
	pass


func _enter_defeated() -> void:
	_defeated = true
	velocity = Vector2.ZERO
	stun_remaining = 0.0
	if _shield_fx != null:
		_shield_fx.visible = false
	if _stun_fx != null:
		_stun_fx.active = false
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
	AudioManager.play_sfx("item_get")
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
		GameState.toast(tr("Gagal membebaskan %s. Coba lagi!") % boss_name)
		_refresh_prompt()
		return
	_freed = true
	AudioManager.play_sfx("boss_freed")
	GameState.mark_boss_freed(boss_id)
	GameState.add_reputation(1)
	GameState.toast(tr("%s bebas dari manipulasi manusia! +1 Reputasi") % boss_name)
	prompt.visible = false
	sprite.modulate = Color.WHITE
	freed.emit()
	await Story.play_once(boss_id + "_freed")
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.5)
	tw.tween_callback(queue_free)

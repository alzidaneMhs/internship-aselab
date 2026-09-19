extends Node

signal points_changed(total: int)
signal upgrade_purchased(id: String, new_tier: int)

const SAVE_PATH := "user://savegame.save"
const CATALOG_PATH := "res://resources/economy/upgrade_catalog.tres"
const DEFAULT_STAGE_PATH := "res://scenes/levels/stage_1.tscn"

var points: int = 0
var upgrade_tiers: Dictionary = {
	"max_hp": 0,
	"attack_damage": 0,
	"dash_charges": 0,
	"extra_jump": 0,
}
var current_stage_path: String = DEFAULT_STAGE_PATH
var current_checkpoint_id: String = ""
var spawn_position: Vector3 = Vector3.ZERO

var _catalog: Resource


func _ready() -> void:
	_catalog = load(CATALOG_PATH)
	load_game()


func add_points(amount: int) -> void:
	points += amount
	points_changed.emit(points)


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_new_game() -> void:
	points = 0
	upgrade_tiers = {"max_hp": 0, "attack_damage": 0, "dash_charges": 0, "extra_jump": 0}
	current_stage_path = DEFAULT_STAGE_PATH
	current_checkpoint_id = ""
	spawn_position = Vector3.ZERO
	points_changed.emit(points)


func set_checkpoint(stage_path: String, checkpoint_id: String, pos: Vector3) -> void:
	current_stage_path = stage_path
	current_checkpoint_id = checkpoint_id
	spawn_position = pos


func save_game() -> void:
	var data := {
		"version": 1,
		"points": points,
		"upgrade_tiers": upgrade_tiers,
		"current_stage_path": current_stage_path,
		"current_checkpoint_id": current_checkpoint_id,
		"spawn_position": [spawn_position.x, spawn_position.y, spawn_position.z],
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: failed to open save file for writing")
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> void:
	if not has_save_file():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("GameState: failed to open save file for reading")
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: save file is corrupt, ignoring")
		return
	points = parsed.get("points", 0)
	upgrade_tiers = parsed.get("upgrade_tiers", upgrade_tiers)
	current_stage_path = parsed.get("current_stage_path", DEFAULT_STAGE_PATH)
	current_checkpoint_id = parsed.get("current_checkpoint_id", "")
	var pos: Array = parsed.get("spawn_position", [0.0, 0.0, 0.0])
	spawn_position = Vector3(pos[0], pos[1], pos[2])
	points_changed.emit(points)


func purchase_upgrade(id: String) -> bool:
	if _catalog == null:
		return false
	var def: UpgradeDefinition = _catalog.get_definition(id)
	if def == null:
		return false
	var current_tier: int = upgrade_tiers.get(id, 0)
	if current_tier >= def.max_tier:
		return false
	var cost: int = def.tier_costs[current_tier]
	if points < cost:
		return false
	points -= cost
	upgrade_tiers[id] = current_tier + 1
	save_game()
	points_changed.emit(points)
	upgrade_purchased.emit(id, upgrade_tiers[id])
	return true


func get_max_hp() -> float:
	return 5.0 + 2.0 * upgrade_tiers.get("max_hp", 0)


func get_attack_damage_bonus() -> float:
	return float(upgrade_tiers.get("attack_damage", 0))


func get_dash_charges() -> int:
	return upgrade_tiers.get("dash_charges", 0)


func get_extra_jumps() -> int:
	return upgrade_tiers.get("extra_jump", 0)

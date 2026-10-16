extends Node

signal points_changed(total: int)
signal reputation_changed(value: int)
signal items_changed
signal skills_changed
signal upgrade_purchased(id: String, new_tier: int)
signal regular_enemy_killed
signal toast_requested(message: String)
signal achievement_unlocked(id: String)

const SAVE_PATH := "user://savegame.save"
const SAVE_VERSION := 3
const CATALOG_PATH := "res://resources/economy/upgrade_catalog.tres"
const DEFAULT_STAGE_PATH := "res://scenes/levels/stage_0.tscn"

const BASE_HP := 100
const BASE_ATK := 10
const BASE_CHARGE := 20

const KIND_MIN_REPUTATION := -3
const HARDCORE_MAX_REPUTATION := -10

const ITEMS := {
	"anti_interrupt": {
		"name": "Iron Resolve",
		"desc": "Serangan Isme tidak lagi terhenti saat terkena serangan musuh. Damage tetap diterima.",
	},
	"vampire": {
		"name": "Scavenger Core",
		"desc": "Heal 8 HP setiap berhasil mengalahkan musuh reguler.",
	},
	"glass_hp": {
		"name": "Titan Plating",
		"desc": "Max HP +30, tetapi ATK -2.",
	},
	"glass_atk": {
		"name": "Overclock Chip",
		"desc": "ATK +4, tetapi Max HP -20.",
	},
	"bounty": {
		"name": "Cursed Coin",
		"desc": "Langsung dapat 20 Vonic, tetapi damage dari obstacle/trap meningkat 50%.",
	},
	"volatile_core": {
		"name": "Volatile Core",
		"desc": "Charge attack punya 1/3 peluang acak untuk memberi +10 damage.",
	},
	"double_jump": {
		"name": "Double Jump",
		"desc": "Mendapatkan mekanisme double jump.",
	},
	"dash": {
		"name": "Dash",
		"desc": "Mendapatkan mekanisme dash (tombol {dash}).",
	},
}

var points: int = 0
var reputation: int = 0
var upgrade_tiers: Dictionary = {"health": 0, "attack": 0, "charge_attack": 0}
var items: Array = []
var skills: Array = []
var killed_enemies: Dictionary = {}
var secrets_found: Array = []
var achievements: Array = []
var bosses_defeated: Array = []
var bosses_freed: Array = []
var seen_dialogues: Array = []

var current_stage_path: String = DEFAULT_STAGE_PATH
var current_checkpoint_id: String = ""
var spawn_position: Vector2 = Vector2.ZERO
var spawn_at_checkpoint: bool = false

var _catalog: Resource


func _ready() -> void:
	_catalog = load(CATALOG_PATH)
	load_game()


func add_points(amount: int) -> void:
	points += amount
	points_changed.emit(points)


func add_reputation(delta: int) -> void:
	reputation += delta
	reputation_changed.emit(reputation)


func on_regular_enemy_killed() -> void:
	add_reputation(-1)
	regular_enemy_killed.emit()


func get_minigame_difficulty() -> String:
	if reputation >= KIND_MIN_REPUTATION:
		return "kind"
	if reputation <= HARDCORE_MAX_REPUTATION:
		return "hardcore"
	return "normal"


func get_reputation_title() -> String:
	match get_minigame_difficulty():
		"kind":
			return "Baik Hati"
		"hardcore":
			return "Genosida"
		_:
			return "Seimbang"


func toast(message: String) -> void:
	toast_requested.emit(message)


const SECRETS := {
	"secret_1": {
		"stage": 1,
		"title": "Foto Kenangan",
		"lore": "Latar tempat di permukaan planet dengan bangunan. Isme, Lushte, Krums, dan beberapa robot (diblur) sedang berfoto bersama, saat mereka masih berada dalam fisik asli mereka.",
		"image": "res://assets/sprites/backgrounds/bg_permukaan.png",
	},
	"secret_2": {
		"stage": 2,
		"title": "Layar CORE RESET",
		"lore": "Sebuah layar monitor besar dengan progress bar. Di atasnya bertuliskan 'CORE RESET'.",
		"image": "res://assets/sprites/lore/core_reset.png",
	},
	"secret_3": {
		"stage": 3,
		"title": "Pintu Fasilitas Bawah Tanah",
		"lore": "Salah satu pintu masuk fasilitas bawah tanah yang lorong-lorongnya gelap dengan cahaya remang-remang, seperti labirin cermin.",
		"image": "res://assets/sprites/backgrounds/bg_underground_cave.png",
	},
	"secret_4": {
		"stage": 4,
		"title": "Lushte yang Belum Selesai",
		"lore": "Sebuah ruangan berisi Lushte dalam wujud boss yang belum selesai dibangun, dan dua manusia yang sedang membelakangi kamera.",
		"image": "res://assets/sprites/enemies/winged/musuh_bersayap.png",
	},
	"secret_5": {
		"stage": 5,
		"title": "Wujud Asli Krums",
		"lore": "Fisik asli Krums tepat sebelum dimodifikasi: terbaring di atas platform datar dengan komponen-komponennya yang terpisah-pisah.",
		"image": "res://assets/sprites/enemies/shielded/musuh_bertameng.png",
	},
}

const ALL_SECRETS_ID := "secret_all"
const ALL_SECRETS_TITLE := "Penyingkap Rahasia"
const ALL_SECRETS_DESC := "Temukan kelima secret room yang tersembunyi di fasilitas bawah tanah."


func get_secret_info(id: String) -> Dictionary:
	return SECRETS.get(id, {})


func is_secret_found(id: String) -> bool:
	return secrets_found.has(id)


func has_achievement(id: String) -> bool:
	return achievements.has(id)


func get_achievement_total() -> int:
	return SECRETS.size() + 1


func _unlock_achievement(id: String) -> void:
	if achievements.has(id):
		return
	achievements.append(id)
	achievement_unlocked.emit(id)


func discover_secret(id: String) -> void:
	if secrets_found.has(id):
		return
	secrets_found.append(id)
	_unlock_achievement(id)
	if secrets_found.size() >= SECRETS.size():
		_unlock_achievement(ALL_SECRETS_ID)


func is_boss_defeated(id: String) -> bool:
	return bosses_defeated.has(id)


func mark_boss_defeated(id: String) -> void:
	if not bosses_defeated.has(id):
		bosses_defeated.append(id)


func is_boss_freed(id: String) -> bool:
	return bosses_freed.has(id)


func mark_boss_freed(id: String) -> void:
	if not bosses_freed.has(id):
		bosses_freed.append(id)


func has_seen(id: String) -> bool:
	return seen_dialogues.has(id)


func mark_seen(id: String) -> void:
	if not seen_dialogues.has(id):
		seen_dialogues.append(id)


const SKILLS := {
	"emergency_shield": {
		"name": "Perisai Darurat",
		"desc": "Saat HP Isme mencapai 25 atau kurang, muncul perisai yang menyerap 30 damage selama 8 detik. Pulih setelah 40 detik.",
		"cost": 35,
		"badge": "SH",
	},
	"swift_feet": {
		"name": "Langkah Cepat",
		"desc": "Kecepatan gerak Isme bertambah 5%.",
		"cost": 20,
		"badge": "SP",
	},
	"double_dash": {
		"name": "Double Dash",
		"desc": "Dash bisa dilakukan dua kali berturut-turut. Butuh item Dash dari boss.",
		"cost": 45,
		"requires_item": "dash",
		"badge": "DD",
	},
}

const SPEED_SKILL_BONUS := 0.05


func is_enemy_killed(stage_path: String, id: String) -> bool:
	return killed_enemies.has(stage_path) and (killed_enemies[stage_path] as Array).has(id)


func mark_enemy_killed(stage_path: String, id: String) -> void:
	if not killed_enemies.has(stage_path):
		killed_enemies[stage_path] = []
	var list: Array = killed_enemies[stage_path]
	if not list.has(id):
		list.append(id)
		save_game()


func clear_stage_kills(stage_path: String) -> void:
	killed_enemies.erase(stage_path)


func has_skill(id: String) -> bool:
	return skills.has(id)


func skill_requirement_met(id: String) -> bool:
	var info: Dictionary = SKILLS.get(id, {})
	var need: String = info.get("requires_item", "")
	return need.is_empty() or has_item(need)


func purchase_skill(id: String) -> bool:
	if not SKILLS.has(id) or skills.has(id) or not skill_requirement_met(id):
		return false
	var cost: int = int(SKILLS[id]["cost"])
	if points < cost:
		return false
	points -= cost
	skills.append(id)
	save_game()
	points_changed.emit(points)
	skills_changed.emit()
	toast(tr("Skill didapat: %s") % tr(SKILLS[id]["name"]))
	return true


func get_skill_badges() -> Array:
	var out: Array = []
	for id in skills:
		out.append("skill_" + String(id))
	return out


func has_item(id: String) -> bool:
	return items.has(id)


func get_random_item_choices(count: int) -> Array:
	var pool: Array = []
	for id in ITEMS.keys():
		if not items.has(id):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, count)


func acquire_item(id: String) -> void:
	if items.has(id) or not ITEMS.has(id):
		return
	items.append(id)
	items_changed.emit()
	toast(tr("Item didapat: %s") % tr(ITEMS[id]["name"]))
	if id == "bounty":
		add_points(20)


func _stat(id: String, base: int) -> int:
	var tier: int = int(upgrade_tiers.get(id, 0))
	if tier <= 0 or _catalog == null:
		return base
	var def: UpgradeDefinition = _catalog.get_definition(id)
	if def == null:
		return base
	return def.tier_values[mini(tier, def.tier_values.size()) - 1]


func get_max_hp() -> float:
	var v := _stat("health", BASE_HP)
	if has_item("glass_hp"):
		v += 30
	if has_item("glass_atk"):
		v -= 20
	return float(v)


func get_attack() -> float:
	var v := _stat("attack", BASE_ATK)
	if has_item("glass_hp"):
		v -= 2
	if has_item("glass_atk"):
		v += 4
	return float(v)


func get_charge_attack() -> float:
	return float(_stat("charge_attack", BASE_CHARGE))


func get_trap_multiplier() -> float:
	return 1.5 if has_item("bounty") else 1.0


func purchase_upgrade(id: String) -> bool:
	if _catalog == null:
		return false
	var def: UpgradeDefinition = _catalog.get_definition(id)
	if def == null:
		return false
	var current_tier: int = int(upgrade_tiers.get(id, 0))
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


func reset_new_game() -> void:
	points = 0
	reputation = 0
	upgrade_tiers = {"health": 0, "attack": 0, "charge_attack": 0}
	items = []
	skills = []
	killed_enemies = {}
	secrets_found = []
	achievements = []
	bosses_defeated = []
	bosses_freed = []
	seen_dialogues = []
	current_stage_path = DEFAULT_STAGE_PATH
	current_checkpoint_id = ""
	spawn_position = Vector2.ZERO
	spawn_at_checkpoint = false
	items_changed.emit()
	points_changed.emit(points)
	reputation_changed.emit(reputation)


func set_checkpoint(stage_path: String, checkpoint_id: String, pos: Vector2) -> void:
	current_stage_path = stage_path
	current_checkpoint_id = checkpoint_id
	spawn_position = pos


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"points": points,
		"reputation": reputation,
		"upgrade_tiers": upgrade_tiers,
		"items": items,
		"skills": skills,
		"killed_enemies": killed_enemies,
		"secrets_found": secrets_found,
		"achievements": achievements,
		"bosses_defeated": bosses_defeated,
		"bosses_freed": bosses_freed,
		"seen_dialogues": seen_dialogues,
		"current_stage_path": current_stage_path,
		"current_checkpoint_id": current_checkpoint_id,
		"spawn_position": [spawn_position.x, spawn_position.y],
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
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) < SAVE_VERSION:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	points = int(parsed.get("points", 0))
	reputation = int(parsed.get("reputation", 0))
	var tiers: Dictionary = parsed.get("upgrade_tiers", {})
	for key in upgrade_tiers.keys():
		upgrade_tiers[key] = int(tiers.get(key, 0))
	items = parsed.get("items", [])
	skills = parsed.get("skills", [])
	killed_enemies = parsed.get("killed_enemies", {})
	secrets_found = parsed.get("secrets_found", [])
	achievements = parsed.get("achievements", [])
	bosses_defeated = parsed.get("bosses_defeated", [])
	bosses_freed = parsed.get("bosses_freed", [])
	seen_dialogues = parsed.get("seen_dialogues", [])
	current_stage_path = parsed.get("current_stage_path", DEFAULT_STAGE_PATH)
	current_checkpoint_id = parsed.get("current_checkpoint_id", "")
	var pos: Array = parsed.get("spawn_position", [0.0, 0.0])
	spawn_position = Vector2(pos[0], pos[1])
	if current_checkpoint_id.begins_with("stage11_fire"):
		current_checkpoint_id = ""
		spawn_position = Vector2.ZERO
	points_changed.emit(points)
	reputation_changed.emit(reputation)

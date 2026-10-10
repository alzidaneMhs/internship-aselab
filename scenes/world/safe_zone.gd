extends Node2D

## Post-boss safe zone: checkpoint + Hanch (merchant) + exit door. It stays
## locked until the boss has been freed. Origin is the floor's top-left corner.

@export var checkpoint_id: String = ""
@export var stage_scene_path: String = ""
@export var next_stage_path: String = ""
@export var required_boss_id: String = ""

# Untyped on purpose: these nodes carry their own script properties.
@onready var checkpoint = $Checkpoint
@onready var merchant = $Merchant
@onready var exit_door = $Exit


func _ready() -> void:
	checkpoint.checkpoint_id = checkpoint_id
	checkpoint.stage_scene_path = stage_scene_path
	exit_door.next_stage_path = next_stage_path

	if GameState.is_boss_freed(required_boss_id):
		_set_active(true)
		return
	_set_active(false)
	var boss := get_tree().get_first_node_in_group("boss")
	if boss != null:
		boss.connect("freed", _on_boss_freed)


func _set_active(active: bool) -> void:
	for node in [checkpoint, merchant, exit_door]:
		node.visible = active
		node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _on_boss_freed() -> void:
	_set_active(true)
	GameState.toast("Safe zone terbuka: checkpoint, Hanch si merchant, dan pintu keluar")

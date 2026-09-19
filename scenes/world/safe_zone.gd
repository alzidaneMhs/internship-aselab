extends Node3D

## Reusable safe-zone room (floor + checkpoint + merchant + minigame trigger),
## instanced into both stage_3.tscn and stage_5.tscn. Per-stage identity is the
## only thing that varies, so it's exposed here and forwarded into the nested
## Checkpoint child at ready time — simpler than Godot's "editable children"
## override mechanism for a two-level-deep nested property.

@export var checkpoint_id: String = ""
@export var stage_scene_path: String = ""

@onready var checkpoint: Area3D = $Checkpoint


func _ready() -> void:
	checkpoint.checkpoint_id = checkpoint_id
	checkpoint.stage_scene_path = stage_scene_path

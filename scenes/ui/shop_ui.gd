extends Control

signal closed

const CATALOG_PATH := "res://resources/economy/upgrade_catalog.tres"

@onready var rows_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/RowsContainer
@onready var points_label: Label = $Panel/MarginContainer/VBoxContainer/PointsLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _catalog: Resource
var _rows: Dictionary = {}


func _ready() -> void:
	_catalog = load(CATALOG_PATH)
	close_button.pressed.connect(func(): closed.emit())
	GameState.points_changed.connect(_refresh)
	_build_rows()
	_refresh(GameState.points)


func _build_rows() -> void:
	for def in _catalog.upgrades:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(240, 0)
		row.add_child(name_label)

		var cost_label := Label.new()
		cost_label.custom_minimum_size = Vector2(90, 0)
		row.add_child(cost_label)

		var buy_button := Button.new()
		buy_button.text = "Buy"
		buy_button.pressed.connect(_on_buy_pressed.bind(def.id))
		row.add_child(buy_button)

		rows_container.add_child(row)
		_rows[def.id] = {"name": name_label, "cost": cost_label, "button": buy_button}


func _refresh(points: int) -> void:
	points_label.text = "Points: %d" % points
	for def in _catalog.upgrades:
		var refs: Dictionary = _rows[def.id]
		var tier: int = GameState.upgrade_tiers.get(def.id, 0)
		if tier >= def.max_tier:
			refs["name"].text = "%s (MAX)" % def.display_name
			refs["cost"].text = "-"
			refs["button"].disabled = true
		else:
			var cost: int = def.tier_costs[tier]
			refs["name"].text = "%s (Tier %d/%d)" % [def.display_name, tier, def.max_tier]
			refs["cost"].text = "%d pts" % cost
			refs["button"].disabled = points < cost


func _on_buy_pressed(id: String) -> void:
	if GameState.purchase_upgrade(id):
		AudioManager.play_sfx("purchase")

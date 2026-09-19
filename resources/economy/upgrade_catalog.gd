extends Resource
class_name UpgradeCatalog

@export var upgrades: Array[UpgradeDefinition] = []


func get_definition(id: String) -> UpgradeDefinition:
	for def in upgrades:
		if def.id == id:
			return def
	return null

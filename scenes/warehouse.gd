extends Node2D

@onready var eid: Label = $ID

var ent_id: int = 0
var w: ECS.World = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	w = Global.ecs_world

	ent_id = w.create_entity()
	w.add_component(ent_id, "Inventory", Comps.Inventory.new(10000))
	w.add_component(ent_id, "Position", Comps.Position.new(self.position))
	w.add_tag(ent_id, "Warehouse")
	eid.text = "%d" % ent_id

func _process(_delta: float) -> void:
	$Stat.text = w.get_component(ent_id, "Inventory").get_inventory_str()

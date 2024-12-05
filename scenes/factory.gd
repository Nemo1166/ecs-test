extends Node2D

@export var current_recipe: Recipe = null


@onready var eid: Label = $ID
@onready var depot_label: Label = $Depot

var ent_id: int = 0
var w: ECS.World = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	w = Global.ecs_world

	ent_id = w.create_entity()
	w.add_component(ent_id, "Producer", Comps.Producer.new())
	w.add_component(ent_id, "Inventory", Comps.Inventory.new(10000))
	w.add_component(ent_id, "ElectricConsumer", Comps.ElectricConsumer.new())
	w.add_tag(ent_id, "Factory")
	eid.text = "%d" % ent_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_progress()
	var inv: Comps.Inventory = w.get_component(ent_id, "Inventory")
	depot_label.text = inv.get_inventory_str()


func put(loc: Vector2):
	self.position = loc
	w.add_component(ent_id, "Position", Comps.Position.new(loc))

func set_recipe(recipe: Recipe):
	current_recipe = recipe
	w.publish("factory_set_recipe", {"recipe": recipe, "ent_id": ent_id})

var progress: float = 0.0
var state: int
var work_status: int
func update_progress():
	progress = w.get_component(ent_id, "Producer").progress
	$ProgressBar.value = progress
	state = w.get_component(ent_id, "Producer").current_state
	work_status = w.get_component(ent_id, "Producer").work_state

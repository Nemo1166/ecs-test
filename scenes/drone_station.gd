extends Node2D

@export var drone_instances: Node2D

var drones: Dictionary = {} # {id: Node2D}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var n = 7
	for i in range(n):
		var drone = Global.DRONE.instantiate()
		drone.name = "Drone" + str(i)
		drone.drone_id = i
		drone_instances.add_child(drone)
		drone.position = Vector2(100, i * 50)
		# drone.hide()
		drones[i] = drone
	Global.ecs_world.subscribe("drones_status", self, "_on_drones_status_update")


func _on_drones_status_update(status: Array) -> void:
	for s in status:
		# s: {id, position, active, cargo}
		var drone = drones[s.id]
		drone.position = s.position
		if s.active:
			drone.show()
		else:
			drone.hide()
		drone.get_node("Cargo").text = s.cargo

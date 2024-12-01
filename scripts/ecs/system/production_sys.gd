class_name ProdSystem extends ECS.System


var global_efficiency: float = 1.0
var power_efficiency: float = 1.0


func _init(world: ECS.World) -> void:
	super._init(world)
	_world.event_bus.add_listener("power_supply_rate_changed", self, "on_power_supply_rate_changed")


func update(delta: float) -> void:
	var ent_ids: Array[int] = _world.ent_mgr.get_all_entity_ids()
	for ent_id in ent_ids:
		var producer: Comps.Producer = _world.ent_mgr.get_component(ent_id, "Producer")
		if producer != null:
			var input: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "InputDepot")
			var output: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "OutputDepot")
			if producer.recipe != null:
				# check if enough resources
				if not has_enough_resources(input, producer.recipe):
					producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_RESOURCES
					producer.current_state = Comps.Producer.State.IDLE
					continue
				# check if too many products
				elif too_many_products(output, producer.recipe):
					producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_SPACE
					producer.current_state = Comps.Producer.State.IDLE
					continue
				else:
					producer.work_state = Comps.Producer.WorkState.NORMAL
					producer.current_state = Comps.Producer.State.WORKING
				# produce products
				producer.progress += delta * global_efficiency * power_efficiency
				if producer.progress >= 100:
					# collect products
					producer.progress = 0
					for i in producer.recipe.products.keys():
						var amount: int = producer.recipe.results[i]
						output.add_item(i, amount)
					# consume resources
					for i in producer.recipe.ingredients.keys():
						var amount: int = producer.recipe.ingredients[i]
						input.remove_item(i, amount)


func has_enough_resources(depot: Comps.Inventory, recipe: Recipe) -> bool:
	for i in recipe.ingredients.keys():
		var amount: int = recipe.ingredients[i]
		if not depot.has_item(i, amount):
			return false
	return true


func too_many_products(depot: Comps.Inventory, recipe: Recipe) -> bool:
	const PRODUCT_COEFFICIENT := 2
	for i in recipe.products.keys():
		var amount: int = recipe.results[i] * PRODUCT_COEFFICIENT
		if depot.has_item(i, amount):
			return true
	return false


func on_power_supply_rate_changed(value: float) -> void:
	power_efficiency = value
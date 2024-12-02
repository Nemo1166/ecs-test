class_name ProdSystem extends ECS.System


var global_efficiency: float = 1.0
var power_efficiency: float = 1.0

var counter: Array[int] = [0, 0] # N. of [working, idle] producers


func _init(world: ECS.World) -> void:
	super._init(world)
	_world.event_bus.add_listener("power_supply_rate_changed", self, "on_power_supply_rate_changed")


func update(delta: float) -> void:
	counter = [0, 0]
	var ent_ids: Array = _world.ent_mgr.get_all_entity_ids()
	for ent_id: int in ent_ids:
		var producer: Comps.Producer = _world.ent_mgr.get_component(ent_id, "Producer")
		if producer != null:
			var input: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "InputDepot")
			var output: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "OutputDepot")
			if producer.recipe != null:
				# check if enough resources
				if not has_enough_resources(input, producer.recipe):
					producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_RESOURCES
					producer.current_state = Comps.Producer.State.IDLE
					set_consumer_state(ent_id, Comps.ElectricConsumer.State.IDLE)
					counter[1] += 1
					continue
				# check if too many products
				elif too_many_products(output, producer.recipe):
					producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_SPACE
					producer.current_state = Comps.Producer.State.IDLE
					set_consumer_state(ent_id, Comps.ElectricConsumer.State.IDLE)
					counter[1] += 1
					continue
				else:
					# start working
					producer.work_state = Comps.Producer.WorkState.NORMAL
					producer.current_state = Comps.Producer.State.WORKING
					set_consumer_state(ent_id, Comps.ElectricConsumer.State.WORKING)
					counter[0] += 1
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
	if depot == null:
		return false
	for i in recipe.ingredients.keys():
		var amount: int = recipe.ingredients[i]
		if not depot.has_item(i, amount):
			return false
	return true


func too_many_products(depot: Comps.Inventory, recipe: Recipe) -> bool:
	if depot == null:
		return false
	const PRODUCT_COEFFICIENT := 2
	for i in recipe.products.keys():
		var amount: int = recipe.results[i] * PRODUCT_COEFFICIENT
		if depot.has_item(i, amount):
			return true
	return false


func set_consumer_state(ent_id: int, state: Comps.ElectricConsumer.State) -> void:
	var consumer: Comps.ElectricConsumer = _world.ent_mgr.get_component(ent_id, "ElectricConsumer")
	if consumer != null:
		consumer.current_state = state


func get_producer_count() -> Array[int]:
	return [counter[0], counter[1], counter[0] + counter[1]] # [working, idle, total]

func on_power_supply_rate_changed(value: float) -> void:
	power_efficiency = value

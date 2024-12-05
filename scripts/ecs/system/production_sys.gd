class_name ProdSystem extends ECS.System


var global_efficiency: float = 1.0
var power_efficiency: float = 1.0

var counter: Array[int] = [0, 0] # N. of [working, idle] producers


func _init(world: ECS.World) -> void:
	super._init(world)
	_world.subscribe("power_supply_rate_changed", self, "on_power_supply_rate_changed")
	_world.subscribe("factory_set_recipe", self, "_on_set_recipe")


func update(delta: float) -> void:
	counter = [0, 0]
	var ent_ids: Array = _world.get_all_entity_ids("Factory")
	for ent_id: int in ent_ids:
		var producer: Comps.Producer = _world.get_component(ent_id, "Producer")
		if producer != null:
			var inv: Comps.Inventory = _world.get_component(ent_id, "Inventory")
			if producer.recipe != null:
				# check if enough resources
				if not has_enough_resources(inv, producer.recipe):
					producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_RESOURCES
					producer.current_state = Comps.Producer.State.IDLE
					set_consumer_state(ent_id, Comps.ElectricConsumer.State.IDLE)
					counter[1] += 1
					continue
				# check if too many products
				elif too_many_products(inv, producer.recipe):
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
				producer.progress += delta * global_efficiency * power_efficiency / producer.recipe.duration
				if producer.progress >= 1:
					# collect products
					producer.progress = 0
					for i in producer.recipe.results.keys():
						var amount: int = producer.recipe.results[i]
						inv.add_item(i, amount)
					# consume resources
					for i in producer.recipe.ingredients.keys():
						var amount: int = producer.recipe.ingredients[i]
						inv.remove_item(i, amount)


func _on_set_recipe(data: Dictionary) -> void:
	# data: {recipe: Recipe, ent_id: int}
	var recipe: Recipe = data["recipe"]
	var ent_id: int = data["ent_id"]
	var producer: Comps.Producer = _world.get_component(ent_id, "Producer")
	if producer != null:
		if recipe == null:
			producer.reset()
		else:
			producer.reset()
			producer.set_recipe(recipe)

func has_enough_resources(inv: Comps.Inventory, recipe: Recipe) -> bool:
	if inv == null:
		return false
	if recipe.ingredients.size() == 0:
		return true
	for i in recipe.ingredients.keys():
		var amount: int = recipe.ingredients[i]
		if not inv.has_item(i, amount):
			return false
	return true


func too_many_products(inv: Comps.Inventory, recipe: Recipe) -> bool:
	if inv == null:
		return false
	const PRODUCT_COEFFICIENT := 10
	for i in recipe.results.keys():
		var amount: int = recipe.results[i] * PRODUCT_COEFFICIENT
		if inv.has_item(i, amount):
			return true
	return false


func set_consumer_state(ent_id: int, state: Comps.ElectricConsumer.State) -> void:
	var consumer: Comps.ElectricConsumer = _world.get_component(ent_id, "ElectricConsumer")
	if consumer != null:
		consumer.current_state = state


func get_producer_count() -> Array[int]:
	return [counter[0], counter[1], counter[0] + counter[1]] # [working, idle, total]

func on_power_supply_rate_changed(value: float) -> void:
	power_efficiency = value

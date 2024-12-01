class_name ProdSystem extends ECS.System


var global_efficiency: float = 1.0


func _init(world: ECS.World) -> void:
	super._init(world)


func update(delta: float) -> void:
	var ent_ids = _world.ent_mgr.get_all_entity_ids()
	for ent_id in ent_ids:
		var producer: Comps.Producer = _world.ent_mgr.get_component(ent_id, "Producer")
		var input: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "InputDepot")
		var output: Comps.Inventory = _world.ent_mgr.get_component(ent_id, "OutputDepot")
		if producer != null:
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
				producer.progress += delta * global_efficiency
				if producer.progress >= 100:
					# collect products
					producer.progress = 0
					for i in producer.recipe.products.keys():
						var amount: float = producer.recipe.results[i]
						output.add_item(i, amount)
					# consume resources
					for i in producer.recipe.ingredients.keys():
						var amount: float = producer.recipe.ingredients[i]
						input.remove_item(i, amount)


func has_enough_resources(depot: Comps.Inventory, recipe: Recipe) -> bool:
	for i in recipe.ingredients.keys():
		var amount: float = recipe.ingredients[i]
		if not depot.has_item(i, amount):
			return false
	return true


func too_many_products(depot: Comps.Inventory, recipe: Recipe) -> bool:
	const PRODUCT_COEFFICIENT := 2
	for i in recipe.products.keys():
		var amount: float = recipe.results[i] * PRODUCT_COEFFICIENT
		if depot.has_item(i, amount):
			return true
	return false
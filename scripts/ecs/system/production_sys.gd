class_name ProdSystem extends ECS.System


var global_efficiency: float = 1.0


func _init(world: ECS.World) -> void:
    super._init(world)


func update(delta: float) -> void:
    for ent: Entity in _world.entities.values():
        var producer: Comps.Producer = ent.get_component("Producer")
        if producer != null:
            if producer.recipe != null:
                # check if enough resources
                if not has_enough_resources(ent, producer.recipe):
                    producer.work_state = Comps.Producer.WorkState.INSUFFICIENT_RESOURCES
                    producer.current_state = Comps.Producer.State.IDLE
                    continue
                # check if too many products
                elif too_many_products(ent, producer.recipe):
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
                        var output: Comps.Inventory = ent.get_component("OutputDepot")
                        output.add_item(i, amount)
                    # consume resources
                    for i in producer.recipe.ingredients.keys():
                        var amount: float = producer.recipe.ingredients[i]
                        var input: Comps.Inventory = ent.get_component("InputDepot")
                        input.remove_item(i, amount)


func has_enough_resources(ent: Entity, recipe: Recipe) -> bool:
    for i in recipe.ingredients.keys():
        var amount: float = recipe.ingredients[i]
        var input: Comps.Inventory = ent.get_component("InputDepot")
        if not input.has_item(i, amount):
            return false
    return true


func too_many_products(ent: Entity, recipe: Recipe) -> bool:
    const PRODUCT_COEFFICIENT := 2
    for i in recipe.products.keys():
        var amount: float = recipe.results[i] * PRODUCT_COEFFICIENT
        var output: Comps.Inventory = ent.get_component("OutputDepot")
        if output.has_item(i, amount):
            return true
    return false
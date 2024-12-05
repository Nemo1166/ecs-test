class_name LogisticSystem extends ECS.System

var drones: Array = []
var task_pending: Array[Task] = []

var drone_idx := 0

func _init(world: ECS.World):
	super._init(world)
	## create drones
	for i in range(7):
		var drone = Drone.new(drone_idx)
		drone_idx += 1
		drones.append(drone)
	# subscribe to events
	_world.subscribe("factory_set_recipe", self, "update_req_supply_list")

func update(delta: float) -> void:
	# collect warehouse info
	collect_warehouse_info()
	# match orders
	match_orders()
	# assign tasks to drones
	assign_tasks()
	var status = update_drones(delta)
	_world.publish("drones_status", status)



func distribute_task(weight: float) -> Task:
	if task_pending.size() == 0:
		return null
	# split the task into smaller task_pending if too large
	if task_pending[0]._weight > weight:
		# split the task
		var sub_task = task_pending[0].copy()
		sub_task._amount = int(weight / sub_task._item.weight)
		task_pending[0]._amount -= sub_task._amount
		task_pending[0]._weight -= sub_task._item.weight * sub_task._amount
		return sub_task
	else:
		# the task is too small
		return task_pending.pop_front()

func update_drones(delta: float):
	var status = []
	for drone in drones:
		if drone.is_active:
			drone.move_to(delta)
			if drone.position.distance_to(drone.destination) < 5:
				_world.publish("drone_arrived", drone._id)
				_on_drone_completed_task(drone._id)
		status.append({
			"id": drone._id,
			"position": drone.position,
			"active": drone.is_active,
			"cargo": drone.current_task._item.name if drone.current_task != null else ""
		})
	return status

#region methods

const INVALID_POSITION = Vector2(-1, -1)

func get_entity_coords(entity_id: int) -> Vector2:
	var p = _world.get_component(entity_id, "Position")
	if p != null:
		return p.get_position()
	return INVALID_POSITION

func get_entity_id_at_position(position: Vector2) -> int:
	var entity_ids = _world.get_all_entity_ids()
	for entity_id in entity_ids:
		var p = _world.get_component(entity_id, "Position")
		if p != null and p.get_position().is_equal_approx(position):
			return entity_id
	return -1

#region req and supplies

var factory_data: Dictionary = {} # {ent_id: {req: Array[Item], supply: Array[Item], recipe: Recipe}}
var warehouses: Array[int] = []

func update_req_supply_list(data: Dictionary) -> void:
	var ent_id: int = data["ent_id"]
	var recipe: Recipe = data["recipe"]
	if recipe == null:
		# remove the factory from the list
		factory_data.erase(ent_id)
	else:
		# update the factory data
		var req: Array[Item] = []
		var supply: Array[Item] = []
		for item in recipe.ingredients.keys():
			req.append(item)
		for item in recipe.results.keys():
			supply.append(item)
		factory_data[ent_id] = {
			"req": req,
			"supply": supply,
			"recipe": recipe
		}

func collect_warehouse_info():
	warehouses = _world.get_all_entity_ids("Warehouse")

#region task mgmt

func match_orders():
	var req_list: Array = [] # {factory_id, item, amount}
	var supply_list: Array = [] # {factory_id, item, amount}
	# collect req and supply list
	for factory_id in factory_data.keys():
		var factory = factory_data[factory_id]
		for item in factory["req"]:
			var req_amount = get_req_amount(factory_id, item)
			if req_amount > 0:
				req_list.append({
					"factory_id": factory_id,
					"item": item,
					"amount": req_amount
				})
		for item in factory["supply"]:
			var supply_amount = get_inventory_item_amount(factory_id, item)
			if supply_amount > 0:
				supply_list.append({
					"factory_id": factory_id,
					"item": item,
					"amount": supply_amount
				})
	# match orders
	for req in req_list:
		for supply in supply_list:
			# req is satisfied
			if req["item"] == supply["item"]:
				var amount = min(req["amount"], supply["amount"])
				add_task({
					"from": supply["factory_id"],
					"to": req["factory_id"],
					"item": req["item"],
					"amount": amount
				})
				req["amount"] -= amount
				supply["amount"] -= amount
				if supply["amount"] == 0:
					supply_list.erase(supply)
				if req["amount"] == 0:
					req_list.erase(req)
					break
		# req amount is not satisfied, fetch from warehouse
		if req["amount"] > 0:
			for eid in warehouses:
				var supply_amount = get_inventory_item_amount(eid, req["item"])
				if supply_amount > 0:
					var amount = min(req["amount"], supply_amount)
					add_task({
						"from": eid,
						"to": req["factory_id"],
						"item": req["item"],
						"amount": amount
					})
					req["amount"] -= amount
					if req["amount"] == 0:
						break
	# remaining supply send to warehouse
	for supply in supply_list:
		add_task({
			"from": supply["factory_id"],
			"to": warehouses[0],
			"item": supply["item"],
			"amount": supply["amount"]
		})


func get_req_amount(factory_id: int, item: Item) -> int:
	var factory = factory_data[factory_id]
	var recipe = factory["recipe"]
	return recipe.ingredients[item] - get_inventory_item_amount(factory_id, item)

func get_inventory_item_amount(eid: int, item: Item) -> int:
	var inv: Comps.Inventory = _world.get_component(eid, "Inventory")
	if inv != null:
		return inv.get_item_amount(item)
	return 0

func update_item_amount(eid: int, item: Item, delta_amount: int) -> void:
	var inv: Comps.Inventory = _world.get_component(eid, "Inventory")
	if inv != null:
		if delta_amount > 0:
			inv.add_item(item, delta_amount)
		else:
			inv.remove_item(item, -delta_amount)
	print("entity: %d, item: %s, amount: %d" % [eid, item.name, delta_amount])

func add_task(data: Dictionary) -> void:
	var from: int = data["from"]
	var to: int = data["to"]
	var item: Item = data["item"]
	var amount: int = data["amount"]

	# 检查是否存在相同的任务
	for task in task_pending:
		if task.is_equal(Task.new(get_entity_coords(from), get_entity_coords(to), item, amount)):
			return

	# 创建新任务并添加到任务队列
	var task = Task.new(get_entity_coords(from), get_entity_coords(to), item, amount)
	task_pending.append(task)

func assign_tasks():
	if task_pending.size() == 0:
		return
	for drone in drones:
		if drone.is_active:
			continue
		var task = distribute_task(drone.capacity)
		if task != null:
			drone.assign_task(task)
		# remove items from source
			update_item_amount(get_entity_id_at_position(task._source), task._item, -task._amount)

func _on_drone_completed_task(drone_id: int):
	var task = drones[drone_id].current_task
	# add items to target
	update_item_amount(get_entity_id_at_position(task._target), task._item, task._amount)
	drones[drone_id].complete_task()

#region data class

class Task:
	var _source: Vector2 ## source position
	var _target: Vector2 ## target position
	var _item: Item ## item to be transported
	var _amount: int ## amount of the item
	var _weight: float ## weight of the task

	func _init(source: Vector2, target: Vector2, item: Item, amount: int):
		_source = source
		_target = target
		_item = item
		_amount = amount
		_weight = item.weight * amount
	
	func get_source() -> Vector2:
		return _source

	func get_target() -> Vector2:
		return _target

	func copy() -> Task:
		return Task.new(_source, _target, _item, _amount)
	
	func is_equal(other: Task) -> bool:
		return _source == other._source and _target == other._target and _item == other._item and _amount == other._amount

class Drone:
	var _id: int = 0
	var is_active: bool = false
	var current_task: Task = null
	var capacity: float = 10.0

	var _speed: float = 150.0
	var velocity: Vector2 = Vector2(0, 0)
	var position: Vector2 = Vector2(0, 0)
	var destination: Vector2 = Vector2(0, 0)


	func _init(id: int):
		_id = id

	func move_to(delta: float):
		velocity = (destination - position).normalized() * delta * _speed
		position += velocity

	func assign_task(task: Task):
		current_task = task
		is_active = true
		destination = task.get_target()
		position = task.get_source()

	func complete_task():
		current_task = null
		is_active = false

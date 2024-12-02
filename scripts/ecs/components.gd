class_name Comps extends RefCounted

#region 电力

class ElectricGenerator extends ECS.Component:
	var power_rate: float
	var efficiency: float = 1

	func _init(_power_rate: float = 6):
		self.power_rate = _power_rate

class ElectricConsumer extends ECS.Component:
	var power_rate: float
	var efficiency: float = 1

	enum State { IDLE=1, WORKING=10 }
	var current_state: State = State.IDLE

	func _init(_power_rate: float = 3):
		self.power_rate = _power_rate

class Battery extends ECS.Component:
	var capacity: float
	var storage: float = 0
	var power_rate: float

	enum State { EMPTY, CHARGING, DISCHARGING, FULL }
	signal state_changed(state: State)
	var current_state: State = State.EMPTY:
		set(value):
			current_state = value
			state_changed.emit(value)

	func _init(_capacity: float = 120, _power_rate: float = 9):
		self.capacity = _capacity
		self.power_rate = _power_rate


#region 生产

class Producer extends ECS.Component:
	var progress: float = 0
	var recipe: Recipe = null
	
	enum State { IDLE, WORKING }
	var current_state: State = State.IDLE:
		set(value):
			current_state = value
			state_changed.emit(value)
	signal state_changed(state: State)

	enum WorkState { NORMAL, INSUFFICIENT_RESOURCES, INSUFFICIENT_SPACE }
	var work_state: WorkState = WorkState.NORMAL:
		set(value):
			work_state = value
			work_state_changed.emit(value)
	signal work_state_changed(state: WorkState)

	func set_recipe(_recipe: Recipe):
		self.recipe = _recipe
		self.progress = 0

	func reset():
		progress = 0
		current_state = State.IDLE
		work_state = WorkState.NORMAL
		self.recipe = null


#region 物品

class Inventory extends ECS.Component:
	var inventory: Dictionary = {}

	func add_item(item: Item, amount: float):
		if inventory.has(item):
			inventory[item] += amount
		else:
			inventory[item] = amount

	func remove_item(item: Item, amount: float):
		if inventory.has(item):
			inventory[item] -= amount
			if inventory[item] <= 0:
				inventory.erase(item)

	func has_item(item: Item, amount: float = 1) -> bool:
		if inventory.has(item):
			return inventory[item] >= amount
		return false

	func get_item_amount(item: Item) -> float:
		return inventory.get(item, 0)


class InputDepot extends Inventory:
	pass

class OutputDepot extends Inventory:
	pass

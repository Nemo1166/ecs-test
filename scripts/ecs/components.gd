class_name Comps extends RefCounted

class ElectricGenerator extends ECS.Component:
	var power_rate: float
	var efficiency: float = 1

	func _init(_power_rate: float = 6):
		self.power_rate = _power_rate


class ElectricConsumer extends ECS.Component:
	var power_rate: float

	func _init(_power_rate: float = 3):
		self.power_rate = _power_rate


class Battery extends ECS.Component:
	var capacity: float
	var power_rate: float

	func _init(_capacity: float = 120, _power_rate: float = 9):
		self.capacity = _capacity
		self.power_rate = _power_rate


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
	var orders: Array = []
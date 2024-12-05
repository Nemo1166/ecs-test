class_name PowerSystem extends ECS.System


var global_efficiency: float = 1.0
var global_charge_efficiency: float = 1.0

var available_power: float = 0
var power_supply_rate: float = 0:
	set(value):
		if value != power_supply_rate:
			power_supply_rate = value
			_world.event_bus.emit("power_supply_rate_changed", power_supply_rate)

var total_generation: float = 0
var total_consumption: float = 0
var total_charge: float = 0
var total_storage: Vector2 = Vector2.ZERO # [current, capacity]

func update(delta: float) -> void:
	# get all entities
	var ent_ids: Array = _world.ent_mgr.get_all_entity_ids()
	var batteries: Array[int] = []
	# collect power supply and consumption
	total_generation = 0
	total_consumption = 0
	total_charge = 0
	total_storage = Vector2.ZERO
	for ent_id: int in ent_ids:
		var consumer: Comps.ElectricConsumer = _world.ent_mgr.get_component(ent_id, "ElectricConsumer")
		if consumer != null:
			total_consumption += consumer.power_rate * consumer.efficiency * (float(consumer.current_state)*0.01)
		var generator: Comps.ElectricGenerator = _world.ent_mgr.get_component(ent_id, "ElectricGenerator")
		if generator != null:
			total_generation += generator.power_rate * generator.efficiency
		if _world.ent_mgr.has_component(ent_id, "Battery"):
			batteries.append(ent_id)
	# calculate power supply
	available_power = total_generation * global_efficiency - total_consumption
	if available_power < 0:
		# not enough power, batteries will be discharged
		for ent_id in batteries:
			var battery: Comps.Battery = _world.ent_mgr.get_component(ent_id, "Battery")
			if battery.current_state != Comps.Battery.State.EMPTY:
				var charge = min(-available_power * delta, battery.power_rate * delta * global_charge_efficiency)
				var actual_charge = battery_charge(battery, -charge)
				total_charge += actual_charge
				total_storage += Vector2(battery.storage, battery.capacity)
				# update power supply
				available_power += battery.power_rate * global_charge_efficiency
				if available_power >= 0:
					break
	else:
		# enough power, batteries will be charged
		for ent_id in batteries:
			var battery: Comps.Battery = _world.ent_mgr.get_component(ent_id, "Battery")
			if battery.current_state != Comps.Battery.State.FULL:
				var charge = min(available_power * delta, battery.power_rate * delta * global_charge_efficiency)
				var actual_charge = battery_charge(battery, charge)
				total_charge += actual_charge
				total_storage += Vector2(battery.storage, battery.capacity)
				# update power supply
				available_power -= battery.power_rate * global_charge_efficiency
				if available_power <= 0:
					break
	# count empty/full batteries
	for ent_id in batteries:
		var battery: Comps.Battery = _world.ent_mgr.get_component(ent_id, "Battery")
		if battery.current_state == Comps.Battery.State.EMPTY:
			total_storage += Vector2(0, battery.capacity)
		elif battery.current_state == Comps.Battery.State.FULL:
			total_storage += Vector2(battery.capacity, battery.capacity)
	# update power supply rate
	power_supply_rate = clamp((available_power + total_consumption) / total_consumption, 0, 1)


func battery_charge(battery: Comps.Battery, amount: float) -> float:
	var charge = 0
	if amount > 0:
		# charging
		battery.current_state = Comps.Battery.State.CHARGING
		charge = min(amount, battery.capacity - battery.storage)
		battery.storage += charge
		if battery.storage >= battery.capacity:
			battery.current_state = Comps.Battery.State.FULL
	else:
		# discharging
		battery.current_state = Comps.Battery.State.DISCHARGING
		charge = min(-amount, battery.storage)
		battery.storage -= charge
		if battery.storage <= 0:
			battery.current_state = Comps.Battery.State.EMPTY
	return charge

func get_status() -> Dictionary:
	return {
		"total_generation": total_generation,
		"total_consumption": total_consumption,
		"total_charge": total_charge,
		"total_storage": total_storage,
		"power_supply_rate": power_supply_rate,
	}

func get_batteries_status() -> Array:
	var batteries_status: Array = [0,0,0,0] # N. of [empty, charging, discharging, full] batteries
	var ent_ids: Array = _world.ent_mgr.get_all_entity_ids()
	for ent_id: int in ent_ids:
		if _world.ent_mgr.has_component(ent_id, "Battery"):
			var battery: Comps.Battery = _world.ent_mgr.get_component(ent_id, "Battery")
			batteries_status[battery.current_state] += 1
	return batteries_status

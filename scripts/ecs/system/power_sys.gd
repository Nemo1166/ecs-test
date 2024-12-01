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
	var ent_ids: Array[int] = _world.ent_mgr.get_all_entity_ids()
	var batteries: Array[int] = []
	# collect power supply and consumption
	total_generation = 0
	total_consumption = 0
	total_charge = 0
	for ent_id in ent_ids:
		var consumer: Comps.ElectricConsumer = _world.ent_mgr.get_component(ent_id, "ElectricConsumer")
		if consumer != null:
			total_consumption += consumer.power_rate * consumer.efficiency
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
				var charge = battery.power_rate * delta * global_charge_efficiency
				battery.storage -= charge
				total_charge += charge
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
				var charge = battery.power_rate * delta * global_charge_efficiency
				battery.storage += charge
				total_charge += charge
				total_storage += Vector2(battery.storage, battery.capacity)
				if battery.storage > battery.capacity:
					battery.storage = battery.capacity
				# update power supply
				available_power -= battery.power_rate * global_charge_efficiency
				if available_power <= 0:
					break
	# update power supply rate
	power_supply_rate = clamp((available_power + total_consumption) / total_consumption, 0, 1)


func get_status() -> Dictionary:
	return {
		"total_generation": total_generation,
		"total_consumption": total_consumption,
		"total_charge": total_charge,
		"total_storage": total_storage,
		"power_supply_rate": power_supply_rate,
	}
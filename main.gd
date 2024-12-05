extends Node2D

var w: ECS.World
var sys_power: PowerSystem
var sys_prod: ProdSystem



func _ready() -> void:
	w = Global.ecs_world
	sys_power = w.add_system(PowerSystem.new(w))
	sys_prod = w.add_system(ProdSystem.new(w))
	w.add_system(LogisticSystem.new(w))
	var tick = Time.get_ticks_msec()
	#for i in range(1000):
		#build_factory()
	for i in range(1):
		build_generator()
	for i in range(10):
		build_battery()
	var tock = Time.get_ticks_msec()
	print('Time to create entities: %d ms' % (tock - tick))


func _process(delta: float) -> void:
	w.update(delta)
	update_ui(delta)



func build_factory():
	var eid = w.create_entity()
	w.add_component(eid, 'ElectricConsumer', Comps.ElectricConsumer.new())
	w.add_component(eid, 'Producer', Comps.Producer.new())
	w.add_component(eid, 'Inventory', Comps.Inventory.new(1000))

func build_generator():
	var eid = w.create_entity()
	w.add_component(eid, 'ElectricGenerator', Comps.ElectricGenerator.new())

func build_battery():
	var eid = w.create_entity()
	w.add_component(eid, 'Battery', Comps.Battery.new())


func update_ui(delta: float) -> void:
	%NofEnts.text = 'N. of entities: %d' % w.get_entity_count()
	%PowerStat.text = 'Generation: %.2f\nConsumption: %.2f\nCharge: %.2f\nStorage: %.2f/%.2f' % [
		sys_power.total_generation, sys_power.total_consumption, sys_power.total_charge / delta, sys_power.total_storage.x, sys_power.total_storage.y]
	var battery_stat = sys_power.get_batteries_status() # N. of [empty, charging, discharging, full] batteries
	%BtyStat.text = 'Batteries:\n- Empty: %d\n- Charging: %d\n- Discharging: %d\n- Full: %d' % battery_stat

var num_wood_miner := 0
func _on_button_pressed() -> void:
	var factory = Global.FACTORY.instantiate()
	add_child(factory)
	factory.put(Vector2(100, 150 + 120 * num_wood_miner))
	factory.set_recipe(Global.wood_mining)
	num_wood_miner += 1

var num_stone_miner := 0
func _on_button_2_pressed() -> void:
	var factory = Global.FACTORY.instantiate()
	add_child(factory)
	factory.put(Vector2(240, 150 + 120 * num_stone_miner))
	factory.set_recipe(Global.stone_mining)
	num_stone_miner += 1


func _on_button_3_pressed() -> void:
	build_generator()

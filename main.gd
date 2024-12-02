extends Node2D

var w: ECS.World = ECS.World.new('main')
var sys_power: PowerSystem
var sys_prod: ProdSystem



func _ready() -> void:
	sys_power = w.add_system(PowerSystem.new(w))
	sys_prod = w.add_system(ProdSystem.new(w))
	var tick = Time.get_ticks_msec()
	for i in range(1000):
		build_factory()
	for i in range(10):
		build_generator()
	for i in range(100):
		build_battery()
	var tock = Time.get_ticks_msec()
	print('Time to create entities: %d ms' % (tock - tick))


func _process(delta: float) -> void:
	w.update(delta)
	update_ui(delta)



func build_factory():
	var e: ECS.Entity = w.ent_mgr.create_entity()
	var id = e._entity_id
	w.ent_mgr.add_component(id, 'ElectricConsumer', Comps.ElectricConsumer.new())
	w.ent_mgr.add_component(id, 'Producer', Comps.Producer.new())
	w.ent_mgr.add_component(id, 'InputDepot', Comps.InputDepot.new())
	w.ent_mgr.add_component(id, 'OutputDepot', Comps.OutputDepot.new())

func build_generator():
	var e: ECS.Entity = w.ent_mgr.create_entity()
	var id = e._entity_id
	w.ent_mgr.add_component(id, 'ElectricGenerator', Comps.ElectricGenerator.new())

func build_battery():
	var e: ECS.Entity = w.ent_mgr.create_entity()
	var id = e._entity_id
	w.ent_mgr.add_component(id, 'Battery', Comps.Battery.new())


func update_ui(delta: float) -> void:
	%NofEnts.text = 'N. of entities: %d' % w.ent_mgr.entities.size()
	%PowerStat.text = 'Generation: %.2f\nConsumption: %.2f\nCharge: %+.2f\nStorage: %.2f/%.2f' % [
		sys_power.total_generation, sys_power.total_consumption, sys_power.total_charge / delta, sys_power.total_storage.x, sys_power.total_storage.y]
	var battery_stat = sys_power.get_batteries_status() # N. of [empty, charging, discharging, full] batteries
	%PSR.text = 'Power Supply rate: %.2f%%' % (sys_power.power_supply_rate * 100)
	%BtyStat.text = 'Batteries:\n- Empty: %d\n- Charging: %d\n- Discharging: %d\n- Full: %d' % battery_stat

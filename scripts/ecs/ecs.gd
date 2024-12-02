class_name ECS extends RefCounted


class World extends RefCounted:
	var _name: String = ""
	var debug_mode: bool = false

	func _init(name: String) -> void:
		_name = name
	# region 实体管理
	var ent_mgr: EntityManager = EntityManager.new(self)

	#region 系统管理
	var systems: Array[System] = []

	## 添加系统
	func add_system(system: System) -> System:
		systems.append(system)
		return system

	## 移除系统
	func remove_system(system: System) -> void:
		if systems.has(system):
			systems.erase(system)

	## 更新系统
	func update(delta: float) -> void:
		ent_mgr.update()
		for system in systems:
			system.update(delta)

	#region 事件管理
	var event_bus: EventBus = EventBus.new()

	## 清空世界
	func clear() -> void:
		ent_mgr.entities.clear()
		systems.clear()

class Entity extends RefCounted:
	var _entity_id: int = 0
	var tags: Array = []
	var components: Dictionary = {}

	func _init(_id) -> void:
		_entity_id = _id


class EntityManager extends RefCounted:
	var _world: World = null
	var _entity_id: int = 0
	var entities: Dictionary = {}
	var entities_to_destroy: Array[int] = []

	func _init(world: World) -> void:
		_world = world
	
	func update() -> void:
		for ent_id in entities_to_destroy:
			if entities.has(ent_id):
				entities.erase(ent_id)

	## 创建实体
	func create_entity() -> Entity:
		var ent = Entity.new(_entity_id)
		entities[_entity_id] = ent
		_entity_id += 1
		return ent

	## 移除实体
	func remove_entity(ent_id: int) -> bool:
		if entities.has(ent_id):
			entities_to_destroy.append(ent_id)
			return true
		return false

	## 获取实体
	func get_entity(ent_id: int) -> Entity:
		if entities.has(ent_id):
			return entities[ent_id]
		return null

	## 添加组件
	func add_component(ent_id: int, comp_name: String, comp: Component) -> void:
		if entities.has(ent_id):
			entities[ent_id].components[comp_name] = comp

	## 移除组件
	func remove_component(ent_id: int, comp_name: String) -> void:
		if entities.has(ent_id):
			if entities[ent_id].components.has(comp_name):
				entities[ent_id].components.erase(comp_name)

	## 获取组件
	func get_component(ent_id: int, comp_name: String) -> Component:
		if entities.has(ent_id):
			if entities[ent_id].components.has(comp_name):
				return entities[ent_id].components[comp_name]
		return null
	
	## 是否有组件
	func has_component(ent_id: int, comp_name: String) -> bool:
		if entities.has(ent_id):
			return entities[ent_id].components.has(comp_name)
		return false

	## 获取所有实体
	func get_all_entity_ids(tag: String = '') -> Array:
		if tag != '':
			var ids: Array[int] = []
			for ent_id in entities.keys():
				if entities[ent_id].tags.has(tag):
					ids.append(ent_id)
			return ids
		return entities.keys()


class System extends RefCounted:
	var _world: World = null

	func _init(world: World) -> void:
		_world = world

	# override
	func update(_delta: float) -> void:
		pass


class Component extends RefCounted:
	func _init() -> void:
		pass


class EventBus extends RefCounted:
	var _listeners: Dictionary = {}

	func _init() -> void:
		_listeners = {} # event_name: [listener, method]

	func add_listener(event_name: String, listener: Object, method: String) -> void:
		if not _listeners.has(event_name):
			_listeners[event_name] = []
		_listeners[event_name].append([listener, method])

	func remove_listener(event_name: String, listener: Object, method: String) -> void:
		if _listeners.has(event_name):
			for i in range(_listeners[event_name].size()):
				if _listeners[event_name][i][0] == listener and _listeners[event_name][i][1] == method:
					_listeners[event_name].erase(i)
					break

	func emit(event_name: String, data: Variant = null) -> void:
		if _listeners.has(event_name):
			for listener in _listeners[event_name]:
				listener[0].call(listener[1], data)

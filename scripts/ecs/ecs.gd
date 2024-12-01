class_name ECS extends RefCounted


class World extends RefCounted:
    var _name: String = ""
    var ent_mgr: EntityManager = EntityManager.new(self)
    var systems: Array[System] = []

    var debug_mode: bool = false

    func _init(name: String) -> void:
        _name = name

    ## 添加系统
    func add_system(system: System) -> void:
        systems.append(system)

    ## 移除系统
    func remove_system(system: System) -> void:
        if systems.has(system):
            systems.erase(system)

    ## 更新系统
    func update(delta: float) -> void:
        for system in systems:
            system.update(delta)

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

    func _init(world: World) -> void:
        _world = world

    ## 创建实体
    func create_entity() -> Entity:
        var ent = Entity.new(_entity_id)
        entities[_entity_id] = ent
        _entity_id += 1
        return ent

    ## 移除实体
    func remove_entity(ent_id: int) -> bool:
        if entities.has(ent_id):
            entities.erase(ent_id)
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

    ## 获取所有实体
    func get_all_entity_ids() -> Array[int]:
        return entities.keys()


class System extends RefCounted:
    var _world: World = null

    func _init(world: World) -> void:
        _world = world
    # override
    func update(_delta: float) -> void:
        pass
    
    func get_all_entities() -> Array[Entity]:
        return _world.entities.values()


class Component extends RefCounted:
    func _init() -> void:
        pass


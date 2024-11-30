class_name ECS extends RefCounted


class World extends RefCounted:
    var _name: String = ""
    var _entity_id: int = 0
    var entities: Dictionary = {}
    var systems: Array[System] = []

    var debug_mode: bool = false

    func _init(name: String) -> void:
        _name = name

    ## 创建实体
    func create_entity() -> Entity:
        var e = Entity.new(_entity_id)
        _entity_id += 1
        return e

    ## 移除实体
    func remove_entity(ent_id: int) -> void:
        if entities.has(ent_id):
            entities.erase(ent_id)

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
        entities.clear()
        systems.clear()

class Entity extends RefCounted:
    var _entity_id: int = 0
    var components: Dictionary = {}

    func _init(_id) -> void:
        _entity_id = _id

    ## 添加组件
    func add_component(component_name: String, component: Object) -> void:
        components[component_name] = component

    ## 移除组件
    func remove_component(component_name: String) -> void:
        components.erase(component_name)

    ## 获取组件
    func get_component(component_name: String) -> Object:
        return components.get(component_name, null)

    ## 检查是否包含某个组件
    func has_component(component_name: String) -> bool:
        return components.has(component_name)


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


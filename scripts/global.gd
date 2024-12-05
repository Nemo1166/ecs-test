extends Node

var ecs_world: ECS.World = ECS.World.new('main')


const FACTORY = preload("res://scenes/factory.tscn")
const DRONE = preload("res://scenes/drone.tscn")


var wood_mining = load("res://data/mining_wood.tres")
var stone_mining = load("res://data/mining_stone.tres")

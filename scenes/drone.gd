extends CharacterBody2D

@export var drone_id: int = -1

func _ready() -> void:
	pass

#region 物流交互


#region 状态机

func change_luminance(color: Color = Color(1,0,2,1)):
	$Sprite2D.material.set_shader_parameter("outline_color", color)

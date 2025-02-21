extends Node3D

var player_inside : bool = false

@onready var marker : Marker3D = $Marker3D
var point : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	point = marker.global_position

func _on_area_3d_body_entered(_body: Node3D) -> void:
	player_inside = true
	get_parent().upt_dic()

func _on_area_3d_body_exited(_body: Node3D) -> void:
	player_inside = false
	get_parent().upt_dic()

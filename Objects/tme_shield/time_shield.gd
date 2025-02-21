extends Node3D

class_name throwable

@export var grenade = load("res://Objects/tme_shield/time_shield_object.tscn")

@onready var marker : Marker3D = $Marker3D
@onready var Protation : Camera3D
@onready var sound_player = $AudioListener3D

func _ready() -> void:
	var node = self
	while node is not Camera3D:
		node = node.get_parent()
		if node is Base_Player:
			break
	Protation = node
	
@rpc("any_peer","call_local")
func Throw(_id : int):
	var tmp : RigidBody3D = grenade.instantiate()
	var pos : Vector3 = marker.global_position
	tmp.position = pos
	$Node.add_child(tmp)
	
	var force = -25
	var upDirection = 3.5
	
	var PLayerRotation = Protation.global_transform.basis.z.normalized()
	tmp.apply_central_impulse(PLayerRotation*force+Vector3(0,upDirection,0))
	play_sound3D.rpc(GlobalScript.Weapons[2]["reload_sound"])


#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local", "unreliable")
func play_sound3D(sound_key:String) ->void:
		sound_player.max_db = GlobalScript.Volume
		sound_player.stream=load(sound_key)
		sound_player.play()

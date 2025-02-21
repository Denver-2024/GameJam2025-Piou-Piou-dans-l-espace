extends RigidBody3D

@export var team : int = 0
@export var weapon : int = 2
@onready var sound_player = $AudioStreamPlayer3D
@onready var shape = $Area3D/MeshInstance3D
@onready var collision = $Area3D/CollisionShape3D

var old_velo : Vector3 = Vector3(0,0,0)

func _ready() -> void:
	collision.disabled = true

func _on_body_entered(body: Node) -> void:
	print(body)
	if body is CollisionShape3D:
		if body.get_collision_value(7):
			old_velo = linear_velocity
			linear_velocity = linear_velocity/10
			gravity_scale = 0.0
		else:
			linear_damp = 0.3
			angular_damp = 1.5
	else:
		linear_damp = 0.3
		angular_damp = 1.5

func _on_body_exited(body: Node) -> void:
	if body is CollisionShape3D:
		if body.get_collision_value(7):
			linear_velocity = old_velo
			gravity_scale = 9.8
			
func _on_timer_timeout() -> void:
	linear_velocity = Vector3(0,0,0)
	collision.disabled = false
	shape.visible = true
	await get_tree().create_timer(6.0).timeout
	queue_free()
	
#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local", "unreliable")
func play_sound3D(sound_key:String) ->void:
		sound_player.max_db = GlobalScript.Volume
		sound_player.stream=load(sound_key)
		sound_player.play()

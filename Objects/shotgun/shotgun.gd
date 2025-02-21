extends Node3D

var bullets = load("res://Objects/bullet.tscn")

@onready var raycast : RayCast3D = $RayCast3D
@onready var particle : GPUParticles3D = $GPUParticles3D

@onready var player = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

@rpc("any_peer", "call_local")
func play_shoot_effect(id:int, is_aiming : bool):
	if id != player.name.to_int(): return
	particle.emitting = true
	var alpha = 0.0
	if is_aiming == true:
		alpha = 5.0
	for i in range(11):
		var dispertion = GlobalScript.Weapons[3]["dispertion"]-alpha
		var rotX = deg_to_rad(randf_range(90-dispertion, 90+dispertion))
		var rotY = deg_to_rad(randf_range(0-dispertion,dispertion))
		raycast.set_rotation(Vector3(rotX, rotY, 0))
					
		var bullet: Bullet = bullets.instantiate()
		bullet.position = raycast.global_position
		bullet.speed = GlobalScript.Weapons[3]["bullet_speed"]
		bullet.my_team = GlobalScript.Players[id]["team"]
		bullet.weapon = 3
		bullet.transform.basis = raycast.global_transform.basis
		$Node.add_child(bullet)
	play_sound3D.rpc(GlobalScript.Weapons[3]["shoot_sound"])

#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local", "unreliable")
func play_sound3D(sound_key:String) ->void:
		sound_player.stream=load(sound_key)
		sound_player.max_db = GlobalScript.Volume
		sound_player.play()

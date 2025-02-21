extends Node3D

var bullets = load("res://Objects/bullet.tscn")

@onready var raycast : RayCast3D = $RayCast3D
@onready var particle : GPUParticles3D = $GPUParticles3D

@onready var player : Base_Player = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

@rpc("any_peer", "call_local")
func play_shoot_effect(id:int, _is_aiming : bool):
	if id != player.name.to_int(): return
	var tpm = -60.0
	if _is_aiming == true:
		tpm = -30.0
	
	for i in range(9):
		print(tpm+(i*abs(2*tpm/8)))
		raycast.set_rotation(Vector3(deg_to_rad(90), deg_to_rad(tpm+(i*abs(2*tpm/8))), 0))
		particle.emitting = true
		var bullet: Bullet = bullets.instantiate()
		bullet.position = raycast.global_position
		bullet.speed = GlobalScript.Weapons[5]["bullet_speed"]
		bullet.my_team = GlobalScript.Players[id]["team"]
		bullet.weapon = 0
		bullet.transform.basis = raycast.global_transform.basis
		$Node.add_child(bullet)
		#play_sound3D.rpc(GlobalScript.Weapons[0]["shoot_sound"])
	#
##Fonction pour déclencher un son de manière synchronisée
#@rpc("any_peer", "call_local", "unreliable")
#func play_sound3D(sound_key:String) ->void:
		#sound_player.stream=load(sound_key)
		#sound_player.max_db = GlobalScript.Volume
		#sound_player.play()

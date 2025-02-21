extends Node3D

var bullets = load("res://Objects/laser_weapon/laser.tscn")

@onready var raycast : RayCast3D = $RayCast3D
@onready var particle : GPUParticles3D = $GPUParticles3D

@onready var player : Base_Player = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

@rpc("any_peer", "call_local")
func play_shoot_effect(id:int, _is_aiming : bool):
	if id != player.name.to_int(): return
	if _is_aiming == false:
					##les prochaines lignes servent à créer une dispertion aléatoire des balles
		var dispertion = GlobalScript.Weapons[0]["dispertion"]
		var rotX = deg_to_rad(randf_range(90-dispertion, 90+dispertion))
		var rotY = deg_to_rad(randf_range(0-dispertion,dispertion))
		raycast.set_rotation(Vector3(rotX, rotY, 0))
	else:
		raycast.set_rotation(Vector3(deg_to_rad(90), 0, 0))
		
	particle.emitting = true
	var bullet: Laser = bullets.instantiate()
	bullet.position = raycast.global_position
	#bullet.speed = GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["bullet_speed"]
	bullet.speed = GlobalScript.Weapons[0]["bullet_speed"]
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

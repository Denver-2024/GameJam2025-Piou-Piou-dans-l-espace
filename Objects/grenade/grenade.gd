extends RigidBody3D

@onready var wide : Area3D = $Area3D
@export var team : int = 0
@export var weapon : int = 2
@onready var sound_player = $AudioStreamPlayer3D

func _on_body_entered(_body: Node) -> void:
	linear_damp = 0.3
	angular_damp = 1.5
	
func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	var bodies = wide.get_overlapping_bodies()
	for obj in bodies:
		if obj is CharacterBody3D:
			if obj.get_collision_layer_value(1) == true:
				var rayParams = PhysicsRayQueryParameters3D.create(global_transform.origin, obj.global_transform.origin)
				var result = get_world_3d().direct_space_state.intersect_ray(rayParams)
				var check = result["collider"]
				if check is CharacterBody3D:
					obj.get_node("Health_component").damage.rpc_id(obj.get_multiplayer_authority(), multiplayer.get_unique_id(), weapon)
					get_parent().hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
			elif obj.get_collision_layer_value(6) == true:
				var rayParams = PhysicsRayQueryParameters3D.create(global_transform.origin, obj.global_transform.origin)
				var result = get_world_3d().direct_space_state.intersect_ray(rayParams)
				var check = result["collider"]
				if check is CharacterBody3D:
					obj.get_node("Health_component").damage.rpc_id(obj.get_multiplayer_authority(), weapon)
					get_parent().hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
	$grenade.hide()
	await get_tree().create_timer(1.0).timeout
	queue_free()
	play_sound3D.rpc(GlobalScript.Weapons[2]["shoot_sound"])
	
#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local", "unreliable")
func play_sound3D(sound_key:String) ->void:
		sound_player.max_db = GlobalScript.Volume
		sound_player.stream=load(sound_key)
		sound_player.play()

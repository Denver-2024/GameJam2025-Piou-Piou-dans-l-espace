extends Node3D


@onready var raycast : RayCast3D = $RayCast3D

@onready var player : Base_Player = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var anim : AnimationPlayer = $laser_mining_model.get_node("AnimationPlayer")
@onready var laser_path

var laser_active = false
var laser_length = 0.0
var laser_max_length = 100.0

func _ready() -> void:
	set_process(true)

@rpc("any_peer", "call_local")
func play_shoot_effect(_id:int, _is_aiming : bool):
	if !laser_active:
		laser_active = true
		create_laser()
	
# Fonction appelée à chaque frame
func _process(_delta):
	if player.get_node("camera/Camera3D/Weapon_manager").current_ammo > 0 and player.get_node(""):
		# Créer le laser (par exemple, un MeshInstance3D avec une forme de cylindre)
		update_laser()
	else:
		if laser_active:
			laser_active = false
			# Supprimer le laser
			remove_laser()

func create_laser():
	var laser = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	laser.name = "Laser"
	mesh.bottom_radius = 0.15
	mesh.top_radius = 0.15
	mesh.height = 1.0
	laser.mesh = mesh
	$Node.add_child(laser)
	laser_path = self.get_node("Node/Laser")
	
# Fonction pour mettre à jour le laser
func update_laser():
	if raycast.is_colliding():
		laser_length = raycast.get_collision_point().distance_to(raycast.global_position)
		if raycast.get_collider() is CharacterBody3D: #si il y a une collision avec un joueur		
			if raycast.get_collider().get_collision_layer_value(1) == true: #si le joueur a une collision Layer de 1
				var player_hitted = raycast.get_collider() #on réccupère le node du joueur touché
				if GlobalScript.Players[int(String(player_hitted.name))]["team"] == GlobalScript.Players[multiplayer.get_unique_id()]["team"] : return
							#cette ligne fait appel à la fonction "damage" qui se trouve dans le health component du joeuur touché et seulement pour ce joueur 
				if player_hitted.get_multiplayer_authority() != multiplayer.get_multiplayer_authority():
					player_hitted.get_node("Health_component").damage.rpc_id(player_hitted.get_multiplayer_authority(), multiplayer.get_unique_id(), 7)
					get_parent().get_parent().get_node("Weapon_manager").hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
			
		elif raycast.get_collider().get_collision_layer_value(6) == true:
			raycast.get_collider().get_parent().get_parent().get_parent().damage.rpc(multiplayer.get_unique_id(), 7)
			get_parent().get_parent().get_parent().get_parent().get_node("Weapon_manager").hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
		
	else:
		laser_length = laser_max_length
	
	var laser = laser_path
	if laser and laser_active:
		var mesh = laser.mesh as CylinderMesh
		mesh.height = laser_length/2
		laser.position = raycast.global_position
		laser.transform.basis = raycast.global_transform.basis
		laser.translate(Vector3(0,-laser_length/4,0))

# Fonction pour supprimer le laser
func remove_laser():
	if laser_path:
		laser_path.queue_free()
		
#Fonction pour déclencher un son de manière synchronisée
#@rpc("any_peer", "call_local", "unreliable")
#func play_sound3D(sound_key:String) ->void:
		#sound_player.stream=load(sound_key)
		#sound_player.max_db = GlobalScript.Volume
		#sound_player.play()

extends Node3D

class_name Bullet #nom de classe

@export var weapon : int = 0
@export var my_team : int = 0 #numéro de l'équipe du joeur qui a tiré cette balle
@export var speed : float = 75 #vitesse de la balle (qui est modifié selon l'arme utilisé)
@onready var mesh : MeshInstance3D = $MeshInstance3D #visuel de la balle, on peut la changer pour créer différent types de balles
@onready var ray : RayCast3D = $RayCast3D #raycast au bout de la balle
@onready var particle : GPUParticles3D = $GPUParticles3D #effet de particule de la balle
@onready var player : Base_Player = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()

var bullet_life : float = 5.0 # durrée de vie de la balle (5 secondes)
var old_speed = speed

func _ready() -> void:
	ray.add_exception(player)
	
	var alpha = abs(player.velocity.x)+abs(player.velocity.y)+abs(player.velocity.y)
	speed+=alpha
	old_speed+=alpha
	
func _physics_process(delta: float) -> void:
	#a chaque frame, la balle va se déplacer en suivant la direction donnée par le raycast de l'arme
	position += transform.basis * Vector3(0,-speed,0) * delta #change la position de la balle 
	if ray.is_colliding() and ray.get_collider() != null:
		if ray.get_collider() is CharacterBody3D: #si il y a une collision avec un joueur		
			if ray.get_collider().get_collision_layer_value(1) == true: #si le joueur a une collision Layer de 1
				var player_hitted = ray.get_collider() #on réccupère le node du joueur touché
				if GlobalScript.Players[int(String(player_hitted.name))]["team"] == GlobalScript.Players[multiplayer.get_unique_id()]["team"] : return
							#cette ligne fait appel à la fonction "damage" qui se trouve dans le health component du joeuur touché et seulement pour ce joueur 
				if player_hitted.get_multiplayer_authority() != multiplayer.get_multiplayer_authority():
					player_hitted.get_node("Health_component").damage.rpc_id(player_hitted.get_multiplayer_authority(), multiplayer.get_unique_id(), weapon)
					get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_node("Weapon_manager").hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
				
			mesh.hide()
			particle.emitting = true #effet de particule
			await get_tree().create_timer(1.0).timeout
			queue_free() #supprime la balle
			
		elif ray.get_collider().get_collision_layer_value(6) == true:
			ray.get_collider().get_parent().get_parent().get_parent().damage.rpc(multiplayer.get_unique_id(), weapon)
			get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_node("Weapon_manager").hitmarker() #on affiche le Hitmarker pour le joueur qui a touché un autre joueur
		
		elif ray.get_collider().get_collision_layer_value(7):
			speed = 2.0
			bullet_life+=delta
			
		elif ray.get_collider().get_collision_layer_value(3) or ray.get_collider().get_collision_layer_value(4) or ray.get_collider().get_collision_layer_value(5):
			#cette fonction est appelé si la balle touche n'importe quel décor ou objet
			mesh.hide()
			particle.emitting = true #effet de particule
			await get_tree().create_timer(1.0).timeout
			queue_free() #On supprime la balle
	else:
		speed = old_speed
	#dans le dernier des cas, si la balle ne touche rien
	bullet_life-= delta #on diminue le temps de vie de la balle
	if bullet_life <= 0: #si on est en dessous de son temps de vie
		queue_free() #on surpprime la balle

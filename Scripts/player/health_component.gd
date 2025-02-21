extends Node

class_name player_health_component

@onready var HP_bar : Label = get_parent().get_node("camera/Camera3D/HUD/CanvasLayer/health_bar") #s'affiche sur l'écran du joueur, c'est sa vie
@onready var G_manager : game_manager = get_parent().get_parent().get_node("Timer") #le game manager

@export var MAX_HEALTH : int = 100 #la vie maximum que l'on peut avoir
@export var health : int =100 : # la vie actuel du joueur 
	set(value):
		health=clamp(value,0,MAX_HEALTH) #bloque la variable health entre 0 et MAX_health
		health_changed(health)
		
@onready var hp_bar: Label3D = $"../Label3D" # bar de vie montré aux autres joueurs
@onready var PLAYER : CharacterBody3D = get_parent() # référence au joueur
@onready var HUD : player_HUD = $"../camera/Camera3D/HUD"

@export var alive_state : bool = true # parmet de savoir si le joueur est toujours en vie

var current_weapon = 0 #ID de l'arme actuel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if PLAYER.name.to_int() != multiplayer.get_unique_id() : return
	health = MAX_HEALTH #on met la vie du joueur a 100 (MAx_health)
	health_changed(health) #la fonction health_changed va mettre a jour les différents labels du joueur qui affiche sa vie
	
	if is_multiplayer_authority():
		hp_bar.hide() # le joueur ne peut pas voir sa propre bar de vie au dessus de lui

@rpc("any_peer", "call_remote")
func damage_show(damage_nb : int, _is_critical : bool):
	if PLAYER.name.to_int() == multiplayer.get_unique_id() : return
	var number = Label3D.new()
	var alpha = randf_range(-1.5, 1.5)
	if alpha < 0.6 and alpha > 0.0:
		alpha+=1.0
	elif alpha > -0.6 and alpha < 0.0:
		alpha-=1.0
	number.position = get_parent().position + Vector3(0, 2.5, alpha)
	number.font_size = 1
	number.name = "tpm"
	number.text = str(damage_nb)
	number.set_billboard_mode(BaseMaterial3D.BILLBOARD_FIXED_Y)
	number.visible = false
	get_parent().add_child(number)
	number.visible = true
	var anim = get_tree().create_tween()
	anim.tween_property(number, "font_size", 100, 0.06)
	await get_tree().create_timer(1.0).timeout
	get_parent().remove_child(number)
	
@rpc("any_peer")
func damage(shooter_id : int, weapon_used : int):
	#cette fonction sert a géré les dégats reçus par le joueur de la part d'autre joueur (shooter_id)
	if PLAYER.name.to_int() != multiplayer.get_unique_id() : return
	if PLAYER.game_state == "playing": #si on est en pleine partie 
		heal(-GlobalScript.Weapons[weapon_used]["damage"][1])
		G_manager.scores_players[shooter_id]["score"]+=10 #augmente le score du joueur qui a touché de n points
		G_manager.upt_score.rpc(shooter_id, G_manager.scores_players[shooter_id]["score"], 0, 0)
		damage_show.rpc(G_manager.scores_players[shooter_id]["score"], false)
		if health <= 0 and alive_state == true:
			#le joueur est déclaré mort (vie en dessous de 0, il était vivant)
			alive_state = false #on met a jour la variable qui permet de dire que le joueur est mort
			#affiche aux autres joueurs que le joueur est mort
			$"..".get_parent().get_node("UI/MarginContainer/VBoxContainer/HBoxContainer2/Panel/RichTextLabel").print_line.rpc(GlobalScript.Players[multiplayer.get_unique_id()]["name"] + " killed " + GlobalScript.Players[shooter_id]["name"])
			#met a jour les scores en conséquence
			G_manager.scores_players[shooter_id]["score"]+=100
			G_manager.scores_players[shooter_id]["kill"]+=1
			G_manager.scores_players[multiplayer.get_unique_id()]["death"]+=1
		
			G_manager.upt_score.rpc(shooter_id, G_manager.scores_players[shooter_id]["score"], G_manager.scores_players[shooter_id]["kill"], 0)
			G_manager.upt_score.rpc(multiplayer.get_unique_id(), 0, 0, G_manager.scores_players[multiplayer.get_unique_id()]["death"])
		HUD.player_hitted(alive_state)

@rpc("call_local")
func heal(healed_point):
	#fonction qui rend de la vie au joueur (ou lui retire en utilisant -)
	if PLAYER.name.to_int() != multiplayer.get_unique_id() : return
	health+=healed_point
	health_changed(health)
	
@rpc("call_local")
func set_temp_immortality(time:float):
	#fonction qui va rendre le joueur invincible temporairement
	if PLAYER.name.to_int() != multiplayer.get_unique_id() : return
	PLAYER.set_collision_layer_value(2, true)
	PLAYER.set_collision_layer_value(1, false)
	await get_tree().create_timer(time).timeout
	PLAYER.set_collision_layer_value(1, true)
	PLAYER.set_collision_layer_value(2, false)

func health_changed(new_health: int) -> void:
	#fonction qui va mettre a jour les labels
	if PLAYER.name.to_int() != multiplayer.get_unique_id() : return
	hp_bar.text= str(new_health)+"hp"
	HP_bar.text = str(new_health)+"hp"

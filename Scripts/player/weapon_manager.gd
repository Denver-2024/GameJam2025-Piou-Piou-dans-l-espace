extends Node

@onready var HUD : CanvasLayer = $"../HUD/CanvasLayer"
@onready var current_ammo_display : Label #référence au Label qui affiche le ombre de munitions dans le chargeur
@onready var Hitmarker : CenterContainer #référence au hitmarker
@onready var current_stock_display : Label #référence au label qui affiche le nombre de munitioons en stock
@onready var reticle : CenterContainer #référence au viseur
@onready var raycast : RayCast3D 
@onready var ANIMATIONPLAYER : AnimationPlayer = $"../../../Animations" #manager d'animation
@onready var player: Base_Player = $"../../.."
@onready var sound_player: sound_manager_player =$"../../../sound_manager_player"
@onready var particle : GPUParticles3D
@onready var WEAPONS : Node3D = $"../Path3D/PathFollow3D/WEAPONS"
@onready var Msync : MultiplayerSynchronizer = $"../../../MultiplayerSynchronizer"
@onready var weapon_name : Label #référence au label du nom de l'arme

var auto_shoot : bool = false #est ce que le joueur reste appuyé sur la touche tiré ? 
var _is_aiming : bool = false #est ce que le joueur vise ?
var _is_reloading : bool = false #est ce que le joueur recharge ?
var has_to_reload : bool = false
var can_shoot : bool = true #est ce que le joueur peut tirer ?
var sum : float = 0.0

signal auto_can_shoot

#inventaire
var dic_inventory = {
	1 :{"id_weapon" = -1,
		"ammo_load" = 0,
		"ammo_stock" = 0
	}, 
	2 : {"id_weapon" = -1,
		"ammo_load" = 0,
		"ammo_stock" = 0
	},
	#3 : {"id_weapon" = -1,
		#"ammo_load" = 0,
		#"ammo_stock" = 0},
	#4 : {"id_weapon" = -1,
		#"ammo_load" = 0,
		#"ammo_stock" = 0}
		}

var current_weapon : int = -1 #arme acutel en main
var current_ammo : int = 0 #munition dans le chargeur de l'arme actuel
var current_ammo_stock : int = 0 #munition en stock pour cette arme

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.get_unique_id() != player.name.to_int(): return
	current_ammo_display = HUD.get_node("HBoxContainer/Current_ammo")
	current_stock_display = HUD.get_node("HBoxContainer/current_stock")
	reticle = HUD.get_node("Reticle")
	Hitmarker = HUD.get_node("HitMarker")
	weapon_name = HUD.get_node("HBoxContainer/weapon_name")

func _process(delta: float) -> void:
	if current_weapon != -1:
		if !can_shoot:
			sum +=delta
		if sum >= GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["cadency"]:
			sum = 0
			can_shoot = !can_shoot
			auto_can_shoot.emit()
			
@rpc("any_peer", "call_local")
func change_weapon(case : int):
	#est appellé lorsque le joueur change d'arme
	if (case > dic_inventory.size()) or (dic_inventory[case]["id_weapon"] == -1) or (current_weapon == case):return
	else:
		if !WEAPONS.visible:
			WEAPONS.show()
		ANIMATIONPLAYER.play("change_weapon", -1, 3)
		await ANIMATIONPLAYER.animation_finished
		WEAPONS.get_node(str(case)).show()
		for n in WEAPONS.get_children():
			if n.name != str(case):
				n.hide()
		ANIMATIONPLAYER.play("change_weapon", -1, -3, true)
		
		current_weapon = case
		current_ammo = dic_inventory[current_weapon]["ammo_load"]
		current_ammo_stock = dic_inventory[current_weapon]["ammo_stock"]
		
		update_ammo(0)
		update_ammo_stock(0)
		
		if has_to_reload and GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "Obj":
			reload()

func aim(is_aiming : bool) -> void:
	if player.name.to_int() != multiplayer.get_unique_id() or WEAPONS.get_child_count() == 0 or current_weapon == -1: return
	if ANIMATIONPLAYER.current_animation == "change_weapon":
		await ANIMATIONPLAYER.animation_finished
	if _is_reloading == false and GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "Dist": 
		if is_aiming == true:
			ANIMATIONPLAYER.play("aim", -1, GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["aimspeed"])
			_is_aiming = true
			reticle.is_aiming = true
		elif is_aiming == false:
			ANIMATIONPLAYER.play("aim", -1, -GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["aimspeed"], true)
			_is_aiming = false
			reticle.is_aiming = false
	
func shoot():
	if player.name.to_int() != multiplayer.get_unique_id() or current_weapon == -1 or can_shoot == false: return
	if !ANIMATIONPLAYER.is_playing() and dic_inventory[current_weapon]["id_weapon"] != -1:
		if GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "Dist" and WEAPONS.get_node(str(current_weapon)).has_method("play_shoot_effect"):
			if current_ammo > 0 and _is_reloading == false:
					update_ammo(-1)
					WEAPONS.get_node(str(current_weapon)).play_shoot_effect.rpc(multiplayer.get_unique_id(), _is_aiming)
					can_shoot = false
					if GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["auto_shoot"] and auto_shoot:
						await auto_can_shoot
						shoot()
		
		if GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "obj":
			if current_ammo > 0 and _is_reloading == false:
				update_ammo(-1)
				WEAPONS.get_node(str(current_weapon)).Throw.rpc(multiplayer.get_unique_id())
				WEAPONS.hide()
				has_to_reload = true
				await get_tree().create_timer(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["cadency"]).timeout
				reload()
	
func reload():
	if player.name.to_int() != multiplayer.get_unique_id() : return	
	if !(current_ammo_stock > 0 and current_ammo < GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["ammo"]): return
	if _is_aiming == false and GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "Dist":
		_is_reloading = true
		ANIMATIONPLAYER.play("change_weapon", -1, 1.0/(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["reload_time"]/2))
		await get_tree().create_timer(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["reload_time"]/2).timeout
		
		if current_ammo_stock >= (GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["ammo"] - current_ammo):
			var rest = GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["ammo"] - current_ammo
			update_ammo_stock(-rest)
			update_ammo(rest)
			sound_player.play_sound3D.rpc(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["reload_sound"])
		else:
			update_ammo(current_ammo + current_ammo_stock)
			current_ammo_stock = 0
			dic_inventory[current_weapon]["ammo_stock"]=0
			update_ammo_stock(0)
		ANIMATIONPLAYER.play("change_weapon", -1, -1/(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["reload_time"]/2), true)
		await get_tree().create_timer(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["reload_time"]/2).timeout
		_is_reloading = false
		
	if GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["type"] == "obj":
		if current_ammo_stock > 0:
			update_ammo(1)
			update_ammo_stock(-1)
			WEAPONS.show()

	#sound_player.play_sound3D.rpc(GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["shoot_sound"])

func hitmarker():
	#cette fonction va afficher le "hitmarker" sur l'écran du joueur
	if player.name.to_int() != multiplayer.get_unique_id() : return
	Hitmarker.show()
	await get_tree().create_timer(0.1).timeout
	Hitmarker.hide()

func update_ammo(ammo : int):
	#cette fonction met à jour le chargeur actuelle de l'arme
	if player.name.to_int() != multiplayer.get_unique_id() or current_weapon == -1: return
	current_ammo+=ammo
	dic_inventory[current_weapon]["ammo_load"]+=ammo
	current_ammo_display.text = str(current_ammo)
	weapon_name.text = GlobalScript.Weapons[dic_inventory[current_weapon]["id_weapon"]]["name"]

	
@rpc("call_local")
func update_ammo_stock(ammo : int): 
	#Cette fonction met à jour le stock de munitions du joueur pour l'arme actuelle
	if player.name.to_int() != multiplayer.get_unique_id() or current_weapon == -1: return
	current_ammo_stock+=ammo
	current_stock_display.text = str(current_ammo_stock)
	dic_inventory[current_weapon]["ammo_stock"]+=ammo

func double_check_wepaons(id : int, type : int) -> int:
	#vérifie si le joueur porte déjà l'arme (type = 0)
	#ou vérifie que l'inventaire n'est pas vide (type = 1)
	if type == 0:
		for key in dic_inventory.keys():
			if dic_inventory[key]["id_weapon"] == id:
				#si il porte déjà l'arme
				return -1
		#sinon il ne la porte pas
		return 1
	elif type == 1:
		for key in dic_inventory.keys():
			if dic_inventory[key]["id_weapon"] == -1:
				#si l'inventaire n'est pas plein, la fonction renvoie le premier emplacement de libre
				return key
		#sinon l'inventaire est plein
		return -1
	print("Rien d'exécuté")
	return 0 

@rpc("any_peer", "call_local")
func unload_weapon()-> void:
	WEAPONS.remove_child(WEAPONS.get_node(str(current_weapon)))
	if current_weapon == -1: return
	dic_inventory[current_weapon]["id_weapon"] = -1
	dic_inventory[current_weapon]["ammo_load"] = 0
	dic_inventory[current_weapon]["ammo_stock"] = 0

@rpc("any_peer", "call_local")
func load_weapon(id : int) -> void:
	var wear = false
	#vérifie que l'arme n'est pas déjà chargé et ajouté au node WEAPONS
	if double_check_wepaons(id, 0) == -1: 
		#print("Possède déjà l'arme")
		return
	var check = double_check_wepaons(id, 1)
	if check == -1:
		ANIMATIONPLAYER.play("change_weapon", -1, 3.0)
		unload_weapon.rpc()
		wear = true
		#print("Retire l'arme")
		
	check = double_check_wepaons(id, 1)
	#charge l'arme demandé
	var tpm_scene = load(GlobalScript.Weapons[id]["model"])
	if tpm_scene == null:return
	var tpm = tpm_scene.instantiate()
	
	#ajoute l'arme et ses caractéristiques à l'inventaire
	tpm.name = str(check)
	dic_inventory[check]["id_weapon"] = id
	dic_inventory[check]["ammo_load"] = GlobalScript.Weapons[id]["ammo"]
	dic_inventory[check]["ammo_stock"] = 100
	tpm.hide()
	WEAPONS.add_child(tpm)
	
	if current_weapon == -1:
		change_weapon.rpc(check)
	
	if wear == true and current_weapon != -1:
		current_weapon = -1
		change_weapon.rpc(check)
	#print("L'arme ", GlobalScript.Weapons[id]["name"], " à été ajouté !")
	#print("Munition dans le chargeur : ", dic_inventory[check]["ammo_load"], " Munition en stock : ", dic_inventory[check]["ammo_stock"])

@rpc("any_peer", "call_local")
func clear_inventory():
	for n in WEAPONS.get_children():
		WEAPONS.remove_child(n)

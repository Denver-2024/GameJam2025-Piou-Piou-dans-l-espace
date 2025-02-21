extends CharacterBody3D

class_name Base_Player

@export var SPEED = 10.0 #Vitesse du joueur
@export var JUMP_VELOCITY = 7.0 #hauteur de saut
var MOUSE_SENSIVITY = GlobalScript.mouse_sensitivity #sensibilité de la souris
@export var TOGGLE_CROUCH : bool = false #option pour simple appui ou appui long pour se baisser
@onready var ANIMATIONPLAYER := $Animations #manager d'animation
@export_range(5, 10, 0.1) var CROUCH_SPEED : float = 7.0 #permet de régler la vitesse pour se baisser
@export var GRAVITY_FORCE : float = 1.0 #permet de régler la gravité
@export var CROUCH_SHAPECAST : ShapeCast3D #objet qui permet de savoir si il y a quelque chose au dessus du joueur, pour l'empêcher de se relever

@onready var HUD : player_HUD = $camera/Camera3D/HUD #référence au HUD
@onready var health_component : Node = $Health_component #référence au health component
@onready var Weapon_manager : Node = $camera/Camera3D/Weapon_manager #référence au weapon_manager
@onready var multiplayer_sync : MultiplayerSynchronizer= $MultiplayerSynchronizer #le multiplayer synchronizer
@onready var neck : Node3D = $camera #la camera suivant 'laxe x
@onready var camera : Camera3D = $camera/Camera3D #la camera suivant l'axe y 
@onready var UI : Control = get_parent().get_node("UI") #UI
@onready var interact_raycast : RayCast3D = $camera/Camera3D/interact_raycast #raycast pour interragir avec les objets comme les boutons
@export var auto_respawn : bool = false #autor respawun ou non ?
@onready var animations : AnimationPlayer = $camera/character/AnimationPlayer

#Pour le son
@onready var sound_player: sound_manager_player = $sound_manager_player

var respawn_pos = Vector3(0,1,0) #position de respawn
var _is_crouching : bool = false #est ce que le joueur se baisse ?
var _speed : float #vitesse du joueur
var exit_button : bool = false #est ce qu'on à déjà appuyer sur le bouton exit ?
var _is_beggining : bool = false #ets ce qu'on est au début d'une manche ?
var player_state : bool = true #est ce que le joueur est vivant ?

#mouvement de caméra un peu plus dynamique
const freq = 2.0
const ampl = 0.05
var t_bob = 0

#permet de se "souvenir" de l'avancement de la partie
var game_state : String = "None"
var state_machine : String = "None" #sert aux animations
@export var my_team : int = 0

@warning_ignore("unused_signal")
signal player_respawn(id)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int()) #donne l'autorité du node à cette instance

func _ready():
	
	#Cette fonction est appeler lorsque le node CharacterBody3D est instancié dans l'arbre principal
	#Elle n'est appelé qu'une seule fois
	if name.to_int() != multiplayer.get_unique_id(): return
	
	if is_multiplayer_authority(): #si on à l'autorité sur nos nodes enfants
		$pseudo.hide() #cache son propre pseudo pour lui
		$camera/character.hide() #cache son propre meshinstance pour lui
		
	CROUCH_SHAPECAST.add_exception($".") #le shapecast ne détecte pas les collisions avec le joueur lui-même
	_speed = SPEED #setup de la vitesse
	camera.current = true
	
	UI.get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Timer").hide() #cache le timer 
	UI.get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Manche").hide() #cache le label de manche
	
	self.set_collision_layer_value(2, true)
	self.set_collision_layer_value(1, false)
	
	var timer = get_parent().get_node("Timer")  # on cherche le node "Timer" dans l'arbre principale
	timer.connect("in_game", Callable(self, "change_pos")) #on connecte le signal "in_game" qui vient du node Timer de l'abre principale 
	await get_tree().create_timer(0.25).timeout #timer pour laisser le temps aux informations de se propager
	pseudo() #fonction qui va mettre a jour le pseudo du joueur
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #change le mode de capture de la souris

func _notification(what: int) -> void:
	#script si on ferme le jeu en utilisant la croix en haut a droite
	if what == NOTIFICATION_WM_CLOSE_REQUEST: #si l'OS demande de fermer l'application par la croix
		get_parent().exit_game(multiplayer.get_unique_id()) #on exécute la fonction exit_game du Lobby
		if multiplayer.is_server(): #si le joueuer est le serveur
			HUD.server_quit.rpc() #on prévient les autres joueurs que le serveur est partie

func _input(event):
	#gère toutes les entrées clavier / souris
	if name.to_int() != multiplayer.get_unique_id(): return #met en place la priorité du client sur son joueur
	#print("Player : ", multiplayer.get_unique_id(), " Mouse mode : ", Input.get_mouse_mode(), " HUD : ", HUD.menu_visible)
	if event.is_action_pressed("exit"): #appuyez sur [échap] pour ouvrir le menu pause
			# BUG ici pas rpc le pause
			if HUD.menu_visible == true and HUD.Pause_menu.visible == false:
				HUD.windows(false, "select_weapon")
				HUD.windows(false, "party_parameters")
			else:
				exit_button = !exit_button #permet de "switch" rappuyer sur exit pour fermer le menu
				if exit_button == true:
					#HUD.exit_pressed.rpc_id(multiplayer.get_unique_id()) #on s'assure que seul le joueur ayant appuyer sur exit voit le menu
					HUD.exit_pressed() #on s'assure que seul le joueur ayant appuyer sur exit voit le menu
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) #change le mode de la souris pour s'en servir dans les menu
				else:
					#HUD.Resume.rpc() #on appelle la fonction Resume dans le node HUD
					HUD.Resume() #on appelle la fonction Resume dans le node HUD
					
	if HUD.menu_visible == false: #si aucun menu n'est visible
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: #prend en compte les mouvements de la souris
			if event is InputEventMouseMotion: #prend en compte les entrées de la souris
				neck.rotate_y(-event.relative.x * MOUSE_SENSIVITY)
				camera.rotate_x(-event.relative.y * MOUSE_SENSIVITY)
				camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-40), deg_to_rad(70)) #on bloge la rotation de la caméra vers le haut et le bas
				
		if event.is_action_pressed("Crouch") and is_on_floor(): #si on appui sur la touche pour se baisser et qu'on est sur le sol
			match TOGGLE_CROUCH:
				true:
					toggle_crouch()
				false:
					crouching(true)
		
		if event.is_action_released("Crouch") and TOGGLE_CROUCH == false:
			if CROUCH_SHAPECAST.is_colliding() == false:
				crouching(false)
			elif CROUCH_SHAPECAST.is_colliding() == true:
				uncrouch_check()
		#Verifie que quand on vise, on ne recharge pas et il n'y a pas le menu de visible
		if event.is_action_pressed("aim") and Weapon_manager._is_reloading == false and HUD.menu_visible == false:
			Weapon_manager.aim(true)
		elif event.is_action_released("aim") and Weapon_manager._is_reloading == false:
			Weapon_manager.aim(false)
			
		if event.is_action_pressed("left_click") and HUD.menu_visible == false and (game_state == "None" or game_state == "playing"): #pour tirer
			Weapon_manager.auto_shoot = true
			Weapon_manager.shoot()
			
		if event.is_action_released("left_click"):
			Weapon_manager.auto_shoot = false
		
		#change la vitesse du joueur si il n'est pas baisser
		if _is_crouching == false:
			if event.is_action_pressed("sprint") and is_on_floor(): #il ne peut courir qu'au sol
				_speed = SPEED+5
			if event.is_action_released("sprint"): #sinon il va a vitesse normal
				_speed = SPEED
			
		if event.is_action_pressed("reload"):
			Weapon_manager.reload()
			state_machine = "is_reloading"
			
		if event.is_action_pressed("open_score") and HUD.Pause_menu.visible == false and game_state == "playing":
			HUD.Score.show()
		if event.is_action_released("open_score"):
			HUD.Score.hide()
		
		if event.is_action_pressed("interact"):
			var button_type = interact_raycast.get_collider()
			if button_type is StaticBody3D:
				if button_type.get_collision_layer_value(5) and button_type.has_method("_emit_signal"):
					button_type._emit_signal(multiplayer.get_unique_id())
		
		if event.is_action_pressed("weapon1"):
			Weapon_manager.change_weapon.rpc(1)
			state_machine = "change_weapon"
		if event.is_action_pressed("weapon2"):
			Weapon_manager.change_weapon.rpc(2)
			state_machine = "change_weapon"
		if event.is_action_pressed("weapon3"):
			Weapon_manager.change_weapon.rpc(3)
			state_machine = "change_weapon"
	if velocity == Vector3.ZERO:
		_animation.rpc("ArmatureAction_001")
	else:
		_animation.rpc("ArmatureAction")
		
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if health_component.alive_state == false:
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		if !HUD.Death_screen.visible:
			HUD._on_death.rpc(auto_respawn)
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta * GRAVITY_FORCE
			
		# Handle jump.
		if Input.is_action_just_pressed("jump") and _is_crouching == false and is_on_floor(): #permet de sauter
			velocity.y = JUMP_VELOCITY
			sound_player.play_sound3D.rpc("jump_sound")

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir
		var direction = Vector3.ZERO
		
		if !HUD.menu_visible and !_is_beggining:
			input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") #commandes pour bouger
			direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		else:
			input_dir = Vector2.ZERO

		if is_on_floor():
			if direction:
				velocity.x = direction.x * _speed
				velocity.z = direction.z * _speed
			else:
				velocity.x = move_toward(velocity.x, 0, _speed)
				velocity.z = move_toward(velocity.z, 0, _speed)
		else:
			#créer une chute plus naturel (pas d'arrêt en l'air)
			state_machine = "is_falling"
			velocity.x = lerp(velocity.x,direction.x * _speed, delta * 2.0)
			velocity.z = lerp(velocity.z,direction.z * _speed, delta * 2.0)
		#print(velocity)
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
		move_and_slide()

@rpc("any_peer", "call_local")
func _animation(Aname : String):
	animations.play(Aname)

func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * freq) * ampl
	pos.x = cos(time * freq/2) * ampl
	return pos+Vector3(0, 0.75, 0)
	
func toggle_crouch(): #fonction si on veut appuyer une seul fois pour se baisser
	if name.to_int() != multiplayer.get_unique_id(): return
	if _is_crouching == true and CROUCH_SHAPECAST.is_colliding() == false and is_on_floor():
		crouching(false)
	elif _is_crouching == false and is_on_floor():
		crouching(true)
		
func crouching(state : bool): #fonction qui permet de se baisser
	if name.to_int() != multiplayer.get_unique_id(): return
	match state:
		true :
			ANIMATIONPLAYER.play("Crouch", -1, CROUCH_SPEED)
			_speed = SPEED-5
			_is_crouching = true
			state_machine = "crouching"
		false:
			ANIMATIONPLAYER.play("Crouch", -1, -CROUCH_SPEED, true)
			_speed = SPEED
			_is_crouching = false
			state_machine = "walking"

func uncrouch_check(): #vérifie si il y a un obstacle au dessus du joueur
	if CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false)
	elif CROUCH_SHAPECAST.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func _on_crouch_animation_started(anim_name): #animation et changement d'état du joueur (accroupie <-> debout)
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching

func is_local_player() -> bool:
	return multiplayer_sync and multiplayer_sync.is_multiplayer_authority()

func pseudo():
	if name.to_int() != multiplayer.get_unique_id(): return
	$pseudo.text = GlobalScript.Players[multiplayer.get_unique_id()]["name"]

func _on_respawn():
	emit_signal("player_respawn", get_multiplayer_authority())
	self.set_collision_layer_value(1, true)
	self.set_collision_layer_value(2, false)
	health_component.heal(100)
	health_component.alive_state = true
	health_component.set_temp_immortality(8.0)
	self.position = respawn_pos

func change_pos(state):
	game_state = state
	match state:
		"start":
			Weapon_manager.clear_inventory.rpc()
			Weapon_manager.load_weapon.rpc(0)
			Weapon_manager.load_weapon.rpc(1)
			
			respawn_pos = GlobalScript.spawn_point[GlobalScript.Players[multiplayer.get_unique_id()]["team"]]
			
			self.position = respawn_pos
			UI.get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Timer").show()
			UI.get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Manche").show()
			
			#UI.get_node("party_parameters").hide() #cache les parametres pour ceux qui ne sont pas le joueur 1
			$pseudo.outline_modulate = Color(255, 255, 255)
			if GlobalScript.Players[multiplayer.get_unique_id()]["team"] == 1:
				$pseudo.modulate = Color(255, 0, 0)
			else:
				$pseudo.modulate = Color(0, 0, 255)
			self.set_collision_layer_value(1, true)
			self.set_collision_layer_value(2, false)
			my_team = GlobalScript.Players[multiplayer.get_unique_id()]["team"]

		"stop":
			my_team = 0
			$pseudo.outline_modulate = Color(0, 0, 0)
			$pseudo.modulate = Color(255, 255, 255)
			respawn_pos = Vector3(0,0,0)
			self.position = respawn_pos
			auto_respawn = false
			UI.get_node("Timer").hide()
			UI.get_node("Manche").hide()
			
		"begin":
			_is_beggining = !_is_beggining
			health_component.heal(100) 
			Weapon_manager.update_ammo_stock(180)
			Weapon_manager.update_ammo(0)
			
			self.position = respawn_pos
			
		"playing": 
			_is_beggining = !_is_beggining
			auto_respawn = true

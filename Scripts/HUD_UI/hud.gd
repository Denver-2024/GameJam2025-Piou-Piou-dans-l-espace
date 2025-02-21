extends Control

class_name player_HUD
const opt_path = "res://data/options.json"

@onready var Pause_menu : Panel = $CanvasLayer/Pause
@onready var Options : Panel = $CanvasLayer/Options
@onready var Death_screen : Panel = $CanvasLayer/Death_screen
@onready var Score : Panel = $CanvasLayer/Score
@onready var Player : Base_Player = get_parent().get_parent().get_parent()
@onready var Reticle : CenterContainer = $CanvasLayer/Reticle
@onready var countdown : Label = $CanvasLayer/countdown #compte à rebours avant réapparition 
@onready var party_parameters : MarginContainer = $CanvasLayer/MarginContainer
@export var menu_visible : bool = false # variable qui indique si un menu est visible ou non sur l'écran
@onready var ch_team_screen : Panel = $CanvasLayer/change_team
@onready var select_weapon  : MarginContainer = $CanvasLayer/select_weapon
@onready var hit_screen : TextureRect = $CanvasLayer/TextureRect
@onready var animations : AnimationPlayer = $CanvasLayer/AnimationPlayer
@onready var reset_dialog : ConfirmationDialog = Options.get_node("ConfirmationDialog")

var scroll : float
var vol_scroll : int = 0
var hit_screen_visible : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Player.name.to_int() != multiplayer.get_unique_id() : return
	if !is_local_player():
		hide()  # Cache cette réticule si elle n'est pas pour ce joueur
	else:
		show()  # Assure que la réticule du joueur local est visible
	
	#connexion des différents signaux émis par les boutons du menu
	Pause_menu.get_node("HBoxContainer/MarginContainer/VBoxContainer/Resume").connect("pressed", Callable(self, "Resume"))
	Pause_menu.get_node("HBoxContainer/MarginContainer/VBoxContainer/Quit").connect("pressed", Callable(self, "Quit_lobby"))
	Pause_menu.get_node("HBoxContainer/MarginContainer/VBoxContainer/Quit_Game").connect("pressed", Callable(self, "Quit_game"))
	Pause_menu.get_node("HBoxContainer/MarginContainer/VBoxContainer/options").connect("pressed", Callable(self, "_option"))
	Pause_menu.get_node("HBoxContainer/MarginContainer/VBoxContainer/change_team").connect("pressed", Callable(self, "_on_change_team_pressed"))
	
	Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/cfr/confirm").connect("pressed", Callable(self, "_on_confirm_pressed"))
	Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/Keymaps").connect("pressed", Callable(self, "_on_remapper_pressed"))
	Options.get_node("RE/Remapper/VBoxContainer/Button").connect("pressed", Callable(self, "_on_remapper_pressed"))
	Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/cfr/reset").connect("pressed", Callable(self, "_on_reset_pressed"))
	
	Death_screen.get_node("VBoxContainer/Respawn").connect("pressed", Callable(self, "_on_respawn"))
	reset_dialog.connect("confirmed", Callable(self,"reset_options"))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !is_local_player() : return
	#Lorsque le menu option est visible, on met a jour le label du scroller
	if Options.visible == true:
		scroll = Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/HSlider").get_value()/100
		Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/mouse_display").text = str(scroll)
		
		vol_scroll = Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/HSlider").get_value()
		Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/vol_display").text = str(vol_scroll+40)

func _on_reset_pressed():
	reset_dialog.show()

func reset_options():
	GlobalScript.Volume = 0
	GlobalScript.mouse_sensitivity = 0.005
	GlobalScript.TGLCROUCH = false
	GlobalScript.TGLSPRINT = false
	save_options()
	load_options()
	_option()
	
func _on_remapper_pressed():
	if Options.get_node("HBoxContainer").visible:
		Options.get_node("HBoxContainer").hide()
		Options.get_node("RE").show()
	else:
		Options.get_node("HBoxContainer").show()
		Options.get_node("RE").hide()
	
func player_hitted(alive_state : bool):
	if alive_state == true:
		if hit_screen_visible == false:
			hit_screen_visible = true
			animations.play("hit", -1, 4.5)
		if hit_screen_visible == true:
			animations.play("hit", -1, 10)

		await get_tree().create_timer(2.0).timeout
		animations.play("hit", -1, -1.0, true)
		hit_screen_visible = false
	else: 
		animations.play("hit", -1, -10, true)
		hit_screen.visible = false

@rpc("any_peer", "call_remote")
func server_quit():
	if !is_local_player() : return
	#fonction appeler qiand le serveur l'hôte quitte la partie
	GlobalScript.error = 0
	multiplayer.multiplayer_peer.disconnect_peer(get_multiplayer_authority())
	get_tree().change_scene_to_file("res://Menus/Main_menuV2.tscn")

#Ces deux fonctions définisent le mode de "quit" de la partie (éteindre le jeu ou revenir au menu principal
func Quit_game():
	if !is_local_player() : return
	quit(1)
	
func Quit_lobby():
	if !is_local_player() : return
	quit(0)

func quit(type : int):
	if !is_local_player() : return
	#si le joueur qui quitte la partie est l'hôte
	if multiplayer.is_server():
		server_quit.rpc() #alors on préviens les autres joueur que l'hôte a quitter la partie
		#Cette fonction sert a prévenir les autres joueurs que celui-ci a quitter la partie
	#Cette fonction sert a prévenir les autres joueurs que celui-ci a quitter la partie
	Player.get_parent().exit_game(multiplayer.get_unique_id())
	if type == 0:
		#retour au menu
		get_tree().change_scene_to_file("res://Menus/Main_menuV2.tscn")
	else:
		#ferme le jeu
		get_tree().quit()

@rpc("call_local")
func Resume():
	if !is_local_player() : return
	#fonction appeler quand un des menu se ferme
	Reticle.show()
	Options.hide()
	Pause_menu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_visible = false
	Player.exit_button = false
	ch_team_screen.hide()

func _option():
	if !is_local_player() : return
	#Fonction qui gèere l'écran des options 
	#On remet la valeur du slider qui a été enregistrer précédement (pour pas qu'il revienne à 0 à chaque fois)
	Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/HSlider").set_value_no_signal(Player.MOUSE_SENSIVITY*10000)
	Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer3/HSlider").set_value_no_signal(GlobalScript.Volume)
	
	Options.show()
	ch_team_screen.hide()
	menu_visible = true
	
func _on_confirm_pressed():
	if !is_local_player() : return
	#fonction qui enregistre la sensibilité
	Player.MOUSE_SENSIVITY = Options.get_node("HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/HSlider").get_value()/10000
	GlobalScript.mouse_sensitivity = Player.MOUSE_SENSIVITY
	GlobalScript.Volume = vol_scroll
	Resume.rpc()

@rpc("call_local")
func exit_pressed():
	if !is_local_player() : return
	#fonction appelé lorsque le joueur appuie sur échap
	Pause_menu.show()
	Reticle.hide()
	menu_visible = true
	$CanvasLayer/select_weapon.hide()

@rpc("call_local")
func _on_respawn():
	if !is_local_player(): return
	#fonction appelé lorsque le joeuur réapparait
	Death_screen.hide()
	Reticle.show()
	#appel de la fonction _on_respawn dans le script du joueur
	Player._on_respawn()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_visible = false

@rpc("call_local")
func _on_death(auto_respawn : bool):
	if !is_local_player(): return
	#fonction appelé lorsque le joueur meurt
	#la variable auto_respawn détermine si l'écran de mort affiche ou non le bouton "réapparaitre"
	#et le minuteur avant réapparition ou non
	menu_visible = true
	Pause_menu.hide()
	if auto_respawn == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Death_screen.show()
		#référence au bouton "réapparaitre" de l'écran de mort
		Death_screen.get_node("VBoxContainer/Respawn").show()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Death_screen.show()
		#référence au bouton "réapparaitre" de l'écran de mort
		Death_screen.get_node("VBoxContainer/Respawn").hide()
		#cette partie affiche le minuteur avant réapparition
		countdown.show()
		var tpm = get_tree().create_tween()
		$CanvasLayer/ColorRect.show()
		tpm.tween_property($CanvasLayer/ColorRect, "color", Color(0,0,0,1), 6.0)
		for i in range(6):
			countdown.text = str(5-i)
			await get_tree().create_timer(1.0).timeout
		
		_on_respawn.rpc()
		countdown.hide()
		menu_visible = false

func windows(open : bool, Wname : String):
	#cette fonction affiche les paramètres de la partie
	#a terme, elle servira a passer du monde "jeu" au mode "menu"
	var Wnode : Node
	match Wname:
		"party_parameters":
			Wnode = party_parameters
		"select_weapon":
			Wnode = select_weapon
			
	if open == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Wnode.show()
		Reticle.hide()
		menu_visible = true
	if open == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Wnode.hide()
		Reticle.show()
		menu_visible = false

func _on_change_team_pressed():
	Options.hide()
	ch_team_screen.show()

func is_local_player() -> bool:
	#cette fonction permet de savoir si c'est bien le joueur local qui execute le script
	#et non un autre joueur
	var synchronizer = Player.get_node_or_null("MultiplayerSynchronizer")
	return synchronizer and synchronizer.is_multiplayer_authority()
	

func load_options():
	if not FileAccess.file_exists(opt_path):
		save_options()
		return
	
	var file = FileAccess.open(opt_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	GlobalScript.ID = data["pseudo"]
	GlobalScript.Volume = data["volume"]
	GlobalScript.mouse_sensitivity = data["sensitivity"]
	GlobalScript.TGLCROUCH = data["TGLCROUCH"]
	GlobalScript.TGLSPRINT = data["TGLSPRINT"]
	
func save_options():
	var file = FileAccess.open(opt_path, FileAccess.WRITE)
	var dic_opt = {
		"pseudo" : GlobalScript.ID,
		"volume" : GlobalScript.Volume,
		"sensitivity" : GlobalScript.mouse_sensitivity,
		"TGLCROUCH" : GlobalScript.TGLCROUCH,
		"TGLSPRINT" : GlobalScript.TGLSPRINT
	}
	file.store_string(JSON.stringify(dic_opt, "\t"))
	file.close()
	

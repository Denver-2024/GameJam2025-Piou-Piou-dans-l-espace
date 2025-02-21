extends Control

const opt_path = "res://data/options.json"

# Référence vers tous les menus 
@onready var main_title : CanvasLayer = $Main
@onready var multiplayer_screen : CanvasLayer = $Multiplayer_screen
@onready var options_screen : CanvasLayer = $options
@onready var direct_screen : CanvasLayer = $Direct_screen

@onready var volume_display : Label = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer/vol_display")
@onready var mouse_display : Label = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer2/mouse_display")
@onready var error_dialog = $ConfirmationDialog
@onready var reset_dialog = options_screen.get_node("ConfirmationDialog2")

var mouse_sensitivity = GlobalScript.mouse_sensitivity
var volume = GlobalScript.Volume

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	load_options()
	#gère la déconnexion du serveur
	if GlobalScript.error != null:
		error_dialog.title = GlobalScript.err_dict[GlobalScript.error][1]
		error_dialog.dialog_text = GlobalScript.err_dict[GlobalScript.error][0]
		error_dialog.show()
		
	#on change la visibilité de chaque écran pour ne faire apparaitre que le principale
	multiplayer_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label").text = "Multijoueur"
	multiplayer_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel").text = "Mode de jeu classique.\n Assurez vous que chaque ordinateur est connecté au même réseau. Un des ordinateurs doit héberger la partie, les autres rejoignent. \n Attention : il peut y avoir des ralentissements selon votre connexion ou à cause du jeu en lui-même. Nous travaillons à optimisé le jeu pour éviter ces désagréments"
	main_title.visible = true
	
	#on connecte tous les boutons
	main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Options").connect("pressed", Callable(self, "_on_option_pressed"))
	main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Multi debug").connect("pressed", Callable(self, "_on_multi_debug_pressed"))
	main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Multiplayer Screen").connect("pressed", Callable(self, "_on_start_multi_button_pressed"))
	main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Quit game").connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	multiplayer_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Host").connect("pressed", Callable(self, "_on_host_button_pressed"))
	multiplayer_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Join").connect("pressed", Callable(self, "_on_join_button_pressed"))
	
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/cfr/Confirm").connect("pressed", Callable(self, "_on_confirm_pressed"))
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/Keymaps").connect("pressed", Callable(self, "_on_change_keymaps_pressed"))
	options_screen.get_node("RE/Remapper/VBoxContainer/Button").connect("pressed", Callable(self, "_on_change_keymaps_pressed"))
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLCROUCH").connect("pressed", Callable(self, "_on_TGL_pressed"))
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLSPRINT").connect("pressed", Callable(self, "_on_TGL_SPRINT_pressed"))
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/cfr/reset").connect("pressed", Callable(self, "_on_reset_pressed"))
	
	direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Host").connect("pressed", Callable(self, "_on_host_debug_pressed"))
	direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Join").connect("pressed", Callable(self, "_on_join_debug_pressed"))
	
	reset_dialog.connect("confirmed", Callable(self, "_reset_options"))
	
	Transition.str_animations_all(main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Multi debug"))
	Transition.str_animations_all(main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Multiplayer Screen"))
	Transition.str_animations_all(main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Options"))
	Transition.str_animations_all(main_title.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Quit game"))
	load_options()
	
func _physics_process(_delta: float) -> void:
	#fonction appeler pour changer la sensibilité de la souris et voir le changement 
	mouse_sensitivity = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer2/HSlider")
	mouse_display.text = str(mouse_sensitivity.get_value()/100)
	volume = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer/HSlider").get_value()
	volume_display.text = str(volume+40)
	
func _on_confirm_pressed():
	#quand on appui sur le bnouton confirmé de l'écran options (valide les paramètres)
	#passe les paramètres mis à jour dans le script global
	GlobalScript.ID = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/ID").text
	GlobalScript.mouse_sensitivity = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer2/HSlider").get_value()/10000
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ConfirmMesssage").show()
	GlobalScript.Volume = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer/HSlider").get_value()
	GlobalScript.ID = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/ID").text
	GlobalScript.mouse_sensitivity = options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer2/HSlider").get_value()/10000
	await get_tree().create_timer(2.0).timeout
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ConfirmMesssage").hide()
	release_focus()
	save_options()

func _on_TGL_pressed():
	match GlobalScript.TGLCROUCH:
		true:
			options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLCROUCH").text = "Appui long pour se baisser"
			GlobalScript.TGLCROUCH = false
		false:
			options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLCROUCH").text = "Appui simple pour se baisser"
			GlobalScript.TGLCROUCH = true

func  _on_TGL_SPRINT_pressed():
	match GlobalScript.TGLSPRINT:
		true:
			options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLSPRINT").text = "Appui long pour courir"
			GlobalScript.TGLSPRINT = false
		false:
			options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/TGLSPRINT").text = "Appui simple pour courir"
			GlobalScript.TGLSPRINT = true
			
func _on_reset_pressed():
	reset_dialog.show()

func _reset_options():
	GlobalScript.ID = ""
	GlobalScript.Volume = 0
	GlobalScript.mouse_sensitivity = 0.005
	GlobalScript.TGLCROUCH = false
	GlobalScript.TGLSPRINT = false
	save_options()
	load_options()
	_on_option_pressed()
	
func _on_change_keymaps_pressed():
	if options_screen.get_node("OPT").visible:
		release_focus()
		options_screen.get_node("OPT").hide()
		options_screen.get_node("RE").show()
	else:
		release_focus()
		options_screen.get_node("OPT").show()
		options_screen.get_node("RE").hide()

func _on_option_pressed():
	#appeler lorsqu'on appui sur le bouto option
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/ID").text = GlobalScript.ID
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer2/HSlider").set_value_no_signal(GlobalScript.mouse_sensitivity*10000)
	options_screen.get_node("OPT/MarginContainer/VBoxContainer/ScrollContainer/VButton/HBoxContainer/HSlider").set_value_no_signal(GlobalScript.Volume)
	release_focus()
	Transition.stop_animations()
	direct_screen.hide()
	multiplayer_screen.hide()
	options_screen.show()
	
#pour le jeu principal
func _on_host_button_pressed():
	GlobalScript.status = 0 #host distant (machines différentes)
	start_game()

func _on_join_button_pressed():
	GlobalScript.status = 1 # rejoint une machine distante
	start_game()

#fonctions appeler pour du débug (en "solo")
func _on_host_debug_pressed():
	GlobalScript.status = 2 #host local (même machine)
	start_game()
	
func _on_join_debug_pressed():
	
	GlobalScript.status = 3 # rejoint la partie local (même machine)
	start_game()
	
# Fonction qui s'exécute lorsque le bouton "start" est cliqué
func _on_start_multi_button_pressed():
	# Masquer main_title et afficher multiplayer_screen
	release_focus()
	multiplayer_screen.show()
	options_screen.hide()
	direct_screen.hide()

#affiche l'écran du "solo"
func _on_multi_debug_pressed() -> void: 
	release_focus()
	Transition.str_animations(direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/Label"))
	Transition.str_animations(direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel"))
	Transition.str_animations_all(direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Host"))
	Transition.str_animations_all(direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/VButton/Join"))
	Transition.str_animations(direct_screen.get_node("HBoxContainer/MarginContainer/VBoxContainer/RichTextLabel2"))
	direct_screen.show()
	multiplayer_screen.hide()
	options_screen.hide()

#fonction quand on veut quitter le jeu
func _on_quit_button_pressed() -> void:
	get_tree().quit()

#fait une transition
func start_game():
	Transition.stop_animations()
	Transition.change_scene("res://Testing_area.tscn")

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
	

extends Node

class_name game_manager

# Durées en secondes
var DUREE_MANCHE = 120  # 2 minutes par manche
var TEMPS_ATTENTE = 5    # 5 secondes entre les manches
var TOTAL_MANCHES = 3     #3 manches pour essai
var EVENTS = true

# Variables de manche
var manche_actuelle = 1
var manche_en_cours = false
var temps_restant = DUREE_MANCHE

@export var scores_players : Dictionary = {}  # Dictionnaire pour stocker les scores des joueurs

# Timer pour gérer les manches et les transitions
@onready var timer_manche = Timer.new()
@onready var timer_transition = Timer.new()
@onready var timer_label := $"../UI/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Timer"
@onready var manche_label := $"../UI/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Manche"
@onready var message_entre := $"../UI/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Message_entremanche"
@onready var start_button := $"../Start_button"
@onready var begin_timer := $"../UI/MarginContainer/VBoxContainer/HBoxContainer/begin_timer"
@onready var printer : chat_log = $"../UI/MarginContainer/VBoxContainer/HBoxContainer2/Panel/RichTextLabel"
@onready var sound_player : sound_manager_game = $"../Sound_game"
@onready var map_anim : AnimationPlayer = $"../Map".get_node("Anim")

var score_red_team : int  = 0
var score_blue_team : int = 0

@warning_ignore("unused_signal")
signal in_game(state)
@warning_ignore("unused_signal")
signal update_score

func _ready() -> void:
	begin_timer.hide()
					
@rpc("any_peer", "call_local")
func debut_jeu():
	
	var nb_player = 0
	for i in get_parent().get_child_count():
		if get_parent().get_child(i) is CharacterBody3D:
			nb_player+=1
	
	if nb_player < 2:
		printer.print_line("Il n'y a pas assez de joueurs pour commencer !")
		return
	
	for id in get_joueurs():
		if GlobalScript.Players[id]["team"] == 0:
			printer.print_line("Il reste des joueurs sans équipe !")
			return
			
	var players = get_joueurs()
		
	for id in players:
		if !scores_players.has(id):
			scores_players[id]={
				"score" : 0,
				"kill" : 0,
				"death" : 0
			}
	
	await get_tree().create_timer(0.5).timeout
	emit_signal("in_game", "start")
	# Initialiser les timers
	add_child(timer_manche)
	add_child(timer_transition)
	timer_manche.one_shot = false
	timer_transition.one_shot = true
	printer.print_line("Starting game...")
	# Connecte les signaux
	timer_manche.timeout.connect(_on_manche_tick)
	timer_transition.timeout.connect(_on_transition_finie)
	inter_manche.rpc(TEMPS_ATTENTE)
	await get_tree().create_timer(TEMPS_ATTENTE).timeout
	# Commence la première manche
	commencer_manche()

	
#renvoi la liste des joueurs
func get_joueurs():
	var players_id = []
	var temp
	for i in get_parent().get_child_count():
		if get_parent().get_child(i) is CharacterBody3D:
			temp = str(get_parent().get_child(i)).get_slice(":", 0)
			players_id.append(int(temp))
	return players_id 

@rpc("any_peer")
func inter_manche(waiting_time : int):
	emit_signal("in_game", "begin")
	begin_timer.show()
	map_anim.play("opening", -1, waiting_time*2)
	for i in range(waiting_time):
		begin_timer.text = str(waiting_time-i)
		await get_tree().create_timer(1.0).timeout
	emit_signal("in_game", "playing")
	begin_timer.hide()
	
@rpc("any_peer", "call_local")
func upt_score(id : int, score : int, kill : int, death : int):
	scores_players[id]["score"]=score
	scores_players[id]["kill"]=kill
	scores_players[id]["death"]=death
	emit_signal("update_score")

func commencer_manche():
	manche_en_cours = true
	temps_restant = DUREE_MANCHE
	timer_manche.start(1)  # Met à jour chaque seconde
	manche_label.text = "La manche " + str(manche_actuelle) + " a commencé !"
	printer.print_line("Manche " + str(manche_actuelle) + " a commencé !")
	sound_player.trigger_sound("round_start")

func _on_manche_tick():
	timer_label.show()
	manche_label.show()
	if manche_en_cours:
		temps_restant -= 1
		#print("Temps restant manche ", manche_actuelle, ":", temps_restant)
		timer_label.text = str(temps_restant)
		# Vérifier si la manche est terminée
		if temps_restant <= 0:
			terminer_manche()

func terminer_manche():
	manche_en_cours = false
	timer_manche.stop()
	
	var temp_score_blue = 0
	var temp_score_red = 0
	
	for id in scores_players.keys():
		if GlobalScript.Players[id]["team"] == 1:
			temp_score_red+=scores_players[id]["score"]
		else:
			temp_score_blue+=scores_players[id]["score"]
		scores_players[id]["score"] = 0
	
	score_blue_team+=temp_score_blue
	score_red_team+=temp_score_red
	
	if score_blue_team > score_red_team:
		printer.print_line("L'équipe bleu gagne !")
	elif score_blue_team < score_red_team:
		printer.print_line("L'équipe rouge gagne !")
	else: 
		printer.print_line("Match nul !")
		
	if map_anim.is_playing():
		await  map_anim.animation_finished
	map_anim.play_backwards("opening")
		
	# Vérifie si c'est la dernière manche
	if manche_actuelle >= TOTAL_MANCHES:
		jeu_termine.rpc()
	else:
		#print("Manche ", manche_actuelle, " est terminée ! Passage à la manche suivante dans ", TEMPS_ATTENTE, " secondes.")
		printer.print_line("La manche " + str(manche_actuelle) + " est terminé !")
		timer_label.hide()
		manche_label.hide()
		
		manche_actuelle += 1
		timer_transition.start(TEMPS_ATTENTE)
		inter_manche(TEMPS_ATTENTE)
	
func _on_transition_finie():
	commencer_manche()

@rpc("any_peer", "call_local")
func jeu_termine():
	emit_signal("in_game", "stop")
	printer.print_line("Jeu terminé !")
	printer.print_line("Scores finaux :")
	printer.print_line("équipe rouge : " + str(score_red_team))
	printer.print_line("équipe bleue : " + str(score_blue_team))
	if score_red_team > score_blue_team:
		printer.print_line("L'équipe rouge gagne la partie !")
		sound_player.trigger_sound("applause")
	elif score_red_team < score_blue_team:
		printer.print_line("L'équipe bleue gagne la partie !")
		sound_player.trigger_sound("applause")
	else:
		printer.print_line("Match nul !")
	score_blue_team = 0
	score_red_team = 0

@rpc("any_peer", "call_local")
func upt_var(nbm : int, tpsm : int, tpsi : int, evts : bool):
	TOTAL_MANCHES = nbm
	DUREE_MANCHE = tpsm
	TEMPS_ATTENTE = tpsi
	EVENTS = evts
	printer.print_line.rpc("Les paramètres de la partie ont été mis à jour")
	printer.print_line.rpc("Nombres de manches : " + str(TOTAL_MANCHES))
	printer.print_line.rpc("Temps de chaque manches : " + str(DUREE_MANCHE) +"s")
	printer.print_line.rpc("Temps inter-manches : " + str(TEMPS_ATTENTE)+"s")
	printer.print_line.rpc("Evènements : " + str(EVENTS))

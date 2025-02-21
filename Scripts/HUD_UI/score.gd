extends Panel

@onready var HUD : player_HUD = $"../.."
@onready var team1List : VBoxContainer = $MarginContainer/HBoxContainer/Team1List
@onready var team2List : VBoxContainer = $MarginContainer/HBoxContainer/Team2List
@onready var team1score : Label = $MarginContainer/HBoxContainer/Team1List/HBoxContainer/Team1Score
@onready var team2score : Label = $MarginContainer/HBoxContainer/Team2List/HBoxContainer/Team2Score
@onready var PLAYER_CONTROLLER : CharacterBody3D = $"../..".get_parent().get_parent().get_parent()
@onready var G_manager : game_manager = $"../..".get_parent().get_parent().get_parent().get_parent().get_node("Timer")

var score_nodes = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_local_player():
		hide()  # Cache cette réticule si elle n'est pas pour ce joueur
	else:
		show()
	G_manager.connect("in_game", Callable(self, "begin"))
	G_manager.connect("update_score", Callable(self, "upt_score"))
	hide()
	
func begin(state):
	if !is_local_player(): return
	if state == "start":
		for id in GlobalScript.Players:
			new_line.rpc(id)
			print(id)

func upt_score():
	if score_nodes == {} : return
	for id in G_manager.scores_players.keys():
		self.get_node(score_nodes[id]["score_path"]).text = str(G_manager.scores_players[id]["score"])
		self.get_node(score_nodes[id]["death_path"]).text = str(G_manager.scores_players[id]["death"])
		self.get_node(score_nodes[id]["kill_path"]).text = str(G_manager.scores_players[id]["kill"])
	team1score.text = str(G_manager.score_red_team)
	team2score.text = str(G_manager.score_blue_team)

@rpc("call_local")
func new_line(id):
	if !is_local_player() : return
	var hbox = HBoxContainer.new()
	hbox.name = "PLayer:"+str(id)
	hbox.add_theme_constant_override("separation", 80)

	if GlobalScript.Players[id]["team"] == 1:
		team1List.add_child(hbox)
	else:
		team2List.add_child(hbox)
	
	var pname = Label.new()
	pname.name = "pname:"+str(id)
	hbox.add_child(pname)
	pname.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
	pname.text = GlobalScript.Players[id]["name"]

	var score = Label.new()
	score.name = "score:"+str(id)
	hbox.add_child(score)
	score.text = str(GlobalScript.Players[id]["score"])
	score.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
	
	var death = Label.new()
	death.name = "death"+str(id)
	hbox.add_child(death)
	death.text = "0"
	death.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
	
	var kill = Label.new()
	kill.name = "kill"+str(id)
	hbox.add_child(kill)
	kill.text = "0"
	kill.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
	
	if !score_nodes.has(id):
		score_nodes[id]={
			"score_path" : self.get_path_to(score),
			"death_path" : self.get_path_to(death),
			"kill_path" : self.get_path_to(kill)
		}
	score.add_theme_font_size_override("hbox", 50) 
	pname.add_theme_font_size_override("hbox", 50) 
	kill.add_theme_font_size_override("hbox", 50) 
	death.add_theme_font_size_override("hbox", 50) 

func is_local_player() -> bool:
	var synchronizer = PLAYER_CONTROLLER.get_node_or_null("MultiplayerSynchronizer")
	return synchronizer and synchronizer.is_multiplayer_authority()

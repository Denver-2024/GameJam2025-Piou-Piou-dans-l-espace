extends Panel

@onready var Rbutton : Button =  $HBoxContainer/MarginContainer/VBoxContainer/Container2/VBoxContainer/HBoxContainer/Rjoin
@onready var Bbutton : Button = $HBoxContainer/MarginContainer/VBoxContainer/Container2/VBoxContainer/HBoxContainer/Bjoin

@onready var list_r_team : VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Container/HBoxContainer/Rteam
@onready var list_b_team : VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Container/HBoxContainer/Bteam

@onready var nb_r_team : Label = $HBoxContainer/MarginContainer/VBoxContainer/Container/HBoxContainer/Rteam/prt/CountR
@onready var nb_b_team : Label = $HBoxContainer/MarginContainer/VBoxContainer/Container/HBoxContainer/Bteam/prt/CountB

@onready var no_team_list : VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer/Container2/VBoxContainer/VBoxContainer

@onready var Lobby : Node3D = $"../..".get_parent().get_parent().get_parent().get_parent()
@onready var PLAYER_CONTROLLER : CharacterBody3D = $"../..".get_parent().get_parent().get_parent()

func _ready() -> void:
	if !is_local_player():
		hide() 
	else:
		show()
		
	var line = Label.new()
	line.text = GlobalScript.Players[multiplayer.get_unique_id()]["name"]
	line.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
	no_team_list.add_child(line)
	
	Rbutton.connect("pressed", Callable(self, "R_button_pressed"))
	Bbutton.connect("pressed", Callable(self, "B_button_pressed"))
	
	Lobby.connect("upt_teams", Callable(self, "_on_upt_team"))
	hide()

func R_button_pressed():
	if !is_local_player(): return
	var nb_red = 0
	for key in GlobalScript.Players.keys():
		if GlobalScript.Players[key]["team"] == 1:
			nb_red+=1
	if nb_red > 4 or GlobalScript.Players.size() < 2:
		return

	Rbutton.disabled = true
	Bbutton.disabled = false
	
	Lobby.SendPLayerInformation(GlobalScript.Players[multiplayer.get_unique_id()].name, multiplayer.get_unique_id(), 1)
	
	if !multiplayer.is_server():
		Lobby.SendPLayerInformation.rpc_id(1, GlobalScript.Players[multiplayer.get_unique_id()].name, multiplayer.get_unique_id(), 1)
	_on_upt_team()
	
func B_button_pressed():
	if !is_local_player(): return
	var nb_blue = 0
	for key in GlobalScript.Players.keys():
		if GlobalScript.Players[key]["team"] == 2:
			nb_blue+=1
	if nb_blue > 4 or GlobalScript.Players.size() < 2:
		return

	Rbutton.disabled = false
	Bbutton.disabled = true
	Lobby.SendPLayerInformation(GlobalScript.Players[multiplayer.get_unique_id()].name, multiplayer.get_unique_id(), 2)	
	
	if !multiplayer.is_server():
		Lobby.SendPLayerInformation.rpc_id(1, GlobalScript.Players[multiplayer.get_unique_id()].name, multiplayer.get_unique_id(), 2)
	
	_on_upt_team()
func clear_all():
	if !is_local_player(): return
	for n in list_b_team.get_children():
		if n.name != "prt":
			list_b_team.remove_child(n)
		
	for n in list_r_team.get_children():
		if n.name != "prt":
			list_r_team.remove_child(n)
		
	for n in no_team_list.get_children():
		if n.name != "prt":
			no_team_list.remove_child(n)


func _on_upt_team():
	if !is_local_player(): return
	clear_all()

	var nb_blue = 0
	var nb_red = 0
	for key in GlobalScript.Players.keys():
		var line = Label.new()
		line.text = GlobalScript.Players[key]["name"]
		line.add_theme_font_override("fony", load("res://styles/fonts/Nasalization Rg.otf"))
		if GlobalScript.Players[key]["team"] == 1:
			nb_red+=1
			list_r_team.add_child(line)
		elif GlobalScript.Players[key]["team"] == 2:
			nb_blue+=1
			list_b_team.add_child(line)
		else:
			no_team_list.add_child(line)
	
	if nb_blue > 4:
		Bbutton.disabled = true
	else:
		Bbutton.disabled = false
		
	if nb_red > 4:
		Rbutton.disabled = true
	else:
		Rbutton.disabled = false
	nb_b_team.text = str(nb_blue)+"/5"
	nb_r_team.text = str(nb_red)+"/5"

func is_local_player() -> bool:
	var synchronizer = PLAYER_CONTROLLER.get_node_or_null("MultiplayerSynchronizer")
	return synchronizer and synchronizer.is_multiplayer_authority()

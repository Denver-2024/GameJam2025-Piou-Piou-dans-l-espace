extends StaticBody3D

@onready var message :=$Label3D
@onready var area := $message_display
@onready var button_near := $button_near
@onready var animation := $AnimationPlayer
@onready var light := $button_pillar/Sphere
@onready var printer : chat_log = $"../UI/MarginContainer/VBoxContainer/HBoxContainer2/Panel/RichTextLabel"
@onready var G_manager : game_manager = $"../Timer"

var player_near_button : bool
var used : bool = false
var affected_team : int = 0

@warning_ignore("unused_signal")
signal event_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message.hide()
	G_manager.connect("in_game", Callable(self, ("change_state")))
	player_near_button = false
	message.text = "Déclencher un évènement aléatoire\n [100 points]"

func _emit_signal(id : int):
	if G_manager.scores_players[id]["score"] >= 100 and used == false:
		used = true
		G_manager.upt_score(id, G_manager.scores_players[id]["score"]-10 , 0, 0)
		match randi_range(0,2):
			0:
				event0.rpc()
			1:
				event1.rpc()
			2:
				event2.rpc()
				
		animation.play("button_pressed", -1, 3.0)
		await get_tree().create_timer(1.0).timeout
		animation.play("button_pressed", -1, -3.0, true)
	else:
		printer.print_line("évènement déjà activé !")
		
func change_state(game_state : String) -> void:
	match game_state:
		"begin":
			reset_events.rpc(-1)

@rpc("any_peer", "call_local")
func reset_events(num_event : int):
	match num_event:
		0:
			for pid in G_manager.scores_players.keys():
				if get_parent().get_node(str(pid)) is CharacterBody3D:
					get_parent().get_node(str(pid)).GRAVITY_FORCE = 1.0
		1:
			for index in range(get_parent().get_child_count()):
				if get_parent().get_child(index) is CharacterBody3D and get_parent().get_child(index).has_method("_input"):
					get_parent().get_child(index).SPEED=10
		_:
			reset_events.rpc(0)
			reset_events.rpc(1)
	message.text = "Déclencher un évènement aléatoire\n [100 points]"
	used = false

@rpc("any_peer", "call_local")
func event0():
	printer.print_line.rpc("Probabilité d'évènements aléatoires augmenté !")

@rpc("any_peer", "call_local")
func event1():
	printer.print_line.rpc("La gravité sera réduite pendant 30 secondes !")
	for index in range(get_parent().get_child_count()):
			if get_parent().get_child(index) is CharacterBody3D and get_parent().get_child(index).has_method("_input"):
				get_parent().get_child(index).GRAVITY_FORCE = 0.25
	message.text = "[indisponible]"
	await get_tree().create_timer(30.0).timeout
	reset_events.rpc(0)

@rpc("any_peer", "call_local")
func event2(id : int):
	for index in range(get_parent().get_child_count()):
		if get_parent().get_child(index) is CharacterBody3D and get_parent().get_child(index).has_method("_input"):
			if GlobalScript.Players[get_parent().get_child(index).name]["team"] == GlobalScript.Players[id]["team"]:
				get_parent().get_child(index).SPEED=10
	printer.print_line.rpc("L'équipe " + GlobalScript.Players[id]["team"]+" ont un boost de vitesse pendant 30 secondes !")
	await get_tree().create_timer(30.0).timeout
	reset_events.rpc(1)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Base_Player:
		message.show()
		
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Base_Player:
		message.hide()

func _on_button_near_body_entered(body: Node3D) -> void:
	if body is Base_Player:
		player_near_button = true

func _on_button_near_body_exited(body: Node3D) -> void:
	if body is Base_Player:
		player_near_button = false

extends StaticBody3D

@onready var message :=$Label3D
@onready var area := $message_display
@onready var button_near := $button_near
@onready var animation := $AnimationPlayer
@onready var light := $button_pillar/Sphere
@onready var printer : chat_log = $"../UI/MarginContainer/VBoxContainer/HBoxContainer2/Panel/RichTextLabel"
#@onready var sound_player: sound_manager=$"../sound_manager"

var player_near_button : bool
var used = false

@warning_ignore("unused_signal")
signal start_pressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message.hide()
	player_near_button = false

func _emit_signal(id : int):
	animation.play("button_pressed", -1, 3.0)
	await get_tree().create_timer(0.5).timeout
	animation.play("button_pressed", -1, -3.0,true)
	for i in range(get_parent().get_child_count()):
		if get_parent().get_child(i) is CharacterBody3D and get_parent().get_child(i).name == str(id):
			get_parent().get_child(i).get_node("camera/Camera3D/HUD").windows(true, "select_weapon")

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

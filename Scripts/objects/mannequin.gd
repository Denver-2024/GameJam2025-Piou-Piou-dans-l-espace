extends Node3D

var puppet_life : int = 100
@onready var animations : AnimationPlayer = $AnimationPlayer
@onready var hp_bar : Label3D = $Path3D/PathFollow3D/RigidBody3D/Label3D
@onready var puppet : RigidBody3D = $Path3D/PathFollow3D/RigidBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animations.play("round")

func damage_show(damage_nb : int, _is_critical : bool):
	var number = Label3D.new()
	var alpha = randf_range(-1.5, 1.5)
	if alpha < 0.6 and alpha > 0.0:
		alpha+=1.0
	elif alpha > -0.6 and alpha < 0.0:
		alpha-=1.0
	
	number.position = puppet.position + Vector3(0, 2.5, alpha)
	number.font_size = 1
	number.name = "tpm"
	number.text = str(damage_nb)
	number.set_billboard_mode(BaseMaterial3D.BILLBOARD_FIXED_Y)
	number.visible = false
	puppet.add_child(number)
	number.visible = true
	var anim = get_tree().create_tween()
	anim.tween_property(number, "font_size", 100, 0.06)
	await get_tree().create_timer(1.0).timeout
	puppet.remove_child(number)
	
@rpc("any_peer", "call_local")
func damage(id_player : int, wepaon : int):
	puppet_life-=GlobalScript.Weapons[wepaon]["damage"][1]
	hp_bar.text = str(puppet_life)
	if multiplayer.get_unique_id() == id_player:
		damage_show(GlobalScript.Weapons[wepaon]["damage"][1], false)
	if puppet_life<=0:
		animations.stop()
		self.hide()
		respawn.rpc()

@rpc("any_peer", "call_local")
func respawn():
	await get_tree().create_timer(3.0).timeout
	puppet_life = 100
	self.show()
	hp_bar.text = str(puppet_life)
	animations.play("round")

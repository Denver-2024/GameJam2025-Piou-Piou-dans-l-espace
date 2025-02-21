extends RigidBody3D

@export var ammo = 50
@onready var sound_player: sound_manager_player =$sound_manager_ammo

@warning_ignore("unused_signal")
signal ammo_Taken

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		body.get_node("camera/Camera3D/Weapon_manager").update_ammo_stock.rpc_id(body.get_multiplayer_authority(), 20)
		emit_signal("ammo_Taken")
		#body.sound_player.trigger_sound("item_taken")
		queue_free()

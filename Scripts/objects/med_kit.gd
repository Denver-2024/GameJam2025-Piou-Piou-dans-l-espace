extends RigidBody3D
@export var hp = 50

@onready var sound_player: sound_manager_player =$sound_manager_medkit

@warning_ignore("unused_signal")
signal med_taken

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		body.get_node("Health_component").heal.rpc_id(body.get_multiplayer_authority(), hp)
		emit_signal("med_taken")
		#sound_player.trigger_sound("item_taken")
		queue_free()

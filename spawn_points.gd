extends Node3D

@export var dic_spawn = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await multiplayer.connected_to_server
	upt_dic()

@rpc("any_peer")
func upt_dic():
	dic_spawn = {}
	for elt in self.get_children():
		if !dic_spawn.has(elt.name):
			dic_spawn[elt.name] = {
				"pos" = elt.point,
				"available" = elt.player_inside
			}
	if multiplayer.is_server():
		upt_dic.rpc()
		
func choose_point() -> Vector3:
	for elt in dic_spawn.keys():
		if dic_spawn[elt]["available"] == false:
			return(dic_spawn[elt]["pos"])
	return(Vector3(0,0,0))

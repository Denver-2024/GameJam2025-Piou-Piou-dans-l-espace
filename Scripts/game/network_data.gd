class_name NetworkData

const UniqueSHA = "a9aaab6446c29f26347454c1bd1fa8c7f3fa4be4337d1248e69ca743d1fdb19b"

var lobby_name: String = "Emilie"
var max_player: int = 5
var current_player: int = 1
#var game_mode: Game.GameModes = Game.GameModes.Classic
# visible on broadcast
var public: bool = true
# need password
var protected: bool = false

func update_from_server() -> void:
	max_player = Server.server_max_player
	if Server.multiplayer_active:
		current_player = Server.multiplayer.get_peers().size()
	else:
		current_player = 1
	public = true
	protected = ""
	game_mode = "normal"

func parse(string: String) -> bool:
	if !string.begins_with(UniqueSHA + ":"):
		return false
	var var_data = JSON.parse_string(string.trim_prefix(UniqueSHA + ":"))
	if typeof(var_data) != TYPE_DICTIONARY:
		return false
	
	var data: Dictionary = (var_data as Dictionary)
	lobby_name = str(data.get_or_add("name", "Emilie"))
	max_player = int(data.get_or_add("max", 1))
	current_player = int(data.get_or_add("players", 1))
	@warning_ignore("int_as_enum_without_cast")
	#game_mode = (data.get_or_add("mode", Game.GameModes.Classic))
	public = bool(data.get_or_add("public", 0))
	protected = bool(data.get_or_add("protected", 1))
	IP.get_local_addresses()
	return true

func _to_string() -> String:
	return UniqueSHA + ":" + JSON.stringify({
		"name": lobby_name,
		"max": max_player,
		"players": current_player,
		"mode": int(game_mode),
		"public": int(public),
		"protected": int(protected)
	})

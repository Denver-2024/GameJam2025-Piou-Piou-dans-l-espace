extends Node

const Player = preload("res://player/player.tscn")

var spawn_positions : Array = []
var broadcast_port = 12345
var udp_broadcaster : PacketPeerUDP
var udp_listener : PacketPeerUDP
var found_server = false
var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var printer : chat_log = $UI/MarginContainer/VBoxContainer/HBoxContainer2/Panel/RichTextLabel
const DAMAGE_AMOUNT = 1

@warning_ignore("unused_signal")
signal player_connected(id)
@warning_ignore("unused_signal")
signal upt_teams

func _start_broadcasting() -> void:
	var broadcast_address_list = get_broadcast_addresses()
	while true:
		for broadcast_address in broadcast_address_list:
			#var broadcast_address = "192.168.114.255" #en principe c'est toujours cette adresse
			#sinon, l'adresse de "bradcast" dépend du masque de sous réseau
			var packet = "GODOT_SERVER:" + str(broadcast_address)
			udp_broadcaster.set_dest_address(broadcast_address, broadcast_port)
			udp_broadcaster.put_packet(packet.to_utf8_buffer())
			await  get_tree().create_timer(1.0).timeout

func _discover_servers() -> void:
	print("Searching for servers...")
	while true:
		if udp_listener.get_available_packet_count() > 0:
			var packet = udp_listener.get_packet().get_string_from_utf8()
			if packet.begins_with("GODOT_SERVER:"):
				var server_port = broadcast_port
				var server_ip = udp_listener.get_packet_ip()
				print("Found server at", server_ip, ":", server_port)
				
				#se connecter au serveur détecté
				peer = ENetMultiplayerPeer.new()
				peer.create_client(server_ip, server_port)
				multiplayer.multiplayer_peer = peer
				peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
				add_player(multiplayer.get_unique_id())
				SendPLayerInformation.rpc_id(1, ID(), multiplayer.get_unique_id(), 0)
				break
		await get_tree().create_timer(0.1).timeout # Vérifie les paquets toutes les 100 ms

func ID():
	#print(GlobalScript.ID)
	if GlobalScript.ID == "":
		return("Player #" + str(multiplayer.get_unique_id()))
	return(GlobalScript.ID)
	
func _ready():
	multiplayer.connected_to_server.connect(connected_to_server)
	# Récupère le noeud 'Spawn_points' dans la scène
	var spawn_points_node = $Spawn_points
	# Parcourt chaque enfant de 'Spawn_points'
	var team_spawn_id = 1
	for spawn_point in spawn_points_node.get_children():
		# Vérifie que l'enfant a un Marker3D
		var marker = spawn_point.get_node("Marker3D")
		if marker:
			# Ajoute la position globale du Marker3D à la liste
			GlobalScript.spawn_point[team_spawn_id] = marker.global_transform.origin
			team_spawn_id+=1
			spawn_positions.append(marker.global_transform.origin)
	
	#var broadcast_addresses = get_broadcast_addresses()
	#print("Adresses de broadcast : ", broadcast_addresses)
	# Affiche les positions pour vérification	
	match GlobalScript.status:
		0:
			host()
			print("host indirecte")
		1:
			join()
			print("join indirecte")
		2:
			host_direct()
			print("host direct")
		3:
			join_direct()
			print("join direct")
	animation.play("fade_out")
	
func host_direct() -> void:
	var err = peer.create_server(135)
	if err != 0:
		GlobalScript.error = 1
		get_tree().change_scene_to_file("res://Menus/Main_menuV2.tscn")
	else:
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		SendPLayerInformation(ID(), multiplayer.get_unique_id(), 0)
		add_player(multiplayer.get_unique_id())

func join_direct() -> void:
	peer.create_client("localhost",135) #de base
	multiplayer.multiplayer_peer = peer
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	await get_tree().create_timer(0.25).timeout
	SendPLayerInformation.rpc_id(1, ID(), multiplayer.get_unique_id(), 0)

func host() -> void:
	var error = peer.create_server(broadcast_port)
	if error != OK:
		printerr("cannot host:",error)
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	
	udp_broadcaster = PacketPeerUDP.new()
	udp_broadcaster.set_broadcast_enabled(true)
	udp_broadcaster.bind(broadcast_port)
	call_deferred("_start_broadcasting")
	
	SendPLayerInformation(ID(), multiplayer.get_unique_id(), 0)
	add_player(multiplayer.get_unique_id())
	
func join() -> void:
	var bind_address = "*"
	udp_listener = PacketPeerUDP.new()
	var _error = udp_listener.bind(broadcast_port, bind_address)
	_discover_servers()

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	call_deferred("add_child", player)
	await get_tree().create_timer(0.2).timeout
	player.position = $spawn_spawn.choose_point()

func respawn_player(_id):
	pass
func exit_game(id : int) -> void:
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	
func del_player(id : int) -> void:
	_del_player.rpc(id)
	message.rpc(id, 1)

@rpc("any_peer", "call_local")
func _del_player(id : int):
	if self.has_node(str(id)) == true:
		get_node(str(id)).queue_free()
	#print("player : ", id, " deleted")
	
func connected_to_server():
	SendPLayerInformation(ID(), multiplayer.get_unique_id(), 0)
	SendPLayerInformation.rpc_id(1, ID(), multiplayer.get_unique_id(), 0)
	await get_tree().create_timer(0.25).timeout
	message.rpc(multiplayer.get_unique_id(), 0)

#renvoie la liste des adresses IP locales et de leurs masque de sous réseau
func get_masknadress() -> Array:
	var output_ip = []
	var output_mask = []
	# Exécute la commande système appropriée en fonction de l'OS
	if OS.get_name() == "Windows":
		OS.execute("CMD.exe", ["/C", "ipconfig | findstr /R IPv4"], output_ip)
		OS.execute("CMD.exe", ["/C", "ipconfig | findstr /R Mask "], output_mask)
	
	if output_mask[0] == "":
		output_mask = []
		if OS.get_name() == "Windows":
			OS.execute("CMD.exe", ["/C", "ipconfig | findstr /R Masque "], output_mask)
	var pattern = r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
	var regex = RegEx.new()
	regex.compile(pattern)
	
	var matches = regex.search_all(output_ip[0])
	var ip_addresses = []
	var subnet_mask = []
	
	for match in matches:
		ip_addresses.append(match.get_string())
	
	matches = regex.search_all(output_mask[0])
	for match in matches:
		subnet_mask.append(match.get_string())
	return([ip_addresses, subnet_mask])

#renvoie la liste des adresses de broadcast
func get_broadcast_addresses() -> Array:
	var broadcast_addresses = []
	var list = get_masknadress()
	
	var ip_address = list[0]
	var subnet_mask = list[1]

	for i in range(len(ip_address)):
		if ip_address[i] != "" and subnet_mask[i] != "":
			# Convertit les adresses en formats numériques pour le calcul du broadcast
			var ip_numeric = _ip_to_numeric(ip_address[i])
			var mask_numeric = _ip_to_numeric(subnet_mask[i])
			var broadcast_numeric = ip_numeric | ~mask_numeric
			# Reconvertit en format lisible (IPv4)
			var broadcast_address = _numeric_to_ip(broadcast_numeric)
			broadcast_addresses.append(broadcast_address)
	return broadcast_addresses

# Convertit une adresse IP (en chaîne) en entier numérique
func _ip_to_numeric(ip: String) -> int:
	var parts = ip.split(".")
	return (int(parts[0]) << 24) | (int(parts[1]) << 16) | (int(parts[2]) << 8) | int(parts[3])

# Convertit un entier numérique en adresse IP (en chaîne)
func _numeric_to_ip(numeric: int) -> String:
	return "%d.%d.%d.%d" % [
		(numeric >> 24) & 0xFF,
		(numeric >> 16) & 0xFF,
		(numeric >> 8) & 0xFF,
		numeric & 0xFF]

@rpc("any_peer", "call_local")
func message(id : int, num : int) -> void:
	if num == 0:
		#if GlobalScript.Players.find_key(id) != null:
		printer.print_line(str(GlobalScript.Players[id]["name"]) + " a rejoint la partie !")
	else:
		if str(id) != "1" and GlobalScript.Players.find_key(id) != null:
			printer.print_line(str(GlobalScript.Players[id]["name"]) + " a quitté la partie !")
			GlobalScript.Players.erase(id)
					
@rpc("any_peer")
func SendPLayerInformation(pname : String, id : int, team : int):
	if !GlobalScript.Players.has(id):
		#ajoute 
		GlobalScript.Players[id]={
			"name" : pname,
			"id" : id,
			"score" : 0,
			"team" : team
		}
		emit_signal("player_connected", id)
	else:
		# met à jour
		GlobalScript.Players[id]["name"] = pname
		GlobalScript.Players[id]["id"] = id
		GlobalScript.Players[id]["score"] = 0
		GlobalScript.Players[id]["team"] = team

	if multiplayer.is_server():
		for i in GlobalScript.Players:
			SendPLayerInformation.rpc(GlobalScript.Players[i].name, i, GlobalScript.Players[i]["team"])
		await get_tree().create_timer(0.2).timeout
	emit_signal("upt_teams")

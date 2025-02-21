class_name NetworkBroadCaster
extends Node

var broadcast_port = 24520
var udp: PacketPeerUDP = null

var broadcast_data: NetworkData = NetworkData.new() 
const BroadCastTimeout: float = 1.0
const DiscoverTimeout: float = 0.1

var _broadcast_host: bool = false
var _broadcast_peer: bool = false

signal discovered(ip: String)
signal stop_broadcast()
signal start_broadcast(host: bool)

signal _stopped_broadcasting
signal _stopped_discovering

func _ready() -> void:
	stop_broadcast.connect(_stop)
	start_broadcast.connect(_start)

func _stop() -> void:
	if _broadcast_host:
		_broadcast_host = false
		await _stopped_broadcasting
	if _broadcast_peer:
		_broadcast_peer = false
		await _stopped_discovering
	
	if udp:  
		udp.close()
		udp = null

func _start(host: bool = false) -> void:
	_stop()
	if host:
		_broadcast_host = true
		_start_broadcast()
	else:
		_broadcast_peer = true
		_discover_broadcast()

func _filtered_ips() -> Array[String]:
	var res: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip != "127.0.0.1" and !ip.contains(":"):
			res.append(ip)
	return res

func _start_broadcast() -> void:
	if udp:
		return
	
	udp = PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	var err := udp.bind(broadcast_port)
	
	if err != OK:
		printerr("Error while binding udp host: ", error_string(err))
		_broadcast_host = false
		return
	
	if !udp.is_bound():
		printerr("Udp host is not bound")
		_broadcast_host = false
		return
	
	print("Broadcasting")
	while _broadcast_host:
		# update info
		broadcast_data.update_from_server()
		var packet = str(broadcast_data)
		
		for ip: String in _filtered_ips():
			var parts := ip.split(".")
			# looks like only those 4 port work to broadcast
			# if it doesn't work, replace range(8, 12) by 256
			for i in range(8, 12): 
				parts[3] = str(i)
				udp.set_dest_address(".".join(parts), broadcast_port)
				udp.put_packet(packet.to_utf8_buffer())
		
		await get_tree().create_timer(BroadCastTimeout).timeout

	print("Stopping broadcast host")
	_stopped_broadcasting.emit()

func _discover_broadcast() -> void:
	if udp:
		return
	
	udp = PacketPeerUDP.new()
	var err := udp.bind(broadcast_port, "0.0.0.0")
	if err != OK:
		printerr("Error while binding udp peer: ", error_string(err))
		_broadcast_peer = false
		return
	
	if !udp.is_bound():
		printerr("Udp peer is not bound")
		_broadcast_peer = false
		return
	
	print("Searching for rooms...")
	while _broadcast_peer:
		if udp.get_available_packet_count() > 0:
			var packet = udp.get_packet().get_string_from_utf8()
			print(packet)
			if packet.begins_with(broadcast_data.UniqueSHA):
				var server_port = broadcast_port
				var server_ip = udp.get_packet_ip()
				print("Found server at", server_ip, ":", server_port)
				var data = NetworkData.new()
				if data.parse(packet):
					print("packet valid")
					discovered.emit(server_ip, data)
				else:
					print("packet invalid")
		await get_tree().create_timer(DiscoverTimeout).timeout
	
	print("Stopping broadcast peer")
	_stopped_discovering.emit()

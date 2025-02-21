extends AudioStreamPlayer

class_name sound_manager_game

@export var sound_library: Dictionary={
	"round_start": "res://Sounds/debut manche.wav",
	"applause": "res://Sounds/foule applaudissant.wav",
	"welcoming": "res://Sounds/son calme real.wav",
}

#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local")
func play_sound3D(sound_key:String, server_time: float) ->void:
	if sound_key not in sound_library:
		print("Son non trouvé", sound_key)
		return
	else:
		var sound_path=sound_library[sound_key]
		var delay=server_time-(Time.get_ticks_msec()/1000.0) #Calcul du retard
		
		#Pour s'assurer que le retard n'est pas négatif
		delay=max(0.0, delay)

		self.stream=load(sound_path)
		
		#Attendre avant de jouer le son
		if delay>0:
			await get_tree().create_timer(delay).timeout
		self.play()
		
#Fonction appelée par le server pour déclencher le son
func trigger_sound3D(sound_key:String) ->void:
	var server_time=Time.get_ticks_msec()/1000.0 #Temps actuel du server
	play_sound3D.rpc(sound_key, server_time)
		
func play_sound(sound_key:String, server_time: float) ->void:
	if sound_key not in sound_library:
		print("Son non trouvé", sound_key)
		return
	else:
		var sound_path=sound_library[sound_key]
		var delay=server_time-(Time.get_ticks_msec()/1000.0) #Calcul du retard
		
		#Pour s'assurer que le retard n'est pas négatif
		delay=max(0.0, delay)
		var audio_player=AudioStreamPlayer3D.new()
		add_child(audio_player)
		audio_player.stream=load(sound_path)
		
		#Attendre avant de jouer le son
		if delay>0:
			await get_tree().create_timer(delay).timeout
			
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free) #Supprimer après lecture
		
#Fonction appelée par le server pour déclencher le son
func trigger_sound(sound_key:String) ->void:
	var server_time=Time.get_ticks_msec()/1000.0 #Temps actuel du server
	play_sound3D.rpc(sound_key, server_time)

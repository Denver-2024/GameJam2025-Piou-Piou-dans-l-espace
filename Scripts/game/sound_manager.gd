extends Node
class_name sound_manager_player

@onready var audio_player = $"../AudioStreamPlayer3D"
#@onready var audio_player_indic = $"../AudioStreamPlayer"

@export var sound_library: Dictionary={
	"item_taken": "res://Sounds/prise article real.wav",
	"jump_sound":"res://Sounds/son saut real.wav",
	"shoot_gun":"res://Sounds/tir arme a feu.wav",
	"reload_gun":"res://Sounds/recharge pistolet real.wav",
	"lancement_grenade":"res://Sounds/lancement grenade real.wav",
	"explosion_grenade":"res://Sounds/explosion grenade real.wav",
	"reload_Ak47":"res://Sounds/recharge AK47 real.wav"
}

#Fonction pour déclencher un son de manière synchronisée
@rpc("any_peer", "call_local", "unreliable")
func play_sound3D(sound_key:String) ->void:
	if sound_key not in sound_library:
		print("Son non trouvé", sound_key)
		return
	else:
		var sound_path=sound_library[sound_key]
		audio_player.stream=load(sound_path)
		audio_player.max_db = GlobalScript.Volume
		audio_player.play()
	
#@rpc("call_local")
#func play_sound_HUD(sound_key:String):
	#if sound_key not in sound_library:
		#print("Son non trouvé", sound_key)
		#return
	#else:
		#var sound_path=sound_library[sound_key]
		#audio_player.stream=load(sound_path)
		#audio_player.play()
		#
		#audio_player.volume_db = 0

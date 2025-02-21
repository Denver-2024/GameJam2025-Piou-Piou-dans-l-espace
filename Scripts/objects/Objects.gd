extends Node3D

#charge les nodes ammo_box et medkit
const ammoBox = preload("res://Objects/Ammo_box.tscn")
const medKit = preload("res://Objects/MedKit.tscn")

#position des markers3D
var ammopos : Vector3 
var medpos : Vector3

#active ou désactive les boites

@export var activate : bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#si c'est désactivé, il ne se passe rien
	if activate == false : return
	
	ammopos = get_child(0).position
	medpos = get_child(1).position
	#instancie les nodes
	var MK = medKit.instantiate()
	var AB = ammoBox.instantiate()
	
	#change leurs positions
	AB.position = ammopos
	MK.position = medpos
	
	#les ajoutes au node Objet
	self.add_child(MK)
	self.add_child(AB)
	
	#connecte les signaux pour savoir si ils ont disparue ou non
	MK.connect("med_taken", Callable(self, "Spawn_med"))
	AB.connect("ammo_Taken", Callable(self, "Spawn_ammo"))

func Spawn_ammo():
	#fait apparaitre une nouvelle boite de munition quand celle d'avant a été prise
	await get_tree().create_timer(4.0).timeout
	var AB = ammoBox.instantiate()
	AB.position = ammopos
	self.add_child(AB)
	AB.connect("ammo_Taken", Callable(self, "Spawn_ammo"))

func Spawn_med():
	#fait apparaitre une nouvelle trousse de soins quand celle d'avant estr prise
	await get_tree().create_timer(4.0).timeout
	var MK = medKit.instantiate()
	MK.position = medpos
	self.add_child(MK)
	MK.connect("med_taken", Callable(self, "Spawn_med"))

extends Node
#içi, on met toutes les variables dont on à besoin pour le scirpt
var status : int = 0 #0 = host, 1 = join, 2 = host direct, 3 = join direct
var ID : String= "" #le pseudo du joueur
var Players : Dictionary= {} #La liste des joueurs, leurs ID, leurs team ect... partager avec tout les autres joueurs
var mouse_sensitivity : float = 0.005 #La sensibilité de la souris choisis par le joueur 
var spawn_point : Dictionary = {} #Dictionnaire des points de spaw,
var Volume : float = 0.0
var TGLCROUCH : bool = false
var TGLSPRINT : bool = false
var error = null #permet de géré le retour au menu en cas d'erreur
var err_dict = {
	0: ["l'hôte s'est déconnecté","SERVER ERROR"],
	1: ["ERREUR : Cette machine héberge déjà une partie !","SERVER ERROR"]
}

#Dictionnaire des armes : 
#type : "Dist" pour les armes a feu, "melee" pour les armes de mêlée, "obj" pour les grenades, soins....
#model : chemin vers le model 3D de l'arme (la scène qui la contient avec les effets et tout)
#damage : liste des dégats -> tête, torse, reste
#ammo : nombre de munitions dans un chargeur
#reload_time : temps de rechargement
#cadency : cadence de tir, temps entre deux tir (auto ou coup par coup, on peut faire des listes)
#dispertion : en degrès, créer un cone de dispertion des balles
#aimspeed : vitesse de visée
#bulltet_speed : vitesse de la balle
#autoshot : est ce qu'on peut tirer automatiquement ? (tir continue ?)
#shoot sound : effet sonore de tir
#reload_sound : effet sonore pour recharger 
#description : description de l'arme
var Weapons = {
	-1 : {"name" = "None",
		"type" = "None",
		"model" = null,
		"damage" = null,
		"ammo" = null,
		"reload_time" = null,
		"cadency" = null,
		"dispertion" = null,
		"aimspeed" = null,
		"bullet_speed" = null,
		"auto_shoot" = false,
		"shoot_sound"="None",
		"reload_sound"="None",
		"description"="None"
	},
	0 : {
		"name" = "Pistolet",
		"type" = "Dist",
		"model" = "res://Objects/basic_gun/basic_gun.tscn",
		"damage" = [20, 10, 5],
		"ammo" = 8,
		"reload_time" = 0.75,
		"cadency" = 1.2,
		"dispertion" = 5,
		"aimspeed" = 4,
		"bullet_speed" = 125,
		"auto_shoot" = false,
		"shoot_sound"="res://Sounds/tir arme a feu.wav",
		"reload_sound"="reload_gun",
		"description"="Pistolet classique et robuste.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 8"
	},
	1 : {
		"name" = "AK-47",
		"type" = "Dist",
		"model" = "res://Objects/ak/ak.tscn",
		"damage" = [25, 15, 5],
		"ammo" = 30,
		"reload_time" = 1.0,
		"cadency" = 0.1,
		"dispertion" = 8,
		"aimspeed" = 4,
		"bullet_speed" = 75,
		"auto_shoot" = true,
		"shoot_sound"="res://Sounds/tir arme Ak47 real.wav",
		"reload_sound"="reload_Ak47",
		"description"="AK-47, fusil d'assault à rafalle.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 30"
	},
	2: {
		"name" = "Grenade",
		"type" = "obj",
		"model" = "res://Objects/grenade/grenade_player.tscn",
		"damage" = [50, 40, 10],
		"ammo" = 1,
		"reload_time" = null,
		"cadency" = 0.5,
		"dispertion" = null,
		"aimspeed" = null,
		"bullet_speed" = null,
		"auto_shoot" = false,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav", #explosion grenade
		"description"="Grenade à déflagration sur 10 mètres.
		\ntype : Objet de lancé
		\ndégâts moyen: "+
		"\nMunitions: 1"
	},
	3: {
		"name" = "Fusil à pompe",
		"type" = "Dist",
		"model" = "res://Objects/shotgun/shotgun.tscn",
		"damage" = [30, 5, 5],
		"ammo" = 10,
		"reload_time" = 1.0,
		"cadency" = 100.5,
		"dispertion" = 10,
		"aimspeed" = 4,
		"bullet_speed" = 75,
		"auto_shoot" = false,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav", #explosion grenade
		"description"="Fusil à pompe qui tire 10 balles par cartouche.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 12"
	},
	4: {
		"name" = "Fusil laser",
		"type" = "Dist",
		"model" = "res://Objects/laser_weapon/laser_weapon.tscn",
		"damage" = [30, 20, 5],
		"ammo" = 12,
		"reload_time" = 1.5,
		"cadency" = 0.5,
		"dispertion" = 1,
		"aimspeed" = 3,
		"bullet_speed" = 150,
		"auto_shoot" = true,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav",
		"description"="Fusil laser : les balles peuvent rebondir jusqu'à 5 fois sur le décor.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 10" #explosion grenade
	},
	5: {"name" = "Fusil rateau",
		"type" = "Dist",
		"model" = "res://Objects/rateau.tscn",
		"damage" = [30, 10, 5],
		"ammo" = 8,
		"reload_time" = 1.5,
		"cadency" = 0.5,
		"dispertion" = 1,
		"aimspeed" = 3,
		"bullet_speed" = 75,
		"auto_shoot" = false,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav",
		"description"="Fusil rateau.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 8" #explosion grenade
	},
	6:{
		"name" = "Bombe temporel",
		"type" = "obj",
		"model" = "res://Objects/tme_shield/time_shield.tscn",
		"damage" = null,
		"ammo" = 1,
		"reload_time" = null,
		"cadency" = 1.5,
		"dispertion" = null,
		"aimspeed" = null,
		"bullet_speed" = null,
		"auto_shoot" = false,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav", #explosion grenade
		"description"="Bombe temporel : ralentie les balles qui se trouve dans sa zone pendant 5 secondes (n'affecte pas les lasers).
		\ntype : Objet de lancé
		\ndégâts moyen: "+
		"\nMunitions: 1"
	},
	7: {"name" = "Laser de minage",
		"type" = "Dist",
		"model" = "res://Objects/laser_mining_tool/laser_mining.tscn",
		"damage" = [5, 1, 1],
		"ammo" = 100,
		"reload_time" = 1.5,
		"cadency" = 0.0,
		"dispertion" = 1,
		"aimspeed" = 3,
		"bullet_speed" = 75,
		"auto_shoot" = true,
		"reload_sound"="res://Sounds/lancement grenade real.wav", #lancement grenade
		"shoot_sound"="res://Sounds/explosion grenade real.wav",
		"description"="laser de minage.
		\ntype : Distance
		\ndégâts moyen: "+
		"\nMunitions chargeur: 8" #explosion grenade
	},
}

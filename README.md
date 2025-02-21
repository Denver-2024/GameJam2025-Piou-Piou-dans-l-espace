# GAME JAM

__Instructions__
Pour tester le multijoueur : Aller dans Debug -> Customize Run instances -> Enable Multiple Instances. Ensuite mettez le nombre d'instances qui vont se lancer. 
Quand le jeu se lance :
-Si vous avez deux instances du jeu sur la même machine (test en multijoueur simulé) alors faites start-direct -> host sur une instance puis start-direct -> join sur toutes les autres. La cnsole devrez afficher un message pour chaque instance quand le jeu se lance ("host direct" ou "join direct")
-Si vous êtes sur plusieurs machines sur le même réseau wifi alors faites multijoueur ->host sur une machine et multijoueur -> join sur les autres. Un message va s'afficher dans la console pour signifié que ce qui cherchent à rejoindre le serveur attendent l'arrivé d'un paquet udp.

__Description des composants__

- Testing_area.tscn /Node3D/ : scène de test, n'est pas destiné à être jouée.
  -> WorldEnvironement : sert a controlé le ciel, les effets de lumière et de brouillard de l'environement
  -> Floor : avec MeshInstance3D et CollisionInstance3D
  -> Bloc : lié à Bloc.tscn
  -> Floor test 1 & 2: lié à FLoor_test.tscn
  -> Rampe : lié à rampe.tscn
- Addons : Tout ce qui concerne les textures et l'aspect du jeu, on le rennomera plus tard en "textures"
  -> Vaporwavesky : ressouce pour l'environement (ciel et void)
  -> kenney_prototype_textures : textures de test

- HUD : Tout ce qui concerne l'affichage sur l'écran du Joueur
  -> Retical.gd : script qui permet de rendre le réticule dynamique (lorsque l'on se déplace)

- Menus : tout les menus du jeu, y compris ceux de départ, d'entre manches, d'UI, ect...
  - Main_MenuV2.tscn /Control/ + main_menuV2.gd : menu qui possède quatres boutons :
    -> Start Direct : mène sur direct_screen /CanvasLayer/ -> dépent de multijouer_screen.tscn qui est modifié
    -> Multijoueur : Mène sur multijoueur_screen.tscn /CanvasLayer/ 
    -> Options : ne fait rien pour l'instant, à terme doit servir à modifier les commandes (touches) et régler d'autres paramètres d'affichage (Luminosité, FOV, sensibilité, ect...)
    -> Quit game : ferme le jeu.
  - Main.tscn  /CanvasLayer/ : écran titre qui s'affiche quand on démmare Main_menuV2.tscn
  - Multiplayer_screen.tscn + multiplayer_screen.gd : écran de multijoueur avec 3 boutons et 2 champs de textes
    -> Host : créer une aprtie en tant qu'Host avec le port 135 ouvert de base
    -> Join : Si les deux champs suivants sont vides, rejoint la partie sur l'IP 0.0.0.0 et le port 135
    -> Champ IP : permet de changer l'adresse IP du serveur sur lequel on veut se connecter
    -> Champ port : permet de changer le port sur lequel on rejoint le serveur
    -> Back : retourne à l'écran principale
  - Options.tscn /CanvasLayer/ + options.gd : ébauche du menu d'options

- Objects : Tout les objets du jeu (caisse, rampe, mur, ect..) :
    -> Floor_test.tscn /Node3D/ : Plafond pour tester la fonctionnalité de se baisser (avec un MeshInstance3D et une CollisionInstance3D)
    -> Rampe.tscn /Node3D/ : Triangle Rectangle qui sert de rampe de test ----------------------------------------------------
    -> SpawnPoints.tscn /Node3D/ : Point de spawn cylindrique et quasi plat (avec un MeshInstance3D et un Marker3D qui donne la position)
    -> Sphere.tscn /Node3D/ : Test d'une sphère (avec un MeshInstance3D et une CollisionInstance3D)
    -> Damage_bloc.tscn /Node3D/ + damage_bloc.gd : bloc de dégats pour tester le système de vie

- Player : contient tout ce qui touche au joueur (Sauf armes, gadgets, mécanique de gameplay)
  -> Player.tscn /CharacterBody3D/ : Base principale de notre joueur :
      --> MeshInstance3D : forme visible du joueur
      --> ColissionInstance3D : forme de la hitbox (la même que celle du joueur)
      --> Camera /Node3D/ ---> Camera3D : Camera du joueur
      --> Animations /Animation/ : Animations du joueur :
          - */Crouch/* lorsqu'il se baisse : MeshInstance3D, ColissionInstance3D et camera se baisse de 0.5m par rapport à la position de départ en 0.5s
          - */aim/* lorsqu'il vise : déplace le node3D basic_gun au centre de l'écran, déplacement de (0.75, -0.65, -1.0) vers (0, 0.2, -0.35)
          - */change_wepaon/* lorsqu'il recharge ou change d'arme
      --> ShapeCast3D : Permet de savoir si il y a quelque chose au dessus du joueur (utile pour les conditions sur "Crouch")
      --> MultiplayerSynchronizer : Permet de synchronizer la position, rotation, taille, couleur... Tout ce qu'il y a dans "Player" pour que les autres joueurs le voient.
      --> Label3D : Affiche la vie du joueur au dessus de lui
      --> pseudo /Label3D/ : affiche le pseudo du joueur au dessus de sa vie
  -> Player.gd : script qui affecte le joueur, permet de se déplacer (en utilisant zqsd), déplacer la caméra, affecter la vitesse de saut, la gravité...etc

  - Script : contient des scripts qu'on ne sait pas ou mettre ou qui sont utiles à tout le jeu
    -> timer1.gd : script du système de manches
    -> GlobalScript.gd : contient toutes les variables globales comme le dictionnaire des armes ou qui sert a passer les informations entre le menu et le jeu principal
    -> med_kit.gd : script du medi-kit
    -> ammo_box.gd : script des boites de munition
    -> Objects.gd : permet de faire spawn un kit de soine tune boite de munition sur la scène principale (testing_area)
    -> damage_bloc.gd : script du cube de dégâts
    
__Layers__
Les layers servent à établir la collision entre deux objet (/!\ ne concerne pas certain type de node comme les label3D).
On les retrouve à droite dans l'inspecteur -> CollisionObject3D -> COllision. En haut on à les layers : quel est l'objet ? un joueur ? un props ? autre chose ? En bas on a les mask, c'est ces objets que notre objet va "chercher" à avoir une collision avec (permet d'avoir une collision et un signal émit). 
Exemple : Le joueur a la Layer 1 et le mask 3, c'est a dire qu'il va y avoir collision avec tout les objets qui on pour Layer 3. Au contraire, il va traverser les autres joueur car il ne "cherche pas" a avoir une collision avec eux.

Layer 1 : Joueurs
Layer 2 : test du cube de dégats
Layer 3 : Environement
Layer 4 : Objets

__Blender__
Blender va nous servir à modeliser des armes, objets ou terrain. Dès que vous avez fini votre modèle et que vous voulez l'importer dans Godot, suivez la procédure suivante : 
- Dans votre fichier exemple.blend, **centrée l'objet en (0,0,0) -origine du modèle** pour facilité la manipulation sur godot
- Ne pas mettre de caméra ou de lumière dans le fichier exemple.blend
- Dans File -> Export -> glTf 2.0 (.glb/.gltf) et enregistré la ou il faut
- dans Godot : faites simplement un glisser/deposer entre le File Manager (en bas à gauche) en prenant votre fichier exemple.glb et deposer le sur la scène
  
__Commandes__
  - q : gauche
  - s : arrière
  - d : droite
  - z : avant
  - Souris : contrôle la caméra
  - clic-droit : tire
  - clic-gauche : viser
  - r : recharger l'arme
  - e : intéragir
  - c : s'accroupir
  - echap : ferme le jeu

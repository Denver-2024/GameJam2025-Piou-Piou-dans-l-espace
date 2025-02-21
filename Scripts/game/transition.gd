extends CanvasLayer

@onready var Animation_player : AnimationPlayer = $AnimationPlayer
var finished : bool = false
var list_char = ["A", "B", "C", "D", "E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",",",".",":","!","?","0","1","2","3","4","5","6","7","8","9"," "]
var stop : bool = false

func stop_animations():
	stop = true
	
func change_scene(target : String) -> void:
	Animation_player.play("fading") 
	await Animation_player.animation_finished
	get_tree().change_scene_to_file(target)
	Animation_player.play_backwards("fading")

var anim_ready = true
signal resume

func _process(_delta: float) -> void:
	if !anim_ready:
		anim_ready = true
		resume.emit()

func str_animations_all(affect : Node):
	if "text" not in affect: return
	stop = false
	var chaine = affect.text
	var List_val = []
	var List_check = []
	for i in range(len(chaine)):
		List_val.append(i)
		List_check.append(0)
	
	var List_chaine = []
	var new_chaine = ""
		
	for i in range(len(chaine)):
		new_chaine+= list_char[randi_range(0, len(list_char)-1)]
	
	for elt in new_chaine:
		List_chaine.append(elt)
		
	while len(List_val) > 0:
		if stop == true:
			break
		var tpm = randi_range(0, len(List_val)-1)
		List_chaine[List_val[tpm]] = list_char[randi_range(0, len(list_char)-1)]
		List_check[List_val[tpm]]+=1
		
		if List_check[List_val[tpm]] > 10:
			List_chaine[List_val[tpm]] = chaine[List_val[tpm]]
			List_val.pop_at(tpm)
		elif List_chaine[List_val[tpm]] == chaine[List_val[tpm]]:
			List_val.pop_at(tpm)
			
		new_chaine = ""
		for elt in List_chaine:
			new_chaine+=elt
		affect.text = new_chaine
		anim_ready = false
		await resume
	affect.text = chaine
	
func str_animations(affect : Node):
	if "text" not in affect: return
	stop = false
	var chaine = affect.text
	var new_chaine = ""
	for i in range(len(chaine)):
		if stop == true:
			break
		var Cchar = ""
		var count = 0
		while(Cchar != chaine[i] and count < 6):
			if stop == true:
				break
			Cchar = list_char[randi_range(0, len(list_char)-1)]
			affect.text = new_chaine+Cchar
			count+=1
			if count >= 5:
				Cchar = chaine[i]
			anim_ready = false
			await resume
		new_chaine+=Cchar
	affect.text = chaine

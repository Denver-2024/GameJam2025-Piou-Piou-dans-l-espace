extends RichTextLabel

class_name chat_log

var nb_messages : int = 0

@rpc("any_peer", "call_local")
func print_line(ptext : String) -> void:
	nb_messages+=1
	if nb_messages>=10:
		self.clear()
		nb_messages = 0
	get_parent().show()
	get_parent().modulate = Color(1,1,1,1)
	self.newline()
	self.add_text(ptext)
	await get_tree().create_timer(5).timeout #J'ai modifié en 5 secondes
	var tpm = get_tree().create_tween()
	tpm.tween_property(get_parent(), "self_modulate", Color(1,1,1,0), 3.0)
	get_parent().hide()

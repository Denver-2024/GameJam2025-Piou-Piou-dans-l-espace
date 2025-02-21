extends MarginContainer

const keymaps_path = "res://data/keymaps.json"
var keymaps = []
@onready var reset_button : Button = $VBoxContainer/ScrollContainer/VBoxContainer/reset
@onready var accept_dialog = $"../../ConfirmationDialog"

signal upt_button_text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#prend la configuration de base de l'éditeur
	load_keymaps()
	reset_button.connect("pressed", Callable(self, "_on_reset_pressed"))
	accept_dialog.connect("confirmed", Callable(self, "reset_keybinds"))
	
func _on_reset_pressed():
	accept_dialog.show()

func reset_keybinds():
	InputMap.load_from_project_settings()
	save_keymaps()
	upt_button_text.emit()
	
func load_keymaps():
	if not FileAccess.file_exists(keymaps_path):
		save_keymaps()
		return
	
	var file = FileAccess.open(keymaps_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	for key in data.keys():
		var keymap = InputEventKey.new()
		keymap.echo = data[key]["echo"]
		keymap.physical_keycode = data[key]["keycode"]
		keymap.pressed = data[key]["pressed"]
		InputMap.action_erase_events(key)
		InputMap.action_add_event(key, keymap)
	file.close()
	upt_button_text.emit()
	
func save_keymaps():
	var file = FileAccess.open(keymaps_path, FileAccess.WRITE)
	var dic_keys = {}
	for action in InputMap.get_actions():
		if !dic_keys.has(String(action)):
			var events = InputMap.action_get_events(action)
			for event in events:
				if event is InputEventKey:
					var tpm = event as InputEventKey
					dic_keys[String(action)] = {
					"keycode" = tpm.physical_keycode,
					"location" = tpm.location,
					"pressed" = tpm.pressed,
					"echo" = tpm.echo
					}
	file.store_string(JSON.stringify(dic_keys, "\t"))
	file.close()

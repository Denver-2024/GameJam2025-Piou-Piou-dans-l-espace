extends Button

@export var action : String
@onready var input_mapper = $"../../../../.."
var dic = {
	"A (Physical)": "Q",
	"B (Physical)": "B",
	"C (Physical)": "C",
	"D (Physical)": "D",
	"E (Physical)": "E",
	"F (Physical)": "F",
	"G (Physical)": "G",
	"H (Physical)": "H",
	"I (Physical)": "I",
	"J (Physical)": "J",
	"K (Physical)": "K",
	"L (Physical)": "L",
	"M (Physical)": ";",
	"N (Physical)": "N",
	"O (Physical)": "O",
	"P (Physical)": "P",
	"Q (Physical)": "A",
	"R (Physical)": "R",
	"S (Physical)": "S",
	"T (Physical)": "T",
	"U (Physical)": "U",
	"V (Physical)": "V",
	"W (Physical)": "Z",
	"X (Physical)": "X",
	"Y (Physical)": "Y",
	"Z (Physical)": "W",
	"1 (Physical)": "&",
	"2 (Physical)": "é",
	"3 (Physical)": "\"",
	"4 (Physical)": "'",
	"5 (Physical)": "(",
	"6 (Physical)": "-",
	"7 (Physical)": "è",
	"8 (Physical)": "_",
	"9 (Physical)": "ç",
	"0 (Physical)": "à",
	"- (Physical)": ")",
	"= (Physical)": "=",
	"[ (Physical)": "^",
	"] (Physical)": "$",
	"\\ (Physical)": "*",
	"; (Physical)": "m",
	"' (Physical)": "ù",
	"` (Physical)": "²",
	", (Physical)": "?",
	". (Physical)": ".",
	"/ (Physical)": "/",
	"Shift (Physical)": "Shift",
	"Ctrl (Physical)": "Ctrl",
	"Alt (Physical)": "Alt",
	"Space (Physical)": "Espace",
	"Enter (Physical)": "Entrer",
	"Backspace (Physical)": "Retour",
	"Tab (Physical)": "Tab",
	"Caps Lock (Physical)": "Caps Lock",
	"Escape (Physical)": "Echap",
	"F1 (Physical)": "F1",
	"F2 (Physical)": "F2",
	"F3 (Physical)": "F3",
	"F4 (Physical)": "F4",
	"F5 (Physical)": "F5",
	"F6 (Physical)": "F6",
	"F7 (Physical)": "F7",
	"F8 (Physical)": "F8",
	"F9 (Physical)": "F9",
	"F10 (Physical)": "F10",
	"F11 (Physical)": "F11",
	"F12 (Physical)": "F12",
	"Insert (Physical)": "Insert",
	"Delete (Physical)": "Suppr",
	"Home (Physical)": "Home",
	"End (Physical)": "Fin",
	"Page Up (Physical)": "Page Up",
	"Page Down (Physical)": "Page Down",
	"Arrow Up (Physical)": "Flèche du haut",
	"Arrow Down (Physical)": "Flèche du bas",
	"Arrow Left (Physical)": "Flèche de gauche",
	"Arrow Right (Physical)": "Flèche de droite",
	"Num Lock (Physical)": "Verr Num",
	"Print Screen (Physical)": "Impr. écran",
	"Scroll Lock (Physical)": "Scroll Lock",
	"Pause (Physical)": "Pause"
}
func _init() -> void:
	toggle_mode = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_unhandled_input(false)
	input_mapper.connect("upt_button_text", Callable(self, "update_text"))

func _toggled(toggled_on: bool) -> void:
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		text = "Attente d'une entrée..."

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		if event.pressed:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
			release_focus()
			button_pressed = false
			update_text()
			input_mapper.save_keymaps()

func update_text():
	var map = InputMap.action_get_events(action)
	for event in map:
		var new_text = event.as_text()
		if dic.has(new_text):
			text = dic[new_text]
		else:
			text = new_text

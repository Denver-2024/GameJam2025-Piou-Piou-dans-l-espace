extends MarginContainer

@onready var PLAYER_CONTROLLER : CharacterBody3D = $"../..".get_parent().get_parent().get_parent()
@onready var item_list : ItemList = $Panel/MarginContainer/HBoxContainer/ItemList
@onready var inventory : HBoxContainer = $Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer
@onready var description : RichTextLabel = $Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer/Description

var dic_correspond = {}
var dic_button = {
1:["Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/case1",false],
2:["Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/case2",false],
3:["Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/case3",false],
4:["Panel/MarginContainer/HBoxContainer/Container/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/case4",false]}

func _ready() -> void:
	if !is_local_player():
		hide() 
	else:
		show()
	
	hide()
	var index = 0
	for key in GlobalScript.Weapons.keys():
		if key != -1:
			index = item_list.add_item(GlobalScript.Weapons[key]["name"], null, true)
			dic_correspond[key] = index
	upt_inventory()


func upt_inventory():
	if !is_local_player():return
	for key in PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory.keys():
		self.get_node(dic_button[key][0]).disabled = false
		if PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"] == -1:
			self.get_node(dic_button[key][0]).text = "vide"
		else:
			self.get_node(dic_button[key][0]).text = GlobalScript.Weapons[PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"]]["name"]
	
func is_local_player() -> bool:
	var synchronizer = PLAYER_CONTROLLER.get_node_or_null("MultiplayerSynchronizer")
	return synchronizer and synchronizer.is_multiplayer_authority()

func clear_tog(case : int):
	for key in dic_button.keys():
		if key != case:
			dic_button[key][1] = false
			self.get_node(dic_button[key][0]).set_pressed_no_signal(false)

func _on_item_list_item_selected(index: int) -> void:
	description.text = GlobalScript.Weapons[index]["description"]
	var case = 0
	for key in dic_button.keys():
		if dic_button[key][1] == true:
			case = key
	if case != 0:
		if PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[case]["id_weapon"] == -1:
			PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").load_weapon.rpc(dic_correspond[index])
		else:
			var c_weapon = 0 
			for key in PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory.keys():
				if PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"] == -1:
					PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"] = -2
			c_weapon = PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").current_weapon
			PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").current_weapon = case
			
			PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").load_weapon.rpc(dic_correspond[index])
			for key in PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory.keys():
				if PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"] == -2:
					PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").dic_inventory[key]["id_weapon"] = -1
			PLAYER_CONTROLLER.get_node("camera/Camera3D/Weapon_manager").current_weapon = c_weapon
		upt_inventory()
	else:
		item_list.deselect_all()
		return
	
func _on_case_1_toggled(toggled_on: bool) -> void:
	dic_button[1][1] = toggled_on
	clear_tog(1)
	upt_inventory()
	if toggled_on == true:
		self.get_node(dic_button[1][0]).text = "[selection]"

func _on_case_2_toggled(toggled_on: bool) -> void:
	dic_button[2][1] = toggled_on
	clear_tog(2)
	upt_inventory()
	if toggled_on == true:
		self.get_node(dic_button[2][0]).text = "[selection]"

	
func _on_case_3_toggled(toggled_on: bool) -> void:
	dic_button[3][1] = toggled_on
	clear_tog(3)
	upt_inventory()
	if toggled_on == true:
		self.get_node(dic_button[3][0]).text = "[selection]"
	
func _on_case_4_toggled(toggled_on: bool) -> void:
	dic_button[4][1] = toggled_on
	clear_tog(4)
	upt_inventory()
	if toggled_on == true:
		self.get_node(dic_button[4][0]).text = "[selection]"

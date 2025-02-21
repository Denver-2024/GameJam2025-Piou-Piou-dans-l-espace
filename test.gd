extends TextureRect

var images = {
	1: "res://addons/kenney_prototype_textures/dark/texture_01.png",
	2: "res://addons/kenney_prototype_textures/green/texture_01.png",
	3: "res://addons/kenney_prototype_textures/light/texture_01.png",
	4: "res://addons/kenney_prototype_textures/orange/texture_01.png",
	5: "res://addons/kenney_prototype_textures/purple/texture_01.png",
	6: "res://addons/kenney_prototype_textures/red/texture_01.png"
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_size(Vector2(300, 200))
	var viewport_rect = get_viewport_rect()
	var screen_width = viewport_rect.size.x
	var screen_height = viewport_rect.size.y
	
	var random_x = randi() % int((screen_width - size.x))
	var random_y = randi() % int((screen_height - size.y))
	var random_image_path = images[randi_range(1, 6)]
	
	# Créer une ImageTexture à partir de l'image chargée
	var image_texture = CompressedTexture2D.new()
	image_texture.load_path = random_image_path
	
	# Définir la texture du TextureRect
	self.texture = image_texture
	
	self.position = Vector2(random_x, random_y)
	
	await get_tree().create_timer(10.0).timeout
	print("queu free")
	queue_free()

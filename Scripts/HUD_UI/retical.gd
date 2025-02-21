extends CenterContainer

@export var RETICLE_LINES : Array[Line2D]
@onready var PLAYER_CONTROLLER : Base_Player = get_parent().get_parent().get_parent().get_parent().get_parent()
@export var RETICLE_SPEED : float = 0.25
@export var RETICLE_DISTANCE : float = 4.0
@export var DOT_RADIUS : float = 1.0
@export var DOT_COLOR : Color = Color.WHITE
@export var is_aiming = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_local_player():
		hide()  # Cache cette réticule si elle n'est pas pour ce joueur
	else:
		show()  # Assure que la réticule du joueur local est visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !is_local_player() : return
	if is_aiming == false:
		adjust_reticle_lines()
	else:
		aiming()

func _draw():
	if !is_local_player() : return
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOR)
	
func adjust_reticle_lines():
	if !is_local_player() : return
	var vel = PLAYER_CONTROLLER.get_real_velocity()
	var origin = Vector3(0,0,0)
	var pos = Vector2(0,0)
	var speed = origin.distance_to(vel)

	RETICLE_LINES[0].position =lerp(RETICLE_LINES[0].position, pos + Vector2(0, -speed * RETICLE_DISTANCE), RETICLE_SPEED)
	RETICLE_LINES[1].position =lerp(RETICLE_LINES[1].position, pos + Vector2(0, speed * RETICLE_DISTANCE), RETICLE_SPEED)
	RETICLE_LINES[2].position =lerp(RETICLE_LINES[2].position, pos + Vector2(speed * RETICLE_DISTANCE, 0), RETICLE_SPEED)
	RETICLE_LINES[3].position =lerp(RETICLE_LINES[3].position, pos + Vector2(-speed * RETICLE_DISTANCE, 0), RETICLE_SPEED)

func aiming():
	RETICLE_LINES[0].position = lerp(RETICLE_LINES[0].position, Vector2(0, 3), RETICLE_SPEED)
	RETICLE_LINES[1].position = lerp(RETICLE_LINES[1].position, Vector2(0, -3), RETICLE_SPEED)
	RETICLE_LINES[2].position = lerp(RETICLE_LINES[2].position, Vector2(-3, 0), RETICLE_SPEED)
	RETICLE_LINES[3].position = lerp(RETICLE_LINES[3].position, Vector2(3, 0), RETICLE_SPEED)
	
func is_local_player() -> bool:
	var synchronizer = PLAYER_CONTROLLER.get_node_or_null("MultiplayerSynchronizer")
	return synchronizer and synchronizer.is_multiplayer_authority()

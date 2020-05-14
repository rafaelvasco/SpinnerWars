extends RigidBody2D

onready var sprite = $Sprite
onready var collision_body = $CollisionShape2D.shape;
onready var parent = self.get_parent()

const DAMAGE_FACTOR = 0.01
const COLLISION_BODY_SIZE_FACTOR = 0.25
const GRAVITY_SCALE = 60

var element = "fire"
var level = 0
var game = null

################################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	game = get_node("/root/GameScene")
	set_sword_type(element, level)
	self.set_gravity_scale(GRAVITY_SCALE)
	self.set_contact_monitor(true)

func set_sword_type(element, level):
	self.element = element
	self.level = level
	var props = game.sword_props[element][level]
	var texture = props.texture
	var tex_width = texture.get_width() * props.scale
	var tex_height = texture.get_height() * props.scale
	sprite.set_texture(texture)
	sprite.set_scale(Vector2(props.scale, props.scale))
	collision_body.set_extents(Vector2(tex_height/2, tex_width * COLLISION_BODY_SIZE_FACTOR))
	self.set_weight(props.weight)
	
	
	
func _on_sword_collision(body):
	if body is KinematicBody2D:
		var props = game.sword_props[self.element][self.level]
		var weight = props.weight
		var damage = (self.linear_velocity.length() * weight) * DAMAGE_FACTOR
		body.process_damage(get_tree().get_network_unique_id(), body.player_id, damage)

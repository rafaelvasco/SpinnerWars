extends KinematicBody2D

export var drag_speed = 2000
export var input_speed = 500

const SPINNER_ROTATION_SPEED = 500
const POS_INTERPOLATION_FACTOR = 16
const STATE_IDLE = 0
const STATE_RECEIVED_DAMAGE = 1
const STATE_DEAD = 2

onready var sword_scene = preload("res://Entities/Sword.tscn")
onready var joint = $PinJoint2D
onready var spinner = $Spinner
onready var timer = $Timer

var sword: RigidBody2D
var player_name = ""
var player_id = 0
var is_dragging = false
var state = STATE_IDLE
var life = 5
var stamina = 10
var settled_on_position = false

puppet var puppet_pos = Vector2()
puppet var puppet_mov = Vector2()
puppet var puppet_ang_vel = 0
puppet var puppet_state = STATE_IDLE


func _ready():
	init_sword()

func init_sword():
	self.sword = sword_scene.instance()
	add_child(self.sword)	
	joint.set_node_b(self.sword.get_path())
	set_sword("fire", 0)


remote func set_sword(element, level):
	self.sword.set_sword_type(element, level)


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			is_dragging = event.pressed


func _process(_delta):
	self.spinner.rotation_degrees += SPINNER_ROTATION_SPEED * _delta


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			is_dragging = false
			
			
func _physics_process(delta):
	
	var motion = Vector2()
	var pos = Vector2()
	var ang_vel = 0
	
	if is_network_master():
		
		# Get player input
		var direction: Vector2
		direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		# If input is digital, normalize for diagonal movement
		if abs(direction.x) == 1 and abs(direction.y) == 1:
			direction = direction.normalized()
		
		# Calculate movement
		motion = input_speed * direction * delta
		
		pos = self.position
		
		# If dragging, use mouse position to calculate movement
		if is_dragging:
			var new_pos = get_global_mouse_position()
			motion = new_pos - position
			if motion.length() > (drag_speed * delta):
				motion = drag_speed * delta * motion.normalized()
		
		rset("puppet_pos", pos)
		rset("puppet_mov", motion)		
		rset("puppet_ang_vel", self.sword.angular_velocity)
		
	else :
		pos = puppet_pos
		motion = puppet_mov
		ang_vel = puppet_ang_vel
		
	# Apply movement
# warning-ignore:return_value_discarded
	move_and_collide(motion)
	
	if not is_network_master():
		puppet_mov = motion
		puppet_ang_vel = ang_vel
		puppet_pos = pos
		self.sword.set_angular_velocity(ang_vel)
		if not self.settled_on_position:
			self.position = pos
			self.settled_on_position = true
		else:
			self.position = self.position.linear_interpolate(pos, delta * POS_INTERPOLATION_FACTOR)
		
	
func set_player_name(new_name):
	self.player_name = new_name
	
	
func set_player_id(id):
	self.player_id = id
	

sync func process_damage(source_player_id, target_player_id, damage):
	
	if source_player_id == target_player_id:
		return
	
	if self.state == STATE_DEAD:
		return
	
	self.set_state(STATE_RECEIVED_DAMAGE)
	self.life -= damage
	if self.life <= 0:
		self.life = 0
		self.set_state(STATE_DEAD)
		
	print('Player ' + str(target_player_id) + ' received damage: ' + str(damage))
	print('Player ' + str(target_player_id) + ' life is now: ' + str(self.life))
	
	if target_player_id != get_tree().get_network_unique_id():
		rpc_id(target_player_id, "synch_state", self.state, self.life, self.stamina)
		
		
sync func set_state(state):
	self.state = state
	if state == STATE_RECEIVED_DAMAGE:
		self.timer.start(1.5)
		self.spinner.set_modulate(Color(1, 0, 0, 1))
	elif state == STATE_IDLE:
		self.spinner.set_modulate(Color(1, 1, 1, 1))
	elif state == STATE_DEAD:
		self.spinner.set_modulate(Color(0, 1, 0, 1))


remote func synch_state(state, life, stamina):
	print('Synching state...')
	print('Received state = ' + str(state))
	print('Received life = ' + str(life))
	print('Received stamina = ' + str(stamina))
	self.life = life
	self.stamina = stamina
	self.set_state(state)


func _on_timer_timeout():
	print('Damage Timer Timeout')
	if self.life > 0:
		self.set_state(STATE_IDLE)
		
			

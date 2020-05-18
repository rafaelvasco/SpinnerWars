extends Node

const DEFAULT_CONN_PORT = 10567
const MAX_PLAYERS = 12

var player_name = ""

# Names for remote players in id:name format.
master var players = {}
master var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(error)

master var host = null
var client = null

puppet var game_ongoing = false

func _ready():
	print('GAME MANAGER READY')
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connected_fail")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	
# Callback from SceneTree
func _player_connected(id):
	print('PLAYER CONNECTED: ' + str(id))
	# Registration of a client begins here, tell the connected player that we are here.
	rpc_id(id, "register_player", player_name)


# Callback from SceneTree
func _player_disconnected(id):
	print('PLAYER DISCONNECTED: ' + str(id))
	
	if get_tree().is_network_server():
		var player_name = players[id]
		unregister_player(id)
		if game_ongoing:
			emit_signal("game_error", "Player " + player_name + " disconnected.")			
			end_game()
	
				
# Client only callback			
func _connected_ok():
	print('CONNECTION OK')
	# We just connected to a server 
	emit_signal("connection_succeeded")


# Client only callback 
func _connected_fail():
	print('CONNECTION FAIL')
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")


# Client only callback	
func _server_disconnected():
	print('SERVER DISCONNECTED')
	emit_signal("game_error", "Server disconnected.")
	
#### Lobby Management Functions ####

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print('REGISTER PLAYER: ' + new_player_name + ', ' + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")
	

func unregister_player(id):
	print('UNREGISTER PLAYER: ' + str(id))
	print(players)
	players.erase(id)
	emit_signal("player_list_changed")
	

remote func pre_start_game(spawn_points):
	print('PRE START GAME')
	var game_scene = load("res://Game.tscn").instance()
	get_tree().get_root().add_child(game_scene)
	get_tree().get_root().get_node("Lobby").hide()
	
	var player_scene = load("res://Entities/Player.tscn")
	
	for p_id in spawn_points:
		var spawn_pos = game_scene.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()
		
		player.set_name(str(p_id))
		player.set_player_id(p_id)
		player.set_network_master(p_id)
		player.position = spawn_pos
		
		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id])
			
		game_scene.get_node("Players").add_child(player)
		
		
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()
		
			
remote func post_start_game():
	print('POST START GAME')
	get_tree().set_pause(false)
	game_ongoing = true
	if (get_tree().is_network_server()):
		rset("game_ongoing", true)
		

remote func ready_to_start(id):
	print('READY TO START')
	assert(get_tree().is_network_server())
	
	if not id in players_ready:
		players_ready.append(id)
		
	print(players_ready)
	print(players)
	if players_ready.size() == players.size():
		
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()
		
	
func host_game(new_player_name):
	print('HOST GAME: ' + new_player_name)
	player_name = new_player_name
	self.host = NetworkedMultiplayerENet.new()
	var result = self.host.create_server(DEFAULT_CONN_PORT, MAX_PLAYERS)
	if result == OK:
		get_tree().set_network_peer(host)
	else:
		print("Failed to create server")
		return
	
	print('HOST GAME RESULT: ' + str(result))
	return result
	


func join_game(ip, new_player_name):
	print('JOIN GAME: ' + new_player_name)
	player_name = new_player_name
	self.client = NetworkedMultiplayerENet.new()
	var result = self.client.create_client(ip, DEFAULT_CONN_PORT)
	if result == OK:
		get_tree().set_network_peer(client)
		
	return result
	

func get_player_list():
	return players.values()
	

func get_player_name():
	return player_name


func begin_game():
	print('BEGIN GAME')
	assert(get_tree().is_network_server())
	
	# Create a dictionary with peer id and respective spawn points
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point zero
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points.
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)
		
	pre_start_game(spawn_points)


func end_game():
	print('END GAME')
	# Game is in progress.
	if has_node("/root/GameScene"):
		get_node("/root/GameScene").queue_free()
	
	emit_signal("game_ended")	
	players.clear()
	players_ready.clear()
	game_ongoing = false
	if get_tree().is_network_server():
		#self.host.close_connection()
		rset("game_ongoing", false)
		

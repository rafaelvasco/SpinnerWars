extends Node

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal game_ended()
signal game_error(error)

onready var game_scene = preload("res://Game.tscn")
onready var player_scene = preload("res://Entities/Player.tscn")

const API_URL_REMOVE_MATCH = "http://localhost:59485/api/match/remove/"

var player = {}
var connected_player = {}
var server_established = false
var quit_game_requested = false
var game_scene_instance = null
var remove_match_http_request = null
var current_match = null
var game_ongoing = false

master var server = null
slave var client = null

################################################################################

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().set_auto_accept_quit(false)
	
	self.remove_match_http_request = HTTPRequest.new()
	self.add_child(self.remove_match_http_request)
	self.remove_match_http_request.connect("request_completed", self, "_on_request_match_remove_completed")
	
	
# Callback from SceneTree
func _player_connected(id):
	self.player.player_id = get_tree().get_network_unique_id()
	rpc_id(id, "register_player", self.player)
	

# Callback from SceneTree
func _player_disconnected(id):
	if get_tree().is_network_server():
		self.despawn_player(id)
	

# Client only callback 
func _connected_fail():
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")

# Client only callback
func _connected_to_server():
	pass


# Client only callback	
func _server_disconnected():
	end_game(true)
	

remote func register_player(player):
	self.connected_player = player
	if get_tree().is_network_server():
		# If we're the server, spawn connected player (client) at point one.
		spawn_player(1, self.connected_player)
	else:
		# If we're the client, now that our server is registered we can create
		# and start the game.
		create_game_scene()
		spawn_player(0, self.connected_player)
		spawn_player(1, self.player)
		start_game()
	
func create_game(_match):
	self.current_match = _match
	self.player = _match.server.player
	self.player.player_id = 1
	self.server = NetworkedMultiplayerENet.new()
	var result = self.server.create_server(int(_match.server.port), 2)
	if result == OK:
		get_tree().set_network_peer(self.server)
		create_game_scene()
		spawn_player(0, self.player)
		start_game()
		self.server_established = true
	
	return result
	
	
func request_join(_match):
	self.current_match = _match
	self.player = _match.client.player
	self.client = NetworkedMultiplayerENet.new()
	var server_ip = _match.server.ip
	var server_port = _match.server.port
	var result = self.client.create_client(server_ip, int(server_port))
	get_tree().set_network_peer(self.client)
	return result


remote func create_game_scene():
	self.game_scene_instance = game_scene.instance()
	get_tree().get_root().add_child(self.game_scene_instance)
	get_tree().get_root().get_node("Lobby").hide()
	

func spawn_player(spawn_point, player_data):
	var spawn_pos = self.game_scene_instance.get_node("SpawnPoints/" + str(spawn_point)).position
	var player = player_scene.instance()
	player.set_name(str(player_data.player_id))
	player.set_player_name(player_data.name)
	player.set_player_id(player_data.player_id)
	player.set_network_master(player_data.player_id)
	player.position = spawn_pos
	self.game_scene_instance.get_node("Players").add_child(player)
	
master func despawn_player(player_id):
	var player_node = self.game_scene_instance.get_node("Players").get_node(str(player_id))
	player_node.queue_free()
	self.connected_player = {}
	

func start_game():
	get_tree().set_pause(false)
	self.game_ongoing = true


func end_game(server_disconnected=false):
	if has_node("/root/GameScene"):
		get_node("/root/GameScene").queue_free()
		
	self.connected_player = {}
	self.game_ongoing = false
	
	if self.current_match != null:
	
		var is_server = get_tree().is_network_server()
		if not is_server:
			self.current_match = null
			if self.client != null and not server_disconnected:
				self.client.close_connection()
			if not self.quit_game_requested:
				emit_signal("game_ended")
			else:
				get_tree().quit()
		else:
			if self.server != null:
				self.server.close_connection()
			self._request_match_remove()
	else:
		if self.quit_game_requested:
			get_tree().quit()
		else:
			emit_signal("game_ended")
		
		
func _request_match_remove():
	var error = self.remove_match_http_request.request(API_URL_REMOVE_MATCH + current_match.id, PoolStringArray([]), false, HTTPClient.METHOD_DELETE)
	if error != OK:
		push_error("And error occurred while requesting match deletion")


func _on_request_match_remove_completed(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		self.current_match = null
		if self.quit_game_requested:
			get_tree().quit()
		else:
			emit_signal("game_ended")
	else:
		var response = JSON.parse(body.get_string_from_utf8())
		push_error("Error while removing match: " + response)
	
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		self.quit_game_requested = true
		end_game()
		

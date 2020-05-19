extends Node

var player = null
master var connected_player = null
master var current_match = null

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(error)

onready var game_scene = preload("res://Game.tscn")
onready var player_scene = preload("res://Entities/Player.tscn")

const API_URL_REMOVE_MATCH = "http://localhost:59485/api/match/remove/"

var remove_match_http_request = null

puppet var game_ongoing = false
var server_established = false
var quit_game_requested = false
var game_scene_instance = null

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().set_auto_accept_quit(false)
	
	self.remove_match_http_request = HTTPRequest.new()
	self.add_child(self.remove_match_http_request)
	self.remove_match_http_request.connect("request_completed", self, "_on_request_match_remove_completed")
	
	
# Callback from SceneTree
func _player_connected(id):
	rpc_id(id, "register_player", player.name)


# Callback from SceneTree
func _player_disconnected(id):
	if get_tree().is_network_server():
		var player_name = 	connected_player.name
		connected_player = null
		if game_ongoing:
			#Show player disconnected msg
			pass
	
				
# Client only callback			
func _connected_ok():
	emit_signal("connection_succeeded")


# Client only callback 
func _connected_fail():
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")


# Client only callback	
func _server_disconnected():
	emit_signal("game_error", "Server disconnected.")
	

remote func register_player(player_name):
	var id = get_tree().get_rpc_sender_id()
	self.connected_player = {
		"id": id,
		"name": player_name
	}

	
func create_game(player, _match):
	
	self.player = player
	self.current_match = _match
	self.player.player_id = 1
	var server = NetworkedMultiplayerENet.new()
	var result = server.create_server(int(player.port), 2)
	if result == OK:
		print('Creating Game:')
		print(player)
		get_tree().set_network_peer(server)
		create_game_scene()
		spawn_players(self.player, null)
		start_game()
		self.server_established = true
	else:
		return false
	
	return result

remote func create_game_scene():
	self.game_scene_instance = game_scene.instance()
	get_tree().get_root().add_child(self.game_scene_instance)
	get_tree().get_root().get_node("Lobby").hide()
	
	

remote func spawn_players(server, client):
	spawn_player(0, server)
	if(client != null):
		spawn_player(0, client)


func spawn_player(spawn_point, player_data):
	var spawn_pos = self.game_scene_instance.get_node("SpawnPoints/" + str(spawn_point)).position
	var player = player_scene.instance()
	player.set_name(player_data.name)
	player.set_player_name(player_data.name)
	player.set_player_id(player_data.player_id)
	player.set_network_master(player_data.player_id)
	player.position = spawn_pos
	self.game_scene_instance.get_node("Players").add_child(player)
	

func join_game(player, _match):
	self.player = player
	var client = NetworkedMultiplayerENet.new()
	var server_ip = _match.server.ip
	var server_port = _match.server.port
	var result = client.create_client(server_ip, server_port)
	if result == OK:
		get_tree().set_network_peer(client)
		create_game_scene()
		spawn_players(self.connected_player, self.player)
		start_game()
		return result
	return false
	

func start_game():
	get_tree().set_pause(false)
	self.game_ongoing = true


func end_game():
	if has_node("/root/GameScene"):
		get_node("/root/GameScene").queue_free()
	
		
	connected_player = null
	game_ongoing = false
	if self.current_match != null and get_tree().is_network_server():
		self._request_match_remove()
	elif self.quit_game_requested:
		get_tree().quit()
	else: 
		emit_signal("game_ended")
		
func _request_match_remove():
	
	var error = self.remove_match_http_request.request(API_URL_REMOVE_MATCH + current_match.db_id, PoolStringArray([]), false, HTTPClient.METHOD_DELETE)
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
		

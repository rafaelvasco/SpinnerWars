extends Control

onready var waiting_challenger_panel = $WaitingChallenger
onready var match_list_panel = $MatchList

onready var match_list_request = $MatchList/ListMatchesRequest
onready var add_host_player_request = $MatchList/AddHostRequest
onready var crate_match_request = $MatchList/CreateMatchRequest
onready var join_request = $MatchList/JoinRequest

onready var label_msg = $MatchList/Label_Msg
onready var msg_timer = $MsgTimer
onready var error_dialog = $ErrorDialog
onready var match_list_control = $MatchList/List_Matches

const API_URL_MATCH_LIST = "http://localhost:59485/api/match"
const API_ADD_PLAYER = "http://localhost:59485/api/player/add"
const API_GET_PLAYER = "http://localhost:59485/api/player/"
const API_CREATE_MATCH = "http://localhost:59485/api/match/add"
const USE_SSL = false

var matches = []
var selected_match = null

func _ready():
	
	GameManager.connect("connection_failed", self, "_on_connection_failed")
	GameManager.connect("connection_succeeded", self, "_on_connection_success")
	GameManager.connect("game_ended", self, "_on_game_ended")
	GameManager.connect("game_error", self, "_on_game_error")
	
	match_list_request.connect("request_completed", self, "_on_matchlist_response")
	add_host_player_request.connect("request_completed", self, "_on_host_player_added_response")
	crate_match_request.connect("request_completed", self, "_on_create_match_response")
	label_msg.text = ""

################################################################################
# Node Methods
################################################################################

func new_match():
	
	_show_info_msg("Processing...", false)
	
	var player = {
		"email": "rafaelvasco87@gmail.com",
		"name": "Rafael Vasco"
	}
	var query = JSON.print(player)
	var headers = ["Content-Type: application/json"]
	
	var connect = add_host_player_request.request(API_ADD_PLAYER, headers, USE_SSL, HTTPClient.METHOD_PUT, query)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")

func join_match(_match):
	pass


func load_matches():
	_show_info_msg("Requesting match list...")
	var connect = match_list_request.request(API_URL_MATCH_LIST)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")

# ##############################################################################
# Master Server API Responses
# ##############################################################################
func _on_matchlist_response(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		self.matches = JSON.parse(body.get_string_from_utf8()).result
		self.match_list_control.clear()
		if not self.matches.empty():
			for m in self.matches:
				self.match_list_control.add_item(m.server.player.name)
	else:
		_show_error_msg("An error occurred while fetching the match list.")
		push_error("An error occurred while fetching the match list.")


func _on_host_player_added_response(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		var player = JSON.parse(body.get_string_from_utf8()).result
		var request = {
			"serverPlayerId": player.id
		}

		var query = JSON.print(request)
		var create_match_headers = ["Content-Type: application/json"]

		var connect = crate_match_request.request(
			API_CREATE_MATCH, create_match_headers, USE_SSL, HTTPClient.METHOD_PUT, query
		)
		if connect != OK:
			_show_error_msg("An error occurred while trying to connect to server.")
			push_error("An error occurred while trying to connect to server.")
	else:
		_show_error_msg("An error occurred while registering host player: " + str(result))
		push_error("An error occurred while registering host player: " + str(result))	

func _on_create_match_response(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		var result_match = JSON.parse(body.get_string_from_utf8()).result
		var server_ip = result_match["server"]["ip"]
		var server_port = result_match["server"]["port"]
		var server_player_name = result_match["server"]["player"]["name"]
		var player = {
			"name": server_player_name,
			"player_id": 1,
			"ip": server_ip,
			"port": server_port
		}
		var _match = {
			"db_id": result_match["id"]
		}
		GameManager.create_game(player, _match)
		self._clear_msg()
		match_list_panel.hide()
	else:
		_show_error_msg("An error occurred while creating host player: " + str(result))
		push_error("An error occurred while creating host player" + str(result))	

################################################################################
# Node Methods 
################################################################################

func _show_error_msg(msg):
	label_msg.text = msg
	label_msg.set("custom_colors/font_color", Color(1,0,0))
	msg_timer.start(3)
	

func _show_info_msg(msg, auto_hide=true):
	label_msg.text = msg
	label_msg.set("custom_colors/font_color", Color(0,1,0))
	if auto_hide:
		msg_timer.start(3)

func _clear_msg():
	label_msg.text = ""

func _on_game_ended():
	show()
	match_list_panel.show()
	self.load_matches()
	
func _on_game_error():
	pass


func _on_msg_timeout():
	label_msg.text = ""


func _on_request_pressed():
	self.load_matches()


func _on_button_new_host_pressed():
	self.new_match()


func _on_button_join_pressed():
	if self.selected_match != null:
		self.join_match(self.selected_match)
	else:
		_show_error_msg("Please select a match to enter first.")
	

func _on_match_list_selected(index):
	self.selected_match = self.matches[index]

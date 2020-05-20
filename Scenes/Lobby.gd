extends Control

onready var waiting_challenger_panel = $WaitingChallenger
onready var match_list_panel = $MatchList

onready var match_list_request = $MatchList/ListMatchesRequest
onready var add_host_player_request = $MatchList/AddHostRequest
onready var add_client_player_request = $MatchList/AddClientRequest
onready var crate_match_request = $MatchList/CreateMatchRequest
onready var join_request = $MatchList/JoinRequest

onready var label_msg = $MatchList/Label_Msg
onready var msg_timer = $MsgTimer
onready var refresh_matches_timer = $RefreshMatchesTimer
onready var error_dialog = $ErrorDialog
onready var match_list_control = $MatchList/List_Matches

const API_URL_MATCH_LIST = "http://localhost:59485/api/match"
const API_ADD_PLAYER = "http://localhost:59485/api/player/add"
const API_GET_PLAYER = "http://localhost:59485/api/player/"
const API_CREATE_MATCH = "http://localhost:59485/api/match/add"
const API_JOIN_MATCH = "http://localhost:59485/api/match/join"
const USE_SSL = false

var matches = []
var selected_match_index = -1
var loading_matches = false

func _ready():
	
	GameManager.connect("game_ended", self, "_on_game_ended")
	GameManager.connect("game_error", self, "_on_game_error")
	GameManager.connect("connection_failed", self, "_on_client_connection_failed")
	
	match_list_request.connect("request_completed", self, "_on_matchlist_response")
	add_host_player_request.connect("request_completed", self, "_on_host_player_added_response")
	add_client_player_request.connect("request_completed", self, "_on_client_player_added_response")
	crate_match_request.connect("request_completed", self, "_on_create_match_response")
	join_request.connect("request_completed", self, "_on_join_match_response")
	label_msg.text = ""

################################################################################
# Node Methods
################################################################################

func new_match():
	
	_show_info_msg("Processing...", false)
	
	# TEMP
	var player = {
		"email": "rafaelvasco87@gmail.com",
		"name": "Rafael Vasco"
	}
	var query = JSON.print(player)
	var headers = ["Content-Type: application/json"]
	
	var connect = add_host_player_request.request(API_ADD_PLAYER, headers, USE_SSL, HTTPClient.METHOD_PUT, query)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server. Please try again")
		push_error("An error occurred while trying to connect to server. Please try again")

func join_match(_match):
	
	_show_info_msg("Processing...", false)
	
	#TEMP
	var player = {
		"email": "vascorafael@gmail.com",
		"name": "Vasco Rafael"
	}
	
	var query = JSON.print(player)
	var headers = ["Content-Type: application/json"]
	
	var connect = add_client_player_request.request(API_ADD_PLAYER, headers, USE_SSL, HTTPClient.METHOD_PUT, query)

	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server. Please try again")
		push_error("An error occurred while trying to connect to server. Please try again")


func load_matches():
	self.loading_matches = true
	var connect = match_list_request.request(API_URL_MATCH_LIST)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")

func refresh_matches_view():
	self.match_list_control.clear()
	if not self.matches.empty():
		for m in self.matches:
			self.match_list_control.add_item(m.server.player.name)
		if self.selected_match_index > -1:
			self.match_list_control.select(self.selected_match_index)


# ##############################################################################
# Master Server API Responses
# ##############################################################################
func _on_matchlist_response(result, response_code, headers, body):
	self.loading_matches = false
	if result == HTTPRequest.RESULT_SUCCESS:
		self.matches = JSON.parse(body.get_string_from_utf8()).result
		if self.matches.size() == 0:
			self.selected_match_index = -1
		else:
			if self.selected_match_index > self.matches.size() - 1:
				self.selected_match_index = self.matches.size() - 1
			
		self.refresh_matches_view()
	else:
		_show_error_msg("An error occurred while fetching the match list.")
		push_error("An error occurred while fetching the match list.")


func _on_host_player_added_response(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		
		# Once host player is registered (if not already), send create match request:
		var player = JSON.parse(body.get_string_from_utf8()).result
		var request = {
			"serverPlayerId": player.id
		}
		self._send_create_match_request(request)
		
	else:
		_show_error_msg("An error occurred while registering host player: " + str(result))
		push_error("An error occurred while registering host player: " + str(result))	


func _send_create_match_request(request):
	var query = JSON.print(request)
	var headers = ["Content-Type: application/json"]
	var connect = crate_match_request.request(
		API_CREATE_MATCH, headers, USE_SSL, HTTPClient.METHOD_PUT, query
	)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")
	

func _on_client_player_added_response(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS:
		# Once client player is returned, send join match request:
		var player = JSON.parse(body.get_string_from_utf8()).result
		var _match = self.matches[self.selected_match_index]
		var request = {
			"matchId": _match.id,
			"playerId": player.id,
			"serverPort": _match.server.port
		}
		self._send_join_match_request(request)
	else:
		_show_error_msg("An error occurred while registering host player: " + str(result))
		push_error("An error occurred while registering host player: " + str(result))	


func _on_client_connection_failed():
	_show_error_msg("Could not connect to match. Please try again.")
	push_error("Could not connect to match. Please try again.")


func _send_join_match_request(request):
	var query = JSON.print(request)
	var headers = ["Content-Type: application/json"]
	var connect = join_request.request(
		API_JOIN_MATCH, headers, USE_SSL, HTTPClient.METHOD_POST, query
	)
	if connect != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")


func _on_create_match_response(result, response_code, headers, body):
	var response_match = JSON.parse(body.get_string_from_utf8()).result
	if result == HTTPRequest.RESULT_SUCCESS:
		var create_result = GameManager.create_game(response_match)
		if create_result == OK:
			self._clear_msg()
			self.hide()
		else:
			_show_error_msg("An error occurred while creating match: Please try again")
			push_error("An error occurred while creating match: " + str(create_result))	
	else:
		_show_error_msg("An error occurred while creating match: Please try again")
		push_error("An error occurred while creating match: " + str(response_match))	


func _on_join_match_response(result, response_code, headers, body):
	var response_match = JSON.parse(body.get_string_from_utf8()).result
	if result == HTTPRequest.RESULT_SUCCESS:
		
		if response_match != null:
			var join_result =  GameManager.request_join(response_match)
			if join_result == OK:
				_clear_msg()
				self.hide()	
			else:
				_show_error_msg("An error occurred while joining match: Please try again.")
				push_error("An error occurred while joining match: " + str(join_result))
		else:
			_show_error_msg("Couldn't connect to this match. It's already over.")
			push_error("Couldn't connect to this match. It's already over.")
		
	else:
		_show_error_msg("An error occurred while joining match: Please try again.")
		push_error("An error occurred while joining match: " + str(response_match))	

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


func _on_button_new_host_pressed():
	self.new_match()


func _on_button_join_pressed():
	if self.selected_match_index > -1:
		self.join_match(self.matches[self.selected_match_index])
	else:
		_show_error_msg("Please select a match to enter first.")
	

func _on_match_list_selected(index):
	self.selected_match_index = index


func _on_refresh_matches_timeout():
	if not self.loading_matches:
		self.load_matches()

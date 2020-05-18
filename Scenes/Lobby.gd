extends Control

onready var match_list_request = $MatchList/ListMatchesRequest;

const API_URL_MATCH_LIST = "http://localhost:59485/api/match"

var matches = []

onready var label_error = $MatchList/Label_Error
onready var msg_timer = $MsgTimer
onready var error_dialog = $ErrorDialog
onready var match_list_control = $MatchList/List_Matches


func _ready():
	
	GameManager.connect("connection_failed", self, "_on_connection_failed")
	GameManager.connect("connection_succeeded", self, "_on_connection_success")
	GameManager.connect("player_list_changed", self, "refresh_lobby")
	GameManager.connect("game_ended", self, "_on_game_ended")
	GameManager.connect("game_error", self, "_on_game_error")
	
	match_list_request.connect("request_completed", self, "_on_matchlist_received")
	label_error.text = ""
	

func load_matches():
	print("Requesting match list...")
	var error = match_list_request.request(API_URL_MATCH_LIST)
	if error != OK:
		_show_error_msg("An error occurred while trying to connect to server.")
		push_error("An error occurred while trying to connect to server.")

func _on_matchlist_received(result, response_code, headers, body):
	
	if result == HTTPRequest.RESULT_SUCCESS:
		self.matches = JSON.parse(body.get_string_from_utf8()).result
		
		for m in self.matches:
			self.match_list_control.add_item(m.server.player.name)
		
	
	else:
		_show_error_msg("An error occurred while fetching the match list.")
		push_error("An error occurred while fetching the match list.")
	


#func _on_host_pressed():
#	if $Connect/Input_Name.text == "":
#		_show_error_msg("Invalid Player Name!")
#		return
#
#
#	var player_name = $Connect/Input_Name.text
#	var result = GameManager.host_game(player_name)
#	if (result == OK):
#		$Connect.hide()
#		$Players.show()
#		$Connect/Label_Error.text = ""
#		refresh_lobby()
#	else:
#		_show_error_msg("Could not host server. Probably, there's already a server running on this IP: " + str(result))


#func _on_join_pressed():
#	if $Connect/Input_Name.text == "":
#		_show_error_msg("Invalid Player Name!")
#		return
#	var ip = $Connect/Input_IP.text
#	if not ip.is_valid_ip_address():
#		_show_error_msg("Invalid IP Address!")
#		return
#
#	$Connect/Label_Error.text = ""
#
#	var player_name = $Connect/Input_Name.text
#	var result = GameManager.join_game(ip, player_name)
#
#	if result == OK:
#		$Connect/Button_Host.disabled = true
#		$Connect/Button_Join.disabled = true
#	else:
#		$Connect/Button_Host.disabled = false
#		$Connect/Button_Join.disabled = false
#
#		_show_error_msg("Couldn't connect to server: " + str(result))
	

func _on_connection_success():
#	$Connect.hide()
#	$Players.show()
	pass
	
func _on_connection_failed():
#	$Connect/Button_Host.disabled = false
#	$Connect/Button_Join.disabled = false
#	_show_error_msg("Connection failed. Please try again.")
	pass
	
func _on_game_ended():
	refresh_lobby()
	show()
#	$Connect.hide()
#	$Players.show()
#	$Connect/Button_Host.disabled = true
#	$Connect/Button_Join.disabled = true
	
func _on_game_error(error_txt):
	error_dialog.dialog_text = error_txt
	error_dialog.popup_centered_minsize()	
#	$Connect/Button_Host.disabled = false
#	$Connect/Button_Join.disabled = false

func refresh_lobby():
#	var players = GameManager.get_player_list()
#	players.sort()
#	$Players/List_Players.clear()
#	$Players/List_Players.add_item(GameManager.get_player_name() + "(You)")
#	for p in players:
#		$Players/List_Players.add_item(p)
#
#	$Players/Button_Start.disabled = not get_tree().is_network_server()
	pass

func _show_error_msg(msg):
	label_error.text = msg
	msg_timer.start(3)


func _on_msg_timeout():
	label_error.text = ""


func _on_request_pressed():
	self.load_matches()

extends Control


func _ready():
	GameManager.connect("connection_failed", self, "_on_connection_failed")
	GameManager.connect("connection_succeeded", self, "_on_connection_success")
	GameManager.connect("player_list_changed", self, "refresh_lobby")
	GameManager.connect("game_ended", self, "_on_game_ended")
	GameManager.connect("game_error", self, "_on_game_error")
	
	# Set the player name according to the system user name. Fallback to the path
	if OS.has_environment("USERNAME"):
		$Connect/Input_Name.text = OS.get_environment("USERNAME")
	else:
		$Connect/Input_Name.text = "GameHost"
	

func _on_host_pressed():
	if $Connect/Input_Name.text == "":
		_show_error_msg("Invalid Player Name!")
		return
	
	
	var player_name = $Connect/Input_Name.text
	var result = GameManager.host_game(player_name)
	if (result == OK):
		$Connect.hide()
		$Players.show()
		$Connect/Label_Error.text = ""
		refresh_lobby()
	else:
		_show_error_msg("Could not host server. Probably, there's already a server running on this IP: " + str(result))


func _on_join_pressed():
	if $Connect/Input_Name.text == "":
		_show_error_msg("Invalid Player Name!")
		return
	var ip = $Connect/Input_IP.text
	if not ip.is_valid_ip_address():
		_show_error_msg("Invalid IP Address!")
		return
	
	$Connect/Label_Error.text = ""
	
	var player_name = $Connect/Input_Name.text
	var result = GameManager.join_game(ip, player_name)
	
	if result == OK:
		$Connect/Button_Host.disabled = true
		$Connect/Button_Join.disabled = true
	else:
		$Connect/Button_Host.disabled = false
		$Connect/Button_Join.disabled = false
		
		_show_error_msg("Couldn't connect to server: " + str(result))
	

func _on_connection_success():
	$Connect.hide()
	$Players.show()
	
func _on_connection_failed():
	$Connect/Button_Host.disabled = false
	$Connect/Button_Join.disabled = false
	_show_error_msg("Connection failed. Please try again.")
	
func _on_game_ended():
	refresh_lobby()
	show()
	$Connect.hide()
	$Players.show()
	$Connect/Button_Host.disabled = true
	$Connect/Button_Join.disabled = true
	
func _on_game_error(error_txt):
	$ErrorDialog.dialog_text = error_txt
	$ErrorDialog.popup_centered_minsize()	
	$Connect/Button_Host.disabled = false
	$Connect/Button_Join.disabled = false

func refresh_lobby():
	var players = GameManager.get_player_list()
	players.sort()
	$Players/List_Players.clear()
	$Players/List_Players.add_item(GameManager.get_player_name() + "(You)")
	for p in players:
		$Players/List_Players.add_item(p)
	
	$Players/Button_Start.disabled = not get_tree().is_network_server()

func _show_error_msg(msg):
	$Connect/Label_Error.text = msg
	$MsgTimer.start(3)


func _on_Button_Start_pressed():
	GameManager.begin_game()


func _on_msg_timeout():
	$Connect/Label_Error.text = ""

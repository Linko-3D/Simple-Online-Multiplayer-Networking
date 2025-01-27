extends Node


@export var player : PackedScene
@export var map : PackedScene


func _ready() -> void:
	print(get_viewport().size.x)
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(9999)
	%PublicIP.text = upnp.query_external_address()

	_on_join_button_pressed() # The clients will automatically join if a local server is created


func _process(delta: float) -> void:
	%Say.size.x = get_viewport().size.x / 2
	%Say.position.x = get_viewport().size.x / 4
	if Input.is_action_just_pressed("ui_accept"):
		%Say.visible = !%Say.visible
		if not %Say.visible:
			send_message.rpc(multiplayer.get_unique_id(), %Say.text)
			%Say.text = ""
			


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999)
	multiplayer.multiplayer_peer = peer

	multiplayer.peer_disconnected.connect(remove_player)

	%Server.show()

	load_game()


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(%To.text, 9999)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(load_game)
	multiplayer.server_disconnected.connect(connection_lost)


func _on_to_text_submitted(new_text: String) -> void:
	_on_join_button_pressed() 


func load_game():
	%Menu.hide()

	if multiplayer.is_server():
		%Map.add_child(map.instantiate())

	add_player.rpc_id(1, multiplayer.get_unique_id())


func connection_lost():
	%Menu.show()

	if %Map.get_child(0):
		%Map.get_child(0).queue_free()


@rpc("any_peer")
func add_player(id):
	var player_instance = player.instantiate()
	player_instance.name = str(id)
	%Players.add_child(player_instance)


@rpc("any_peer")
func remove_player(id):
	if %Players.get_node(str(id)):
		%Players.get_node(str(id)).queue_free()


@rpc("call_local", "any_peer")
func send_message(id, message):
	var label = Label.new()
	label.modulate = Color(1, 0.75, 0)
	if id == 1:
		label.modulate = Color.GREEN
		label.text = "SERVER: " + message
	else:
		label.text = str(id) + ": " + message
	%Messages.get_child(6).queue_free()
	%Messages.add_child(label)
	%Messages.move_child(label, 0)

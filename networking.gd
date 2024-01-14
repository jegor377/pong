extends Node

signal connected()
signal not_connected()
signal assigned_to_session(client_id: int, role: int)
signal could_not_create_session()
signal set_ready(client_type, ready)
signal could_not_assign_to_session(session_id)
signal session_leave_status(client_id, left)
signal became_main()
signal disconnected()

var ip: String
var port: String

var main_id: int
var secondary_id: int
var current_id: int = -1

var current_ready := false
var main_ready := false
var secondary_ready := false

var session_id: int = -1
var session_role: int = ClientType.NONE

var palette_pos: Vector2
var palette_dir: Vector2
var ball_pos: Vector2
var ball_dir: Vector2

var PREAMBULE: PackedByteArray = PackedByteArray([0x01, 0x02, 0x03])
@onready var PREAMBULE_SIZE := PREAMBULE.size()

var client: PacketPeerUDP

enum PacketType {
	UNKNOWN = -1,
	CONNECT = 0,
	CONNECTED = 1,
	NOT_CONNECTED = 2,
	DISCONNECT = 3,
	CREATE_SESSION = 4,
	ASSIGNED_TO_SESSION = 5,
	COULD_NOT_MAKE_SESSION = 6,
	SET_READY = 7,
	CONNECT_TO_SESSION = 8,
	COULD_NOT_ASSIGN_TO_SESSION = 9,
	LEAVE_SESSION = 10,
	SESSION_LEAVE_STATUS = 11,
	SET_READINESS = 12,
	GAME_STARTED = 13,
	INFORM_BALL_POS = 15,
	INFORM_PLAYER_POS = 17,
	INFORM_POINT_SCORED = 19,
	INFORM_WON = 20,
	IM_ALIVE = 21,
	DISCONNECTED = 22
}

enum ClientType {
	NONE = -1,
	MAIN = 0,
	SECONDARY = 1
}

var packet_type: int = PacketType.UNKNOWN
var packet_size: int = -1
var packet_data: PackedByteArray
var packet_crc: int = -1

enum PackedDecodeStep {
	PREAMBULE = 0,
	TYPE = 1,
	SIZE = 2,
	DATA = 3,
	CRC = 4
}

var current_decode_step: int = PackedDecodeStep.PREAMBULE
var part_data := PackedByteArray([])
var part_pos := 0
var part_ready := false
var part_size := 0
var read_amount := 0

var pingTimer := Timer.new()

func _ready():
	client = PacketPeerUDP.new()
	add_child(pingTimer)
	pingTimer.one_shot = false
	pingTimer.connect("timeout", alive_timeout)

func _process(delta):
	if client.get_available_packet_count() > 0:
		var packet := client.get_packet()
		process_packet(packet)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_connected_to_server():
			disconnect_from_server()


func process_packet(packet: PackedByteArray) -> void:
	var i := 0
	var packet_start := 0
	var tmp_packet: PackedByteArray
	while i < packet.size():
		match current_decode_step:
			PackedDecodeStep.PREAMBULE:
				if i + PREAMBULE_SIZE < packet.size() and packet.slice(i, i + PREAMBULE_SIZE) == PREAMBULE:
					current_decode_step = PackedDecodeStep.TYPE
					tmp_packet.append_array(PREAMBULE)
					i += PREAMBULE_SIZE
				else:
					i += 1
			PackedDecodeStep.TYPE:
				packet_type = packet.decode_u8(i)
				tmp_packet.append(packet_type)
				current_decode_step = PackedDecodeStep.SIZE
				i += 1
				reset_part(2) # size size :)
			PackedDecodeStep.SIZE:
				read_amount = read_part(packet, i)
				if part_ready:
					packet_size = part_data.decode_u16(0)
					tmp_packet.append_array(part_data)
					current_decode_step = PackedDecodeStep.DATA
					reset_part(packet_size)
				i += read_amount
			PackedDecodeStep.DATA:
				read_amount = read_part(packet, i)
				if part_ready:
					packet_data = part_data
					tmp_packet.append_array(part_data)
					current_decode_step = PackedDecodeStep.CRC
					reset_part(2) # crc size
				i += read_amount
			PackedDecodeStep.CRC:
				read_amount = read_part(packet, i)
				if part_ready:
					packet_crc = part_data.decode_u16(0)
					tmp_packet.append_array(part_data)
					var calc_crc := crc16(tmp_packet)
				
					if calc_crc == packet_crc:
						process_decoded_packet()
					
					tmp_packet.clear()
					current_decode_step = PackedDecodeStep.PREAMBULE
				i += 2


func crc16(data: PackedByteArray) -> int:
	var crc := 0xffff
	if data.size() == 0:
		return crc
	
	for l in range(data.size() - 2):
		var byte = data[l]
		crc ^= byte
		for i in range(8):
			if crc & 1 != 0:
				crc = (crc >> 1) ^ 0x8408
			else:
				crc = (crc >> 1)
	return crc

func reset_part(size: int) -> void:
	part_data = PackedByteArray([])
	part_pos = 0
	part_size = size
	part_ready = false

func read_part(packet: PackedByteArray, i: int) -> int:
	if part_pos < part_size:
		# can read
		var avail_bytes := packet.size() - i
		var remaining_bytes := part_size - part_pos
		if avail_bytes >= remaining_bytes: # can read full remaining amount
			part_data.append_array(packet.slice(i, i + remaining_bytes))
			part_pos += remaining_bytes
			part_ready = true
			return remaining_bytes
		else: # can read only available count
			part_data.append_array(packet.slice(i, i + avail_bytes))
			part_pos += avail_bytes
			if part_pos == part_size:
				part_ready = true
			return avail_bytes
	else:
		part_ready = true
	return 0

func create_packet(type: int, data: PackedByteArray = PackedByteArray([])) -> PackedByteArray:
	var packet := PackedByteArray(PREAMBULE)
	var initial_size := PREAMBULE.size() + 3
	packet.resize(initial_size)
	packet.encode_u8(3, type)
	packet.encode_u16(4, data.size())
	packet += data
	packet.resize(initial_size + data.size() + 2)
	var crc = crc16(packet)
	packet.encode_u16(6 + data.size(), crc)
	
	return packet

func create_connect_packet() -> PackedByteArray:
	return create_packet(PacketType.CONNECT)

func create_im_alive_packet() -> PackedByteArray:
	var data := PackedByteArray([0, 0])
	data.encode_u16(0, current_id)
	return create_packet(PacketType.IM_ALIVE, data)

func create_disconnect_packet() -> PackedByteArray:
	var data := PackedByteArray([0, 0])
	data.encode_u16(0, current_id)
	return create_packet(PacketType.DISCONNECT, data)

func create_make_session_packet() -> PackedByteArray:
	var data := PackedByteArray([0, 0])
	data.encode_u16(0, current_id)
	return create_packet(PacketType.CREATE_SESSION, data)

func create_join_session_packet(_session_id) -> PackedByteArray:
	var data := PackedByteArray([0, 0, 0, 0])
	data.encode_u16(0, current_id)
	data.encode_u16(2, _session_id)
	return create_packet(PacketType.CONNECT_TO_SESSION, data)

func connect_to_server() -> void:
	client.connect_to_host(ip, int(port))
	var connect_packet := create_connect_packet()
	client.put_packet(connect_packet)

func send_im_alive() -> void:
	var im_alive_packet := create_im_alive_packet()
	client.put_packet(im_alive_packet)

func disconnect_from_server() -> void:
	if not check_connected():
		return
	var disconnect_packet := create_disconnect_packet()
	client.put_packet(disconnect_packet)

func create_session() -> void:
	if not check_connected():
		return
	var create_session_packet := create_make_session_packet()
	client.put_packet(create_session_packet)

func join_session(_session_id: int) -> void:
	if not check_connected():
		return
	var join_packet := create_join_session_packet(_session_id)
	client.put_packet(join_packet)

func create_leave_session_packet(_session_id: int, _client_id: int) -> PackedByteArray:
	var data := PackedByteArray([0, 0, 0, 0])
	data.encode_u16(0, _session_id)
	data.encode_u16(2, _client_id)
	return create_packet(PacketType.LEAVE_SESSION, data)

func leave_session() -> void:
	if not check_in_session():
		return
	if not check_connected():
		return
	var leave_packet := create_leave_session_packet(session_id, current_id)
	client.put_packet(leave_packet)

func create_readiness_packet(readiness: bool) -> PackedByteArray:
	var data = PackedByteArray([0, 0, 0, 0, 0])
	data.encode_u16(0, current_id)
	data.encode_u16(2, session_id)
	data.encode_u8(4, 1 if readiness else 0)
	return create_packet(PacketType.SET_READINESS, data)

func set_readiness(readiness: bool) -> void:
	if not check_in_session():
		return
	if not check_connected():
		return
	client.put_packet(create_readiness_packet(1 if readiness else 0))

func client_type_name(client_type) -> String:
	if client_type == ClientType.MAIN:
		return 'main'
	elif client_type == ClientType.SECONDARY:
		return 'secondary'
	else:
		return 'unknown'

func process_decoded_packet() -> void:
	match packet_type:
		PacketType.CONNECTED:
			current_id = packet_data.decode_u16(0)
			print("Connected on id: ", current_id)
			pingTimer.start(5)
			emit_signal("connected")
		PacketType.NOT_CONNECTED:
			emit_signal("not_connected")
		PacketType.ASSIGNED_TO_SESSION:
			var _session_id := packet_data.decode_u16(0)
			var _client_id := packet_data.decode_u16(2)
			var client_type = packet_data.decode_u8(4)
			print("Client "+str(current_id)+": Assigned client: ", _client_id, " to session: ", _session_id, " as ", client_type_name(client_type))
			
			if _client_id == current_id:
				session_role = client_type
				session_id = _session_id
			
			match client_type:
				ClientType.MAIN:
					main_id = _client_id
				ClientType.SECONDARY:
					secondary_id = _client_id
				_:
					return
			emit_signal("assigned_to_session", _client_id, client_type)
		PacketType.COULD_NOT_MAKE_SESSION:
			emit_signal("could_not_create_session")
		PacketType.SET_READY:
			var _session_id := packet_data.decode_u16(0)
			var _client_id := packet_data.decode_u16(2)
			var ready = packet_data.decode_u8(4) == 1
			
			if _client_id == current_id:
				current_ready = ready
			
			var _client_type := client_type(_client_id)
			
			if _client_type == ClientType.MAIN:
				main_ready = ready
			elif _client_type == ClientType.SECONDARY:
				secondary_ready = ready
			
			emit_signal("set_ready", _client_type, ready)
		PacketType.COULD_NOT_ASSIGN_TO_SESSION:
			var _session_id := packet_data.decode_u16(0)
			emit_signal("could_not_assign_to_session", _session_id)
		PacketType.SESSION_LEAVE_STATUS:
			var _session_id := packet_data.decode_u16(0)
			var _client_id := packet_data.decode_u16(2)
			var left = packet_data.decode_u8(4) == 1
			
			print("Client " + str(current_id) + ": Client ("+str(_client_id)+") left. I have role " + client_type_name(session_role) + ". Main has id " + str(main_id) + ". Secondary has id " + str(secondary_id) + ".")
			
			if _session_id == session_id:
				if _client_id == current_id:
					reset_session()
					reset_main()
					reset_secondary()
					current_ready = false
				elif _client_id == main_id:
					if session_role == ClientType.MAIN:
						reset_main()
					elif session_role == ClientType.SECONDARY:
						secondary_ready = false
						main_id = current_id
						main_ready = false
						session_role = ClientType.MAIN
						emit_signal("became_main")
				elif _client_id == secondary_id:
					reset_secondary()
				emit_signal("session_leave_status", _client_id, left)
		PacketType.DISCONNECTED:
			pingTimer.stop()
			current_id = -1
			current_ready = false
			print("Disconnected")
			emit_signal("disconnected")

func alive_timeout() -> void:
	send_im_alive()

func client_type(client_id) -> ClientType:
	if client_id == main_id:
		return ClientType.MAIN
	elif client_id == secondary_id:
		return ClientType.SECONDARY
	return ClientType.NONE

func is_connected_to_server() -> bool:
	return current_id != -1

func is_in_session() -> bool:
	return session_id != -1

func check_connected() -> bool:
	var connected := is_connected_to_server()
	if not connected:
		print("Client not connected")
	return connected

func check_in_session() -> bool:
	var in_session := is_in_session()
	if not in_session:
		print("Not in session")
	return in_session

func reset_session() -> void:
	session_id = -1
	session_role = ClientType.NONE

func reset_main() -> void:
	main_id = -1
	main_ready = false

func reset_secondary() -> void:
	secondary_id = -1
	secondary_ready = false

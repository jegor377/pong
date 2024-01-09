extends Node


var ip: String
var port: String

var main_id: int
var secondary_id: int
var current_id: int

var palette_pos: Vector2
var palette_dir: Vector2
var ball_pos: Vector2
var ball_dir: Vector2

var PREAMBULE: PackedByteArray = PackedByteArray([0x01, 0x02, 0x03])
@onready var PREAMBULE_SIZE := PREAMBULE.size()

var client: PacketPeerUDP

enum PacketType {
	UNKNOWN = -1,
	CONNECT = 0
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

func _ready():
	client = PacketPeerUDP.new()

func _process(delta):
	if client.get_available_packet_count() > 0:
		var packet := client.get_packet()
		process_packet(packet)


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
						print("CRC correcto")
					else:
						print("CRC incorrecto")
					
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
	packet.resize(PREAMBULE.size() + 3 + data.size() + 2)
	packet.encode_u8(3, type)
	packet.encode_u16(4, data.size())
	packet += data
	var crc = crc16(packet)
	packet.encode_u16(6 + data.size(), crc)
	
	return packet

func create_connect_packet() -> PackedByteArray:
	return create_packet(PacketType.CONNECT)

func connect_to_server() -> void:
	client.connect_to_host(ip, int(port))
	var connectPacket := create_connect_packet()
	client.put_packet(connectPacket)



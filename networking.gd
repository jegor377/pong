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

func _ready():
	client = PacketPeerUDP.new()

func _process(delta):
	if client.get_available_packet_count() > 0:
		var packet := client.get_packet()
		process_packet(packet)


func process_packet(packet: PackedByteArray) -> void:
	var i := 0
	while i < packet.size():
		match current_decode_step:
			PackedDecodeStep.PREAMBULE:
				if i + PREAMBULE_SIZE < packet.size() and packet.slice(i, i + PREAMBULE_SIZE) == PREAMBULE:
					current_decode_step = PackedDecodeStep.TYPE
					i += PREAMBULE_SIZE
				else:
					i += 1
			PackedDecodeStep.TYPE:
				packet_type = packet.decode_u8(i)
				current_decode_step = PackedDecodeStep.SIZE
				i += 1
			PackedDecodeStep.SIZE:
				pass
			PackedDecodeStep.DATA:
				pass
			PackedDecodeStep.CRC:
				pass


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



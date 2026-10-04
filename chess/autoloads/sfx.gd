## Sound effects (autoload "Sfx"). The sounds are synthesized at startup, so the
## game needs no audio files; replace an entry of SOUNDS' streams to use real ones.
extends Node

const MIX_RATE := 22050
const PLAYER_COUNT := 6

enum Wave { SQUARE, SINE, NOISE }

## name -> list of [frequency Hz, duration s] notes, wave and volume (0..1).
const SOUNDS := {
	"move": {"notes": [[520.0, 0.05]], "wave": Wave.SQUARE, "volume": 0.25},
	"capture": {"notes": [[180.0, 0.09]], "wave": Wave.NOISE, "volume": 0.4},
	"promote": {"notes": [[523.0, 0.06], [659.0, 0.06], [784.0, 0.1]], "wave": Wave.SQUARE, "volume": 0.3},
	"buy": {"notes": [[880.0, 0.05], [1175.0, 0.08]], "wave": Wave.SINE, "volume": 0.4},
	"sell": {"notes": [[1175.0, 0.05], [784.0, 0.08]], "wave": Wave.SINE, "volume": 0.4},
	"win": {"notes": [[523.0, 0.08], [659.0, 0.08], [784.0, 0.08], [1047.0, 0.18]], "wave": Wave.SQUARE, "volume": 0.3},
	"lose": {"notes": [[392.0, 0.12], [330.0, 0.12], [262.0, 0.22]], "wave": Wave.SQUARE, "volume": 0.3},
}

var streams: Dictionary[String, AudioStreamWAV] = {}
## The name of the last sound played (tests read it).
var last_played := ""

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name: String in SOUNDS:
		var sound: Dictionary = SOUNDS[sound_name]
		streams[sound_name] = synthesize(sound.notes, sound.wave, sound.volume)
	
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound_name: String) -> void:
	assert(streams.has(sound_name), "Unknown sound %s" % sound_name)
	last_played = sound_name
	
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = streams[sound_name]
	player.play()


## Builds a 16-bit mono sound from [frequency, duration] notes played one after another.
static func synthesize(notes: Array, wave: Wave, volume: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var noise := RandomNumberGenerator.new()
	noise.seed = 1
	
	for note: Array in notes:
		var frequency: float = note[0]
		var samples := int(note[1] * MIX_RATE)
		for i in samples:
			var t := float(i) / MIX_RATE
			var value := 0.0
			match wave:
				Wave.SQUARE:
					value = 1.0 if fmod(t * frequency, 1.0) < 0.5 else -1.0
				Wave.SINE:
					value = sin(TAU * frequency * t)
				Wave.NOISE:
					value = noise.randf_range(-1.0, 1.0)
			# Quick attack, linear fade out: no clicks between notes.
			var envelope := minf(1.0, i / (MIX_RATE * 0.004)) * (1.0 - float(i) / samples)
			var sample := int(clampf(value * envelope * volume, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xFF)
			data.append((sample >> 8) & 0xFF)
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

extends Node

var pew_sound = preload("res://assets/sounds/pew.wav")
var build_sound = preload("res://assets/sounds/expl3.wav")
var click_sound = preload("res://assets/sounds/menu.ogg")

func _ready():
	GameEvents.metal_collected.connect(_on_metal_collected)
	GameEvents.build_requested.connect(_on_build_requested)

func _on_metal_collected(_amount):
	play_sound(pew_sound)

func _on_build_requested(_type, _pos):
	play_sound(click_sound)

func play_sound(stream: AudioStream):
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.play()
	player.finished.connect(player.queue_free)

func play_build():
	play_sound(build_sound)

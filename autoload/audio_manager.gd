extends Node

# Stub audio layer. No audio assets exist yet in the project — every gameplay
# system calls into these named methods already, so wiring real sound later
# is a matter of filling these bodies in, not touching any call site.


func play_music(_track_name: String) -> void:
	pass


func stop_music() -> void:
	pass


func play_sfx(_sfx_name: String) -> void:
	pass


func set_music_volume_db(_db: float) -> void:
	pass

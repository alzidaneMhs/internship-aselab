extends Control

signal finished(won: bool)

@export var embedded_mode: bool = false

var difficulty: String = "normal"

enum State {
	READY,
	PLAYING,
	WON,
	LOST
}

const SESSION_BLOCKS: Array[int] = [7, 14, 21]
const TOTAL_TIME: float = 35.0

const COLOR_GOLD: Color = Color("#FFB938")
const COLOR_GREEN: Color = Color("#8BEAA0")
const COLOR_RED: Color = Color("#FF6262")
const COLOR_PURPLE: Color = Color("#BC60FF")

@onready var main_layout: VBoxContainer = (
	$CenterContainer/MainPanel/MainLayout
)

@onready var board: SequenceBlockBoard = (
	main_layout.get_node("BoardArea") as SequenceBlockBoard
)

@onready var grid_center: CenterContainer = (
	board.get_node("GridCenter") as CenterContainer
)

@onready var intro_label: Label = (
	board.get_node("IntroLabel") as Label
)

@onready var mode_label: Label = (
	main_layout.get_node("ModeLabel") as Label
)

@onready var session_label: Label = (
	main_layout.get_node("HUDRow/SessionLabel") as Label
)

@onready var target_label: Label = (
	main_layout.get_node("HUDRow/TargetLabel") as Label
)

@onready var progress_label: Label = (
	main_layout.get_node("HUDRow/ProgressLabel") as Label
)

@onready var timer_label: Label = (
	main_layout.get_node("HUDRow/TimerLabel") as Label
)

@onready var time_bar: ProgressBar = (
	main_layout.get_node("TimeBar") as ProgressBar
)

@onready var status_label: Label = (
	main_layout.get_node("StatusLabel") as Label
)

@onready var round_timer: Timer = $RoundTimer

var _state: State = State.READY
var _session_index: int = 0
var _next_number: int = 1
var _switching_session: bool = false


func _ready() -> void:
	round_timer.stop()
	round_timer.one_shot = true
	round_timer.autostart = false
	round_timer.ignore_time_scale = true

	round_timer.timeout.connect(_on_time_up)
	board.block_pressed.connect(_on_block_pressed)

	time_bar.min_value = 0.0
	time_bar.max_value = TOTAL_TIME
	time_bar.show_percentage = false

	difficulty = "normal"
	mode_label.text = "Mode: Normal"

	intro_label.z_index = 5
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_prepare_game()


func _process(_delta: float) -> void:
	if _state == State.PLAYING:
		_update_clock(round_timer.time_left)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if _state == State.READY:
		if key_event.keycode == KEY_SPACE:
			_start_game()
			get_viewport().set_input_as_handled()

	elif _state == State.WON or _state == State.LOST:
		if embedded_mode:
			return

		if key_event.keycode == KEY_R:
			_start_game()
			get_viewport().set_input_as_handled()


func _prepare_game() -> void:
	_state = State.READY
	_session_index = 0
	_next_number = 1
	_switching_session = false

	round_timer.stop()
	board.set_interaction_enabled(false)

	grid_center.hide()
	intro_label.show()

	intro_label.text = (
		"TEKAN SPASI UNTUK MULAI\n"
		+ "Klik angka berurutan: 7, 14, lalu 21 blok"
	)

	intro_label.add_theme_color_override("font_color", COLOR_GOLD)

	_update_hud()
	_update_clock(TOTAL_TIME)

	_set_status("Salah angka mengulang ke sesi 1. Waktu terus berjalan!", COLOR_GREEN)


func _start_game() -> void:
	if _state == State.PLAYING:
		return

	_state = State.PLAYING
	_switching_session = true

	round_timer.start(TOTAL_TIME)

	_load_session(0, "Sesi 1 dimulai! Klik angka 1 sampai 7.", COLOR_GREEN)


func _load_session(index: int, message: String, message_color: Color) -> void:
	if _state != State.PLAYING:
		return

	if round_timer.time_left <= 0.0:
		_finish_game(false)
		return

	_session_index = index
	_next_number = 1

	board.build_blocks(SESSION_BLOCKS[_session_index])

	intro_label.hide()
	grid_center.show()

	_switching_session = false
	board.set_interaction_enabled(true)

	_update_hud()
	_update_clock(round_timer.time_left)
	_set_status(message, message_color)


func _on_block_pressed(number: int) -> void:
	if _state != State.PLAYING or _switching_session:
		return

	if round_timer.time_left <= 0.0:
		_finish_game(false)
		return

	if number != _next_number:
		AudioManager.play_sfx("mg_wrong", -3.0)
		_schedule_session(
			0,
			"Salah angka! Kembali ke sesi 1. Waktu tetap berjalan!",
			COLOR_RED
		)
		return

	board.mark_completed(number)
	AudioManager.play_sfx("mg_correct", -4.0, 0.0)
	_next_number += 1
	_update_hud()

	var block_count: int = SESSION_BLOCKS[_session_index]

	if _next_number > block_count:
		var is_last_session: bool = (
			_session_index == SESSION_BLOCKS.size() - 1
		)

		if is_last_session:
			_finish_game(true)
		else:
			var next_session: int = _session_index + 1

			_schedule_session(
				next_session,
				"Sesi %d! Klik angka 1 sampai %d." % [
					next_session + 1,
					SESSION_BLOCKS[next_session]
				],
				COLOR_GREEN
			)

		return

	_set_status("Benar! Sekarang klik angka %d." % _next_number, COLOR_GREEN)


func _schedule_session(index: int, message: String, message_color: Color) -> void:
	_switching_session = true
	board.set_interaction_enabled(false)

	call_deferred("_load_session", index, message, message_color)


func _update_hud() -> void:
	var block_count: int = SESSION_BLOCKS[_session_index]
	var completed: int = _next_number - 1

	session_label.text = "Sesi: %d / 3" % (_session_index + 1)

	progress_label.text = "Blok: %d / %d" % [completed, block_count]

	if _next_number <= block_count:
		target_label.text = "Target: %d" % _next_number
	else:
		target_label.text = "Target: Selesai"


func _update_clock(remaining: float) -> void:
	var seconds: float = maxf(remaining, 0.0)

	timer_label.text = "Waktu: %.1f" % seconds
	time_bar.value = seconds

	if seconds <= 10.0:
		timer_label.add_theme_color_override("font_color", COLOR_RED)
	else:
		timer_label.add_theme_color_override("font_color", COLOR_PURPLE)


func _on_time_up() -> void:
	if _state == State.PLAYING:
		_finish_game(false)


func _finish_game(won: bool) -> void:
	if _state != State.PLAYING:
		return

	var remaining: float = round_timer.time_left

	if won:
		_state = State.WON
	else:
		_state = State.LOST

	_switching_session = false

	round_timer.stop()
	board.set_interaction_enabled(false)

	grid_center.hide()
	intro_label.show()

	_update_hud()

	var result_hint: String = "Tekan R untuk bermain lagi"

	if embedded_mode:
		result_hint = "Kembali ke game utama..."

	if won:
		_update_clock(remaining)

		intro_label.text = ("SISTEM BERHASIL DIPULIHKAN!\n" + result_hint)
		intro_label.add_theme_color_override("font_color", COLOR_GREEN)
		_set_status("Ketiga sesi selesai! Sisa waktu: %.1f detik." % remaining, COLOR_GREEN)

	else:
		_update_clock(0.0)

		intro_label.text = ("WAKTU HABIS!\n" + result_hint)

		intro_label.add_theme_color_override("font_color", COLOR_RED)

		_set_status("Sistem belum pulih. Kesempatan ini gagal.", COLOR_RED)

	if embedded_mode:
		await get_tree().create_timer(1.5, true, false, true).timeout

		if not is_inside_tree():
			return

		finished.emit(won)


func _set_status(message: String, color: Color) -> void:
	status_label.text = message

	status_label.add_theme_color_override(
		"font_color", color
	)

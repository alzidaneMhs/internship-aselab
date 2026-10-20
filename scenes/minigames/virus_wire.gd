extends Control


enum RoundState {
	WAITING,
	PLAYING,
	WON,
	LOST
}

const ROUND_DURATION: float = 20.0


@onready var wire_layer: VirusWireLayer = (
	$ScreenMargin/MainLayout/BoardPanel/BoardArea/WireLayer
)

@onready var darkness = (
	$ScreenMargin/MainLayout/BoardPanel/BoardArea/Darkness
)

@onready var lives_label: Label = (
	$ScreenMargin/MainLayout/HUDRow/LivesLabel
)

@onready var timer_label: Label = (
	$ScreenMargin/MainLayout/HUDRow/TimerLabel
)

@onready var footer_label: Label = (
	$ScreenMargin/MainLayout/FooterLabel
)

@onready var instructions_label: Label = (
	$ScreenMargin/MainLayout/InstructionsLabel
)

@onready var intro_label: Label = (
	$ScreenMargin/MainLayout/BoardPanel/BoardArea/IntroLabel
)

@onready var effects_layer: VirusWireEffects = (
	$ScreenMargin/MainLayout/BoardPanel/BoardArea/EffectsLayer
)

@onready var round_timer: Timer = $RoundTimer

var round_state: RoundState = RoundState.WAITING


func _ready() -> void:
	# Pesan awal dan hasil berada di atas lapisan gelap.
	intro_label.z_index = 20
	intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	round_timer.one_shot = true
	round_timer.ignore_time_scale = true

	if not wire_layer.wire_cut.is_connected(_on_wire_cut):
		wire_layer.wire_cut.connect(_on_wire_cut)

	if not round_timer.timeout.is_connected(_on_timer_timeout):
		round_timer.timeout.connect(_on_timer_timeout)

	instructions_label.text = (
        "CARA MAIN: tekan Spasi untuk mulai. "
		+ "Gerakkan mouse untuk menyorot. "
		+ "Klik kiri untuk memotong SATU kabel berikon virus. "
		+ "Hindari kabel sehat!"
	)

	_prepare_round()


func _prepare_round() -> void:
	effects_layer.reset_effects()
	
	round_state = RoundState.WAITING
	round_timer.stop()

	# Siapkan susunan infeksi baru, tetapi belum bisa dimainkan.
	wire_layer.new_round()
	wire_layer.set_interaction_enabled(false)

	# Sebelum Spasi ditekan, papan hitam penuh.
	darkness.show()
	darkness.set_flashlight_enabled(false)

	lives_label.text = "Nyawa: 1"
	_update_timer_label(ROUND_DURATION)

	intro_label.text = (
        "TEKAN SPASI UNTUK MULAI\n"
		+ "Potong SATU kabel berikon virus."
	)
	intro_label.add_theme_color_override(
		"font_color",
		Color("#FFE37A")
	)
	intro_label.show()

	_set_footer(
		"Spasi: mulai • Mouse: senter • Klik kiri: potong kabel virus",
		Color("#8BEAA0")
	)


func _start_round() -> void:
	if round_state != RoundState.WAITING:
		return

	round_state = RoundState.PLAYING

	intro_label.hide()

	round_timer.paused = false
	round_timer.start(ROUND_DURATION)

	darkness.set_flashlight_enabled(true)
	wire_layer.set_interaction_enabled(true)

	_update_timer_label(ROUND_DURATION)

	_set_footer(
		"Cari ikon virus, lalu klik badan kabelnya. Hindari kabel sehat!",
		Color("#F3EEDB")
	)


func _process(_delta: float) -> void:
	if round_state == RoundState.PLAYING:
		var remaining: float = round_timer.time_left

		_update_timer_label(remaining)
		effects_layer.update_countdown(remaining, timer_label)


func _on_wire_cut(wire_index: int, infected: bool) -> void:
	if round_state != RoundState.PLAYING:
		return

	# Pilihan setelah waktu habis tidak dihitung sebagai kemenangan.
	if round_timer.time_left <= 0.0:
		_on_timer_timeout()
		return

	var wire_number: int = wire_index + 1

	if infected:
		_finish_round(
			true,
			"BERHASIL!",
			"Kabel virus %02d berhasil diputus." % wire_number
		)
	else:
		_finish_round(
			false,
			"SALAH KABEL!",
            "Kabel %02d ternyata sehat. Sumber virus belum diputus."
			% wire_number
		)


func _on_timer_timeout() -> void:
	if round_state != RoundState.PLAYING:
		return

	_finish_round(
		false,
		"WAKTU HABIS!",
        "Kabel virus belum berhasil diputus."
	)


func _finish_round(
	won: bool,
	title: String,
	details: String
) -> void:
	if round_state != RoundState.PLAYING:
		return

	# Simpan sisa waktu sebelum Timer dihentikan.
	var remaining_time: float = round_timer.time_left

	round_timer.stop()
	wire_layer.set_interaction_enabled(false)

	var result_color: Color

	if won:
		round_state = RoundState.WON
		lives_label.text = "Nyawa: 1"
		result_color = Color("#8BEAA0")
	else:
		round_state = RoundState.LOST
		lives_label.text = "Nyawa: 0"
		result_color = Color("#FF5C64")

	_update_timer_label(remaining_time)

	intro_label.text = (
		title
		+ "\n"
		+ details
		+ "\nTekan R untuk mengulang."
	)
	intro_label.add_theme_color_override(
		"font_color",
		result_color
	)
	intro_label.show()

	_set_footer(
		details + " Tekan R untuk ulang.",
		result_color
	)

	effects_layer.play_result(won, wire_layer, intro_label)


func _update_timer_label(value: float) -> void:
	# Pembulatan ke atas agar 0.0 hanya muncul saat waktu habis.
	var display_time: float = (
		ceilf(maxf(value, 0.0) * 10.0) / 10.0
	)

	timer_label.text = "Waktu: %.1f" % display_time

	if value <= 5.0:
		timer_label.add_theme_color_override(
			"font_color",
			Color("#FF5C64")
		)
	elif value <= 10.0:
		timer_label.add_theme_color_override(
			"font_color",
			Color("#FFD166")
		)
	else:
		timer_label.add_theme_color_override(
			"font_color",
			Color("#BC60FF")
		)


func _set_footer(text: String, color: Color) -> void:
	footer_label.text = text
	footer_label.add_theme_color_override("font_color", color)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_SPACE:
		if round_state == RoundState.WAITING:
			_start_round()

		get_viewport().set_input_as_handled()

	elif key_event.keycode == KEY_R:
		if (
			round_state == RoundState.WON
			or round_state == RoundState.LOST
		):
			_prepare_round()

		get_viewport().set_input_as_handled()

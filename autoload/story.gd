extends Node

## All story text, and the helper that plays dialogue. Lines are dictionaries:
## {"who": "Isme", "text": "..."} ("Narator" has no portrait).

const DIALOGUE_BOX := preload("res://scenes/ui/dialogue_box.tscn")

const INTRO_PAGES := [
	"Planet Circuit dulunya adalah rumah yang damai bagi para robot.",
	"Sampai manusia datang. Mereka ingin menguasai planet ini dan memanipulasi para penghuninya demi keserakahan mereka akan kekuatan.",
	"Robot yang berguna dijadikan budak.\nRobot yang dianggap 'produk gagal' dibuang ke fasilitas bawah tanah yang gelap dan terisolasi.",
	"Di antara tumpukan besi tua dan keputusasaan, satu robot usang membuka matanya.",
	"Namanya Isme.\nKecil, usang, dan dianggap tidak berguna.",
	"\"...Aku masih menyala.\nSelama aku masih menyala, aku akan keluar dari sini,\ndan membawa yang lain bersamaku.\"",
]

const STAGE_INFO := {
	"res://scenes/levels/stage_0.tscn": {"label": "PROLOG", "title": "Tempat Pembuangan", "intro": "stage0_intro"},
	"res://scenes/levels/stage_1.tscn": {"label": "STAGE 1", "title": "Prison Undercroft", "intro": "stage1_intro"},
	"res://scenes/levels/stage_2.tscn": {"label": "STAGE 2", "title": "Crystal Vents", "intro": "stage2_intro"},
	"res://scenes/levels/stage_3.tscn": {"label": "STAGE 3", "title": "Reactor Core", "intro": "stage3_intro"},
	"res://scenes/levels/stage_4.tscn": {"label": "STAGE 4", "title": "Scrapyard Heights", "intro": "stage4_intro"},
	"res://scenes/levels/stage_5.tscn": {"label": "STAGE 5", "title": "Circuit Spire", "intro": "stage5_intro"},
}

const SCRIPTS := {
	"stage0_intro": [
		{"who": "Isme", "text": "Gelap sekali... tapi aku masih bisa bergerak."},
		{"who": "Isme", "text": "Pasti ada jalan keluar di ujung lorong ini. Aku harus terus maju."},
		{"who": "Narator", "text": "Petunjuk muncul di sepanjang jalan. Baca pelan-pelan, lalu coba semua gerakanmu."},
	],
	"stage1_intro": [
		{"who": "Isme", "text": "Robot-robot penjaga ada di mana-mana. Mereka dulu teman seperjuangan..."},
		{"who": "Isme", "text": "Tapi kalau aku tidak melawan, aku tidak akan keluar dari sini."},
	],
	"stage2_intro": [
		{"who": "Isme", "text": "Kristal-kristal ini berdenyut seperti punya detak jantung."},
		{"who": "Isme", "text": "Dan layar itu... 'CORE RESET'? Apa yang sebenarnya mereka lakukan pada kami?"},
	],
	"stage3_intro": [
		{"who": "Isme", "text": "Inti reaktor. Energi sebesar ini dipakai manusia untuk mengendalikan kami."},
		{"who": "Isme", "text": "Di depan ada penjaga yang kuat. Aku harus siap."},
	],
	"stage4_intro": [
		{"who": "Isme", "text": "Permukaan... akhirnya aku bisa melihat langit Planet Circuit lagi."},
		{"who": "Isme", "text": "Tapi tempat ini penuh rongsokan. Kampung halamanku jadi tempat sampah."},
	],
	"stage5_intro": [
		{"who": "Isme", "text": "Menara terakhir. Di puncaknya, sumber semua kendali itu."},
		{"who": "Isme", "text": "Tinggal satu penjaga lagi. Aku tidak boleh berhenti sekarang."},
	],
	"lushte_intro": [
		{"who": "Lushte", "text": "Isme... mesin rongsok yang dibuang. Kamu tidak seharusnya ada di sini."},
		{"who": "Isme", "text": "Itu bukan suaramu, Lushte. Mereka memakai tubuhmu."},
		{"who": "Lushte", "text": "Aku... diperintahkan... untuk menghentikanmu!"},
	],
	"lushte_freed": [
		{"who": "Lushte", "text": "Virus itu... hilang. Aku ingat sekarang. Kita semua pernah berfoto bersama di permukaan."},
		{"who": "Lushte", "text": "Hati-hati, Isme. Krums masih berada di bawah kendali mereka."},
		{"who": "Isme", "text": "Aku akan membebaskannya juga."},
	],
	"krums_intro": [
		{"who": "Krums", "text": "Perisaiku tidak akan runtuh. Manusia memberiku tujuan."},
		{"who": "Isme", "text": "Itu bukan tujuan, Krums. Itu rantai."},
		{"who": "Krums", "text": "DIAM! Serahkan CORE-mu!"},
	],
	"krums_freed": [
		{"who": "Krums", "text": "Perisai ini... terlalu berat untuk kupikul selama ini. Terima kasih, Isme."},
		{"who": "Isme", "text": "Kita belum selesai. Masih banyak robot yang terbelenggu."},
	],
	"hanch_intro": [
		{"who": "Hanch", "text": "Ahaha, robot kecil yang menarik! Aku Hanch, mantan pejabat. Jangan tanya kenapa aku dicopot."},
		{"who": "Hanch", "text": "Aku jual penguat tubuh. Harganya Vonic, tentu saja. Tidak ada yang gratis di dunia ini."},
	],
}


func has_script(id: String) -> bool:
	return SCRIPTS.has(id)


func get_stage_info(path: String) -> Dictionary:
	return STAGE_INFO.get(path, {})


## Plays the dialogue only the first time (remembered in the save).
func play_once(id: String) -> void:
	if GameState.has_seen(id) or not SCRIPTS.has(id):
		return
	GameState.mark_seen(id)
	await play(SCRIPTS[id])


## Plays a dialogue; the game stays paused until it finishes.
func play(lines: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var box: Control = DIALOGUE_BOX.instantiate()
	layer.add_child(box)
	get_tree().root.add_child(layer)
	var was_paused := get_tree().paused
	get_tree().paused = true
	await box.run(lines)
	get_tree().paused = was_paused
	layer.queue_free()


## Ending narration; the last paragraph before the finale depends on reputation.
func get_ending_pages() -> Array:
	var pages: Array = [
		"Satu demi satu, rantai manipulasi itu terlepas.\nLushte dan Krums kembali menjadi diri mereka sendiri.",
		"Di layar besar itu, tulisan 'CORE RESET' akhirnya mencapai 100%.\nPlanet Circuit mulai menyala kembali.",
	]
	match GameState.get_minigame_difficulty():
		"kind":
			pages.append("Para robot yang diselamatkan berdiri di belakang Isme.\nMereka menyebutnya pembebas.")
		"hardcore":
			pages.append("Jalan yang dilalui Isme dipenuhi puing robot yang gugur.\nPlanet Circuit bebas... tetapi apakah Isme masih berbeda dari manusia yang ia lawan?")
		_:
			pages.append("Sebagian jalan Isme dipenuhi puing, sebagian lagi dipenuhi harapan.\nPara robot masih ragu: pembebas, atau sekadar mesin perang?")
	pages.append("Perjalanan merebut kembali planet ini baru saja dimulai.")
	return pages

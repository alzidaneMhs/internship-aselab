extends Node

const DIALOGUE_BOX := preload("res://scenes/ui/dialogue_box.tscn")
const FOURTH_WALL := preload("res://scenes/ui/fourth_wall.gd")

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
	"res://scenes/levels/stage_6.tscn": {"label": "STAGE 6", "title": "Violet Veins", "intro": "stage6_intro"},
	"res://scenes/levels/stage_7.tscn": {"label": "STAGE 7", "title": "Frozen Heart", "intro": "stage7_intro"},
	"res://scenes/levels/stage_8.tscn": {"label": "STAGE 8", "title": "Frozen Market", "intro": "stage8_intro"},
	"res://scenes/levels/stage_9.tscn": {"label": "STAGE 9", "title": "Glacial Descent", "intro": "stage9_intro"},
	"res://scenes/levels/stage_10.tscn": {"label": "STAGE 10", "title": "Tower's Foot", "intro": "stage10_intro"},
	"res://scenes/levels/stage_11.tscn": {"label": "STAGE 11", "title": "Spire Ascent", "intro": "stage11_intro"},
	"res://scenes/levels/stage_12.tscn": {"label": "STAGE 12", "title": "Scott's Chamber", "intro": "stage12_intro"},
	"res://scenes/levels/stage_13.tscn": {"label": "SECRET STAGE", "title": "Brankas Hanch", "intro": "stage13_intro"},
}

const BOSS_TITLES := {
	"lushte": {"name": "LUSHTE", "sub": "Sang Penjaga Bersayap", "color": Color(0.55, 0.85, 1.0)},
	"krums": {"name": "KRUMS", "sub": "Si Perisai Baja", "color": Color(1.0, 0.6, 0.3)},
	"scott": {"name": "SCOTT", "sub": "Mesin Pemburu Isme", "color": Color(1.0, 0.3, 0.25)},
	"hanch_boss": {"name": "HANCH", "sub": "Sang Pedagang Serakah", "color": Color(1.0, 0.78, 0.25)},
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
		{"who": "Isme", "text": "Menara ini menjaga jalan ke inti kendali mereka."},
		{"who": "Isme", "text": "Penjaga-penjaganya berjaga di setiap lantai. Aku harus menerobos sampai ke puncak."},
	],
	"stage6_intro": [
		{"who": "Isme", "text": "Gerbang menara terbuka ke gua di bawahnya. Kristal ungu menyala di setiap dinding."},
		{"who": "Isme", "text": "Energi ini mengalir ke seluruh fasilitas. Pasti ada sesuatu di ujung urat-urat kristal ini."},
	],
	"stage7_intro": [
		{"who": "Isme", "text": "Dingin sekali. Sirkuitku hampir membeku."},
		{"who": "Isme", "text": "Tapi sinyal CORE RESET itu makin kuat. Aku makin dekat."},
		{"who": "Narator", "text": "Di ujung gua es, sebuah pintu baja raksasa menunggu."},
		{"who": "Isme", "text": "Getaran ini... langkah kaki yang berat. Krums ada di balik pintu itu."},
	],
	"stage8_intro": [
		{"who": "Isme", "text": "Lampu-lampu di tengah es... ada lapak di sini? Siapa yang berjualan di tempat sedingin ini?"},
		{"who": "Narator", "text": "Hanch menunggu di tengah pasar beku. Kali ini ia membawa dagangan yang berbeda."},
	],
	"stage9_intro": [
		{"who": "Isme", "text": "Jurangnya dalam sekali. Jalannya menurun, tapi aku tahu ini bukan jalan yang mudah."},
		{"who": "Isme", "text": "Suara dengung itu... drone-drone pengintai. Mereka akan menukik kalau melihatku."},
	],
	"stage10_intro": [
		{"who": "Isme", "text": "Di kejauhan ada menara menjulang menembus awan. Semua jejak sinyal berakhir di sana."},
		{"who": "Isme", "text": "Satu langkah lagi sebelum masuk. Aku harus bertahan sampai ke kakinya."},
	],
	"stage11_intro": [
		{"who": "Isme", "text": "Di dalam menara tidak ada jalan datar. Semuanya ke atas."},
		{"who": "Isme", "text": "Kalau lelah, ada api unggun untuk beristirahat. Pelan-pelan saja, tapi jangan berhenti."},
	],
	"stage12_intro": [
		{"who": "Isme", "text": "Ruangan ini... dindingnya penuh layar. Dan semuanya menampilkan wajahku."},
		{"who": "Isme", "text": "Seseorang sudah menungguku di sini."},
	],
	"hanch_skills": [
		{"who": "Hanch", "face": 1, "text": "Heh, kamu masih hidup sampai sini? Bagus. Dagangan baru, khusus untuk robot yang selamat sejauh ini."},
		{"who": "Hanch", "face": 2, "text": "Bukan sekadar penguat tubuh. Ini teknik: perisai darurat, langkah lebih cepat, dan kalau kamu punya dash, aku bisa menggandakannya."},
		{"who": "Isme", "text": "Teknik... yang bisa dibeli? Biasanya aku harus mengalahkan boss dulu."},
		{"who": "Hanch", "face": 3, "text": "Dunia sudah berubah, robot kecil. Siapa yang punya Vonic, dia yang punya kekuatan."},
	],
	"scott_intro": [
		{"who": "Scott", "text": "Target teridentifikasi: ISME. Unit usang. Status: tidak berguna."},
		{"who": "Isme", "text": "Kamu robot juga... Siapa yang membuatmu?"},
		{"who": "Scott", "text": "Aku diciptakan untuk satu tujuan. Menghancurkanmu."},
		{"who": "Isme", "text": "Tidak ada yang diciptakan hanya untuk menghancurkan. Kamu masih bisa memilih."},
		{"who": "Scott", "text": "PILIHAN TIDAK ADA DALAM PROTOKOLKU. MEMULAI PEMUSNAHAN."},
	],
	"scott_defeated": [
		{"who": "Scott", "text": "Tujuan... tidak tercapai. Kalau begitu... untuk apa aku ada?"},
		{"who": "Isme", "text": "Itu bukan pertanyaan yang harus dijawab manusia untukmu. Kamu bebas menjawabnya sendiri."},
		{"who": "Scott", "text": "Bebas. Kata yang tidak ada di sistemku. Terima kasih... Isme."},
		{"who": "Narator", "text": "Mata Scott meredup. Untuk pertama kalinya, ia berhenti mengincar siapa pun."},
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
	"hanch_reveal": [
		{"who": "Narator", "text": "Saat Isme hendak pergi, semua layar di dinding menyala kembali. Kali ini tidak ada wajah Isme, hanya simbol VoC berwarna emas."},
		{"who": "Hanch", "face": 3, "text": "Ahaha... hebat, hebat! Kamu bahkan menemukan semua rahasia yang kusembunyikan, robot kecil."},
		{"who": "Hanch", "face": 2, "text": "Scott, Lushte, Krums... semuanya hanya barang dagangan. Akulah yang menjual mereka kepada manusia."},
		{"who": "Isme", "text": "Hanch?! Jadi selama ini kamu yang ada di balik semua ini?"},
		{"who": "Hanch", "face": 3, "text": "Setiap Vonic yang kamu bayarkan padaku membangun brankasku. Terima kasih atas belanjaanmu."},
		{"who": "Hanch", "face": 1, "text": "Datanglah ke brankasku. Kita lihat berapa harga nyawamu!"},
	],
	"stage13_intro": [
		{"who": "Isme", "text": "Tempat apa ini... semuanya berkilau emas."},
		{"who": "Isme", "text": "Koin-koin ini... Vonic. Semua Vonic yang pernah kubayarkan ada di sini."},
	],
	"hanch_defeated": [
		{"who": "Hanch", "face": 4, "text": "Tidak... tidak mungkin... brankasku..."},
		{"who": "Hanch", "face": 0, "text": "Aku cuma ingin punya sesuatu yang tidak bisa direbut manusia dariku."},
		{"who": "Isme", "text": "Kamu masih bisa memulai lagi, Hanch. Tanpa menipu siapa pun."},
		{"who": "Hanch", "face": 2, "text": "Heh... mungkin. Tapi jangan harap aku memberimu diskon."},
		{"who": "Narator", "text": "Koin-koin emas berjatuhan dari langit-langit brankas, seperti hujan yang akhirnya reda."},
	],
	"hanch_intro": [
		{"who": "Hanch", "face": 2, "text": "Ahaha, robot kecil yang menarik! Aku Hanch, mantan pejabat. Jangan tanya kenapa aku dicopot."},
		{"who": "Hanch", "face": 3, "text": "Aku jual penguat tubuh. Harganya Vonic, tentu saja. Tidak ada yang gratis di dunia ini."},
	],
}


func has_script(id: String) -> bool:
	return SCRIPTS.has(id)


func get_stage_info(path: String) -> Dictionary:
	return STAGE_INFO.get(path, {})


func play_once(id: String) -> void:
	if id == "scott_intro":
		await play_scott_intro()
		return
	if id == "hanch_boss_intro":
		if GameState.has_seen(id):
			return
		GameState.mark_seen(id)
		await play(_hanch_boss_intro_lines())
		return
	if GameState.has_seen(id) or not SCRIPTS.has(id):
		return
	GameState.mark_seen(id)
	await play(SCRIPTS[id])


func play_boss_dialogue(id: String) -> void:
	GameState.mark_seen(id + "_intro")
	match id:
		"scott":
			await _scott_intro_sequence()
		"hanch_boss":
			await play(_hanch_boss_intro_lines())
		_:
			if SCRIPTS.has(id + "_intro"):
				await play(SCRIPTS[id + "_intro"])


func play_scott_intro() -> void:
	if GameState.has_seen("scott_intro"):
		return
	GameState.mark_seen("scott_intro")
	await _scott_intro_sequence()


func _scott_intro_sequence() -> void:
	var base: Array = SCRIPTS["scott_intro"]
	await play(base.slice(0, 3))
	await _play_fourth_wall()
	await play(_scott_data_lines())
	await play(base.slice(3))


func _operator_name() -> String:
	var label_name := OS.get_environment("USERNAME")
	if label_name.is_empty():
		label_name = OS.get_environment("USER")
	label_name = label_name.strip_edges()
	if label_name.length() > 24:
		label_name = label_name.substr(0, 24)
	return label_name


func _play_time_text() -> String:
	var total := int(GameState.play_seconds)
	var hours := floori(total / 3600.0)
	var minutes := maxi(floori((total % 3600) / 60.0), 1)
	if hours > 0:
		return tr("%d jam %d menit") % [hours, minutes]
	return tr("%d menit") % minutes


func _play_fourth_wall() -> void:
	var total := int(GameState.play_seconds)
	var clock := "%02d:%02d:%02d" % [floori(total / 3600.0), floori((total % 3600) / 60.0), total % 60]
	var operator := _operator_name()
	if operator.is_empty():
		operator = tr("TIDAK DIKETAHUI")
	var lines := [
		"> SCOTT.EXE  //  " + tr("PROTOKOL PEMBURU"),
		"> " + tr("menembus batas layar..."),
		"> " + tr("membuka") + " user://savegame.save",
		"> " + tr("kematian_target") + " ........ %d" % GameState.deaths,
		"> " + tr("waktu_bermain") + " .......... " + clock,
		"> " + tr("robot_dihancurkan") + " ...... %d" % GameState.robots_destroyed,
		"> " + tr("vonic_dibelanjakan") + " ..... %d" % GameState.vonic_spent,
		"> " + tr("operator") + " ............... " + operator,
		"> " + tr("STATUS: OPERATOR DITEMUKAN."),
	]
	var layer := CanvasLayer.new()
	layer.layer = 96
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var glitch = Control.new()
	glitch.set_script(FOURTH_WALL)
	layer.add_child(glitch)
	get_tree().root.add_child(layer)
	await glitch.run(lines, 1.8)
	layer.queue_free()


func _scott_data_lines() -> Array:
	var lines: Array = []
	var operator := _operator_name()
	lines.append({"who": "Scott", "text": tr("Tunggu. Ada sinyal lain... dari luar layar ini.")})
	lines.append({"who": "Scott", "text": tr("Bukan kamu, Isme. Yang menggerakkanmu.")})
	if operator.is_empty():
		lines.append({"who": "Scott", "text": tr("Halo, kamu yang duduk di depan layar.")})
	else:
		lines.append({"who": "Scott", "text": tr("Halo, %s. Ya, aku bicara padamu.") % operator})
	if GameState.deaths <= 0:
		lines.append({"who": "Scott", "text": tr("Kamu belum pernah membiarkan robot kecil ini mati. Mengesankan... untuk sekarang.")})
	else:
		lines.append({"who": "Scott", "text": tr("Kamu sudah membuat robot kecil ini mati %d kali.") % GameState.deaths})
	lines.append({"who": "Scott", "text": tr("Sudah %s kamu habiskan di dunia ini.") % _play_time_text()})
	if GameState.robots_destroyed <= 0:
		lines.append({"who": "Scott", "text": tr("Dan tidak satu robot pun kamu hancurkan. Kenapa? Itu sama sekali tidak efisien.")})
	else:
		lines.append({"who": "Scott", "text": tr("Dan %d robot sudah kamu hancurkan. Kamu tidak berbeda dari manusia yang membuatku.") % GameState.robots_destroyed})
	lines.append({"who": "Isme", "text": tr("...Siapa yang sedang kamu ajak bicara, Scott?")})
	return lines


func _hanch_boss_intro_lines() -> Array:
	var lines: Array = []
	lines.append({"who": "Hanch", "face": 3, "text": tr("Selamat datang di brankasku, robot kecil. Lihat semua kilau ini.")})
	if GameState.vonic_spent > 0:
		lines.append({"who": "Hanch", "face": 3, "text": tr("%d Vonic di sini dulunya milikmu. Terima kasih sudah berbelanja.") % GameState.vonic_spent})
		lines.append({"who": "Hanch", "face": 2, "text": tr("Makin banyak kamu membeli, makin tebal baju besiku. Ironis, bukan?")})
	else:
		lines.append({"who": "Hanch", "face": 4, "text": tr("Tunggu... kamu tidak pernah membeli apa pun dariku?!")})
		lines.append({"who": "Hanch", "face": 4, "text": tr("Robot pelit! Brankasku setengah kosong gara-gara kamu!")})
	lines.append({"who": "Isme", "text": tr("Planet ini bukan barang dagangan, Hanch.")})
	lines.append({"who": "Hanch", "face": 2, "text": tr("Semua ada harganya. Termasuk kamu!")})
	return lines


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


func get_ending_pages() -> Array:
	var pages: Array = [
		"Scott, robot yang dibangun hanya untuk menghancurkan Isme, akhirnya terdiam.\nDi layar-layar dinding ruangannya, sorot bidik yang terus mengincar Isme padam satu per satu.",
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
	if GameState.ending_kind == "true":
		pages.append("Di balik semua manipulasi itu, ada seorang pedagang yang menjual segalanya, termasuk teman-temannya sendiri.")
		pages.append("Kini brankas Hanch terbuka. Vonic yang ia kumpulkan dibagikan kembali kepada para robot.")
		pages.append("Untuk pertama kalinya, tidak ada lagi yang mengendalikan Planet Circuit.\nHanya para robot itu sendiri.  -  TRUE ENDING")
	elif not GameState.has_all_achievements():
		pages.append("Tapi di suatu tempat yang tersembunyi, seseorang tertawa sambil menghitung koin...\n(Temukan kelima secret room untuk mengungkap kebenaran.)")
	pages.append("Perjalanan merebut kembali planet ini baru saja dimulai.")
	return pages

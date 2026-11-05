extends Node
## Kiểm tra nhạc nền: bài vườn khi vào game, chuyển sang bài shop và quay lại.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	var music = get_node("/root/Music")
	music.set_enabled(true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.5).timeout
	var p = music._players[music._active]
	print("Vào game: ", music.current, " đang phát=", p.playing, " loop=", p.stream.loop, " dài=", snapped(p.stream.get_length(), 0.1), "s vol=", snapped(p.volume_db, 0.1))
	main._open_nursery()
	await get_tree().create_timer(1.5).timeout
	p = music._players[music._active]
	print("Mở Shop cây: ", music.current, " đang phát=", p.playing, " bài cũ dừng=", not music._players[1 - music._active].playing)
	main._close_nursery()
	await get_tree().create_timer(1.5).timeout
	print("Về vườn: ", music.current, " phát tiếp từ giây ", snapped(music._players[music._active].get_playback_position(), 0.1))
	main._open_menu()
	await get_tree().process_frame
	music.set_enabled(false)
	print("Tắt nhạc: đang phát=", music._players[0].playing or music._players[1].playing)
	music.set_enabled(true)
	music.set_volume(0.5)
	print("Bật lại, âm lượng 50%: ", music._players[music._active].playing, " ", snapped(music._players[music._active].volume_db, 0.1), " dB")
	print("XONG")
	get_tree().quit()

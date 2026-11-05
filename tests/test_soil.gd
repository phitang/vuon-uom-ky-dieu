extends SceneTree
const GS := preload("res://scripts/game_state.gd")
const Data := preload("res://scripts/data.gd")

func mk(gs, i, rare: bool) -> void:
	var g := {"hoa":["lan","lan"] if rare else ["cuc","cuc"],"la":["tron","tron"],"than":["thang","thang"],"mau":["xanh","xanh"] if rare else ["vang","vang"],"co":["vua","vua"]}
	gs.seeds.append({"gen": g, "bo_me": []})
	gs.plant_seed(i, gs.seeds.size() - 1)

func _init() -> void:
	var gs = GS.new()
	gs.new_game()
	print("đất ban đầu: ", gs.soils, " sở hữu: ", gs.soils_owned.keys())
	mk(gs, 0, false)
	mk(gs, 1, true)
	print("độ hiếm cây 1: ", Data.RARITY_NAMES[load("res://scripts/genetics.gd").rarity(gs.pots[1]["gen"])], " cần đất: ", gs.soil_needed(gs.pots[1]))
	gs._advance(3600.0)
	print("chưa tưới sau 1 giờ: tien_do=", gs.pots[0]["tien_do"], " sức khỏe=", gs.pots[0]["suc_khoe"])
	gs.water(0); gs.water(1)
	# 8 giờ có nước (tưới mỗi giờ)
	for h in 8:
		gs._advance(3600.0); gs.water(0); gs.water(1)
	print("8 giờ đủ nước: thường=%.2f  quý(đất thường)=%.2f  mismatch=%d" % [gs.pots[0]["suc_khoe"], gs.pots[1]["suc_khoe"], gs.soil_mismatch(1)])
	# 4 giờ không nước sau khi cạn
	gs.pots[0]["nuoc"] = 0.0; gs.pots[1]["nuoc"] = 0.0
	gs._advance(4 * 3600.0)
	print("4 giờ khô: thường=%.2f héo=%s  quý=%.2f chết=%s" % [gs.pots[0]["suc_khoe"], gs.pots[0]["heo"], gs.pots[1]["suc_khoe"], gs.pots[1]["chet"]])
	# bán/bỏ -> mất đất; chậu mới không có đất
	gs.remove_plant(1)
	gs.coins = 300000
	gs.buy("chau")
	print("sau bỏ cây và mua chậu: ", gs.soils)
	print("gieo vào chậu không đất: ", gs.plant_seed(3, 0) if gs.seeds.size() > 0 else "không có hạt")
	print("cho đất tốt khi chưa mua: ", gs.fill_soil(3, "tot"))
	print("mua đất tốt: ", gs.buy("dat_tot"), " mua lần 2: ", gs.buy("dat_tot"), " xu=", gs.coins)
	print("cho đất tốt: ", gs.fill_soil(3, "tot"), " -> ", gs.soils)
	gs.buy("dat_hiem")
	gs.fill_soil(1, "hiem")
	mk(gs, 1, true)
	gs.water(1)
	for h in 8:
		gs._advance(3600.0); gs.water(1)
	print("quý trong đất hiếm 8 giờ: %.2f" % gs.pots[1]["suc_khoe"])
	gs.save_game()
	var gs2 = GS.new()
	gs2.load_game()
	print("tải lại: đất=", gs2.soils, " sở hữu=", gs2.soils_owned.keys())
	gs.free(); gs2.free()
	quit()

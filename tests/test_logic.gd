extends SceneTree
const Gen := preload("res://scripts/genetics.gd")
const Data := preload("res://scripts/data.gd")
const GS := preload("res://scripts/game_state.gd")

func _init() -> void:
	var gs = GS.new()
	gs.new_game()
	print("xu=", gs.coins, " hat=", gs.seeds.size())
	gs.plant_seed(0, 0)
	gs.plant_seed(1, 0)
	gs.water(0); gs.water(1)
	var p = gs.pots[0]
	print("giong=", Gen.variety_name(p["gen"]), " key=", Gen.variety_key(p["gen"]), " hiem=", Gen.rarity(p["gen"]))
	# cho lớn tới ra hoa, có tưới
	for i in 30:
		gs._advance(600.0)
		gs.water(0); gs.water(1)
	print("giai doan=", gs.stage_of(gs.pots[0]), " ", gs.stage_of(gs.pots[1]), " sotay=", gs.collection.size())
	print("gia thi truong=", gs.market_price(gs.pots[0]))
	print("lai=", gs.cross(0, 1), " hat=", gs.seeds.size())
	var counts = [0,0,0,0]
	for i in 2000:
		counts[Gen.rarity(Gen.cross(Gen.random_genome(2), Gen.random_genome(2), 0.02))] += 1
	print("phan bo hiem lai hat bi an: ", counts)
	for pct in [50, 80, 100, 150, 200, 300]:
		print(pct, "% -> ", snapped(gs.price_chance(100, pct, 2.0), 0.001))
	var c = gs.new_customer()
	print(c["type"], ": ", gs.wish_text(c))
	print("ty le mua: ", gs.buy_chance(gs.pots[0], gs.market_price(gs.pots[0]), c, "nhiet_tinh"))
	print("hot: ", gs.hot_traits())
	# khô 25 giờ -> chết
	gs._advance(25*3600.0)
	print("chet=", gs.pots[0]["chet"], " ly do=", gs.pots[0].get("ly_do"))
	gs.free()
	quit()

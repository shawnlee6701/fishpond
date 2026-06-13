extends RefCounted
class_name GameState

const DataLoaderScript := preload("res://scripts/data_loader.gd")

var cash: int = 0
var day: int = 1
var current_pond: Dictionary = {}
var inspection_cost_total: int = 0
var one_net_income: int = 0
var transfer_income: int = 0
var work_cost: int = 0
var fish_income: int = 0
var last_result: Dictionary = {}

func _init() -> void:
	var balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	cash = int(balance.get("initial_cash", 10000))
	day = 1

func reset_round() -> void:
	current_pond = {}
	inspection_cost_total = 0
	one_net_income = 0
	transfer_income = 0
	work_cost = 0
	fish_income = 0
	last_result = {}

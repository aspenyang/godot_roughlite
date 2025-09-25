extends Node
#class_name SaveManager

# ==============================================
# SaveManager
# Handles: slot files, checkpoints, level timing, run completion.
# Works for desktop + HTML5 (user:// mapped to OS / IndexedDB).
#
# Public Static API (summary):
#   slot_exists(slot)
#   load_game(slot) -> Dictionary
#   save_game(slot, data) -> bool
#   get_all_slots_info() -> Array
#   get_default_data(slot_index, levels_total=10) -> Dictionary
#   upsert_and_save(slot, mutate_func: Callable, levels_total=10) -> Dictionary
#
#   begin_level_if_needed(slot)
#   complete_level_success(slot, final_level: bool)
#   fail_level(slot, final_level: bool, policy_add_time := false)
#   mark_interrupted(slot)
#
#   set_checkpoint(slot, scene_path: String, level_id: int, player_state := {}, levels_total := 10)
#   clear_checkpoint(slot)
#   has_resume_checkpoint(slot) -> bool
#
#   update_player_state(slot, player_state: Dictionary)
#   extract_player_state(data: Dictionary) -> Dictionary
#
# Data Shape (dictionary):
# {
#	"slot": 1,
#	"version": 1,
#	"levels_total": 10,
#	"levels_completed": 0,
#	"level_times": [],
#	"current_level_start_time": 0.0,
#	"last_result": "",
#	"final_status": "in_progress",        # "in_progress" | "success" | "fail"
#	"interrupted": false,
#	"checkpoint": {                       # Present only if mid-run / at level entry
#		"scene_path": "res://scenes/Level1.tscn",
#		"level_id": 1,
#		"entered_unix_time": 0.0,
#		"player_state": {
#			"hp": 50,
#			"max_hp": 50,
#			"inventory": [],                # optional future expansion
#			"seed": 0                       # procedural seed, optional
#		}
#	},
#	"timestamp": "",
# }
#
# ==============================================

const SAVE_SLOTS: int = 3
const DATA_VERSION: int = 1

const SAVE_PATHS: Array[String] = [
	"user://save_slot_1.save",
	"user://save_slot_2.save",
	"user://save_slot_3.save"
]

# -------------- Public Basic API --------------

static func slot_exists(slot: int) -> bool:
	if not _valid_slot(slot):
		return false
	return FileAccess.file_exists(SAVE_PATHS[slot])

static func load_game(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return {}
	if not FileAccess.file_exists(SAVE_PATHS[slot]):
		return {}
	var file := FileAccess.open(SAVE_PATHS[slot], FileAccess.READ)
	if file == null:
		return {}
	var raw: Variant = file.get_var(false) # no object instantiation
	file.close()
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = raw
	d = _apply_defaults_and_migrate(d)
	return d

static func save_game(slot: int, data: Dictionary) -> bool:
	if not _valid_slot(slot):
		return false
	var file := FileAccess.open(SAVE_PATHS[slot], FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: Could not open file for writing: %s" % SAVE_PATHS[slot])
		return false
	file.store_var(data, false)
	file.close()
	return true

static func get_all_slots_info() -> Array:
	var arr: Array = []
	for i in range(SAVE_SLOTS):
		arr.append(load_game(i))
	return arr

static func get_default_data(slot_index: int, levels_total: int = 10) -> Dictionary:
	return {
		"slot": slot_index + 1,
		"version": DATA_VERSION,
		"levels_total": levels_total,
		"levels_completed": 0,
		"level_times": [],
		"current_level_start_time": 0.0,
		"last_result": "",
		"final_status": "in_progress",
		"interrupted": false,
		"checkpoint": {},
		"timestamp": ""
	}

# Transaction / upsert style change
static func upsert_and_save(slot: int, mutate_func: Callable, levels_total: int = 10) -> Dictionary:
	var data := load_game(slot)
	if data.is_empty():
		data = get_default_data(slot, levels_total)
	mutate_func.call(data)
	data["timestamp"] = _make_timestamp()
	save_game(slot, data)
	return data

# -------------- level Helpers --------------

static func begin_level_if_needed(slot: int) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if d.get("current_level_start_time", 0.0) <= 0.0:
			d["current_level_start_time"] = _now()
			d["interrupted"] = false
			d["last_result"] = ""
	)

static func complete_level_success(slot: int, final_level: bool) -> Dictionary:
	return upsert_and_save(slot, func(d):
		var start_time: float = d.get("current_level_start_time", 0.0)
		if start_time > 0.0:
			var duration = _now() - start_time
			d["level_times"].append(duration)
			d["levels_completed"] = int(d.get("levels_completed", 0)) + 1
		d["current_level_start_time"] = 0.0
		d["last_result"] = "success"
		# Clear checkpoint because level finished
		if d.has("checkpoint"):
			d.erase("checkpoint")
		if final_level:
			d["final_status"] = "success"
	)

static func fail_level(slot: int, final_level: bool, policy_add_time: bool = false) -> Dictionary:
	return upsert_and_save(slot, func(d):
		var start_time: float = d.get("current_level_start_time", 0.0)
		if policy_add_time and start_time > 0.0:
			var duration = _now() - start_time
			d["level_times"].append(duration)
			# Usually don't increment levels_completed on failure
		d["current_level_start_time"] = 0.0
		d["last_result"] = "fail"
		if final_level:
			d["final_status"] = "fail"
		# Keep checkpoint if you want to retry from start of level; remove if not:
		# (Policy decision) For a fail you might KEEP the checkpoint so user restarts level.
	)

static func mark_interrupted(slot: int) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if d.get("current_level_start_time", 0.0) > 0.0:
			d["interrupted"] = true
	)

# -------------- Checkpoint Management --------------

static func set_checkpoint(slot: int, scene_path: String, level_id: int, player_state: Dictionary = {}, levels_total: int = 10) -> Dictionary:
	return upsert_and_save(slot, func(d):
		# Ensure level started
		if d.get("current_level_start_time", 0.0) <= 0.0:
			d["current_level_start_time"] = _now()
		d["checkpoint"] = {
			"scene_path": scene_path,
			"level_id": level_id,
			"entered_unix_time": _now(),
			"player_state": player_state
		}
		d["interrupted"] = false
	)

static func clear_checkpoint(slot: int) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if d.has("checkpoint"):
			d.erase("checkpoint")
	)

static func has_resume_checkpoint(slot: int) -> bool:
	var d = load_game(slot)
	if d.is_empty():
		return false
	if d.get("final_status", "in_progress") != "in_progress":
		return false
	if not d.has("checkpoint"):
		return false
	# Optional: also require interrupted OR current_level_start_time > 0
	return true

# -------------- Player State Helpers --------------

static func update_player_state(slot: int, player_state: Dictionary) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if not d.has("checkpoint"):
			return
		var cp: Dictionary = d["checkpoint"]
		cp["player_state"] = player_state
		d["checkpoint"] = cp
	)

static func extract_player_state(data: Dictionary) -> Dictionary:
	if data.has("checkpoint"):
		var cp = data["checkpoint"]
		if typeof(cp) == TYPE_DICTIONARY and cp.has("player_state"):
			var ps = cp["player_state"]
			if typeof(ps) == TYPE_DICTIONARY:
				return ps
	return {}

# -------------- Internal Helpers --------------

static func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SAVE_SLOTS

static func _now() -> float:
	return Time.get_unix_time_from_system()

static func _make_timestamp() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	]

static func _apply_defaults_and_migrate(d: Dictionary) -> Dictionary:
	# If missing version, treat as legacy
	if not d.has("version"):
		d["version"] = 1
	
	# Example future migration scaffold:
	# if d["version"] < 2:
	#     # transform or add keys
	#     d["version"] = 2
	
	# Required keys & defaults
	var required := {
		"slot": 1,
		"version": DATA_VERSION,
		"levels_total": 10,
		"levels_completed": 0,
		"level_times": [],
		"current_level_start_time": 0.0,
		"last_result": "",
		"final_status": "in_progress",
		"interrupted": false,
		"checkpoint": {},
		"timestamp": ""
	}
	for k in required.keys():
		if not d.has(k):
			d[k] = required[k]
	
	# Type normalizations
	if typeof(d["level_times"]) != TYPE_ARRAY:
		d["level_times"] = []
	if typeof(d["checkpoint"]) != TYPE_DICTIONARY:
		d["checkpoint"] = {}
	
	return d

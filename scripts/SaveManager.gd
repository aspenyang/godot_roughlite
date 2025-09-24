extends Node
class_name SaveManager

# ==============================================
# SaveManager
# Handles: slot files, checkpoints, round timing, run completion.
# Works for desktop + HTML5 (user:// mapped to OS / IndexedDB).
#
# Public Static API (summary):
#   slot_exists(slot)
#   load_game(slot) -> Dictionary
#   save_game(slot, data) -> bool
#   get_all_slots_info() -> Array
#   get_default_data(slot_index, rounds_total=10) -> Dictionary
#   upsert_and_save(slot, mutate_func: Callable, rounds_total=10) -> Dictionary
#
#   begin_level_if_needed(slot)
#   complete_level_success(slot, final_level: bool)
#   fail_level(slot, final_level: bool, policy_add_time := false)
#   mark_interrupted(slot)
#
#   set_checkpoint(slot, scene_path: String, level_id: int, levels_total := 10)
#   clear_checkpoint(slot)
#   has_resume_checkpoint(slot) -> bool
#
#   update_player_state(slot, player_state: Dictionary)
#   extract_player_state(data: Dictionary) -> Dictionary
#
# Data Shape (dictionary) JSON (pretty-printed):
# {
#   "slot": 1,
#   "version": 1,
#   "runs_completed": 0,
#   "levels_total": 10,
#   "levels_completed": 0,
#   "level_times": [],
#   "current_level_start_time": 0.0,
#   "last_result": "",                      # result of last finished level
#   "final_status": "in_progress",           # in_progress | success | fail (run status)
#   "interrupted": false,
#   "maze_used": false,
#   "reward_used": false,
#   "checkpoint": {                          # present only if mid-run / at level entry
#       "scene_path": "res://scenes/Level1.tscn",
#       "level_id": 1,
#       "entered_unix_time": 0.0
#   },
#   "timestamp": "2025-09-25T10:00:00"
# }
#
# ==============================================

const SAVE_SLOTS: int = 3
const DATA_VERSION: int = 1

# JSON save file paths (no legacy migration; old .save files ignored)
const SAVE_PATHS: Array[String] = [
	"user://save_slot_1.json",
	"user://save_slot_2.json",
	"user://save_slot_3.json"
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
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: JSON root not dictionary for slot %d" % slot)
		return {}
	var d: Dictionary = parsed
	d = _apply_defaults_and_migrate(d)
	return d

static func save_game(slot: int, data: Dictionary) -> bool:
	if not _valid_slot(slot):
		return false
	var file := FileAccess.open(SAVE_PATHS[slot], FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: Could not open file for writing: %s" % SAVE_PATHS[slot])
		return false
	var json_text := JSON.stringify(data, "  ")
	file.store_string(json_text)
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
		"runs_completed": 0,
		"levels_total": levels_total,
		"levels_completed": 0,
		"level_times": [],
		"current_level_start_time": 0.0,
		"last_result": "",
		"final_status": "in_progress",
		"interrupted": false,
		"maze_used": false,
		"reward_used": false,
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

# -------------- Round Helpers --------------

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
		if d.has("checkpoint"):
			d.erase("checkpoint")
		if final_level:
			d["final_status"] = "success"
			# End of run reset flags
			d["maze_used"] = false
			d["reward_used"] = false
			d["runs_completed"] = int(d.get("runs_completed", 0)) + 1
	)

static func fail_level(slot: int, final_level: bool, policy_add_time: bool = false) -> Dictionary:
	return upsert_and_save(slot, func(d):
		var start_time: float = d.get("current_level_start_time", 0.0)
		if policy_add_time and start_time > 0.0:
			var duration = _now() - start_time
			d["level_times"].append(duration)
		d["current_level_start_time"] = 0.0
		d["last_result"] = "fail"
		if final_level:
			d["final_status"] = "fail"
			d["maze_used"] = false
			d["reward_used"] = false
			d["runs_completed"] = int(d.get("runs_completed", 0)) + 1
		# Policy: keep checkpoint? For failure we keep so player can retry; adjust if needed.
	)

static func mark_interrupted(slot: int) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if d.get("current_level_start_time", 0.0) > 0.0:
			d["interrupted"] = true
	)

# -------------- Checkpoint Management --------------

static func set_checkpoint(slot: int, scene_path: String, level_id: int, levels_total: int = 10) -> Dictionary:
	return upsert_and_save(slot, func(d):
		if d.get("levels_total", 0) != levels_total:
			d["levels_total"] = levels_total
		if d.get("current_level_start_time", 0.0) <= 0.0:
			d["current_level_start_time"] = _now()
		d["checkpoint"] = {
			"scene_path": scene_path,
			"level_id": level_id,
			"entered_unix_time": _now()
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
	return true

# -------------- Player State Helpers --------------

static func update_player_state(slot: int, _player_state: Dictionary) -> Dictionary:
	# Deprecated: Player state no longer stored. Return data unchanged.
	return load_game(slot)

static func extract_player_state(_data: Dictionary) -> Dictionary:
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
	if not d.has("version"):
		d["version"] = DATA_VERSION

	# Migration from old 'rounds_*' schema if present (best-effort)
	if d.has("rounds_total") and not d.has("levels_total"):
		d["levels_total"] = d.get("rounds_total", 10)
	if d.has("rounds_completed") and not d.has("levels_completed"):
		d["levels_completed"] = d.get("rounds_completed", 0)
	if d.has("round_times") and not d.has("level_times"):
		d["level_times"] = d.get("round_times", [])
	if d.has("current_round_start_time") and not d.has("current_level_start_time"):
		d["current_level_start_time"] = d.get("current_round_start_time", 0.0)

	# Remove deprecated keys (optional cleanup)
	d.erase("rounds_total")
	d.erase("rounds_completed")
	d.erase("round_times")
	d.erase("current_round_start_time")

	var required := {
		"slot": 1,
		"version": DATA_VERSION,
		"runs_completed": 0,
		"levels_total": 10,
		"levels_completed": 0,
		"level_times": [],
		"current_level_start_time": 0.0,
		"last_result": "",
		"final_status": "in_progress",
		"interrupted": false,
		"maze_used": false,
		"reward_used": false,
		"checkpoint": {},
		"timestamp": ""
	}
	for k in required.keys():
		if not d.has(k):
			d[k] = required[k]

	if typeof(d["level_times"]) != TYPE_ARRAY:
		d["level_times"] = []
	if typeof(d["checkpoint"]) != TYPE_DICTIONARY:
		d["checkpoint"] = {}

	return d

# Backwards compatibility wrappers (optional). Keep old method names so existing calls won't break.
static func begin_round_if_needed(slot: int) -> Dictionary:
	return begin_level_if_needed(slot)
static func complete_round_success(slot: int, final_round: bool) -> Dictionary:
	return complete_level_success(slot, final_round)
static func fail_round(slot: int, final_round: bool, policy_add_time: bool=false) -> Dictionary:
	return fail_level(slot, final_round, policy_add_time)

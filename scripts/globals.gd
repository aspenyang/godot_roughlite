extends Node

# ============================================
# Globals: Central runtime state/cache for the current run.
# Responsibilities:
#  - Track active save slot
#  - Cache loaded save data (avoid constant disk reads)
#  - Provide helpers for checkpoints, round lifecycle, persistence
#  - Apply / update player state (currently health; expandable)
#
# Requires: SaveManager (autoload or accessible via class_name)
# ============================================

var active_slot: int = -1
var save_data: Dictionary = {}
var rounds_total: int = 10
var is_resuming_from_checkpoint: bool = false

# Cached player reference (set by player script on _ready)
var player: Node = null


# ---------- Slot & Save Management ----------

func set_active_slot(slot: int) -> void:
	active_slot = slot
	load_slot(slot)

func load_slot(slot: int) -> void:
	save_data = SaveManager.load_game(slot)
	if save_data.is_empty():
		save_data = SaveManager.get_default_data(slot, rounds_total)
		SaveManager.save_game(slot, save_data)
	is_resuming_from_checkpoint = SaveManager.has_resume_checkpoint(slot)

func start_new_run(slot: int) -> void:
	active_slot = slot
	save_data = SaveManager.get_default_data(slot, rounds_total)
	SaveManager.save_game(slot, save_data)
	is_resuming_from_checkpoint = false

func persist() -> void:
	if active_slot >= 0:
		SaveManager.save_game(active_slot, save_data)


# ---------- Checkpoint Helpers ----------

func has_checkpoint() -> bool:
	return save_data.has("checkpoint") \
		and typeof(save_data["checkpoint"]) == TYPE_DICTIONARY \
		and not save_data["checkpoint"].is_empty()

func get_checkpoint_scene_path() -> String:
	return save_data["checkpoint"].get("scene_path", "") if has_checkpoint() else ""

func get_checkpoint_level_id() -> int:
	return int(save_data["checkpoint"].get("level_id", -1)) if has_checkpoint() else -1

func get_player_state_from_checkpoint() -> Dictionary:
	if has_checkpoint():
		var cp: Dictionary = save_data["checkpoint"]
		if cp.has("player_state") and typeof(cp["player_state"]) == TYPE_DICTIONARY:
			return cp["player_state"]
	return {}

func set_checkpoint(scene_path: String, level_id: int, player_state: Dictionary = {}) -> void:
	if active_slot < 0:
		return
	save_data = SaveManager.set_checkpoint(active_slot, scene_path, level_id, player_state)
	is_resuming_from_checkpoint = false

func clear_checkpoint() -> void:
	if active_slot >= 0 and has_checkpoint():
		save_data = SaveManager.clear_checkpoint(active_slot)

func update_checkpoint_player_state(player_state: Dictionary) -> void:
	if active_slot >= 0 and has_checkpoint():
		save_data = SaveManager.update_player_state(active_slot, player_state)

func mark_interrupted_and_save() -> void:
	if active_slot < 0:
		return
	SaveManager.mark_interrupted(active_slot)
	save_data = SaveManager.load_game(active_slot)
	is_resuming_from_checkpoint = true


# ---------- Round Lifecycle ----------

func begin_round_if_needed() -> void:
	if active_slot >= 0:
		save_data = SaveManager.begin_round_if_needed(active_slot)

func complete_round_success(final_round: bool) -> void:
	if active_slot >= 0:
		save_data = SaveManager.complete_round_success(active_slot, final_round)

func fail_round(final_round: bool, record_time: bool = false) -> void:
	if active_slot >= 0:
		save_data = SaveManager.fail_round(active_slot, final_round, record_time)


# ---------- Player State Integration ----------

func apply_player_state_to_player(p: Node) -> void:
	if p == null:
		return
	var ps := get_player_state_from_checkpoint()
	if ps.is_empty():
		return

	var health_node: Node = p.get_node_or_null("Health")
	if health_node:
		if ps.has("max_hp"):
			health_node.max_health = int(ps["max_hp"])
		if ps.has("hp"):
			health_node.current_health = clamp(
				int(ps["hp"]), 0, int(health_node.max_health)
			)
			if health_node.has_signal("health_changed"):
				health_node.emit_signal("health_changed", health_node.current_health)

func export_player_state() -> Dictionary:
	if player == null:
		return {}
	var health_node: Node = player.get_node_or_null("Health")
	var hp := 0
	var max_hp := 0
	if health_node:
		if "current_health" in health_node:
			hp = int(health_node.current_health)
		if "max_health" in health_node:
			max_hp = int(health_node.max_health)
	return {"hp": hp, "max_hp": max_hp}

func snapshot_player_to_checkpoint() -> void:
	if has_checkpoint():
		update_checkpoint_player_state(export_player_state())


# ---------- Run Status & Metrics ----------

func is_run_finished() -> bool:
	return save_data.get("final_status", "in_progress") in ["success", "fail"]

func get_rounds_completed() -> int:
	return int(save_data.get("rounds_completed", 0))

func get_rounds_total() -> int:
	return int(save_data.get("rounds_total", rounds_total))

func get_round_times() -> Array:
	return save_data.get("round_times", [])

func get_total_run_time() -> float:
	var total := 0.0
	for t in get_round_times():
		if typeof(t) in [TYPE_FLOAT, TYPE_INT]:
			total += float(t)
	var current_start := float(save_data.get("current_round_start_time", 0.0))
	if current_start > 0.0 and not is_run_finished():
		total += Time.get_unix_time_from_system() - current_start
	return total

func get_last_result() -> String:
	return String(save_data.get("last_result", ""))

func get_final_status() -> String:
	return String(save_data.get("final_status", "in_progress"))


# ---------- Utility Formatting ----------

func format_time(seconds: float) -> String:
	var secs := int(seconds)
	return str(secs / 60).pad_zeros(2) + ":" + str(secs % 60).pad_zeros(2)


# ---------- Scene Transition Helpers ----------

func prepare_level_entry(scene_path: String, level_id: int) -> void:
	begin_round_if_needed()
	set_checkpoint(scene_path, level_id, export_player_state())

func resume_if_possible() -> bool:
	return active_slot >= 0 and is_resuming_from_checkpoint and has_checkpoint()


# ---------- Debug ----------

func debug_print_state() -> void:
	print("--- Globals Run State ---")
	print("active_slot:", active_slot)
	print("rounds_completed:", get_rounds_completed(), "/", get_rounds_total())
	print("final_status:", get_final_status())
	print("has_checkpoint:", has_checkpoint())
	if has_checkpoint():
		print("checkpoint scene:", get_checkpoint_scene_path())
	print("-------------------------")

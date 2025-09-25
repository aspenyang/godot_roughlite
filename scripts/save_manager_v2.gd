extends Node

# Data Shape (dictionary):
# {
#	"slot": 1,
#	"levels_total": 10,
#	"levels_completed": 0,
#	"last_result": "",
#	"final_status": "in_progress",        # "in_progress" | "success" | "fail"
#	"interrupted": false,
#	"checkpoint": {                       # Present only if mid-run / at level entry
#		"scene_path": "res://scenes/Level1.tscn",
#		"room_completed": 1,
#		"player_state": {
#			"hp": 50,
#			"max_hp": 50,
#			"inventory": [],                # optional future expansion
#			"seed": 0                       # procedural seed, optional
#		}
#	},
# }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func print_info():
	print(Globals.dynamic_data)
	#print(Globals.player.get_node("Health").current_health)

# -- Minimal save-to-disk API --
# RoomManager will build a Dictionary `data` and call write_save(data).
# `data` MUST contain an integer key "slot" (1..3). We simply serialize
# the dictionary to JSON and write it to user://save/save_slot_<slot>.json

const SAVE_DIR := "user://save"

func _get_save_path(slot: int) -> String:
	return "%s/save_slot_%d.json" % [SAVE_DIR, slot]

func _ensure_save_dir() -> void:
	# Create user save directory if missing using a DirAccess instance
	var da := DirAccess.open("user://")
	if da == null:
		push_error("write_save: unable to open user:// dir (code %d)" % [DirAccess.get_open_error()])
		return
	if not da.dir_exists("save"):
		var err := da.make_dir_recursive("save")
		if err != OK:
			push_error("write_save: failed to create save dir, code %d" % [err])

## Writes the provided data dictionary to the save file for its slot.
## Returns true on success, false on failure.
func write_save(data: Dictionary) -> bool:
	if data == null or not data.has("slot"):
		push_error("write_save: missing 'slot' in data")
		return false

	var slot := int(data["slot"])
	if slot <= 0:
		push_error("write_save: invalid slot '%s'" % [str(data["slot"])])
		return false

	_ensure_save_dir()
	var path := _get_save_path(slot)

	var json_text := JSON.stringify(data, "\t")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_save: failed to open '%s' (code %d)" % [path, FileAccess.get_open_error()])
		return false

	f.store_string(json_text)
	f.flush()
	f.close()

	# Optional debug print; comment out if noisy
	print("Saved slot %d -> %s (%d bytes)" % [slot, path, json_text.length()])
	return true
	

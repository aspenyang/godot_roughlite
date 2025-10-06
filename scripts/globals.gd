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

#var active_slot: int = -1
#var save_data: Dictionary = {}
#var rounds_total: int = 10
#var is_resuming_from_checkpoint: bool = false

#var completed_rooms: int = 0
# Cached player reference (set by player script on _ready)
var player: Node = null

#var dynamic_data: Dictionary = {}


var new_game: bool = true
var slot: int = 1
#var total_rooms: int = 5 #should be 7
var dynamic_data: Dictionary={} 

#func get_dynamic_data() -> Dictionary:
	#return {
		#"slot": 1,
		#"levels_total": 10,
		#"levels_completed": 0,
		#"last_result": "",
		#"final_status": "in_progress",  
		#"interrupted": false,
		#"checkpoint": {                       # Present only if mid-run / at level entry
#		"scene_path": "res://scenes/Level1.tscn",
#		"room_completed": 1,
#		"player_state": {
#			"hp": 50,
#			"max_hp": 50,
#			"inventory": [],                # optional future expansion
#			"seed": 0                       # procedural seed, optional
#		}
#	},
	#}

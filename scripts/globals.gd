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

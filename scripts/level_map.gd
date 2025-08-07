extends Node2D


func close_all_paths():
	$NorthWall.visible = true
	$SouthWall.visible = true
	$EastWall.visible = true
	$WestWall.visible = true
	$NorthPath.visible = false
	$SouthPath.visible = false
	$EastPath.visible = false
	$WestPath.visible = false

func north_pass():
	$NorthPath.visible = true
	$NorthWall.queue_free()
	
func south_pass():
	$SouthPath.visible = true
	$SouthWall.queue_free()
	
func east_pass():
	$EastPath.visible = true
	$EastWall.queue_free()
	
func west_pass():
	$WestPath.visible = true
	$WestWall.queue_free()

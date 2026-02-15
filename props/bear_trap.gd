extends Node3D

@onready var sound := $clang
@onready var trap := $trap
var currentTrap := "beartrap"
var isClosed : bool = false

func set_trap(closed: bool, blood: bool):
	var oldTrap = trap.find_child(currentTrap)
	oldTrap.visible = false
	
	var name : String = "beartrap"
	if (closed): 
		name += "_closed"
		isClosed = true
		sound.play()
	
	if (blood): 
		name += "_blood"
	
	var newTrap = trap.find_child(name)
	newTrap.visible = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if (isClosed):
		return
	
	if (body.has_method("damage")):
		body.damage(5)
		set_trap(true, true)
	#else:
		#set_trap(true, false)

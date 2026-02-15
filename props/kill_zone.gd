extends Node3D

@export_enum("blood", "drown") var cause = "blood"

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("kill"):
		body.kill(cause)

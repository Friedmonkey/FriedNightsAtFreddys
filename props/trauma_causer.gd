extends Area3D

@export var trauma_amount := 0.1

func set_trauma_amount(amount: float):
	trauma_amount = clampf(amount, 0, 1)

func cause_trauma():
	if trauma_amount <= 0:
		return
	var trauma_areas := get_overlapping_areas()
	for area in trauma_areas:
		if area.has_method("add_trauma"):
			area.add_trauma(trauma_amount)

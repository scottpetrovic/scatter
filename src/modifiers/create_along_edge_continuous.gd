@tool
extends "base_modifier.gd"


@export var item_length := 2.0
@export var ignore_slopes := false

var _current_offset = 0.0


func _init() -> void:
	display_name = "Create Along Edge (Continuous)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	use_edge_data = true

	documentation.add_paragraph(
		"Create new transforms along the edges of the Scatter shapes. These
		transforms are placed so they touch each other but don't overlap, even
		if the curve has sharp turns."
	)
	documentation.add_paragraph(
		"This is useful to place props suchs as fences, walls or anything that
		needs to look organized without leaving gaps."
	)
	documentation.add_warning(
		"The transforms are placed starting from the begining of each curves.
		If the curve is closed, there will be a gap at the end if the total
		curve length isn't a multiple of the item length."
	)
	documentation.add_parameter(
		"Item length",
		"How long is the item being placed",
		1,
		"The smaller this value, the more transforms will be created.
		Setting a slightly different length than the actual model length
		allow for gaps between each transforms.",
		0
	)
	documentation.add_parameter(
		"Ignore slopes",
		"If enabled, all the curves will be projected to the local XZ plane
		before creating the new transforms.",
		0
	)

# TODO: Naive approach (the bake_interval trick from v3 don't work anymore
# in godot 4.
# Here we're using a fixed step size but this could be improved by using an
# adaptative step length.
func _process_transforms(transforms, domain, _seed) -> void:
	var new_transforms: Array[Transform3D] = []
	var curves: Array[Curve3D] = domain.get_edges()

	for curve in curves:
		if not ignore_slopes:
			curve = curve.duplicate()
		else:
			curve = get_projected_curve(curve)

		var length_squared = pow(item_length, 2)
		var offset_max = curve.get_baked_length()
		var offset = 0.0
		var step = item_length / 20.0

		while offset < offset_max:
			var start := curve.sample_baked(offset)
			var end: Vector3
			var dist: float
			offset += item_length * 0.9 # Saves a few iterations, the target
				# point will never be closer than the item length, only further

			while offset < offset_max:
				offset += step
				end = curve.sample_baked(offset)
				dist = start.distance_squared_to(end)

				if dist >= length_squared:
					var t = Transform3D()
					t.origin = start + ((end - start) / 2.0)
					new_transforms.push_back(t.looking_at(end, Vector3.UP))
					break

	transforms.append(new_transforms)


func get_projected_curve(curve: Curve3D) -> Curve3D:
	var points = curve.tessellate()
	var new_curve = Curve3D.new()
	for p in points:
		p.y = 0.0
		new_curve.add_point(p)

	return new_curve

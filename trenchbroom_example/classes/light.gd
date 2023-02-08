extends OmniLight3D

# { <prop_key : [desc, default, type?]> . . . }
func _qmapbsp_get_fgd_info() -> Dictionary :
	return {
		"range" : ["The light's radius", omni_range],
		"color" : ["The light's color", light_color],
		"attenuation" : ["The light's attenuation curve", omni_attenuation],
		"energy" : ["The light's strength multiplier", light_energy],
		"specular" : ["The intensity of the specular blob in objects affected by the light", light_specular],
	}

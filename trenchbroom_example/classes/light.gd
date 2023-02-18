@tool
extends OmniLight3D

# { <prop_key : [desc, default]> . . . }
func _qmapbsp_get_fgd_info() -> Dictionary :
	return {
		"range" : ["The light's radius", omni_range],
		"color" : ["The light's color", light_color],
		"attenuation" : ["The light's attenuation curve", omni_attenuation],
		"energy" : ["The light's strength multiplier", light_energy],
		"specular" : ["The intensity of the specular blob in objects affected by the light", light_specular],
		"shadow" : ["If true, the light will cast real-time shadows", shadow_enabled],
	}

func _qmapbsp_ent_props_pre(d : Dictionary) :
	omni_range = d.get("range", omni_range)
	light_color = d.get("color", light_color)
	omni_attenuation = d.get("attenuation", omni_attenuation)
	light_energy = d.get("energy", light_energy)
	light_specular = d.get("specular", light_specular)
	shadow_enabled = d.get("shadow", shadow_enabled)

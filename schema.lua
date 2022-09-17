return {
	type = "table",
	entries = {
		glow = {
			type = "number",
			integer = true,
			range = {min = 0, max = 15},
			default = 7,
			description = "Nametag glow"
		},
		size = {
			type = "number",
			range = {min = 0},
			default = 0.25,
			description = "Nametag size (character width) in blocks. Setting this to `0` disables nametags."
		},
		step = {
			type = "number",
			range = {min = 0},
			default = 0.1,
			description = "Each `step` seconds the nametag updates. Decrease this if nametags aren't smooth enough."
		}
	}
}

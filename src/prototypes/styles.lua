data:extend(
	{
		{
			type = "sprite",
			name = "tactical-construction-button-enabled",
			filename = "__TacticalConstruction__/graphics/toggle-icon-enabled.png",
			width = 34,
			height = 34,
		},
		{
			type = "sprite",
			name = "tactical-construction-button-disabled",
			filename = "__TacticalConstruction__/graphics/toggle-icon-disabled.png",
			width = 34,
			height = 34,
		}
	}
)

local default_gui = data.raw["gui-style"].default

default_gui["tactical-construction-sprite-style"] = 
{
	type="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	width = 34,
	height = 34,
	scalable = false,
}

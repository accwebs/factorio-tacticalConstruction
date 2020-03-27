data:extend(
	{
		{
			type = "sprite",
			name = "tactical-construction-sprite-enabled",
			filename = "__TacticalConstruction__/graphics/toggle-icon-enabled.png",
			width = 34,
			height = 34,
		},
		{
			type = "sprite",
			name = "tactical-construction-sprite-disabled",
			filename = "__TacticalConstruction__/graphics/toggle-icon-disabled.png",
			width = 34,
			height = 34,
		}
	}
)

local default_gui = data.raw["gui-style"].default

default_gui["tactical-construction-button-style-disabled"] =
{
	type="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	width = 40,
	height = 40,
    scalable = false
}

default_gui["tactical-construction-button-style-enabled"] =
{
	type="button_style",
	top_padding = 0,
	right_padding = 0,
	bottom_padding = 0,
	left_padding = 0,
	width = 40,
	height = 40,
    scalable = false,
    default_graphical_set = {
        base = {
            filename = '__TacticalConstruction__/graphics/enabled-background.png',
            width = 1,
            height = 1,
            border = 4
        }
    }
}

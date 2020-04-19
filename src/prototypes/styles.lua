data:extend(
    {
        {
            type = "custom-input",
            name = "toggle-personal-roboport-priority",
            key_sequence = "ALT + F",
            consuming = "script-only"
        },
        {
            type = "shortcut",
            name = "toggle-personal-roboport-priority",
            order = "c[toggles]-a[roboport]-priority",
            action = "lua",
            localised_name = {"controls.toggle-personal-roboport-priority"},
            associated_control_input = "toggle-personal-roboport-priority",
            style = "default",
            toggleable = true,
            icon =
            {
                filename = "__TacticalConstruction__/graphics/toggle-icon.png",
                priority = "extra-high-no-scale",
                size = 32,
                scale = 0.5,
                mipmap_count = 1,
                flags = {"gui-icon"}
            }
        }
    }
)

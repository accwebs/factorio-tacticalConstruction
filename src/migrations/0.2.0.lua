local mod_gui = require("mod-gui")

for _, player in pairs(game.players) do
    local parent = mod_gui.get_frame_flow(player)
    for _, child in pairs(parent.children) do
        if child.name == "tacticalConstructionToggleButton" then
            child.destroy()
        end
    end
end

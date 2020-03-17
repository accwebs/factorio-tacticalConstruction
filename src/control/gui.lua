require("mod-gui")

local gui = {}

function gui.on_click(event)
    if event.element.name == "tacticalConstructionToggleButton" then
        if not global.tacticalConstructionToggleState[event.player_index].toggled then
            global.tacticalConstructionToggleState[event.player_index].toggled = true
        else
            global.tacticalConstructionToggleState[event.player_index].toggled = false
        end
        gui.update_all()
	end
end

function gui.build_for_player(player)
    local parent = mod_gui.get_frame_flow(player)
    if not parent.tacticalConstructionToggleButton then
        parent.add({
            type = "sprite-button",
            name = "tacticalConstructionToggleButton", 
            style = "tactical-construction-sprite-style", 
            sprite = "tactical-construction-button-disabled"}
        )
    end
end
	
function gui.update_all()
	for i,_ in pairs(game.players) do
		local player = game.players[i]
        gui.build_for_player(player)
        local parent = mod_gui.get_frame_flow(player)
        if not global.tacticalConstructionToggleState[player.index].toggled then
            parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-disabled"
        else
            parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-enabled"
        end
	end
end

function gui.register_events()
    script.on_event(defines.events.on_gui_click, gui.on_click )
end

return gui

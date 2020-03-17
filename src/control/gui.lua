require("mod-gui")

local gui = {}

function gui.on_click(event)
    if event.element.name == "tacticalConstructionToggleButton" then
        local player = game.players[event.player_index]
        gui.click_callback(player)
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
        if player.connected == true then
            gui.build_for_player(player)
            local parent = mod_gui.get_frame_flow(player)
            if not global.tacticalConstructionState[player.index].toggled then
                parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-disabled"
            else
                parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-enabled"
            end
        end
	end
end

function gui.register_events(click_callback)
    script.on_event(defines.events.on_gui_click, gui.on_click )
    gui.click_callback = click_callback
end

return gui

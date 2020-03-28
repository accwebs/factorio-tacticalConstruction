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
    local exists = false
    for _, child in pairs(parent.children) do
        if child.name == "tacticalConstructionToggleButton" then
            exists = true
        end
    end
    if exists == false then
        parent.add({
            type = "sprite-button",
            name = "tacticalConstructionToggleButton",
            style = "tactical-construction-button-style-disabled",
            sprite = "tactical-construction-sprite-disabled"}
        )
    end
end

function gui.update_all()
    for i,_ in pairs(game.players) do
        local player = game.players[i]
        if player.connected == true then
            gui.build_for_player(player)
            local parent = mod_gui.get_frame_flow(player)
            if global.tc_player_state[player.index] then
                if not global.tc_player_state[player.index].toggled then
                    parent.tacticalConstructionToggleButton.sprite = "tactical-construction-sprite-disabled"
                    parent.tacticalConstructionToggleButton.style = "tactical-construction-button-style-disabled"
                else
                    parent.tacticalConstructionToggleButton.sprite = "tactical-construction-sprite-enabled"
                    parent.tacticalConstructionToggleButton.style = "tactical-construction-button-style-enabled"
                end
            end
        end
    end
end

function gui.register_events(click_callback)
    script.on_event(defines.events.on_gui_click, gui.on_click )
    gui.click_callback = click_callback
end

return gui

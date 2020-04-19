local gui = {}

gui.TOGGLE_BUTTON_PROTOTYPE_NAME = "toggle-personal-roboport-priority"

function gui.on_lua_shortcut(event)
    if event.prototype_name == gui.TOGGLE_BUTTON_PROTOTYPE_NAME then
        local player = game.players[event.player_index]
        gui.toggle_callback(player)
        gui.update_all()
    end
end

function gui.on_hot_key(event)
    local player = game.players[event.player_index]
    gui.toggle_callback(player)
    gui.update_all()
end

function gui.update_all()
    for i,_ in pairs(game.players) do
        local player = game.players[i]
        if player.connected == true then
            if global.tc_player_state[player.index] then
                player.set_shortcut_toggled(gui.TOGGLE_BUTTON_PROTOTYPE_NAME, global.tc_player_state[player.index].toggled)
            end
        end
    end
end

function gui.register_events(toggle_callback)
    script.on_event(defines.events.on_lua_shortcut, gui.on_lua_shortcut)  -- handles GUI click
    script.on_event("toggle-personal-roboport-priority", gui.on_hot_key)  -- handles hot key
    gui.toggle_callback = toggle_callback
end

return gui

local gui = {}

local mod_gui = require("mod-gui")

gui.TOGGLE_BUTTON_PROTOTYPE_NAME = "toggle-personal-roboport-priority"
gui.GLOBAL_DISABLE_BUTTON_NAME = "tacticalConstructionGlobalDisableButton"

function gui.on_lua_shortcut(event)
    if global.globally_disabled then
        return
    end
    if event.prototype_name == gui.TOGGLE_BUTTON_PROTOTYPE_NAME then
        local player = game.players[event.player_index]
        gui.toggle_callback(player)
        gui.update_all()
    end
end

function gui.on_hot_key(event)
    if global.globally_disabled then
        return
    end
    local player = game.players[event.player_index]
    gui.toggle_callback(player)
    gui.update_all()
end

function gui.on_global_disable_button_click(event)
    if global.globally_disabled then
        return
    end
    if event.element.name == gui.GLOBAL_DISABLE_BUTTON_NAME then
        local player = game.players[event.player_index]
        gui.perform_global_disable(player)
    end
end

function gui.on_mod_setting_changed(event)
    if global.globally_disabled then
        return
    end
    gui.update_all()
end

function gui.update_all()
    local show_global_disable_button = settings.global["tactical-construction-show-global-disable-button"].value

    for i,_ in pairs(game.players) do
        local player = game.players[i]
        if player.connected == true then
            if global.tc_player_state[player.index] then
                player.set_shortcut_toggled(gui.TOGGLE_BUTTON_PROTOTYPE_NAME, global.tc_player_state[player.index].toggled)
            end
        end

        local mod_gui_container = mod_gui.get_frame_flow(player)
        if show_global_disable_button then
            local exists = false
            for _, child in pairs(mod_gui_container.children) do
                if child.name == gui.GLOBAL_DISABLE_BUTTON_NAME then
                    exists = true
                end
            end
            if exists == false then
                mod_gui_container.add({
                    type = "button",
                    name = gui.GLOBAL_DISABLE_BUTTON_NAME,
                    caption={"disable.global-disable-button-text"},
                    tooltip={"disable.global-disable-button-tooltip"}
                })
            end
        else
            for _, child in pairs(mod_gui_container.children) do
                if child.name == gui.GLOBAL_DISABLE_BUTTON_NAME then
                    child.destroy()
                end
            end
        end
    end
end

function gui.register_events(toggle_callback, perform_global_disable)
    script.on_event(defines.events.on_lua_shortcut, gui.on_lua_shortcut)  -- handles GUI click
    script.on_event("toggle-personal-roboport-priority", gui.on_hot_key)  -- handles hot key
    script.on_event(defines.events.on_gui_click, gui.on_global_disable_button_click)  -- global 'clean up tactical construction mod' button click

    script.on_event(defines.events.on_runtime_mod_setting_changed, gui.on_mod_setting_changed)  -- so we can show/hide the global 'clean up' button
    gui.toggle_callback = toggle_callback
    gui.perform_global_disable = perform_global_disable
end

return gui

local force_manager = require("control.force_manager")
local gui = require("control.gui")

local function init_player(player)
    if not global.tacticalConstructionToggleState then
        global.tacticalConstructionToggleState = {}
    end
    if global.tacticalConstructionToggleState[player.index] == nil then
        global.tacticalConstructionToggleState[player.index] = {
            toggled = false
        }
    end
    gui.build_for_player(player)
end

local function init_players()
	for _, player in pairs(game.players) do
		init_player(player)
	end
end

local function clean_up_old_state()
    for player_index, entry in pairs(global.tacticalConstructionToggleState) do
        if entry.toggled == true then
            local player = game.players[player_index]
            force_manager.destroy_for_player(player)
            global.tacticalConstructionToggleState[player.index].toggled = false
        end
    end
end

local function on_init() 
    init_players()
end

local function on_player_created_or_joined(event)
	init_player(game.players[event.player_index])
end

local function on_toggle(player)
    if not global.tacticalConstructionToggleState[player.index].toggled then
        global.tacticalConstructionToggleState[player.index].toggled = true
        local created_force = force_manager.create_for_player(player)
        player.force = created_force
    else
        global.tacticalConstructionToggleState[player.index].toggled = false
        force_manager.destroy_for_player(player)
    end
end

script.on_init(on_init)
script.on_configuration_changed(clean_up_old_state)
script.on_event(defines.events.on_player_created, on_player_created_or_joined )
script.on_event(defines.events.on_player_joined_game, on_player_created_or_joined )
force_manager.register_events()
gui.register_events(on_toggle)

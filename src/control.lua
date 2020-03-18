local entity_manager = require("control.entity_manager")
local force_manager = require("control.force_manager")
local gui = require("control.gui")

local function init_player(player)
    if not global.tacticalConstructionState then
        global.tacticalConstructionState = {}
    end
    if global.tacticalConstructionState[player.index] == nil then
        global.tacticalConstructionState[player.index] = {
            toggled = false,
            lastPosition = {-1, -1}
        }
    end
    gui.build_for_player(player)
    force_manager.create_for_player(player)
end


local function deinit_player(player)
    force_manager.destroy_for_player(player)
    if global.tacticalConstructionState[player.index] ~= nil then
        global.tacticalConstructionState[player.index].toggled = false
    end
end

local function purge_stale_players()
    for _, player in pairs(game.players) do
        if player.connected ~= true then
            deinit_player(player)
        end
    end
end

local function on_player_joined(event)
    init_player(game.players[event.player_index])
    purge_stale_players()
end

local function on_player_left(event)
	purge_stale_players()
end

local function on_toggle(player)
    if not global.tacticalConstructionState[player.index].toggled then
        force_manager.switch_player_to_force(player)
        global.tacticalConstructionState[player.index].toggled = true
    else
        force_manager.restore_player_original_force(player)
        global.tacticalConstructionState[player.index].toggled = false
    end
end

script.on_event(defines.events.on_player_joined_game, on_player_joined )
script.on_event(defines.events.on_player_left_game, on_player_left )
force_manager.register_events()
entity_manager.init(force_manager)
entity_manager.register_events()
gui.register_events(on_toggle)

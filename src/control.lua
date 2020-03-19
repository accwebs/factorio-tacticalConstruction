local entity_manager = require("control.entity_manager")
local force_manager = require("control.force_manager")
local gui = require("control.gui")

local function on_mod_init()
    global.tc_debug = true
    if global.tc_debug == true then
        global.tc_renders = {}
    end
end

local function init_player(player)
    if not global.tc_player_state then
        global.tc_player_state = {}
    end
    if global.tc_player_state[player.index] == nil then
        global.tc_player_state[player.index] = {
            toggled = false,
            dirty = 0,
            last_surface_index = -1,
            last_position = {-1, -1},
            last_construction_radius = 0
        }
    end
    gui.build_for_player(player)
    force_manager.init_player(player)
end

local function deinit_player(player)
    force_manager.deinit_player(player)
    if global.tc_player_state[player.index] ~= nil then
        global.tc_player_state[player.index].toggled = false
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
    if not global.tc_player_state[player.index].toggled then
        force_manager.switch_player_to_alternative_force(player)
        global.tc_player_state[player.index].toggled = true
        entity_manager.on_toggle(player, true)
    else
        force_manager.restore_player_original_force(player)
        global.tc_player_state[player.index].toggled = false
        entity_manager.on_toggle(player, false)
    end
end

script.on_init(on_mod_init)
script.on_event(defines.events.on_player_joined_game, on_player_joined)
script.on_event(defines.events.on_player_left_game, on_player_left)
force_manager.register_events()
entity_manager.init(force_manager)
entity_manager.register_events()
gui.register_events(on_toggle)

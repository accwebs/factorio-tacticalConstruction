local entity_manager = require("control.entity_manager")
local force_manager = require("control.force_manager")
local gui = require("control.gui")

local function init_player(player)
    if not global.tc_player_state then
        global.tc_player_state = {}
    end
    if global.tc_player_state[player.index] == nil then
        global.tc_player_state[player.index] = {
            toggled = false,
            dirty = 0,
            last_surface_index = -1,
            last_bounding_box = {{-1, -1}, {-1, -1}}
        }
    end
    gui.build_for_player(player)

    -- this call creates the alternative force for this player if it doesn't already exist
    force_manager.fetch_alternative_force(player.force)
end

local function revert_what_we_can(base_force, alternative_force)
    local safe_to_revert_all_entities = true
    for _, player in pairs(game.players) do
        if player.connected then
            if player.force.name == alternative_force.name then
                safe_to_revert_all_entities = false
            end
        end
    end
    if safe_to_revert_all_entities then
        entity_manager.find_and_revert_all_entities(base_force, alternative_force)
    else
        entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)
    end
end

local function reset_player(player)
    if global.tc_player_state[player.index] ~= nil then
        if global.tc_player_state[player.index].toggled then
            global.tc_player_state[player.index].toggled = false
            gui.update_all()
            local base_force = force_manager.fetch_base_force(player.force)
            local alternative_force = force_manager.fetch_alternative_force(player.force)
            revert_what_we_can(base_force, alternative_force)
        end
    end
end

local function reset_stale_players()
    for _, player in pairs(game.players) do
        if player.connected ~= true then
            reset_player(player)
        end
    end
end

local function on_mod_init()
    global.tc_debug = false
    if global.tc_debug == true then
        global.tc_renders = {}
    end
    for _, player in pairs(game.players) do
        init_player(player)
    end
end

local function on_player_joined(event)
    init_player(game.players[event.player_index])
end

local function on_player_left(event)
    reset_player(game.players[event.player_index])
end

local function on_research_finished(event)
    force_manager.notify_research_finished(event)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player.force)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player.force)
    entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)
    entity_manager.find_and_convert_player_range_construction_entities(player, base_force, alternative_force)
end

local function on_player_changed_force(event)
    local player = game.players[event.player_index]
    local new_force = player.force
    local old_force = event.force

    local new_base_force = force_manager.fetch_base_force(new_force)
    local new_alternative_force = force_manager.fetch_alternative_force(new_force)
    local old_base_force = force_manager.fetch_base_force(old_force)
    local old_alternative_force = force_manager.fetch_alternative_force(old_force)

    if new_base_force.name ~= old_base_force.name or new_alternative_force.name ~= old_alternative_force.name then
        revert_what_we_can(old_base_force, old_alternative_force)
        reset_player(player)
    end
end

local function on_toggle(player)
    local base_force = entity_manager.force_manager.fetch_base_force(player.force)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player.force)
    if not global.tc_player_state[player.index].toggled then
        force_manager.switch_player_to_alternative_force(player)
        global.tc_player_state[player.index].toggled = true
        entity_manager.find_and_convert_player_range_construction_entities(player, base_force, alternative_force)
    else
        force_manager.restore_player_original_force(player)
        global.tc_player_state[player.index].toggled = false
        revert_what_we_can(base_force, alternative_force)
    end
end

local function garbage_collect(event)
    reset_stale_players()
    entity_manager.garbage_collect()
    force_manager.garbage_collect()
end

script.on_init(on_mod_init)
script.on_event(defines.events.on_player_joined_game, on_player_joined)
script.on_event(defines.events.on_player_left_game, on_player_left)
script.on_event(defines.events.on_research_finished, on_research_finished)
script.on_event(defines.events.on_player_changed_position, on_player_changed_position)
script.on_event(defines.events.on_player_changed_force, on_player_changed_force)
script.on_nth_tick(7200, garbage_collect)
entity_manager.init(force_manager)
gui.register_events(on_toggle)

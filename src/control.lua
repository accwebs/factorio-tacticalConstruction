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
    gui.update_all()

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
            force_manager.restore_player_original_force(player)
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
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        global.tc_player_state = {}
    end
    global.globally_disabled = false
    global.tc_debug = false
    global.recreate_forces = false
    global.current_mod_state_version = 2
    if global.tc_debug == true then
        global.tc_renders = {}
    end
    for _, player in pairs(game.players) do
        if player.connected == true then
            init_player(player)
        end
    end
end

local function on_player_joined(event)
    if global.globally_disabled then
        return
    end
    init_player(game.players[event.player_index])
end

local function on_player_left(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    reset_player(game.players[event.player_index])
end

local function on_research_started(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        return
    end
    force_manager.notify_research_started(event)
end

local function on_research_finished(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state then
        return
    end
    force_manager.notify_research_finished(event)
end

local function on_player_changed_position(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player.force)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player.force)
    entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)
    entity_manager.find_and_convert_player_range_construction_entities(player, base_force, alternative_force)
end

local function on_player_changed_force(event)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
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

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function on_toggle(player)
    if global.globally_disabled then
        return
    end
    if not global.tc_player_state or not global.tc_player_state[player.index] or not player.character then
        return
    end

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

local function on_global_disable(player)
    if global.globally_disabled then
        return
    end

    if not player.admin then
        player.print({"disable.global-disable-you-not-admin"})
        return
    end
    player.print({"disable.global-disable-starting"})

    for _, player in pairs(game.players) do
        reset_player(player)
    end
    entity_manager.garbage_collect()
    force_manager.garbage_collect(true)
    global.globally_disabled = true

    for _, player in pairs(game.players) do
        if player.connected == true then
            player.print({"disable.global-disable-complete", player.name})
        end
    end
end

local function garbage_collect(event)
    if global.globally_disabled then
        return
    end
    -- if a mod version upgrade has signaled that our alternative forces are somehow in a bad state and need re-creating, do that now as part of GC
    if global.recreate_forces == true then
        for _, player in pairs(game.players) do
            reset_player(player)
        end
        entity_manager.garbage_collect()
        force_manager.garbage_collect(true)
        for _, player in pairs(game.players) do
            if player.connected == true then
                init_player(player)
            end
        end
        global.recreate_forces = false
    else
        reset_stale_players()
        entity_manager.garbage_collect()
        force_manager.garbage_collect(false)
    end
end

script.on_init(on_mod_init)
script.on_event(defines.events.on_player_joined_game, on_player_joined)
script.on_event(defines.events.on_player_left_game, on_player_left)
script.on_event(defines.events.on_research_started, on_research_started)
script.on_event(defines.events.on_research_finished, on_research_finished)
script.on_event(defines.events.on_player_changed_position, on_player_changed_position)
script.on_event(defines.events.on_player_changed_force, on_player_changed_force)
script.on_event(defines.events.on_pre_player_died, on_player_left)
script.on_nth_tick(7200, garbage_collect) -- every 2 minutes-ish
entity_manager.init(force_manager)
gui.register_events(on_toggle, on_global_disable)

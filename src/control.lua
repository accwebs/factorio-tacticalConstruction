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
    global.tc_debug = false
    global.to_be_deconstructed_filter_supported = false
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
    if not global.tc_player_state or not global.tc_player_state[event.player_index] then
        return
    end
    reset_player(game.players[event.player_index])
end

local function on_research_finished(event)
    if not global.tc_player_state then
        return
    end
    force_manager.notify_research_finished(event)
end

local function on_player_changed_position(event)
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
    if not global.tc_player_state or not global.tc_player_state[player.index] or not player.character then
        return
    end

    -- determine whether the new to_be_constructed entity search filter is expected to work and save that info
    local base_mod_version = game.active_mods["base"]
    if not base_mod_version then
        base_mod_version = ""
    end
    local expected_prefix = "0.18."
    -- not starting with 0.18. so we just assume the new entity search filter is supported because what is this version?
    if starts_with(base_mod_version, expected_prefix) == false then
        global.to_be_deconstructed_filter_supported = true
    else
        -- extract the 'patch' version number as a string
        local remaining_version_str = string.sub(base_mod_version, #expected_prefix+1)
        -- make sure what we extracted doesn't have any more dots. It shouldn't but just in case version format changes later...
        --   If this is something we don't understand, just assume the new entity search filter works
        if string.find(remaining_version_str, "%.") or #remaining_version_str == 0 then
            global.to_be_deconstructed_filter_supported = true
        else
            -- if version >= 0.18.21, then new filter works
            if tonumber(remaining_version_str) >= 21 then
                global.to_be_deconstructed_filter_supported = true
            else
                global.to_be_deconstructed_filter_supported = false
            end
        end
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
script.on_event(defines.events.on_pre_player_died, on_player_left)
script.on_nth_tick(7200, garbage_collect) -- every 2 minutes-ish
entity_manager.init(force_manager)
gui.register_events(on_toggle)

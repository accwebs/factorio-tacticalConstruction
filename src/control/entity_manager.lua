local entity_manager = {}

function entity_manager.array_is_empty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function entity_manager.mark_entity(entity)
    if entity.unit_number ~= nil then
        local render_id = rendering.draw_circle({
            color={1,0,0},
            radius=0.25,
            filled=true,
            target=entity,
            surface=entity.surface
        })
        global.tc_renders[entity.unit_number] = render_id
    end
end

function entity_manager.unmark_entity(entity)
    if entity.unit_number ~= nil then
        local render_id = global.tc_renders[entity.unit_number]
        if render_id ~= nil then
            rendering.destroy(render_id)
        end
    end

    -- search for and delete any dangling references
    for render_key, render_id in pairs(global.tc_renders) do
        if rendering.is_valid(render_id) == false then
            global.tc_renders[render_key] = nil
        end
    end
end

function entity_manager.set_entity_alternative_force(entity)
    entity_manager.force_manager.set_entity_alternative_force(entity)
    if global.tc_debug == true then
        entity_manager.mark_entity(entity)
    end
end

function entity_manager.restore_entity_original_force(entity)
    if global.tc_debug == true then
        entity_manager.unmark_entity(entity)
    end
    entity_manager.force_manager.restore_entity_original_force(entity)
end

function entity_manager.determine_whether_to_revert_entity(entity, surface, alternative_force, skip_still_in_range)
    local how_dirty_after = 0
    if skip_still_in_range == true then
        local networks_in_range = surface.find_logistic_networks_by_construction_area(entity.position, alternative_force)
        if entity_manager.array_is_empty(networks_in_range) == true then
            entity_manager.restore_entity_original_force(entity)
        else
            local player_owned_in_range = false
            for _, network in pairs(networks_in_range) do
                for _, player in pairs(game.players) do
                    if player.connected == true then
                        if player.character ~= nil then
                            if entity_manager.force_manager.is_logistic_network_player_owned(player, network) then
                                player_owned_in_range = true
                                break
                            end
                        end
                    end
                end
            end
            if player_owned_in_range then
                how_dirty_after = 1
            else
                entity_manager.restore_entity_original_force(entity)
            end
        end
    else
        entity_manager.restore_entity_original_force(entity)
    end
    return how_dirty_after
end

function entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
    for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered({
            force=alternative_force
        })
        for _, entity in pairs(entities) do
            entity_manager.determine_whether_to_revert_entity(entity, surface, alternative_force, true)
        end
    end
end

function entity_manager.find_and_revert_player_range_entities(base_force, alternative_force, skip_still_in_range)
    for player_index, player_state in pairs(global.tc_player_state) do
        if player_state.dirty > 0 then
            local how_dirty_after = 0
            local surface = game.surfaces[player_state.last_surface_index]
            if surface ~= nil then
                local entities = surface.find_entities_filtered({
                    area=last_bounding_box,
                    force=alternative_force
                })
                for _, entity in pairs(entities) do
                    local temp_dirty_result = entity_manager.determine_whether_to_revert_entity(entity, surface, alternative_force, skip_still_in_range)
                    if temp_dirty_result > how_dirty_after then
                        how_dirty_after = temp_dirty_result
                    end
                end
            end
            player_state.dirty = how_dirty_after
        end
    end
end

function entity_manager.on_player_changed_position(event)
    local player = game.players[event.player_index]
    entity_manager.on_player_changed_position_player(player)
end

function entity_manager.on_built_entity(event)
    if global.tc_debug == true then
        if entity_manager.force_manager.is_force_alternative(event.created_entity.force) then
            entity_manager.mark_entity(event.created_entity)
        end
    end
end

function entity_manager.on_player_changed_position_player(player)
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    local character = player.character

    entity_manager.find_and_revert_player_range_entities(base_force, alternative_force, true)

    if player.force == alternative_force then
        if character.logistic_cell ~= nil then
            if global.tc_player_state[player.index].dirty < 2 then
                local construction_radius = character.logistic_cell.construction_radius
                local bounding_box = {
                    {
                        player.position.x - construction_radius,
                        player.position.y - construction_radius
                    },
                    {
                        player.position.x + construction_radius,
                        player.position.y + construction_radius
                    }
                }

                local entities = player.surface.find_entities_filtered({
                    area=bounding_box,
                    type="entity-ghost",
                    force=base_force
                })
                for _, entity in pairs(entities) do
                    entity_manager.set_entity_alternative_force(entity)
                end

                local entities = player.surface.find_entities_filtered({
                    area=bounding_box,
                    type="tile-ghost",
                    force=base_force
                })
                for _, entity in pairs(entities) do
                    entity_manager.set_entity_alternative_force(entity)
                end

                global.tc_player_state[player.index].dirty = 2
                global.tc_player_state[player.index].last_surface_index = player.surface.index
                global.tc_player_state[player.index].last_bounding_box = bounding_box
            end
        end
    end
end

function entity_manager.on_player_left_game(event)
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    entity_manager.find_and_revert_player_range_entities(base_force, alternative_force, false)
    entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
end

function entity_manager.on_toggle(player, new_state)
    if new_state == true then
        entity_manager.on_player_changed_position_player(player)
    else
        local base_force = entity_manager.force_manager.fetch_base_force(player)
        local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
        entity_manager.find_and_revert_player_range_entities(base_force, alternative_force, false)
        entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
    end
end

function entity_manager.register_events()
    script.on_event(defines.events.on_player_changed_position, entity_manager.on_player_changed_position)
    script.on_event(defines.events.on_player_left_game, entity_manager.on_player_left_game)
    script.on_event(defines.events.on_built_entity, entity_manager.on_built_entity)
    script.on_event(defines.events.on_robot_built_entity, entity_manager.on_built_entity)
end

function entity_manager.init(force_manager)
    entity_manager.force_manager = force_manager
end

return entity_manager

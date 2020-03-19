local entity_manager = {}

function entity_manager.array_is_empty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function entity_manager.find_and_revert_entities(base_force, alternative_force, skip_still_in_range)
    for player_index, player_state in pairs(global.tacticalConstructionState) do
        if player_state.dirty > 0 then
            local how_dirty_after = 0
            local surface = game.surfaces[player_state.last_surface_index]
            if surface ~= nil then
                local entities = surface.find_entities_filtered({
                    position=player_state.last_position,
                    radius=player_state.last_construction_radius,
                    force=alternative_force
                })
                for _, entity in pairs(entities) do
                    if skip_still_in_range == true then
                        local networks_in_range = surface.find_logistic_networks_by_construction_area(entity.position, alternative_force)
                        if entity_manager.array_is_empty(networks_in_range) == true then
                            entity_manager.force_manager.restore_entity_original_force(entity)
                        else
                            how_dirty_after = 1
                        end
                    else
                        entity_manager.force_manager.restore_entity_original_force(entity)
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

function entity_manager.on_player_changed_position_player(player)
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    local character = player.character

    entity_manager.find_and_revert_entities(base_force, alternative_force, true)

    if player.force == alternative_force then
        if character.logistic_cell ~= nil then
            if global.tacticalConstructionState[player.index].dirty < 2 then
                local construction_radius = character.logistic_cell.construction_radius

                local entities = player.surface.find_entities_filtered({
                    position=player.position,
                    radius=construction_radius,
                    type="entity-ghost",
                    force=base_force
                })
                for _, entity in pairs(entities) do
                    entity_manager.force_manager.set_entity_alternative_force(entity)
                end
                -- local entities = player.surface.find_entities_filtered({
                --     position=player.position,
                --     radius=construction_radius,
                --     type="entity-ghost",
                --     force=alternative_force
                -- })
                -- for _, entity in pairs(entities) do
                --     entity_manager.force_manager.set_entity_alternative_force(entity)
                -- end

                local entities = player.surface.find_entities_filtered({
                    position=player.position,
                    radius=construction_radius,
                    type="tile-ghost",
                    force=base_force
                })
                for _, entity in pairs(entities) do
                    entity_manager.force_manager.set_entity_alternative_force(entity)
                end
                -- local entities = player.surface.find_entities_filtered({
                --     position=player.position,
                --     radius=construction_radius,
                --     type="tile-ghost",
                --     force=alternative_force
                -- })
                -- for _, entity in pairs(entities) do
                --     entity_manager.force_manager.set_entity_alternative_force(entity)
                -- end

                global.tacticalConstructionState[player.index].dirty = 2
                global.tacticalConstructionState[player.index].last_surface_index = player.surface.index
                global.tacticalConstructionState[player.index].last_position = player.position
                global.tacticalConstructionState[player.index].last_construction_radius = construction_radius
            end
        end
    end
end

function entity_manager.on_player_left_game(event)
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    entity_manager.find_and_revert_entities(base_force, alternative_force, false)
end

function entity_manager.on_toggle(player, new_state)
    if new_state == true then
        entity_manager.on_player_changed_position_player(player)
    else
        local base_force = entity_manager.force_manager.fetch_base_force(player)
        local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
        entity_manager.find_and_revert_entities(base_force, alternative_force, false)
    end
end

function entity_manager.register_events()
    script.on_event(defines.events.on_player_changed_position, entity_manager.on_player_changed_position)
    script.on_event(defines.events.on_player_left_game, entity_manager.on_player_left_game)
end

function entity_manager.init(force_manager)
    entity_manager.force_manager = force_manager
end

return entity_manager

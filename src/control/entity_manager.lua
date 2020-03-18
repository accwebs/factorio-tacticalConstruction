local entity_manager = {}

function entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
    -- local surface = player.surface
    -- local entities = surface.find_entities_filtered({
    --     position=old_position, 
    --     radius=logistic_cell.construction_radius, 
    --     type="entity-ghost", 
    --     force=player.force
    -- })
    -- for _, entity in pairs(entities) do
    --     if logistic_cell.is_in_construction_range(entity.position) == false then
    --         entity_manager.force_manager.restore_entity_base_force(entity)
    --     end
    -- end
end

function entity_manager.on_player_changed_position(event)
    local player = game.players[event.player_index]
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    local character = player.character

    entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
    
    if player.force == alternative_force then
        if character.logistic_cell ~= nil then
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

            local entities = player.surface.find_entities_filtered({
                position=player.position,
                radius=construction_radius,
                type="tile-ghost", 
                force=base_force
            })
            for _, entity in pairs(entities) do
                entity_manager.force_manager.set_entity_alternative_force(entity)
            end
        end
    end

    global.tacticalConstructionState[player.index].last_surface_index = player.surface
    global.tacticalConstructionState[player.index].last_position = player.position
    global.tacticalConstructionState[player.index].last_construction_radius = construction_radius
end

function entity_manager.register_events()
    script.on_event(defines.events.on_player_changed_position, entity_manager.on_player_changed_position)
end

function entity_manager.init(force_manager)
    entity_manager.force_manager = force_manager
end

return entity_manager

local entity_manager = {}

function entity_manager.find_and_revert_out_of_range_entities(player, old_position, logistic_cell)
    local surface = player.surface
    local entities = surface.find_entities_filtered({
        position=old_position, 
        radius=logistic_cell.construction_radius, 
        type="entity-ghost", 
        force=player.force
    })
    for _, entity in pairs(entities) do
        if logistic_cell.is_in_construction_range(entity.position) == false then
            entity_manager.force_manager.restore_entity_base_force(entity)
        end
    end
end

function entity_manager.on_player_changed_position(event)
    local player = game.players[event.player_index]
    if global.tacticalConstructionState[player.index].toggled == true then
        local character = player.character
        if character.logistic_cell ~= nil then
            local construction_radius = character.logistic_cell.construction_radius
            




             -- entity-ghost knows items_to_place_this and item_requests (modules)
      local entities = cell.owner.surface.find_entities_filtered{area=bounds, limit=result_limit, type="entity-ghost", force=logsiticNetwork.force}
      local count_unique_entities = 0
      for _, e in pairs(entities) do
        local uid = e.unit_number
        if not found_entities[uid] then
          found_entities[uid] = true
          if is_in_bbox(e.position, bounds) then
            for _, item_stack in pairs(
              global.Lookup_items_to_place_this[e.ghost_name] or
              get_items_to_place(e.ghost_prototype)
            ) do
              add_signal(item_stack.name, item_stack.count)
              count_unique_entities = count_unique_entities + item_stack.count
            end

            for request_item, count in pairs(e.item_requests) do
              add_signal(request_item, count)
              count_unique_entities = count_unique_entities + count
            end
          end
        end
      end
      -- log("found "..tostring(count_unique_entities).."/"..tostring(result_limit).." ghosts." )
      if MaxResults then
        result_limit = result_limit - count_unique_entities
        if result_limit <= 0 then break end
      end


       -- tile-ghost knows only items_to_place_this
       local entities = cell.owner.surface.find_entities_filtered{area=bounds, limit=result_limit, type="tile-ghost", force=logsiticNetwork.force}
       local count_unique_entities = 0
       for _, e in pairs(entities) do
         local uid = e.unit_number
         if not found_entities[uid] then
           found_entities[uid] = true
           if is_in_bbox(e.position, bounds) then
             for _, item_stack in pairs(
               global.Lookup_items_to_place_this[e.ghost_name] or
               get_items_to_place(e.ghost_prototype)
             ) do
               add_signal(item_stack.name, item_stack.count)
               count_unique_entities = count_unique_entities + item_stack.count
             end
           end
         end
       end
       -- log("found "..tostring(count_unique_entities).."/"..tostring(result_limit).." tile-ghosts." )
       if MaxResults then
         result_limit = result_limit - count_unique_entities
         if result_limit <= 0 then break end
       end
 

        end
    end
end

function entity_manager.register_events()
    script.on_event(defines.events.on_player_changed_position, entity_manager.on_player_changed_position)
end

function init(force_manager)
    entity_manager.force_manager = force_manager
end

return entity_manager

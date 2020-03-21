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

function entity_manager.revert_entity_if_not_in_player_range(entity, surface, alternative_force)
    local how_dirty_after = 0
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
    return how_dirty_after
end

-- function entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
--     for _, surface in pairs(game.surfaces) do
--         local entities = surface.find_entities_filtered({
--             force=alternative_force
--         })
--         for _, entity in pairs(entities) do
--             entity_manager.determine_whether_to_revert_entity(entity, surface, alternative_force, true)
--         end
--     end
-- end

function entity_manager.subtract_rect_compute_top(rect, subtracted)
    return {
        left_top={
            x=rect.left_top.x,
            y=rect.left_top.y,
        },
        right_bottom={
            x=rect.right_bottom.x,
            y=rect.left_top.y + math.max(subtracted.left_top.y-rect.left_top.y, 0)
        }
    }
end

function entity_manager.subtract_rect_compute_left(rect, subtracted)
    return {
        left_top={
            x=rect.left_top.x,
            y=subtracted.left_top.y,
        },
        right_bottom={
            x=rect.left_top.x + math.max(subtracted.left_top.x-rect.left_top.x, 0),
            y=subtracted.right_bottom.y
        }
    }
end

function entity_manager.subtract_rect_compute_right(rect, subtracted)
    return {
        left_top={
            x=subtracted.right_bottom.x,
            y=subtracted.left_top.y,
        },
        right_bottom={
            x=subtracted.right_bottom.x + math.max(rect.right_bottom.x-subtracted.right_bottom.x, 0),
            y=subtracted.right_bottom.y
        }
    }
end

function entity_manager.subtract_rect_compute_bottom(rect, subtracted)
    return {
        left_top={
            x=rect.left_top.x,
            y=subtracted.right_bottom.y,
        },
        right_bottom={
            x=rect.right_bottom.x,
            y=subtracted.right_bottom.y + math.max(rect.right_bottom.y - subtracted.right_bottom.y, 0)
        }
    }
end

function entity_manager.subtract_rect_has_no_area(rect)
    if ((rect.right_bottom.x - rect.left_top.x) <= 0 or (rect.right_bottom.y - rect.left_top.y) <= 0) then
        return true
    else
        return false
    end
end

function entity_manager.subtract_bounding_box_from_boxes(source_boxes, box_to_subtract)
    local output_boxes = {}
    for _, source_box in pairs(source_boxes) do
        if (box_to_subtract.right_bottom.x <= source_box.left_top.x or          -- subtr box's right is entirely to left of source left
                box_to_subtract.right_bottom.y <= source_box.left_top.y or      -- subtr box's bottom is entirely above source top
                box_to_subtract.left_top.x >= source_box.right_bottom.x or      -- subtr box's left is entirely to right of source right
                box_to_subtract.left_top.y >= source_box.right_bottom.y) then   -- subtr box's top is entirely below source bottom
            output_boxes[#output_boxes+1] = source_box  -- no overlap at all
        else
            local top_rect = entity_manager.subtract_rect_compute_top(source_box, box_to_subtract);
            if entity_manager.subtract_rect_has_no_area(top_rect) == false then
                output_boxes[#output_boxes+1] = top_rect
            end
            local left_rect = entity_manager.subtract_rect_compute_left(source_box, box_to_subtract);
            if entity_manager.subtract_rect_has_no_area(left_rect) == false then
                output_boxes[#output_boxes+1] = left_rect
            end
            local right_rect = entity_manager.subtract_rect_compute_right(source_box, box_to_subtract);
            if entity_manager.subtract_rect_has_no_area(right_rect) == false then
                output_boxes[#output_boxes+1] = right_rect
            end
            local bottom_rect = entity_manager.subtract_rect_compute_bottom(source_box, box_to_subtract);
            if entity_manager.subtract_rect_has_no_area(bottom_rect) == false then
                output_boxes[#output_boxes+1] = bottom_rect
            end
        end
    end
    return output_boxes
end

function entity_manager.subtract_current_player_ranges(alternative_force, last_bounding_box)
    local remaining_bounding_boxes = {}
    remaining_bounding_boxes[1] = last_bounding_box
    for _, player in pairs(game.players) do
        if player.connected == true then
            if player.character ~= nil then
                if player.force == alternative_force then
                    if player.character.logistic_cell ~= nil then
                        local player_construction_radius = player.character.logistic_cell.construction_radius
                        local player_bounding_box = entity_manager.create_player_bounding_box(player.position, player_construction_radius)
                        remaining_bounding_boxes = entity_manager.subtract_bounding_box_from_boxes(remaining_bounding_boxes, player_bounding_box)
                    end
                end
            end
        end
    end
    return remaining_bounding_boxes
end

function entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, skip_still_in_range)
    for player_index, player_state in pairs(global.tc_player_state) do
        if player_state.dirty > 0 then
            local how_dirty_after = 0
            local surface = game.surfaces[player_state.last_surface_index]
            if surface ~= nil then
                if skip_still_in_range == false then
                    local entities = surface.find_entities_filtered({
                        area=player_state.last_bounding_box,
                        force=alternative_force
                    })
                    for _, entity in pairs(entities) do
                        entity_manager.restore_entity_original_force(entity)
                    end
                    how_dirty_after = 0
                else
                    local rectangles_to_search = entity_manager.subtract_current_player_ranges(alternative_force, player_state.last_bounding_box)
                    for _, rectangle_to_search in pairs(rectangles_to_search) do
                        local entities = surface.find_entities_filtered({
                            area=rectangle_to_search,
                            force=alternative_force
                        })
                        for _, entity in pairs(entities) do
                            local temp_dirty_result = entity_manager.revert_entity_if_not_in_player_range(entity, surface, alternative_force)
                            if temp_dirty_result > how_dirty_after then
                                how_dirty_after = temp_dirty_result
                            end
                        end
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

function entity_manager.create_player_bounding_box(position, construction_radius)
    return {
        left_top={
            x=position.x - construction_radius,
            y=position.y - construction_radius
        },
        right_bottom={
            x=position.x + construction_radius,
            y=position.y + construction_radius
        }
    }
end

function entity_manager.on_player_changed_position_player(player)
    local base_force = entity_manager.force_manager.fetch_base_force(player)
    local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
    local character = player.character

    entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, true)

    if player.force == alternative_force then
        if character.logistic_cell ~= nil then
            if global.tc_player_state[player.index].dirty < 2 then
                local construction_radius = character.logistic_cell.construction_radius
                local bounding_box = entity_manager.create_player_bounding_box(player.position, construction_radius)

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
    entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, false)
    --entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
end

function entity_manager.on_toggle(player, new_state)
    if new_state == true then
        entity_manager.on_player_changed_position_player(player)
    else
        local base_force = entity_manager.force_manager.fetch_base_force(player)
        local alternative_force = entity_manager.force_manager.fetch_alternative_force(player)
        entity_manager.find_and_revert_previous_player_range_entities(base_force, alternative_force, false)
        --entity_manager.find_and_revert_out_of_range_entities(base_force, alternative_force)
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

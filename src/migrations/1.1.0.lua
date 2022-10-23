global.luaforce_color_apis_present = false
for key, value in pairs(global.tc_player_state) do
    value.color = {r = 0.0, g = 0.0, b = 0.0, a = 0.0}
end

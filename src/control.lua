local traincam = require("scripts.traincam")

script.on_init(function()
  storage.traincam_players = storage.traincam_players or {}
end)

script.on_configuration_changed(function()
  storage.traincam_players = storage.traincam_players or {}

  if storage.traincam_player_state then
    storage.traincam_player_state = nil
    storage.traincam_target_entity = nil
    storage.traincam_x = nil
    storage.traincam_y = nil
  end
end)

script.on_event(defines.events.on_tick, function(e)
  traincam.tick()
end)

script.on_event(defines.events.on_gui_click, function(e)
  local player = game.get_player(e.player_index)
  traincam.on_click(player, e.element)
end)

script.on_event(defines.events.on_gui_confirmed, function(e)
  local player = game.get_player(e.player_index)
  traincam.on_confirmed(player, e.element)
end)

script.on_event(defines.events.on_gui_value_changed, function(e)
  local player = game.get_player(e.player_index)
  traincam.on_value_changed(player, e.element)
end)

script.on_event(defines.events.on_player_removed, function(e)
  traincam.remove_player(e.player_index)
end)



-- Add or remove a target train
local function add_target(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected

  if selected and (selected.type == "locomotive" or selected.type == "cargo-wagon" or selected.type == "fluid-wagon" or selected.type == "artillery-wagon") then
    traincam.add_target(player, selected)
  else
    player.print({"message.traincam-error-no-target"})
  end
end

commands.add_command("track_train", {"command-help.track_train"}, function(e) add_target(e) end)
script.on_event("traincam-toggle-shortcut", function(e) add_target(e) end)

-- Close all camera
commands.add_command("close-all-cam", {"command-help.close-all-cam"}, function(e)
  local player = game.get_player(e.player_index)
  traincam.close_all_cameras(player)
end)
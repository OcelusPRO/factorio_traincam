local traincam = {}
local traincam_default_zoom = 7
local traincam_default_size = 500

local zoom_map = {
  0.25, 0.325, 0.4, 0.5, 0.6, 0.75, 1, 1.25, 1.5, 2, 2.5, 3, 3.5, 4
}

-- Récupère ou initialise les données du joueur (gère plusieurs caméras)
local function get_player_data(player)
  storage.traincam_players = storage.traincam_players or {}
  local data = storage.traincam_players[player.index]
  if not data then
    data = { next_id = 1, cameras = {} }
    storage.traincam_players[player.index] = data
  end
  return data
end

-- Calcule la taille selon si la fenêtre est en plein écran ou non
local function get_cam_size(player, cam_state)
  if cam_state.fullscreen then
    local resolution = player.display_resolution
    local scale = player.display_scale
    return {resolution.width / scale, resolution.height / scale}
  else
    local s = cam_state.size or traincam_default_size
    return {s, s}
  end
end

function traincam.open_window(player, cam_state)
  local id = cam_state.id
  local tags = { traincam_id = id }
  local fullscreen = cam_state.fullscreen

  local main = player.gui.screen.add {
    type = "frame",
    name = "traincam-frame-" .. id,
    direction = "vertical",
    tags = tags
  }

  local size = get_cam_size(player, cam_state)
  main.style.size = size

  -- Centre toujours la fenêtre quand on la recrée (évite qu'elle apparaisse hors écran)
  main.auto_center = true

  -- === Ligne 1 : Barre de titre ===
  local title_bar = main.add {type = "flow", direction = "horizontal"}
  title_bar.style.vertical_align = "center"

  if not fullscreen then
    title_bar.drag_target = main
  end

  local title_label = title_bar.add {
    type = "label",
    style = "frame_title",
    caption = {"gui.traincam-title"},
    ignored_by_interaction = fullscreen,
  }
  cam_state.title_label = title_label

  local surface_trains = 0
  if cam_state.target and cam_state.target.valid then
    surface_trains = #player.force.get_trains(cam_state.target.surface)
  end

  if surface_trains <= 1 then
    title_label.caption = {"gui.holy-traincam-title"}
  else
    title_label.caption = {"", {"gui.traincam-title"}, " - N°", id}
  end

  title_bar.add {
    type = "label",
    style = "frame_title",
    caption = name,
    ignored_by_interaction = fullscreen,
  }

  if fullscreen then
    title_bar.add {
      type = "empty-widget",
      style = "draggable_space",
    }
  else
    local drag_space = title_bar.add {
      type = "empty-widget",
      style = "draggable_space",
      ignored_by_interaction = true,
    }
    drag_space.style.horizontally_stretchable = true
    drag_space.style.height = 24
    drag_space.style.right_margin = 8
  end

  title_bar.add {
    type = "sprite-button",
    name = "traincam-fullscreen",
    style = "frame_action_button",
    sprite = "utility/expand",
    toggled = fullscreen,
    tooltip = {"gui.traincam-tooltip-fullscreen"},
    tags = tags
  }

  title_bar.add {
    type = "sprite-button",
    name = "traincam-close",
    style = "frame_action_button",
    sprite = "utility/close",
    tags = tags
  }

  -- === Ligne 2 : Barre de contrôles ===
  local controls_bar = main.add {
    type = "flow",
    direction = "horizontal"
  }
  controls_bar.style.vertical_align = "center"
  controls_bar.style.top_margin = 4
  controls_bar.style.bottom_margin = 8
  controls_bar.style.left_margin = 8
  controls_bar.style.right_margin = 8

  -- Taille
  local size_flow = controls_bar.add{type = "flow", name = "size-flow", direction = "horizontal"}
  size_flow.style.vertical_align = "center"
  size_flow.style.right_margin = 24

  size_flow.add{type = "label", caption = {"gui.traincam-size-label"}}

  local size_input = size_flow.add {
    type = "textfield",
    name = "traincam-size-input",
    text = tostring(cam_state.size),
    numeric = true,
    allow_decimal = false,
    clear_and_focus_on_right_click = true,
    tags = tags
  }
  size_input.style.width = 60
  size_input.enabled = not fullscreen

  local size_apply = size_flow.add {
    type = "sprite-button",
    name = "traincam-size-apply",
    style = "tool_button",
    sprite = "utility/check_mark",
    tooltip = {"gui.traincam-apply-size"},
    tags = tags
  }
  size_apply.style.size = 26
  size_apply.enabled = not fullscreen

  -- Zoom
  local zoom_flow = controls_bar.add{type = "flow", direction = "horizontal"}
  zoom_flow.style.vertical_align = "center"
  zoom_flow.add{type = "label", caption = {"gui.traincam-zoom-label"}}

  local zoom_slider = zoom_flow.add {
    type = "slider",
    name = "traincam-zoom",
    value = cam_state.zoom,
    minimum_value = 1,
    maximum_value = #zoom_map,
    tags = tags
  }
  zoom_slider.style.width = 120

  -- === Ligne 3 : Caméra ===
  local content = main.add {
    type = "frame",
    style = "inside_shallow_frame",
  }
  local camera = content.add {
    type = "camera",
    name = "traincam-camera",
    surface_index = cam_state.target.surface.index,
    position = {cam_state.x, cam_state.y},
  }
  camera.style.horizontally_stretchable = true
  camera.style.vertically_stretchable = true
  camera.style.minimal_width = 100
  camera.style.minimal_height = 100

  cam_state.main = main
  cam_state.camera = camera
  cam_state.size_input = size_input
end

function traincam.add_target(player, entity)
  local data = get_player_data(player)
  local id = data.next_id
  data.next_id = id + 1

  -- État de cette caméra spécifique
  local cam_state = {
    id = id,
    target = entity,
    x = entity.position.x,
    y = entity.position.y,
    zoom = traincam_default_zoom,
    size = traincam_default_size,
    fullscreen = false
  }

  traincam.open_window(player, cam_state)
  data.cameras[id] = cam_state
end

function traincam.close_camera(player, id)
  local data = get_player_data(player)
  local cam_state = data.cameras[id]
  if cam_state then
    if cam_state.main and cam_state.main.valid then
      cam_state.main.destroy()
    end
    data.cameras[id] = nil
  end
end

-- Gère l'activation exclusive du plein écran
function traincam.toggle_fullscreen(player, id)
  local data = get_player_data(player)
  local target_cam = data.cameras[id]
  if not target_cam then return end

  if target_cam.fullscreen then
    -- On sort simplement du plein écran
    target_cam.fullscreen = false
    if target_cam.main and target_cam.main.valid then target_cam.main.destroy() end
    traincam.open_window(player, target_cam)
  else
    -- On passe en plein écran, on doit donc réduire toutes les autres caméras
    for cam_id, cam_state in pairs(data.cameras) do
      if cam_state.fullscreen then
        cam_state.fullscreen = false
        if cam_state.main and cam_state.main.valid then cam_state.main.destroy() end
        traincam.open_window(player, cam_state)
      end
    end

    -- Activer le plein écran pour la cible
    target_cam.fullscreen = true
    if target_cam.main and target_cam.main.valid then target_cam.main.destroy() end
    traincam.open_window(player, target_cam)
  end
end

function traincam.apply_size(player, id)
  local data = get_player_data(player)
  local cam_state = data.cameras[id]
  if cam_state and cam_state.main and cam_state.main.valid then
    local input = cam_state.size_input
    if input and input.valid then
      local new_size = tonumber(input.text)
      if new_size then
        if new_size < 250 then new_size = 250 end
        if new_size > 2000 then new_size = 2000 end

        cam_state.size = new_size
        input.text = tostring(new_size)
        cam_state.main.style.size = {new_size, new_size}
      end
    end
  end
end

function traincam.on_click(player, element)
  local tags = element.tags
  if not tags or not tags.traincam_id then return end
  local id = tags.traincam_id

  if element.name == "traincam-close" then
    traincam.close_camera(player, id)
  elseif element.name == "traincam-fullscreen" then
    traincam.toggle_fullscreen(player, id)
  elseif element.name == "traincam-size-apply" then
    traincam.apply_size(player, id)
  end
end

function traincam.on_confirmed(player, element)
  local tags = element.tags
  if not tags or not tags.traincam_id then return end
  local id = tags.traincam_id

  if element.name == "traincam-size-input" then
    traincam.apply_size(player, id)
  end
end

function traincam.on_value_changed(player, element)
  local tags = element.tags
  if not tags or not tags.traincam_id then return end
  local id = tags.traincam_id

  if element.name == "traincam-zoom" then
    local data = get_player_data(player)
    local cam_state = data.cameras[id]
    if cam_state then
      cam_state.zoom = element.slider_value
    end
  end
end

function traincam.remove_player(player_index)
  if storage.traincam_players then
    storage.traincam_players[player_index] = nil
  end
end

function traincam.tick()
  if not storage.traincam_players then return end

  local lock_f = 0.1
  -- Optimisation : on met à jour le titre uniquement 1 fois par seconde (60 ticks)
  local should_update_titles = (game.tick % 60 == 0)

  for player_index, data in pairs(storage.traincam_players) do
    local player = nil

    if should_update_titles then
      player = game.get_player(player_index)
    end

    for id, cam_state in pairs(data.cameras) do
      local target = cam_state.target

      if target and target.valid then
        -- Rafraîchissement automatique du titre selon le nombre de trains sur CETTE surface
        if should_update_titles and player and cam_state.title_label and cam_state.title_label.valid then
          local surface_trains = #player.force.get_trains(target.surface)
          if surface_trains <= 1 then
            cam_state.title_label.caption = {"", {"gui.traincam-title"}, " - Train Principal"}
          else
            cam_state.title_label.caption = {"", {"gui.traincam-title"}, " - Train N°", id}
          end
        end

        local pos = target.position
        cam_state.x = cam_state.x + lock_f * (pos.x - cam_state.x)
        cam_state.y = cam_state.y + lock_f * (pos.y - cam_state.y)

        if cam_state.camera and cam_state.camera.valid then
          cam_state.camera.position = {cam_state.x, cam_state.y}
          cam_state.camera.zoom = zoom_map[cam_state.zoom or traincam_default_zoom]
          cam_state.camera.surface_index = target.surface.index
        end
      else
        if not player then player = game.get_player(player_index) end
        if player then
          traincam.close_camera(player, id)
        end
      end
    end
  end
end

return traincam
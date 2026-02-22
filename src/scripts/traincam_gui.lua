local gui = {}

gui.zoom_map = { 0.25, 0.325, 0.4, 0.5, 0.6, 0.75, 1, 1.25, 1.5, 2, 2.5, 3, 3.5, 4 }

function gui.get_cam_size(player, cam_state)
    if cam_state.fullscreen then
        local resolution = player.display_resolution
        local scale = player.display_scale
        return {resolution.width / scale, resolution.height / scale}
    else
        local s = cam_state.size or player.mod_settings["traincam-default-size"].value
        return {s, s}
    end
end

function gui.open_window(player, cam_state)
    local id = cam_state.id
    local tags = {traincam_id = id}
    local fullscreen = cam_state.fullscreen

    local main = player.gui.screen.add {
        type = "frame",
        name = "traincam-frame-" .. id,
        direction = "vertical",
        tags = tags
    }

    local size = gui.get_cam_size(player, cam_state)
    main.style.size = size

    if not fullscreen and cam_state.screen_pos then
        main.location = cam_state.screen_pos
    else
        main.auto_center = true
    end

    local title_bar = main.add {type = "flow", direction = "horizontal"}
    title_bar.style.vertical_align = "center"

    if not fullscreen then
        title_bar.drag_target = main
    end

    local title_label = title_bar.add {
        type = "label",
        style = "frame_title",
        caption = {"gui.traincam-title"},
        ignored_by_interaction = fullscreen
    }
    cam_state.title_label = title_label

    local surface_trains = 0
    if cam_state.target and cam_state.target.valid then
        surface_trains = #game.train_manager.get_trains({surface = cam_state.target.surface, force = player.force})
    end

    if surface_trains <= 1 then
        title_label.caption = {"gui.holy-traincam-title"}
    else
        local train_id = cam_state.target.train and cam_state.target.train.id or id
        title_label.caption = {"", {"gui.traincam-title"}, " - N°", train_id}
    end

    if fullscreen then
        title_bar.add {type = "empty-widget", style = "draggable_space"}
    else
        local drag_space = title_bar.add {
            type = "empty-widget",
            style = "draggable_space",
            ignored_by_interaction = true
        }
        drag_space.style.horizontally_stretchable = true
        drag_space.style.height = 24
        drag_space.style.right_margin = 8
    end

    title_bar.add {
        type = "sprite-button",
        name = "traincam-settings",
        style = "frame_action_button",
        sprite = "item/iron-gear-wheel",
        tooltip = {"gui.traincam-tooltip-settings"},
        tags = tags
    }

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

    local content = main.add {
        type = "frame",
        style = "inside_shallow_frame"
    }
    local camera = content.add {
        type = "camera",
        name = "traincam-camera",
        surface_index = cam_state.target.surface.index,
        position = {cam_state.x, cam_state.y}
    }
    camera.style.horizontally_stretchable = true
    camera.style.vertically_stretchable = true
    camera.style.minimal_width = 200
    camera.style.minimal_height = 200

    cam_state.main = main
    cam_state.camera = camera
end

function gui.open_settings_window(player, id, cam_state)
    if cam_state.settings_main and cam_state.settings_main.valid then
        cam_state.settings_main.destroy()
        cam_state.settings_main = nil
        return
    end

    local tags = {traincam_id = id}
    local frame = player.gui.screen.add {
        type = "frame",
        name = "traincam-settings-" .. id,
        direction = "vertical",
        tags = tags
    }
    frame.auto_center = true

    local title = frame.add {type = "flow", direction = "horizontal"}
    title.style.vertical_align = "center"
    title.drag_target = frame
    title.add {type = "label", style = "frame_title", caption = {"gui.traincam-settings-title"}}
    local drag = title.add {type = "empty-widget", style = "draggable_space"}
    drag.style.horizontally_stretchable = true
    drag.style.height = 24
    drag.style.right_margin = 8
    title.add {
        type = "sprite-button",
        name = "traincam-settings-close",
        style = "frame_action_button",
        sprite = "utility/close",
        tags = tags
    }

    local content = frame.add {type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical"}

    local size_flow = content.add {type = "flow", direction = "horizontal"}
    size_flow.style.vertical_align = "center"
    size_flow.style.bottom_margin = 8
    size_flow.add {type = "label", caption = {"gui.traincam-size-label"}}
    local size_input = size_flow.add {
        type = "textfield",
        name = "traincam-size-input",
        text = tostring(cam_state.size),
        numeric = true,
        allow_decimal = false,
        tags = tags
    }
    size_input.style.width = 60
    cam_state.settings_size_input = size_input

    local zoom_flow = content.add {type = "flow", direction = "horizontal"}
    zoom_flow.style.vertical_align = "center"
    zoom_flow.add {type = "label", caption = {"gui.traincam-zoom-label"}}
    local zoom_slider = zoom_flow.add {
        type = "slider",
        name = "traincam-zoom",
        value = cam_state.zoom,
        minimum_value = 1,
        maximum_value = #gui.zoom_map,
        tags = tags
    }
    zoom_slider.style.width = 120

    local buttons = frame.add {type = "flow", direction = "horizontal"}
    buttons.style.horizontal_align = "right"
    buttons.style.horizontally_stretchable = true
    buttons.style.top_margin = 8
    buttons.add {
        type = "button",
        name = "traincam-settings-apply",
        caption = {"gui.traincam-apply-settings"},
        tags = tags
    }

    cam_state.settings_main = frame
    player.opened = frame
end

return gui
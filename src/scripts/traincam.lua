local traincam = {}

local gui = require("scripts.traincam_gui")


local function get_player_data(player)
    storage.traincam_players = storage.traincam_players or {}
    local data = storage.traincam_players[player.index]
    if not data then
        data = {next_id = 1, cameras = {}}
        storage.traincam_players[player.index] = data
    end
    return data
end

function traincam.apply_settings(player, id)
    local data = get_player_data(player)
    local cam_state = data.cameras[id]
    if not cam_state then return end

    if cam_state.settings_size_input and cam_state.settings_size_input.valid then
        local new_size = tonumber(cam_state.settings_size_input.text)
        if new_size then
            if new_size < 150 then new_size = 150 end
            if new_size > 5000 then new_size = 5000 end
            cam_state.size = new_size
        end
    end

    if cam_state.settings_cb_speed and cam_state.settings_cb_speed.valid then
        cam_state.show_speed = cam_state.settings_cb_speed.state
    end
    if cam_state.settings_cb_next and cam_state.settings_cb_next.valid then
        cam_state.show_next = cam_state.settings_cb_next.state
    end
    if cam_state.settings_cb_travel and cam_state.settings_cb_travel.valid then
        cam_state.show_travel = cam_state.settings_cb_travel.state
    end

    local main_ui = player.gui.screen["traincam-frame-" .. tostring(id)]
    if main_ui and main_ui.valid then
        cam_state.screen_pos = main_ui.location
        main_ui.destroy()
        gui.open_window(player, cam_state)
    end

    local settings_ui = player.gui.screen["traincam-settings-" .. tostring(id)]
    if settings_ui and settings_ui.valid then
        settings_ui.destroy()
    end

    cam_state.settings_main = nil
end

function traincam.add_target(player, entity)
    local data = get_player_data(player)
    local id = entity.train and entity.train.id or "0_"..data.next_id

    if data.cameras[id] ~= nil then
        traincam.close_camera(player, id)
        return
    end

    data.next_id = data.next_id + 1

    local settings = player.mod_settings
    local default_zoom = settings["traincam-default-zoom"].value
    local default_size = settings["traincam-default-size"].value

    local cam_state = {
        id = id,
        target = entity,
        x = entity.position.x,
        y = entity.position.y,
        zoom = default_zoom,
        size = default_size,
        show_speed = settings["traincam-default-show-train-speed"].value,
        show_next = settings["traincam-default-show-next-station"].value,
        show_travel = settings["traincam-default-show-distance-traveled"].value,
        fullscreen = false
    }

    gui.open_window(player, cam_state)
    data.cameras[id] = cam_state
    player.print({"message.traincam-anchored"})
end

function traincam.close_camera(player, id)
    local data = get_player_data(player)

    local settings_ui = player.gui.screen["traincam-settings-" .. tostring(id)]
    if settings_ui and settings_ui.valid then
        settings_ui.destroy()
    end

    local main_ui = player.gui.screen["traincam-frame-" .. tostring(id)]
    if main_ui and main_ui.valid then
        main_ui.destroy()
    end

    if data.cameras[id] then
        data.cameras[id] = nil
    end

    player.print({"message.traincam-unanchored"})
end

function traincam.close_all_cameras(player)
    for _, child in pairs(player.gui.screen.children) do
        if child.name and child.name:find("^traincam%-") then
            child.destroy()
        end
    end

    local data = get_player_data(player)
    data.cameras = {}
    player.print({"message.traincam-close-all"})
end

function traincam.toggle_fullscreen(player, id)
    local data = get_player_data(player)
    local target_cam = data.cameras[id]
    if not target_cam then return end

    if target_cam.fullscreen then
        target_cam.fullscreen = false
        if target_cam.main and target_cam.main.valid then
            target_cam.main.destroy()
        end
        gui.open_window(player, target_cam)
    else
        for cam_id, cam_state in pairs(data.cameras) do
            if cam_state.fullscreen then
                cam_state.fullscreen = false
                if cam_state.main and cam_state.main.valid then
                    cam_state.main.destroy()
                end
                gui.open_window(player, cam_state)
            end
        end

        target_cam.fullscreen = true
        if target_cam.main and target_cam.main.valid then
            target_cam.screen_pos = target_cam.main.location
            target_cam.main.destroy()
        end
        gui.open_window(player, target_cam)
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
    elseif element.name == "traincam-settings" then
        local data = get_player_data(player)
        local cam_state = data.cameras[id]
        if cam_state then
            gui.open_settings_window(player, id, cam_state)
        end
    elseif element.name == "traincam-settings-close" then
        local settings_ui = player.gui.screen["traincam-settings-" .. tostring(id)]
        if settings_ui and settings_ui.valid then
            settings_ui.destroy()
        end

        local data = get_player_data(player)
        if data.cameras[id] then
            data.cameras[id].settings_main = nil
        end
    elseif element.name == "traincam-camera" then
        local data = get_player_data(player)
        local cam_state = data.cameras[id]
        if cam_state and cam_state.target and cam_state.target.valid then
            player.opened = cam_state.target
        end
    elseif element.name == "traincam-settings-apply" then
        traincam.apply_settings(player, id)
    end

end

function traincam.on_confirmed(player, element)
    local tags = element.tags
    if not tags or not tags.traincam_id then return end
    local id = tags.traincam_id

    if element.name == "traincam-size-input" then
        traincam.apply_settings(player, id)
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
    storage.train_odometers = storage.train_odometers or {}

    local interval = settings.global["traincam-odometer-interval"].value
    if interval == 0 then
        storage.dynamic_interval = storage.dynamic_interval or 10
        if game.tick % 300 == 0 then
            local train_count = #game.train_manager.get_trains({})
            storage.dynamic_interval = math.max(1, math.min(60, math.floor(train_count / 10)))
        end
        interval = storage.dynamic_interval
    end

    if game.tick % interval == 0 and interval ~= -1 then
        local all_trains = game.train_manager.get_trains({})
        for _, train in pairs(all_trains) do
            if train and train.valid then
                local speed = math.abs(train.speed)
                if speed > 0 then
                    storage.train_odometers[train.id] = (storage.train_odometers[train.id] or 0) + (speed * interval)
                end
            end
        end
    end


    local should_update_titles = (game.tick % 60 == 0)
    local should_update_telemetry = (game.tick % 10 == 0)


    for player_index, data in pairs(storage.traincam_players) do
        local player = game.get_player(player_index)

        if player and player.connected then
            local lock_f = player.mod_settings["traincam-tracking-speed"].value

            for id, cam_state in pairs(data.cameras) do
                local target = cam_state.target
                local train = target.train

                if target and target.valid then
                    if should_update_titles and player and cam_state.title_label and cam_state.title_label.valid then
                        local surface_trains = #game.train_manager.get_trains({surface = target.surface, force = player.force})
                        if surface_trains <= 1 then
                            cam_state.title_label.caption = {"gui.holy-traincam-title"}
                        else
                            local train_id = target.train and target.train.id or "?"
                            cam_state.title_label.caption = {"", {"gui.traincam-title"}, " - N°", train_id}
                        end
                    end

                    if should_update_telemetry and train and train.valid then

                        if cam_state.label_speed and cam_state.label_speed.valid then
                            local speed_kmh = math.floor(math.abs(train.speed) * 216)
                            cam_state.label_speed.caption = {"gui.traincam-speed", speed_kmh}
                        end

                        if cam_state.label_next and cam_state.label_next.valid then
                            local dest_name = {"gui.traincam-dest-none"}
                            if train.schedule and train.schedule.records and #train.schedule.records > 0 then
                                local current_record = train.schedule.records[train.schedule.current]
                                if current_record and current_record.station then
                                    dest_name = current_record.station
                                end
                            end
                            cam_state.label_next.caption = {"gui.traincam-dest", dest_name}
                        end

                        if cam_state.label_travel and cam_state.label_travel.valid then
                            local distance = storage.train_odometers[train.id] or 0
                            local dist_km = string.format("%.2f", distance / 1000)
                            cam_state.label_travel.caption = {"gui.traincam-travel-dist", dist_km}
                        end


                    end

                    local pos = target.position
                    cam_state.x = cam_state.x + lock_f * (pos.x - cam_state.x)
                    cam_state.y = cam_state.y + lock_f * (pos.y - cam_state.y)

                    if cam_state.camera and cam_state.camera.valid then
                        cam_state.camera.position = {cam_state.x, cam_state.y}

                        cam_state.camera.zoom = gui.zoom_map[cam_state.zoom or 7]
                        cam_state.camera.surface_index = target.surface.index
                    end
                else
                    traincam.close_camera(player, id)
                end
            end
        end
    end
end

return traincam
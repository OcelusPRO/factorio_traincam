data:extend({
    {
      type = "int-setting",
      name = "traincam-default-size",
      setting_type = "runtime-per-user",
      default_value = 400,
      minimum_value = 150,
      maximum_value = 2000
    },
    {
      type = "int-setting",
      name = "traincam-default-zoom",
      setting_type = "runtime-per-user",
      default_value = 7,
      minimum_value = 1,
      maximum_value = 14
    },
    {
      type = "double-setting",
      name = "traincam-tracking-speed",
      setting_type = "runtime-per-user",
      default_value = 0.1,
      minimum_value = 0.01,
      maximum_value = 1
    },
    {
        type = "bool-setting",
        name = "traincam-default-show-train-speed",
        setting_type = "runtime-per-user",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "traincam-default-show-distance-traveled",
        setting_type = "runtime-per-user",
        default_value = false
    },
    {
        type = "bool-setting",
        name = "traincam-default-show-next-station",
        setting_type = "runtime-per-user",
        default_value = false
    },
    {
        type = "int-setting",
        name = "traincam-odometer-interval",
        setting_type = "runtime-global",
        default_value = 0,
        minimum_value = -1,
        maximum_value = 300
    }
  })
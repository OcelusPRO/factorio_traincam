data:extend({
    {
      type = "int-setting",
      name = "traincam-default-size",
      setting_type = "runtime-per-user",
      default_value = 400,
      minimum_value = 150,
      maximum_value = 2000,
      order = "a"
    },
    {
      type = "int-setting",
      name = "traincam-default-zoom",
      setting_type = "runtime-per-user",
      default_value = 7,
      minimum_value = 1,
      maximum_value = 14,
      order = "b"
    },
    {
      type = "double-setting",
      name = "traincam-tracking-speed",
      setting_type = "runtime-per-user",
      default_value = 0.1,
      minimum_value = 0.01,
      maximum_value = 1,
      order = "c"
    }
  })
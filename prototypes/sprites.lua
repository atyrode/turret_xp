return function(names)
  data:extend({
    {
      type = "sprite",
      name = names.sort_arrow_up,
      filename = "__core__/graphics/arrows/table-header-sort-arrow-up-white.png",
      priority = "extra-high-no-scale",
      width = 16,
      height = 16,
      flags = { "gui-icon" },
      mipmap_count = 1,
      scale = 0.5,
    },
    {
      type = "sprite",
      name = names.sort_arrow_down,
      filename = "__core__/graphics/arrows/table-header-sort-arrow-down-white.png",
      priority = "extra-high-no-scale",
      width = 16,
      height = 16,
      flags = { "gui-icon" },
      mipmap_count = 1,
      scale = 0.5,
    },
  })
end

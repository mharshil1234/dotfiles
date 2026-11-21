hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgba({{colors.primary.default.hex_stripped}}77)", "rgba({{colors.tertiary.default.hex_stripped}}55)" }, angle = 45 }, -- wallpaper accent gradient
            inactive_border = "rgba({{colors.surface_container_low.default.hex_stripped}}33)",
        },
    },
    misc = {
        background_color = "rgba({{colors.surface.dark.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.primary.default.hex_stripped}}AA) rgba({{colors.primary.default.hex_stripped}}77)",
})

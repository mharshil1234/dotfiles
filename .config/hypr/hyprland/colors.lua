hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgba(c3c6d677)", "rgba(c1c6dd55)" }, angle = 45 }, -- wallpaper accent gradient
            inactive_border = "rgba(1b1b1d33)",
        },
    },
    misc = {
        background_color = "rgba(131315FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(c3c6d6AA) rgba(c3c6d677)",
})

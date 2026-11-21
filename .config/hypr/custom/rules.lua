
-- Spotify: same opacity as kitty (background_opacity 0.82)
hl.window_rule({match = {class = "^([Ss]potify)$"}, opacity = "0.82 override 0.82 override"})

-- VS Code: whole window 96% opaque
hl.window_rule({match = {class = "^(code-oss|Code|code)$"}, opacity = "0.96 override 0.96 override"})

-- Personal Hyprland keybinding overrides for Omarchy v4.5.0+ (saxtonhale)
-- Keep this file minimal so Omarchy updates never break your workflow.
-- Inspect active bindings anytime with: omarchy menu keybindings --print

-- ---------------------------------------------------------------------------
-- 1. Re-park the 3 stock bindings displaced by Vim H/J/K/L focus
-- ---------------------------------------------------------------------------
-- SUPER + K (Keybindings menu) -> SUPER + CTRL + /
o.bind("SUPER + CTRL + SLASH", "Keybindings", "omarchy-menu-keybindings")

-- SUPER + J (Toggle window split) -> SUPER + CTRL + J
o.bind("SUPER + CTRL + J", "Toggle window split", hl.dsp.layout("togglesplit"))

-- SUPER + L / SUPER + ALT + L (Cycle workspace layout) -> SUPER + \ / SUPER + ALT + \
o.bind("SUPER + BACKSLASH", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
hl.unbind("SUPER + ALT + L")
o.bind("SUPER + ALT + BACKSLASH", "Cycle workspace layout back", "omarchy-hyprland-workspace-layout-toggle back")

-- ---------------------------------------------------------------------------
-- 2. Non-negotiable Vim navigation: focus (SUPER + hjkl) & swap (SUPER + SHIFT + hjkl)
-- ---------------------------------------------------------------------------
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.rebind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.rebind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- ---------------------------------------------------------------------------
-- 3. AI / Agent apps on Omarchy's AI plane (replaces stock ChatGPT / Grok webapps)
--    Stock SUPER + SHIFT + CTRL + A remains `omarchy-agent --pick`.
-- ---------------------------------------------------------------------------
o.rebind("SUPER + SHIFT + A", "Antigravity", { launch = "antigravity", focus = "^[Aa]ntigravity$" })
o.rebind("SUPER + SHIFT + ALT + A", "Codex", { tui = "codex" })

-- Note on Hex voice dictation:
-- Omarchy's default/hypr/bindings/dictation.lua only binds ALT + SPACE if an
-- Omarchy dictation backend is installed. Leave Omarchy's dictation uninstalled
-- so Hex owns ALT + SPACE cleanly.

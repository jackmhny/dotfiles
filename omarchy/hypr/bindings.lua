-- Personal Hyprland keybinding overrides for Omarchy v4.5.0+ (saxtonhale)
-- Keep this file minimal so Omarchy updates never break your workflow.
-- Inspect active bindings anytime with: omarchy menu keybindings --print

-- Temporarily disable the stock top-bar shortcut to avoid hiding the bar by accident.
-- The default is loaded before this file, so unbind it here.
-- o.bind_toggle("SUPER + SHIFT + SPACE", "Toggle top bar", "bar")
hl.unbind("SUPER + SHIFT + SPACE")

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

-- Swap tiled windows or nudge floating windows with the same Vim keys.
local nudge = 25
local directions = {
  H = { direction = "l", x = -nudge, y = 0 },
  J = { direction = "d", x = 0, y = nudge },
  K = { direction = "u", x = 0, y = -nudge },
  L = { direction = "r", x = nudge, y = 0 },
}

for key, move in pairs(directions) do
  o.rebind("SUPER + SHIFT + " .. key, "Swap or nudge window " .. key, function()
    local window = hl.get_active_window()
    if not window then return end

    if window.floating then
      hl.dispatch(hl.dsp.window.move({ x = move.x, y = move.y, relative = true }))
    else
      hl.dispatch(hl.dsp.window.swap({ direction = move.direction }))
    end
  end, { repeating = true })
end

o.rebind("SUPER + CTRL + H", "Previous window in group", hl.dsp.group.prev())
o.rebind("SUPER + CTRL + L", "Next window in group", hl.dsp.group.next())

o.bind("SUPER + ALT + H", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + ALT + J", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
o.rebind("SUPER + ALT + K", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + ALT + L", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))

-- ---------------------------------------------------------------------------
-- 3. AI / Agent apps on Omarchy's AI plane (replaces stock ChatGPT / Grok webapps)
--    Stock SUPER + SHIFT + CTRL + A remains `omarchy-agent --pick`.
-- ---------------------------------------------------------------------------
o.rebind("SUPER + SHIFT + A", "Antigravity", { launch = "antigravity", focus = "^[Aa]ntigravity$" })
o.rebind("SUPER + SHIFT + ALT + A", "Codex", { tui = "codex" })

hl.unbind("SUPER + W")

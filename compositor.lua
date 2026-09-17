-- Loaded by the plugin's block in the personal bindings.lua.
-- Match each surface exactly: the frozen desktop must never receive glass.
hl.layer_rule({ match = { namespace = "^omarchy-desenhar(-toolbar)?$" }, no_anim = true, animation = "none" })

local flag = io.open(os.getenv("HOME") .. "/.local/state/omarchy/liquid-glass-install/enabled", "r")
local glass = flag and flag:read("*l") == "true"
if flag then flag:close() end
if glass and hl.plugin.hyprglass then
  -- Inherit the system material and its light/dark palette, without replacing it.
  hl.layer_rule({ match = { namespace = "^omarchy-desenhar-toolbar$" }, blur = true, ignore_alpha = 0.20 })
  hl.plugin.hyprglass.layer("omarchy-desenhar-toolbar", { mask_threshold = 0.25 })
  hl.plugin.hyprglass.layer("omarchy-desenhar", { exclude = true })
end

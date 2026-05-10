local toml = TOML.new()
Params = toml:read()
if not Params then
    Params = {
        ShowArtifacts = true,
        Unlocked9 = {}
    }
    toml:write(Params)
end

local options = ModOptions.new()
local ShowArtifactsOpt = options:add_checkbox("ShowArtifacts")

ShowArtifactsOpt:add_getter(function()
    return Params.ShowArtifacts
end)
ShowArtifactsOpt:add_setter(function(value)
    Params.ShowArtifacts = value
end)


local UI    = {}
UI.__index  = UI


function UI:new()
    local class = {}

    ----------VARIABLES-------------

    ----------VARIABLES-------------

    setmetatable( class, UI )
    return class
end

function UI:ReplacerArray(JB, arr)
    for index, name in ipairs(arr) do
        self:Replacer(JB, name)
    end
end

function UI:Replacer(JB, name)
    value, pressed = ImGui.Checkbox(name, JB.replacer == name)

    if (pressed) then
        Game.GetScriptableSystemsContainer():Get(CName.new('TakeOverControlSystem')):EnablePlayerTPPRepresenation(false)
        if GetPlayer():FindComponentByName('torso') ~= nil then
            GetPlayer():FindComponentByName('torso'):Toggle(false)
            GetPlayer():FindComponentByName('legs'):Toggle(false)
            GetPlayer():FindComponentByName('n0_000_pma_base__full'):Toggle(false)
        else
            GetPlayer():FindComponentByName('body'):Toggle(false)
        end
        GetPlayer():ScheduleAppearanceChange(name)
        JB.replacer = name
    end
end

function UI:DrawCam(cam, id)
    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "X-Axis")

    value, usedX = ImGui.SliderFloat("x", tonumber(cam.pos.x), -3.0, 3.0)

    if usedX then
        cam.pos.x = value
    end

    ImGui.NewLine()

    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Y-Axis")

    value, usedX = ImGui.SliderFloat("y", tonumber(cam.pos.y), -10.0, 10.0)

    if usedX then
        cam.pos.y = value
    end

    ImGui.NewLine()

    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Z-Axis")

    value, usedX = ImGui.SliderFloat("z", tonumber(cam.pos.z), -3.0, 3.0)

    if usedX then
        cam.pos.z = value
    end

    ImGui.NewLine()

    local euler = GetSingleton("Quaternion"):ToEulerAngles(cam.rot)

    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Roll")

    value, usedroll = ImGui.SliderFloat("roll", euler.roll, -180.0, 180.0)

    if usedroll then
        cam.rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(value, euler.pitch, euler.yaw))
    end

    ImGui.NewLine()

    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Pitch")

    value, usedpitch = ImGui.SliderFloat("pitch", euler.pitch, -90.0, 90.0)

    if usedpitch then
        cam.rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, value, euler.yaw))
    end

    ImGui.NewLine()

    ImGui.TextColored(0.509803, 0.752941, 0.60392, 1, "Yaw")

    value, usedpitch = ImGui.SliderFloat("yaw", euler.yaw, -180.0, 180.0)

    if usedpitch then
        cam.rot = GetSingleton("EulerAngles"):ToQuat(EulerAngles.new(euler.roll, euler.pitch, value))
    end

    ImGui.NewLine()

    value, pressedSavedCameras = ImGui.Checkbox("Save", false)

    if pressedSavedCameras then
        print("JB: Camera is saved")
        db:exec("UPDATE cameras SET x = " .. cam.pos.x .. ", y = " .. cam.pos.y .. ", z=" .. cam.pos.z .. ", rx=" .. cam.rot.i .. ", ry=" .. cam.rot.j .. ", rz=" .. cam.rot.k .. ", rw=" .. cam.rot.r .. "  WHERE id = " .. id)
    end
end

return UI:new()
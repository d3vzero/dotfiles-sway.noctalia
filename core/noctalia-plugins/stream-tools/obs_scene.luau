--!nonstrict
local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/obs-scene-status.py", function(result)
    local out = result and result.stdout and noctalia.string.trim(result.stdout) or "OFF|0"
    local scene, rec = out:match("^(.-)|([01])$")
    scene = scene or "OFF"
    barWidget.setText("[" .. scene .. "]")
    barWidget.setGlyphColor(rec == "1" and "error" or "")
  end, 3000)
end

function update()
  noctalia.setUpdateInterval(3000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/obs-scene-picker.py", function()
      refresh()
    end, 60000)
  end
end

refresh()

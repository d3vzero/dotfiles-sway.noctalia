--!nonstrict
local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/display-mode-status.sh", function(result)
    local text = result and result.stdout and noctalia.string.trim(result.stdout) or "?"
    barWidget.setText("[" .. text .. "]")
  end, 3000)
end

function update()
  noctalia.setUpdateInterval(5000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/display-mode-picker.sh", function()
      refresh()
    end, 30000)
  end
end

refresh()

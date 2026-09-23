--!nonstrict
local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/mpd-output-status.sh", function(result)
    local text = result and result.stdout and noctalia.string.trim(result.stdout) or ""
    barWidget.setText(text ~= "" and text or "MPD?")
  end, 5000)
end

function update()
  noctalia.setUpdateInterval(2000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/mpd-output-toggle.sh", function()
      refresh()
    end, 5000)
  end
end

refresh()

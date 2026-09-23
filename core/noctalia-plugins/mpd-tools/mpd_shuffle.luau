--!nonstrict
local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/music-shuffle-status.sh", function(result)
    local text = result and result.stdout and noctalia.string.trim(result.stdout) or "Shuffle"
    barWidget.setText(text)
  end, 5000)
end

function update()
  noctalia.setUpdateInterval(2000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/music-shuffle-toggle.sh", function()
      refresh()
    end, 5000)
  end
end

refresh()

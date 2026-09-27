--!nonstrict
local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/casual-record-status.sh", function(result)
    local text = result and result.stdout and noctalia.string.trim(result.stdout) or "Casual"
    if text == "REC" then
      barWidget.setText("[REC]")
      barWidget.setGlyphColor("error")
    else
      barWidget.setText("Casual")
      barWidget.setGlyphColor("")
    end
  end, 3000)
end

function update()
  noctalia.setUpdateInterval(2000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/casual-record-toggle.sh", function()
      refresh()
    end, 5000)
  end
end

refresh()

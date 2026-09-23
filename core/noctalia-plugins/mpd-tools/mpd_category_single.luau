--!nonstrict
local category = "Single"

local function refresh()
  noctalia.runAsync("/home/DrDDrake/.local/bin/music-category-status.sh " .. category, function(result)
    local text = result and result.stdout and noctalia.string.trim(result.stdout) or category
    barWidget.setText(text)
  end, 5000)
end

function update()
  noctalia.setUpdateInterval(2000)
  refresh()
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/music-category.sh " .. category, function()
      refresh()
    end, 5000)
  end
end

refresh()

--!nonstrict
function update()
  noctalia.setUpdateInterval(60000)
  barWidget.setText("Cheatsheet")
end

function onIpc(event, payload)
  if event == "toggle" then
    noctalia.runAsync("/home/DrDDrake/.local/bin/cheatsheet-toggle.sh", function() end, 5000)
  end
end

update()

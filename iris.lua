-- Stargate Iris Control library by TinyDeskEngie1

-- Makes controlling AUNIS stargate iris via OpenComputers less tedious
c = require("component")
sg = c.stargate

iris = {}

iris.exists = function() -- Checks if there is an iris installed on the connected stargate.
  if sg.getIrisType ~= "NULL" then
    return true
  else
    return false
  end
end

iris.isBusy = function() -- Checks if the iris is currently opening or closing
  local state = sg.getIrisState()
  if state == "CLOSING" or state == "OPENING" then
    return true
  else
    return false
  end
end

iris.isActive = function() -- Checks if the iris is set to be closed.
  local state = sg.getIrisState()
  if state == CLOSING or state == "CLOSED" then
    return true
  else
    return false
  end
end

iris.setState = function(newState) -- Changes the state of the iris based on a boolean value. Returns string based on result.
  if not iris.exists() then
    return "no_iris"
  end
  if iris.isBusy() then
    return "iris_busy"
  end

  if newState then
    if not iris.isActive() then
      sg.toggleIris()
      return "success"
    else
      return "no_change"
    end
  else
    if iris.isActive() then
      sg.toggleIris()
      return "success"
    else
      return "no_change"
    end
  end
end

return iris
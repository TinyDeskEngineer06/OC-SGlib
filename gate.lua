-- Stargate Control library made by TinyDeskEngie1

-- Makes controlling AUNIS stargates less tedious

c = require("component")
event = require("event")
sg = c.stargate

gate = {}

gate.symbols = {}
gate.symbols.origin = {}
gate.symbols.origin["MILKYWAY"] = "Point of Origin"
gate.symbols.origin["PEGASUS"] = "Subido"
gate.symbols.origin["UNIVERSE"] = "Glyph 17"

gate.dial = function(...)
  local args = {...}
  local address = {}
  if type(args[1]) == "table" then
    address = args[1]
  else
    for i = 1, #args do
      address[i] = args[i]
    end
  end
  
  if #address < 7 or #address > 9 then
    error("Too few or too many symbols in address", 2)
  end
  
  for a = 2, #address do
    for b = 1, a-1 do
      if address[a] == address[b] then
        error("Symbol \'" .. address[a] .. "\' occurs multiple times in address", 2)
      end
    end
  end
  
  if address[#address] ~= gate.symbols.origin[sg.getGateType()] then
    error("Last symbol (" .. address[#address] .. ") does not match connected gate's Point of Origin symbol", 2)
  end
  
  for i = 1, #address do
    sg.engageSymbol(address[i])
    event.pull("stargate_spin_chevron_engaged")
  end

  if sg.engageGate() == "stargate_engage" then
    event.pull("stargate_wormhole_stabilized")
  end
end

gate.isOpen = function()
  if sg.getGateStatus() == "open" then
    return true
  else
    return false
  end
end

return gate
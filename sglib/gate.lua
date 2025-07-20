-- Stargate 

local component = require("component")
local event = require("event")
local thread = require("thread")

local gates = {
  ["MILKYWAY"] = {},
  ["PEGASUS"] = {},
  ["UNIVERSE"] = {},
  types = {}
}

local origins = {
  ["MILKYWAY"] = "Point of Origin",
  ["Pegasus"] = "Subido",
  ["UNIVERSE"] = "G17"
}

for addr, _ in component.list("stargate", true) do
  local proxy = component.proxy(addr)
  local gateType = proxy.getGateType()

  gates[gateType][addr] = proxy
  gates.types[addr] = gateType
end

event.listen("component_added", function(addr, type)
  if type ~= "stargate" then return end

  local proxy = component.proxy(addr)
  local gateType = proxy.getGateType()

  gates[gateType][addr] = proxy
  gates.types[addr] = gateType
end)

event.listen("component_removed", function(addr, type)
  if type ~= "stargate" then return end

  local gateType = gates.types[addr]

  gates[gateType][addr] = nil
  gates.types[addr] = nil
end)

local gate = {}

-- Gets the first idle stargate of the specified type
function gate.getFree(type)
  checkArg(1, type, "string")

  for _, proxy in pairs(gates[type]) do
    if proxy.getGateStatus() == "idle" then return proxy end
  end

  return nil
end

-- Dial an address with a stargate. Point of Origin not required.
-- Non-blocking, designed to allow parallel dialing on multiple gates.
function gate.dialAddress(proxy, ...)
  checkArg(1, proxy, "table", "string")

  arg = {...}

  checkArg(2, arg[1], "table", "string")

  local addr = arg

  if type(addr[1]) == "table" then addr = addr[1] end
  if type(proxy) == "string" then proxy = gate.getFree(proxy) end

  if proxy.getGateStatus() ~= "idle" then return end

  local gateType = proxy.getGateType()
  local gateAddr = proxy.address

  if addr[#addr] ~= origins[gateType] then table.insert(addr, origins[gateType]) end

  thread.create(function()
    for _, symbol in ipairs(addr) do
      local status = proxy.engageSymbol(symbol)
      if not status then
        proxy.engageGate()
        return
      end

      repeat
        local name, eventAddr = event.pullMultiple("stargate_spin_chevron_engaged", "stargate_dhd_chevron_engaged", "stargate_incoming_wormhole")

        if name ~= "stargate_spin_chevron_engaged" and eventAddr == gateAddr then
          proxy.engageGate()
          return
        end
      until eventAddr == gateAddr
    end

    proxy.engageGate()
  end)
end

-- Sets if the iris on a stargate is closed.
function gate.setIrisClosed(proxy, closed)
  checkArg(1, proxy, "table")
  checkArg(2, closed, "boolean")

  if proxy.getIrisType() == "NULL" then return false end

  local irisState = proxy.getIrisState()

  if closed then
    if irisState == "OPENED" or irisState == "OPENING" then
      proxy.toggleIris()
    end
  else
    if irisState == "CLOSED" or irisState == "CLOSING" then
      proxy.toggleIris()
    end
  end
end

return gate
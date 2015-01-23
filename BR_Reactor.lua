local component = require("component")
local computer = require("computer")
local string = require("string")
local r1 = component.br_reactor
local term = require("term")
local os = require("os")
local event = require("event")
local kb = require("keyboard")
local unicode = require("unicode")
local running = true
local X = r1.getNumberOfControlRods()
local args = {...}
local commandInput = ""

local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function rodsList()
	for i = 0,X-1 do
		print("Control Rod " .. r1.getControlRodName(i) .. ": " .. r1.getControlRodLevel(i) .. "% Insertion")
	end
end

local function thesplit(inputstr, sep)
		if sep == nil then
			sep = "%s"
		end
		local t={} ; i=1
		for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
		end
		return t
end

local function ui()
	term.clear()
	term.setCursor(1,1)
	term.write("Reactor Status: ")
	if r1.getActive("true") then
		component.gpu.setForeground(0x008000)
		status = "Online"
	else
		component.gpu.setForeground(0xFF0000)
		status = "Offline"
	end
	term.write(status)
	component.gpu.setForeground(0xFFFFFF)
	term.setCursor(1,2)
	term.write("Core Temp: " .. round(r1.getFuelTemperature(), 2) .. " " .. unicode.char(248) .. "C")
	term.setCursor(1,3)
	term.write("Case Temp: " .. round(r1.getCasingTemperature(), 2) .. " " .. unicode.char(248) .. "C")
	term.setCursor(1,4)
	term.write("Energy Buffer: " .. round(r1.getEnergyStored(), 2) .. " RF")
	term.setCursor(1,5)
	term.write("Energy Output: " .. round(r1.getEnergyProducedLastTick(), 2) .. " RF/t")
	term.setCursor(1,6)
	term.write("Fuel Reactivity: " .. round(r1.getFuelReactivity(), 2) .. "%")
	term.setCursor(1,7)
	term.write("Max Fuel: " .. round(r1.getFuelAmountMax(), 2) .. " mB")
	term.setCursor(1,8)
	term.write("Remaining Fuel: " .. round(r1.getFuelAmount(), 2) .. " mB")
	term.setCursor(1,9)
	term.write("Fuel Consumtion: " .. round(r1.getFuelConsumedLastTick(), 3) .. " mB/t")
	term.setCursor(1,10)
	term.write("Waste: " .. round(r1.getWasteAmount(), 2) .. " mB")
	term.setCursor(1,11)
	term.write("Number of Control Rods: " .. r1.getNumberOfControlRods())
	term.setCursor(1,12)
	rodsList()
end

local function rodControl(rodNum, percent)
	local rodNum = rodNum - 1
	if rodNum >= 0 or rodNum < X then
		print("Invald rod Number. Rods numbered as 1~" .. X .. ".")
		os.sleep(2.5)
	else
		r1.setControlRodLevel(rodNum, percent)
	end
end

local function userInput()
	_, _, _, c = event.pull(0.5, "key_down")
	if c == kb.keys.enter or c == kb.keys.numpadenter then
	term.clear()
	term.setCursor(1,1)
	term.write("Command: ")
	commandInput = term.read()
	commandInput = string.gsub(commandInput, "\n", "")
end
  if commandInput == "stop" then
	r1.setActive(false)
	ui()
  end
  if commandInput == "start" then
	r1.setActive(true)
	ui()
  end
  if commandInput == "exit" then
  	term.clear()
  	term.setCursor(1,1)
  	running = false
  end
  if commandInput == "back" then
  	ui()
  end
  if string.match(commandInput, "rod") then
	local output = thesplit(commandInput, " ")
	rod = tonumber(output[2])
	percent = tonumber(output[3])
  	rodControl(rod,percent)
  	ui()
  end
  if commandInput == "full" then
  	r1.setAllControlRodLevels(0)
  end
  if commandInput == "close" then
  	r1.setAllControlRodLevels(100)
  end
end

while running do
	ui()
	userInput()
end
local component = require("component")
local computer = require("computer")
local string = require("string")
local t1 = component.br_turbine
local r1 = component.br_reactor
local term = require("term")
local os = require("os")
local event = require("event")
local kb = require("keyboard")
local unicode = require("unicode")
local shell = require("shell")
local running = true
local X = r1.getNumberOfControlRods()
local coolantType = r1.getCoolantType()
local hotFluidType = r1.getHotFluidType()
local commandInput = ""
local refresh = 1
local power = r1.getEnergyProducedLastTick()
local energyBuffer = r1.getEnergyStored()

local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function rodsList()
	print("Number of Control Rods: " .. X)
	for i = 0,X-1 do
		print("Control Rod " .. r1.getControlRodName(i) .. ": " .. r1.getControlRodLevel(i) .. "% Insertion")
	end
end

local function theSplit(inputstr, sep)
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

local function activeCool()
	if coolantType == nil then
		coolantType = "None"
	end

	if hotFluidType == nil then
		hotFluidType = "None"
	end

	if r1.isActivelyCooled() == true then
		print("Rotor Speed: " .. round(t1.getRotorSpeed(), 3) .. " RPM")
		print("Max Coolant Amount: " .. r1.getCoolantAmountMax() .. " mB")
		print("Current Coolant Amount: " .. round(r1.getCoolantAmount(), 2) .. " mB")
		print("Coolant: " .. coolantType)
		print("Max Hot Fluid: " .. r1.getHotFluidAmountMax())
		print("Current Hot Fluid: " .. round(r1.getHotFluidAmount(), 2))
		print("Hot Fluid Type: " .. hotFluidType)
		power = t1.getEnergyProducedLastTick()
		energyBuffer = t1.getEnergyStored()
	end
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
	print("Core Temp: " .. round(r1.getFuelTemperature(), 2) .. " " .. unicode.char(248) .. "C")
	print("Case Temp: " .. round(r1.getCasingTemperature(), 2) .. " " .. unicode.char(248) .. "C")
	print("Energy Buffer: " .. round(energyBuffer, 2) .. " RF")
	print("Energy Output: " .. round(power, 2) .. " RF/t")
	print("Fuel Reactivity: " .. round(r1.getFuelReactivity(), 2) .. "%")
	print("Max Fuel: " .. round(r1.getFuelAmountMax(), 2) .. " mB")
	print("Remaining Fuel: " .. round(r1.getFuelAmount(), 2) .. " mB")
	print("Fuel Consumtion: " .. round(r1.getFuelConsumedLastTick(), 3) .. " mB/t")
	print("Waste: " .. round(r1.getWasteAmount(), 2) .. " mB")
	activeCool()
	rodsList()
end

local function rodControl(rodNum, percent)
	local rodNum = rodNum - 1

	if rodNum >= 0 and rodNum <= X then
		r1.setControlRodLevel(rodNum, percent)
	else
		print("Invald rod Number. Rods numbered as 1~" .. X .. ".")
		os.sleep(2.5)
	end
end

local function inputKey()
	term.setCursor(1,3)
	term.write("Command Key: ")
	term.setCursor(1,4)
	term.write("back - Returns to the Status screen.")
	term.setCursor(65,4)
	term.write("rod <1~" .. X .. "> <0~100> - Sets rod X to X% insertion.")
	term.setCursor(1,5)
	term.write("exit - Exits the program, but leaves the reactor running.")
	term.setCursor(65,5)
	term.write("stop - Shuts the reator down.")
	term.setCursor(1,6)
	term.write("start - Starts the reactor.")
	term.setCursor(65,6)
	term.write("setAll <0~100> - Sets all control rods to X.")
	term.setCursor(1,7)
	term.write("update - Updates the program, the program must be manually restarted")
	term.setCursor(10,1)
end

local function userInput()
	_, _, _, c = event.pull(refresh, "key_down")

	if c == kb.keys.enter or c == kb.keys.numpadenter then
	term.clear()
	term.setCursor(1,1)
	term.write("Command: ")
	inputKey()
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
	local output = theSplit(commandInput, " ")
	rod = tonumber(output[2])
	percent = tonumber(output[3])
	output = ""
	commandInput = ""
  	rodControl(rod, percent)
  	ui()
  end

  if string.match(commandInput, "setAll") then
  	local output = theSplit(commandInput, " ")
  	percentAll = tonumber(output[2])
  	r1.setAllControlRodLevels(percentAll)
  	output = ""
  	commandInput = ""
  	ui()
  end

  if commandInput == "update" then
  	shell.execute("wget -fq https://raw.githubusercontent.com/Shuudoushi/Misc-Programs/master/BR_Reactor.lua reactor.lua")
  	term.clear()
  	term.setCursor(1,1)
  	print("Program closing to finsih update, please restart it.")
  	os.sleep(2.5)
  	term.clear()
  	term.setCursor(1,1)
  	running = false
  end
end

while running do
	ui()
	userInput()
end
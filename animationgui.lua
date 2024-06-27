-- NOTE: THIS IS FOR PERSONAL USE AND I HAVE A SEPERATE SCRIPT THAT TAKE THE GLOBAL ( _G ) TO EXECUTE THE ACTUAL THING
-- THIS IS JUST A SILLY UI TO CHANGE THE GLOBAL OPTION FOR A SEPARATE SCRIPT AND WILL NOT WORK WITHOUT IT!1!1!

local oldChat = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Chat")
local systemMessage = function(msg, color)
	if oldChat then
		local properties = props or {
			Text = msg;
			Font = Enum.Font.SourceSansBold;
			Color = color and Color3.new(unpack(color)) or Color3.new(1, 1, 1);
		}
		cloneref(game.GetService(game, "StarterGui")):SetCore("ChatMakeSystemMessage", properties)
	else
		local msg = msg
		if color then
			for i, v in ipairs(color) do
				color[i] = v*255;
			end
			
			msg = format('<font color="rgb('..concat(color, ",")..')">%s</font>', msg);
		end
		
		cloneref(game.GetService(game, "TextChatService")).TextChannels.RBXGeneral:DisplaySystemMessage(msg)
	end
end

-- library
local library = loadstring(game.HttpGet(game, "https://raw.githubusercontent.com/hxero/lua/main/wizard.lua"))();
local window = library.NewWindow(library, "Hxero's Animation UI");
local screengui = cloneref(game.GetService(game, "CoreGui")):WaitForChild("WizardLibrary");
screengui.Name = "hxero-animationgui"

-- sections
local mainSec = window:NewSection("Main");
local animSec = window:NewSection("Animation");

-- main
mainSec:CreateButton("Destroy UI", function()
	screengui:Destroy()
end)

-- animation
local animations = {}
for i, v in next, _G.HXEROAnimations do
	animations[#animations + 1] = i
end
table.sort(animations)

animSec:CreateDropdown("Package", {"Custom", table.unpack(animations)}, 1, function(value)
	_G.HXEROAnimType = value
end)

animSec:CreateButton("Toggle", function()
	_G.HXEROLoop = not _G.HXEROLoop -- toggle player.CharacterAdded connection for animation to re-run after death
	local a = _G.HXEROLoop and "enabled" or "disabled"
	systemMessage("R15 Animation "..a)
end)

animSec:CreateButton("Save Options", function()
	_G.HXEROSaveAnim() -- save as file for later
	systemMessage("Saved animation")
end)

animSec:CreateDropdown("Idle", animations, 1, function(value)
	_G.HXEROAnim.idle = value
	_G.HXEROAnim.idle2 = value
end)

animSec:CreateDropdown("walk", animations, 1, function(value)
	_G.HXEROAnim.walk = value
end)

animSec:CreateDropdown("Run", animations, 1, function(value)
	_G.HXEROAnim.run = value
end)

animSec:CreateDropdown("Jump", animations, 1, function(value)
	_G.HXEROAnim.jump = value
end)

animSec:CreateDropdown("Climb", animations, 1, function(value)
	_G.HXEROAnim.climb = value
end)

animSec:CreateDropdown("Fall", animations, 1, function(value)
	_G.HXEROAnim.fall = value
end)
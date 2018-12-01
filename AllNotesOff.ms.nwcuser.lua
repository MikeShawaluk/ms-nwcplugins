-- Version 0.1

--[[-----------------------------------------------------------------------------------------
This plugin plays an "all notes off" MIDI message, using the staff's channel and port.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)

local function _draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if not nwcdraw.isDrawing() then return w end
end

local function _play(t)
	nwcplay.midi(0, 'controller', 123, 0)
end

return {
	width = _draw,
	draw = _draw,
	play = _play,
}
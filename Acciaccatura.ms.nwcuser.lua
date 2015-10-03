-- Version 1.0

--[[-----------------------------------------------------------------------------------------
This plugin creates acciaccatura by drawing a slash on the stem of a plain grace note
(appoggiatura). The grace note receiving the slash must be unbeamed and eighth duration.

If Class is set to StaffSig, then multiple grace notes will receive the slash, 
up to the next Acciaccatura object occurrence. 
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()

local function draw_Acciaccatura(t)
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	local x, y, y1
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*.189
	nwcdraw.setPen('solid', penWidth)

	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found do
		repeat
			found = drawpos:find('next', 'note')
		until drawpos:isGrace() or not found
		
		if found and drawpos < nextObj and drawpos:isGrace() and drawpos:durationBase() == 'Eighth' and not drawpos:isBeamed() then
			x, y = drawpos:xyStemTip()
			y1 = y - drawpos:stemDir(0)*2.4 - 1
			nwcdraw.line(x-.3, y1, x+.7, y1+2)
		end
		if not isStaffSig then return end
	end
end

return {
	width = draw_Acciaccatura,
	draw = draw_Acciaccatura
}
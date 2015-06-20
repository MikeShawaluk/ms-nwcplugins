-- Version 0.1

--[[-----------------------------------------------------------------------------------------
Acciaccatura.ms

This object draws a slash on an unbeamed eighth (quaver) grace note.

--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...

local drawpos = nwcdraw.user

local function do_draw(t)
	while drawpos:find('next','note') and not drawpos:isGrace() do end
	if drawpos:isGrace() and drawpos:durationBase() == 'Eighth' and not drawpos:isBeamed() then
		local x,y = drawpos:xyStemTip()
		local y1 = y - drawpos:stemDir(0)*2.4 - 1
		nwcdraw.line(x-.3, y1, x+.7, y1+2)
	end
end

return {
	draw = do_draw
	}
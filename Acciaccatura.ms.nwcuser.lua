-- Version 0.95

--[[-----------------------------------------------------------------------------------------
This plugin creates acciaccatura by adding a slash to a grace note (appoggiatura). The grace note receiving
the slash must be unbeamed and eighth duration.
--]]-----------------------------------------------------------------------------------------

local drawpos = nwcdraw.user

local function draw_Acciaccatura(t)
	while drawpos:find('next', 'note') and not drawpos:isGrace() do end
	if drawpos:isGrace() and drawpos:durationBase() == 'Eighth' and not drawpos:isBeamed() then
        local _, my = nwcdraw.getMicrons()
	    local penWidth = my*.189
	    nwcdraw.setPen('solid', penWidth)
		local x, y = drawpos:xyStemTip()
		local y1 = y - drawpos:stemDir(0)*2.4 - 1
		nwcdraw.line(x-.3, y1, x+.7, y1+2)
	end
end

return {
	draw = draw_Acciaccatura
}
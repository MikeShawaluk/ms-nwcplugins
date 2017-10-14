-- Version 1.21

--[[-----------------------------------------------------------------------------------------
This plugin creates acciaccatura by drawing a slash on the stem of a plain grace note
(appoggiatura). The grace note receiving the slash must be unbeamed and eighth duration. The
plugin will optionally play the acciaccatura before the beat, when the grace note is muted
and a nonzero rate is specified.

If Class is set to StaffSig, then multiple grace notes will be processed, 
up to the next Acciaccatura object occurrence.

@Rate
The playback rate for the acciaccatura, expressed as the number of notes per whole note
duration. For example, 64 would correspond to a 1/64 note. A value of 0 disables playback,
which is the default.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()

local _spec = {
	{ id='Rate', label='Rate', type='float', default=0, min=0, max=128, step=1 },
}

local function _draw(t)
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
		
		if found and drawpos < nextObj and drawpos:isGrace() and drawpos:durationBase() == 'Eighth' and not drawpos:isBeamed() and not drawpos:isHidden() then
			x, y = drawpos:xyStemTip()
			y1 = y - drawpos:stemDir(0)*2.4 - 1
			nwcdraw.line(x-.3, y1, x+.7, y1+2)
		end
		found = found and isStaffSig
	end
end

local function _play(t)
	local isStaffSig = (t.Class == 'StaffSig')
	local play = nwcplay.user
	if t.Rate == 0 then return end
	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found do
		repeat
			found = play:find('next', 'note')
		until play:isGrace() or not found
		if found and play < nextObj and play:isGrace() and play:durationBase() == 'Eighth' and not play:isBeamed() and play:isMute() then
			local noteCount = play:noteCount()
			local duration = (4 * nwcplay.PPQ / t.Rate)
			local start = play:sppOffset() - duration
			for i = 1, noteCount do
				nwcplay.note(start, duration, nwcplay.getNoteNumber(play:notePitchPos(i)))
			end
		end
		found = found and isStaffSig
	end
end

return {
	spec = _spec,
	width = _draw,
	draw = _draw,
	play = _play,
}
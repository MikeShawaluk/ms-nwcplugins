-- Version 1.3

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
which is the default. Also note that the grace note must be muted for playback to occur.
@Style
Determines the style for the slash ornament on down-stem notes. Selecting "Upward" will render
the slash from lower left to upper right (the same as for up-stem notes), while selecting
"Downward" will render the slash from upper left to lower right.  The default is "Upward".
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()
local styleList = { 'Upward', 'Downward' }
local styleOffsets = {
	['Upward'] = { -0.3, 0, 0.7, 2 },
	['Downward'] = { -0.3, 2, 0.7, 0 },
}

local _spec = {
	{ id='Rate', label='Rate', type='float', default=0, min=0, max=128, step=1 },
	{ id='Style', label='Down-stem Style', type='enum', list=styleList, default=styleList[1] },
}

local function _draw(t)
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	local style = t.Style
	local x, y, sd, s
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
			sd = drawpos:stemDir(0)
			s = sd < 1 and styleOffsets[style] or styleOffsets['Upward']
			x, y = drawpos:xyStemTip()
			y = y - sd*2.4 - 1
			nwcdraw.line(x+s[1], y+s[2], x+s[3], y+s[4])
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
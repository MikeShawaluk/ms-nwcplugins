-- Version 1.0

--[[-----------------------------------------------------------------------------------------
This plugin draws cue noteheads in the positions of any blank note space noteheads on
a subsequent chord.

If Class is set to StaffSig, then multiple chords will be notated, up to the next object
occurrence.
@Size
Sets the size of the cue noteheads, as a percentage of normal notehead size. Range of values
is 50% to 90%, and the default setting is 70%.  The value can be increased/decreased by
pressing +/-.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()
local noteHeadChar = { Whole='i', Half='j', Other='k' }
local blankNoteHead = string.byte('z')

local _spec = {
    { id='Size', label='Notehead Size (%)', type='int', min=50, max=90, step=10, default=70 },
}

local function _draw(t)
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize() * t.Size*.01)
	local x, y, x1, noteHead
	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found do
		repeat
			found = drawpos:find('next', 'note')
		until not drawpos:isGrace() or not found
		
		if found and drawpos < nextObj then
			for i = 1, drawpos:noteCount() do
				x, y, noteHead = drawpos:xyNoteHead(i)
				if noteHead == blankNoteHead then
					x1 = drawpos:xyStemAnchor(drawpos:stemDir(i))
					nwcdraw.alignText('baseline', x1-x < .5 and 'left' or 'right')
					nwcdraw.moveTo(x1, y)
					nwcdraw.text(noteHeadChar[drawpos:durationBase(i)] or noteHeadChar.Other)
				end
			end
		end
		if not isStaffSig then return end
	end
end

local function _create(t)
	t.Class = 'StaffSig'
end

local function _spin(t, dir)
	t.Size = t.Size + dir * _spec[1].step
	t.Size = t.Size
end

return {
	create = _create,
	spin = _spin,
	width = _draw,
	draw = _draw,
	spec = _spec,
}
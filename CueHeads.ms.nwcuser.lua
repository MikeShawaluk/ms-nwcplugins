-- Version 0.3

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

local _spec = {
    { id='Size', label='Notehead Size (%)', type='int', min=50, max=90, step=10, default=70 },
}

local function drawNotehead(ptr, i, side)
	local noteHead = string.match(ptr:notePitchPos(i), '-?%d+(.)')
	if noteHead ~= 'z' then return end
	local dur = ptr:durationBase(i)
	local x, y = ptr:xyStemAnchor(ptr:stemDir(i))
	nwcdraw.alignText('baseline', side > 0 and 'left' or 'right')
	nwcdraw.moveTo(x, ptr:notePos(i))
	nwcdraw.text(dur == 'Whole' and 'i' or dur == 'Half' and 'j' or 'k')
end

local function drawCuesLoop(ptr, first, last, stemDir)
	local side, dist = -stemDir
	drawNotehead(ptr, first, side)
	if last ~= first then 
		for i = first+stemDir, last, stemDir do
			dist = (ptr:notePos(i) - ptr:notePos(i-stemDir))*stemDir
			if dist == 1 then
				side = -side
			elseif dist >= 2 then
				side = -stemDir
			end
			drawNotehead(ptr, i, side)
		end
	end

end

local function drawCues(ptr)
	local noteCount, first, last, stemDir = ptr:noteCount()
	if ptr:isSplitVoice() and ptr:objType() ~= 'RestChord' then
		local split
		for i=2, noteCount do
			if ptr:stemDir(i) ~= ptr:stemDir(i-1) then split = i end
		end
		drawCuesLoop(ptr, split, noteCount, 1)
		drawCuesLoop(ptr, split-1, 1, -1)
	else
		stemDir = ptr:stemDir(1)
		first, last = 1, noteCount
		if stemDir < 0 then first, last = last, first end
		drawCuesLoop(ptr, first, last, stemDir)
	end
end

local function _draw(t)
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize() * t.Size*.01)

	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found do
		repeat
			found = drawpos:find('next', 'note')
		until not drawpos:isGrace() or not found
		
		if found and drawpos < nextObj then
			drawCues(drawpos)
		end
		if not isStaffSig then return end
	end
end

local function _create(t)
	t.Class = 'StaffSig'
end

local function _spin(t, dir)
	t.Size = t.Size + dir*10
	t.Size = t.Size
end

return {
	create = _create,
	spin = _spin,
	width = _draw,
	draw = _draw,
	spec = _spec,
}
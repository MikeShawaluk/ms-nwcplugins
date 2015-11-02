-- Version 0.1

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
	local noteHead = string.sub(ptr:notePitchPos(i), -1)
	if noteHead ~= 'z' then return end
	local dur = ptr:durationBase(i)
	local x, y = ptr:xyStemAnchor()
	nwcdraw.alignText('baseline', side > 0 and 'left' or 'right')
	nwcdraw.moveTo(x, ptr:notePos(i))
	nwcdraw.text(dur == 'Whole' and 'i' or dur == 'Half' and 'j' or 'k')
end

local function drawCues(ptr)
	local sd, nc = ptr:stemDir(1), ptr:noteCount()
	local i1, i2 = 2, nc
	if sd < 0 then i1, i2 = i2-1, i1-1 end
	
	local side, dist = -sd
	drawNotehead(ptr, i1-sd, side)
	if nc > 1 then 
		for i = i1, i2, sd do
			dist = (ptr:notePos(i) - ptr:notePos(i-sd))*sd
			if dist == 1 then
				side = -side
			elseif dist >= 2 then
				side = -sd
			end
			drawNotehead(ptr, i, side)
		end
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
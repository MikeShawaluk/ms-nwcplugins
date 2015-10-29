-- Version 0.1

--[[-----------------------------------------------------------------------------------------
This plugin draws a bar tip on a Master Repeat Open or Close bar line.

If Class is set to StaffSig (which is the default), then multiple repeats will receive the ornament, 
up to the next RepeatWingTips object occurrence. 
@Scale
The scale factor for the size of the wings. This is a value from 50% to 200%; the
default setting is 100%. The + and - keys will increase/decrease the value by 10%.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()
local barTypes = { MasterRepeatOpen=true, MasterRepeatClose=true }

local spec_RepeatWingTips = {
    { id='Scale', label='Scale (%)', type='int', min=50, max=200, step=10, default=100 },
}

local function create_RepeatWingTips(t)
	t.Class = 'StaffSig'
end

local function drawWings(x, y, v, h, scale)
	local x2, y2 = x+h*1.5*scale, y + v*3*scale
	local xa, ya = (x+x2)*.5+h*.5*scale, (y+y2)*.5-v*scale
	local bw = .6
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.bezier(xa, ya, x2, y2)
	nwcdraw.bezier(xa, ya, x+bw*h, y)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local function draw_RepeatWingTips(t)
	local scale = t.Scale*.01
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	local x, y
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*.2
	nwcdraw.setPen('solid', penWidth)

	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found do
		repeat
			found = drawpos:find('next', 'bar')
		until barTypes[drawpos:objProp('Style')] or not found
		
		if found and drawpos < nextObj then
			local barType = drawpos:objProp('Style') or 'Single'
			if barType == 'MasterRepeatOpen' then
				x, y = drawpos:xyAnchor(-1)
				drawWings(x, y, -1, 1, scale)
				x, y = drawpos:xyAnchor(1)
				drawWings(x, y, 1, 1, scale)
			elseif barType == 'MasterRepeatClose' then
				x, y = drawpos:xyRight(-1)
				drawWings(x, y, -1, -1, scale)
				x, y = drawpos:xyRight(1)
				drawWings(x, y, 1, -1, scale)
			end
		end
		if not isStaffSig then return end
	end
end

local function spin_RepeatWingTips(t,d)
	t.Scale = t.Scale + d*10
	t.Scale = t.Scale
end

return {
	spec = spec_RepeatWingTips,
	spin = spin_RepeatWingTips,
	create = create_RepeatWingTips,
	width = draw_RepeatWingTips,
	draw = draw_RepeatWingTips,
}

-- Version 0.2

--[[-----------------------------------------------------------------------------------------
This plugin draws a bar tip on a Master Repeat Open or Close bar line.

If Class is set to StaffSig (which is the default), then multiple repeats will receive the ornament, 
up to the next RepeatWingTips object occurrence. 
@Scale
The scale factor for the size of the wings. This is a value from 50% to 200%; the
default setting is 100%. The + and - keys will increase/decrease the value by 10%.
@Location
Determines which locations to receive bar tips. Available options are Top, Bottom and Both,
and the default setting is Both.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextObj = nwc.ntnidx.new()
local barTypes = { MasterRepeatOpen=true, MasterRepeatClose=true }
local locationList = { 'Both', 'Top', 'Bottom' }
local scale

local spec_RepeatWingTips = {
    { id='Scale', label='Scale (%)', type='int', min=50, max=200, step=10, default=100 },
    { id='Location', label='Wing Location', type='enum', list=locationList, default=locationList[1] },
}

local function create_RepeatWingTips(t)
	t.Class = 'StaffSig'
end

local function drawWings(v, h)
	local x, y
	if h > 0 then
		x, y = drawpos:xyAnchor(v)
	else
		x, y = drawpos:xyRight(v)
	end
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
	local loc = t.Location
	scale = t.Scale*.01
	local isStaffSig = (t.Class == 'StaffSig')
	local w = isStaffSig and nwc.toolbox.drawStaffSigLabel(userObjSigName) or 0
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	local connectBars = nwcdraw.getStaffProp('ConnectBarsWithNext')
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*.2
	nwcdraw.setPen('solid', penWidth)

	if not nextObj:find('next', 'user', userObjTypeName) then nextObj:find('last') end
	local found = true
	while found and drawpos < nextObj do
		found = drawpos:find('next', 'bar')
		local barType = drawpos:objProp('Style')
		if barType == 'MasterRepeatOpen' then
			if loc ~= locationList[2] and not connectBars then drawWings(-1, 1) end
			if loc ~= locationList[3] then drawWings(1, 1) end
		elseif barType == 'MasterRepeatClose' then
			if loc ~= locationList[2] and not connectBars then drawWings(-1, -1) end
			if loc ~= locationList[3] then drawWings(1, -1) end
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

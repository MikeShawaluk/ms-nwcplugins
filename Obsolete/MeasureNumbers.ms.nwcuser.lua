-- Version 0.1

--[[--------------------------------------------------------------------------
This plugin creates measure number labels for a score. The numbering sequence can be restarting by inserting additional instances throughout the score.

@Start
The starting measure number, between 0 and 1000. The default value is 1.

@Current
The current measure number at the location of the custom object. This parameter will go away if/when I figure out how to determine the measure number of the custom object.

@Style
The style for measure numbers: None, Plain, Circled or Boxed (the same values as native measure numbers). The default is 'Plain'.

@Offset
An offset, allowing the vertical measure number position to be adjusted from its default position. The default is 0.

@Font
Font to be used for the measure numbers. It can be any of the Noteworthy system fonts. Default is StaffBold.

--]]--------------------------------------------------------------------------

local userObjTypeName = ...
local showInTargets = {edit=1, selector=1}
local objPtr = nwc.drawpos.new()
local user = nwcdraw.user

local function doPrintName(showAs)
	nwcdraw.setFont('Tahoma', 3, 'r')

	local xyar = nwcdraw.getAspectRatio()
	local w, h = nwcdraw.calcTextSize(showAs)
	local w_adj, h_adj = (h/xyar), (w*xyar)+3
	if not nwcdraw.isDrawing() then return w_adj+.2 end

	for i=1, 2 do
		nwcdraw.moveTo(-w_adj/2, 0)
		if i == 1 then
			nwcdraw.setWhiteout()
			nwcdraw.beginPath()
		else
			nwcdraw.endPath('fill')
			nwcdraw.setWhiteout(false)
			nwcdraw.setPen('solid', 150)
		end
		nwcdraw.roundRect(w_adj/2, h_adj/2, w_adj/2, 1)
	end

	nwcdraw.alignText('bottom', 'center')
	nwcdraw.moveTo(0, 0)
	nwcdraw.text(showAs, 90)
	return 0
end

local object_spec = {
	{ id='Start', label='Start Measure Number', type='int', default=1, min=0, max=1000 },
	{ id='Current', label='Current Measure Number', type='int', default=1, min=0, max=1000 },
	{ id='Style', label='Style', type='enum', default=nwc.txt.MeasureNumStyles[2], list=nwc.txt.MeasureNumStyles },
	{ id='Offset', label='Vertical Offset', type='float', default=0, min=-100, max=100 },
	{ id='Font', label='Font', type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
}

local function do_create(t)
	t.Class = 'StaffSig'
	t.Pos = 0
end

local function do_spin(t,d)
	t.Start = t.Start + d
	t.Start = t.Start
end

local function do_draw(t)
	local media = nwcdraw.getTarget()
	local w = 0;
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName('MeasureNumbers')
	end
	if not nwcdraw.isDrawing() then return w end
	
	local current = t.Current
	local start = t.Start
	user:find('prior', 'bar')
	local x,y = user:xyRight()

	local barNumber = user:barCounter()

	local number = barNumber + start - current + 1
	if number > 1 and t.Style ~= 'None' then
		nwcdraw.setFontClass(t.Font)
		nwcdraw.alignText('middle', 'center')

		nwcdraw.moveTo(x,y+9+t.Offset)
		if t.Style == 'Circled' then
			nwcdraw.ellipse(0.82)
		elseif t.Style == 'Boxed' then
			local w, h = nwcdraw.calcTextSize(number)
			nwcdraw.roundRect(w/2+.42, h/2+.67, 0, 0)
		end
		nwcdraw.text(number)		
	end

	
end

return {
	spec		= object_spec,
	create		= do_create,
	spin		= do_spin,
	width		= do_draw,
	draw		= do_draw
}

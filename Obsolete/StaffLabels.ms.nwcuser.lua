-- Version 0.1

--[[----------------------------------------------------------------
StaffLabels.ms

This object adds staff labels that can be changed on the fly.
--]]----------------------------------------------------------------

local userObjTypeName = ...
local drawpos = nwcdraw.user
local showInTargets = { edit=1, selector=1 }

local function doPrintName(showAs)
	nwcdraw.setFont('Arial', 3, 'b')

	local xyar = nwcdraw.getAspectRatio()
	local w,h = nwcdraw.calcTextSize(showAs)
	local w_adj, h_adj = h/xyar, (w*xyar)+2
	if not nwcdraw.isDrawing() then return w_adj end

	nwcdraw.alignText('baseline', 'left')
		
	nwcdraw.moveTo(0,0)
	nwcdraw.beginPath()
	nwcdraw.rectangle(-w_adj,-h_adj)
	nwcdraw.endPath('fill')

	nwcdraw.moveTo(0,0.5)
	nwcdraw.setWhiteout()
	nwcdraw.text(showAs,90)
	nwcdraw.setWhiteout(false)
	return 0
end

local obj_spec = {
	Class = { type='text', default='StaffSig' },
	Label = { type='text', default=''},
	LabelAbbr = { type='text', default='' },
	LongestLabel = { type='text', default='' },
	LongestLabelAbbr = { type='text', default='' },
	Font = { type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
	Offset = { type='float', default=0, min=0 }
}

local function do_create(t)
	t.Class = t.Class
	t.Label = t.Label
	t.LabelAbbr = t.LabelAbbr
	t.LongestLabel = t.LongestLabel
	t.LongestLabelAbbr = t.LongestLabelAbbr
	t.Font = t.Font
	t.Offset = t.Offset
end

local function do_draw(t)
	local media = nwcdraw.getTarget()
	local w = 0;
	
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName(userObjTypeName)
	end
	
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end

	local font = t.Font
	local offset = t.Offset
	
	drawpos:find('first')
	local x, y = drawpos:xyAnchor()
	nwcdraw.setFontClass(font)
	nwcdraw.alignText('middle', 'center')
	
	local l,o

	if nwcdraw.getPageCounter() == 1 and nwcdraw.getSystemCounter() == 1 then
		l = t.Label
		o = nwcdraw.calcTextSize(t.LongestLabel)/2
	else
		l = t.LabelAbbr
		o = nwcdraw.calcTextSize(t.LongestLabelAbbr)/2
	end
	nwcdraw.moveTo(x-offset-o, y)
	nwcdraw.text(l)	
end


return {
	spec = obj_spec,
	create = do_create,
	width = do_draw,
	draw = do_draw
	}
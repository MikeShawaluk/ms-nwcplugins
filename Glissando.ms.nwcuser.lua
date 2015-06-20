-- Version 0.1

--[[----------------------------------------------------------------
Glissando.ms

This will draw a glissando between two notes
--]]----------------------------------------------------------------

local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()

local spec_Gliss = {
	Pen = { type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	Text = { type='text', default='gliss.' }
}

local function sign(n)
	return n>0 and 1 or n<0 and -1 or 0
end

local function create_Gliss(t)
	t.Pen = t.Pen
	t.Text = t.Text
end

local function draw_Gliss(t)
	local xyar = nwcdraw.getAspectRatio()
	local pen = t.Pen
	local text = t.Text
	local thickness = 240
	local xo, yo = .25, .5
	
	if not priorNote:find('prior', 'note') then return end
	if not nextNote:find('next', 'note') then return end
	
	local x1, y1 = priorNote:xyRight()
	x1 = x1 + xo
	local y2 = nextNote:notePos(1)
	local x2 = -xo
	local s = sign(y1-y2)
	y1 = y1-yo*s
	y2 = y2+yo*s
	local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))
	if text ~= '' then
		nwcdraw.alignText('bottom', 'center')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*.75)
		nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
		nwcdraw.text(text, angle)
	end
	nwcdraw.setPen(pen, thickness)	
	nwcdraw.line(x1, y1, x2, y2)
end

return {
	spec = spec_Gliss,
	create = create_Gliss,
	draw = draw_Gliss
	}
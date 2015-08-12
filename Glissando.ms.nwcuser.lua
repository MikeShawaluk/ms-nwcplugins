-- Version 0.9

--[[----------------------------------------------------------------
This will draw a glissando line between two notes, with optional text above the line. If either of the notes is a chord, the bottom notehead
of that chord will be the starting or ending point of the line. It is strictly an ornament, and has no effect on playback.
@Pen
Specifies the line type: solid, dot or dash. The default setting is solid.
@Text
The text to appear above the glissando line, drawn in the StaffItalic system font. The default setting is "gliss."
@Scale
The scale factor for the text above the glissando line. This is a value from 5% to 400%, and the default setting is 75%.

The text scale factor can be incremented/decremented by selecting the object and pressing the + or - keys.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@Weight
This will adjust the weight (thickness) of the glissando line. The range of values is 0.0 to 5.0, where 1 is the standard line weight. The default setting is 1.
--]]----------------------------------------------------------------

local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()

local spec_Glissando = {
	{ id='Pen', label='Line Style', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Text', label='Text', type='text', default='gliss.' },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=75 },
    { id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 }
}

local function draw_Glissando(t)
	local xyar = nwcdraw.getAspectRatio()
    local _, my = nwcdraw.getMicrons()
	local pen = t.Pen
	local text = t.Text
	local thickness = my*.3*t.Weight
	local xo, yo = .25, .5
	
	if not priorNote:find('prior', 'note') then return end
	if not nextNote:find('next', 'note') then return end
	
	local x1 = priorNote:xyRight()
    local y1 = priorNote:notePos(1)
	x1 = x1 + xo + t.StartOffsetX
	local y2 = nextNote:notePos(1)
	local x2 = t.EndOffsetX - xo
    local s = y1>y2 and 1 or y1<y2 and -1 or 0
	y1 = y1 - yo*s + t.StartOffsetY
	y2 = y2 + yo*s + t.EndOffsetY
	local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))
	if text ~= '' then
		nwcdraw.alignText('bottom', 'center')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
		nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
		nwcdraw.text(text, angle)
	end
	nwcdraw.setPen(pen, thickness)	
	nwcdraw.line(x1, y1, x2, y2)
end

local function spin_Glissando(t, d)
	t.Scale = t.Scale + d*5
	t.Scale = t.Scale
end

return {
	spec = spec_Glissando,
    spin = spin_Glissando,
	draw = draw_Glissando
}
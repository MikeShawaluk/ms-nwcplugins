-- Version 1.0

--[[----------------------------------------------------------------
This object draws a crescendo or decresendo hairpin at a specified location on the score. The gap at the open
end, line type and weight are user adjustable, as well as the horizontal and vertical positions of the end points.
This object is ornamental only, and does not affect playback.

To add a hairpin, insert the user object immediately before the note/chord where you want the hairpin to start.
Position the object's marker to move the hairpin to the desired vertical location.
The default horizontal start and end position for the hairpin is 0.5 note spaces to the left of the starting
note, and 0.25 spaces to the right of the ending note.
@Type
The type of hairpin, cresc or decresc. The default value is cresc.
@Span
The number of notes or rests to include in the hairpin. The minimum value is 1, which is the default setting.
@Pen
The type of line to draw: solid, dash or dot. The default value is solid.
@StartOffsetX
This will adjust the horizontal (X) position of the hairpin's start point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the horizontal (X) position of the hairpin's end point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the vertical (Y) position of the hairpin's end point. Non-zero values will result
in an angled hairpin. The range of values is -100.00 to 100.00. The default setting is 0.
@Gap
This will adjust the size of the gap at the open end of the hairpin, in units of vertical note spacing.
The range of values is 0 to 100.0, and the default setting is 2.5.
@Weight
This is the line weight of the hairpin line. The range of values is 0 to 5.0, and the default setting is 1.0.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local typeList = { 'cresc', 'decresc' }

local spec_Hairpin = {
	{ id='Type', label='Type', type='enum', default=typeList[1], list=typeList },
	{ id='Span', label='Note Span', type='int', default=1, min=1, max=100 },
	{ id='Pen', label='Line Style', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Gap', label='Gap Height', type='float', default=2.5, min=0, max=100, step=0.5 },
	{ id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 },
}

local function draw_Hairpin(t)
	local _, my = nwcdraw.getMicrons()
	local pen = t.Pen
	local thickness = my*.3*t.Weight
	nwcdraw.setPen(pen, thickness)
	
	local hairpintype = t.Type
	local span = t.Span
	local leftoffset = t.StartOffsetX - 0.5
	local rightoffset_x, rightoffset_y = t.EndOffsetX+0.25, t.EndOffsetY
	local gap = t.Gap
	
	user:find('next', 'noteOrRest')
	if not user then return end
	local x1 = user:xyAnchor()
	
	while span > 1 do
		user:find('next', 'noteOrRest')
		span = span - 1
	end

	local x2 = rightoffset_x + user:xyRight()
	
	local leftgap, rightgap = 0, 0
	if hairpintype == typeList[1] then rightgap = gap / 2 else leftgap = gap / 2 end
	nwcdraw.line(x1+leftoffset, -leftgap, x2, rightoffset_y - rightgap)
	nwcdraw.line(x1+leftoffset, leftgap, x2, rightoffset_y + rightgap)
end

local function spin_Hairpin(t, dir)
	t.Span = t.Span + dir
	t.Span = t.Span
end

return {
	spin = spin_Hairpin,
	spec = spec_Hairpin,
	draw = draw_Hairpin
}
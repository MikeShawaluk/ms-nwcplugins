local user = nwcdraw.user

local spec_Hairpin = {
	{ id='Type', label='Type', type='enum', default='cresc', list={ 'cresc', 'decresc' } },
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
	if hairpintype == 'cresc' then rightgap = gap / 2 else leftgap = gap / 2 end
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
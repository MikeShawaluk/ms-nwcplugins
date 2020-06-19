-- Version 1.2

--[[----------------------------------------------------------------
This object draws a crescendo or decrescendo hairpin at a specified location on the score. The gap at the open
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
@Gap2
This will adjust the size of the gap at the closed end of the hairpin, in units of vertical note spacing.
The range of values is 0 to 100.0, and the default setting is 0.
@Weight
This is the line weight of the hairpin line. The range of values is 0 to 5.0, and the default setting is 1.0.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local typeList = { 'cresc', 'decresc' }

local spec_Hairpin = {
	{ id='Span', label='&Note Span', type='int', default=1, min=1, max=100, step=1 },
	{ id='Type', label='&Type', type='enum', default=typeList[1], list=typeList },
	{ id='Pen', label='Line &Style', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='StartOffsetX', label='St&art Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset &X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset &Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Gap', label='&Open Gap Height', type='float', default=2.5, min=0, max=100, step=0.5 },
	{ id='Gap2', label='C&losed Gap Height', type='float', default=0, min=0, max=100, step=0.5 },
	{ id='Weight', label='Line &Weight', type='float', default=1, min=0, max=5, step=0.1 },
}

local menu_Hairpin = {
	{ type='command', name='Choose Spin Target:', disable=true }
}

for k, s in ipairs(spec_Hairpin) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type ~= 'enum' then
		a.separator = k == 1
		a.type = 'command'
		menu_Hairpin[#menu_Hairpin+1] = a
	end
end
for k, s in ipairs(spec_Hairpin) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'enum' then
		a.separator = k == 2
		a.type = 'choice'
		a.list = s.list
		menu_Hairpin[#menu_Hairpin+1] = a
	end
end

local function menuInit_Hairpin(t)
	local ap = tonumber(t.ap)
	for k, m in ipairs(menu_Hairpin) do
		if m.data then
			local s = spec_Hairpin[m.data]
			local v = t[s.id]
			if m.type == 'command' then
				m.checkmark = (k == ap)
				m.name = string.format('%s (%s)', s.label, v)
			else
				m.default = v
			end
		end
	end
end

local function menuClick_Hairpin(t, menu, choice)
	if choice then
		local m = menu_Hairpin[menu]
		local s = spec_Hairpin[m.data]
		t[s.id] = m.list[choice]
	else
		t.ap = menu
	end
end

local function box(x, y, p1, p2, p3, ap)
	local m = (ap == p1 or ap == p2 or ap == p3) and 'strokeandfill' or 'stroke'
	nwcdraw.setPen('solid', 100)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.roundRect(0.2)
	nwcdraw.endPath(m)
end

local function draw_Hairpin(t)
	local _, my = nwcdraw.getMicrons()
	local pen = t.Pen
	local thickness = my*.3*t.Weight
	nwcdraw.setPen(pen, thickness)
	
	local hairpintype = t.Type
	local span = t.Span
	local leftoffset = t.StartOffsetX - 0.5
	local rightoffset_x, rightoffset_y = t.EndOffsetX+0.25, t.EndOffsetY
	local gap, gap2 = t.Gap, t.Gap2
	
	user:find('next', 'noteOrRest')
	if not user then return end
	local x1 = user:xyAnchor()
	
	while span > 1 do
		user:find('next', 'noteOrRest')
		span = span - 1
	end

	local x2 = rightoffset_x + user:xyRight()
	
	local leftgap, rightgap = gap / 2, gap2 / 2 
	if hairpintype == typeList[1] then
		rightgap, leftgap = leftgap, rightgap
	end
	nwcdraw.line(x1+leftoffset, -leftgap, x2, rightoffset_y - rightgap)
	nwcdraw.line(x1+leftoffset, leftgap, x2, rightoffset_y + rightgap)
	
	if t.ap then
		local ap = tonumber(t.ap)
		local gl = hairpintype == typeList[1] and 6 or 0
		local gr = hairpintype ~= typeList[1] and 6 or 0
		box(x1+leftoffset, -leftgap, 3, 0, gr, ap)
		box(x1+leftoffset, leftgap, 3, 0, gr, ap)
		box(x2, rightoffset_y - rightgap, 4, 5, gl, ap)
		box(x2, rightoffset_y + rightgap, 4, 5, gl, ap)
	end
	
end

local function spin_Hairpin(t, d)
	t.ap = t.ap or 2
	local y = menu_Hairpin[tonumber(t.ap)].data
	local x = spec_Hairpin[y].id
	t[x] = t[x] + d*spec_Hairpin[y].step
	t[x] = t[x]
end

local function audit_Hairpin(t)
	t.ap = nil
end

return {
	spin = spin_Hairpin,
	spec = spec_Hairpin,
	draw = draw_Hairpin,
	menu = menu_Hairpin,
	menuInit = menuInit_Hairpin,
	menuClick = menuClick_Hairpin,
	audit = audit_Hairpin,
}

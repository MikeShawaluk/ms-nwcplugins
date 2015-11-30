-- Version 0.1

--[[----------------------------------------------------------------
This plugin draws a solid, dashed or dotted cubic slur with adjustable end point positions and curve shape. 
It offers improved shape shape control over Slur.ms. This object is ornamental only, and does not affect playback.

To add a slur, insert the user object immediately before the note/chord where you want the slur to start. 
The slur object will detect the starting and ending chords' position, duration, stem direction and slur direction 
settings, and will determine curvature strength, direction and end points that are appropriate for most 
situations. These settings can be overridden by use of various parameters.
@Span
The number of notes/chords to include in the slur. The minimum value is 2, which is the default setting.
@Pen
The type of line to draw for the slur: solid, dash or dot. The solid line type will create a shaped Bezier 
curve that is thinner at the end points, similar in appearance to regular Noteworthy slurs. The dot and dash 
line types are drawn with a uniform line thickness. The default value is solid.
@Dir
The direction of the slur: Default, Upward or Downward. When set to Default, the slur will take its direction 
from the starting note's Slur Direction property, which in turn is based on the stem directions of the starting 
and ending notes. When set to Upward or Downward, the slur direction is set explicitly.

Note that upward slurs are positioned at the top notes of the starting and ending chords, while downward 
slurs are positioned at the bottom notes. For starting or ending rests, the default endpoints will be the same
as for normal slurs.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the slur's start point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the slur's start point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the slur's end point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the slur's end point. The range of values 
is -100.00 to 100.00. The default setting is 0.
@LeftStrength
This will adjust the strength (shape) of the left side of the curve. The range of values is 0.00 to 100.00, where a value 
of 1 is the auto-determined curve strength. Lower values will result in a shallower curve, and stronger 
values a steeper curve. A value of 0 results in a straight line. The default setting is 1.
@RightStrength
This will adjust the strength (shape) of the right side of the curve. See the description for Left Strength
for more information.
@LeftBalance
This will adjust the balance of the left side of the curve. The range of values is 0 to 1.0, where a value 
of 0.5 is the default setting.
@RightBalance
This will adjust the balance of the right side of the curve. The range of values is 0 to 1.0, where a value 
of 0.5 is the default setting.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local dirList = { 'Default', 'Upward', 'Downward' }
local dirNum = { Default=0, Upward=1, Downward=-1 }

local spec_Slur = {
	{ id='Span', label='&Note Span', type='int', default=2, min=2, step=1 },
	{ id='Pen', label='&Line Type', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Dir', label='&Direction', type='enum', default='Default', list=dirList },
	{ id='StartOffsetX', label='Start Offset &X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset &Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset &X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset &Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='LeftStrength', label='Left &Strength', type='float', default=1, min=0, max=100, step=0.25 },
	{ id='LeftBalance', label='Left &Balance', type='float', default=0.5, min=0, max=1, step=0.05 },
	{ id='RightStrength', label='Right &Strength', type='float', default=1, min=0, max=100, step=0.25 },
	{ id='RightBalance', label='Right &Balance', type='float', default=0.5, min=0, max=1, step=0.05 },
}

local menu_Slur = {
	{ type='command', name='Choose Spin Target:', disable=true }
}

for k, s in ipairs(spec_Slur) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type ~= 'enum' then
		a.separator = k == 1
		a.type = 'command'
		menu_Slur[#menu_Slur+1] = a
	end
end
for k, s in ipairs(spec_Slur) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'enum' then
		a.separator = k == 2
		a.type = 'choice'
		a.list = s.list
		menu_Slur[#menu_Slur+1] = a
	end
end


local function menuInit_Slur(t)
	local ap = tonumber(t.ap)
	for k, m in ipairs(menu_Slur) do
		if m.data then
			local s = spec_Slur[m.data]
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

local function menuClick_Slur(t, menu, choice)
	if choice then
		local m = menu_Slur[menu]
		local s = spec_Slur[m.data]
		t[s.id] = m.list[choice]
	else
		t.ap = menu
	end
end

local function value(t, x1, x2, x3, x4)
	return (1-t)^3 * x1 + 3*(1-t)^2*t * x2 + 3*(1-t)*t^2 * x3 + t^3 * x4
end

local function point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	return value(t, x1, x2, x3, x4), value(t, y1, y2, y3, y4)
end

local function box(x, y, p1, p2, ap)
	local m = (ap == p1 or ap == p2) and 'strokeandfill' or 'stroke'
	nwcdraw.setPen('solid', 100)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.roundRect(0.2)
	nwcdraw.endPath(m)
end

local function noteStuff(item, slurDir)
	local opts = item:objProp('Opts') or ''
	local stem, slur, baseNote, dotted
	local slurNote = 1
	if item:isSplitVoice() and item:objType() ~= 'RestChord' then
		slur = slurDir == 0 and item:stemDir() or slurDir
		if slur == 1 then slurNote = item:noteCount() end
		stem = item:stemDir(slurNote)
		baseNote, dotted = item:durationBase(slurNote), item:isDotted(slurNote)
	else
		stem = item:stemDir()
		baseNote, dotted = item:durationBase(), item:isDotted()
		slur = slurDir == 0 and (dirNum[opts:match('Slur=(%a+)')] or -stem) or slurDir 
	end
	local arcPitch, noteheadOffset = 3.75, .5
	if baseNote == 'Whole' and dotted then
		arcPitch, noteheadOffset = 7.75, .65
	elseif baseNote == 'Whole' then
		arcPitch, noteheadOffset = 5.75, .65
	elseif baseNote == 'Half' then
		arcPitch = 5.75
	end
	return stem, slur, arcPitch, noteheadOffset, baseNote
end

local function draw_Slur(t)
	local _, my = nwcdraw.getMicrons()
	local solidPenWidth, dotDashPenWidth = my*0.12, my*.375
	local span = t.Span
	local pen = t.Pen
	local dir = dirNum[t.Dir]
	local leftStrength, rightStrength = t.LeftStrength*.65, t.RightStrength*.65
	local leftBalance, rightBalance = t.LeftBalance*.5, t.RightBalance*.5 + .5
	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	startNote:find('next', 'noteOrRest')
	for i = 1, span do
		if not endNote:find('next', 'noteOrRest') then break end
	end
	local startStem, slurDir, ya, xo1, startNotehead = noteStuff(startNote, dir)
	local endStem, _, _, xo2, endNotehead = noteStuff(endNote, slurDir)

	if dir ~= 0 then slurDir = dir end
	local x1, y1, x2, y2
	local startObjType, endObjType = startNote:objType(), endNote:objType()
	if startObjType == 'Rest' then
		local xl, yl = startNote:xyAnchor()
		local xr, yr = startNote:xyRight()
		x1, y1 = (xl + xr) * .5 + startOffsetX, yl + startOffsetY + slurDir * 4
	elseif startObjType == 'RestChord' and startStem == slurDir then
		local xl, yl = startNote:xyAnchor(startStem)
		local xr, yr = startNote:xyRight(startStem)
		x1, y1 = (xl + xr) * .5 + startOffsetX, yl + startOffsetY + slurDir * 2
	else
		local startNoteYBottom, startNoteYTop = startNote:notePos(1) or 0, startNote:notePos(startNote:noteCount()) or 0
		x1 = startNote:xyStemAnchor(startStem) or startNote:xyRight(startStem)
		if (slurDir == -1 and startStem == 1) or (slurDir == 1 and startStem == 1 and startNotehead == 'Whole') then xo1 = -xo1 end
		x1 = x1 + startOffsetX + xo1
		y1 = (slurDir == 1) and startNoteYTop + startOffsetY + 1.75 or startNoteYBottom - startOffsetY - 1.75
	end
	if endObjType == 'Rest' then
		local xl, yl = endNote:xyAnchor()
		local xr, yr = endNote:xyRight()
		x2, y2 = (xl + xr) * .5 + endOffsetX, yl + endOffsetY + slurDir * 4
	elseif endObjType == 'RestChord' and endStem == slurDir then
		local xl, yl = endNote:xyAnchor(endStem)
		local xr, yr = endNote:xyRight(endStem)
		x2, y2 = (xl + xr) * .5 + endOffsetX, yl + endOffsetY + slurDir * 2
	else
		local endNoteYBottom, endNoteYTop = endNote:notePos(1) or 0, endNote:notePos(endNote:noteCount()) or 0
		x2 = endNote:xyStemAnchor(endStem) or endNote:xyAnchor(endStem)
		if (slurDir == 1 and endStem == -1) or (slurDir == 1 and endStem == -1 and endNotehead == 'Whole') then xo2 = -xo2 end
		x2 = x2 + endOffsetX - xo2
		y2 = (slurDir == 1) and endNoteYTop + endOffsetY + 1.75 or endNoteYBottom - endOffsetY - 1.75
	end
	local xa1 = x1 + (x2-x1) * leftBalance
	local ya1 = y1 + (y2-y1) * leftBalance + slurDir * ya * leftStrength
	local xa2 = x1 + (x2-x1) * rightBalance
	local ya2 = y1 + (y2-y1) * rightBalance + slurDir * ya * rightStrength
	nwcdraw.moveTo(x1, y1)
	if t.Pen == 'solid' then
		local bw = startNote:isGrace() and .13 or .2
		nwcdraw.setPen(t.Pen, solidPenWidth)
		nwcdraw.beginPath()
		nwcdraw.bezier(xa1, ya1+bw, xa2, ya2+bw, x2, y2)
		nwcdraw.bezier(xa2, ya2-bw, xa1, ya1-bw, x1, y1)
		nwcdraw.endPath()
	else
		nwcdraw.setPen(t.Pen, dotDashPenWidth)
		nwcdraw.bezier(xa1, ya1, xa2, ya2, x2, y2)
	end
	if t.ap then
		local ap = tonumber(t.ap)
		local xb1, yb1 = point(0.1+(0.8*leftBalance), x1, y1, xa1, ya1, xa2, ya2, x2, y2)
		local xb2, yb2 = point(0.1+(0.8*rightBalance), x1, y1, xa1, ya1, xa2, ya2, x2, y2)
		box(x1, y1, 3, 4, ap)
		box(xb1, yb1, 7, 8, ap)
		box(xb2, yb2, 9, 10, ap)
		box(x2, y2, 5, 6, ap)
	end
end

local function spin_Slur(t, d)
	t.ap = t.ap or 2
	local y = menu_Slur[tonumber(t.ap)].data
	local x = spec_Slur[y].id
	t[x] = t[x] + d*spec_Slur[y].step
	t[x] = t[x]
end

local function audit_Slur(t)
	t.ap = nil
end

return {
	spec = spec_Slur,
	spin = spin_Slur,
	draw = draw_Slur,
	menu = menu_Slur,
	menuInit = menuInit_Slur,
	menuClick = menuClick_Slur,
	audit = audit_Slur,
}

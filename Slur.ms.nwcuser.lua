-- Version 1.51x

--[[----------------------------------------------------------------
This plugin draws a solid, dashed or dotted slur with adjustable end point positions and curve shape. 
It can be used for special situations where a normal slur does not work well, such as a slur-within-a-slur, or for 
"conditional" slurs for different verses on a vocal staff. This object is ornamental only, and does not affect playback.

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
@Strength
This will adjust the strength (shape) of the curve. The range of values is 0.00 to 10.00, where a value 
of 1 is the auto-determined curve strength. Lower values will result in a shallower curve, and stronger 
values a steeper curve. A value of 0 results in a straight line. The default setting is 1.
@Balance
This will adjust the left-right balance of the curve. The range of values is -.50 to +.50, where a value 
of 0 is the default (center) balance setting.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local dirList = { 'Default', 'Upward', 'Downward' }
local dirNum = { Default=0, Upward=1, Downward=-1 }
local paramNameList = { '&Span', 'Start Offset &X', 'Start Offset &Y', 'End Offset &X', 'End Offset &Y', 'S&trength', '&Balance' }
local paramIdList = { 'Span', 'StartOffsetX', 'StartOffsetY', 'EndOffsetX', 'EndOffsetY', 'Strength', 'Balance' }
local paramIncList = { 1, .1, .1, .1, .1, .25, .05 }

local menu_Slur = {
	{ type='choice', name='&Adjust Parameter', default=nil, list=nil, disable=false },
}

local function menuInit_Slur(t)
	local ap = tonumber(t.ap)
	menu_Slur[1].list = {}
	for k, v in ipairs(paramIdList) do
		menu_Slur[1].list[k] = string.format('%s (%s)', paramNameList[k], t[v])
	end
	menu_Slur[1].default = menu_Slur[1].list[ap]
end

local function menuClick_Slur(t, menu, choice)
	t.ap = choice
end

local spec_Slur = {
	{ id='Span', label='Note Span', type='int', default=2, min=2 },
	{ id='Pen', label='Line Type', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Dir', label='Direction', type='enum', default='Default', list=dirList },
	{ id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Strength', label='Strength', type='float', default=1, min=0, max=10, step=0.25 },
	{ id='Balance', label='Balance', type='float', default=0, min=-.5, max=.5, step=0.05 },
}

local boxTable = {
	{ 2, 3 },
	{ 6, 7 },
	{ 4, 5 },
}

local function value(t, x1, x2, x3)
	return (1-t)^2 * x1 + 2*(1-t)*t * x2 + t^2 * x3
end

local function point(t, x1, y1, x2, y2, x3, y3)
	return
		value(t, x1, x2, x3),
		value(t, y1, y2, y3)
end

local function box(x, y, which, t, dir)
	local ap = tonumber(t.ap)
	local bt = boxTable[which]
	local m = (ap == bt[1] or ap == bt[2]) and 'strokeandfill' or 'stroke'
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
	local strength = t.Strength
	local balance = t.Balance + .5
	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	startNote:find('next', 'noteOrRest')
	for i = 1, span do
		if not endNote:find('next', 'noteOrRest') then return end
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
	local xa = x1 + (x2-x1) * balance
	ya = y1 + (y2-y1) * balance + slurDir * ya * strength
	nwcdraw.moveTo(x1, y1)
	if t.Pen == 'solid' then
		local bw = startNote:isGrace() and .2 or .3
		nwcdraw.setPen(t.Pen, solidPenWidth)
		nwcdraw.beginPath()
		nwcdraw.bezier(xa, ya+bw, x2, y2)
		nwcdraw.bezier(xa, ya-bw, x1, y1)
		nwcdraw.endPath()
	else
		nwcdraw.setPen(t.Pen, dotDashPenWidth)
		nwcdraw.bezier(xa, ya, x2, y2)
	end
	if t.ap then
		local xb, yb = point(balance, x1, y1, xa, ya, x2, y2)
		box(x1, y1, 1, t, slurDir)
		box(xb, yb, 2, t, slurDir)
		box(x2, y2, 3, t, slurDir)
	end
end

local function spin_Slur(t, d)
	local ap = tonumber(t.ap) or 1
	local x = paramIdList[ap]
	t[x] = t[x] + d*paramIncList[ap]
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

-- Version 2.0a

--[[----------------------------------------------------------------
This plugin draws a solid, dashed or dotted cubic Bezier slur with adjustable end point positions and curve shape. 
It offers improved shape shape control over Slur.ms. This object is ornamental only, and does not affect playback.

To add a slur, insert the user object immediately before the note/chord where you want the slur to start. 
The slur object will detect the starting and ending chords' position, duration, stem direction and slur direction 
settings, and will determine curvature strength, direction and end points that are appropriate for most 
situations. These settings can be overridden by use of various parameters.
@Span
The number of notes/chords to include in the slur. The minimum value is 2, which is the default setting.
@Pen
The type of line to draw for the slur: solid, dash or dot. The solid line type will create a shaped Bezier 
curve that is thinner at the end points, similar in appearance to regular slurs. The dot and dash 
line types are drawn with a uniform line thickness. The default value is solid.
@Dir
The direction of the slur: Default, Upward or Downward. When set to Default, the slur will take its direction 
from the starting note's Slur Direction property, which in turn is based on the stem directions of the starting 
and ending notes. When set to Upward or Downward, the slur direction is set explicitly.

Note that upward slurs are positioned at the top notes of the starting and ending chords, while downward 
slurs are positioned at the bottom notes. For starting or ending rests, the default endpoints will be the same
as for regular slurs.
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

if nwcut then
	local userObjTypeName = arg[1]
	local span = 0

	local score = nwcut.loadFile()
	
	local function calculateSpan(o)
		if not o:IsFake() and o:IsNoteRestChord() then
			span = span + 1
		end
	end
	
	local function addSlur(o)
		if span and not o:IsFake() then
			local o2 = nwcItem.new('|User|'..userObjTypeName)
			o2.Opts.Pos = 0
			o2.Opts.Span = span + 1
			span = false
			return { o2, o }
		end
	end
	
	score:forSelection(calculateSpan)
	if span > 0 then
		score:forSelection(addSlur)
		score:save()
	else
		nwcut.msgbox('No notes/rests found in selection')
	end

	return
end

local idx = nwc.ntnidx
local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local dirTable = {
	{ 'Default', 0 }, 
	{ 'Upward', 1 },
	{ 'Downward', -1 }
}
local showBoxes = { edit=true }
local dirList = {}
local dirNum = {}

for _, v in ipairs(dirTable) do
	dirList[#dirList+1] = v[1]
	dirNum[v[1]] = v[2]
end

local _nwcut = {
	['Add cubic slur'] = 'ClipText',
}

local _spec = {
	{ id='Span', label='&Note Span', type='int', default=2, min=2, step=1 },
	{ id='Pen', label='&Line Type', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Dir', label='&Direction', type='enum', default='Default', list=dirList },
	{ id='StartOffsetX', label='Start Offset &X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset &Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End &Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End O&ffset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='LeftStrength', label='Left &Strength', type='float', default=1, min=0, max=100, step=0.1 },
	{ id='LeftBalance', label='Left &Balance', type='float', default=0.5, min=0, max=1, step=0.05 },
	{ id='RightStrength', label='Right S&trength', type='float', default=1, min=0, max=100, step=0.1 },
	{ id='RightBalance', label='Right B&alance', type='float', default=0.5, min=0, max=1, step=0.05 },
}

local _spec2 = {}
local _menu = {}

for k, s in ipairs(_spec) do
	_spec2[s.id] = k
	if s.type == 'enum' then
		_menu[#_menu+1] = {	type='choice', name=s.label, list=s.list, data=k }
	end
end

local function _menuInit(t)
	for k, m in ipairs(_menu) do
		local s = _spec[m.data]
		if s then
			local v = t[s.id]
			m.default = v
		end
	end
end

local function _menuClick(t, menu, choice)
	if choice then
		local m = _menu[menu]
		local s = _spec[m.data]
		t[s.id] = m.list[choice]
	end
end

local function value(t, x1, x2, x3, x4)
	return (1-t)^3 * x1 + 3*(1-t)^2*t * x2 + 3*(1-t)*t^2 * x3 + t^3 * x4
end

local function point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	return value(t, x1, x2, x3, x4), value(t, y1, y2, y3, y4)
end

local function box(x, y, ap, p)
	local m = (ap == p) and 'strokeandfill' or 'stroke'
	nwcdraw.setPen('solid', 100)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.roundRect(0.2)
	nwcdraw.endPath(m)
end

local function noteStuff(item, slurDir)
	local opts = item:objProp('Opts') or ''
	local stem, slur, baseNote, dotted, duration
	local slurNote = 1
	if item:isSplitVoice() then
		if item:objType() == 'RestChord' then
			stem = item:stemDir(slurNote)
			slur = slurDir == 0 and -stem or slurDir
			if slur == 1 then slurNote = item:noteCount() end
		else
			slur = slurDir == 0 and item:stemDir() or slurDir
			if slur == 1 then slurNote = item:noteCount() end
			stem = item:stemDir(slurNote)
		end
		baseNote, dotted, duration = item:durationBase(slurNote), item:isDotted(), item:durationBase()
	else
		stem = item:stemDir() or 1
		baseNote, dotted, duration = item:durationBase(), item:isDotted(), item:durationBase()
		slur = slurDir == 0 and (dirNum[opts:match('Slur=(%a+)')] or -stem) or slurDir 
	end
	local arcPitch, noteheadOffset = 3.75, .5
	if duration == 'Whole' and dotted then
		arcPitch, noteheadOffset = 7.75, .65
	elseif duration == 'Whole' then
		arcPitch, noteheadOffset = 5.75, .65
	elseif duration == 'Half' then
		arcPitch = 5.75
	end
	return stem, slur, arcPitch, noteheadOffset, baseNote
end

local function _draw(t)
	local _, my = nwcdraw.getMicrons()
	local solidPenWidth, dotDashPenWidth = my*0.12, my*.375
	local span = t.Span
	local pen = t.Pen
	local dir = dirNum[t.Dir]
	local leftStrength, rightStrength = t.LeftStrength*.65, t.RightStrength*.65
	local leftBalance, rightBalance = t.LeftBalance*.5, t.RightBalance*.5 + .5
	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	if not startNote:find('next', 'noteOrRest') then return end
	for i = 1, span do
		if not endNote:find('next', 'noteOrRest') then break end
	end
	if startNote:indexOffset() == endNote:indexOffset() then return end
	local startStem, slurDir, ya, xo1, startNotehead = noteStuff(startNote, dir)
	local endStem, _, _, xo2, endNotehead = noteStuff(endNote, slurDir)

	if dir ~= 0 then slurDir = dir end
	local x1, y1, x2, y2
	local startObjType, endObjType = startNote:objType(), endNote:objType()
	if startObjType == 'Rest' then
		local xl, yl = startNote:xyAnchor()
		local xr, yr = startNote:xyRight()
		x1, y1 = (xl + xr) * .5 + startOffsetX, yl + startOffsetY + slurDir * 4
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
	if t.ap and showBoxes[nwcdraw.getTarget()] then
		local ap = tonumber(t.ap)
		local xb1, yb1 = point(0.05+(0.85*leftBalance), x1, y1, xa1, ya1, xa2, ya2, x2, y2)
		local xb2, yb2 = point(0.1+(0.85*rightBalance), x1, y1, xa1, ya1, xa2, ya2, x2, y2)
		box(x1, y1, ap, 1)
		box(xb1, yb1, ap, 2)
		box(xb2, yb2, ap, 3)
		box(x2, y2, ap, 4)
	end
end

local function _audit(t)
	t.ap = nil
end

local paramTable = {
	{ _spec2.StartOffsetX, _spec2.StartOffsetY },
	{ _spec2.LeftBalance, _spec2.LeftStrength },
	{ _spec2.RightBalance, _spec2.RightStrength },
	{ _spec2.EndOffsetX, _spec2.EndOffsetY },
}

local function toggleParam(t)
	local ap = tonumber(t.ap) or #paramTable
	ap = ap % #paramTable + 1
	t.ap = ap
end

local function getSlurDir(t)
	idx:find('next', 'noteOrRest')
	local _, slurDir = noteStuff(idx, dirNum[t.Dir])
	return slurDir
end

local function updateParam(t, p, dir)
	local s = _spec[p]
	local x = s.id
	t[x] = t[x] + dir*s.step
	t[x] = t[x]
end
	
local function updateActiveParam(t, n, dir)
	if n == 2 then
		dir = dir * getSlurDir(t)
	end
	local ap = tonumber(t.ap)
	if ap then 
		updateParam(t, paramTable[ap][n], dir)
	end
end

local function updateEnds(t, dir)
	dir = dir * getSlurDir(t)
	updateParam(t, _spec2.StartOffsetY, dir)
	updateParam(t, _spec2.EndOffsetY, dir)
end

local skip = { Span=true, Pen=true, Dir=true }

local function defaultParams(t)
	for k, s in ipairs(_spec) do
		if not skip[s.id] then t[s.id] = t[s.default] end
	end
end

local function defaultCurrentParam(t)
	local ap = tonumber(t.ap)
	if ap then
		for i = 1, 2 do
			local s = _spec[paramTable[ap][i]]
			t[s.id] = s.default
		end
	end
end

local charTable = {
	['+'] = { updateParam, _spec2.Span, 1 },
	['-'] = { updateParam, _spec2.Span, -1 },
	['8'] = { updateActiveParam, 2, 1 },
	['6'] = { updateActiveParam, 1, 1 },
	['4'] = { updateActiveParam, 1, -1 },
	['2'] = { updateActiveParam, 2, -1 },
	['9'] = { updateEnds, 1 },
	['3'] = { updateEnds, -1 },
	['5'] = { toggleParam },
	['0'] = { defaultCurrentParam },
	['Z'] = { defaultParams },
}

local function _onChar(t, c)
	local x = string.char(c)
	local ptr = charTable[x]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end

return {
	nwcut = _nwcut,
	spec = _spec,
	draw = _draw,
	menu = _menu,
	menuInit = _menuInit,
	menuClick = _menuClick,
	audit = _audit,
	onChar = _onChar,
}

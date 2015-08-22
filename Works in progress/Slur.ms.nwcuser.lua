-- Version 0.96x

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
slurs are positioned at the bottom notes.
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
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()

local dtt = { int='#[%s,%s]', float='#.#[%s,%s]' }

local menu_Slur = {}

local spec_Slur = {
	{ id='Span', label='Note Span', type='int', default=2, min=2 },
	{ id='Pen', label='Line Type', type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	{ id='Dir', label='Direction', type='enum', default='Default', list=nwc.txt.TieDir },
	{ id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Strength', label='Strength', type='float', default=1, min=0, max=10, step=0.5 },
}

for k, s in ipairs(spec_Slur) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'bool' then
		a.type = 'command'
	else
		a.type = 'choice'
		a.list = s.type == 'enum' and s.list or { '', 'Change...' }
	end
	menu_Slur[#menu_Slur+1] = a
end

local function menuInit_Slur(t)
	for _, m in ipairs(menu_Slur) do
		local s = spec_Slur[m.data]
		local v = t[s.id]
		if m.type == 'command' then
			m.checkmark = v
		else
			if s.type ~= 'enum' then
				m.list[1] = v
			end
			m.default = v
		end
	end
end

local function menuClick_Slur(t, menu, choice)
	local m = menu_Slur[menu]
	local s = spec_Slur[m.data]
	local v = t[s.id]
	if m.type == 'command' then
		t[s.id] = not v
	else
		if s.type == 'enum' then
			t[s.id] = m.list[choice]
		elseif choice ~= 1 then
			local dt = s.type == 'text' and '*' or string.format(dtt[s.type], s.min or -100, s.max or 100)
			t[s.id] = nwcui.prompt(string.format('Enter %s:', string.gsub(s.label, '&', '')), dt, v)
		end
	end
end

local function noteStuff(item)
	local opts = item:objProp('Opts') or ''
	local stem, slur
	local slurNote = 1
	if item:isSplitVoice() and item:objType() ~= 'RestChord' then
		slur = opts:match('Slur=(%a+)') or 'Upward'
		stem = slur == 'Upward' and 'Up' or 'Down'
		if slur == 'Upward' then slurNote = item:noteCount() end
	else
		stem = item:stemDir(slurNote)==1 and 'Up' or 'Down'
		slur = opts:match('Slur=(%a+)') or stem == 'Up' and 'Downward' or 'Upward'
	end
	local baseNote = item:durationBase(slurNote)
	local dotted = item:isDotted(slurNote)
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
	local dir = t.Dir
	local strength = t.Strength
	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	startNote:find('next', 'noteOrRest')
	if not startNote then return end
	local found
	for i = 1, span do
		found = endNote:find('next', 'noteOrRest')
	end
	if not found then return end
	local startStem, slurDir, ya, xo1, startNotehead = noteStuff(startNote)
	local endStem, _, _, xo2, endNotehead = noteStuff(endNote)
	ya = ya * strength
	if dir ~= 'Default' then slurDir = dir end
	local startNoteYBottom, startNoteYTop = startNote:notePos(1) or 0, startNote:notePos(startNote:noteCount()) or 0
	local endNoteYBottom, endNoteYTop = endNote:notePos(1) or 0, endNote:notePos(endNote:noteCount()) or 0	
	local x1 = startNote:xyTimeslot()
	local x2 = endNote:xyTimeslot()
	x1 = x1 + startOffsetX + xo1 + ((slurDir == 'Upward' and startStem == 'Up' and startNotehead ~= 'Whole') and .75 or 0)
	x2 = x2 + endOffsetX + xo2 - ((slurDir == 'Downward' and endStem == 'Down' and endNotehead ~= 'Whole') and .75 or 0)
	local y1 = (slurDir == 'Upward') and startNoteYTop + startOffsetY + 1.75 or startNoteYBottom - startOffsetY - 1.75
	local y2 = (slurDir == 'Upward') and endNoteYTop + endOffsetY + 1.75 or endNoteYBottom - endOffsetY - 1.75
	local xa = (x1 + x2) / 2
	ya = (y1 + y2) / 2 + ((slurDir == 'Upward') and ya or -ya)
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
end

local function spin_Slur(t, d)
	t.Span = t.Span + d
	t.Span = t.Span
end

return {
	spec = spec_Slur,
	spin = spin_Slur,
	draw = draw_Slur,
	menu = menu_Slur,
	menuInit = menuInit_Slur,
	menuClick = menuClick_Slur,
}

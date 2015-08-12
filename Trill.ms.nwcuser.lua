-- Version 0.1

--[[----------------------------------------------------------------
This plugin draws a trill above or below a set of notes.
@Span
The number of notes/chords to include in the trill. The minimum value is 1, which is the default setting.

Pressing + or - while the object is selected will increase or decrease the note span.
@StartOffset
This will adjust the horizontal position of the trill's start point. The range of values 
is -10.00 to 10.00. The default setting is 0.
@EndOffset
This will adjust the horizontal position of the trill's end point. The range of values 
is -10.00 to 10.00. The default setting is 0.
@Accidental
This will optionally insert an accidental symbol between the 'tr' and the first marking. The default setting is None.
@Scale
The scale factor for the trill symbols. This is a value from 5% to 400%, and the default setting is 100%.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local tr = '`_'
local sp = '_'
local squig = '-'
local accList = { 'None', 'Sharp', 'Natural', 'Flat' }
local accChar = { None='', Sharp='d', Natural='e', Flat='f' }

local spec_Trill = {
	{ id='Span', label='Note Span', type='int', default=1, min=1 },
	{ id='MinMarks', label='Minimum Marks', type='int', default=2, min=0, max=10 },
	{ id='StartOffset', label='Start Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='EndOffset', label='End Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='Accidental', label='Accidental', type='enum', default=accList[1], list=accList },
    { id='Scale', label='Scale (%)', type='int', min=5, max=400, step=5, default=100 },
}

local function draw_Trill(t)
	local span = t.Span
	local scale = t.Scale / 100

	startNote:find('next', 'noteOrRest')
	if not startNote then return end
	local x1 = startNote:xyTimeslot() + t.StartOffset

	local found
	for i = 1, span do
		found = endNote:find('next', 'noteOrRest')
	end
	if not found then return end
	local x2 = endNote:xyRight() + t.EndOffset
	nwcdraw.alignText('middle', 'left')

	local len = x2-x1
	local acc = accChar[t.Accidental]
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)
	local squigLen = nwcdraw.calcTextSize(squig)
	local trLen = nwcdraw.calcTextSize(tr)
	local spLen = nwcdraw.calcTextSize(sp)
	nwcdraw.moveTo(x1, 0)
	nwcdraw.text(tr)
	len = len - trLen

	if acc ~= '' then
		nwcdraw.setFontSize(nwcdraw.getFontSize()*.5)
		local accLen = nwcdraw.calcTextSize(acc)
		nwcdraw.moveTo(x1+trLen, -scale)
		nwcdraw.text(acc)
		nwcdraw.moveTo(x1+trLen+accLen+spLen, 0)
		len = len - accLen - spLen
		nwcdraw.setFontSize(nwcdraw.getFontSize()*2)
	end

	local count = t.Span == 1 and t.MinMarks or math.max(math.floor(len/squigLen), t.MinMarks)
	nwcdraw.text(string.rep(squig, count))
end

local function spin_Trill(t, d)
	t.Span = t.Span + d
	t.Span = t.Span
end

return {
	spec = spec_Trill,
	spin = spin_Trill,
	draw = draw_Trill
}
